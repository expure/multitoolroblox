local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local gameId = game.PlaceId

local supportedGames = {
    [6961824067] = {
        url = "https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/FTAP.lua",
        name = "FTAP"
    }
}

local gui = nil
local mouseReleased = false
local originalCameraType = nil
local originalCameraSubject = nil
local cameraForceConnection = nil
local scriptActive = true

local function forceThirdPersonCamera()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    if camera.CameraType ~= Enum.CameraType.Custom then
        originalCameraType = camera.CameraType
        originalCameraSubject = camera.CameraSubject
        camera.CameraType = Enum.CameraType.Custom
    end
    
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    if humanoid then
        camera.CameraSubject = humanoid
    end
    
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local currentCF = camera.CFrame
        local desiredPos = hrp.Position + Vector3.new(0, 2, 5)
        local desiredCF = CFrame.new(desiredPos, hrp.Position)
        if (currentCF.Position - desiredPos).Magnitude > 0.5 then
            camera.CFrame = desiredCF
        end
    end
end

local function startCameraForce()
    if cameraForceConnection then
        cameraForceConnection:Disconnect()
        cameraForceConnection = nil
    end
    
    cameraForceConnection = RunService.RenderStepped:Connect(function()
        if scriptActive and mouseReleased then
            forceThirdPersonCamera()
        end
    end)
end

local function stopCameraForce()
    if cameraForceConnection then
        cameraForceConnection:Disconnect()
        cameraForceConnection = nil
    end
end

local function releaseMouse()
    if not mouseReleased and scriptActive then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        
        local success, err = pcall(function()
            game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end)
        
        forceThirdPersonCamera()
        startCameraForce()
        
        mouseReleased = true
    end
end

local function lockMouse()
    if mouseReleased then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
        
        local camera = workspace.CurrentCamera
        if camera and originalCameraType then
            camera.CameraType = originalCameraType
            camera.CameraSubject = originalCameraSubject
        end
        
        stopCameraForce()
        
        mouseReleased = false
    end
end

local function fullCleanup()
    scriptActive = false
    stopCameraForce()
    lockMouse()
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

local function onCharacterAdded()
    if scriptActive and mouseReleased then
        task.wait(0.5)
        forceThirdPersonCamera()
    end
end

player.CharacterAdded:Connect(onCharacterAdded)

if supportedGames[gameId] then
    createMainGUI()
else
    lockMouse()
    loadScript("https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/main.lua")
end
