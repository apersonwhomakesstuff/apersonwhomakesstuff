-- Nano-like Editor for CC: Tweaked
-- Backslash (\) commands for save, quit, copy, paste, cut, uncut
-- Inspired by https://github.com/VedaRePowered/lua-nano

local args = {...}
local filename = args[1]
local w, h = term.getSize()
local clipboard_supported = term.getClipboard and term.setClipboard
local lines = {""}
local cursor_x, cursor_y = 1, 1
local scroll_y = 0
local status_msg = ""
local running = true
local cut_buffer = ""

-- File IO
local function load_file(fname)
    local f = fs.open(fname, "r")
    if not f then return {""} end
    local out = {}
    while true do
        local line = f.readLine()
        if not line then break end
        table.insert(out, line)
    end
    f.close()
    return #out > 0 and out or {""}
end

local function save_file(fname)
    local f = fs.open(fname, "w")
    if not f then
        status_msg = "Error: Cannot save file!"
        return
    end
    for _, l in ipairs(lines) do f.writeLine(l) end
    f.close()
    status_msg = "Saved!"
end

-- Utility
local function clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

local function redraw()
    term.clear()
    -- Draw visible lines
    for i = 1, h-2 do
        local l = lines[i+scroll_y] or ""
        term.setCursorPos(1, i)
        term.write(l:sub(1, w))
    end

    -- Status bar
    term.setCursorPos(1, h-1)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clearLine()
    local fname = filename or "[No Name]"
    term.write(string.format("nano.lua | %s | Ln %d, Col %d", fname, cursor_y, cursor_x))
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.yellow)
    term.setCursorPos(1, h)
    term.clearLine()
    term.write(status_msg)
    status_msg = ""
    -- Cursor
    term.setCursorPos(cursor_x, clamp(cursor_y-scroll_y,1,h-2))
end

local function move_cursor(dx, dy)
    cursor_y = clamp(cursor_y + dy, 1, #lines)
    cursor_x = clamp(cursor_x, 1, #lines[cursor_y]+1)
    cursor_x = clamp(cursor_x + dx, 1, #lines[cursor_y]+1)
end

local function set_cursor(x, y)
    cursor_y = clamp(y, 1, #lines)
    cursor_x = clamp(x, 1, #lines[cursor_y]+1)
end

local function insert_char(c)
    local l = lines[cursor_y]
    lines[cursor_y] = l:sub(1, cursor_x-1) .. c .. l:sub(cursor_x)
    cursor_x = cursor_x + 1
end

local function backspace()
    if cursor_x > 1 then
        local l = lines[cursor_y]
        lines[cursor_y] = l:sub(1, cursor_x-2) .. l:sub(cursor_x)
        cursor_x = cursor_x - 1
    elseif cursor_y > 1 then
        local prev = lines[cursor_y-1]
        local cur = lines[cursor_y]
        cursor_x = #prev + 1
        lines[cursor_y-1] = prev .. cur
        table.remove(lines, cursor_y)
        cursor_y = cursor_y - 1
    end
end

local function enter()
    local l = lines[cursor_y]
    local left = l:sub(1, cursor_x-1)
    local right = l:sub(cursor_x)
    lines[cursor_y] = left
    table.insert(lines, cursor_y+1, right)
    cursor_y = cursor_y + 1
    cursor_x = 1
end

-- Copy/Paste/Cut
local function copy_line()
    local l = lines[cursor_y]
    if clipboard_supported then
        term.setClipboard(l)
        status_msg = "Copied line to clipboard!"
    else
        status_msg = "Clipboard not supported!"
    end
end

local function paste_clipboard()
    if clipboard_supported then
        local text = term.getClipboard()
        if text then
            for line in (text .. "\n"):gmatch("([^\n]*)\n") do
                if line then
                    for i = 1, #line do
                        insert_char(line:sub(i,i))
                    end
                    enter()
                end
            end
            status_msg = "Pasted from clipboard!"
        end
    else
        status_msg = "Clipboard not supported!"
    end
end

local function cut_line()
    cut_buffer = lines[cursor_y]
    table.remove(lines, cursor_y)
    if #lines == 0 then lines[1] = "" end
    cursor_y = clamp(cursor_y, 1, #lines)
    cursor_x = clamp(cursor_x, 1, #lines[cursor_y]+1)
    status_msg = "Cut line."
end

local function uncut_line()
    table.insert(lines, cursor_y, cut_buffer)
    status_msg = "Uncut (pasted) line."
end

-- Main loop
if filename and fs.exists(filename) then
    lines = load_file(filename)
end

redraw()
local in_command_mode = false

while running do
    local ev, p1 = os.pullEvent()
    if ev == "key" then
        if p1 == keys.left then move_cursor(-1,0)
        elseif p1 == keys.right then move_cursor(1,0)
        elseif p1 == keys.up then move_cursor(0,-1)
        elseif p1 == keys.down then move_cursor(0,1)
        elseif p1 == keys.backspace then backspace()
        elseif p1 == keys.enter then enter()
        elseif p1 == keys.tab then insert_char("\t")
    elseif ev == "char" then
        if in_command_mode then
            if p1 == "s" then
                save_file(filename or "untitled.txt")
            elseif p1 == "q" then
                running = false
            elseif p1 == "c" then
                copy_line()
            elseif p1 == "v" then
                paste_clipboard()
            elseif p1 == "k" then
                cut_line()
            elseif p1 == "u" then
                uncut_line()
            else
                status_msg = "Unknown command: \\" .. p1
            end
            in_command_mode = false
        elseif p1 == "\\" then
            in_command_mode = true
            status_msg = "Command mode: s(save), q(quit), c(copy line), v(paste clipboard), k(cut line), u(uncut line)"
        else
            insert_char(p1)
        end
    elseif ev == "paste" then
        -- Fallback paste event if supported
        local text = tostring(p1)
        for line in (text .. "\n"):gmatch("([^\n]*)\n") do
            if line then
                for i = 1, #line do
                    insert_char(line:sub(i,i))
                end
                enter()
            end
        end
    end

    -- Scroll if needed
    if cursor_y - scroll_y < 1 then scroll_y = cursor_y - 1 end
    if cursor_y - scroll_y > h-2 then scroll_y = cursor_y - (h-2) end
    scroll_y = clamp(scroll_y, 0, math.max(0, #lines-h+2))

    redraw()
end

term.clear()
term.setCursorPos(1,1)
print("Exited nano.lua")
