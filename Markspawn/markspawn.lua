-- =================================================================================================
--
-- GVAW MarkSpawn Enhanched - Universal Spawning Script for DCS World
-- By EagleEye - DCS Indonesia
-- Version 3.0.1 - Integrated Template Spawning (Code Cleanup)
--
-- =================================================================================================
--[[
  SETUP:
  1. Place this file in "Saved Games\DCS\Scripts\".
  2. Place "dbspawn.json" (the unit database) in the same folder.
  3. Download "json.lua" from https://github.com/rxi/json.lua and place it in the same folder.
  4. Load this script in your mission with a DO SCRIPT FILE trigger.

  COMMAND SYNTAX:
  Single Type: spawn,type=UNIT,amount=NUM,country=C,hdg=DEG,alt=FEET,spd=KNOTS
  Template:    spawn,temp=TEMPLATE_NAME,country=C,hdg=DEG

  EXAMPLE JSON FOR TEMPLATES:
  "TEMPLATES": {
    "FOB Alpha": {
      "units": [
        { "name": "M1A2", "dx": 0, "dy": 0, "heading": 0 },
        { "name": "Humvee", "dx": 50, "dy": 50, "heading": 45 },
        { "name": "Tent", "dx": -50, "dy": 50, "heading": 0 }
      ]
    }
  }
--]]

markspawn = {}

-- Script Configuration
markspawn.debug = true
markspawn.commandIdent = "spawn"
markspawn.dbFileName = "dbspawn.json"

-- Runtime Data
markspawn.spawnedGroups = {} -- Tracks all spawned groups by name

-- Load external libraries
JSON = dofile(lfs.writedir() .. [[Scripts\json.lua]])
if not JSON then
    trigger.action.outText("CRITICAL ERROR: json.lua not found. Please ensure it is in your Scripts folder.", 30)
    return
end

---------------------------------------------------------------------------------------------------
-- Unit Database Loader
---------------------------------------------------------------------------------------------------
markspawn.unitDatabase = {}

function markspawn.loadDatabase()
    local dbPath = lfs.writedir() .. [[Scripts\]] .. markspawn.dbFileName
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

--- MODIFIED --- Use a more flexible regex to allow spaces in template names
function markspawn.getMessageParameters(message)
    local params = {}
    for key, value in string.gmatch(message, "([^=,]+)=([^,]+)") do
        params[key:lower():gsub("%s+", "")] = value
    end
    return params
end
function markspawn.notify(message, timeout) if not timeout then timeout = 10 end; trigger.action.outText("[MarkSpawn] " .. message, timeout) end
function markspawn.log(message) if markspawn.debug then print("MARKSPAWN DEBUG: " .. message) end end

--- MODIFIED --- Ignores the "TEMPLATES" category when searching for unit types
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

function markspawn.menu.deleteAll()
    markspawn.notify("Deleting all spawned units...")
    local groupsToDelete = {}
    for _, groupData in pairs(markspawn.spawnedGroups) do table.insert(groupsToDelete, groupData) end
    for _, groupData in ipairs(groupsToDelete) do
        local group = Group.getByName(groupData.name)
        if group and group:isExist() then group:destroy() end
    end
    markspawn.spawnedGroups = {}
    markspawn.menu.updateDeleteMenu()
end

function markspawn.menu.deleteSingleGroup(args)
    local groupName = args.groupName
    if not groupName then return end
    local group = Group.getByName(groupName)
    if group and group:isExist() then group:destroy(); markspawn.notify("Deleted group: " .. groupName) end
    for i, groupData in ipairs(markspawn.spawnedGroups) do
        if groupData.name == groupName then table.remove(markspawn.spawnedGroups, i); break end
    end
    markspawn.menu.updateDeleteMenu()
end

function markspawn.menu.updateDeleteMenu()
    missionCommands.removeItemForCoalition(coalition.side.BLUE, { "MarkSpawn" })
    missionCommands.removeItemForCoalition(coalition.side.RED, { "MarkSpawn" })
    markspawn.setupF10Menu()
end

--- MODIFIED --- Updated F10 menu to include template spawning info and lists.
function markspawn.setupF10Menu()
    for _, coa in ipairs({coalition.side.BLUE, coalition.side.RED}) do
        local spawnMenu = missionCommands.addSubMenuForCoalition(coa, "MarkSpawn")
        
        missionCommands.addCommandForCoalition(coa, "Show Command Syntax", spawnMenu, function()
            local helpText = [[
            -- MARKSPAWN SYNTAX --
            Template Spawn:
            spawn,temp=TEMPLATE NAME,country=COUNTRY,hdg=DEG

            Single/Multi-Unit Spawn:
            spawn,type=UNIT,amount=N,country=C,hdg=DEG,alt=FT,spd=KTS
            ]]
            markspawn.notify(helpText, 45)
        end)

        local listMenu = missionCommands.addSubMenuForCoalition(coa, "List Spawnable Items", spawnMenu)

        -- --- ADDED --- Submenu for listing templates
        if markspawn.unitDatabase.TEMPLATES then
            local templatesMenu = missionCommands.addSubMenuForCoalition(coa, "List Templates", listMenu)
            local templateNames = {}
            for name, _ in pairs(markspawn.unitDatabase.TEMPLATES) do table.insert(templateNames, name) end
            table.sort(templateNames)
            for _, templateName in ipairs(templateNames) do
                missionCommands.addCommandForCoalition(coa, templateName, templatesMenu, function()
                    markspawn.notify("Template Command: temp=" .. templateName, 15)
                end)
            end
        end

        local sortedCategories = {"PLANE", "HELICOPTER", "GROUND_UNIT", "SHIP", "STATIC", "CARGO"}
        for _, categoryName in ipairs(sortedCategories) do
            local unitList = markspawn.unitDatabase[categoryName]
            if unitList and #unitList > 0 then
                missionCommands.addCommandForCoalition(coa, "List " .. categoryName, listMenu, function()
                    table.sort(unitList)
                    local message = "-- Spawnable " .. categoryName .. " --\n" .. table.concat(unitList, "\n")
                    markspawn.notify(message, 60)
                end)
            end
        end

        local cleanUpMenu = missionCommands.addSubMenuForCoalition(coa, "Clean Up Units", spawnMenu)
        missionCommands.addCommandForCoalition(coa, "Delete All Spawned Units", cleanUpMenu, markspawn.menu.deleteAll)
        if #markspawn.spawnedGroups > 0 then
            missionCommands.addCommandForCoalition(coa, "----------", cleanUpMenu, function() end)
            for _, groupData in ipairs(markspawn.spawnedGroups) do
                missionCommands.addCommandForCoalition(coa, "Delete " .. groupData.name, cleanUpMenu, markspawn.menu.deleteSingleGroup, {groupName = groupData.name})
            end
        end
    end
    markspawn.log("F10 Menu Initialized.")
end

---------------------------------------------------------------------------------------------------
-- Unit Tasking & Setup Functions
---------------------------------------------------------------------------------------------------
markspawn.tasking = {}

function markspawn.postSpawnSetup(groupName, spawnLocation, params)
    local newGroup = Group.getByName(groupName)
    if not newGroup or not newGroup:isExist() then return end
    local controller = newGroup:getController()
    if not controller then return end

    local unitType = params.type
    
    if params.freq then
        if unitType == "JTAC" or params.category == Group.Category.AIRPLANE or params.category == Group.Category.HELICOPTER then
            controller:setCommand({id = 'SetFrequency', params = {frequency = tonumber(params.freq) * 1000000, modulation = 0}})
            markspawn.notify(groupName .. " radio set to " .. params.freq .. " MHz AM.")
        end
    end

    if params.category == Group.Category.AIRPLANE or params.category == Group.Category.HELICOPTER then
        local taskTable
        if unitType == "KC-135MPRS" or unitType == "KC-135" or unitType == "KC-130" then
            taskTable = markspawn.tasking.createTankerTask(spawnLocation, params)
            markspawn.notify("Tasking " .. groupName .. " as TANKER.")
            if params.tacan then
                local channelStr, band = params.tacan:match("(%d+)(%a)")
                if channelStr and band then
                    controller:setCommand({id = 'ActivateBeacon', params = {type = 4, system = 2, channel = tonumber(channelStr), mode = band:upper(), callsign = "TKR"}})
                    markspawn.notify(groupName .. " TACAN activated on " .. params.tacan:upper())
                end
            end
        else
            taskTable = markspawn.tasking.createOrbitTask(spawnLocation, params)
            markspawn.notify("Tasking " .. groupName .. " to perform race-track orbit.")
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

--- ADDED --- Function to handle spawning of pre-defined templates
function markspawn.spawner.spawnTemplate(location, params)
    local templateName = params.temp
    if not templateName then markspawn.notify("Error: 'temp' parameter is missing."); return end
    
    local templateData = markspawn.unitDatabase.TEMPLATES[templateName]
    if not templateData then markspawn.notify("Error: Template '" .. templateName .. "' not found in database."); return end

    local countryName = params.country
    if not countryName then markspawn.notify("Error: 'country' parameter is required for templates."); return end
    local countryID = country.id[countryName]
    if not countryID then markspawn.notify("Error: Country '" .. countryName .. "' is not valid."); return end

    local groupCategory = Group.Category.GROUND -- All templates are assumed to be ground units for now
    local baseHeadingRad = math.rad(tonumber(params.hdg) or 0)

    local unitsTable = {}
    for _, unitT in pairs(templateData.units) do
        -- Calculate the unit's final heading by adding its relative heading to the base heading
        local unitHeadingRad = baseHeadingRad + math.rad(unitT.heading or 0)
        if unitHeadingRad > (2 * math.pi) then unitHeadingRad = unitHeadingRad - (2 * math.pi) end
        if unitHeadingRad < 0 then unitHeadingRad = unitHeadingRad + (2 * math.pi) end

        -- Calculate the unit's final world position using a 2D rotation matrix
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
        markspawn.notify("Spawned template: " .. actualGroupName)
        table.insert(markspawn.spawnedGroups, {name = actualGroupName})
        markspawn.menu.updateDeleteMenu()
    else
        markspawn.notify("Failed to spawn template: " .. templateName)
    end
end

--- MODIFIED --- This function now acts as a dispatcher.
function markspawn.spawner.spawnObject(location, params)
    -- If 'temp' parameter exists, use the template spawner
    if params.temp then
        markspawn.spawner.spawnTemplate(location, params)
        return
    end

    if not params.type then markspawn.notify("Error: 'type' parameter is missing."); return end
    local unitType = params.type
    local unitCategory = markspawn.getUnitCategory(unitType)
    if not unitCategory then markspawn.notify("Error: Unit type '" .. unitType .. "' not found in database."); return end
    local countryName = params.country or "USA"
    params.heading = tonumber(params.hdg) or 360
    local headingRad = math.rad(params.heading)
    local countryID = country.id[countryName]
    if not countryID then markspawn.notify("Error: Country '" .. countryName .. "' is not valid."); countryID = country.id.USA end
    
    if unitCategory == "STATIC" then
        local newStatic = { type = unitType, name = unitType .. "_" .. math.random(1000, 9999), x = location.x, y = location.z, heading = headingRad }
        if coalition.addStaticObject(countryID, newStatic) then markspawn.notify("Spawned static object: " .. unitType) else markspawn.notify("Failed to spawn static object: " .. unitType) end
    else
        local groupName = unitType .. "_" .. math.random(1000, 9999)
        local callsignTable
        local onboardNum = 1
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
                -- Trail formation for ground units
                local spacing = 200 -- 200 meters
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
            markspawn.notify("Spawned group: " .. actualGroupName .. " with " .. amount .. " unit(s).")
            table.insert(markspawn.spawnedGroups, {name = actualGroupName})
            markspawn.menu.updateDeleteMenu()
            
            params.category = unitCategory
            
            timer.scheduleFunction(function() markspawn.postSpawnSetup(actualGroupName, location, params) end, {}, timer.getTime() + 2)
        else
            markspawn.notify("Failed to spawn unit: " .. unitType)
        end
    end
end

---------------------------------------------------------------------------------------------------
-- Event Handler & Mission Setup
---------------------------------------------------------------------------------------------------
function markspawn.eventHandler(event)
    if event.id == 26 and event.text and event.text:lower():startsWith(markspawn.commandIdent) then
        local command, _, params_str = event.text:find("spawn,(.+)")
        if params_str then
            local params = markspawn.getMessageParameters(params_str)
            markspawn.spawner.spawnObject(event.pos, params)
        else
            markspawn.notify("Invalid format. Use: spawn,type=... or spawn,temp=...")
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
timer.scheduleFunction(markspawn.setupF10Menu, nil, timer.getTime() + 1)

markspawn.log("GVAW MarkSpawn - Universal Spawning Script Initialized.")
