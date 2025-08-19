-- =========================================================================
-- Fuel Tracking Script using DCS API
-- Tracks fuel percentage of all active aircraft and logs to Logs/fuelstate.log
-- 
--
--
-- Made by EagleEye from DCS Indonesia/Garuda virtual Air Wing
-- =========================================================================

-- Configuration
local checkInterval = 10              -- seconds between fuel checks
local notificationInterval = 10      -- seconds between notifications
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

    -- Mission time string (os.* is blocked in DCS sandbox)
    local seconds = timer.getAbsTime()
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    local currentTime = string.format("%02d:%02d:%02d (mission time)", hours, minutes, secs)

    local logString = string.format("\n--- Fuel Check on %s ---\n", currentTime)
    local notificationString = "Current Fuel Status:\n"
    local unitsInAir = getAirUnits()
    local humanFound = false

    if #unitsInAir > 0 then
        for _, unit in ipairs(unitsInAir) do
            local fuel = unit:getFuel() or 0
            local playerName = unit:getPlayerName()
            local unitType = unit:getDesc().displayName
            local entry

            if playerName then
                entry = string.format("%s in %s: %.1f%%", playerName, unitType, fuel * 100)
                notificationString = notificationString .. entry .. "\n"
                humanFound = true
            else
                entry = string.format("%s (AI) in %s: %.1f%%", unit:getName(), unitType, fuel * 100)
            end

            logString = logString .. entry .. "\n"
        end
    else
        logString = logString .. "No active aircraft found.\n"
        notificationString = "No active aircraft found."
    end

    -- Log to dcs.log
    env.info(logString)

    -- Log to separate fuelstate.log inside /Logs/
    local filePath = lfs.writedir() .. "Logs/fuelstate.log"
    local file = io.open(filePath, "a")
    if file then
        file:write(logString)
        file:close()
    else
        env.info("FuelScript ERROR: Cannot open " .. filePath)
    end

    -- Send notifications (only if humans exist)
    if notificationCounter >= notificationInterval then
        notificationCounter = 0
        if humanFound then
            trigger.action.outText(notificationString, 10, true)
        end
    end

    -- Reschedule
    return timer.getTime() + checkInterval
end

-- =========================================================================
-- Start the script
-- =========================================================================
timer.scheduleFunction(checkFuel, {}, timer.getTime() + checkInterval)
env.info("Fuel tracking script (pure API) started. Interval: " .. checkInterval .. "s")
