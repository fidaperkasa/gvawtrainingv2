-- =================================================================================================
--
-- GVAW MarkSpawn Enhanced - Universal Spawning Script for DCS World
-- By EagleEye - DCS Indonesia
-- Version 3.0.4 - Fixed F10 menu messaging using proper group-based approach
--
-- =================================================================================================

markspawn = {}

-- Script Configuration
markspawn.debug = true
markspawn.commandIdent = "spawn"
markspawn.dbFileName = "dbspawn.json"

-- Runtime Data
markspawn.spawnedGroups = {} -- Tracks all spawned groups by name

-- Load external libraries
JSON = dofile(lfs.writedir() .. [[Scripts\GVAWv2\json.lua]])
if not JSON then
    trigger.action.outText("CRITICAL ERROR: json.lua not found. Please ensure it is in your Scripts folder.", 30)
    return
end

---------------------------------------------------------------------------------------------------
-- Unit Database Loader
---------------------------------------------------------------------------------------------------
markspawn.unitDatabase = {}

function markspawn.loadDatabase()
    local dbPath = lfs.writedir() .. [[Scripts\GVAWv2\]] .. markspawn.dbFileName
    local file = io.open(dbPath, "r")
    if file then
        local contents = file:read("*a")
        io.close(file)
        local success, db = pcall(JSON.decode, contents)
        if success then markspawn.unitDatabase = db; markspawn.notify("Unit database loaded.")
        else markspawn.notify("ERROR: Failed to parse " .. markspawn.dbFileName) end
    else markspawn.notify("ERROR: " .. markspawn.dbFileName .. " not found!") end
end

---------------------------------------------------------------------------------------------------
-- Helper Functions
---------------------------------------------------------------------------------------------------
function string.startsWith(String, Start) return string.sub(String, 1, string.len(Start)) == Start end

function markspawn.getMessageParameters(message)
    local params = {}
    for key, value in string.gmatch(message, "([^=,]+)=([^,]+)") do
        params[key:lower():gsub("%s+", "")] = value
    end
    return params
end

-- Sends message to a specific unit if unitId is provided.
function markspawn.notify(message, timeout, unitId)
    timeout = timeout or 10
    local text = "[MarkSpawn] " .. message
    if unitId then
        trigger.action.outTextForUnit(unitId, text, timeout, false)
    else
        trigger.action.outText(text, timeout)
    end
end

function markspawn.log(message) if markspawn.debug then print("MARKSPAWN DEBUG: " .. message) end end

function markspawn.getUnitCategory(unitTypeName)
    for category, unitList in pairs(markspawn.unitDatabase) do
        if category ~= "TEMPLATES" then
            for _, name in ipairs(unitList) do
                if name == unitTypeName then
                    if category == "GROUND_UNIT" then return Group.Category.GROUND end
                    if category == "PLANE" then return Group.Category.AIRPLANE end
                    if category == "HELICOPTER" then return Group.Category.HELICOPTER end
                    if category == "SHIP" then return Group.Category.SHIP end
                    if category == "STATIC" or category == "CARGO" then return "STATIC" end
                end
            end
        end
    end
    return nil
end

markspawn.callsigns = {
    jtac = { axeman = 1, darknight = 2, warrior = 3, pointer = 4, eyeball = 5, moonbeam = 6, whiplash = 7, finger = 8, pinpoint = 9, ferret = 10, shaba = 11, playboy = 12, hammer = 13, jaguar = 14, deathstar = 15, anvil = 16, firefly = 17, mantis = 18, badger = 19 },
    tanker = { texaco = 1, arco = 2, shell = 3 },
    awacs = { overlord = 1, magic = 2, wizard = 3, focus = 4, darkstar = 5 },
    aircraft = { enfield = 1, springfield = 2, uzi = 3, colt = 4, dodge = 5, ford = 6, chevy = 7, pontiac = 8 }
}

function markspawn.getCallsignTable(callsignStr, unitType)
    local name, flight, element = callsignStr:match("([a-zA-Z_]+)(%d)%-?(%d?)")
    if not name then name = callsignStr:match("([a-zA-Z_]+)") end
    if not name then return nil end

    name = name:lower()
    flight = tonumber(flight) or 1
    element = tonumber(element) or 1

    local callsignID
    if unitType == "KC-135MPRS" or unitType == "KC-135" or unitType == "KC-130" then
        callsignID = markspawn.callsigns.tanker[name]
    elseif unitType == "JTAC" then
        callsignID = markspawn.callsigns.jtac[name]
    else
        callsignID = markspawn.callsigns.aircraft[name]
    end
    
    if not callsignID then return nil end

    return {
        [1] = callsignID,
        [2] = flight,
        [3] = element,
        name = callsignStr
    }
end

---------------------------------------------------------------------------------------------------
-- F10 Menu Management
---------------------------------------------------------------------------------------------------
markspawn.menu = {}

-- Check if unit is a player unit
function markspawn.isPlayerUnit(unit)
    return unit and unit:getPlayerName() ~= nil
end

-- Delete all spawned units (for specific player)
function markspawn.cmdDeleteAll(params)
    local uid = params.uid
    markspawn.notify("Deleting all spawned units...", 10, uid)

    -- Delete everything we know about
    for _, g in ipairs(markspawn.spawnedGroups or {}) do
        local grp = Group.getByName(g.name)
        if grp and grp:isExist() then
            grp:destroy()
        end
    end

    -- Reset tracker
    markspawn.spawnedGroups = {}
    markspawn.notify("All spawned units and templates deleted.", 10, uid)
end

-- Show command syntax
function markspawn.cmdShowSyntax(params)
    local uid = params.uid
    local helpText = [[
    -- MARKSPAWN SYNTAX --
    Template Spawn:
    spawn,temp=TEMPLATE NAME,country=COUNTRY,hdg=DEG

    Single/Multi-Unit Spawn:
    spawn,type=UNIT,amount=N,country=C,hdg=DEG,alt=FT,spd=KTS
    ]]
    markspawn.notify(helpText, 45, uid)
end

-- Show template list
function markspawn.cmdShowTemplates(params)
    local uid = params.uid
    local page = params.page
    
    if not markspawn.unitDatabase or not markspawn.unitDatabase.TEMPLATES then
        markspawn.notify("No templates available in database.", 10, uid)
        return
    end

    local templateNames = {}
    for name, _ in pairs(markspawn.unitDatabase.TEMPLATES) do
        table.insert(templateNames, name)
    end
    table.sort(templateNames)

    local chunkSize = 20
    local startIndex = (page - 1) * chunkSize + 1
    local endIndex = math.min(startIndex + chunkSize - 1, #templateNames)

    if startIndex > #templateNames then
        markspawn.notify("No more templates to display.", 10, uid)
        return
    end

    local msg = string.format("-- Templates Page %d --\n", page)
    for i = startIndex, endIndex do
        msg = msg .. templateNames[i] .. "\n"
    end

    if endIndex < #templateNames then
        msg = msg .. string.format("\n... and %d more templates", #templateNames - endIndex)
    end

    markspawn.notify(msg, 60, uid)
end

-- Show unit list by category
function markspawn.cmdShowUnits(params)
    local uid = params.uid
    local category = params.category
    local page = params.page
    
    local unitList = markspawn.unitDatabase and markspawn.unitDatabase[category]
    if not unitList or #unitList == 0 then
        markspawn.notify("No units available in category: " .. category, 10, uid)
        return
    end

    table.sort(unitList)
    local chunkSize = 20
    local startIndex = (page - 1) * chunkSize + 1
    local endIndex = math.min(startIndex + chunkSize - 1, #unitList)

    if startIndex > #unitList then
        markspawn.notify("No more units to display in category: " .. category, 10, uid)
        return
    end

    local msg = string.format("-- %s Page %d --\n", category, page)
    for i = startIndex, endIndex do
        msg = msg .. unitList[i] .. "\n"
    end

    if endIndex < #unitList then
        msg = msg .. string.format("\n... and %d more units", #unitList - endIndex)
    end

    markspawn.notify(msg, 60, uid)
end

-- Setup F10 menu for a player unit
function markspawn.setupPlayerMenu(unit)
    if not markspawn.isPlayerUnit(unit) then return end
    
    local groupId = unit:getGroup():getID()
    local uid = unit:getID()

    -- Remove old menu if it exists
    if markspawn.menu[uid] then
        missionCommands.removeItemForGroup(groupId, markspawn.menu[uid])
    end

    -- Create new menu
    local root = missionCommands.addSubMenuForGroup(groupId, "MarkSpawn")
    markspawn.menu[uid] = root

    -- Syntax help
    missionCommands.addCommandForGroup(groupId, "Show Command Syntax", root, markspawn.cmdShowSyntax, { uid = uid })

    -- List spawnable items
    local listMenu = missionCommands.addSubMenuForGroup(groupId, "List Spawnable Items", root)

    -- Templates listing
    if markspawn.unitDatabase and markspawn.unitDatabase.TEMPLATES then
        local templateMenu = missionCommands.addSubMenuForGroup(groupId, "List Templates", listMenu)
        local templateCount = 0
        for _ in pairs(markspawn.unitDatabase.TEMPLATES) do templateCount = templateCount + 1 end
        
        if templateCount > 0 then
            local pages = math.ceil(templateCount / 20)
            for i = 1, pages do
                missionCommands.addCommandForGroup(groupId, "Page " .. i, templateMenu, 
                    markspawn.cmdShowTemplates, { uid = uid, page = i })
            end
        end
    end

    -- Units per category
    local sortedCategories = { "PLANE", "HELICOPTER", "GROUND_UNIT", "SHIP", "STATIC", "CARGO" }
    for _, cat in ipairs(sortedCategories) do
        local unitList = markspawn.unitDatabase and markspawn.unitDatabase[cat]
        if unitList and #unitList > 0 then
            local catMenu = missionCommands.addSubMenuForGroup(groupId, "List " .. cat, listMenu)
            local pages = math.ceil(#unitList / 20)
            for i = 1, pages do
                missionCommands.addCommandForGroup(groupId, "Page " .. i, catMenu, 
                    markspawn.cmdShowUnits, { uid = uid, category = cat, page = i })
            end
        end
    end

    -- Clean up
    missionCommands.addCommandForGroup(groupId, "Delete All Spawned Units", root, markspawn.cmdDeleteAll, { uid = uid })
end

---------------------------------------------------------------------------------------------------
-- Unit Tasking & Setup Functions
---------------------------------------------------------------------------------------------------
markspawn.tasking = {}

function markspawn.postSpawnSetup(groupName, spawnLocation, params, unitId)
    local newGroup = Group.getByName(groupName)
    if not newGroup or not newGroup:isExist() then return end
    local controller = newGroup:getController()
    if not controller then return end

    local unitType = params.type
    
    if params.freq then
        if unitType == "JTAC" or params.category == Group.Category.AIRPLANE or params.category == Group.Category.HELICOPTER then
            controller:setCommand({id = 'SetFrequency', params = {frequency = tonumber(params.freq) * 1000000, modulation = 0}})
            markspawn.notify(groupName .. " radio set to " .. params.freq .. " MHz AM.", 10, unitId)
        end
    end

    if params.category == Group.Category.AIRPLANE or params.category == Group.Category.HELICOPTER then
        local taskTable
        if unitType == "KC-135MPRS" or unitType == "KC-135" or unitType == "KC-130" then
            taskTable = markspawn.tasking.createTankerTask(spawnLocation, params)
            markspawn.notify("Tasking " .. groupName .. " as TANKER.", 10, unitId)
            if params.tacan then
                local channelStr, band = params.tacan:match("(%d+)(%a)")
                if channelStr and band then
                    controller:setCommand({id = 'ActivateBeacon', params = {type = 4, system = 2, channel = tonumber(channelStr), mode = band:upper(), callsign = "TKR"}})
                    markspawn.notify(groupName .. " TACAN activated on " .. params.tacan:upper(), 10, unitId)
                end
            end
        else
            taskTable = markspawn.tasking.createOrbitTask(spawnLocation, params)
            markspawn.notify("Tasking " .. groupName .. " to perform race-track orbit.", 10, unitId)
        end
        if taskTable then controller:setTask(taskTable) end
    end
end

function markspawn.tasking.createTankerTask(spawnPos, params)
    local headingRad = math.rad(tonumber(params.hdg) or 360)
    local orbitStartDist = 15 * 1852
    local orbitTrackLength = 10 * 1852
    local orbitPoint1 = {x = spawnPos.x + math.cos(headingRad) * orbitStartDist, z = spawnPos.z + math.sin(headingRad) * orbitStartDist}
    local orbitPoint2 = {x = orbitPoint1.x + math.cos(headingRad) * orbitTrackLength, z = orbitPoint1.z + math.sin(headingRad) * orbitTrackLength}
    local speedMPS = (tonumber(params.spd) or 350) * 0.514444
    local groundY = land.getHeight({x = orbitPoint1.x, y = orbitPoint1.z})
    local altAGL_Meters = (tonumber(params.alt) or 20000) * 0.3048
    local altMSL = groundY + altAGL_Meters
    return {id = 'Mission', params = {route = {points = {{x = orbitPoint1.x, y = orbitPoint1.z, alt = altMSL, speed = speedMPS, action = "Turning Point", task = { id = 'Tanker', params = {} }}, {x = orbitPoint2.x, y = orbitPoint2.z, alt = altMSL, speed = speedMPS, action = "Turning Point", task = {id = 'Orbit', params = {pattern = 'Race-Track', speed = speedMPS, altitude = altMSL}}}}}}}
end

function markspawn.tasking.createOrbitTask(spawnPos, params)
    local headingRad = math.rad(tonumber(params.hdg) or 360)
    local distanceMeters = 15 * 1852
    local orbitEndPoint = {x = spawnPos.x + math.cos(headingRad) * distanceMeters, z = spawnPos.z + math.sin(headingRad) * distanceMeters}
    local speedMPS = (tonumber(params.spd) or (params.category == Group.Category.AIRPLANE and 430 or 135)) * 0.514444
    local groundY = land.getHeight({x = spawnPos.x, y = spawnPos.z})
    local altAGL_Meters = (tonumber(params.alt) or (params.category == Group.Category.AIRPLANE and 3000 or 300)) * 0.3048
    local altMSL = groundY + altAGL_Meters
    return {id = 'Orbit', params = {pattern = 'Race-Track', point = { x = spawnPos.x, y = spawnPos.z }, point2 = { x = orbitEndPoint.x, y = orbitEndPoint.z }, speed = speedMPS, altitude = altMSL}}
end

---------------------------------------------------------------------------------------------------
-- Core Spawner Function
---------------------------------------------------------------------------------------------------
markspawn.spawner = {}

function markspawn.spawner.spawnTemplate(location, params, unitId)
    local templateName = params.temp
    if not templateName then markspawn.notify("Error: 'temp' parameter is missing.", 10, unitId); return end
    
    local templateData = markspawn.unitDatabase.TEMPLATES[templateName]
    if not templateData then markspawn.notify("Error: Template '" .. templateName .. "' not found in database.", 10, unitId); return end

    local countryName = params.country or "CJTF_RED"
    local countryID = country.id[countryName]
    if not countryID then
        markspawn.notify("Error: Country '" .. countryName .. "' is not valid, defaulting to CJTF_RED.", 10, unitId)
        countryID = country.id.CJTF_RED
    end

    local groupCategory = Group.Category.GROUND
    local baseHeadingRad = math.rad(tonumber(params.hdg) or 0)

    local unitsTable = {}
    for _, unitT in pairs(templateData.units) do
        local unitHeadingRad = baseHeadingRad + math.rad(unitT.heading or 0)
        if unitHeadingRad > (2 * math.pi) then unitHeadingRad = unitHeadingRad - (2 * math.pi) end
        if unitHeadingRad < 0 then unitHeadingRad = unitHeadingRad + (2 * math.pi) end

        local unitX = location.x + ((unitT.dx or 0) * math.cos(baseHeadingRad) - (unitT.dy or 0) * math.sin(baseHeadingRad))
        local unitZ = location.z + ((unitT.dx or 0) * math.sin(baseHeadingRad) + (unitT.dy or 0) * math.cos(baseHeadingRad))
        
        local unitData = {
            name = unitT.name .. "_" .. math.random(100,999),
            type = unitT.name,
            x = unitX,
            y = unitZ,
            heading = unitHeadingRad,
            skill = unitT.skill or "Average"
        }
        table.insert(unitsTable, unitData)
    end

    local groupName = templateName .. "_" .. math.random(1000, 9999)
    local newGroup = { name = groupName, task = "Ground Attack", units = unitsTable }
    
    local result = coalition.addGroup(countryID, groupCategory, newGroup)
    if result then
        local actualGroupName = result:getName()
        markspawn.notify("Spawned template: " .. actualGroupName, 10, unitId)
        table.insert(markspawn.spawnedGroups, { name = actualGroupName, isTemplate = true })
    else
        markspawn.notify("Failed to spawn template: " .. templateName, 10, unitId)
    end
end

function markspawn.spawner.spawnObject(location, params, unitId)
    if params.temp then
        markspawn.spawner.spawnTemplate(location, params, unitId)
        return
    end

    if not params.type then markspawn.notify("Error: 'type' parameter is missing.", 10, unitId); return end
    local unitType = params.type
    local unitCategory = markspawn.getUnitCategory(unitType)
    if not unitCategory then markspawn.notify("Error: Unit type '" .. unitType .. "' not found in database.", 10, unitId); return end
    local countryName = params.country or "CJTF_RED"
    params.heading = tonumber(params.hdg) or 360
    local headingRad = math.rad(params.heading)
    local countryID = country.id[countryName]
    if not countryID then markspawn.notify("Error: Country '" .. countryName .. "' is not valid.", 10, unitId); countryID = country.id.CJTF_RED end
    
    if unitCategory == "STATIC" then
        local newStatic = { type = unitType, name = unitType .. "_" .. math.random(1000, 9999), x = location.x, y = location.z, heading = headingRad }
        if coalition.addStaticObject(countryID, newStatic) then markspawn.notify("Spawned static object: " .. unitType, 10, unitId) else markspawn.notify("Failed to spawn static object: " .. unitType, 10, unitId) end
    else
        local groupName = unitType .. "_" .. math.random(1000, 9999)
        local callsignTable
        local amount = tonumber(params.amount) or 1
        
        local isAircraft = unitCategory == Group.Category.AIRPLANE or unitCategory == Group.Category.HELICOPTER
        local callsignStr = params.callsign
        if isAircraft or unitType == "JTAC" then
            if not callsignStr then
                if unitType == "KC-135MPRS" or unitType == "KC-135" or unitType == "KC-130" then callsignStr = "Texaco1-1"
                elseif unitType == "JTAC" then callsignStr = "Axeman1-1"
                else callsignStr = "Enfield" .. math.random(1,9) .. "-1" end
            end
            callsignTable = markspawn.getCallsignTable(callsignStr, unitType)
            if callsignTable then groupName = callsignTable.name end
        end
        
        local unitsTable = {}
        for i = 1, amount do
            local unitData = { type = unitType, name = groupName .. "-" .. i, x = location.x, y = location.z, heading = headingRad, livery_id = params.livery, callsign = callsignTable }
            
            if callsignTable then
                unitData.onboard_num = callsignTable[3] + i - 1
            end

            if isAircraft then
                local groundY = land.getHeight({x = location.x, y = location.z})
                unitData.alt = groundY + (tonumber(params.alt) or (unitCategory == Group.Category.AIRPLANE and 3000 or 300)) * 0.3048
                unitData.speed = (tonumber(params.spd) or (unitCategory == Group.Category.AIRPLANE and 430 or 135)) * 0.514444
            elseif unitCategory == Group.Category.GROUND and i > 1 then
                local spacing = 200
                local distance = (i - 1) * spacing
                unitData.x = location.x - math.cos(headingRad) * distance
                unitData.y = location.z - math.sin(headingRad) * distance
            end
            table.insert(unitsTable, unitData)
        end

        local groupTask = "Ground Attack"
        if unitType == "KC-135MPRS" or unitType == "KC-135" or unitType == "KC-130" then
            groupTask = "Refueling"
        end
        
        local newGroup = { name = groupName, task = groupTask, units = unitsTable }
        if isAircraft and amount > 1 then
            newGroup.formation = "Echelon Right"
        end
        
        local result = coalition.addGroup(countryID, unitCategory, newGroup)
        if result then
            local actualGroupName = result:getName()
            markspawn.notify("Spawned group: " .. actualGroupName .. " with " .. amount .. " unit(s).", 10, unitId)
            table.insert(markspawn.spawnedGroups, {name = actualGroupName})
            
            params.category = unitCategory
            
            timer.scheduleFunction(function() markspawn.postSpawnSetup(actualGroupName, location, params, unitId) end, {}, timer.getTime() + 2)
        else
            markspawn.notify("Failed to spawn unit: " .. unitType, 10, unitId)
        end
    end
end

---------------------------------------------------------------------------------------------------
-- Event Handlers
---------------------------------------------------------------------------------------------------
function markspawn.eventHandler(event)
    -- Chat command handling
    if event.id == 26 and event.text and event.text:lower():startsWith(markspawn.commandIdent) then
        local initiatorUnit = event.initiator
        if not initiatorUnit then return end
        local initiatorUnitId = initiatorUnit:getID()

        local command, _, params_str = event.text:find("spawn,(.+)")
        if params_str then
            local params = markspawn.getMessageParameters(params_str)
            markspawn.spawner.spawnObject(event.pos, params, initiatorUnitId)
        else
            markspawn.notify("Invalid format. Use: spawn,type=... or spawn,temp=...", 10, initiatorUnitId)
        end
    end
    
    -- Player enter unit - setup menu
    if event.id == 15 then -- S_EVENT_PLAYER_ENTER_UNIT
        local unit = event.initiator
        if unit and unit:getPlayerName() then
            timer.scheduleFunction(function()
                markspawn.setupPlayerMenu(unit)
            end, nil, timer.getTime() + 2)
        end
    end
end

---------------------------------------------------------------------------------------------------
-- Script Initialization
---------------------------------------------------------------------------------------------------
local MarkSpawnEventHandler = {}
function MarkSpawnEventHandler:onEvent(event) markspawn.eventHandler(event) end
world.addEventHandler(MarkSpawnEventHandler)

markspawn.loadDatabase()
markspawn.log("GVAW MarkSpawn - Universal Spawning Script Initialized.")
env.info("GVAW Markspawn v3 - rev 3.0.3 initialized.")
