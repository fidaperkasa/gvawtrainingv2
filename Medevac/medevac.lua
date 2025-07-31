-- =================================================================================================
--
-- Standalone Medevac Script for DCS World
-- Original by ragnarDa
-- Modified by EagleEye + ChatGPT
--
-- =================================================================================================

medevac = {}

-- Configuration
medevac.debug = true
medevac.casualtyPrefix = "casualty"
medevac.hospitalPrefix = "hospital"
medevac.messageIdent = "mvac"
medevac.delimiter = ","
medevac.unitIndex = 1
medevac.casualties = {}
medevac.hospitals = {}

---------------------------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------------------------

function string.startsWith(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

function medevac.getMessageParameters(message, delimiter)
    local params = {}
    for key, value in string.gmatch(message, '(%w+)=([%w%.]+)') do
        params[key] = value
    end
    return params
end

function medevac.get3DDistance(p1, p2)
    local dx = p1.x - p2.x
    local dy = p1.y - p2.y
    local dz = p1.z - p2.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

function medevac.notify(msg, timeout)
    trigger.action.outText("[" .. medevac.messageIdent .. "] " .. msg, timeout or 10)
end

function medevac.log(msg)
    if medevac.debug then
        env.info("[MEDEVAC] " .. msg)
    end
end

function medevac.getInitiatorGroupName(args)
    return args._groupName
end

---------------------------------------------------------------------------------------------------
-- Spawner
---------------------------------------------------------------------------------------------------

medevac.spawner = {}

function medevac.spawner.spawnAdditionalFeatures(location, objectData, config)
    if config.freq then
        local freq = tonumber(config.freq)
        if freq > 1000 then freq = freq / 1000 end
        local volume = tonumber(config.volume) or 100
        objectData.radio = {
            beacon = trigger.action.radioTransmission("l10n/DEFAULT/elt1.wav", location, 0, true, freq, volume),
            freq = config.freq
        }
        medevac.notify("Radio on " .. config.freq .. " KHz.")
    end

    if config.smoke then
        local colorMap = {
            blue = trigger.smokeColor.Blue,
            green = trigger.smokeColor.Green,
            orange = trigger.smokeColor.Orange,
            red = trigger.smokeColor.Red,
            white = trigger.smokeColor.White,
        }
        local color = colorMap[config.smoke:lower()] or trigger.smokeColor.Blue
        trigger.action.smoke(location, color)
        objectData.smoke = { colour = config.smoke }
        medevac.notify(config.smoke:gsub("^%l", string.upper) .. " smoke deployed.")
    end
    return objectData
end

function medevac.spawner.spawnCasualty(location, config)
    local name = medevac.casualtyPrefix .. tostring(medevac.unitIndex)
    local newGroup = {
        name = name,
        task = "Ground Nothing",
        units = {
            [1] = {
                type = "Soldier M4",
                name = name .. "-1",
                x = location.x,
                y = location.z,
                playerCanDrive = false,
            }
        }
    }
    local result = coalition.addGroup(country.id.USA, Group.Category.GROUND, newGroup)
    if result then
        local data = {
            group = name,
            status = "waiting",
            name = "Casualty " .. tostring(medevac.unitIndex)
        }
        data = medevac.spawner.spawnAdditionalFeatures(location, data, config)
        medevac.casualties[medevac.unitIndex] = { casualty = data }
        medevac.unitIndex = medevac.unitIndex + 1
        medevac.notify(data.name .. " reported.")
    end
end

function medevac.spawner.spawnHospital(location, config)
    local name = medevac.hospitalPrefix .. tostring(#medevac.hospitals + 1)
    local newStatic = {
        type = "FARP Tent",
        name = name,
        x = location.x,
        y = location.z,
        heading = math.random(0, 360)
    }
    local result = coalition.addStaticObject(country.id.USA, newStatic)
    if result then
        local data = { name = name }
        data = medevac.spawner.spawnAdditionalFeatures(location, data, config)
        table.insert(medevac.hospitals, data)
        medevac.notify("Hospital " .. name .. " operational.")
    end
end

---------------------------------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------------------------------

function medevac.collectCasualties(args)
    local group = Group.getByName(args._groupName)
    if not group then return end
    local unit = group:getUnit(1)
    if not unit or unit:inAir() then
        medevac.notify("Must be on ground to collect.")
        return
    end

    local pos = unit:getPoint()
    local count = 0
    for _, data in pairs(medevac.casualties) do
        if data.casualty.status == "waiting" then
            local g = Group.getByName(data.casualty.group)
            if g and g:isExist() then
                local u = g:getUnit(1)
                if u and medevac.get3DDistance(pos, u:getPoint()) <= 50 then
                    g:destroy()
                    data.casualty.status = "onboard"
                    data.casualty.medevacGroupName = args._groupName
                    medevac.notify(data.casualty.name .. " onboard.")
                    count = count + 1
                end
            end
        end
    end
    if count == 0 then
        medevac.notify("No casualties nearby.")
    end
end

function medevac.deliverCasualties(args)
    local group = Group.getByName(args._groupName)
    if not group then return end
    local unit = group:getUnit(1)
    if not unit or unit:inAir() then
        medevac.notify("Must be on ground to deliver.")
        return
    end

    local pos = unit:getPoint()
    local hospital = nil
    for _, h in pairs(medevac.hospitals) do
        local o = StaticObject.getByName(h.name)
        if o and medevac.get3DDistance(pos, o:getPoint()) <= 100 then
            hospital = h
            break
        end
    end
    if not hospital then
        medevac.notify("No hospital in range.")
        return
    end

    local count = 0
    for _, data in pairs(medevac.casualties) do
        if data.casualty.status == "onboard" and data.casualty.medevacGroupName == args._groupName then
            data.casualty.status = "rescued"
            data.casualty.hospital = hospital.name
            count = count + 1
            medevac.notify("Rescued " .. data.casualty.name)
        end
    end
    if count == 0 then
        medevac.notify("No onboard casualties.")
    end
end

function medevac.listHospitals(args)
    local group = Group.getByName(args._groupName)
    if not group then return end
    local unit = group:getUnit(1)
    if not unit then return end
    local pos = unit:getPoint()

    local msg = ""
    for _, h in pairs(medevac.hospitals) do
        msg = msg .. "\n" .. h.name
        local o = StaticObject.getByName(h.name)
        if o then
            local d = medevac.get3DDistance(pos, o:getPoint()) / 1852
            msg = msg .. string.format(" - %.1f NM", d)
        end
        if h.radio then msg = msg .. " - Freq: " .. h.radio.freq end
    end
    medevac.notify("Hospitals:" .. msg, 15)
end

function medevac.listAllCasualties(args)
    local msg = ""
    for _, data in pairs(medevac.casualties) do
        if data.casualty.status == "waiting" then
            msg = msg .. "\n" .. data.casualty.name
            if data.casualty.radio then msg = msg .. " - Freq: " .. data.casualty.radio.freq end
            if data.casualty.smoke then msg = msg .. " - Smoke: " .. data.casualty.smoke.colour end
        end
    end
    if msg == "" then msg = "No casualties waiting." end
    medevac.notify(msg, 15)
end

function medevac.printHelp(args)
    local txt = [[Examples:
mvac,freq=251,smoke=red
mvac-hospital,freq=401
Supports: freq=XXX, volume=100, smoke=red|green|...
]]
    medevac.notify(txt, 25)
end

---------------------------------------------------------------------------------------------------
-- Event Handler
---------------------------------------------------------------------------------------------------

local handler = {}
function handler:onEvent(event)
    if event.id == 26 and event.text then
        local msg = event.text:lower()
        local pos = event.pos
        local config = medevac.getMessageParameters(msg, medevac.delimiter)
        if msg == medevac.messageIdent .. ".help" then return medevac.printHelp() end
        if msg:startsWith(medevac.messageIdent) then
            if msg:find("hospital") then
                medevac.spawner.spawnHospital(pos, config)
            else
                medevac.spawner.spawnCasualty(pos, config)
            end
        end
    elseif event.id == world.event.S_EVENT_BIRTH and event.initiator and event.initiator.getGroup then
        local unit = event.initiator
        local group = unit:getGroup()
        if unit:getPlayerName() and group then
            local groupId = group:getID()
            local groupName = group:getName()
            local args = { _groupName = groupName }

            local submenu = missionCommands.addSubMenuForGroup(groupId, "Medevac Action")
            missionCommands.addCommandForGroup(groupId, "Collect nearby casualties", submenu, medevac.collectCasualties, args)
            missionCommands.addCommandForGroup(groupId, "Deliver casualties to hospital", submenu, medevac.deliverCasualties, args)
            missionCommands.addCommandForGroup(groupId, "List Available Hospitals", submenu, medevac.listHospitals, args)
            medevac.log("F10 menu created for group: " .. groupName)
        end
    end
end
world.addEventHandler(handler)

---------------------------------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------------------------------

-- Setup coalition-wide menu
local blueMenu = missionCommands.addSubMenuForCoalition(coalition.side.BLUE, "Medevac")
-- local redMenu = missionCommands.addSubMenuForCoalition(coalition.side.RED, "Medevac")

missionCommands.addCommandForCoalition(coalition.side.BLUE, "List All Casualties", blueMenu, medevac.listAllCasualties, {})
missionCommands.addCommandForCoalition(coalition.side.BLUE, "Help", blueMenu, medevac.printHelp, {})
-- missionCommands.addCommandForCoalition(coalition.side.RED, "List All Casualties", redMenu, medevac.listAllCasualties, {})
-- missionCommands.addCommandForCoalition(coalition.side.RED, "Help", redMenu, medevac.printHelp, {})

medevac.log("Medevac system initialized.")
