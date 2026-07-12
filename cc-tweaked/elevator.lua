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
--   - The turtle sitting in that shaft, powered, with the Chat Box
--     turtle upgrade (see jarvis.lua's Chat Box notes -- crafted
--     upgrade, not adjacent block). Chat is the only control method --
--     no redstone/physical buttons in this version.
--   - Fuel: any standard turtle fuel item in its inventory.
--   - To auto-start on boot: save this file's contents as "startup" on
--     the turtle (or `copy elevator startup` if you've already got it
--     saved under a different name), then `reboot`. It'll launch and
--     start listening immediately, no manual "elevator" run needed.
--
-- Configure FLOORS below. "height" is blocks from the BOTTOM of the
-- shaft (where the turtle starts), not a world Y-coordinate -- only the
-- DIFFERENCE between two floors matters. This table scales fine to
-- hundreds of entries with no redesign needed -- findFloor() is a
-- linear scan but that's trivial even at hundreds of floors, and
-- "floors" just lists whatever's configured (expect a long chat message
-- if you actually fill in hundreds of names).
--
-- IMPORTANT: the turtle must actually be sitting at FLOORS[1]'s position
-- when this script starts, since currentFloorIndex defaults to 1 with
-- no GPS to verify it. Order entries bottom-to-top to match where the
-- turtle actually starts.
local FLOORS = {
    { name = "lower", height = 0 },
    { name = "upper", height = 33 },
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
-- accurate if every call completes fully -- if the turtle gets stopped
-- mid-move (manually, fuel out, obstruction) this can drift from
-- reality. Run "elevator resync <floor name>" to manually correct it.
local currentFloorIndex = 1

-- Set while a move is in progress (for "status") and used to let "stop"
-- interrupt "start" resume a partially-completed move.
local moving = false
local stopRequested = false
local pendingTargetIndex = nil

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
-- Returns (blocksActuallyMoved, stoppedEarly).
local function moveVertical(blocks, goingUp)
    local moveFn = goingUp and turtle.up or turtle.down
    for i = 1, blocks do
        if stopRequested then
            return i - 1, true
        end
        local moved = false
        local attempts = 0
        while not moved and attempts < 10 do
            if stopRequested then
                return i - 1, true
            end
            moved = moveFn()
            if not moved then
                attempts = attempts + 1
                sleep(MOVE_RETRY_DELAY)
            end
        end
        if not moved then
            say("Blocked and couldn't clear the shaft after multiple attempts. Stopping.")
            return i - 1, false
        end
    end
    return blocks, false
end

-- The actual move, run as one branch of parallel.waitForAny so a "stop"
-- chat command arriving on the other branch can end it early. Since
-- FLOORS only stores each floor's absolute height (not "how far from
-- wherever we currently are"), resuming after a partial move re-reads
-- the turtle's CURRENT position via currentHeightEstimate rather than
-- assuming it's still at the floor it left from.
local currentHeightEstimate = nil -- set on first goToFloor call

local function doMove(targetIndex)
    moving = true
    stopRequested = false

    if currentHeightEstimate == nil then
        currentHeightEstimate = FLOORS[currentFloorIndex].height
    end

    local to = FLOORS[targetIndex]
    local delta = to.height - currentHeightEstimate
    local blocks = math.abs(delta)
    local goingUp = delta > 0

    if blocks == 0 then
        currentFloorIndex = targetIndex
        pendingTargetIndex = nil
        moving = false
        say("Already at " .. to.name .. ".")
        return
    end

    if not ensureFuel(blocks) then
        say("Not enough fuel to reach " .. to.name .. " (" .. blocks .. " blocks needed).")
        moving = false
        return
    end

    pendingTargetIndex = targetIndex
    say("Heading to " .. to.name .. (goingUp and " (up)" or " (down)") .. "...")
    local moved, stoppedEarly = moveVertical(blocks, goingUp)
    currentHeightEstimate = currentHeightEstimate + (goingUp and moved or -moved)

    moving = false
    if stoppedEarly then
        say("Stopped partway to " .. to.name .. ". Say 'elevator start' to continue, or 'elevator resync <floor>' if the shaft position isn't what you expect.")
    elseif moved == blocks then
        currentFloorIndex = targetIndex
        pendingTargetIndex = nil
        say("Arrived at " .. to.name .. ".")
    else
        say("Didn't make it to " .. to.name .. " -- say 'elevator start' to retry, or 'elevator resync <floor>' once you know where the turtle actually is.")
    end
end

-- Runs during a move to catch "elevator stop" without blocking movement.
-- Ends (letting parallel.waitForAny return) the instant stop is heard;
-- doMove notices stopRequested on its next per-block check.
local function watchForStop()
    while true do
        local event, username, message = os.pullEvent("chat")
        if chat then
            local prefix = message:match("^[Ee][Ll][Ee][Vv][Aa][Tt][Oo][Rr][,:]?%s*(.*)")
            if prefix and prefix:lower():gsub("^%s+", ""):gsub("%s+$", "") == "stop" then
                stopRequested = true
                say("Stopping...")
                return
            end
        end
    end
end

local function goToFloor(targetIndex)
    if moving then
        say("Already moving -- say 'elevator stop' first if you want to redirect.")
        return
    end
    if targetIndex == currentFloorIndex and currentHeightEstimate == nil then
        say("Already at " .. FLOORS[targetIndex].name .. ".")
        return
    end
    parallel.waitForAny(function() doMove(targetIndex) end, watchForStop)
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

    if cmd == "floors" then
        listFloors()
        return
    end

    if cmd == "status" then
        if moving then
            say("Moving toward " .. FLOORS[pendingTargetIndex].name .. "...")
        elseif pendingTargetIndex then
            say("Stopped partway to " .. FLOORS[pendingTargetIndex].name .. ". Say 'elevator start' to continue.")
        else
            say("Idle at " .. FLOORS[currentFloorIndex].name .. ".")
        end
        return
    end

    if cmd == "stop" then
        if moving then
            stopRequested = true
        else
            say("Not moving.")
        end
        return
    end

    if cmd == "start" then
        if moving then
            say("Already moving.")
        elseif pendingTargetIndex then
            goToFloor(pendingTargetIndex)
        else
            say("Nothing to resume. Say 'elevator floor <name>' to call it somewhere.")
        end
        return
    end

    local resyncTarget = cmd:match("^resync%s+(.+)$")
    if resyncTarget then
        local idx = findFloor(resyncTarget)
        if idx then
            currentFloorIndex = idx
            currentHeightEstimate = FLOORS[idx].height
            pendingTargetIndex = nil
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
        say("Unrecognized command '" .. cmd .. "'. Try: floor <name>, floors, status, stop, start, resync <name>.")
    end
end

term.clear()
term.setCursorPos(1, 1)
print(NAME .. " online.")
print("Chat Box: " .. (chat and "YES" or "no -- required, this program only listens for chat commands"))
listFloors()
say(NAME .. " ready. Say 'elevator floor <name>' in chat.")

while true do
    local event, username, message = os.pullEvent("chat")
    if chat then
        local prefix = message:match("^[Ee][Ll][Ee][Vv][Aa][Tt][Oo][Rr][,:]?%s*(.*)")
        if prefix and #prefix > 0 then
            handleCommand(prefix, username)
        end
    end
end
