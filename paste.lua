-- paste.lua: receive pasted/typed code line-by-line and save it to a file.
-- Useful when `edit` mangles large pastes or HTTP/wget/pastebin is blocked
-- by the server's HTTP allowlist -- this just reads raw lines from the
-- terminal, so a clipboard paste (which the terminal delivers as one
-- line-buffered read() per line) comes through cleanly.
--
-- Usage:
--   paste <filename>
--
-- Then paste/type your code. Finish with a line containing only:
--   :done
-- on its own (mirrors common chat/paste conventions and won't collide with
-- real Lua, since a bare label ::done:: is the closest legal syntax and
-- nobody writes ":done" as code).
--
-- If the target file already exists you'll be asked whether to overwrite.

local args = { ... }
local filename = args[1]

if not filename then
    print("Usage: paste <filename>")
    print("  e.g. paste startup")
    return
end

if fs.exists(filename) then
    write("'" .. filename .. "' already exists. Overwrite? (y/n): ")
    local answer = read()
    if answer:lower() ~= "y" then
        print("Cancelled.")
        return
    end
end

print("Paste your code now. End with a line containing only ':done'")
print("(Ctrl+V to paste, then press Enter after the last line, then type :done)")
print("")

local lines = {}
while true do
    local line = read()
    if line == ":done" then
        break
    end
    lines[#lines + 1] = line
end

local file = fs.open(filename, "w")
for _, line in ipairs(lines) do
    file.writeLine(line)
end
file.close()

print("")
print("Saved " .. #lines .. " lines to '" .. filename .. "'.")
