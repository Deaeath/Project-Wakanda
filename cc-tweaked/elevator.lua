-- ELEVATOR: turtle-pushed vertical lift for CC:Tweaked (CraftOS 1.9 / CC
-- 1.120.0, MC 1.21.1). Sits in a 1x1 vertical shaft; when called to a
-- floor, it moves up/down that shaft, physically pushing anything in its
-- path (including you) along with it.
--
-- SOURCE-VERIFIED: CC:Tweaked turtles can push entities on movement, the
-- same PushReaction mechanism vanilla pistons use -- confirmed via
-- dan200.computercraft.shared.turtle.core.TurtleMoveCommand.canPushEntities()
-- and dan200.computercraft.shared.config.Config.turtlesCanPush (defaults
-- to enabled). If your server has turtlesCanPush disabled, this won't
-- push you and needs a different mechanism (e.g. a Create Elevator
-- Pulley contraption instead).
--
-- Build requirements:
--   - A clear 1x1 (or wider, turtle just needs its own column clear)
--     vertical shaft spanning every floor you want to stop at.
--   - The turtle sitting in that shaft, powered.
--   - Fuel: any standard turtle fuel item in its inventory.
--   - Optional: Chat Box turtle upgrade (see jarvis.lua's Chat Box notes
--     -- crafted upgrade, not adjacent block) for chat-commanded calls.
--   - Optional: physical call buttons -- see REDSTONE_CALLS below.
--   - To auto-start on boot: save this file's contents as "startup" on
--     the turtle (or `copy elevator startup` if you've already got it
--     saved under a different name), then `reboot`. It'll launch and
--     start listening immediately, no manual "elevator" run needed.
--
-- Configure FLOORS below. "height" is blocks from the BOTTOM of the
-- shaft (where the turtle starts), not a world Y-coordinate -- only the
-- DIFFERENCE between two floors matters, and world Y11 to Y44 is a 33
-- block gap, so "lower" is 0 and "upper" is 33.
--
-- IMPORTANT: the turtle must actually be sitting at the "lower" (Y11)
-- position when this script starts, since currentFloorIndex defaults to
-- FLOORS[1] with no GPS to verify it. If the turtle starts at the upper
-- floor instead, swap the order of these two entries.
local FLOORS = {
    { name = "lower", height = 0 },
    { name = "upper", height = 33 },
}

-- Physical call buttons: run redstone wire (dust + repeaters as needed)
-- from a lever/button at each floor down/up the shaft to a distinct side
-- on the turtle. When that side goes high, the elevator is called to the
-- mapped floor -- no chat command needed. Only sides not otherwise used
-- (the turtle needs "top"/"bottom" free for movement, though redstone
-- input doesn't actually block movement, it's just avoided here for
-- clarity) are mapped below; add/remove entries to match how you wire it.
-- Leave empty ({}) to disable physical call buttons entirely.
local REDSTONE_CALLS = {
    front = "lower",
    back  = "upper",
}

local NAME = "ELEVATOR"
local MOVE_RETRY_DELAY = 0.5 -- seconds to wait before retrying a blocked move

local chat = peripheral.find("chat_box")

local function say(msg)
    print("[" .. NAME .. "] " .. msg)
    if chat then
        pcall(chat.sendMessage, msg, NAME)
    end
end

-- currentFloorIndex tracks where the turtle THINKS it is. It's only
-- accurate if every call completes fully -- if the turtle gets stuck
-- mid-move (fuel out, obstruction) this can drift from reality. Run
-- "elevator resync <floor name>" to manually correct it if that happens.
local currentFloorIndex = 1

local function findFloor(name)
    for i, floor in ipairs(FLOORS) do
        if floor.name:lower() == name:lower() then
            return i
        end
    end
    return nil
end

local function ensureFuel(blocksNeeded)
    if turtle.getFuelLevel() == "unlimited" then return true end
    if turtle.getFuelLevel() >= blocksNeeded then return true end
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then -- refuel(0) just checks if the item IS fuel
            turtle.refuel()
            if turtle.getFuelLevel() >= blocksNeeded or turtle.getFuelLevel() == "unlimited" then
                return true
            end
        end
    end
    return turtle.getFuelLevel() >= blocksNeeded
end

-- Moves the given number of blocks in the given vertical direction,
-- pushing anything (including a player) in the shaft along with it.
-- Retries on obstruction instead of giving up immediately -- a player
-- riding the lift IS the expected "obstruction" this pushes through.
local function moveVertical(blocks, goingUp)
    local moveFn = goingUp and turtle.up or turtle.down
    for i = 1, blocks do
        local moved = false
        local attempts = 0
        while not moved and attempts < 10 do
            moved = moveFn()
            if not moved then
                attempts = attempts + 1
                sleep(MOVE_RETRY_DELAY)
            end
        end
        if not moved then
            say("Blocked and couldn't clear the shaft after multiple attempts. Stopping.")
            return false
        end
    end
    return true
end

local function goToFloor(targetIndex)
    if targetIndex == currentFloorIndex then
        say("Already at " .. FLOORS[targetIndex].name .. ".")
        return
    end

    local from = FLOORS[currentFloorIndex]
    local to = FLOORS[targetIndex]
    local delta = to.height - from.height
    local blocks = math.abs(delta)
    local goingUp = delta > 0

    if not ensureFuel(blocks) then
        say("Not enough fuel to reach " .. to.name .. " (" .. blocks .. " blocks needed).")
        return
    end

    say("Heading to " .. to.name .. (goingUp and " (up)" or " (down)") .. "...")
    if moveVertical(blocks, goingUp) then
        currentFloorIndex = targetIndex
        say("Arrived at " .. to.name .. ".")
    else
        say("Didn't make it to " .. to.name .. " -- run 'elevator resync <floor>' once you know where the turtle actually is.")
    end
end

local function listFloors()
    local names = {}
    for _, floor in ipairs(FLOORS) do
        names[#names + 1] = floor.name
    end
    say("Floors: " .. table.concat(names, ", "))
end

local function handleCommand(cmd, sender)
    cmd = cmd:lower():gsub("^%s+", ""):gsub("%s+$", "")

    if cmd == "floors" or cmd == "status" then
        listFloors()
        say("Currently at: " .. FLOORS[currentFloorIndex].name)
        return
    end

    local resyncTarget = cmd:match("^resync%s+(.+)$")
    if resyncTarget then
        local idx = findFloor(resyncTarget)
        if idx then
            currentFloorIndex = idx
            say("Resynced -- now treating current position as " .. FLOORS[idx].name .. ".")
        else
            say("Unknown floor '" .. resyncTarget .. "'.")
        end
        return
    end

    local floorTarget = cmd:match("^floor%s+(.+)$") or cmd
    local idx = findFloor(floorTarget)
    if idx then
        goToFloor(idx)
    else
        say("Unrecognized command '" .. cmd .. "'. Try: floor <name>, floors, status, resync <name>.")
    end
end

local function callButtonCount()
    local n = 0
    for _ in pairs(REDSTONE_CALLS) do n = n + 1 end
    return n
end

term.clear()
term.setCursorPos(1, 1)
print(NAME .. " online.")
print("Chat Box:      " .. (chat and "YES" or "no -- chat commands won't work without one"))
print("Call buttons:  " .. (callButtonCount() > 0 and callButtonCount() .. " side(s) mapped" or "none configured"))
listFloors()
say(NAME .. " ready. Say 'elevator floor <name>' in chat, or use a call button.")

-- Unfiltered event loop -- catches both "chat" (unless no Chat Box, in
-- which case that event type never fires anyway) and "redstone" (fires
-- once per actual signal change on any side, not continuously while a
-- lever is held, so no extra debouncing needed here).
while true do
    local event, a, b = os.pullEvent()

    if event == "chat" and chat then
        local username, message = a, b
        local prefix = message:match("^[Ee][Ll][Ee][Vv][Aa][Tt][Oo][Rr][,:]?%s*(.*)")
        if prefix and #prefix > 0 then
            handleCommand(prefix, username)
        end
    elseif event == "redstone" then
        for side, floorName in pairs(REDSTONE_CALLS) do
            if redstone.getInput(side) then
                local idx = findFloor(floorName)
                if idx then
                    goToFloor(idx)
                end
            end
        end
    end
end
