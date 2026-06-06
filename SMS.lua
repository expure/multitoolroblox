local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local head = character:WaitForChild("Head")
local Mouse = player:GetMouse()

local BASE_WALK_SPEED = humanoid.WalkSpeed
local BASE_JUMP = humanoid.JumpPower

local gui = Instance.new("ScreenGui")
gui.Name = "SpeedTool"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 280)
frame.Position = UDim2.new(0.5, -110, 0.5, -140)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.02, 0)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 150, 255)
stroke.Thickness = 1
stroke.Transparency = 0.3
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Text = "Speed Tool"
title.Size = UDim2.new(1, 0, 0, 28)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "X"
closeBtn.Size = UDim2.new(0, 28, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.BackgroundTransparency = 0.2
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.AutoButtonColor = false
closeBtn.Parent = frame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0.2, 0)
closeCorner.Parent = closeBtn

local function Notify(text, titleText, duration)
    duration = duration or 2
    local notifContainer = gui:FindFirstChild("NotifContainer")
    if not notifContainer then
        notifContainer = Instance.new("Frame")
        notifContainer.Name = "NotifContainer"
        notifContainer.Size = UDim2.new(1, 0, 1, 0)
        notifContainer.BackgroundTransparency = 1
        notifContainer.ZIndex = 100
        notifContainer.Parent = gui
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 6)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.Parent = notifContainer
    end
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 250, 0, 50)
    notif.Position = UDim2.new(1, 260, 1, -60)
    notif.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notif.BackgroundTransparency = 0.1
    notif.BorderSizePixel = 0
    notif.ZIndex = 101
    notif.Parent = notifContainer
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0.02, 0)
    notifCorner.Parent = notif
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0, 20)
    titleLabel.Position = UDim2.new(0, 5, 0, 2)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = titleText or "Notice"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notif
    local bodyLabel = Instance.new("TextLabel")
    bodyLabel.Size = UDim2.new(1, -10, 0, 22)
    bodyLabel.Position = UDim2.new(0, 5, 0, 22)
    bodyLabel.BackgroundTransparency = 1
    bodyLabel.Font = Enum.Font.Gotham
    bodyLabel.Text = text or ""
    bodyLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    bodyLabel.TextSize = 12
    bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bodyLabel.Parent = notif
    local slideIn = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -10, 1, -60)
    })
    slideIn:Play()
    task.delay(duration, function()
        local fadeOut = TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1})
        fadeOut:Play()
        fadeOut.Completed:Wait()
        notif:Destroy()
    end)
end

local currentSpeedMult = 1
local speedMethod = "Off"
local infJumpEnabled = false
local yStabEnabled = false
local puncherEnabled = false

local yStabilizerForce = nil
local yStabilizerAttachment = nil
local puncherConnections = {}
local puncherParts = {}

local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(0.9, 0, 0.12, 0)
sliderFrame.Position = UDim2.new(0.05, 0, 0.12, 0)
sliderFrame.BackgroundTransparency = 1
sliderFrame.Parent = frame

local speedLabel = Instance.new("TextLabel")
speedLabel.Text = "Speed: 1.000x"
speedLabel.Size = UDim2.new(0.5, 0, 0.35, 0)
speedLabel.Position = UDim2.new(0, 0, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 11
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = sliderFrame

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.22, 0, 0.35, 0)
speedBox.Position = UDim2.new(0.78, 0, 0, 0)
speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 10
speedBox.Text = "1"
speedBox.TextXAlignment = Enum.TextXAlignment.Center
speedBox.Parent = sliderFrame
local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0.2, 0)
boxCorner.Parent = speedBox

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, 0, 0.3, 0)
sliderBg.Position = UDim2.new(0, 0, 0.5, 0)
sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = sliderFrame
local sliderBgCorner = Instance.new("UICorner")
sliderBgCorner.CornerRadius = UDim.new(0.3, 0)
sliderBgCorner.Parent = sliderBg

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg
local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(0.3, 0)
sliderFillCorner.Parent = sliderFill

local sliderBtn = Instance.new("TextButton")
sliderBtn.Size = UDim2.new(0, 16, 0, 16)
sliderBtn.Position = UDim2.new(0.5, -8, -0.2, 0)
sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderBtn.BorderSizePixel = 0
sliderBtn.Text = ""
sliderBtn.Parent = sliderBg
local sliderBtnCorner = Instance.new("UICorner")
sliderBtnCorner.CornerRadius = UDim.new(0.5, 0)
sliderBtnCorner.Parent = sliderBtn

local methodBtn = Instance.new("TextButton")
methodBtn.Text = "Speed OFF"
methodBtn.Size = UDim2.new(0.9, 0, 0.1, 0)
methodBtn.Position = UDim2.new(0.05, 0, 0.26, 0)
methodBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
methodBtn.BackgroundTransparency = 0.2
methodBtn.BorderSizePixel = 0
methodBtn.Font = Enum.Font.GothamBold
methodBtn.TextSize = 12
methodBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
methodBtn.Parent = frame
local methodCorner = Instance.new("UICorner")
methodCorner.CornerRadius = UDim.new(0.2, 0)
methodCorner.Parent = methodBtn

local line = Instance.new("Frame")
line.Size = UDim2.new(0.9, 0, 0.002, 0)
line.Position = UDim2.new(0.05, 0, 0.38, 0)
line.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
line.BorderSizePixel = 0
line.Parent = frame

local buttons = {}
local function createToggleButton(name, yPos, color)
    local btn = Instance.new("TextButton")
    btn.Text = name .. " OFF"
    btn.Size = UDim2.new(0.42, 0, 0.09, 0)
    btn.Position = UDim2.new(0.05, 0, yPos, 0)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = frame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0.2, 0)
    btnCorner.Parent = btn
    return btn
end

local infJumpBtn = createToggleButton("Inf Jump", 0.41, Color3.fromRGB(255, 165, 0))
local yStabBtn = createToggleButton("Y-Stab", 0.52, Color3.fromRGB(0, 200, 200))
local puncherBtn = createToggleButton("Puncher", 0.63, Color3.fromRGB(200, 100, 0))
local grabberBtn = createToggleButton("Grabber", 0.74, Color3.fromRGB(0, 100, 150))

infJumpBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
yStabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
puncherBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
grabberBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

local function updateSliderUI(value)
    value = math.clamp(value, 0.1, 9e9)
    local logMin = math.log10(0.1)
    local logMax = math.log10(9e9)
    local logVal = math.log10(value)
    local ratio = (logVal - logMin) / (logMax - logMin)
    ratio = math.clamp(ratio, 0, 1)
    sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
    local btnPos = ratio * sliderBg.AbsoluteSize.X - 8
    local relativePos = btnPos / sliderBg.AbsoluteSize.X
    sliderBtn.Position = UDim2.new(relativePos, -8, -0.2, 0)
    if value >= 1e6 then
        speedLabel.Text = string.format("Speed: %.1fx", value / 1e6) .. "M"
    elseif value >= 1e3 then
        speedLabel.Text = string.format("Speed: %.1fx", value / 1e3) .. "K"
    else
        speedLabel.Text = string.format("Speed: %.3fx", value)
    end
    speedBox.Text = string.format("%.3f", value)
end

local function setSpeedMethod(method)
    speedMethod = method
    if speedMethod == "Off" then
        methodBtn.Text = "Speed OFF"
        humanoid.WalkSpeed = BASE_WALK_SPEED
        local bv = hrp:FindFirstChild("StrengthVelocity")
        if bv then bv:Destroy() end
    elseif speedMethod == "CFrame" then
        methodBtn.Text = "CFrame"
        humanoid.WalkSpeed = BASE_WALK_SPEED
        local bv = hrp:FindFirstChild("StrengthVelocity")
        if bv then bv:Destroy() end
    elseif speedMethod == "Strength" then
        methodBtn.Text = "Strength"
        humanoid.WalkSpeed = BASE_WALK_SPEED
    end
end

local dragActive = false
sliderBtn.MouseButton1Down:Connect(function()
    dragActive = true
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragActive and input.UserInputType == Enum.UserInputType.MouseMovement then
        local pos = input.Position.X - sliderBg.AbsolutePosition.X
        local ratio = math.clamp(pos / sliderBg.AbsoluteSize.X, 0, 1)
        local logMin = math.log10(0.1)
        local logMax = math.log10(9e9)
        currentSpeedMult = 10^(logMin + ratio * (logMax - logMin))
        currentSpeedMult = math.clamp(currentSpeedMult, 0.1, 9e9)
        updateSliderUI(currentSpeedMult)
    end
end)
speedBox.FocusLost:Connect(function()
    local val = tonumber(speedBox.Text) or 1
    val = math.clamp(val, 0.1, 9e9)
    currentSpeedMult = val
    updateSliderUI(currentSpeedMult)
end)

methodBtn.MouseButton1Click:Connect(function()
    local methods = {"Off", "CFrame", "Strength"}
    local idx = 1
    for i, m in ipairs(methods) do if m == speedMethod then idx = i break end end
    idx = idx % #methods + 1
    setSpeedMethod(methods[idx])
end)

local infJumpConnection = nil
local function setupInfJump()
    if infJumpConnection then
        infJumpConnection:Disconnect()
        infJumpConnection = nil
    end
    if infJumpEnabled then
        infJumpConnection = UIS.JumpRequest:Connect(function()
            local hum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

infJumpBtn.MouseButton1Click:Connect(function()
    infJumpEnabled = not infJumpEnabled
    infJumpBtn.Text = infJumpEnabled and "Inf Jump ON" or "Inf Jump OFF"
    infJumpBtn.BackgroundColor3 = infJumpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 165, 0)
    setupInfJump()
end)

player.CharacterAdded:Connect(function()
    setupInfJump()
end)
setupInfJump()

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

local function destroyYStabilizer()
    if yStabilizerForce then yStabilizerForce:Destroy() yStabilizerForce = nil end
    if yStabilizerAttachment then yStabilizerAttachment:Destroy() yStabilizerAttachment = nil end
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

yStabBtn.MouseButton1Click:Connect(function()
    yStabEnabled = not yStabEnabled
    yStabBtn.Text = yStabEnabled and "Y-Stab ON" or "Y-Stab OFF"
    yStabBtn.BackgroundColor3 = yStabEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(0, 200, 200)
    if yStabEnabled then
        createYStabilizer()
    else
        destroyYStabilizer()
    end
end)

local function addPuncherToPart(part)
    if not part or part:IsDescendantOf(character) then return end
    if part:FindFirstChild("PuncherCD") then return end
    if part.Anchored then return end
    local cd = Instance.new("ClickDetector")
    cd.Name = "PuncherCD"
    cd.Parent = part
    local connection
    connection = cd.MouseClick:Connect(function(plr)
        if plr ~= player then return end
        if part:CanSetNetworkOwnership() then
            pcall(function() part:SetNetworkOwner(player) end)
        end
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        local dir = (part.Position - hrp.Position).Unit
        bv.Velocity = dir * 2000 + Vector3.new(0, 100, 0)
        bv.Parent = part
        Debris:AddItem(bv, 0.5)
        local bav = Instance.new("BodyAngularVelocity")
        bav.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bav.AngularVelocity = Vector3.new(math.random(-1000,1000), math.random(-1000,1000), math.random(-1000,1000))
        bav.Parent = part
        Debris:AddItem(bav, 0.5)
    end)
    puncherConnections[part] = connection
    puncherParts[part] = cd
end

local function scanForParts()
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsDescendantOf(character) and not part.Anchored then
            if not part:FindFirstChild("PuncherCD") then
                addPuncherToPart(part)
            end
        end
    end
end

local function enablePuncher()
    if puncherEnabled then
        scanForParts()
        puncherConnections.DescendantAdded = workspace.DescendantAdded:Connect(function(obj)
            if puncherEnabled and obj:IsA("BasePart") and not obj:IsDescendantOf(character) and not obj.Anchored then
                if not obj:FindFirstChild("PuncherCD") then
                    addPuncherToPart(obj)
                end
            end
        end)
    else
        for part, cd in pairs(puncherParts) do
            if cd and cd.Parent then cd:Destroy() end
        end
        for part, conn in pairs(puncherConnections) do
            if type(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        if puncherConnections.DescendantAdded then
            puncherConnections.DescendantAdded:Disconnect()
            puncherConnections.DescendantAdded = nil
        end
        puncherParts = {}
        puncherConnections = {}
    end
end

puncherBtn.MouseButton1Click:Connect(function()
    puncherEnabled = not puncherEnabled
    puncherBtn.Text = puncherEnabled and "Puncher ON" or "Puncher OFF"
    puncherBtn.BackgroundColor3 = puncherEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 100, 0)
    enablePuncher()
end)

local grabberTool = nil
local grabberActive = false
local grabbedPart = nil
local grabberBodyPos = nil
local grabberBeam = nil
local grabberConn = nil

local function cleanupGrabber()
    if grabberBodyPos then grabberBodyPos:Destroy() grabberBodyPos = nil end
    if grabberBeam then grabberBeam:Destroy() grabberBeam = nil end
    if grabberConn then grabberConn:Disconnect() grabberConn = nil end
    grabbedPart = nil
    grabberActive = false
end

local function createGrabberTool()
    if grabberTool then grabberTool:Destroy() end
    local tool = Instance.new("Tool")
    tool.Name = "Grabber"
    tool.RequiresHandle = false
    tool.CanBeDropped = true
    tool.Parent = player.Backpack
    tool.Activated:Connect(function()
        if grabberActive then
            cleanupGrabber()
            return
        end
        local target = Mouse.Target
        if not target then return end
        local part = target:IsA("BasePart") and target or target.Parent:FindFirstChildWhichIsA("BasePart")
        if not part then return end
        if part:IsDescendantOf(character) then return end
        if part.Anchored then return end
        if Players:GetPlayerFromCharacter(part:FindFirstAncestorOfClass("Model")) then return end
        if part:CanSetNetworkOwnership() then
            pcall(function() part:SetNetworkOwner(player) end)
        end
        grabberBodyPos = Instance.new("BodyPosition")
        grabberBodyPos.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        grabberBodyPos.P = 2000
        grabberBodyPos.D = 500
        grabberBodyPos.Parent = part
        local att0 = Instance.new("Attachment")
        att0.Parent = head
        att0.Position = Vector3.new(0, 0.5, 0)
        local att1 = Instance.new("Attachment")
        att1.Parent = part
        att1.Position = Vector3.new(0, 0, 0)
        grabberBeam = Instance.new("Beam")
        grabberBeam.Attachment0 = att0
        grabberBeam.Attachment1 = att1
        grabberBeam.Color = ColorSequence.new(Color3.new(0, 1, 0))
        grabberBeam.Width0 = 0.2
        grabberBeam.Width1 = 0.2
        grabberBeam.Brightness = 3
        grabberBeam.LightEmission = 1
        grabberBeam.FaceCamera = true
        grabberBeam.Parent = workspace
        grabbedPart = part
        grabberActive = true
        grabberConn = RunService.RenderStepped:Connect(function()
            if not grabberActive then
                if grabberConn then grabberConn:Disconnect() end
                return
            end
            if grabberBodyPos and grabberBodyPos.Parent then
                local camera = workspace.CurrentCamera
                local targetPos = camera.CFrame.Position + camera.CFrame.LookVector * 25
                grabberBodyPos.Position = targetPos
            end
        end)
    end)
    tool.Unequipped:Connect(cleanupGrabber)
    tool.AncestryChanged:Connect(function()
        if not tool.Parent then
            cleanupGrabber()
            grabberTool = nil
        end
    end)
    return tool
end

grabberBtn.MouseButton1Click:Connect(function()
    if grabberTool then
        grabberTool:Destroy()
        grabberTool = nil
        grabberBtn.Text = "Grabber"
        grabberBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
        Notify("Grabber removed", "Grabber", 2)
    else
        grabberTool = createGrabberTool()
        grabberBtn.Text = "Grabber ON"
        grabberBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        Notify("Grabber added to backpack", "Grabber", 2)
    end
end)

local function applySpeed()
    local dir = humanoid.MoveDirection
    local targetSpeed = BASE_WALK_SPEED * currentSpeedMult
    if speedMethod == "CFrame" then
        if dir.Magnitude > 0 then
            local y = hrp.Position.Y
            hrp.CFrame = hrp.CFrame + (dir * targetSpeed * RunService.Heartbeat:Wait())
            hrp.CFrame = CFrame.new(hrp.Position.X, y, hrp.Position.Z)
        end
    elseif speedMethod == "Strength" then
        if dir.Magnitude > 0 then
            local speedLimit = BASE_WALK_SPEED * math.min(currentSpeedMult, 2)
            local force = 1e12 * currentSpeedMult
            if not hrp:FindFirstChild("StrengthVelocity") then
                local bv = Instance.new("BodyVelocity")
                bv.Name = "StrengthVelocity"
                bv.MaxForce = Vector3.new(force, force, force)
                bv.Parent = hrp
            end
            local bv = hrp:FindFirstChild("StrengthVelocity")
            if bv then
                bv.MaxForce = Vector3.new(force, force, force)
                bv.Velocity = dir * speedLimit
            end
        else
            local bv = hrp:FindFirstChild("StrengthVelocity")
            if bv then bv:Destroy() end
        end
    elseif speedMethod == "Off" then
        local bv = hrp:FindFirstChild("StrengthVelocity")
        if bv then bv:Destroy() end
    end
end

RunService.Heartbeat:Connect(function()
    applySpeed()
    updateYStabilizer()
end)

closeBtn.MouseButton1Click:Connect(function()
    destroyYStabilizer()
    if infJumpConnection then infJumpConnection:Disconnect() end
    if puncherEnabled then
        puncherEnabled = false
        enablePuncher()
    end
    if grabberTool then grabberTool:Destroy() end
    local bv = hrp:FindFirstChild("StrengthVelocity")
    if bv then bv:Destroy() end
    humanoid.WalkSpeed = BASE_WALK_SPEED
    gui:Destroy()
    script:Destroy()
end)

updateSliderUI(1)
setSpeedMethod("Off")
Notify("Strongman GUI", "System", 2)
