-- PATROL: walks a turtle around a defined loop, watching for
-- non-trusted players via a Player Detector and sounding an alarm --
-- same trust-list pattern as jarvis.lua. For CC:Tweaked (CraftOS 1.9 /
-- CC 1.120.0, MC 1.21.1).
--
-- No GPS required: the route is a relative step sequence (forward N,
-- turn, forward N...) starting from wherever the turtle is placed and
-- facing when this program first runs -- NOT absolute coordinates. If
-- you get GPS satellites set up later, this can be upgraded to
-- gps.locate()-based waypoints for a route that self-corrects if the
-- turtle gets knocked off course; until then, an obstruction the turtle
-- can't clear will leave it stuck rather than rerouting.
--
-- Build requirements:
--   - Player Detector peripheral (Advanced Peripherals) attached.
--   - Chat Box turtle upgrade if you want in-game alerts (see jarvis.lua
--     notes on why this has to be a crafted turtle upgrade, not just an
--     adjacent block).
--   - Enough fuel in inventory to complete the loop repeatedly.
--
-- Configure ROUTE below as a sequence of steps. Each step is one of:
--   {"forward", N}  -- move forward N blocks (digs through obstructions)
--   {"turn_left"}   -- turn 90 degrees left
--   {"turn_right"}  -- turn 90 degrees right
--   {"wait", N}     -- pause N seconds (e.g. to watch a chokepoint)
-- The sequence should form a closed loop back to the start.
local ROUTE = {
    { "forward",   10 },
    { "turn_right" },
    { "forward",   10 },
    { "turn_right" },
    { "forward",   10 },
    { "turn_right" },
    { "forward",   10 },
    { "turn_right" },
}

-- Anyone NOT in this list triggers the alarm when seen nearby. Same
-- convention as jarvis.lua's TRUSTED_PLAYERS -- keep them in sync if you
-- run both.
local TRUSTED_PLAYERS = {
    -- "Tyronee_0",
    -- "Xiangel",
}

local NAME = "PATROL"
local DETECTION_RANGE = 16       -- blocks, how far the Player Detector scans each step
local ALARM_SIDE = "back"        -- redstone output side for a siren/alarm
local ALARM_PULSE_TICKS = 1.0    -- seconds the alarm redstone line stays high
local STEP_PAUSE = 0.5           -- seconds between route steps, gives the scan time to matter

local chat = peripheral.find("chat_box")
local playerDetect = peripheral.find("player_detector")
local speaker = peripheral.find("speaker")

local trustedSet = {}
for _, name in ipairs(TRUSTED_PLAYERS) do
    trustedSet[name:lower()] = true
end

local function isTrusted(name)
    return trustedSet[name:lower()] == true
end

local function say(msg)
    print("[" .. NAME .. "] " .. msg)
    if chat then
        pcall(chat.sendMessage, msg, NAME)
    end
end

local function chime(instrument, pitch)
    if speaker then
        pcall(speaker.playNote, instrument or "bell", 1, pitch or 12)
    end
end

local alarmClearAt = nil
local function triggerAlarm(reason)
    say("ALARM: " .. reason)
    chime("bass", 4)
    pcall(redstone.setOutput, ALARM_SIDE, true)
    alarmClearAt = os.clock() + ALARM_PULSE_TICKS
end

-- Called opportunistically between route steps -- turns the alarm back
-- off once its pulse duration has elapsed. Not event-driven (this whole
-- script is synchronous via sleep() during route walking, unlike
-- jarvis.lua's event loop), so this just checks elapsed real time.
local function clearAlarmIfExpired()
    if alarmClearAt and os.clock() >= alarmClearAt then
        pcall(redstone.setOutput, ALARM_SIDE, false)
        alarmClearAt = nil
    end
end

local knownIntruders = {}

local function scanForIntruders()
    if not playerDetect then return end
    local ok, nearby = pcall(playerDetect.getPlayersInRange, DETECTION_RANGE)
    if not ok or not nearby then return end

    local seenNow = {}
    for _, p in ipairs(nearby) do
        if not isTrusted(p) then
            seenNow[p] = true
            if not knownIntruders[p] then
                triggerAlarm("unrecognized player '" .. p .. "' spotted on patrol")
            end
        end
    end
    knownIntruders = seenNow
end

-- Digs through whatever's blocking forward movement. A patrol route is
-- assumed to be through territory you control, so clearing an
-- obstruction is treated as safe -- if your route passes anywhere a
-- player could wall it off maliciously, this will just tunnel through
-- that too.
local function safeForward(count)
    for i = 1, count do
        while turtle.detect() do
            turtle.dig()
            sleep(0.4)
        end
        local moved = false
        local attempts = 0
        while not moved and attempts < 5 do
            moved = turtle.forward()
            if not moved then
                attempts = attempts + 1
                sleep(0.5)
            end
        end
        if not moved then
            say("Stuck -- couldn't move forward after multiple attempts. Pausing route.")
            return false
        end
        scanForIntruders()
        clearAlarmIfExpired()
    end
    return true
end

local function runRoute()
    for _, step in ipairs(ROUTE) do
        local action = step[1]
        if action == "forward" then
            if not safeForward(step[2]) then
                return false
            end
        elseif action == "turn_left" then
            turtle.turnLeft()
        elseif action == "turn_right" then
            turtle.turnRight()
        elseif action == "wait" then
            local elapsed = 0
            while elapsed < step[2] do
                sleep(1)
                elapsed = elapsed + 1
                scanForIntruders()
            end
        end
        sleep(STEP_PAUSE)
    end
    return true
end

term.clear()
term.setCursorPos(1, 1)
print(NAME .. " online.")
print("Chat Box:        " .. (chat and "YES" or "no"))
print("Player Detector: " .. (playerDetect and "YES" or "no (patrol runs but can't detect intruders)"))
print("Speaker:         " .. (speaker and "YES" or "no"))
if next(trustedSet) == nil then
    print("")
    print("WARNING: TRUSTED_PLAYERS is empty -- every player seen will trigger the alarm,")
    print("including you. Edit the list at the top of this script.")
end
print("")

pcall(redstone.setOutput, ALARM_SIDE, false)
say(NAME .. " starting loop.")

while true do
    local ok = runRoute()
    clearAlarmIfExpired()
    if not ok then
        say("Route interrupted. Retrying from current position in 10 seconds.")
        sleep(10)
        clearAlarmIfExpired()
    end
end
