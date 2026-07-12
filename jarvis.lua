-- JARVIS: base assistant for CC:Tweaked (CraftOS 1.9, CC 1.120.0, MC 1.21.1)
-- Auto-detects whichever Advanced Peripherals are attached and activates
-- matching features. Missing a peripheral just disables that feature --
-- nothing crashes.
--
-- Supported peripherals (attach any or all, wired or wireless):
--   Chat Box            -> talk back in-game, listen for "jarvis <cmd>"
--   ME Bridge or RS Bridge -> AE2 or RS storage + item lookups
--   Player Detector     -> greet you on arrival, warn on stranger nearby
--   Energy Detector     -> report or alert on FE flow
--
-- Install: place this file as "startup" on the turtle or computer (or run
-- `edit startup` and paste this in), or run it directly with `jarvis`.

local NAME = "J.A.R.V.I.S."
local LOW_ENERGY_THRESHOLD = 0.15   -- warn below 15% stored energy
local HIGH_STORAGE_THRESHOLD = 0.95 -- warn above 95% ME storage used
local GREETING_RANGE = 12
local INTRUDER_RANGE = 24           -- wider net for unknown-player detection
local POLL_INTERVAL = 5             -- seconds between background checks
local ALARM_SIDE = "back"           -- redstone output side for the siren or alarm
local ALARM_PULSE_TICKS = 1.0       -- seconds the alarm redstone line stays high

-- Anyone NOT in this list triggers the intruder alarm when seen nearby.
-- Add every player who's allowed to be at the base.
local TRUSTED_PLAYERS = {
    -- "Tyronee_0",
    -- "Xiangel",
}

-- ===== Peripheral discovery =====

local chat = peripheral.find("chat_box")
local storage = peripheral.find("me_bridge") or peripheral.find("rs_bridge")
local playerDetect = peripheral.find("player_detector")
local energyDetect = peripheral.find("energy_detector")
local speaker = peripheral.find("speaker")
local monitor = peripheral.find("monitor")

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

-- ===== Redstone alarm =====
-- Pulses are timed via the main event loop's timer dispatch (see bottom),
-- not os.sleep, so triggering an alarm never blocks chat or detector handling.

local alarmTimer = nil

local function triggerAlarm(reason)
    say("ALARM: " .. reason)
    chime("bass", 4)
    pcall(redstone.setOutput, ALARM_SIDE, true)
    alarmTimer = os.startTimer(ALARM_PULSE_TICKS)
end

-- ===== Feature: storage report =====

local function reportStorage()
    if not storage then
        say("No ME or RS bridge attached, can't check storage.")
        return
    end
    local ok, items = pcall(storage.listItems)
    if not ok or not items then
        say("Storage bridge didn't respond.")
        return
    end
    local totalStored, itemCount = 0, 0
    for _, item in ipairs(items) do
        totalStored = totalStored + item.amount
        itemCount = itemCount + 1
    end
    say(("Tracking %d item types, %d total items in the network."):format(itemCount, totalStored))
end

local function reportItem(query)
    if not storage then
        say("No storage bridge attached.")
        return
    end
    local ok, items = pcall(storage.listItems)
    if not ok or not items then return end
    local q = query:lower()
    local found = false
    for _, item in ipairs(items) do
        local name = (item.displayName or item.name or ""):lower()
        if name:find(q, 1, true) then
            say(("%s: %d"):format(item.displayName or item.name, item.amount))
            found = true
        end
    end
    if not found then
        say("Nothing matching '" .. query .. "' found in storage.")
    end
end

-- ===== Feature: energy report =====

local function reportEnergy()
    if not energyDetect then
        say("No energy detector attached.")
        return
    end
    local ok, stored = pcall(energyDetect.getEnergy)
    local ok2, capacity = pcall(energyDetect.getMaxEnergy)
    if ok and ok2 and capacity and capacity > 0 then
        local pct = math.floor((stored * capacity^-1) * 100)
        say(("Power reserves at %d%% (%d out of %d FE)."):format(pct, stored, capacity))
    else
        say("Energy detector didn't return a reading.")
    end
end

-- ===== Feature: scan and status =====

local function fullScan()
    say("Running full diagnostic...")
    chime("chime", 18)
    if storage then reportStorage() end
    if energyDetect then reportEnergy() end
    if playerDetect then
        local ok, players = pcall(playerDetect.getPlayersInRange, GREETING_RANGE)
        if ok and players then
            say(#players .. " player(s) within " .. GREETING_RANGE .. " blocks.")
        end
    end
    say("Diagnostic complete. All systems nominal.")
end

-- ===== Chat command handling =====

local function handleCommand(cmd, sender)
    cmd = cmd:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if cmd == "status" or cmd == "scan" then
        fullScan()
    elseif cmd == "storage" or cmd == "inventory" then
        reportStorage()
    elseif cmd == "energy" or cmd == "power" then
        reportEnergy()
    elseif cmd:match("^find ") then
        reportItem(cmd:sub(6))
    elseif cmd == "hello" or cmd == "hi" then
        say("At your service, " .. (sender or "sir") .. ".")
        chime("bell", 15)
    else
        say("Unrecognized command: '" .. cmd .. "'. Try status, storage, energy, or find <item>.")
    end
end

-- ===== Shared state (forward-declared so drawDashboard and backgroundCheck,
-- which are defined before their state is otherwise assigned, close over
-- the real locals instead of falling through to globals) =====

local knownNearby = {}
local knownIntruders = {}

-- ===== Monitor dashboard =====

local function drawDashboard()
    if not monitor then return end
    local ok = pcall(function()
        monitor.setTextScale(0.5)
        monitor.setBackgroundColor(colors.black)
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.setTextColor(colors.cyan)
        monitor.write(NAME .. " -- BASE STATUS")

        local line = 3
        monitor.setTextColor(colors.white)

        if energyDetect then
            local eok, stored = pcall(energyDetect.getEnergy)
            local eok2, capacity = pcall(energyDetect.getMaxEnergy)
            monitor.setCursorPos(1, line)
            if eok and eok2 and capacity and capacity > 0 then
                local pct = math.floor((stored * capacity^-1) * 100)
                monitor.setTextColor(pct < LOW_ENERGY_THRESHOLD * 100 and colors.red or colors.green)
                monitor.write(("Power: %d%% (%d out of %d FE)"):format(pct, stored, capacity))
            else
                monitor.write("Power: no reading")
            end
            line = line + 2
        end

        if storage then
            local sok, items = pcall(storage.listItems)
            monitor.setCursorPos(1, line)
            monitor.setTextColor(colors.white)
            if sok and items then
                local total, types = 0, 0
                for _, it in ipairs(items) do
                    total = total + it.amount
                    types = types + 1
                end
                monitor.write(("Storage: %d types, %d items"):format(types, total))
            else
                monitor.write("Storage: no reading")
            end
            line = line + 2
        end

        if playerDetect then
            monitor.setCursorPos(1, line)
            monitor.setTextColor(colors.white)
            local names = {}
            for p, _ in pairs(knownNearby) do names[#names + 1] = p end
            if #names > 0 then
                monitor.write("Nearby: " .. table.concat(names, ", "))
            else
                monitor.write("Nearby: none detected")
            end
            line = line + 2
        end

        monitor.setCursorPos(1, line)
        monitor.setTextColor(alarmTimer and colors.red or colors.lime)
        monitor.write(alarmTimer and "ALERT ACTIVE" or "All systems nominal")
    end)
    -- silently ignore monitor draw failures (e.g. too small, disconnected)
end

-- ===== Background loop: greetings + alerts =====

local function backgroundCheck()
    -- Player arrival greeting + intruder alarm
    if playerDetect then
        local ok, nearby = pcall(playerDetect.getPlayersInRange, GREETING_RANGE)
        if ok and nearby then
            local seenNow = {}
            for _, p in ipairs(nearby) do
                seenNow[p] = true
                if not knownNearby[p] then
                    if isTrusted(p) then
                        say("Welcome back, " .. p .. ".")
                        chime("bell", 18)
                    end
                end
            end
            knownNearby = seenNow
        end

        -- wider-radius sweep purely for unknown players, even if they never
        -- get close enough to trigger the greeting range. Skipped entirely
        -- if TRUSTED_PLAYERS is empty, since that would alarm on the owner too.
        local ok2, wide = pcall(playerDetect.getPlayersInRange, INTRUDER_RANGE)
        if ok2 and wide and next(trustedSet) ~= nil then
            local seenIntruders = {}
            for _, p in ipairs(wide) do
                if not isTrusted(p) then
                    seenIntruders[p] = true
                    if not knownIntruders[p] then
                        triggerAlarm("unrecognized player '" .. p .. "' detected within " ..
                            INTRUDER_RANGE .. " blocks.")
                    end
                end
            end
            knownIntruders = seenIntruders
        end
    end

    -- Energy alert
    if energyDetect then
        local ok, stored = pcall(energyDetect.getEnergy)
        local ok2, capacity = pcall(energyDetect.getMaxEnergy)
        if ok and ok2 and capacity and capacity > 0 then
            if (stored * capacity^-1) < LOW_ENERGY_THRESHOLD then
                say("Warning: power reserves critical, " ..
                    math.floor((stored * capacity^-1) * 100) .. "% remaining.")
                chime("bass", 6)
            end
        end
    end

    drawDashboard()
end

-- ===== Boot sequence =====

term.clear()
term.setCursorPos(1, 1)
print(NAME .. " online.")
print("Peripherals detected:")
print("  Chat Box:        " .. (chat and "YES" or "no"))
print("  Storage Bridge:  " .. (storage and "YES" or "no"))
print("  Player Detector: " .. (playerDetect and "YES" or "no"))
print("  Energy Detector: " .. (energyDetect and "YES" or "no"))
print("  Speaker:         " .. (speaker and "YES" or "no"))
print("  Monitor:         " .. (monitor and "YES" or "no"))
print("  Redstone alarm:  side '" .. ALARM_SIDE .. "'")
if next(trustedSet) == nil then
    print("")
    print("WARNING: TRUSTED_PLAYERS is empty -- intruder alarm is disabled")
    print("until you edit the list at the top of this script.")
end
print("")

pcall(redstone.setOutput, ALARM_SIDE, false)
chime("pling", 24)
say(NAME .. " systems online. Say 'jarvis status' in chat for a diagnostic.")
drawDashboard()

-- ===== Main event loop =====

local pollTimer = os.startTimer(POLL_INTERVAL)

while true do
    local event, a, b, c, d = os.pullEvent()

    if event == "chat" and chat then
        -- Advanced Peripherals chat event: chat, username, message, uuid, isHidden
        local username, message = a, b
        local prefix = message:match("^[Jj][Aa][Rr][Vv][Ii][Ss][,:]?%s*(.*)")
        if prefix and #prefix > 0 then
            handleCommand(prefix, username)
        end
    elseif event == "timer" and a == pollTimer then
        backgroundCheck()
        pollTimer = os.startTimer(POLL_INTERVAL)
    elseif event == "timer" and alarmTimer and a == alarmTimer then
        pcall(redstone.setOutput, ALARM_SIDE, false)
        alarmTimer = nil
        drawDashboard()
    end
end
