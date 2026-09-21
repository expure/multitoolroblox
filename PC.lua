local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playerName = player.Name
local camera = workspace.CurrentCamera
if  _G.sourcecheckexvs ~= "source" then 
    warn("https://rscripts.net/script/multi-tool-hub-X0cu")
    error("The script source is not supported! Please use EXVS Hub from link upper!", 0)
end
local ourAircraft = nil
local targetRootPart = nil
local targetName = ""
local targetAircraftModel = nil
local isConnected = false
local isFollowing = false
local followMode = ""
local aimbotActive = false
local manualAttackActive = false
local controlActive = false
local keysPressed = {W = false, A = false, S = false, D = false}
local stopBind = Enum.KeyCode.F
local safeAttackActive = false
local autoRetryActive = false
local autoTargetTriggered = false

local predictionEnabled = true
local lastTargetPos = nil
local lastTargetTime = nil
local targetVelocity = Vector3.new(0,0,0)
local pingEstimate = 0.15

local mainLoopConnection = nil
local autoTargetActive = false
local retryMonitorConnection = nil

local bodyAngularVelocity = nil
local bodyVelocity = nil
local followBodyVelocity = nil

local easySelectActive = false
local easySelectMap = {}
local easySelectBtnList = {}
local easySelectUpdateConnection = nil
local easySelectScanning = false
local easySelectPeriodicConnection = nil

local showIndicator = true
local targetIndicator = nil
local targetHighlight = nil

local screenGui = nil
local mainFrame = nil
local GUI = {}

local function createGUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AircraftAttack"
    screenGui.Parent = playerGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 360, 0, 720)
    mainFrame.Position = UDim2.new(0.5, -180, 0.5, -360)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BackgroundTransparency = 0.95
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.Image = "rbxassetid://1316044617"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.BackgroundTransparency = 1
    shadow.ZIndex = 0
    shadow.Parent = mainFrame

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, -4, 1, -4)
    panel.Position = UDim2.new(0, 2, 0, 2)
    panel.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    panel.BackgroundTransparency = 0.3
    panel.BorderSizePixel = 0
    panel.Parent = mainFrame
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 10)
    panelCorner.Parent = panel

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
    titleBar.BackgroundTransparency = 0.2
    titleBar.BorderSizePixel = 0
    titleBar.Parent = panel
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 60, 90)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 30, 50))
    })
    gradient.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Aircraft Attack"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        if screenGui then screenGui:Destroy() end
    end)
    closeBtn.MouseEnter:Connect(function()
        closeBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
        closeBtn.BackgroundTransparency = 0.3
    end)
    closeBtn.MouseLeave:Connect(function()
        closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
        closeBtn.BackgroundTransparency = 0.5
    end)

    local dragStart, dragPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = input.Position
            dragPos = mainFrame.Position
        end
    end)
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                dragPos.X.Scale,
                dragPos.X.Offset + delta.X,
                dragPos.Y.Scale,
                dragPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = nil
        end
    end)

    GUI.statusLabel = Instance.new("TextLabel")
    GUI.statusLabel.Size = UDim2.new(1, -20, 0, 24)
    GUI.statusLabel.Position = UDim2.new(0, 10, 0, 55)
    GUI.statusLabel.BackgroundTransparency = 1
    GUI.statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    GUI.statusLabel.Text = "Not connected"
    GUI.statusLabel.Font = Enum.Font.Gotham
    GUI.statusLabel.TextSize = 14
    GUI.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    GUI.statusLabel.Parent = panel

    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -20, 0, 1)
    sep.Position = UDim2.new(0, 10, 0, 82)
    sep.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    sep.BackgroundTransparency = 0.5
    sep.BorderSizePixel = 0
    sep.Parent = panel

    GUI.targetBox = Instance.new("TextBox")
    GUI.targetBox.Size = UDim2.new(0, 220, 0, 32)
    GUI.targetBox.Position = UDim2.new(0.5, -110, 0, 95)
    GUI.targetBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    GUI.targetBox.TextColor3 = Color3.fromRGB(220, 220, 255)
    GUI.targetBox.PlaceholderText = "Enter target name"
    GUI.targetBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 180)
    GUI.targetBox.Text = ""
    GUI.targetBox.Font = Enum.Font.Gotham
    GUI.targetBox.TextSize = 14
    GUI.targetBox.ClearTextOnFocus = false
    GUI.targetBox.BorderSizePixel = 0
    GUI.targetBox.Parent = panel
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = GUI.targetBox

    local function createStyledButton(text, yPos, color, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 0, 30)
        btn.Position = UDim2.new(0.5, -50, 0, yPos)
        btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 70)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.BorderSizePixel = 0
        btn.Parent = panel
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = color and color:Lerp(Color3.new(1,1,1), 0.2) or Color3.fromRGB(70, 70, 90)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 70)
        end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    GUI.connectBtn = createStyledButton("Connect", 140, Color3.fromRGB(30, 80, 50))
    GUI.connectBtn.Size = UDim2.new(0, 120, 0, 32)
    GUI.connectBtn.Position = UDim2.new(0.5, -60, 0, 140)

    GUI.tpBtn = createStyledButton("TP", 185, Color3.fromRGB(30, 60, 120))
    GUI.tpBtn.Size = UDim2.new(0, 90, 0, 30)
    GUI.tpBtn.Position = UDim2.new(0.5, -95, 0, 185)
    GUI.tpBtn.Visible = false

    GUI.bpBtn = createStyledButton("BP", 185, Color3.fromRGB(30, 100, 80))
    GUI.bpBtn.Size = UDim2.new(0, 90, 0, 30)
    GUI.bpBtn.Position = UDim2.new(0.5, 5, 0, 185)
    GUI.bpBtn.Visible = false

    GUI.fpBtn = createStyledButton("FP", 185, Color3.fromRGB(80, 40, 100))
    GUI.fpBtn.Size = UDim2.new(0, 90, 0, 30)
    GUI.fpBtn.Position = UDim2.new(0.5, -95, 0, 225)
    GUI.fpBtn.Visible = false

    GUI.aimbotToggle = createStyledButton("Aimbot: OFF", 265, Color3.fromRGB(60, 50, 90))
    GUI.aimbotToggle.Size = UDim2.new(0, 120, 0, 30)
    GUI.aimbotToggle.Position = UDim2.new(0.5, -60, 0, 265)
    GUI.aimbotToggle.Visible = false

    GUI.autoTargetBtn = createStyledButton("Auto Target", 305, Color3.fromRGB(40, 80, 60))
    GUI.autoTargetBtn.Size = UDim2.new(0, 120, 0, 30)
    GUI.autoTargetBtn.Position = UDim2.new(0.5, -60, 0, 305)
    GUI.autoTargetBtn.Visible = false

    GUI.manualAttackBtn = createStyledButton("Manual Attack: OFF", 345, Color3.fromRGB(80, 40, 40))
    GUI.manualAttackBtn.Size = UDim2.new(0, 140, 0, 30)
    GUI.manualAttackBtn.Position = UDim2.new(0.5, -70, 0, 345)
    GUI.manualAttackBtn.Visible = false

    GUI.controlBtn = createStyledButton("Control: OFF", 385, Color3.fromRGB(40, 70, 90))
    GUI.controlBtn.Size = UDim2.new(0, 140, 0, 30)
    GUI.controlBtn.Position = UDim2.new(0.5, -70, 0, 385)
    GUI.controlBtn.Visible = false

    GUI.predictionBtn = createStyledButton("Prediction: ON", 425, Color3.fromRGB(50, 50, 80))
    GUI.predictionBtn.Size = UDim2.new(0, 140, 0, 30)
    GUI.predictionBtn.Position = UDim2.new(0.5, -70, 0, 425)
    GUI.predictionBtn.Visible = false

    GUI.easySelectBtn = createStyledButton("Easy-Select: OFF", 465, Color3.fromRGB(40, 60, 100))
    GUI.easySelectBtn.Size = UDim2.new(0, 140, 0, 30)
    GUI.easySelectBtn.Position = UDim2.new(0.5, -70, 0, 465)
    GUI.easySelectBtn.Visible = false

    GUI.safeAttackBtn = createStyledButton("Safe Attack: OFF", 505, Color3.fromRGB(60, 70, 40))
    GUI.safeAttackBtn.Size = UDim2.new(0, 140, 0, 30)
    GUI.safeAttackBtn.Position = UDim2.new(0.5, -70, 0, 505)
    GUI.safeAttackBtn.Visible = false

    GUI.autoRetryBtn = createStyledButton("Auto Retry: OFF", 545, Color3.fromRGB(80, 60, 30))
    GUI.autoRetryBtn.Size = UDim2.new(0, 140, 0, 30)
    GUI.autoRetryBtn.Position = UDim2.new(0.5, -70, 0, 545)
    GUI.autoRetryBtn.Visible = false

    GUI.indicatorBtn = createStyledButton("Indicator: ON", 585, Color3.fromRGB(40, 120, 80))
    GUI.indicatorBtn.Size = UDim2.new(0, 140, 0, 30)
    GUI.indicatorBtn.Position = UDim2.new(0.5, -70, 0, 585)
    GUI.indicatorBtn.Visible = false

    GUI.bindBtn = createStyledButton("Bind Stop: F", 625, Color3.fromRGB(80, 40, 40))
    GUI.bindBtn.Size = UDim2.new(0, 140, 0, 30)
    GUI.bindBtn.Position = UDim2.new(0.5, -70, 0, 625)
    GUI.bindBtn.Visible = false

    GUI.targetDisplay = Instance.new("TextLabel")
    GUI.targetDisplay.Size = UDim2.new(1, -20, 0, 24)
    GUI.targetDisplay.Position = UDim2.new(0, 10, 0, 660)
    GUI.targetDisplay.BackgroundTransparency = 1
    GUI.targetDisplay.TextColor3 = Color3.fromRGB(100, 200, 255)
    GUI.targetDisplay.Text = "Target: none"
    GUI.targetDisplay.Font = Enum.Font.Gotham
    GUI.targetDisplay.TextSize = 14
    GUI.targetDisplay.TextXAlignment = Enum.TextXAlignment.Left
    GUI.targetDisplay.Parent = panel

    GUI.debugLabel = Instance.new("TextLabel")
    GUI.debugLabel.Size = UDim2.new(1, -20, 0, 18)
    GUI.debugLabel.Position = UDim2.new(0, 10, 0, 685)
    GUI.debugLabel.BackgroundTransparency = 1
    GUI.debugLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
    GUI.debugLabel.Text = ""
    GUI.debugLabel.Font = Enum.Font.Gotham
    GUI.debugLabel.TextSize = 11
    GUI.debugLabel.TextXAlignment = Enum.TextXAlignment.Left
    GUI.debugLabel.Parent = panel
end

createGUI()

local function updateStatus(text, color)
    GUI.statusLabel.Text = text
    GUI.statusLabel.TextColor3 = color or Color3.fromRGB(255, 200, 100)
end

local function showMessage(text, duration)
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(0, 310, 0, 30)
    msg.Position = UDim2.new(0.5, -155, 1, -40)
    msg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    msg.TextColor3 = Color3.fromRGB(255, 255, 100)
    msg.Text = text
    msg.TextScaled = true
    msg.Font = Enum.Font.Gotham
    msg.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = msg
    msg.Parent = mainFrame
    wait(duration or 2)
    msg:Destroy()
end

local function findModelRecursive(container, namePattern)
    for _, obj in pairs(container:GetChildren()) do
        if obj:IsA("Model") and string.find(string.lower(obj.Name), string.lower(namePattern)) then
            return obj
        end
        local found = findModelRecursive(obj, namePattern)
        if found then return found end
    end
    return nil
end

local function findAircraft(playerName)
    local pattern = playerName .. " Aircraft"
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name == pattern then
            return obj
        end
    end
    return findModelRecursive(Workspace, pattern)
end

local function findPlayerModel(playerName)
    return findModelRecursive(Workspace, playerName)
end

local function getRootPart(model)
    if not model then return nil end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then return root end
    root = model:FindFirstChild("Torso")
    if root then return root end
    root = model:FindFirstChild("UpperTorso")
    return root
end

local function updateIndicator()
    if targetIndicator then
        targetIndicator:Destroy()
        targetIndicator = nil
    end
    if targetHighlight then
        targetHighlight:Destroy()
        targetHighlight = nil
    end
    if not showIndicator or not targetRootPart then return end
    local indicator = Instance.new("Part")
    indicator.Name = "TargetIndicator"
    indicator.Size = Vector3.new(35, 35, 35)
    indicator.Shape = Enum.PartType.Ball
    indicator.Material = Enum.Material.SmoothPlastic
    indicator.Color = Color3.fromRGB(0, 255, 128)
    indicator.Transparency = 0.6
    indicator.Anchored = true
    indicator.CanCollide = false
    indicator.Position = targetRootPart.Position
    indicator.Parent = Workspace

    local hl = Instance.new("Highlight")
    hl.Adornee = indicator
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.FillTransparency = 0.8
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.OutlineTransparency = 0
    hl.Parent = indicator

    targetIndicator = indicator
    targetHighlight = hl
end

local function destroyIndicator()
    if targetIndicator then
        targetIndicator:Destroy()
        targetIndicator = nil
    end
    if targetHighlight then
        targetHighlight:Destroy()
        targetHighlight = nil
    end
end

local function setTarget(name)
    targetName = name
    local aircraft = findAircraft(name)
    if aircraft then
        targetAircraftModel = aircraft
        local root = getRootPart(aircraft)
        if root then
            targetRootPart = root
            GUI.targetDisplay.Text = "Target: " .. name .. " (Aircraft)"
            updateIndicator()
            return true
        end
    end
    targetAircraftModel = nil
    local playerModel = findPlayerModel(name)
    if playerModel then
        local root = getRootPart(playerModel)
        if root then
            targetRootPart = root
            GUI.targetDisplay.Text = "Target: " .. name .. " (Player)"
            updateIndicator()
            return true
        end
    end
    targetRootPart = nil
    GUI.targetDisplay.Text = "Target: none"
    destroyIndicator()
    return false
end

local function resumeFollow()
    print("[ResumeFollow] Called. isFollowing=", isFollowing, " followMode=", followMode)
    if not ourAircraft then
        print("[ResumeFollow] no ourAircraft")
        return
    end
    if not isFollowing or followMode == "" then
        print("[ResumeFollow] Not following or mode empty, skip")
        return
    end
    if not targetRootPart or not targetRootPart.Parent then
        print("[ResumeFollow] No target, launching Auto Target")
        autoTarget()
        return
    end
    if followMode == "TP" then
        followTP()
    elseif followMode == "BP" then
        followBP()
    elseif followMode == "FP" then
        followFP()
    end
    startMainLoop()
    print("[ResumeFollow] Follow restarted in mode:", followMode)
end

local function autoTarget()
    if not isConnected then
        showMessage("Connect first", 2)
        return
    end
    if autoTargetActive then
        showMessage("Auto Target already running", 1.5)
        return
    end
    if autoTargetTriggered then
        print("[AutoTarget] Already triggered, skipping")
        return
    end
    autoTargetTriggered = true
    autoTargetActive = true
    showMessage("Auto Target: scanning for Aircraft only... (45 sec)", 2)
    GUI.debugLabel.Text = "Auto Target: scanning..."
    local startTime = tick()
    local found = false
    local connection = RunService.Heartbeat:Connect(function()
        if tick() - startTime > 45 then
            connection:Disconnect()
            autoTargetActive = false
            autoTargetTriggered = false
            if not found then
                showMessage("Auto Target: no Aircraft found after 45 sec", 2)
                GUI.debugLabel.Text = "Auto Target: no Aircraft found"
            end
            return
        end
        local function scanForAircraft(container)
            for _, obj in pairs(container:GetChildren()) do
                if obj:IsA("Model") and string.find(string.lower(obj.Name), "aircraft") and obj ~= ourAircraft then
                    local root = getRootPart(obj)
                    if root then
                        targetRootPart = root
                        targetAircraftModel = obj
                        targetName = obj.Name:gsub(" Aircraft", "")
                        GUI.targetDisplay.Text = "Target: " .. targetName .. " (Auto)"
                        updateIndicator()
                        found = true
                        connection:Disconnect()
                        autoTargetActive = false
                        autoTargetTriggered = false
                        showMessage("Auto Target: " .. targetName .. " found!", 2)
                        GUI.debugLabel.Text = "Auto Target: found " .. targetName
                        resumeFollow()
                        return true
                    end
                end
                if scanForAircraft(obj) then return true end
            end
            return false
        end
        scanForAircraft(Workspace)
    end)
end

local function updateTargetVelocity()
    if not targetRootPart then return end
    local currentPos = targetRootPart.Position
    local currentTime = tick()
    if lastTargetPos and lastTargetTime then
        local dt = currentTime - lastTargetTime
        if dt > 0.01 then
            targetVelocity = (currentPos - lastTargetPos) / dt
        end
    end
    lastTargetPos = currentPos
    lastTargetTime = currentTime
end

local function getPredictedTargetPos()
    if not targetRootPart then return nil end
    local currentPos = targetRootPart.Position
    local predictionTime = pingEstimate + 0.05
    return currentPos + targetVelocity * predictionTime
end

local function stopFollowingAndAimbot()
    isFollowing = false
    aimbotActive = false
    if followBodyVelocity then
        followBodyVelocity:Destroy()
        followBodyVelocity = nil
    end
    if retryMonitorConnection then
        retryMonitorConnection:Disconnect()
        retryMonitorConnection = nil
    end
    GUI.aimbotToggle.Text = "Aimbot: OFF"
    GUI.aimbotToggle.BackgroundColor3 = Color3.fromRGB(60, 50, 90)
    updateStatus("Following & Aimbot stopped", Color3.fromRGB(255, 150, 150))
    showMessage("Following & Aimbot stopped", 1.5)
    if mainLoopConnection and not controlActive and not manualAttackActive then
        mainLoopConnection:Disconnect()
        mainLoopConnection = nil
    end
end

local function attemptRetry(retryType)
    if retryType == "target" then
        if not autoRetryActive or not isFollowing or not targetName then
            print("[AutoRetry] attemptRetry(target) skipped: autoRetryActive=", autoRetryActive, " isFollowing=", isFollowing, " targetName=", targetName)
            return false
        end
        print("[AutoRetry] Starting active search for target:", targetName)
        showMessage("Auto Retry: actively searching for target " .. targetName .. " (45 sec)", 2)
        updateStatus("Retrying target...", Color3.fromRGB(255, 200, 100))
    else
        if not autoRetryActive then
            print("[AutoRetry] attemptRetry(self) skipped: autoRetryActive=false")
            return false
        end
        print("[AutoRetry] Starting active search for own Aircraft:", playerName)
        showMessage("Auto Retry: actively searching for your Aircraft (45 sec)", 2)
        updateStatus("Retrying self Aircraft...", Color3.fromRGB(255, 200, 100))
    end

    local startTime = tick()
    local success = false
    local searchName = (retryType == "target") and targetName or playerName
    local buildGUI = playerGui:FindFirstChild("BuildGUI2")
    local toolbar = buildGUI and buildGUI:FindFirstChild("Toolbar")
    local playButton = toolbar and toolbar:FindFirstChild("PlayButton")

    while tick() - startTime < 45 do
        local aircraft = findAircraft(searchName)
        if aircraft then
            local root = getRootPart(aircraft)
            if root then
                if retryType == "target" then
                    targetAircraftModel = aircraft
                    targetRootPart = root
                else
                    ourAircraft = aircraft
                    isConnected = true
                end
                success = true
                print("[AutoRetry] Aircraft found for", searchName)
                break
            end
        end

        if retryType == "target" then
            local playerModel = findPlayerModel(searchName)
            if playerModel then
                local root = getRootPart(playerModel)
                if root then
                    targetAircraftModel = nil
                    targetRootPart = root
                    success = true
                    print("[AutoRetry] Player model found for", searchName)
                    break
                end
            end
        end

        if toolbar and toolbar.Visible and playButton then
            print("[AutoRetry] Toolbar visible, activating PlayButton via VirtualInputManager")
            local previousSelected = GuiService.SelectedObject
            playButton.Active = true
            playButton.Selectable = true
            GuiService.SelectedObject = playButton
            task.wait(0.1)
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            end)
            task.wait(0.1)
            GuiService.SelectedObject = previousSelected
            showMessage("PlayButton clicked, waiting 3 sec...", 1)
        end

        if retryType == "self" then
            local connSuccess = (findAircraft(playerName) ~= nil)
            if connSuccess then
                ourAircraft = findAircraft(playerName)
                isConnected = true
                success = true
                break
            end
        end

        wait(3)
    end

    if success then
        if retryType == "target" then
            showMessage("Auto Retry: target found!", 2)
            updateStatus("Connected to " .. targetName, Color3.fromRGB(100, 255, 100))
            resumeFollow()
        else
            showMessage("Auto Retry: your Aircraft restored!", 2)
            updateStatus("Aircraft restored", Color3.fromRGB(100, 255, 100))
            resumeFollow()
        end
        return true
    else
        if retryType == "target" then
            print("[AutoRetry] Retry target failed: target not found within 45 sec")
            showMessage("Can't retry target! Target lost.", 3)
            updateStatus("Retry target failed", Color3.fromRGB(255, 100, 100))
            if autoRetryActive and isConnected then
                print("[AutoRetry] Launching Auto Target instead of target")
                autoTarget()
            end
        else
            print("[AutoRetry] Retry self failed: own Aircraft not found within 45 sec")
            showMessage("Can't retry your Aircraft! Script stopped.", 3)
            updateStatus("Retry self failed", Color3.fromRGB(255, 100, 100))
            autoRetryActive = false
            GUI.autoRetryBtn.Text = "Auto Retry: OFF"
            GUI.autoRetryBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 30)
            stopFollowingAndAimbot()
        end
        return false
    end
end

local function startRetryMonitor()
    if retryMonitorConnection then
        retryMonitorConnection:Disconnect()
        retryMonitorConnection = nil
    end
    if not autoRetryActive then
        print("[AutoRetry] Monitor not started: autoRetryActive = false")
        return
    end
    print("[AutoRetry] Monitor started (watching own Aircraft)")

    local selfCheckTimer = 0

    retryMonitorConnection = RunService.Heartbeat:Connect(function()
        if not autoRetryActive then
            print("[AutoRetry] Monitor stopped: autoRetryActive=false")
            retryMonitorConnection:Disconnect()
            retryMonitorConnection = nil
            return
        end

        selfCheckTimer = selfCheckTimer + 0.05
        if selfCheckTimer >= 3 then
            selfCheckTimer = 0
            if not ourAircraft or not ourAircraft.Parent then
                print("[AutoRetry] Own Aircraft lost! Launching retry self...")
                if followBodyVelocity then
                    followBodyVelocity:Destroy()
                    followBodyVelocity = nil
                end
                retryMonitorConnection:Disconnect()
                retryMonitorConnection = nil
                local ok = attemptRetry("self")
                if ok then
                    print("[AutoRetry] Self restored, restarting monitor")
                    startRetryMonitor()
                else
                    print("[AutoRetry] Failed to restore Aircraft, monitor stopped")
                end
                return
            end
        end
    end)
end

local function mainLoop()
    if not ourAircraft then return end
    local primaryPart = ourAircraft.PrimaryPart or ourAircraft:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then return end

    if isFollowing and followMode == "TP" and targetRootPart then
        local targetPos = predictionEnabled and getPredictedTargetPos() or targetRootPart.Position
        if targetPos then
            local direction = targetPos - primaryPart.Position
            local distance = direction.Magnitude
            if distance > 0.5 then
                local speed = distance > 1000 and 8000 or distance > 500 and 4000 or distance > 200 and 2000 or distance > 100 and 1000 or distance > 75 and 500 or 350
                local velocity = direction.Unit * speed
                if not followBodyVelocity then
                    followBodyVelocity = Instance.new("BodyVelocity")
                    followBodyVelocity.MaxForce = Vector3.new(1e7, 1e7, 1e7)
                    followBodyVelocity.Parent = primaryPart
                end
                followBodyVelocity.Velocity = velocity
            else
                if followBodyVelocity then followBodyVelocity:Destroy(); followBodyVelocity = nil end
                primaryPart.CFrame = CFrame.new(targetPos)
            end
        end
    else
        if followBodyVelocity then followBodyVelocity:Destroy(); followBodyVelocity = nil end
    end

    if isFollowing and followMode == "FP" and targetRootPart then
        local targetPos = predictionEnabled and getPredictedTargetPos() or targetRootPart.Position
        if targetPos then
            local distance = (targetPos - primaryPart.Position).Magnitude
            if distance > 0.5 then
                local lerpAlpha = distance > 500 and 0.8 or distance > 100 and 0.6 or 0.4
                primaryPart.CFrame = primaryPart.CFrame:Lerp(CFrame.new(targetPos), lerpAlpha)
            else
                primaryPart.CFrame = CFrame.new(targetPos)
            end
        end
    end

    if controlActive then
        local moveVec = Vector3.new(0,0,0)
        if keysPressed.W then moveVec = moveVec + camera.CFrame.LookVector end
        if keysPressed.S then moveVec = moveVec - camera.CFrame.LookVector end
        if keysPressed.A then moveVec = moveVec - camera.CFrame.RightVector end
        if keysPressed.D then moveVec = moveVec + camera.CFrame.RightVector end
        moveVec = Vector3.new(moveVec.X, 0, moveVec.Z)
        if moveVec.Magnitude > 0 then
            moveVec = moveVec.Unit * 800
            if not bodyVelocity then
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                bodyVelocity.Velocity = moveVec
                bodyVelocity.Parent = primaryPart
            else
                bodyVelocity.Velocity = moveVec
            end
        else
            if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
        end
    else
        if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
    end

    if manualAttackActive then
        if not bodyAngularVelocity then
            bodyAngularVelocity = Instance.new("BodyAngularVelocity")
            bodyAngularVelocity.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            bodyAngularVelocity.AngularVelocity = Vector3.new(15, 10, 8)
            bodyAngularVelocity.Parent = primaryPart
        end
    else
        if bodyAngularVelocity then bodyAngularVelocity:Destroy(); bodyAngularVelocity = nil end
    end

    if aimbotActive and targetRootPart then
        local cam = workspace.CurrentCamera
        if cam then
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetRootPart.Position + Vector3.new(0, 1.5, 0))
        end
    end

    if showIndicator and targetIndicator and targetRootPart then
        targetIndicator.Position = targetRootPart.Position
    end
end

local function startMainLoop()
    if not mainLoopConnection then
        mainLoopConnection = RunService.Heartbeat:Connect(mainLoop)
    end
end

local function teleportToSafePosition()
    if not ourAircraft or not targetRootPart then return end
    local primaryPart = ourAircraft.PrimaryPart or ourAircraft:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then return end
    local targetPos = targetRootPart.Position
    local currentPos = primaryPart.Position
    local distance = (targetPos - currentPos).Magnitude
    if distance <= 5 then return end
    local direction = (currentPos - targetPos).Unit
    local safePos = targetPos + direction * 5
    primaryPart.CFrame = CFrame.new(safePos)
    showMessage("Teleported to safe position (5 studs from target)", 1.5)
end

local function followTP()
    if not ourAircraft or not targetRootPart then
        showMessage("Missing aircraft or target", 2)
        return
    end
    if isFollowing then
        if followBodyVelocity then followBodyVelocity:Destroy(); followBodyVelocity = nil end
        isFollowing = false
    end
    if safeAttackActive then
        teleportToSafePosition()
        wait(0.1)
    end
    isFollowing = true
    followMode = "TP"
    updateStatus("Following (TP) ... press Bind Stop", Color3.fromRGB(100, 255, 100))
    startMainLoop()
    if autoRetryActive then startRetryMonitor() end
end

local function followBP()
    if not ourAircraft or not targetRootPart then
        showMessage("Missing aircraft or target", 2)
        return
    end
    if isFollowing then
        if followBodyVelocity then followBodyVelocity:Destroy(); followBodyVelocity = nil end
        isFollowing = false
    end
    if safeAttackActive then
        teleportToSafePosition()
        wait(0.1)
    end
    isFollowing = true
    followMode = "BP"
    local primaryPart = ourAircraft.PrimaryPart or ourAircraft:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then return end
    local function startBPTween()
        if not targetRootPart then return nil end
        local targetPos = targetRootPart.Position
        local dist = (targetPos - primaryPart.Position).Magnitude
        local speed = dist > 100 and 3500 or 500
        local duration = dist / speed
        if duration < 0.05 then duration = 0.05 end
        local tween = TweenService:Create(primaryPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
        tween:Play()
        return tween
    end
    local currentTween = startBPTween()
    spawn(function()
        while isFollowing and followMode == "BP" do
            wait(0.3)
            if not targetRootPart then break end
            local newPos = targetRootPart.Position
            local dist = (newPos - primaryPart.Position).Magnitude
            if dist > 1 then
                if currentTween then currentTween:Cancel() end
                currentTween = startBPTween()
            end
        end
    end)
    updateStatus("Following (BP) ... press Bind Stop", Color3.fromRGB(100, 255, 100))
    startMainLoop()
    if autoRetryActive then startRetryMonitor() end
end

local function followFP()
    if not ourAircraft or not targetRootPart then
        showMessage("Missing aircraft or target", 2)
        return
    end
    if isFollowing then
        if followBodyVelocity then followBodyVelocity:Destroy(); followBodyVelocity = nil end
        isFollowing = false
    end
    if safeAttackActive then
        teleportToSafePosition()
        wait(0.1)
    end
    isFollowing = true
    followMode = "FP"
    updateStatus("Following (FP) ... press Bind Stop", Color3.fromRGB(200, 150, 255))
    startMainLoop()
    if autoRetryActive then startRetryMonitor() end
end

local function toggleAimbot()
    if not targetRootPart then
        showMessage("No target set", 2)
        return
    end
    aimbotActive = not aimbotActive
    if aimbotActive then
        GUI.aimbotToggle.Text = "Aimbot: ON"
        GUI.aimbotToggle.BackgroundColor3 = Color3.fromRGB(30, 120, 30)
        updateStatus("Aimbot ON", Color3.fromRGB(100, 255, 100))
        startMainLoop()
    else
        GUI.aimbotToggle.Text = "Aimbot: OFF"
        GUI.aimbotToggle.BackgroundColor3 = Color3.fromRGB(60, 50, 90)
        updateStatus("Aimbot OFF", Color3.fromRGB(255, 200, 100))
        if not isFollowing and not controlActive and not manualAttackActive and mainLoopConnection then
            mainLoopConnection:Disconnect()
            mainLoopConnection = nil
        end
    end
end

local function toggleManualAttack()
    if not ourAircraft then
        showMessage("Connect first", 2)
        return
    end
    manualAttackActive = not manualAttackActive
    if manualAttackActive then
        GUI.manualAttackBtn.Text = "Manual Attack: ON"
        GUI.manualAttackBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
        updateStatus("Manual Attack ON (physics)", Color3.fromRGB(255, 150, 150))
        startMainLoop()
    else
        GUI.manualAttackBtn.Text = "Manual Attack: OFF"
        GUI.manualAttackBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
        updateStatus("Manual Attack OFF", Color3.fromRGB(255, 200, 100))
        if bodyAngularVelocity then
            bodyAngularVelocity:Destroy()
            bodyAngularVelocity = nil
        end
        if not isFollowing and not aimbotActive and not controlActive and mainLoopConnection then
            mainLoopConnection:Disconnect()
            mainLoopConnection = nil
        end
    end
end

local function toggleControl()
    if not ourAircraft then
        showMessage("Connect first", 2)
        return
    end
    controlActive = not controlActive
    if controlActive then
        GUI.controlBtn.Text = "Control: ON"
        GUI.controlBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 120)
        updateStatus("Control ON (WASD, 800 sps)", Color3.fromRGB(100, 255, 200))
        startMainLoop()
    else
        GUI.controlBtn.Text = "Control: OFF"
        GUI.controlBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 90)
        updateStatus("Control OFF", Color3.fromRGB(255, 200, 100))
        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
        keysPressed.W = false
        keysPressed.A = false
        keysPressed.S = false
        keysPressed.D = false
        if not isFollowing and not aimbotActive and not manualAttackActive and mainLoopConnection then
            mainLoopConnection:Disconnect()
            mainLoopConnection = nil
        end
    end
end

local function togglePrediction()
    predictionEnabled = not predictionEnabled
    GUI.predictionBtn.Text = predictionEnabled and "Prediction: ON" or "Prediction: OFF"
    GUI.predictionBtn.BackgroundColor3 = predictionEnabled and Color3.fromRGB(50, 50, 80) or Color3.fromRGB(80, 50, 50)
    showMessage(predictionEnabled and "Prediction enabled" or "Prediction disabled", 1.5)
end

local function toggleSafeAttack()
    safeAttackActive = not safeAttackActive
    GUI.safeAttackBtn.Text = safeAttackActive and "Safe Attack: ON" or "Safe Attack: OFF"
    GUI.safeAttackBtn.BackgroundColor3 = safeAttackActive and Color3.fromRGB(60, 120, 40) or Color3.fromRGB(60, 70, 40)
    showMessage(safeAttackActive and "Safe Attack ENABLED" or "Safe Attack DISABLED", 2)
end

local function toggleAutoRetry()
    autoRetryActive = not autoRetryActive
    if autoRetryActive then
        GUI.autoRetryBtn.Text = "Auto Retry: ON"
        GUI.autoRetryBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 40)
        showMessage("Auto Retry ENABLED (restores Aircraft even without following)", 2)
        startRetryMonitor()
    else
        GUI.autoRetryBtn.Text = "Auto Retry: OFF"
        GUI.autoRetryBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 30)
        if retryMonitorConnection then
            retryMonitorConnection:Disconnect()
            retryMonitorConnection = nil
        end
        showMessage("Auto Retry DISABLED", 1.5)
    end
end

local function isTargetModel(model)
    if not model or not model:IsA("Model") then return false end
    if model == ourAircraft or model == player.Character then return false end
    local hasHumanoid = model:FindFirstChild("Humanoid") ~= nil
    local isAircraft = string.find(string.lower(model.Name), "aircraft") ~= nil
    return isAircraft or hasHumanoid
end

local function createButtonForModel(model)
    if not model or not isTargetModel(model) then return end
    if easySelectMap[model] then return end
    local root = getRootPart(model)
    if not root or not root:IsA("BasePart") then
        if not easySelectMap[model] then
            easySelectMap[model] = {listening = true}
            local conn = model.ChildAdded:Connect(function(child)
                if child:IsA("BasePart") and (child.Name == "HumanoidRootPart" or child.Name == "Torso" or child.Name == "UpperTorso") then
                    conn:Disconnect()
                    createButtonForModel(model)
                end
            end)
            easySelectMap[model].conn = conn
        end
        return
    end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 120)
    btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    btn.BackgroundTransparency = 0.75
    btn.Text = model.Name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = screenGui
    btn.ZIndex = 10
    btn:SetAttribute("TargetName", model.Name)
    btn.MouseButton1Click:Connect(function()
        local targetNameAttr = btn:GetAttribute("TargetName")
        if targetNameAttr and root then
            targetRootPart = root
            targetName = targetNameAttr
            targetAircraftModel = model
            GUI.targetDisplay.Text = "Target: " .. targetNameAttr .. " (Easy-Select)"
            updateIndicator()
            showMessage("Selected: " .. targetNameAttr, 2)
            updateStatus("Target selected via Easy-Select", Color3.fromRGB(100, 255, 100))
        end
    end)
    easySelectMap[model] = {btn = btn, rootPart = root}
    table.insert(easySelectBtnList, {btn = btn, rootPart = root})
end

local function removeButtonForModel(model)
    local entry = easySelectMap[model]
    if entry then
        if entry.conn then entry.conn:Disconnect() end
        if entry.btn then entry.btn:Destroy() end
        easySelectMap[model] = nil
        for i, e in pairs(easySelectBtnList) do
            if e.btn == entry.btn then
                table.remove(easySelectBtnList, i)
                break
            end
        end
    end
end

local function quickEasySelectScan()
    if easySelectScanning then return end
    easySelectScanning = true
    coroutine.wrap(function()
        local modelsToCheck = {}
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and not easySelectMap[obj] and isTargetModel(obj) then
                table.insert(modelsToCheck, obj)
            end
        end
        local count = 0
        for _, model in pairs(modelsToCheck) do
            createButtonForModel(model)
            count = count + 1
            if count % 250 == 0 then task.wait() end
        end
        if count > 0 then
            print("[Easy-Select] Quick scan added " .. count .. " new buttons, total: " .. #easySelectBtnList)
        end
        easySelectScanning = false
    end)()
end

local function startPeriodicEasySelect()
    if easySelectPeriodicConnection then
        easySelectPeriodicConnection:Disconnect()
        easySelectPeriodicConnection = nil
    end
    if not easySelectActive then return end
    easySelectPeriodicConnection = RunService.Heartbeat:Connect(function()
        if easySelectActive then
            quickEasySelectScan()
        else
            easySelectPeriodicConnection:Disconnect()
            easySelectPeriodicConnection = nil
        end
    end)
    spawn(function()
        wait(30)
        if easySelectPeriodicConnection then
            easySelectPeriodicConnection:Disconnect()
            easySelectPeriodicConnection = nil
        end
        if easySelectActive then
            quickEasySelectScan()
            startPeriodicEasySelect()
        end
    end)
end

local function onDescendantAdded(instance)
    if not easySelectActive then return end
    if instance:IsA("Model") and isTargetModel(instance) then
        createButtonForModel(instance)
    elseif instance:IsA("BasePart") and (instance.Name == "HumanoidRootPart" or instance.Name == "Torso" or instance.Name == "UpperTorso") then
        local model = instance.Parent
        if model and model:IsA("Model") and isTargetModel(model) and not easySelectMap[model] then
            createButtonForModel(model)
        end
    elseif instance:IsA("Humanoid") then
        local model = instance.Parent
        if model and model:IsA("Model") and string.find(string.lower(model.Name), "aircraft") and not easySelectMap[model] then
            createButtonForModel(model)
        end
    end
end

local function onDescendantRemoving(instance)
    if not easySelectActive then return end
    if instance:IsA("Model") and easySelectMap[instance] then
        removeButtonForModel(instance)
    end
end

Workspace.DescendantAdded:Connect(onDescendantAdded)
Workspace.DescendantRemoving:Connect(onDescendantRemoving)

local function toggleEasySelect()
    easySelectActive = not easySelectActive
    if easySelectActive then
        GUI.easySelectBtn.Text = "Easy-Select: ON"
        GUI.easySelectBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 200)
        quickEasySelectScan()
        showMessage("Easy-Select ON (fast scan + events)", 2)
        if not easySelectUpdateConnection then
            easySelectUpdateConnection = RunService.RenderStepped:Connect(function()
                if not easySelectActive then return end
                for _, entry in pairs(easySelectBtnList) do
                    local btn = entry.btn
                    local root = entry.rootPart
                    if btn and btn.Parent and root and root:IsA("BasePart") then
                        local screenPos, onScreen = camera:WorldToScreenPoint(root.Position)
                        if onScreen then
                            btn.Position = UDim2.new(0, screenPos.X - 60, 0, screenPos.Y - 60)
                            btn.Visible = true
                        else
                            btn.Visible = false
                        end
                    end
                end
            end)
        end
        startPeriodicEasySelect()
    else
        GUI.easySelectBtn.Text = "Easy-Select: OFF"
        GUI.easySelectBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
        for model, entry in pairs(easySelectMap) do
            if entry.conn then entry.conn:Disconnect() end
            if entry.btn then entry.btn:Destroy() end
        end
        easySelectMap = {}
        easySelectBtnList = {}
        if easySelectUpdateConnection then
            easySelectUpdateConnection:Disconnect()
            easySelectUpdateConnection = nil
        end
        if easySelectPeriodicConnection then
            easySelectPeriodicConnection:Disconnect()
            easySelectPeriodicConnection = nil
        end
        showMessage("Easy-Select OFF", 1.5)
    end
end

local function toggleIndicator()
    showIndicator = not showIndicator
    GUI.indicatorBtn.Text = showIndicator and "Indicator: ON" or "Indicator: OFF"
    GUI.indicatorBtn.BackgroundColor3 = showIndicator and Color3.fromRGB(40, 120, 80) or Color3.fromRGB(60, 60, 60)
    if showIndicator then
        updateIndicator()
    else
        destroyIndicator()
    end
    showMessage(showIndicator and "Indicator ON" or "Indicator OFF", 1.5)
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then keysPressed.W = true end
    if input.KeyCode == Enum.KeyCode.A then keysPressed.A = true end
    if input.KeyCode == Enum.KeyCode.S then keysPressed.S = true end
    if input.KeyCode == Enum.KeyCode.D then keysPressed.D = true end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then keysPressed.W = false end
    if input.KeyCode == Enum.KeyCode.A then keysPressed.A = false end
    if input.KeyCode == Enum.KeyCode.S then keysPressed.S = false end
    if input.KeyCode == Enum.KeyCode.D then keysPressed.D = false end
end)

GUI.connectBtn.MouseButton1Click:Connect(function()
    ourAircraft = findAircraft(playerName)
    if ourAircraft then
        isConnected = true
        updateStatus("Connected to " .. playerName .. " Aircraft", Color3.fromRGB(100, 255, 100))
        showMessage("Connected!", 2)
        GUI.tpBtn.Visible = true
        GUI.bpBtn.Visible = true
        GUI.fpBtn.Visible = true
        GUI.aimbotToggle.Visible = true
        GUI.autoTargetBtn.Visible = true
        GUI.manualAttackBtn.Visible = true
        GUI.controlBtn.Visible = true
        GUI.predictionBtn.Visible = true
        GUI.easySelectBtn.Visible = true
        GUI.safeAttackBtn.Visible = true
        GUI.autoRetryBtn.Visible = true
        GUI.indicatorBtn.Visible = true
        GUI.bindBtn.Visible = true
        GUI.debugLabel.Text = "Aircraft: " .. ourAircraft.Name
        startMainLoop()
        if autoRetryActive then startRetryMonitor() end
    else
        showMessage("Your Aircraft not found!", 2)
        updateStatus("Connection failed", Color3.fromRGB(255, 100, 100))
        GUI.debugLabel.Text = "Aircraft not found: " .. playerName .. " Aircraft"
    end
end)

GUI.tpBtn.MouseButton1Click:Connect(function()
    if not isConnected then
        showMessage("Connect first", 2)
        return
    end
    if targetRootPart then
        followTP()
        return
    end
    local name = GUI.targetBox.Text
    if name == "" or name == "Enter target name" then
        showMessage("Enter name", 2)
        return
    end
    updateStatus("Searching...", Color3.fromRGB(255, 200, 100))
    findTargetWithRetry(name, function(success)
        if success then
            followTP()
        else
            showMessage("Target not found", 2)
            updateStatus("Target not found", Color3.fromRGB(255, 100, 100))
        end
    end)
end)

GUI.bpBtn.MouseButton1Click:Connect(function()
    if not isConnected then
        showMessage("Connect first", 2)
        return
    end
    if targetRootPart then
        followBP()
        return
    end
    local name = GUI.targetBox.Text
    if name == "" or name == "Enter target name" then
        showMessage("Enter name", 2)
        return
    end
    updateStatus("Searching...", Color3.fromRGB(255, 200, 100))
    findTargetWithRetry(name, function(success)
        if success then
            followBP()
        else
            showMessage("Target not found", 2)
            updateStatus("Target not found", Color3.fromRGB(255, 100, 100))
        end
    end)
end)

GUI.fpBtn.MouseButton1Click:Connect(function()
    if not isConnected then
        showMessage("Connect first", 2)
        return
    end
    if targetRootPart then
        followFP()
        return
    end
    local name = GUI.targetBox.Text
    if name == "" or name == "Enter target name" then
        showMessage("Enter name", 2)
        return
    end
    updateStatus("Searching...", Color3.fromRGB(255, 200, 100))
    findTargetWithRetry(name, function(success)
        if success then
            followFP()
        else
            showMessage("Target not found", 2)
            updateStatus("Target not found", Color3.fromRGB(255, 100, 100))
        end
    end)
end)

GUI.aimbotToggle.MouseButton1Click:Connect(toggleAimbot)
GUI.autoTargetBtn.MouseButton1Click:Connect(autoTarget)
GUI.manualAttackBtn.MouseButton1Click:Connect(toggleManualAttack)
GUI.controlBtn.MouseButton1Click:Connect(toggleControl)
GUI.predictionBtn.MouseButton1Click:Connect(togglePrediction)
GUI.easySelectBtn.MouseButton1Click:Connect(toggleEasySelect)
GUI.safeAttackBtn.MouseButton1Click:Connect(toggleSafeAttack)
GUI.autoRetryBtn.MouseButton1Click:Connect(toggleAutoRetry)
GUI.indicatorBtn.MouseButton1Click:Connect(toggleIndicator)

GUI.bindBtn.MouseButton1Click:Connect(function()
    showMessage("Press any key to bind", 2)
    local conn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            stopBind = input.KeyCode
            GUI.bindBtn.Text = "Bind Stop: " .. tostring(stopBind):gsub("Enum.KeyCode.", "")
            conn:Disconnect()
            showMessage("Bind set to " .. tostring(stopBind):gsub("Enum.KeyCode.", ""), 1.5)
        end
    end)
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == stopBind then
        stopFollowingAndAimbot()
        showMessage("Stopped by bind (only following & aimbot)", 1.5)
    end
end)

spawn(function()
    while screenGui and screenGui.Parent do
        if isConnected then
            if isFollowing then
                GUI.statusLabel.Text = "Following (" .. followMode .. ") | Bind: " .. tostring(stopBind):gsub("Enum.KeyCode.", "")
                GUI.statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            elseif aimbotActive then
                GUI.statusLabel.Text = "Aimbot ON | Bind: " .. tostring(stopBind):gsub("Enum.KeyCode.", "")
                GUI.statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            elseif manualAttackActive then
                GUI.statusLabel.Text = "Manual Attack ON | Bind: " .. tostring(stopBind):gsub("Enum.KeyCode.", "")
                GUI.statusLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
            elseif controlActive then
                GUI.statusLabel.Text = "Control ON (WASD) | Bind: " .. tostring(stopBind):gsub("Enum.KeyCode.", "")
                GUI.statusLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
            else
                GUI.statusLabel.Text = "Connected | Target: " .. (targetName or "none")
                GUI.statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
        else
            GUI.statusLabel.Text = "Not connected"
            GUI.statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
        wait(0.5)
    end
end)

print("[Aircraft Attack] Loaded. Auto Retry now fully restores following after self restore.")
