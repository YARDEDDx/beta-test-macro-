local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local name = "Exotica Macros"
local ownerid = "kFHLyWbpTo"
local version = "1.0"
local saveFileName = "ExoticaKey.txt"
local sessionid = nil

print("--- LOADER STARTED ---")

local function safeRequest(requestData)
    local reqFunc = request or (syn and syn.request) or (http and http.request)
    if not reqFunc then return nil end
    local success, res = pcall(function() return reqFunc(requestData) end)
    if not success then return nil end
    return res
end

local function initKeyAuth()
    local initUrl = string.format("https://keyauth.win/api/1.2/?type=init&name=%s&ownerid=%s&ver=%s", name, ownerid, version)
    local response = safeRequest({ Url = initUrl, Method = "GET" })
    if response and response.StatusCode == 200 then
        local successDec, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
        if successDec and data and data.success then
            sessionid = data.sessionid
            return true
        end
    end
    return false
end

local function executeMasterScript()
    local mainScriptUrl = "https://raw.githubusercontent.com/YARDEDDx/beta-test-macro-/refs/heads/main/macro?nocache=" .. tostring(tick())
    local fetchSuccess, result = pcall(function() return game:HttpGet(mainScriptUrl) end)
    if not fetchSuccess or not result or result == "" then return end
    
    -- Sets the global session token so the master script knows it came through the loader!
    _G.ExoticaAuthorizedSession = true
    
    local fn, err = loadstring(result)
    if not fn then return end
    pcall(fn)
end

local function validateKey(keyToTest)
    if not sessionid then
        local inited = initKeyAuth()
        if not inited then return false, "Init Failed" end
    end

    local hwid = player.UserId .. "_" .. tostring(game.JobId ~= "" and game.JobId or "Studio")
    local url = string.format("https://keyauth.win/api/1.2/?type=license&key=%s&hwid=%s&sessionid=%s&name=%s&ownerid=%s", keyToTest, hwid, sessionid, name, ownerid)

    local response = safeRequest({ Url = url, Method = "GET" })
    if response and response.StatusCode == 200 then
        local successDec, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
        if successDec and data then
            if data.success then
                if writefile then pcall(function() writefile(saveFileName, keyToTest) end) end
                return true, "Success"
            else
                if isfile and isfile(saveFileName) and delfile then pcall(function() delfile(saveFileName) end) end
                return false, data.message or "Invalid Key"
            end
        end
    end
    return false, "Connection Error"
end

task.spawn(function()
    local readSuccess, fileExists = pcall(function() return isfile and isfile(saveFileName) end)
    if readSuccess and fileExists then
        local readOk, savedKey = pcall(function() return readfile(saveFileName) end)
        if readOk and savedKey and savedKey ~= "" then
            local isValid, msg = validateKey(savedKey)
            if isValid then
                executeMasterScript()
                return
            end
        end
    end

    pcall(function()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "ExoticaKeyLoader"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = (gethui and gethui()) or CoreGui

        local frame = Instance.new("Frame", screenGui)
        frame.Size = UDim2.new(0, 320, 0, 160)
        frame.Position = UDim2.new(0.5, -160, 0.5, -80)
        frame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
        frame.BorderSizePixel = 0
        frame.BackgroundTransparency = 1

        local uiCorner = Instance.new("UICorner", frame)
        uiCorner.CornerRadius = UDim.new(0, 8)

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1, 0, 0, 40)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = "Exotica Macros - Login"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 16
        title.TextTransparency = 1

        local textBox = Instance.new("TextBox", frame)
        textBox.Size = UDim2.new(0.85, 0, 0, 40)
        textBox.Position = UDim2.new(0.075, 0, 0.35, 0)
        textBox.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        textBox.PlaceholderText = "Enter License Key..."
        textBox.Text = ""
        textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        textBox.Font = Enum.Font.Gotham
        textBox.TextSize = 14
        textBox.BackgroundTransparency = 1
        textBox.TextTransparency = 1

        local boxCorner = Instance.new("UICorner", textBox)
        boxCorner.CornerRadius = UDim.new(0, 6)

        local submitBtn = Instance.new("TextButton", frame)
        submitBtn.Size = UDim2.new(0.85, 0, 0, 40)
        submitBtn.Position = UDim2.new(0.075, 0, 0.65, 0)
        submitBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
        submitBtn.Font = Enum.Font.GothamBold
        submitBtn.Text = "Verify Key"
        submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        submitBtn.TextSize = 14
        submitBtn.BackgroundTransparency = 1
        submitBtn.TextTransparency = 1

        local btnCorner = Instance.new("UICorner", submitBtn)
        btnCorner.CornerRadius = UDim.new(0, 6)

        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(title, tweenInfo, {TextTransparency = 0}):Play()
        TweenService:Create(textBox, tweenInfo, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
        TweenService:Create(submitBtn, tweenInfo, {BackgroundTransparency = 0, TextTransparency = 0}):Play()

        local dragging, dragInput, dragStart, startPos
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        submitBtn.Activated:Connect(function()
            local enteredKey = textBox.Text
            if enteredKey == "" then
                textBox.PlaceholderText = "Please enter a key!"
                return
            end

            submitBtn.Text = "Verifying..."
            local success, msg = validateKey(enteredKey)
            if success then
                submitBtn.Text = "Success! Loading..."
                task.wait(1)
                screenGui:Destroy()
                executeMasterScript()
            else
                submitBtn.Text = "Verify Key"
                textBox.Text = ""
                textBox.PlaceholderText = msg
            end
        end)
    end)
end)
