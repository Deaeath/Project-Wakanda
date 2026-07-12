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
--   - The turtle sitting in that shaft, powered, with a Chat Box
--     peripheral attached (see jarvis.lua's Chat Box notes -- turtle
--     upgrade, not adjacent block).
--   - Fuel: any standard turtle fuel item in its inventory.
--
-- Configure FLOORS below: each entry is the number of blocks from the
-- BOTTOM of the shaft (where the turtle starts) up to that floor. Edit
-- the names and heights to match your actual base.
local FLOORS = {
    { name = "basement", height = 0 },
    { name = "ground",   height = 5 },
    { name = "second",   height = 10 },
    { name = "roof",     height = 15 },
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
