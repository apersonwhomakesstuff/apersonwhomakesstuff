-- CC: Tweaked ChatBot using Advanced Peripherals' chatBox
-- Place this on a computer with a chatBox attached

local chatBox = peripheral.find("chatBox")
if not chatBox then
    error("chatBox peripheral not found! Attach one to the computer.")
end

while true do
    local event, username, message, uuid = os.pullEvent("chat")
    if message:lower() == "hello" then
        chatBox.sendMessage("Hello!")
    end
end
