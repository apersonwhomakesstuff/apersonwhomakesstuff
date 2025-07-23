-- Replace "left" with your chatBox's side
local chatBox = peripheral.wrap("right")
if not chatBox then
    error("chatBox peripheral not found on the specified side!")
end

while true do
    local event, username, message, uuid = os.pullEvent("chat")
    if message:lower() == "hello" then
        chatBox.sendMessage("Hello!")
    end
end
