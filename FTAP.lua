local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local Mouse = player:GetMouse()

local BASE_WALK_SPEED = humanoid.WalkSpeed
local BASE_JUMP = humanoid.JumpPower

local gui = Instance.new("ScreenGui")
gui.Name = "SpeedGUI"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 210)
frame.Position = UDim2.new(0.02, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.01, 0)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 150, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.3
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Text = "FTAP GUI"
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "X"
closeBtn.Size = UDim2.new(0, 24, 0, 20)
closeBtn.Position = UDim2.new(1, -28, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.BackgroundTransparency = 0.2
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.AutoButtonColor = false
closeBtn.Parent = frame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0.2, 0)
closeCorner.Parent = closeBtn

local speedLabel = Instance.new("TextLabel")
speedLabel.Text = "Speed: 1.0x"
speedLabel.Size = UDim2.new(1, -20, 0, 20)
speedLabel.Position = UDim2.new(0, 10, 0, 28)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 11
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = frame

local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(1, -20, 0, 4)
sliderTrack.Position = UDim2.new(0, 10, 0, 50)
sliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = frame
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0.2, 0)
trackCorner.Parent = sliderTrack

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.1, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderTrack
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0.2, 0)
fillCorner.Parent = sliderFill

local sliderButton = Instance.new("TextButton")
sliderButton.Size = UDim2.new(0, 14, 0, 14)
sliderButton.Position = UDim2.new(0.1, -7, -0.5, 0)
sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderButton.BorderSizePixel = 0
sliderButton.Text = ""
sliderButton.Parent = sliderTrack
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0.5, 0)
btnCorner.Parent = sliderButton

local speedValue = Instance.new("TextBox")
speedValue.Size = UDim2.new(0, 40, 0, 20)
speedValue.Position = UDim2.new(1, -50, 0, 28)
speedValue.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
speedValue.TextColor3 = Color3.fromRGB(255, 255, 255)
speedValue.Font = Enum.Font.Gotham
speedValue.TextSize = 11
speedValue.Text = "1.0"
speedValue.ClearTextOnFocus = false
speedValue.Parent = frame
local valCorner = Instance.new("UICorner")
valCorner.CornerRadius = UDim.new(0.2, 0)
valCorner.Parent = speedValue

local speedMethodBtn = Instance.new("TextButton")
speedMethodBtn.Text = "CFrame ON"
speedMethodBtn.Size = UDim2.new(1, -20, 0, 24)
speedMethodBtn.Position = UDim2.new(0, 10, 0, 64)
speedMethodBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
speedMethodBtn.BackgroundTransparency = 0.2
speedMethodBtn.BorderSizePixel = 0
speedMethodBtn.Font = Enum.Font.GothamBold
speedMethodBtn.TextSize = 11
speedMethodBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
speedMethodBtn.AutoButtonColor = false
speedMethodBtn.Parent = frame
local methodCorner = Instance.new("UICorner")
methodCorner.CornerRadius = UDim.new(0.2, 0)
methodCorner.Parent = speedMethodBtn

local function createToggleButton(parent, text, yPos, color)
    local btn = Instance.new("TextButton")
    btn.Text = text .. " OFF"
    btn.Size = UDim2.new(0.45, 0, 0, 24)
    btn.Position = UDim2.new(yPos, 0, 0, 96)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.AutoButtonColor = false
    btn.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0.2, 0)
    c.Parent = btn
    btn:SetAttribute("Active", false)
    return btn
end

local infJumpBtn = createToggleButton(frame, "Inf Jump", 0, Color3.fromRGB(255, 165, 0))
infJumpBtn.Position = UDim2.new(0.1, 0, 0, 96)
local moveStabBtn = createToggleButton(frame, "Move Stab", 0.55, Color3.fromRGB(150, 0, 150))
moveStabBtn.Position = UDim2.new(0.55, 0, 0, 96)
local yStabBtn = createToggleButton(frame, "Y Stab", 0.1, Color3.fromRGB(0, 200, 200))
yStabBtn.Position = UDim2.new(0.1, 0, 0, 126)
local aimbotBtn = createToggleButton(frame, "AimBot", 0.55, Color3.fromRGB(150, 100, 0))
aimbotBtn.Position = UDim2.new(0.55, 0, 0, 126)

local currentSpeed = 1.0
local speedMethodEnabled = true
local infJumpEnabled = false
local moveStabEnabled = false
local yStabEnabled = false
local aimbotEnabled = false

local trustedPosition = nil
local trustedVelocity = nil
local lastUpdateStabTime = tick()
local inputActive = false
local tempTeleportAllowed = false
local tempTeleportUntil = 0
local aimbotConnection = nil
local yStabilizerForce = nil
local yStabilizerAttachment = nil
local infJumpConnection = nil

local function refreshCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    hrp = character:WaitForChild("HumanoidRootPart")
    BASE_WALK_SPEED = humanoid.WalkSpeed
    BASE_JUMP = humanoid.JumpPower
    
    if infJumpEnabled then
        if infJumpConnection then infJumpConnection:Disconnect() end
        infJumpConnection = UIS.JumpRequest:Connect(function()
            if infJumpEnabled then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
    
    if yStabEnabled then
        destroyYStabilizer()
        createYStabilizer()
    end
    
    if moveStabEnabled then
        resetStabilization()
    end
    
    humanoid.WalkSpeed = BASE_WALK_SPEED
    if speedMethodEnabled then
    else
        humanoid.WalkSpeed = BASE_WALK_SPEED
    end
end

local function isInputActive()
    return UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.S) or
           UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.D)
end

local function allowTempTeleport(duration)
    tempTeleportAllowed = true
    tempTeleportUntil = tick() + duration
    task.delay(duration, function() tempTeleportAllowed = false end)
end

local function resetStabilization()
    if hrp then
        trustedPosition = hrp.Position
        trustedVelocity = hrp.Velocity
    end
    inputActive = false
end

local function updateStabilization()
    if not moveStabEnabled then return end
    if not hrp or not hrp.Parent then return end
    local now = tick()
    local dt = math.min(now - lastUpdateStabTime, 0.1)
    lastUpdateStabTime = now

    if tempTeleportAllowed and now < tempTeleportUntil then
        trustedPosition = hrp.Position
        trustedVelocity = hrp.Velocity
        return
    end

    local currentPos = hrp.Position
    local currentVel = hrp.Velocity
    local moving = isInputActive()

    if moving then
        if not inputActive then
            trustedPosition = currentPos
            trustedVelocity = currentVel
        end
        inputActive = true
        trustedPosition = currentPos
        trustedVelocity = currentVel
        return
    else
        inputActive = false
    end

    if trustedPosition then
        local delta = currentPos - trustedPosition
        local expectedDelta = trustedVelocity and (trustedVelocity * dt) or Vector3.new()
        local horizDelta = Vector3.new(delta.X, 0, delta.Z)
        local horizExpected = Vector3.new(expectedDelta.X, 0, expectedDelta.Z)

        if horizDelta.Magnitude > horizExpected.Magnitude + 1.5 then
            hrp.CFrame = CFrame.new(trustedPosition.X, currentPos.Y, trustedPosition.Z)
            hrp.Velocity = Vector3.new(0, currentVel.Y, 0)
            return
        end

        local state = humanoid:GetState()
        local isJumping = (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall)
        if not isJumping then
            if currentPos.Y > trustedPosition.Y + 0.5 then
                hrp.CFrame = CFrame.new(currentPos.X, trustedPosition.Y, currentPos.Z)
                hrp.Velocity = Vector3.new(currentVel.X, 0, currentVel.Z)
                return
            end
        end

        if delta.Magnitude < 2 then
            trustedPosition = currentPos
            trustedVelocity = currentVel
        end
    else
        trustedPosition = currentPos
        trustedVelocity = currentVel
    end
end

local function createYStabilizer()
    if yStabilizerForce then yStabilizerForce:Destroy() end
    if yStabilizerAttachment then yStabilizerAttachment:Destroy() end
    if not yStabEnabled then return end
    if not hrp then return end
    yStabilizerAttachment = Instance.new("Attachment")
    yStabilizerAttachment.Parent = hrp
    yStabilizerForce = Instance.new("VectorForce")
    yStabilizerForce.Name = "YStabilizer"
    yStabilizerForce.Attachment0 = yStabilizerAttachment
    yStabilizerForce.Force = Vector3.new(0, 0, 0)
    yStabilizerForce.RelativeTo = Enum.ActuatorRelativeTo.World
    yStabilizerForce.Parent = hrp
end

local function updateYStabilizer()
    if not yStabEnabled or not yStabilizerForce then return end
    if not hrp then return end
    local isGrounded = (humanoid.FloorMaterial ~= Enum.Material.Air)
    if not isGrounded then
        local vy = hrp.Velocity.Y
        local forceMagnitude = -vy * 15000
        if vy > 0 then
            forceMagnitude = forceMagnitude * (1 + math.min(math.abs(vy) * 0.3, 5))
        end
        forceMagnitude = math.clamp(forceMagnitude, -120000, 120000)
        yStabilizerForce.Force = Vector3.new(0, forceMagnitude, 0)
    else
        yStabilizerForce.Force = Vector3.new(0, 0, 0)
    end
end

local function destroyYStabilizer()
    if yStabilizerForce then yStabilizerForce:Destroy() yStabilizerForce = nil end
    if yStabilizerAttachment then yStabilizerAttachment:Destroy() yStabilizerAttachment = nil end
end

local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local closestDistance = math.huge
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local targetRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = otherPlayer.Character:FindFirstChild("Humanoid")
            if targetRoot and hum and hum.Health > 0 then
                local screenPoint = workspace.CurrentCamera:WorldToScreenPoint(targetRoot.Position)
                if screenPoint.Z > 0 then
                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                    local playerPos = Vector2.new(screenPoint.X, screenPoint.Y)
                    local distance = (mousePos - playerPos).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = otherPlayer
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function AimAtPlayer()
    if not aimbotEnabled then return end
    local targetPlayer = GetClosestPlayerToCursor()
    if targetPlayer and targetPlayer.Character then
        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, targetRoot.Position)
        end
    end
end

local function setupAimbot()
    if aimbotConnection then aimbotConnection:Disconnect() end
    if aimbotEnabled then
        aimbotConnection = RunService.RenderStepped:Connect(function()
            if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                AimAtPlayer()
            end
        end)
    end
end

local function updateSpeedCFrame(dt)
    local dir = humanoid.MoveDirection
    if dir.Magnitude > 0 then
        local targetSpeed = BASE_WALK_SPEED * currentSpeed
        local y = hrp.Position.Y
        hrp.CFrame = hrp.CFrame + (dir * targetSpeed * dt)
        hrp.CFrame = CFrame.new(hrp.Position.X, y, hrp.Position.Z)
    end
end

local function updateSpeed()
    local dt = math.min(RunService.Heartbeat:Wait(), 0.1)
    if speedMethodEnabled then
        humanoid.WalkSpeed = BASE_WALK_SPEED
        updateSpeedCFrame(dt)
    else
        humanoid.WalkSpeed = BASE_WALK_SPEED
    end
    updateYStabilizer()
    if moveStabEnabled then updateStabilization() end
end

local function updateSliderUI()
    local ratio = (currentSpeed - 0.1) / (10 - 0.1)
    sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
    sliderButton.Position = UDim2.new(ratio, -7, -0.5, 0)
    speedLabel.Text = string.format("Speed: %.1fx", currentSpeed)
    speedValue.Text = string.format("%.1f", currentSpeed)
end

local dragging = false
sliderButton.MouseButton1Down:Connect(function()
    dragging = true
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local trackPos = sliderTrack.AbsolutePosition.X
        local trackWidth = sliderTrack.AbsoluteSize.X
        local mouseX = input.Position.X
        local ratio = math.clamp((mouseX - trackPos) / trackWidth, 0, 1)
        currentSpeed = 0.1 + ratio * (10 - 0.1)
        updateSliderUI()
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

speedValue.FocusLost:Connect(function()
    local val = tonumber(speedValue.Text)
    if val then
        currentSpeed = math.clamp(val, 0.1, 10)
        updateSliderUI()
    else
        speedValue.Text = string.format("%.1f", currentSpeed)
    end
end)

speedMethodBtn.MouseButton1Click:Connect(function()
    speedMethodEnabled = not speedMethodEnabled
    speedMethodBtn.Text = speedMethodEnabled and "CFrame ON" or "CFrame OFF"
    if not speedMethodEnabled then
        humanoid.WalkSpeed = BASE_WALK_SPEED
    end
end)

infJumpBtn.MouseButton1Click:Connect(function()
    infJumpEnabled = not infJumpEnabled
    infJumpBtn.Text = infJumpEnabled and "Inf Jump ON" or "Inf Jump OFF"
    infJumpBtn.BackgroundColor3 = infJumpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 165, 0)
    if infJumpEnabled then
        if infJumpConnection then infJumpConnection:Disconnect() end
        infJumpConnection = UIS.JumpRequest:Connect(function()
            if infJumpEnabled then
                local hum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    else
        if infJumpConnection then infJumpConnection:Disconnect() end
    end
end)

moveStabBtn.MouseButton1Click:Connect(function()
    moveStabEnabled = not moveStabEnabled
    moveStabBtn.Text = moveStabEnabled and "Move Stab ON" or "Move Stab OFF"
    moveStabBtn.BackgroundColor3 = moveStabEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(150, 0, 150)
    resetStabilization()
end)

yStabBtn.MouseButton1Click:Connect(function()
    yStabEnabled = not yStabEnabled
    yStabBtn.Text = yStabEnabled and "Y Stab ON" or "Y Stab OFF"
    yStabBtn.BackgroundColor3 = yStabEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(0, 200, 200)
    if yStabEnabled then createYStabilizer() else destroyYStabilizer() end
end)

aimbotBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimbotBtn.Text = aimbotEnabled and "AimBot ON" or "AimBot OFF"
    aimbotBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(150, 100, 0)
    setupAimbot()
end)

closeBtn.MouseButton1Click:Connect(function()
    if infJumpConnection then infJumpConnection:Disconnect() end
    if aimbotConnection then aimbotConnection:Disconnect() end
    destroyYStabilizer()
    humanoid.WalkSpeed = BASE_WALK_SPEED
    gui:Destroy()
end)

player.CharacterAdded:Connect(function()
    task.wait(0.1)
    refreshCharacter()
end)

updateSliderUI()
resetStabilization()

RunService.Heartbeat:Connect(function()
    updateSpeed()
end)

local function Notify(msg)
    local notif = Instance.new("TextLabel")
    notif.Text = msg
    notif.Size = UDim2.new(0, 220, 0, 30)
    notif.Position = UDim2.new(0.5, -110, 1, -40)
    notif.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notif.TextColor3 = Color3.fromRGB(255, 255, 255)
    notif.Font = Enum.Font.Gotham
    notif.TextSize = 12
    notif.BorderSizePixel = 0
    notif.Parent = gui
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0.2, 0)
    c.Parent = notif
    task.delay(2, function()
        local fade = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 1, BackgroundTransparency = 1})
        fade:Play()
        fade.Completed:Connect(function() notif:Destroy() end)
    end)
end

Notify("FTAP GUI Loaded | CFrame mode | Hold RMB for AimBot")
