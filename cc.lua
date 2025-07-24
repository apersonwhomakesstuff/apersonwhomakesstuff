--[[
Nano-like Code Editor for CC: Tweaked
Single-file all-in-one port inspired by VedaRePowered/lua-nano
Supports Ctrl+Shift+C (Copy) and Ctrl+Shift+V (Paste)
]]

local args = {...}
local filename = args[1]
local w, h = term.getSize()
local clipboard_supported = term.getClipboard and term.setClipboard
local lines = {""}
local cursor_x, cursor_y = 1, 1
local scroll_y = 0
local status_msg = ""
local running = true
local selection = nil -- {x1, y1, x2, y2}

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

-- Copy/paste helpers
local function copy_selection()
    if not selection then status_msg = "No selection!" return end
    local x1, y1, x2, y2 = table.unpack(selection)
    if y1 > y2 or (y1 == y2 and x1 > x2) then x1,y1,x2,y2 = x2,y2,x1,y1 end
    local clip = {}
    for y = y1, y2 do
        local l = lines[y]
        if y == y1 and y == y2 then
            table.insert(clip, l:sub(x1, x2-1))
        elseif y == y1 then
            table.insert(clip, l:sub(x1))
        elseif y == y2 then
            table.insert(clip, l:sub(1, x2-1))
        else
            table.insert(clip, l)
        end
    end
    local text = table.concat(clip, "\n")
    if clipboard_supported then
        term.setClipboard(text)
        status_msg = "Copied selection to clipboard!"
    else
        status_msg = "Clipboard not supported!"
    end
end

local function paste_clipboard()
    if clipboard_supported then
        local text = term.getClipboard()
        if text then
            for line in text:gmatch("([^\n]*)\n?") do
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

-- Main loop
if filename and fs.exists(filename) then
    lines = load_file(filename)
end

redraw()

while running do
    local ev, p1, p2, p3 = os.pullEvent()
    if ev == "key" then
        if p1 == keys.left then move_cursor(-1,0)
        elseif p1 == keys.right then move_cursor(1,0)
        elseif p1 == keys.up then move_cursor(0,-1)
        elseif p1 == keys.down then move_cursor(0,1)
        elseif p1 == keys.backspace then backspace()
        elseif p1 == keys.enter then enter()
        elseif p1 == keys.tab then insert_char("\t")
        elseif p1 == keys.leftCtrl then -- ignore
        elseif p1 == keys.rightCtrl then -- ignore
        elseif p1 == keys.leftShift then -- ignore
        elseif p1 == keys.rightShift then -- ignore
        elseif p1 == keys.s and p2 and (p2 == "leftCtrl" or p2 == "rightCtrl") then
            save_file(filename or "untitled.txt")
        elseif p1 == keys.q and p2 and (p2 == "leftCtrl" or p2 == "rightCtrl") then
            running = false
        end
    elseif ev == "char" then
        insert_char(p1)
    elseif ev == "paste" then
        -- Paste event: term.getClipboard() is preferred but paste event is fallback
        local text = tostring(p1)
        for line in text:gmatch("([^\n]*)\n?") do
            if line then
                for i = 1, #line do
                    insert_char(line:sub(i,i))
                end
                enter()
            end
        end
    elseif ev == "key_up" then
        -- Detect Ctrl+Shift+C/Paste
        if p1 == keys.c and p2 and p3 and ((p2 == "leftCtrl" or p2 == "rightCtrl") and (p3 == "leftShift" or p3 == "rightShift")) then
            copy_selection()
        elseif p1 == keys.v and p2 and p3 and ((p2 == "leftCtrl" or p2 == "rightCtrl") and (p3 == "leftShift" or p3 == "rightShift")) then
            paste_clipboard()
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
