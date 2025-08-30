-- =================================================================================================
--
-- GVAW MarkSpawn Enhanced - Universal Spawning Script for DCS World
-- By EagleEye - DCS Indonesia
-- Version 3.0.7
-- --- Expansion modification AWACS and TANKER default
-- --- FIX error for several things
-- --- Enhanced with selective deletion functionality and individual group deletion
-- --- Enhanced JTAC functionality with FAC tasking
-- --- Enhanced with Embarking system for Troops to Transport
--
-- =================================================================================================

markspawn = {}

-- Script Configuration
markspawn.debug = true
markspawn.commandIdent = "spawn"
markspawn.dbFileName = "dbspawn.json"

-- Runtime Data - Enhanced tracking
markspawn.spawnedGroups = {} -- Tracks all spawned groups with metadata
markspawn.spawnedStatics = {} -- Tracks static objects

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

-- static template spawn
-- Map template unit names to actual DCS unit types
function markspawn.getActualUnitType(templateUnitName)
    local unitMap = {
        ["FARP Command Post"] = "FARP CP Blindage",
        ["FARP Fuel Depot"] = "FARP Fuel Depot", 
        ["FARP Ammo Dump Coating"] = "FARP Ammo Dump Coating",
        ["FARP Tent"] = "FARP Tent",
        -- Add other mappings as needed
    }
    
    return unitMap[templateUnitName] or templateUnitName
end

function markspawn.isStaticObject(unitTypeName)
    -- Common static object patterns
    local staticPatterns = {
        "FARP", "Tent", "Depot", "Dump", "Command", "Post", "Fuel", "Ammo", 
        "Barracks", "Hangar", "Warehouse", "Shelter", "Tower", "Container"
    }
    
    -- Check if unit type name contains any static pattern
    unitTypeName = unitTypeName:lower()
    for _, pattern in ipairs(staticPatterns) do
        if unitTypeName:find(pattern:lower()) then
            return true
        end
    end
    
    -- Also check against the database STATIC category
    if markspawn.unitDatabase and markspawn.unitDatabase.STATIC then
        for _, staticName in ipairs(markspawn.unitDatabase.STATIC) do
            if staticName:lower() == unitTypeName then
                return true
            end
        end
    end
    
    return false
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
    
    -- Check if this is a tanker unit
    if unitType == "KC-135MPRS" or unitType == "KC-135" or unitType == "KC-130" or unitType == "S-3B" then
        callsignID = markspawn.callsigns.tanker[name]
        if not callsignID then
            -- Default to Texaco if invalid callsign provided for tanker
            callsignID = 1 -- Texaco
            name = "texaco"
        end
    -- Check if this is an AWACS unit
    elseif unitType == "E-2C" or unitType == "E-3A" or unitType == "A-50" then
        callsignID = markspawn.callsigns.awacs[name]
        if not callsignID then
            -- Default to Overlord if invalid callsign provided for AWACS
            callsignID = 1 -- Overlord
            name = "overlord"
        end
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
    for _, group in ipairs(markspawn.spawnedGroups or {}) do
        local grp = Group.getByName(group.name)
        if grp and grp:isExist() then
            grp:destroy()
        end
    end
    
    for _, static in ipairs(markspawn.spawnedStatics or {}) do
        local staticObj = StaticObject.getByName(static.name)
        if staticObj and staticObj:isExist() then
            staticObj:destroy()
        end
    end

    -- Reset trackers
    markspawn.spawnedGroups = {}
    markspawn.spawnedStatics = {}
    markspawn.notify("All spawned units and templates deleted.", 10, uid)
end

-- Delete by unit type
function markspawn.cmdDeleteByType(params)
    local uid = params.uid
    local unitType = params.unitType
    
    if not unitType then
        markspawn.notify("Error: Please specify unit type to delete", 10, uid)
        return
    end
    
    local deletedCount = 0
    
    -- Delete groups of this type
    for i = #markspawn.spawnedGroups, 1, -1 do
        local group = markspawn.spawnedGroups[i]
        if group.unitType == unitType or group.templateName == unitType then
            local grp = Group.getByName(group.name)
            if grp and grp:isExist() then
                grp:destroy()
                table.remove(markspawn.spawnedGroups, i)
                deletedCount = deletedCount + 1
            end
        end
    end
    
    -- Delete statics of this type
    for i = #markspawn.spawnedStatics, 1, -1 do
        local static = markspawn.spawnedStatics[i]
        if static.type == unitType then
            local staticObj = StaticObject.getByName(static.name)
            if staticObj and staticObj:isExist() then
                staticObj:destroy()
                table.remove(markspawn.spawnedStatics, i)
                deletedCount = deletedCount + 1
            end
        end
    end
    
    markspawn.notify("Deleted " .. deletedCount .. " objects of type: " .. unitType, 10, uid)
end

-- Delete templates only
function markspawn.cmdDeleteTemplates(params)
    local uid = params.uid
    local deletedCount = 0
    
    for i = #markspawn.spawnedGroups, 1, -1 do
        local group = markspawn.spawnedGroups[i]
        if group.isTemplate then
            local grp = Group.getByName(group.name)
            if grp and grp:isExist() then
                grp:destroy()
                table.remove(markspawn.spawnedGroups, i)
                deletedCount = deletedCount + 1
            end
        end
    end
    
    markspawn.notify("Deleted " .. deletedCount .. " template groups", 10, uid)
end

-- Delete single units only
function markspawn.cmdDeleteSingleUnits(params)
    local uid = params.uid
    local deletedCount = 0
    
    for i = #markspawn.spawnedGroups, 1, -1 do
        local group = markspawn.spawnedGroups[i]
        if not group.isTemplate then
            local grp = Group.getByName(group.name)
            if grp and grp:isExist() then
                grp:destroy()
                table.remove(markspawn.spawnedGroups, i)
                deletedCount = deletedCount + 1
            end
        end
    end
    
    -- Also delete statics (they're always single units)
    for i = #markspawn.spawnedStatics, 1, -1 do
        local static = markspawn.spawnedStatics[i]
        local staticObj = StaticObject.getByName(static.name)
        if staticObj and staticObj:isExist() then
            staticObj:destroy()
            table.remove(markspawn.spawnedStatics, i)
            deletedCount = deletedCount + 1
        end
    end
    
    markspawn.notify("Deleted " .. deletedCount .. " single units and statics", 10, uid)
end

-- Delete specific group by name
function markspawn.cmdDeleteSpecificGroup(params)
    local uid = params.uid
    local groupName = params.groupName
    
    if not groupName then
        markspawn.notify("Error: Please specify group name to delete", 10, uid)
        return
    end
    
    local deleted = false
    
    -- Search through groups
    for i = #markspawn.spawnedGroups, 1, -1 do
        local group = markspawn.spawnedGroups[i]
        if group.name == groupName then
            local grp = Group.getByName(groupName)
            if grp and grp:isExist() then
                grp:destroy()
                table.remove(markspawn.spawnedGroups, i)
                markspawn.notify("Deleted group: " .. groupName, 10, uid)
                deleted = true
                break
            end
        end
    end
    
    -- Search through statics
    if not deleted then
        for i = #markspawn.spawnedStatics, 1, -1 do
            local static = markspawn.spawnedStatics[i]
            if static.name == groupName then
                local staticObj = StaticObject.getByName(groupName)
                if staticObj and staticObj:isExist() then
                    staticObj:destroy()
                    table.remove(markspawn.spawnedStatics, i)
                    markspawn.notify("Deleted static: " .. groupName, 10, uid)
                    deleted = true
                    break
                end
            end
        end
    end
    
    if not deleted then
        markspawn.notify("Group not found: " .. groupName, 10, uid)
    end
end

-- Embarking troops
function markspawn.cmdAssignTransport(params)
    local uid = params.uid
    markspawn.notify("Transport assignment feature coming soon!\nUse DCS built-in transport commands for now.", 15, uid)
end


-- List spawned objects
function markspawn.cmdListSpawned(params)
    local uid = params.uid
    local msg = "-- Currently Spawned --\n"
    
    local templateCount = 0
    local unitCount = 0
    local staticCount = #markspawn.spawnedStatics
    
    for _, group in ipairs(markspawn.spawnedGroups) do
        if group.isTemplate then
            templateCount = templateCount + 1
        else
            unitCount = unitCount + 1
        end
    end
    
    msg = msg .. "Templates: " .. templateCount .. "\n"
    msg = msg .. "Single Units: " .. unitCount .. "\n"
    msg = msg .. "Static Objects: " .. staticCount .. "\n"
    msg = msg .. "Total: " .. (templateCount + unitCount + staticCount)
    
    markspawn.notify(msg, 15, uid)
end

-- List all groups with details
function markspawn.cmdListAllGroups(params)
    local uid = params.uid
    local page = params.page or 1
    
    if #markspawn.spawnedGroups == 0 and #markspawn.spawnedStatics == 0 then
        markspawn.notify("No spawned groups found.", 10, uid)
        return
    end
    
    local allItems = {}
    
    -- Add groups
    for _, group in ipairs(markspawn.spawnedGroups) do
        local itemType = group.isTemplate and "TEMPLATE" or "UNIT"
        table.insert(allItems, {
            name = group.name,
            display = group.displayName .. " (" .. itemType .. ")",
            type = "group"
        })
    end
    
    -- Add statics
    for _, static in ipairs(markspawn.spawnedStatics) do
        table.insert(allItems, {
            name = static.name,
            display = static.type .. " (STATIC)",
            type = "static"
        })
    end
    
    -- Pagination
    local chunkSize = 15
    local startIndex = (page - 1) * chunkSize + 1
    local endIndex = math.min(startIndex + chunkSize - 1, #allItems)
    
    if startIndex > #allItems then
        markspawn.notify("No more groups to display.", 10, uid)
        return
    end
    
    local msg = string.format("-- Spawned Groups Page %d --\n", page)
    for i = startIndex, endIndex do
        local item = allItems[i]
        msg = msg .. string.format("%d. %s\n", i, item.display)
    end
    
    if endIndex < #allItems then
        msg = msg .. string.format("\n... %d more groups", #allItems - endIndex)
    end
    
    msg = msg .. "\n\nUse: /spawn delete,group=GROUP_NAME to delete specific group"
    
    markspawn.notify(msg, 30, uid)
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

    JTAC Special:
    spawn,type=JTAC,country=C,freq=FREQ,laser=CODE,marktype=TYPE
    (marktype: all, laser, smoke, infrared)

    Delete Specific Group:
    spawn delete,group=GROUP_NAME
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

     -- Transport assignment menu
    local transportMenu = missionCommands.addSubMenuForGroup(groupId, "Transport Assignment", cleanupMenu)
    
    missionCommands.addCommandForGroup(groupId, "List Available Infantry", transportMenu, markspawn.cmdAssignTransport, { uid = uid })
    
    -- Add menu items for each available infantry group
    if markspawn.embarkableGroups and #markspawn.embarkableGroups > 0 then
        for i, infantry in ipairs(markspawn.embarkableGroups) do
            missionCommands.addCommandForGroup(groupId, 
                "Transport " .. infantry.groupName, 
                transportMenu, 
                markspawn.cmdAssignTransportToList, 
                { uid = uid, infantryIndex = i }
            )
        end
    end
    -- Enhanced cleanup menu
    local cleanupMenu = missionCommands.addSubMenuForGroup(groupId, "Selective Cleanup", root)

    -- List spawned objects
    missionCommands.addCommandForGroup(groupId, "List Spawned Objects", cleanupMenu, markspawn.cmdListSpawned, { uid = uid })
    missionCommands.addCommandForGroup(groupId, "List All Groups", cleanupMenu, markspawn.cmdListAllGroups, { uid = uid })

    -- Existing delete all
    missionCommands.addCommandForGroup(groupId, "Delete ALL Spawned Units", cleanupMenu, markspawn.cmdDeleteAll, { uid = uid })

    -- New selective options
    missionCommands.addCommandForGroup(groupId, "Delete Templates Only", cleanupMenu, markspawn.cmdDeleteTemplates, { uid = uid })
    missionCommands.addCommandForGroup(groupId, "Delete Single Units Only", cleanupMenu, markspawn.cmdDeleteSingleUnits, { uid = uid })

    -- Delete by type submenu
    local deleteByTypeMenu = missionCommands.addSubMenuForGroup(groupId, "Delete by Unit Type", cleanupMenu)

    -- Add common unit types to the menu
    local commonTypes = {"E-2C", "E-3A", "A-50", "KC-135", "KC-135MPRS", "KC-130", "S-3B", "JTAC"}
    for _, unitType in ipairs(commonTypes) do
        missionCommands.addCommandForGroup(groupId, "Delete " .. unitType, deleteByTypeMenu, 
            markspawn.cmdDeleteByType, { uid = uid, unitType = unitType })
    end
    
    -- Individual deletion info
    missionCommands.addCommandForGroup(groupId, "Delete Specific Group...", cleanupMenu, function()
        markspawn.notify("Use text command on Mark Label:\n 'spawn delete,group=GROUP_NAME'\nexample: spawn delete,group=US_Infantry_5212", 15, uid)
    end, { uid = uid })
end

---------------------------------------------------------------------------------------------------
-- Unit Tasking & Setup Functions
---------------------------------------------------------------------------------------------------
markspawn.tasking = {}

--- Embark infantry
-- Enhanced infantry embarkation setup
function markspawn.setupInfantryEmbarkation(group, controller, params, unitId)
    local groupName = group:getName()
    local groupId = group:getID()
    local groupPos = group:getUnit(1):getPoint()
    
    -- List of infantry unit types that should be embarkable
    local infantryTypes = {
        "Soldier AK", "Soldier M249", "Soldier M4 GRG", "Soldier M4", 
        "Soldier RPG", "Soldier stinger", "Infantry AK Ins", "Infantry AK ver2", 
        "Infantry AK ver3", "Infantry AK", "Paratrooper"
    }
    
    -- Set embarkation task for each individual infantry unit in the group
    local units = group:getUnits()
    if units then
        for i, unit in ipairs(units) do
            if unit and unit:isExist() then
                local unitType = unit:getTypeName()
                
                -- Check if this unit type is in our infantry list
                local isInfantryUnit = false
                for _, infantryType in ipairs(infantryTypes) do
                    if unitType == infantryType then
                        isInfantryUnit = true
                        break
                    end
                end
                
                if isInfantryUnit then
                    local unitController = unit:getController()
                    if unitController then
                        local embarkTask = {
                            id = 'EmbarkToTransport',
                            params = {
                                zoneRadius = 1500,
                                x = groupPos.x,
                                y = groupPos.z
                            }
                        }
                        unitController:setTask(embarkTask)
                    end
                end
            end
        end
    end
    
    -- Store infantry group info for tracking
    if not markspawn.embarkableGroups then
        markspawn.embarkableGroups = {}
    end
    table.insert(markspawn.embarkableGroups, {
        groupId = groupId,
        groupName = groupName,
        position = groupPos,
        spawnTime = timer.getTime(),
        radius = 1500
    })
    
    markspawn.notify("Infantry group " .. groupName .. " ready for embarkation\nEmbark radius: 1500m from spawn position\nUse F7 menu to assign transport", 15, unitId)
end

-- Function to assign transport to infantry
function markspawn.cmdAssignTransport(params)
    local uid = params.uid
    
    if not markspawn.embarkableGroups or #markspawn.embarkableGroups == 0 then
        markspawn.notify("No infantry groups available for transport assignment.", 10, uid)
        return
    end
    
    -- For now, just show available infantry groups
    local msg = "Available infantry groups for transport:\n"
    for i, infantry in ipairs(markspawn.embarkableGroups) do
        msg = msg .. string.format("%d. %s (ID: %d)\n", i, infantry.groupName, infantry.groupId)
    end
    msg = msg .. "\nUse DCS F10 menu: F10 -> Other -> Assign Transport to Group"
    
    markspawn.notify(msg, 20, uid)
end

-- Function to create transport task for helicopters
function markspawn.createTransportTask(helicopterGroup, infantryGroupId, destination)
    local controller = helicopterGroup:getController()
    if not controller then return false end
    
    local infantryGroup = Group.getByID(infantryGroupId)
    if not infantryGroup or not infantryGroup:isExist() then return false end
    
    local infantryPos = infantryGroup:getUnit(1):getPoint()
    local destPos = destination or infantryPos  -- Default to pickup location if no destination
    
    local transportTask = {
        id = 'Embarking',
        params = {
            x = infantryPos.x,
            y = infantryPos.z,
            groupsForEmbarking = { infantryGroupId },
            duration = 300,  -- 5 minutes wait time
            distributionFlag = false
        }
    }
    
    controller:setTask(transportTask)
    return true
end

-- Enhanced transport assignment command with list of infantry groups
function markspawn.cmdAssignTransportToList(params)
    local uid = params.uid
    local infantryIndex = params.infantryIndex
    
    if not markspawn.embarkableGroups or not markspawn.embarkableGroups[infantryIndex] then
        markspawn.notify("Invalid infantry group selection.", 10, uid)
        return
    end
    
    local infantry = markspawn.embarkableGroups[infantryIndex]
    local playerUnit = Unit.getByName(Unit.getID(uid))
    
    if not playerUnit then
        markspawn.notify("Player unit not found.", 10, uid)
        return
    end
    
    local playerGroup = playerUnit:getGroup()
    if not playerGroup then
        markspawn.notify("Player group not found.", 10, uid)
        return
    end
    
    if markspawn.createTransportTask(playerGroup, infantry.groupId, infantry.position) then
        markspawn.notify("Transport task assigned for infantry: " .. infantry.groupName, 15, uid)
        table.remove(markspawn.embarkableGroups, infantryIndex)
    else
        markspawn.notify("Failed to assign transport task.", 10, uid)
    end
end


--- JTAC
function markspawn.setupJTAC(group, controller, params, unitId)
    local groupName = group:getName()
    
    -- Set laser code (default 1688 or custom)
    local laserCode = tonumber(params.laser) or 1688
    
    -- Set radio frequency if provided (default to 30.0 MHz if not specified)
    local frequency = tonumber(params.freq) or 30.0
    
    -- Create FAC task for JTAC
    local jtacTask = {
        id = 'FAC',  -- Corrected to uppercase 'FAC'
        params = {
            frequency = frequency * 1000000,  -- Convert MHz to Hz
            modulation = 0,  -- 0 = AM, 1 = FM
            laserCode = laserCode
        }
    }
    
    controller:setTask(jtacTask)
    
    markspawn.notify("JTAC " .. groupName .. " activated as FAC\nFrequency: " .. frequency .. " MHz AM\nLaser Code: " .. laserCode, 15, unitId)
end

function markspawn.setJTACMarkingType(controller, markType)
    -- This function is no longer needed as marking is handled by DCS FAC task
    return
end

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

    -- JTAC specific setup
    if unitType == "JTAC" then
        markspawn.setupJTAC(newGroup, controller, params, unitId)
        return
    end

    -- Infantry specific setup - auto embarkation readiness
    local isInfantry = false
    local infantryTypes = {
        "Soldier AK", "Soldier M249", "Soldier M4 GRG", "Soldier M4", 
        "Soldier RPG", "Soldier stinger", "Infantry AK Ins", "Infantry AK ver2", 
        "Infantry AK ver3", "Infantry AK", "Paratrooper", "Marine", "Special Forces"
    }
    
    -- Check if unit type is in our infantry list
    if unitType then
        for _, infantryType in ipairs(infantryTypes) do
            if unitType == infantryType then
                isInfantry = true
                break
            end
        end
    end

    -- Template specific setup - check if template contains any infantry units
    if params.temp then
        local templateData = markspawn.unitDatabase.TEMPLATES[params.temp]
        if templateData then
            for _, unitT in pairs(templateData.units) do
                for _, infantryType in ipairs(infantryTypes) do
                    if unitT.name == infantryType then
                        isInfantry = true
                        break
                    end
                end
                if isInfantry then break end
            end
        end
    end

    if isInfantry then
        markspawn.setupInfantryEmbarkation(newGroup, controller, params, unitId)
        return
    end
    
    -- Check if unit type indicates infantry
    if unitType and (unitType:lower():find("infantry") or unitType:lower():find("soldier") or 
        unitType:lower():find("rifle") or unitType:lower():find("machinegun") or 
        unitType:lower():find("at") or unitType:lower():find("aa") or
        unitType:lower():find("mortar") or unitType:lower():find("sniper")) then
        isInfantry = true
    end

    -- Template specific setup - check if template name contains "infantry"
    if params.temp then
        local templateName = params.temp:lower()
        if templateName:find("infantry") or templateName:find("soldier") or 
           templateName:find("rifle") or templateName:find("squad") or
           templateName:find("platoon") or templateName:find("company") then
            isInfantry = true
        else
            -- Also check individual units in the template
            local templateData = markspawn.unitDatabase.TEMPLATES[params.temp]
            if templateData then
                for _, unitT in pairs(templateData.units) do
                    if unitT.name and (unitT.name:lower():find("infantry") or unitT.name:lower():find("soldier") or 
                       unitT.name:lower():find("rifle") or unitT.name:lower():find("machinegun") or 
                       unitT.name:lower():find("at") or unitT.name:lower():find("aa") or
                       unitT.name:lower():find("mortar") or unitT.name:lower():find("sniper")) then
                        isInfantry = true
                        break
                    end
                end
            end
        end
    end

    -- REMOVED THE EXTRA TWO 'end' STATEMENTS HERE

    if isInfantry then
        markspawn.setupInfantryEmbarkation(newGroup, controller, params, unitId)
        return
    end

    if params.category == Group.Category.AIRPLANE or params.category == Group.Category.HELICOPTER then
        local taskTable
        
        -- Check for tanker types
        if unitType == "KC-135MPRS" or unitType == "KC-135" or unitType == "KC-130" or unitType == "S-3B" then
            taskTable = markspawn.tasking.createTankerTask(spawnLocation, params)
            markspawn.notify("Tasking " .. groupName .. " as TANKER.", 10, unitId)
            if params.tacan then
                local channelStr, band = params.tacan:match("(%d+)(%a)")
                if channelStr and band then
                    controller:setCommand({id = 'ActivateBeacon', params = {type = 4, system = 2, channel = tonumber(channelStr), mode = band:upper(), callsign = "TKR"}})
                    markspawn.notify(groupName .. " TACAN activated on " .. params.tacan:upper(), 10, unitId)
                end
            end
        -- Check for AWACS types
        elseif unitType == "E-2C" or unitType == "E-3A" or unitType == "A-50" then
            taskTable = markspawn.tasking.createAWACSTask(spawnLocation, params)
            markspawn.notify("Tasking " .. groupName .. " as AWACS.", 10, unitId)
            
            -- EPLRS is enabled by default for AWACS in DCS
            markspawn.notify(groupName .. " EPLRS enabled by default for AWACS.", 10, unitId)
            
            if params.tacan then
                local channelStr, band = params.tacan:match("(%d+)(%a)")
                if channelStr and band then
                    controller:setCommand({id = 'ActivateBeacon', params = {type = 4, system = 2, channel = tonumber(channelStr), mode = band:upper(), callsign = "AWACS"}})
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

function markspawn.tasking.createAWACSTask(spawnPos, params)
    local headingRad = math.rad(tonumber(params.hdg) or 360)
    local orbitRadius = 20 * 1852 -- Larger orbit for AWACS
    local orbitCenter = {x = spawnPos.x + math.cos(headingRad) * orbitRadius, z = spawnPos.z + math.sin(headingRad) * orbitRadius}
    local speedMPS = (tonumber(params.spd) or 300) * 0.514444 -- Slower speed for AWACS
    local groundY = land.getHeight({x = orbitCenter.x, y = orbitCenter.z})
    local altAGL_Meters = (tonumber(params.alt) or 25000) * 0.3048 -- Higher altitude for AWACS
    local altMSL = groundY + altAGL_Meters
    
    return {id = 'Orbit', params = {pattern = 'Circle', point = { x = orbitCenter.x, y = orbitCenter.z }, speed = speedMPS, altitude = altMSL}}
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

    local baseHeadingRad = math.rad(tonumber(params.hdg) or 0)
    
    -- Spawn each unit individually
    for _, unitT in pairs(templateData.units) do
        local unitHeadingRad = baseHeadingRad + math.rad(unitT.heading or 0)
        if unitHeadingRad > (2 * math.pi) then unitHeadingRad = unitHeadingRad - (2 * math.pi) end
        if unitHeadingRad < 0 then unitHeadingRad = unitHeadingRad + (2 * math.pi) end

        local unitX = location.x + ((unitT.dx or 0) * math.cos(baseHeadingRad) - (unitT.dy or 0) * math.sin(baseHeadingRad))
        local unitZ = location.z + ((unitT.dx or 0) * math.sin(baseHeadingRad) + (unitT.dy or 0) * math.cos(baseHeadingRad))
        
        local actualUnitType = markspawn.getActualUnitType(unitT.name)
        local isStatic = markspawn.isStaticObject(actualUnitType)
        
        if isStatic then
            -- Spawn as static object
            local staticName = actualUnitType .. "_" .. math.random(1000, 9999)
            local newStatic = {
                type = actualUnitType,
                name = staticName,
                x = unitX,
                y = unitZ,
                heading = unitHeadingRad
            }
            if coalition.addStaticObject(countryID, newStatic) then
                table.insert(markspawn.spawnedStatics, {
                    name = staticName,
                    type = actualUnitType,
                    spawnTime = timer.getTime(),
                    spawnedBy = unitId
                })
            end
        else
            -- Spawn as single unit group (for now)
            local unitName = actualUnitType .. "_" .. math.random(1000, 9999)
            local unitData = {
                type = actualUnitType,
                name = unitName,
                x = unitX,
                y = unitZ,
                heading = unitHeadingRad,
                skill = unitT.skill or "Average"
            }
            
            local groupName = unitName
            local newGroup = { name = groupName, task = "Ground Attack", units = {unitData} }
            
            local result = coalition.addGroup(countryID, Group.Category.GROUND, newGroup)
            if result then
                table.insert(markspawn.spawnedGroups, {
                    name = result:getName(),
                    displayName = actualUnitType,
                    unitType = actualUnitType,
                    isTemplate = false,
                    spawnTime = timer.getTime(),
                    spawnedBy = unitId,
                    units = 1
                })
            end
        end
    end
    
    markspawn.notify("Spawned template: " .. templateName, 10, unitId)
end

-- Helper function to check if a unit type is a static object
-- Enhanced static object detection
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
        if coalition.addStaticObject(countryID, newStatic) then
            markspawn.notify("Spawned static object: " .. unitType, 10, unitId)
            table.insert(markspawn.spawnedStatics, {
                name = newStatic.name,
                type = unitType,
                spawnTime = timer.getTime(),
                spawnedBy = unitId
            })
        else
            markspawn.notify("Failed to spawn static object: " .. unitType, 10, unitId)
        end
    else
        local groupName = unitType .. "_" .. math.random(1000, 9999)
        local callsignTable
        local amount = tonumber(params.amount) or 1
        
        local isAircraft = unitCategory == Group.Category.AIRPLANE or unitCategory == Group.Category.HELICOPTER
        local callsignStr = params.callsign
        if isAircraft or unitType == "JTAC" then
            if not callsignStr then
                -- Default callsigns for tankers
                if unitType == "KC-135MPRS" or unitType == "KC-135" or unitType == "KC-130" or unitType == "S-3B" then
                    callsignStr = "Texaco1-1"
                -- Default callsigns for AWACS
                elseif unitType == "E-2C" or unitType == "E-3A" or unitType == "A-50" then
                    callsignStr = "Overlord1-1"
                elseif unitType == "JTAC" then
                    callsignStr = "Axeman1-1"
                else
                    callsignStr = "Enfield" .. math.random(1,9) .. "-1"
                end
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
                -- Set appropriate altitude based on unit type
                local defaultAlt
                if unitType == "E-2C" or unitType == "E-3A" or unitType == "A-50" then
                    defaultAlt = 25000 -- AWACS altitude
                elseif unitType == "KC-135MPRS" or unitType == "KC-135" or unitType == "KC-130" or unitType == "S-3B" then
                    defaultAlt = 20000 -- Tanker altitude
                else
                    defaultAlt = (unitCategory == Group.Category.AIRPLANE and 3000 or 300)
                end
                unitData.alt = groundY + (tonumber(params.alt) or defaultAlt) * 0.3048
                
                -- Set appropriate speed based on unit type
                local defaultSpeed
                if unitType == "E-2C" or unitType == "E-3A" or unitType == "A-50" then
                    defaultSpeed = 300 -- AWACS speed
                elseif unitType == "KC-135MPRS" or unitType == "KC-135" or unitType == "KC-130" or unitType == "S-3B" then
                    defaultSpeed = 350 -- Tanker speed
                else
                    defaultSpeed = (unitCategory == Group.Category.AIRPLANE and 430 or 135)
                end
                unitData.speed = (tonumber(params.spd) or defaultSpeed) * 0.514444
            elseif unitCategory == Group.Category.GROUND and i > 1 then
                local spacing = 200
                local distance = (i - 1) * spacing
                unitData.x = location.x - math.cos(headingRad) * distance
                unitData.y = location.z - math.sin(headingRad) * distance
            end
            table.insert(unitsTable, unitData)
        end

        local groupTask = "Ground Attack"
        -- Set task to Refueling for tanker types
        if unitType == "KC-135MPRS" or unitType == "KC-135" or unitType == "KC-130" or unitType == "S-3B" then
            groupTask = "Refueling"
        -- Set task to AWACS for AWACS types
        elseif unitType == "E-2C" or unitType == "E-3A" or unitType == "A-50" then
            groupTask = "AWACS"
        -- Set task to FAC for JTAC
        elseif unitType == "JTAC" then
            groupTask = "FAC"
        end
        
        local newGroup = { name = groupName, task = groupTask, units = unitsTable }
        if isAircraft and amount > 1 then
            newGroup.formation = "Echelon Right"
        end
        
        local result = coalition.addGroup(countryID, unitCategory, newGroup)
        if result then
            local actualGroupName = result:getName()
            markspawn.notify("Spawned group: " .. actualGroupName .. " with " .. amount .. " unit(s).", 10, unitId)
            table.insert(markspawn.spawnedGroups, {
                name = actualGroupName,
                displayName = groupName,
                unitType = unitType,
                isTemplate = false,
                spawnTime = timer.getTime(),
                spawnedBy = unitId,
                category = unitCategory,
                units = amount
            })
            
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

        -- Check for delete command
        if event.text:lower():startsWith("spawn delete,") then
            local _, _, params_str = event.text:find("spawn delete,(.+)")
            if params_str then
                local params = markspawn.getMessageParameters(params_str)
                if params.group then
                    markspawn.cmdDeleteSpecificGroup({uid = initiatorUnitId, groupName = params.group})
                else
                    markspawn.notify("Usage: spawn delete,group=GROUP_NAME", 10, initiatorUnitId)
                end
            end
            return
        end

        -- Original spawn command
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
        -- Use event.initiator if available, otherwise fall back to getting the unit by ID
        local unit = event.initiator
        if not unit and event.unitID then
            unit = Unit.getByID(event.unitID)
        end
        
        -- Check if unit exists and has getPlayerName method before calling it
        if unit and unit.getPlayerName and unit:getPlayerName() then
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
env.info("GVAW Markspawn v3 - rev 3.0.7 initialized.")
