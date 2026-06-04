local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local Mouse = player:GetMouse()

local flyEnabled = false
local flySpeedMult = 1
local flyBodyGyro = nil
local flyBodyVelocity = nil
local flyControls = {f=0,b=0,l=0,r=0}
local lastFlyControls = {f=0,b=0,l=0,r=0}
local currentFlySpeed = 0
local baseFlySpeed = 50
local keyBinds = {}
local sliderDragging = false

local function Notify(text, title, duration)
    duration = duration or 3
    local notificationContainer = gui and gui:FindFirstChild("NotificationContainer")
    if not notificationContainer and gui then
        notificationContainer = Instance.new("Frame")
        notificationContainer.Name = "NotificationContainer"
        notificationContainer.Size = UDim2.new(1, 0, 1, 0)
        notificationContainer.Position = UDim2.new(0, 0, 0, 0)
        notificationContainer.BackgroundTransparency = 1
        notificationContainer.ZIndex = 100
        notificationContainer.Parent = gui
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 6)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.Parent = notificationContainer
    end
    if not notificationContainer then return end

    local frameNotif = Instance.new("Frame")
    frameNotif.AnchorPoint = Vector2.new(1, 1)
    frameNotif.Size = UDim2.new(0, 250, 0, 50)
    frameNotif.Position = UDim2.new(1, 270, 1, -10)
    frameNotif.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frameNotif.BackgroundTransparency = 0.1
    frameNotif.BorderSizePixel = 0
    frameNotif.ZIndex = 200
    frameNotif.Parent = notificationContainer
    local frameNotifCorner = Instance.new("UICorner")
    frameNotifCorner.CornerRadius = UDim.new(0.03, 0)
    frameNotifCorner.Parent = frameNotif

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -10, 0, 20)
    titleLabel.Position = UDim2.new(0, 5, 0, 2)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title or "Notice"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 201
    titleLabel.Parent = frameNotif

    local bodyLabel = Instance.new("TextLabel")
    bodyLabel.BackgroundTransparency = 1
    bodyLabel.Size = UDim2.new(1, -10, 1, -22)
    bodyLabel.Position = UDim2.new(0, 5, 0, 22)
    bodyLabel.Font = Enum.Font.Gotham
    bodyLabel.Text = text or ""
    bodyLabel.TextColor3 = Color3.new(1, 1, 1)
    bodyLabel.TextSize = 12
    bodyLabel.TextWrapped = true
    bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bodyLabel.ZIndex = 201
    bodyLabel.Parent = frameNotif

    task.defer(function()
        local slideIn = TweenService:Create(frameNotif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -10, 1, -10)
        })
        slideIn:Play()
    end)

    task.delay(duration, function()
        local fadeOut = TweenService:Create(frameNotif, TweenInfo.new(0.3), {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 270, 1, -10)
        })
        local titleFade = TweenService:Create(titleLabel, TweenInfo.new(0.3), {TextTransparency = 1})
        local bodyFade = TweenService:Create(bodyLabel, TweenInfo.new(0.3), {TextTransparency = 1})
        fadeOut:Play()
        titleFade:Play()
        bodyFade:Play()
        fadeOut.Completed:Wait()
        frameNotif:Destroy()
    end)
end

local function setFlyEnabled(enabled)
    flyEnabled = enabled
    if flyEnabled then
        if flyBodyGyro then flyBodyGyro:Destroy() end
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.P = 9e4
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.CFrame = hrp.CFrame
        flyBodyGyro.Parent = hrp
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVelocity.Parent = hrp
        humanoid.PlatformStand = true
        currentFlySpeed = 0
        Notify("Fly enabled", "Fly", 2)
    else
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        humanoid.PlatformStand = false
        flyControls = {f=0, b=0, l=0, r=0}
        currentFlySpeed = 0
        Notify("Fly disabled", "Fly", 2)
    end
end

local function updateFlySpeed()
    local currentFlySpeedValue = baseFlySpeed * flySpeedMult
    if flyControls.l + flyControls.r ~= 0 or flyControls.f + flyControls.b ~= 0 then
        currentFlySpeed = currentFlySpeed + 0.5 + (currentFlySpeed / currentFlySpeedValue)
        if currentFlySpeed > currentFlySpeedValue then currentFlySpeed = currentFlySpeedValue end
    elseif currentFlySpeed ~= 0 then
        currentFlySpeed = currentFlySpeed - 1
        if currentFlySpeed < 0 then currentFlySpeed = 0 end
    end
    if (flyControls.l + flyControls.r) ~= 0 or (flyControls.f + flyControls.b) ~= 0 then
        local look = workspace.CurrentCamera.CFrame.LookVector
        local side = (workspace.CurrentCamera.CFrame * CFrame.new(flyControls.l + flyControls.r, (flyControls.f + flyControls.b) * 0.2, 0).p) - workspace.CurrentCamera.CFrame.p
        flyBodyVelocity.Velocity = (look * (flyControls.f + flyControls.b) + side) * currentFlySpeed
        lastFlyControls = {f = flyControls.f, b = flyControls.b, l = flyControls.l, r = flyControls.r}
    elseif currentFlySpeed ~= 0 then
        local look = workspace.CurrentCamera.CFrame.LookVector
        local side = (workspace.CurrentCamera.CFrame * CFrame.new(lastFlyControls.l + lastFlyControls.r, (lastFlyControls.f + lastFlyControls.b) * 0.2, 0).p) - workspace.CurrentCamera.CFrame.p
        flyBodyVelocity.Velocity = (look * (lastFlyControls.f + lastFlyControls.b) + side) * currentFlySpeed
    else
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
    flyBodyGyro.CFrame = workspace.CurrentCamera.CFrame
end

local function updateSliderUI(sliderData, value, minVal, maxVal)
    value = tonumber(value) or 1
    value = math.clamp(value, minVal, maxVal)
    local logMin = math.log10(minVal)
    local logMax = math.log10(maxVal)
    local logValue = math.log10(value)
    local ratio = (logValue - logMin) / (logMax - logMin)
    ratio = math.clamp(ratio, 0, 1)
    sliderData.fill.Size = UDim2.new(ratio, 0, 1, 0)
    local btnPos = ratio * sliderData.slider.AbsoluteSize.X - 8
    local relativePos = btnPos / sliderData.slider.AbsoluteSize.X
    sliderData.button.Position = UDim2.new(relativePos, -8, -0.4, 0)
    sliderData.box.Text = string.format("%.3f", value)
    return value
end

local gui = Instance.new("ScreenGui")
gui.Name = "FlyPanel"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 160, 0, 120)
frame.Position = UDim2.new(0.02, 0, 0.5, -60)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.02, 0)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 200, 255)
stroke.Thickness = 1
stroke.Transparency = 0.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 24)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
titleBar.BackgroundTransparency = 0.2
titleBar.BorderSizePixel = 0
titleBar.Parent = frame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0.02, 0)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 8, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "FLY"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 1, -2)
closeBtn.Position = UDim2.new(1, -22, 0, 1)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.BackgroundTransparency = 0.2
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0.2, 0)
closeCorner.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function()
    setFlyEnabled(false)
    gui:Destroy()
end)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.7, -10, 0, 28)
toggleBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
toggleBtn.Text = "FLY OFF"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 12
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = frame
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0.2, 0)
toggleCorner.Parent = toggleBtn

local bindBtn = Instance.new("TextButton")
bindBtn.Size = UDim2.new(0.2, -5, 0, 28)
bindBtn.Position = UDim2.new(0.75, 0, 0.25, 0)
bindBtn.Text = "?"
bindBtn.Font = Enum.Font.GothamBold
bindBtn.TextSize = 12
bindBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
bindBtn.BackgroundTransparency = 0.2
bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bindBtn.BorderSizePixel = 0
bindBtn.Parent = frame
local bindCorner = Instance.new("UICorner")
bindCorner.CornerRadius = UDim.new(0.2, 0)
bindCorner.Parent = bindBtn

local speedContainer = Instance.new("Frame")
speedContainer.Size = UDim2.new(0.9, 0, 0, 32)
speedContainer.Position = UDim2.new(0.05, 0, 0.55, 0)
speedContainer.BackgroundTransparency = 1
speedContainer.Parent = frame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.4, 0, 1, 0)
speedLabel.Position = UDim2.new(0, 0, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed:"
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 10
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedContainer

local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(0.45, 0, 0.5, 0)
sliderFrame.Position = UDim2.new(0.4, 0, 0.25, 0)
sliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
sliderFrame.BorderSizePixel = 0
sliderFrame.Parent = speedContainer
local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(0.3, 0)
sliderCorner.Parent = sliderFrame

local fill = Instance.new("Frame")
fill.Size = UDim2.new(0, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
fill.BorderSizePixel = 0
fill.ZIndex = 2
fill.Parent = sliderFrame
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0.3, 0)
fillCorner.Parent = fill

local sliderButton = Instance.new("TextButton")
sliderButton.Size = UDim2.new(0, 12, 1.8, 0)
sliderButton.Position = UDim2.new(0, -6, -0.4, 0)
sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderButton.BorderSizePixel = 0
sliderButton.Text = ""
sliderButton.ZIndex = 3
sliderButton.Parent = sliderFrame
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0.5, 0)
buttonCorner.Parent = sliderButton

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.2, 0, 0.6, 0)
speedBox.Position = UDim2.new(0.85, 0, 0.2, 0)
speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 9
speedBox.ClearTextOnFocus = false
speedBox.Text = "1.000"
speedBox.Parent = speedContainer
local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0.2, 0)
boxCorner.Parent = speedBox

local function updateFlyDisplay()
    toggleBtn.Text = flyEnabled and "FLY ON" or "FLY OFF"
    toggleBtn.BackgroundColor3 = flyEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(0, 150, 200)
end

local function refreshSlider()
    local ratio = (math.log10(flySpeedMult) - math.log10(0.001)) / (math.log10(1500) - math.log10(0.001))
    ratio = math.clamp(ratio, 0, 1)
    fill.Size = UDim2.new(ratio, 0, 1, 0)
    local btnPos = ratio * sliderFrame.AbsoluteSize.X - 6
    local relativePos = btnPos / sliderFrame.AbsoluteSize.X
    sliderButton.Position = UDim2.new(relativePos, -6, -0.4, 0)
    speedBox.Text = string.format("%.3f", flySpeedMult)
end

sliderButton.MouseButton1Down:Connect(function()
    sliderDragging = true
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if sliderDragging then
        local pos = input.Position.X - sliderFrame.AbsolutePosition.X
        local ratio = math.clamp(pos / sliderFrame.AbsoluteSize.X, 0, 1)
        local logMin = math.log10(0.001)
        local logMax = math.log10(1500)
        flySpeedMult = 10^(logMin + ratio * (logMax - logMin))
        flySpeedMult = math.clamp(flySpeedMult, 0.001, 1500)
        refreshSlider()
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = false
    end
end)

speedBox.FocusLost:Connect(function()
    local val = tonumber(speedBox.Text) or 1
    val = math.clamp(val, 0.001, 1500)
    flySpeedMult = val
    refreshSlider()
end)

toggleBtn.MouseButton1Click:Connect(function()
    setFlyEnabled(not flyEnabled)
    updateFlyDisplay()
end)

local currentBindKey = nil
local waitingForBind = false
local timeoutThread = nil

local function clearTimeout()
    if timeoutThread then
        task.cancel(timeoutThread)
        timeoutThread = nil
    end
end

local function updateBindDisplay()
    if currentBindKey then
        local keyName = tostring(currentBindKey):gsub("Enum.KeyCode.", "")
        if #keyName > 3 then keyName = keyName:sub(1, 3) end
        bindBtn.Text = keyName
    else
        bindBtn.Text = "?"
    end
end

bindBtn.MouseButton1Click:Connect(function()
    if currentBindKey then
        keyBinds[currentBindKey] = nil
        currentBindKey = nil
        updateBindDisplay()
        Notify("Fly bind removed", "Bind", 1)
        return
    end
    
    waitingForBind = true
    local originalText = bindBtn.Text
    bindBtn.Text = "..."
    clearTimeout()
    
    local conn
    conn = UIS.InputBegan:Connect(function(input, processed)
        if processed or not waitingForBind then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode
            if key ~= Enum.KeyCode.Unknown then
                if currentBindKey then
                    keyBinds[currentBindKey] = nil
                end
                currentBindKey = key
                keyBinds[key] = function()
                    setFlyEnabled(not flyEnabled)
                    updateFlyDisplay()
                end
                updateBindDisplay()
                Notify("Fly bound to " .. tostring(key):gsub("Enum.KeyCode.", ""), "Bind", 2)
            end
            waitingForBind = false
            conn:Disconnect()
            clearTimeout()
        end
    end)
    
    timeoutThread = task.spawn(function()
        task.wait(3)
        if waitingForBind then
            waitingForBind = false
            if conn then conn:Disconnect() end
            if bindBtn.Text == "..." then
                bindBtn.Text = originalText
            end
            Notify("Bind cancelled: no key pressed", "Bind", 2)
        end
        timeoutThread = nil
    end)
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        local callback = keyBinds[key]
        if callback then
            callback()
        end
    end
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed or not flyEnabled then return end
    if input.KeyCode == Enum.KeyCode.W then flyControls.f = 1
    elseif input.KeyCode == Enum.KeyCode.S then flyControls.b = -1
    elseif input.KeyCode == Enum.KeyCode.A then flyControls.l = -1
    elseif input.KeyCode == Enum.KeyCode.D then flyControls.r = 1
    elseif input.KeyCode == Enum.KeyCode.Space then flyControls.up = 1
    elseif input.KeyCode == Enum.KeyCode.LeftControl then flyControls.down = -1
    end
end)

UIS.InputEnded:Connect(function(input)
    if not flyEnabled then return end
    if input.KeyCode == Enum.KeyCode.W then flyControls.f = 0
    elseif input.KeyCode == Enum.KeyCode.S then flyControls.b = 0
    elseif input.KeyCode == Enum.KeyCode.A then flyControls.l = 0
    elseif input.KeyCode == Enum.KeyCode.D then flyControls.r = 0
    elseif input.KeyCode == Enum.KeyCode.Space then flyControls.up = 0
    elseif input.KeyCode == Enum.KeyCode.LeftControl then flyControls.down = 0
    end
end)

local camera = workspace.CurrentCamera
RunService.Heartbeat:Connect(function()
    if flyEnabled and flyBodyGyro and flyBodyVelocity then
        local currentFlySpeedValue = baseFlySpeed * flySpeedMult
        local upDown = (flyControls.up or 0) + (flyControls.down or 0)
        if flyControls.l + flyControls.r ~= 0 or flyControls.f + flyControls.b ~= 0 or upDown ~= 0 then
            currentFlySpeed = currentFlySpeed + 0.5 + (currentFlySpeed / currentFlySpeedValue)
            if currentFlySpeed > currentFlySpeedValue then currentFlySpeed = currentFlySpeedValue end
        elseif currentFlySpeed ~= 0 then
            currentFlySpeed = currentFlySpeed - 1
            if currentFlySpeed < 0 then currentFlySpeed = 0 end
        end
        local look = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local up = camera.CFrame.UpVector
        local moveDir = (look * (flyControls.f + flyControls.b) + right * (flyControls.l + flyControls.r) + up * upDown)
        if moveDir.Magnitude > 0 then
            flyBodyVelocity.Velocity = moveDir.Unit * currentFlySpeed
        else
            flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        flyBodyGyro.CFrame = camera.CFrame
    end
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
    if flyEnabled then
        setFlyEnabled(true)
    end
end)

refreshSlider()
updateFlyDisplay()
Notify("Fly panel loaded! Click ? to bind a key", "Fly", 3)
