local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local gameId = game.GameId

local supportedGames = {
    [6961824067] = {
        url = "https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/FTAP.lua",
        name = "FTAP"
    },
    [6766156863] = {
        url = "https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/SMS.lua",
        name = "Strongman Simulator"
    },
    [2907962276] = {
        url = "https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/SSE2.lua",
        name = "Solar System Exploration 2"
    },
    [9419242500] = {
        url = "https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/CI.lua",
        name = "Cat Invasion"
    },
    [9312646406] = {
        url = "https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/LOD.lua",
        name = "Land or Die"
    }
}

local gui = nil
local mouseReleased = false
local originalCameraType = nil
local originalCameraSubject = nil
local scriptActive = true
local keyVerified = false
local keySkipped = false

local function decodeBase64(str)
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    str = string.gsub(str, '[^'..b64chars..'=]', '')
    local result = {}
    for i = 1, #str, 4 do
        local chunk = str:sub(i, i+3)
        local a, b, c, d = chunk:byte(1, 4)
        local function val(ch)
            if ch == 61 then return 0 end
            local pos = b64chars:find(string.char(ch), 1, true)
            return pos and pos - 1 or 0
        end
        local n = val(a) * 0x40000 + val(b) * 0x1000 + val(c) * 0x40 + val(d)
        result[#result+1] = string.char(math.floor(n / 0x10000))
        if c ~= 61 then
            result[#result+1] = string.char(math.floor((n % 0x10000) / 0x100))
        end
        if d ~= 61 then
            result[#result+1] = string.char(n % 0x100)
        end
    end
    return table.concat(result)
end

local function getCorrectKey()
    local encoded = "WDchcFIjazI="
    return decodeBase64(encoded)
end

local function trim(str)
    return str:match("^%s*(.-)%s*$")
end

local function setThirdPerson()
    local camera = workspace.CurrentCamera
    if not camera then return end
    originalCameraType = camera.CameraType
    originalCameraSubject = camera.CameraSubject
    camera.CameraType = Enum.CameraType.Follow
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
        end
    end
end

local function resetCamera()
    local camera = workspace.CurrentCamera
    if camera and originalCameraType then
        camera.CameraType = originalCameraType
        camera.CameraSubject = originalCameraSubject
    end
end

local function showMouse()
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
    mouseReleased = true
end

local function releaseMouse()
    if not mouseReleased and scriptActive then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        pcall(function()
            game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end)
        setThirdPerson()
        mouseReleased = true
    end
end

local function lockMouse()
    if mouseReleased then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
        resetCamera()
        mouseReleased = false
    end
end

local function fullCleanup()
    scriptActive = false
    resetCamera()
    if gui then
        gui:Destroy()
        gui = nil
    end
end

local function createNotification(text, duration)
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "NotificationGUI"
    notifGui.ResetOnSpawn = false
    notifGui.Parent = player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 50)
    frame.Position = UDim2.new(0.5, -150, 0.9, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = notifGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.02, 0)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.Parent = frame
    
    local tween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -150, 0.85, 0)
    })
    tween:Play()
    
    task.delay(duration or 3, function()
        local fadeOut = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        fadeOut:Play()
        task.delay(0.3, function()
            notifGui:Destroy()
        end)
    end)
end

local function loadScript(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if success and result then
        local func, err = loadstring(result)
        if func then
            fullCleanup()
            pcall(func)
        else
            createNotification("Failed to load script: " .. tostring(err), 3)
            releaseMouse()
        end
    else
        createNotification("Failed to fetch script from server", 3)
        releaseMouse()
    end
end

local function createMainGUI()
    if gui then
        gui:Destroy()
        gui = nil
    end
    
    gui = Instance.new("ScreenGui")
    gui.Name = "ScriptLoaderGUI"
    gui.ResetOnSpawn = false
    gui.Parent = player.PlayerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 150)
    mainFrame.Position = UDim2.new(0.02, 0, 0.5, -75)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0.02, 0)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(100, 100, 150)
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.5
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.2, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "EXVS ► Script Loader"
    title.Parent = mainFrame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 25)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = mainFrame
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0.2, 0)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        lockMouse()
        gui:Destroy()
        gui = nil
    end)
    
    local universalBtn = Instance.new("TextButton")
    universalBtn.Size = UDim2.new(0.8, 0, 0.25, 0)
    universalBtn.Position = UDim2.new(0.1, 0, 0.3, 0)
    universalBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    universalBtn.BackgroundTransparency = 0.2
    universalBtn.BorderSizePixel = 0
    universalBtn.Font = Enum.Font.GothamBold
    universalBtn.TextSize = 14
    universalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    universalBtn.Text = "Universal"
    universalBtn.AutoButtonColor = false
    universalBtn.Parent = mainFrame
    local uniCorner = Instance.new("UICorner")
    uniCorner.CornerRadius = UDim.new(0.2, 0)
    uniCorner.Parent = universalBtn
    universalBtn.MouseEnter:Connect(function()
        universalBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 230)
    end)
    universalBtn.MouseLeave:Connect(function()
        universalBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    end)
    universalBtn.MouseButton1Click:Connect(function()
        loadScript("https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/main.lua")
    end)
    
    local specificBtn = Instance.new("TextButton")
    specificBtn.Size = UDim2.new(0.8, 0, 0.25, 0)
    specificBtn.Position = UDim2.new(0.1, 0, 0.6, 0)
    specificBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    specificBtn.BackgroundTransparency = 0.2
    specificBtn.BorderSizePixel = 0
    specificBtn.Font = Enum.Font.GothamBold
    specificBtn.TextSize = 14
    specificBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    specificBtn.AutoButtonColor = false
    specificBtn.Parent = mainFrame
    local specCorner = Instance.new("UICorner")
    specCorner.CornerRadius = UDim.new(0.2, 0)
    specCorner.Parent = specificBtn
    specificBtn.MouseEnter:Connect(function()
        specificBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
    end)
    specificBtn.MouseLeave:Connect(function()
        specificBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    end)
    
    local gameInfo = supportedGames[gameId]
    if gameInfo and gameInfo.name then
        specificBtn.Text = "For This Game (" .. gameInfo.name .. ")"
    else
        specificBtn.Text = "For This Game"
    end
    
    specificBtn.MouseButton1Click:Connect(function()
        local gameData = supportedGames[gameId]
        if gameData and gameData.url then
            loadScript(gameData.url)
        else
            createNotification("No specific script available for this game", 2)
        end
    end)
    
    releaseMouse()
    
    local fadeIn = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.15
    })
    fadeIn:Play()
end

local function startScript()
    if supportedGames[gameId] then
        createMainGUI()
    else
        loadScript("https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/main.lua")
    end
end

local function createKeyGUI()
    if gui then
        gui:Destroy()
        gui = nil
    end
    
    gui = Instance.new("ScreenGui")
    gui.Name = "KeyGUI"
    gui.ResetOnSpawn = false
    gui.Parent = player.PlayerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 220)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -110)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0.02, 0)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(100, 100, 150)
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.5
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.18, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "EXVS ► Discord Key"
    title.Parent = mainFrame
    
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, 0, 0.2, 0)
    desc.Position = UDim2.new(0, 0, 0.18, 0)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 13
    desc.TextColor3 = Color3.fromRGB(180, 180, 200)
    desc.Text = "Join Discord to get the key:"
    desc.Parent = mainFrame
    
    local discordBtn = Instance.new("TextButton")
    discordBtn.Size = UDim2.new(0.7, 0, 0.15, 0)
    discordBtn.Position = UDim2.new(0.15, 0, 0.35, 0)
    discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    discordBtn.BackgroundTransparency = 0.2
    discordBtn.BorderSizePixel = 0
    discordBtn.Font = Enum.Font.GothamBold
    discordBtn.TextSize = 14
    discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordBtn.Text = "Join Discord"
    discordBtn.AutoButtonColor = false
    discordBtn.Parent = mainFrame
    local discCorner = Instance.new("UICorner")
    discCorner.CornerRadius = UDim.new(0.2, 0)
    discCorner.Parent = discordBtn
    discordBtn.MouseEnter:Connect(function()
        discordBtn.BackgroundColor3 = Color3.fromRGB(108, 121, 262)
    end)
    discordBtn.MouseLeave:Connect(function()
        discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    end)
    discordBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard("https://discord.gg/fpxfWh5kSG")
        end
        createNotification("Discord link copied to clipboard!", 2)
    end)
    
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(0.3, 0, 0.15, 0)
    keyLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Font = Enum.Font.GothamBold
    keyLabel.TextSize = 14
    keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyLabel.Text = "Enter Key:"
    keyLabel.TextXAlignment = Enum.TextXAlignment.Right
    keyLabel.Parent = mainFrame
    
    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(0.55, 0, 0.15, 0)
    keyBox.Position = UDim2.new(0.38, 0, 0.55, 0)
    keyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    keyBox.BackgroundTransparency = 0.2
    keyBox.BorderSizePixel = 0
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextSize = 14
    keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyBox.Text = ""
    keyBox.PlaceholderText = "Paste key here..."
    keyBox.ClearTextOnFocus = false
    keyBox.Parent = mainFrame
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0.02, 0)
    boxCorner.Parent = keyBox
    
    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Size = UDim2.new(0.3, 0, 0.15, 0)
    verifyBtn.Position = UDim2.new(0.35, 0, 0.78, 0)
    verifyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    verifyBtn.BackgroundTransparency = 0.2
    verifyBtn.BorderSizePixel = 0
    verifyBtn.Font = Enum.Font.GothamBold
    verifyBtn.TextSize = 14
    verifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    verifyBtn.Text = "Verify"
    verifyBtn.AutoButtonColor = false
    verifyBtn.Parent = mainFrame
    local verCorner = Instance.new("UICorner")
    verCorner.CornerRadius = UDim.new(0.2, 0)
    verCorner.Parent = verifyBtn
    verifyBtn.MouseEnter:Connect(function()
        verifyBtn.BackgroundColor3 = Color3.fromRGB(0, 230, 120)
    end)
    verifyBtn.MouseLeave:Connect(function()
        verifyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    end)
    
    local skipBtn = Instance.new("TextButton")
    skipBtn.Size = UDim2.new(0.3, 0, 0.12, 0)
    skipBtn.Position = UDim2.new(0.35, 0, 0.95, 0)
    skipBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    skipBtn.BackgroundTransparency = 0.5
    skipBtn.BorderSizePixel = 0
    skipBtn.Font = Enum.Font.Gotham
    skipBtn.TextSize = 12
    skipBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    skipBtn.Text = "Skip the key"
    skipBtn.AutoButtonColor = false
    skipBtn.Visible = false
    skipBtn.Parent = mainFrame
    local skipCorner = Instance.new("UICorner")
    skipCorner.CornerRadius = UDim.new(0.2, 0)
    skipCorner.Parent = skipBtn
    skipBtn.MouseEnter:Connect(function()
        skipBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
        skipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    skipBtn.MouseLeave:Connect(function()
        skipBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        skipBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    end)
    skipBtn.MouseButton1Click:Connect(function()
        keySkipped = true
        keyVerified = true
        gui:Destroy()
        gui = nil
        showMouse()
        startScript()
    end)
    
    task.delay(10, function()
        skipBtn.Visible = true
        local fadeIn = TweenService:Create(skipBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.3
        })
        fadeIn:Play()
    end)
    
    verifyBtn.MouseButton1Click:Connect(function()
        local inputKey = trim(keyBox.Text)
        if inputKey == getCorrectKey() then
            keyVerified = true
            if writefile then
                writefile("key.active", "")
            end
            createNotification("Key verified! Loading...", 1.5)
            task.wait(1.5)
            gui:Destroy()
            gui = nil
            showMouse()
            startScript()
        else
            createNotification("Invalid key! Please try again.", 2)
        end
    end)
    
    releaseMouse()
end

local function onCharacterAdded()
    if scriptActive and mouseReleased then
        task.wait(0.5)
        setThirdPerson()
    end
end

player.CharacterAdded:Connect(onCharacterAdded)

if isfile and isfile("key.active") then
    keyVerified = true
    createNotification("Key already active! Loading...", 1.5)
    task.wait(1)
    startScript()
else
    createKeyGUI()
end
