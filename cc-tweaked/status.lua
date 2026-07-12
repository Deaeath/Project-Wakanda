-- status.lua: comprehensive one-shot diagnostic dump for a turtle or
-- computer running CC:Tweaked + Advanced Peripherals. Prints everything it
-- can find; missing peripherals/features just print "not present" instead
-- of erroring. Run with: status

local function header(text)
    print("")
    print("== " .. text .. " ==")
end

local function kv(label, value)
    print(("  %-18s%s"):format(label .. ":", tostring(value)))
end

term.clear()
term.setCursorPos(1, 1)
print("STATUS REPORT")
print(os.date("%Y-%m-%d %H:%M:%S"))

-- ===== System =====
header("System")
kv("Computer ID", os.getComputerID())
kv("Label", os.getComputerLabel() or "(none)")
kv("CraftOS", os.version())
kv("Day", os.day())
kv("Time", textutils.formatTime(os.time(), true))
kv("Uptime (clock)", os.clock())

-- ===== Turtle-specific =====
if turtle then
    header("Turtle")
    kv("Fuel level", turtle.getFuelLevel())
    kv("Fuel limit", turtle.getFuelLimit())

    local totalItems, usedSlots = 0, 0
    for slot = 1, 16 do
        local count = turtle.getItemCount(slot)
        if count > 0 then
            usedSlots = usedSlots + 1
            totalItems = totalItems + count
        end
    end
    kv("Inventory slots used", usedSlots .. " out of 16")
    kv("Total item count", totalItems)

    local eq = {}
    for _, side in ipairs({ "left", "right" }) do
        local ok, name = pcall(function() return peripheral.getType(side) end)
        eq[#eq + 1] = side .. " = " .. (ok and name or "none")
    end
    kv("Equipped upgrades", table.concat(eq, ", "))

    if gps then
        local x, y, z = gps.locate(2)
        if x then
            kv("GPS position", ("%d, %d, %d"):format(x, y, z))
        else
            kv("GPS position", "no signal")
        end
    end
else
    header("Turtle")
    print("  Not a turtle (no turtle API present).")
end

-- ===== Peripherals =====
header("Attached Peripherals")
local names = peripheral.getNames()
if #names == 0 then
    print("  None detected.")
else
    for _, name in ipairs(names) do
        local ok, ptype = pcall(peripheral.getType, name)
        print("  " .. name .. " (" .. (ok and ptype or "unknown") .. ")")
    end
end

-- ===== Storage bridge (ME or RS) =====
local storage = peripheral.find("me_bridge") or peripheral.find("rs_bridge")
header("Storage Bridge")
if not storage then
    print("  Not present.")
else
    local ok, items = pcall(storage.listItems)
    if ok and items then
        local total, types = 0, 0
        for _, item in ipairs(items) do
            total = total + item.amount
            types = types + 1
        end
        kv("Item types", types)
        kv("Total items", total)
    else
        print("  Bridge present but didn't respond.")
    end

    local ok2, energyStored = pcall(storage.getEnergyStorage)
    local ok3, energyCap = pcall(storage.getMaxEnergyStorage)
    if ok2 and ok3 and energyCap and energyCap > 0 then
        local pct = math.floor((energyStored * energyCap^-1) * 100)
        kv("Network energy", pct .. "% (" .. energyStored .. " out of " .. energyCap .. ")")
    end
end

-- ===== Energy detector =====
local energyDetect = peripheral.find("energy_detector")
header("Energy Detector")
if not energyDetect then
    print("  Not present.")
else
    local ok, stored = pcall(energyDetect.getEnergy)
    local ok2, capacity = pcall(energyDetect.getMaxEnergy)
    if ok and ok2 and capacity and capacity > 0 then
        local pct = math.floor((stored * capacity^-1) * 100)
        kv("Reading", pct .. "% (" .. stored .. " out of " .. capacity .. " FE)")
    else
        print("  Present but no reading.")
    end
end

-- ===== Player detector =====
local playerDetect = peripheral.find("player_detector")
header("Player Detector")
if not playerDetect then
    print("  Not present.")
else
    local ok, players = pcall(playerDetect.getPlayersInRange, 32)
    if ok and players then
        kv("Players within 32 blocks", #players)
        for _, p in ipairs(players) do
            print("    - " .. p)
        end
    else
        print("  Present but no reading.")
    end
end

-- ===== Chat box =====
local chat = peripheral.find("chat_box")
header("Chat Box")
kv("Present", chat and "yes" or "no")

-- ===== Redstone =====
header("Redstone (all sides)")
local sides = { "top", "bottom", "left", "right", "front", "back" }
for _, side in ipairs(sides) do
    local ok, level = pcall(redstone.getAnalogInput, side)
    if ok then
        print("  " .. side .. " = " .. level)
    end
end

print("")
print("Report complete.")
