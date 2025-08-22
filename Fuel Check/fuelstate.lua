-- =========================================================================
-- Fuel Tracking Script using DCS API
-- Tracks fuel percentage of all active aircraft and logs to Logs/fuelstate.log
-- 
--
--
-- Made by EagleEye from DCS Indonesia/Garuda virtual Air Wing
-- =========================================================================

-- Configuration
local checkInterval = 1              -- seconds between fuel checks
local notificationInterval = 1      -- seconds between notifications
local notificationCounter = 0

-- =========================================================================
-- Helper: Iterate all active air units (airplanes + helicopters)
-- =========================================================================
local function getAirUnits()
    local units = {}
    local coalitions = { coalition.side.RED, coalition.side.BLUE, coalition.side.NEUTRAL }

    for _, side in ipairs(coalitions) do
        local groups = coalition.getGroups(side, Group.Category.AIRPLANE)
        for _, group in ipairs(groups) do
            for _, unit in ipairs(group:getUnits()) do
                if unit and unit:isExist() then
                    table.insert(units, unit)
                end
            end
        end

        local heligroups = coalition.getGroups(side, Group.Category.HELICOPTER)
        for _, group in ipairs(heligroups) do
            for _, unit in ipairs(group:getUnits()) do
                if unit and unit:isExist() then
                    table.insert(units, unit)
                end
            end
        end
    end

    return units
end

-- =========================================================================
-- Main function
-- =========================================================================
local function checkFuel()
    notificationCounter = notificationCounter + checkInterval

    -- Mission time string
    local seconds = timer.getAbsTime()
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    local currentTime = string.format("%02d:%02d:%02d", hours, minutes, secs)

    local unitsInAir = getAirUnits()
    local notificationString = "Current Fuel Status:\n"
    local humanFound = false

    -- Track already written players to avoid duplicates
    local seenPlayers = {}

    -- Open file once for appending
    local filePath = lfs.writedir() .. "Logs/fuelstate.log"
    local file = io.open(filePath, "a")

    if #unitsInAir > 0 and file then
        for _, unit in ipairs(unitsInAir) do
            local fuel = unit:getFuel() or 0
            local playerName = unit:getPlayerName()
            local unitType = unit:getDesc().displayName

            if playerName and not seenPlayers[playerName] then
                local fuelPercent = string.format("%.1f", fuel * 100)
                local logLine = string.format("%s,%s,%s\n", currentTime, playerName, fuelPercent)

                file:write(logLine)

                notificationString = notificationString ..
                    string.format("%s in %s: %s%%\n", playerName, unitType, fuelPercent)
                humanFound = true
                seenPlayers[playerName] = true
            end
        end
        file:close()
    else
        notificationString = "No active aircraft found."
    end

    -- Notifications
    if notificationCounter >= notificationInterval then
        notificationCounter = 0
        if humanFound then
            trigger.action.outText(notificationString, 10, true)
        end
    end

    return timer.getTime() + checkInterval
end

-- =========================================================================
-- Start the script
-- =========================================================================
timer.scheduleFunction(checkFuel, {}, timer.getTime() + checkInterval)
env.info("Fuel tracking script (pure API) started. Interval: " .. checkInterval .. "s")
