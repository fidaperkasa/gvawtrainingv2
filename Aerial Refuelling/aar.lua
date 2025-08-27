----------------------------------------------------------------
-- AAR Tracking Script (RefuelTracker) RCv1.0.3 stable 27/08/2025 07.22PM
-- FIX 10.27PM
-- FIX 28/08/2025 01:40AM | FIX 02:28AM
-- by EagleEye
----------------------------------------------------------------
----------------------------------------------------------------

local RefuelTracker = {}
RefuelTracker.sessions = {}       -- [uid] = session
RefuelTracker.stats = {}          -- [playerName] = stats
local FuelWatch = {}              -- [uid] = { lastFuel, risingTime, stillTime }

-- === CONFIG ===
local MONITOR_INTERVAL = 1        -- seconds between fuel polls
local CONTACT_CONFIRM   = 3       -- sec of continuous fuel increase before "contact"
local STOP_TOLERANCE    = 60      -- sec without fuel increase before "disconnect"
local SESSION_CLEANUP_INTERVAL = 60 -- Clean up old sessions every minute

-- Logging File
local function getLogFileName()
    local timestamp = os.date("%Y%m%d-%H%M%S")  -- YYYYMMDD-HHMMSS
    local logDir = lfs.writedir() .. "/Logs/"
    
    if not lfs.attributes(logDir) then
        lfs.mkdir(logDir)
    end
    
    return logDir .. "aar-" .. timestamp .. ".log"
end

local AAR_LOG_PATH = getLogFileName()
env.info("[AAR] Logging to: " .. AAR_LOG_PATH)

----------------------------------------------------------------
-- Utility
----------------------------------------------------------------
local function isPlayerUnit(u)
    if not u then return false end
    local success, result = pcall(function()
        return u:isExist() and u:getPlayerName() and u:getCategory() == Object.Category.UNIT
    end)
    return success and result or false
end

local function isTankerUnit(u)
    if not u or not u:isExist() then return false end
    local typeName = u:getTypeName() or ""
    return typeName:find("KC") or typeName:find("Tanker") or typeName:find("S3") or typeName:find("Il78")
end

local function safeName(u)
    if not u then return "Unknown" end
    local p = u:getPlayerName()
    return p or u:getName() or ("Unit #" .. tostring(u:getID()))
end

local function getCoalitionName(coa)
    if coa == coalition.side.RED then return "RED"
    elseif coa == coalition.side.BLUE then return "BLUE"
    elseif coa == coalition.side.NEUTRAL then return "NEUTRAL"
    else return "UNKNOWN" end
end

local function aarLogLine(line)
    local ts = os.date("[%Y-%m-%d %H:%M:%S] ")
    local ok, err = pcall(function()
        local fh = io.open(AAR_LOG_PATH, "a")
        if fh then
            fh:write(ts .. line .. "\n")
            fh:close()
        end
    end)
    if not ok then
        env.info("[AAR] Failed writing aar.log: " .. tostring(err))
    end
end

----------------------------------------------------------------
-- Session + Stats management
----------------------------------------------------------------
local function ensureSession(u)
    if not isPlayerUnit(u) then return nil end
    local uid = u:getID()
    
    -- Check if we need to create a new session (no active session or previous one finalized)
    if not RefuelTracker.sessions[uid] or RefuelTracker.sessions[uid].finalized then
        RefuelTracker.sessions[uid] = {
            uid = uid,
            unit = u,
            playerName = safeName(u),
            coalition = u:getCoalition(),
            startFuel = u:getFuel() or 0,
            contactActive = false,
            fuelStart = nil,
            fuelEnd = nil,
            totalFuelTaken = 0,
            contactTime = nil,
            disconnectTime = nil,
            totalTime = 0,
            totalContacts = 0,
            lastUpdate = timer.getTime(),
            initialFuel = u:getFuel() or 0,
            finalized = false,
            lastDisconnectTime = 0  -- Track when last disconnect happened
        }
        FuelWatch[uid] = { lastFuel = u:getFuel() or 0, risingTime = 0, stillTime = 0 }
        env.info(string.format("[AAR] New session created for %s (UID: %d)", safeName(u), uid))
    end
    
    RefuelTracker.sessions[uid].lastUpdate = timer.getTime()
    return RefuelTracker.sessions[uid]
end

local function ensureStats(name)
    if not RefuelTracker.stats[name] then
        RefuelTracker.stats[name] = { 
            totalFuel = 0, 
            totalContacts = 0, 
            bestRefuel = 0, 
            totalTime = 0,
            lastFuel = 0,
            lastTime = 0,
            lastGrade = "N/A"
        }
    end
    return RefuelTracker.stats[name]
end

local function cleanupSession(uid)
    local session = RefuelTracker.sessions[uid]
    if session then
        -- Finalize any active contact before cleanup
        if session.contactActive and not session.finalized then
            session.finalized = true
            session.contactActive = false
            session.disconnectTime = timer.getTime()
            local currentFuel = session.unit:isExist() and session.unit:getFuel() or session.fuelStart or 0
            local gained = (currentFuel - (session.fuelStart or 0))
            
            -- Ignore negative fuel values (external tanks drop, loadout changes)
            gained = math.max(0, gained)
            
            if gained > 0 then
                local dur = session.disconnectTime - (session.contactTime or session.disconnectTime)
                local st = ensureStats(session.playerName)
                st.totalFuel = st.totalFuel + gained
                st.totalContacts = st.totalContacts + 1
                st.totalTime = st.totalTime + dur
                st.lastFuel = gained
                st.lastTime = dur
                st.lastGrade = "Incomplete"
                
                if gained > st.bestRefuel then 
                    st.bestRefuel = gained 
                end
                
                aarLogLine(string.format("FORCED DISCONNECT: %s took %.3f fuel over %.1fs (session cleanup)",
                    session.playerName, gained, dur))
            end
        end
        
        RefuelTracker.sessions[uid] = nil
        FuelWatch[uid] = nil
        env.info(string.format("[AAR] Session cleaned up for UID: %d", uid))
    end
end

local function onDisconnect(s)
    if not s.contactActive or not isPlayerUnit(s.unit) or s.finalized then return end
    
    s.finalized = true
    s.contactActive = false
    s.disconnectTime = timer.getTime()
    s.lastDisconnectTime = s.disconnectTime  -- Store disconnect time for cooldown
    s.fuelEnd = s.unit:getFuel() or 0
    local dur = s.disconnectTime - (s.contactTime or s.disconnectTime)
    
    -- Calculate actual fuel gained (0.0-1.0 scale)
    local gained = (s.fuelEnd - (s.fuelStart or s.fuelEnd))
    gained = math.max(0, gained)

    -- Save stats for F10 / leaderboard
    local st = ensureStats(s.playerName)
    st.totalFuel = st.totalFuel + gained
    st.totalContacts = st.totalContacts + 1
    st.totalTime = st.totalTime + dur
    st.lastFuel = gained
    st.lastTime = dur
    
    -- Determine grade based on fuel stability (time)
    local grade = "Poor"
    if dur >= 30 then
        grade = "Excellent"
    elseif dur >= 15 then
        grade = "Good"
    end
    st.lastGrade = grade
    
    if gained > st.bestRefuel then 
        st.bestRefuel = gained 
    end

    -- Log and display result
    local msg = string.format(
        "[AAR] %s\nFuel Taken: %.3f\nTime of Taking Fuel: %.1fs\nGrade: %s\nTotal Contacts: %d",
        s.playerName,
        gained,
        dur,
        grade,
        st.totalContacts
    )
    
    trigger.action.outText(msg, 15)
    aarLogLine(string.format("DISCONNECT: %s took %.3f fuel over %.1fs (Grade: %s)",
        s.playerName, gained, dur, grade))
        
    -- Immediately clean up this session to allow new ones
    cleanupSession(s.uid)
end

----------------------------------------------------------------
-- Menu Command Handlers
----------------------------------------------------------------
local function cmdShowMyStats(uid)
    local s = RefuelTracker.sessions[uid]
    local name = s and s.playerName or "Unknown"
    local st = ensureStats(name)
    
    local txt = string.format(
        "[AAR] Statistics for %s:\n" ..
        "Total Fuel Taken: %.3f\n" ..
        "Total Contacts: %d\n" ..
        "Best Refuel: %.3f\n" ..
        "Total Time: %.1fs\n" ..
        "Last Refuel: %.3f (%.1fs) - Grade: %s",
        name,
        st.totalFuel,
        st.totalContacts,
        st.bestRefuel,
        st.totalTime,
        st.lastFuel,
        st.lastTime,
        st.lastGrade
    )
    
    trigger.action.outTextForUnit(uid, txt, 15)
end

local function cmdShowLeaderboard(uid)
    local leaderboard = {}
    for name, st in pairs(RefuelTracker.stats) do
        table.insert(leaderboard, { name = name, total = st.totalFuel, contacts = st.totalContacts })
    end
    table.sort(leaderboard, function(a, b) return a.total > b.total end)

    local txt = "[AAR] Leaderboard (Top Refuelers):\n"
    for i, v in ipairs(leaderboard) do
        txt = txt .. string.format("%d. %s - %.3f (%d contacts)\n", i, v.name, v.total, v.contacts)
        if i >= 10 then break end
    end
    
    if #leaderboard == 0 then
        txt = txt .. "No refueling data yet."
    end
    
    trigger.action.outTextForUnit(uid, txt, 15)
end

-- Handler for radio/F10 commands
local function displayStats(vars)
    local uid = vars.uid
    local t = vars.type

    if t == "my" then
        cmdShowMyStats(uid)
    elseif t == "leaderboard" then
        cmdShowLeaderboard(uid)
    end
end

----------------------------------------------------------------
-- F10 / Radio Menu
----------------------------------------------------------------
local function addMenus(u)
    if not isPlayerUnit(u) then return end
    local uid = u:getID()

    local root = missionCommands.addSubMenuForGroup(u:getGroup():getID(), "AAR Statistics")
    missionCommands.addCommandForGroup(u:getGroup():getID(), "My Statistics", root, displayStats, { uid = uid, type = "my" })
    missionCommands.addCommandForGroup(u:getGroup():getID(), "Leaderboards", root, displayStats, { uid = uid, type = "leaderboard" })
end

----------------------------------------------------------------
-- Contact + Disconnect logic
----------------------------------------------------------------
local function onContact(s)
    if not isPlayerUnit(s.unit) then return end
    
    -- Reset finalized flag when starting a new contact
    s.finalized = false
    s.contactActive = true
    s.contactTime = timer.getTime()
    s.fuelStart = s.unit:getFuel() or 0

    local msg = string.format("[AAR] %s (Coalition: %s) CONTACT, fuel=%.3f",
        s.playerName, getCoalitionName(s.coalition), s.fuelStart)
    trigger.action.outText(msg, 10)
    aarLogLine("CONTACT: " .. msg)
end

----------------------------------------------------------------
-- Event Handlers
----------------------------------------------------------------
function RefuelTracker:onEvent(e)
    -- Add more robust initiator validation
    if not e or not e.initiator then return end
    
    -- Check if initiator is a valid object before proceeding
    local ok, result = pcall(function() return e.initiator.getCategory and e.initiator:getCategory() end)
    if not ok then return end  -- Invalid object, skip processing
    
    -- Filter tanker STOP events - only process player units
    if e.id == world.event.S_EVENT_REFUELING_STOP then
        if isTankerUnit(e.initiator) then
            -- Ignore tanker-side STOP events completely
            return
        end
    end
    
    if not isPlayerUnit(e.initiator) then return end
    local u = e.initiator
    
    if e.id == world.event.S_EVENT_BIRTH then
        ensureSession(u)
        addMenus(u)

    elseif e.id == world.event.S_EVENT_REFUELING then
        -- Log refueling start event
        local session = ensureSession(u)
        if session then
            aarLogLine(string.format("REFUELING START: %s (Coalition: %s)", 
                session.playerName, getCoalitionName(session.coalition)))
        end

    elseif e.id == world.event.S_EVENT_REFUELING_STOP then
        -- Immediate disconnect on REFUELING_STOP event (player side only)
        local session = ensureSession(u)
        if session and session.contactActive and not session.finalized then
            aarLogLine(string.format("REFUELING STOP: %s (Coalition: %s) - Immediate disconnect", 
                session.playerName, getCoalitionName(session.coalition)))
            onDisconnect(session)
        end

    elseif e.id == world.event.S_EVENT_DEAD or
           e.id == world.event.S_EVENT_CRASH or
           e.id == world.event.S_EVENT_EJECTION or
           e.id == world.event.S_EVENT_PLAYER_LEAVE_UNIT then
        -- Clean up session when player leaves or unit is destroyed
        local uid = u:getID()
        cleanupSession(uid)
    end
end

----------------------------------------------------------------
-- Fuel Polling Loop with cooldown period
----------------------------------------------------------------
local function pollFuel()
    local currentTime = timer.getTime()
    
    for uid, s in pairs(RefuelTracker.sessions) do
        -- Check if unit still exists and is valid
        if not isPlayerUnit(s.unit) then
            cleanupSession(uid)
        else
            -- Check cooldown period (5 seconds minimum between contacts)
            local shouldProcess = true
            if s.finalized and (currentTime - (s.lastDisconnectTime or 0)) < 5 then
                -- Still in cooldown period, skip processing this session
                shouldProcess = false
            end
            
            if shouldProcess then
                local fuel = s.unit:getFuel() or 0
                local fw = FuelWatch[uid] or { lastFuel = fuel, risingTime = 0, stillTime = 0 }

                if fuel > fw.lastFuel + 0.001 then  -- Small threshold to avoid floating point issues
                    fw.risingTime = fw.risingTime + MONITOR_INTERVAL
                    fw.stillTime = 0
                    
                    -- If we're in cooldown but fuel is rising, create a new session
                    if s.finalized and fw.risingTime >= CONTACT_CONFIRM then  -- based on CONTACT_CONFIRM fuel increasing
                        ensureSession(s.unit)  -- This will create a new session
                        s = RefuelTracker.sessions[uid]  -- Get the new session
                        fw = FuelWatch[uid] or { lastFuel = fuel, risingTime = 0, stillTime = 0 }
                    end
                    
                    if not s.contactActive and fw.risingTime >= CONTACT_CONFIRM and not s.finalized then
                        s.fuelStart = fw.lastFuel
                        onContact(s)
                    end
                elseif math.abs(fuel - fw.lastFuel) < 0.001 then  -- Essentially no change
                    fw.stillTime = fw.stillTime + MONITOR_INTERVAL
                    fw.risingTime = 0
                    
                    if s.contactActive and fw.stillTime >= STOP_TOLERANCE and not s.finalized then
                        aarLogLine(string.format("SAFETY DISCONNECT: %s (timeout after %.1fs)", 
                            s.playerName, fw.stillTime))
                        onDisconnect(s)
                    end
                else
                    -- Fuel decreased, reset counters (external tanks drop, etc.)
                    fw.risingTime = 0
                    fw.stillTime = 0
                end

                fw.lastFuel = fuel
                FuelWatch[uid] = fw
                s.lastUpdate = currentTime
            end
        end
    end
    
    timer.scheduleFunction(pollFuel, {}, timer.getTime() + MONITOR_INTERVAL)
end

----------------------------------------------------------------
-- Session cleanup loop
----------------------------------------------------------------
local function cleanupOldSessions()
    local currentTime = timer.getTime()
    local cleaned = 0
    
    for uid, s in pairs(RefuelTracker.sessions) do
        -- Clean up sessions older than 2 minutes or with invalid units
        if not isPlayerUnit(s.unit) or (currentTime - s.lastUpdate) > 120 then
            cleanupSession(uid)
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        env.info(string.format("[AAR] Cleaned up %d old sessions", cleaned))
    end
    
    timer.scheduleFunction(cleanupOldSessions, {}, timer.getTime() + SESSION_CLEANUP_INTERVAL)
end

----------------------------------------------------------------
-- Initialization
----------------------------------------------------------------
world.addEventHandler(RefuelTracker)
timer.scheduleFunction(pollFuel, {}, timer.getTime() + MONITOR_INTERVAL)
timer.scheduleFunction(cleanupOldSessions, {}, timer.getTime() + SESSION_CLEANUP_INTERVAL)

-- Add menus for players already in mission
for _, coa in pairs({ coalition.side.RED, coalition.side.BLUE }) do
    local groups = coalition.getGroups(coa, Group.Category.AIRPLANE) or {}
    for _, g in ipairs(groups) do
        for _, u in ipairs(g:getUnits()) do
            if isPlayerUnit(u) then
                ensureSession(u)
                addMenus(u)
            end
        end
    end
end

env.info("AAR Tracking RefuelTracker by EagleEye Initialized - RCv1.0.3")
