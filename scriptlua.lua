local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local head = character:WaitForChild("Head")
local Mouse = player:GetMouse()
local PlaceId = game.PlaceId
local JobId = game.JobId

local BASE_WALK_SPEED = humanoid.WalkSpeed
local BASE_JUMP = humanoid.JumpPower

local function generate_string(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local result = ""
    for _ = 1, length or 10 do
        result = result .. charset:sub(math.random(1, #charset), math.random(1, #charset))
    end
    return result
end

local function Notify(text, title, duration)
    duration = duration or 4
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
    frameNotif.Size = UDim2.new(0, 300, 0, 70)
    frameNotif.Position = UDim2.new(1, 320, 1, -10)
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
    titleLabel.Size = UDim2.new(1, -10, 0, 24)
    titleLabel.Position = UDim2.new(0, 5, 0, 4)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title or "Notice"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 201
    titleLabel.Parent = frameNotif

    local bodyLabel = Instance.new("TextLabel")
    bodyLabel.BackgroundTransparency = 1
    bodyLabel.Size = UDim2.new(1, -10, 1, -30)
    bodyLabel.Position = UDim2.new(0, 5, 0, 28)
    bodyLabel.Font = Enum.Font.Gotham
    bodyLabel.Text = text or ""
    bodyLabel.TextColor3 = Color3.new(1, 1, 1)
    bodyLabel.TextSize = 14
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
            Position = UDim2.new(1, 320, 1, -10)
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

local function NotifyERROR(text)
    Notify(text, "ERROR", 3)
end

if not _G.FullBrightExecuted then
    _G.FullBrightEnabled = false
    _G.NormalLightingSettings = {
        Brightness    = Lighting.Brightness,
        ClockTime     = Lighting.ClockTime,
        FogEnd        = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient       = Lighting.Ambient,
    }
    local function fbProtect(prop, fullValue)
        Lighting:GetPropertyChangedSignal(prop):Connect(function()
            if Lighting[prop] ~= fullValue and Lighting[prop] ~= _G.NormalLightingSettings[prop] then
                _G.NormalLightingSettings[prop] = Lighting[prop]
                repeat task.wait() until _G.FullBrightEnabled
                Lighting[prop] = fullValue
            end
        end)
    end
    fbProtect("Brightness",    1)
    fbProtect("ClockTime",     12)
    fbProtect("FogEnd",        786543)
    fbProtect("GlobalShadows", false)
    fbProtect("Ambient",       Color3.fromRGB(178,178,178))

    spawn(function()
        local last = _G.FullBrightEnabled
        while true do
            task.wait(0.1)
            if _G.FullBrightEnabled ~= last then
                if _G.FullBrightEnabled then
                    Lighting.Brightness    = 1
                    Lighting.ClockTime     = 12
                    Lighting.FogEnd        = 786543
                    Lighting.GlobalShadows = false
                    Lighting.Ambient       = Color3.fromRGB(178,178,178)
                else
                    for k,v in pairs(_G.NormalLightingSettings) do
                        Lighting[k] = v
                    end
                end
                last = _G.FullBrightEnabled
            end
        end
    end)
    _G.FullBrightExecuted = true
end

if _G.InfiniteJumpEnabled == nil then
    _G.InfiniteJumpEnabled = false
    UIS.JumpRequest:Connect(function()
        if _G.InfiniteJumpEnabled then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "ControlGUI"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.32, 0, 0.72, 0)
frame.Position = UDim2.new(0.34, 0, 0.14, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.02, 0)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(180, 180, 200)
stroke.Thickness = 1
stroke.Transparency = 0.4
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Text = "EXVS ► Multi Tool"
title.Size = UDim2.new(0.8, 0, 0.05, 0)
title.Position = UDim2.new(0.05, 0, 0.01, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local closeButton = Instance.new("TextButton")
closeButton.Text = "X"
closeButton.Size = UDim2.new(0.08, 0, 0.05, 0)
closeButton.Position = UDim2.new(0.92, 0, 0.01, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeButton.BackgroundTransparency = 0.2
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.AutoButtonColor = false
closeButton.Parent = frame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0.2, 0)
closeCorner.Parent = closeButton

local containers = {}
local function addContainer(name, ypos, height)
    height = height or 0.06
    local c = Instance.new("Frame")
    c.Size = UDim2.new(0.9, 0, height, 0)
    c.Position = UDim2.new(0.05, 0, ypos, 0)
    c.BackgroundTransparency = 1
    c.Parent = frame
    containers[name] = c
end
addContainer("speed", 0.07)
addContainer("jump", 0.135)
addContainer("buttons1", 0.20)
addContainer("buttons2", 0.27)
addContainer("flySpeed", 0.34)
addContainer("extra", 0.41)
addContainer("extra2", 0.48)
addContainer("instruction", 0.55, 0.14)

local sliders = {}
local function addSlider(container, name, labelText, isLog, minVal, maxVal, defaultVal)
    local s = {}
    s.label = Instance.new("TextLabel")
    s.label.Text = labelText
    s.label.Size = UDim2.new(0.4, 0, 0.4, 0)
    s.label.Position = UDim2.new(0, 0, 0, 0)
    s.label.BackgroundTransparency = 1
    s.label.TextColor3 = Color3.fromRGB(255,255,255)
    s.label.Font = Enum.Font.Gotham
    s.label.TextSize = 11
    s.label.TextXAlignment = Enum.TextXAlignment.Left
    s.label.Parent = container

    s.slider = Instance.new("Frame")
    s.slider.Size = UDim2.new(0.42, 0, 0.3, 0)
    s.slider.Position = UDim2.new(0.42, 0, 0.35, 0)
    s.slider.BackgroundColor3 = Color3.fromRGB(60,60,70)
    s.slider.BorderSizePixel = 0
    s.slider.Parent = container
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0.3,0)
    sc.Parent = s.slider

    s.fill = Instance.new("Frame")
    s.fill.Size = UDim2.new(0,0,1,0)
    s.fill.BackgroundColor3 = Color3.fromRGB(0,150,255)
    s.fill.BorderSizePixel = 0
    s.fill.ZIndex = 2
    s.fill.Parent = s.slider
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0.3,0)
    fc.Parent = s.fill

    s.button = Instance.new("TextButton")
    s.button.Size = UDim2.new(0,16,1.8,0)
    s.button.Position = UDim2.new(0,-8,-0.4,0)
    s.button.BackgroundColor3 = Color3.fromRGB(255,255,255)
    s.button.BorderSizePixel = 0
    s.button.Text = ""
    s.button.ZIndex = 3
    s.button.Parent = s.slider
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0.5,0)
    bc.Parent = s.button

    s.box = Instance.new("TextBox")
    s.box.Size = UDim2.new(0.12,0,0.5,0)
    s.box.Position = UDim2.new(0.86,0,0.25,0)
    s.box.BackgroundColor3 = Color3.fromRGB(40,40,50)
    s.box.TextColor3 = Color3.fromRGB(255,255,255)
    s.box.Font = Enum.Font.Gotham
    s.box.TextSize = 11
    s.box.ClearTextOnFocus = false
    s.box.Text = tostring(defaultVal)
    s.box.Parent = container
    local bc2 = Instance.new("UICorner")
    bc2.CornerRadius = UDim.new(0.2,0)
    bc2.Parent = s.box
    sliders[name] = s
    return s
end
addSlider(containers.speed, "speed", "Speed (0.001x-8Bx):", true, 0.001, 8e9, 1)
addSlider(containers.jump, "jump", "Jump (1x-100x):", false, 1, 100, 1)
addSlider(containers.flySpeed, "flySpeed", "Fly Speed (0.001x-1500x):", true, 0.001, 1500, 1)

local buttons = {}
local function createButton(parent, text, color, xPos, width)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Size = UDim2.new(width or 0.21, 0, 0.4, 0)
    btn.Position = UDim2.new(xPos or 0, 0, 0.1, 0)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.AutoButtonColor = false
    btn.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0.2,0)
    c.Parent = btn
    btn:SetAttribute("OriginalColor", color)
    btn:SetAttribute("ActiveColor", Color3.fromRGB(0,200,100))
    btn:SetAttribute("IsActive", false)
    btn.MouseEnter:Connect(function()
        if not btn:GetAttribute("IsActive") then
            local oc = btn:GetAttribute("OriginalColor")
            btn.BackgroundColor3 = Color3.fromRGB(
                math.min(oc.R*255+30,255),
                math.min(oc.G*255+30,255),
                math.min(oc.B*255+30,255))/255
        end
    end)
    btn.MouseLeave:Connect(function()
        if not btn:GetAttribute("IsActive") then
            btn.BackgroundColor3 = btn:GetAttribute("OriginalColor")
        else
            btn.BackgroundColor3 = btn:GetAttribute("ActiveColor")
        end
    end)
    return btn
end

buttons.fullbright = createButton(containers.buttons1, "FullBright", Color3.fromRGB(255,0,0), 0, 0.22)
buttons.infJump = createButton(containers.buttons1, "Inf Jump", Color3.fromRGB(255,165,0), 0.24, 0.22)
buttons.speedMethod = createButton(containers.buttons1, "Speed OFF", Color3.fromRGB(100,200,100), 0.48, 0.22)
buttons.noclip = createButton(containers.buttons1, "Noclip OFF", Color3.fromRGB(100,100,200), 0.72, 0.22)

buttons.fly = createButton(containers.buttons2, "Fly", Color3.fromRGB(0,255,255), 0, 0.22)
buttons.esp = createButton(containers.buttons2, "ESP OFF", Color3.fromRGB(255,255,255), 0.24, 0.22)
buttons.clickTP = createButton(containers.buttons2, "Click TP", Color3.fromRGB(0,0,255), 0.48, 0.22)
buttons.tweenMove = createButton(containers.buttons2, "Tween Move", Color3.fromRGB(128,0,128), 0.72, 0.22)

buttons.fling = createButton(containers.extra, "Fling OFF", Color3.fromRGB(255,100,0), 0, 0.22)
buttons.yStab = createButton(containers.extra, "Y-Stab OFF", Color3.fromRGB(0,200,200), 0.24, 0.22)
buttons.fused = createButton(containers.extra, "Fused", Color3.fromRGB(0,150,0), 0.48, 0.22)

buttons.stabilize = createButton(containers.extra2, "Move Stab OFF", Color3.fromRGB(150,0,150), 0, 0.22)
buttons.aimbot = createButton(containers.extra2, "AimBot OFF", Color3.fromRGB(150,100,0), 0.24, 0.22)
buttons.puncher = createButton(containers.extra2, "Puncher OFF", Color3.fromRGB(200,100,0), 0.48, 0.22)
buttons.grabber = createButton(containers.extra2, "Grabber", Color3.fromRGB(0,100,150), 0.72, 0.22)

buttons.fly.TextColor3 = Color3.fromRGB(0,0,0)
buttons.esp.TextColor3 = Color3.fromRGB(0,0,0)
buttons.fling.TextColor3 = Color3.fromRGB(0,0,0)
buttons.yStab.TextColor3 = Color3.fromRGB(0,0,0)
buttons.stabilize.TextColor3 = Color3.fromRGB(255,255,255)
buttons.aimbot.TextColor3 = Color3.fromRGB(255,255,255)
buttons.puncher.TextColor3 = Color3.fromRGB(255,255,255)
buttons.grabber.TextColor3 = Color3.fromRGB(255,255,255)
buttons.noclip.TextColor3 = Color3.fromRGB(0,0,0)

local instructionLabel = Instance.new("TextLabel")
instructionLabel.Size = UDim2.new(0.96, 0, 1, 0)
instructionLabel.Position = UDim2.new(0.02, 0, 0.02, 0)
instructionLabel.BackgroundTransparency = 1
instructionLabel.Text = "Recommended speed-up method: Legit. Use Strength mode to push/pull heavy objects. If Grabber or Puncher don't working, nudge, jump, or touch the target until they activate. Y‑Stab counteracts unintended upward impulses (e.g., from high speed), keeping you grounded while running. Move‑Stab prevents rubberbanding or movement without your input. AimBot: hold RMB to snap camera to the nearest player. The Fused tab contains various scripts – some may be broken or low quality, use with caution."
instructionLabel.TextColor3 = Color3.fromRGB(220,220,220)
instructionLabel.Font = Enum.Font.GothamBold
instructionLabel.TextSize = 12
instructionLabel.TextWrapped = true
instructionLabel.TextXAlignment = Enum.TextXAlignment.Left
instructionLabel.TextYAlignment = Enum.TextYAlignment.Top
instructionLabel.Parent = containers.instruction

local resizeHandle = Instance.new("TextButton")
resizeHandle.Size = UDim2.new(0,16,0,16)
resizeHandle.Position = UDim2.new(1,-16,1,-16)
resizeHandle.BackgroundColor3 = Color3.fromRGB(80,80,90)
resizeHandle.BackgroundTransparency = 0.3
resizeHandle.BorderSizePixel = 0
resizeHandle.Text = ""
resizeHandle.ZIndex = 10
resizeHandle.Parent = frame
local rhc = Instance.new("UICorner")
rhc.CornerRadius = UDim.new(0.2,0)
rhc.Parent = resizeHandle
local resizeIcon = Instance.new("ImageLabel")
resizeIcon.Size = UDim2.new(0.6,0,0.6,0)
resizeIcon.Position = UDim2.new(0.2,0,0.2,0)
resizeIcon.BackgroundTransparency = 1
resizeIcon.Image = "rbxassetid://11189678979"
resizeIcon.ImageColor3 = Color3.fromRGB(200,200,220)
resizeIcon.ZIndex = 11
resizeIcon.Parent = resizeHandle

local currentSpeedMult = 1
local currentJumpMult = 1
local flySpeedMult = 1
local speedMethod = "Off"
local espEnabled = false
local clickTPEnabled = false
local tweenMoveEnabled = false
local flyEnabled = false
local flingEnabled = false
local noclipEnabled = false
local yStabEnabled = false
local moveStabEnabled = false
local aimbotEnabled = false
local puncherEnabled = false

local bodyVelocity = nil
local strengthBodyVelocity = nil
local legitCurrentSpeed = 0
local legitLastMoveTime = tick()
local lastUpdateTime = tick()
local collidePlatform = nil
local yStabilizerForce = nil
local yStabilizerAttachment = nil

local flyBodyGyro = nil
local flyBodyVelocity = nil
local flyControls = {f=0,b=0,l=0,r=0}
local lastFlyControls = {f=0,b=0,l=0,r=0}
local currentFlySpeed = 0
local baseFlySpeed = 50

local activeTween = nil
local activeMarkers = {}
local espHighlights = {}
local espBeams = {}
local clickTPConnection = nil
local noclipThread = nil
local flingCoroutine = nil
local aimbotConnection = nil
local puncherConnections = {}
local puncherParts = {}

local trustedPosition = nil
local trustedVelocity = nil
local lastUpdateStabTime = tick()
local inputActive = false
local tempTeleportAllowed = false
local tempTeleportUntil = 0

local function isInputActive()
    return UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.S) or
           UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.D)
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
        if not isJumping and not flyEnabled then
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

local function setButtonActive(btn, active)
    btn:SetAttribute("IsActive", active)
    btn.BackgroundColor3 = active and btn:GetAttribute("ActiveColor") or btn:GetAttribute("OriginalColor")
end

local function updateSliderUI(sliderData, value, maxVal, minVal, isLog)
    if type(value) == "Color3" then value = 1 end
    value = tonumber(value) or 1
    value = math.clamp(value, minVal, maxVal)
    
    if isLog then
        sliderData.box.Text = string.format("%.3f", value)
        local logMin = math.log10(minVal)
        local logMax = math.log10(maxVal)
        local logValue = math.log10(value)
        local ratio = (logValue - logMin) / (logMax - logMin)
        ratio = math.clamp(ratio, 0, 1)
        sliderData.fill.Size = UDim2.new(ratio, 0, 1, 0)
        local btnPos = ratio * sliderData.slider.AbsoluteSize.X - 8
        local relativePos = btnPos / sliderData.slider.AbsoluteSize.X
        sliderData.button.Position = UDim2.new(relativePos, -8, -0.4, 0)
    else
        value = math.floor(value)
        sliderData.box.Text = tostring(value)
        local ratio = value / maxVal
        sliderData.fill.Size = UDim2.new(ratio, 0, 1, 0)
        local btnPos = ratio * sliderData.slider.AbsoluteSize.X - 8
        local relativePos = btnPos / sliderData.slider.AbsoluteSize.X
        sliderData.button.Position = UDim2.new(relativePos, -8, -0.4, 0)
    end
    sliderData.fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
end

local function updateAllSliders()
    updateSliderUI(sliders.speed, currentSpeedMult, 8e9, 0.001, true)
    updateSliderUI(sliders.jump, currentJumpMult, 100, 1, false)
    updateSliderUI(sliders.flySpeed, flySpeedMult, 1500, 0.001, true)
end

local function clampVal(v, minv, maxv)
    if type(v) == "Color3" then v = 1 end
    return math.clamp(tonumber(v) or minv, minv, maxv)
end

local function destroyAllSpeedControllers()
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if strengthBodyVelocity then strengthBodyVelocity:Destroy() strengthBodyVelocity = nil end
    if collidePlatform then
        collidePlatform.Platform:Destroy()
        collidePlatform = nil
    end
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    humanoid.PlatformStand = false
    if yStabilizerForce then yStabilizerForce:Destroy() yStabilizerForce = nil end
    if yStabilizerAttachment then yStabilizerAttachment:Destroy() yStabilizerAttachment = nil end
    
    humanoid.WalkSpeed = BASE_WALK_SPEED
    
    if hrp then
        hrp.Massless = false
        hrp:SetAttribute("OriginalMass", nil)
    end
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj:IsA("BodyAngularVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyThrust") then
            if obj.Name ~= "FlingGyro" then
                obj:Destroy()
            end
        end
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
    local state = humanoid:GetState()
    if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
        local vy = hrp.Velocity.Y
        if vy > 0 then
            yStabilizerForce.Force = Vector3.new(0, -vy * 4000, 0)
        else
            yStabilizerForce.Force = Vector3.new(0, 0, 0)
        end
    else
        yStabilizerForce.Force = Vector3.new(0, 0, 0)
    end
end

local function destroyYStabilizer()
    if yStabilizerForce then yStabilizerForce:Destroy() yStabilizerForce = nil end
    if yStabilizerAttachment then yStabilizerAttachment:Destroy() yStabilizerAttachment = nil end
end

local function ensureBodyVelocity()
    if not bodyVelocity then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e9, 0, 1e9)
        bodyVelocity.Parent = character:WaitForChild("HumanoidRootPart")
    end
end

local function ensureStrengthVelocity()
    if not strengthBodyVelocity then
        strengthBodyVelocity = Instance.new("BodyVelocity")
        strengthBodyVelocity.Parent = character:WaitForChild("HumanoidRootPart")
    end
end

local function updateStrength()
    if speedMethod ~= "Strength" then
        if strengthBodyVelocity then strengthBodyVelocity:Destroy() strengthBodyVelocity = nil end
        if hrp then hrp.Massless = false end
        return
    end
    ensureStrengthVelocity()
    if strengthBodyVelocity then
        local dir = humanoid.MoveDirection
        local maxSpeedMult = 2
        local speedMult = math.min(currentSpeedMult, maxSpeedMult)
        local speedLimit = BASE_WALK_SPEED * speedMult
        strengthBodyVelocity.Velocity = dir * speedLimit
        local force = 1e12 * currentSpeedMult
        strengthBodyVelocity.MaxForce = Vector3.new(force, force, force)
        if hrp then
            hrp.Massless = false
            hrp:SetAttribute("OriginalMass", hrp:GetAttribute("OriginalMass") or hrp.Mass)
        end
    end
end

local function createCollidePlatform()
    if collidePlatform then
        collidePlatform.Platform:Destroy()
        collidePlatform = nil
    end
    if not hrp then return end
    local platform = Instance.new("Part")
    platform.Name = "CollidePlatform"
    platform.Size = Vector3.new(4, 0.5, 4)
    platform.Anchored = false
    platform.CanCollide = true
    platform.Transparency = 1
    platform.Material = Enum.Material.SmoothPlastic
    platform.Parent = workspace
    local weld = Instance.new("Weld")
    weld.Part0 = hrp
    weld.Part1 = platform
    weld.C0 = CFrame.new(0, -2, 0)
    weld.C1 = CFrame.new(0,0,0)
    weld.Parent = platform
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9, 0, 1e9)
    bv.Parent = platform
    collidePlatform = {Platform = platform, Velocity = bv, Weld = weld}
end

local function updateCollide(targetSpeed)
    if not collidePlatform then createCollidePlatform() end
    if collidePlatform and collidePlatform.Velocity then
        local dir = humanoid.MoveDirection
        collidePlatform.Velocity.Velocity = dir * targetSpeed
    end
end

local LEGIT_ACCEL = (PlaceId == 13796645198) and 600 or 150
local function updateLegitCollide(dt)
    if speedMethod ~= "Legit" then return end
    local targetSpeed = BASE_WALK_SPEED * currentSpeedMult
    local now = tick()
    if humanoid.MoveDirection.Magnitude > 0 then
        legitCurrentSpeed = math.min(legitCurrentSpeed + LEGIT_ACCEL * dt, targetSpeed)
        legitLastMoveTime = now
    else
        if now - legitLastMoveTime > 2 then
            legitCurrentSpeed = 0
        else
            legitCurrentSpeed = math.max(legitCurrentSpeed - LEGIT_ACCEL * dt, 0)
        end
    end
    updateCollide(legitCurrentSpeed)
end

local function updateCollideMethod()
    if speedMethod == "Collide" then
        local targetSpeed = BASE_WALK_SPEED * currentSpeedMult
        updateCollide(targetSpeed)
    end
end

local function setNoclip(enabled)
    noclipEnabled = enabled
    if enabled then
        if not noclipThread or coroutine.status(noclipThread) == "dead" then
            noclipThread = coroutine.create(function()
                while noclipEnabled do
                    if character and character.Parent then
                        for _, part in ipairs(character:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                    task.wait(0.1)
                end
            end)
            coroutine.resume(noclipThread)
        end
    else
        noclipEnabled = false
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

local function disableFlyEXVS()
    if flyBodyGyro then flyBodyGyro:Destroy() end
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    humanoid.PlatformStand = false
    flyControls = {f=0,b=0,l=0,r=0}
    currentFlySpeed = 0
end

local function enableFling()
    if flingCoroutine and coroutine.status(flingCoroutine) ~= "dead" then return end
    flingCoroutine = coroutine.create(function()
        local movel = 0.1
        while flingEnabled do
            if hrp then
                local vel = hrp.Velocity
                hrp.Velocity = vel * 10000 + Vector3.new(0,10000,0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = vel
                RunService.Stepped:Wait()
                hrp.Velocity = vel + Vector3.new(0,movel,0)
                movel = -movel
            end
            task.wait()
        end
    end)
    coroutine.resume(flingCoroutine)
    if hrp and not hrp:FindFirstChild("FlingGyro") then
        local gyro = Instance.new("BodyGyro")
        gyro.Name = "FlingGyro"
        gyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
        gyro.P = 20000
        gyro.D = 2000
        gyro.CFrame = hrp.CFrame
        gyro.Parent = hrp
        local rotateTask
        rotateTask = RunService.Heartbeat:Connect(function()
            if flingEnabled and gyro and gyro.Parent then
                gyro.CFrame = gyro.CFrame * CFrame.Angles(0, math.rad(500), 0)
            elseif not flingEnabled then
                rotateTask:Disconnect()
            end
        end)
        _G.flingRotateTask = rotateTask
    end
end

local function disableFling()
    flingEnabled = false
    flingCoroutine = nil
    if hrp then
        local gyro = hrp:FindFirstChild("FlingGyro")
        if gyro then gyro:Destroy() end
    end
    if _G.flingRotateTask then _G.flingRotateTask:Disconnect() end
    if hrp then hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0) end
end

local function updateESP()
    if not espEnabled then return end
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local targetChar = otherPlayer.Character
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                if not espHighlights[otherPlayer] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(255,0,0)
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.fromRGB(255,255,255)
                    hl.OutlineTransparency = 0.2
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = targetChar
                    espHighlights[otherPlayer] = hl
                end
                local localHRP = hrp
                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                if localHRP and targetHRP and not espBeams[otherPlayer] then
                    local beam = Instance.new("Beam")
                    beam.Color = ColorSequence.new(Color3.new(1,0,0))
                    beam.Width0 = 0.2
                    beam.Width1 = 0.2
                    beam.Brightness = 3
                    beam.LightEmission = 1
                    beam.FaceCamera = true
                    local att0 = Instance.new("Attachment")
                    att0.Parent = localHRP
                    att0.Position = Vector3.new(0,1.5,0)
                    local att1 = Instance.new("Attachment")
                    att1.Parent = targetHRP
                    att1.Position = Vector3.new(0,1.5,0)
                    beam.Attachment0 = att0
                    beam.Attachment1 = att1
                    beam.Parent = workspace
                    espBeams[otherPlayer] = {Beam=beam, Att0=att0, Att1=att1}
                end
            else
                if espHighlights[otherPlayer] then espHighlights[otherPlayer]:Destroy() espHighlights[otherPlayer]=nil end
                if espBeams[otherPlayer] then
                    espBeams[otherPlayer].Beam:Destroy()
                    espBeams[otherPlayer].Att0:Destroy()
                    espBeams[otherPlayer].Att1:Destroy()
                    espBeams[otherPlayer]=nil
                end
            end
        end
    end
end

local function cleanupESP()
    for _,hl in pairs(espHighlights) do hl:Destroy() end
    espHighlights = {}
    for _,data in pairs(espBeams) do
        data.Beam:Destroy()
        data.Att0:Destroy()
        data.Att1:Destroy()
    end
    espBeams = {}
end

local function createMarker(pos)
    local m = Instance.new("Part")
    m.Size = Vector3.new(2,10,2)
    m.Position = pos + Vector3.new(0,5,0)
    m.Anchored = true
    m.CanCollide = false
    m.Material = Enum.Material.Neon
    m.BrickColor = BrickColor.new("Bright green")
    m.Parent = workspace
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Range = 15
    light.Color = Color3.new(0,1,0)
    light.Parent = m
    table.insert(activeMarkers, m)
    return m
end

local function cleanupMarkers()
    for _,m in ipairs(activeMarkers) do m:Destroy() end
    activeMarkers = {}
end

local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local closestDistance = math.huge
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local char = otherPlayer.Character
            local targetRoot = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
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
            local camera = workspace.CurrentCamera
            camera.CFrame = CFrame.new(camera.CFrame.Position, targetRoot.Position)
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
    else
        if aimbotConnection then aimbotConnection:Disconnect() end
    end
end

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

local activeGrabbers = {}
local grabberTool = nil

local function setupGrabber(tool)
    if not tool then return end
    if activeGrabbers[tool] then return end
    local data = {
        grabbed = false,
        bodyPosition = nil,
        beam = nil,
        grabbedPart = nil,
        connection = nil,
    }
    activeGrabbers[tool] = data
    
    local function cleanup()
        if data.bodyPosition then data.bodyPosition:Destroy() data.bodyPosition = nil end
        if data.beam then data.beam:Destroy() data.beam = nil end
        if data.grabbedPart then
            data.grabbedPart = nil
        end
        if data.connection then data.connection:Disconnect() data.connection = nil end
        data.grabbed = false
    end
    
    tool.Activated:Connect(function()
        if data.grabbed then
            cleanup()
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
        
        data.bodyPosition = Instance.new("BodyPosition")
        data.bodyPosition.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        data.bodyPosition.P = 2000
        data.bodyPosition.D = 500
        data.bodyPosition.Parent = part
        
        local att0 = Instance.new("Attachment")
        att0.Parent = head
        att0.Position = Vector3.new(0, 0.5, 0)
        
        local att1 = Instance.new("Attachment")
        att1.Parent = part
        att1.Position = Vector3.new(0,0,0)
        
        data.beam = Instance.new("Beam")
        data.beam.Attachment0 = att0
        data.beam.Attachment1 = att1
        data.beam.Color = ColorSequence.new(Color3.new(0,1,0))
        data.beam.Width0 = 0.2
        data.beam.Width1 = 0.2
        data.beam.Brightness = 3
        data.beam.LightEmission = 1
        data.beam.FaceCamera = true
        data.beam.Parent = workspace
        
        data.grabbedPart = part
        
        data.connection = RunService.RenderStepped:Connect(function()
            if not data.grabbed then 
                if data.connection then data.connection:Disconnect() end
                return 
            end
            if data.bodyPosition and data.bodyPosition.Parent then
                local camera = workspace.CurrentCamera
                local targetPos = camera.CFrame.Position + camera.CFrame.LookVector * 25
                data.bodyPosition.Position = targetPos
            end
        end)
        
        data.grabbed = true
    end)
    
    tool.Unequipped:Connect(function()
        cleanup()
    end)
    
    tool.AncestryChanged:Connect(function()
        if not tool.Parent then
            cleanup()
            activeGrabbers[tool] = nil
        end
    end)
end

local function createGrabberTool()
    if grabberTool then grabberTool:Destroy() end
    local tool = Instance.new("Tool")
    tool.Name = "Grabber"
    tool.RequiresHandle = false
    tool.CanBeDropped = true
    tool.Parent = player.Backpack
    setupGrabber(tool)
    return tool
end

local function applySpeed()
    local now = tick()
    local dt = math.min(now - lastUpdateTime, 0.1)
    lastUpdateTime = now

    local dir = humanoid.MoveDirection
    local targetSpeed = BASE_WALK_SPEED * currentSpeedMult

    if flyEnabled and flyBodyGyro and flyBodyVelocity then
        local currentFlySpeedValue = baseFlySpeed * flySpeedMult
        if flyControls.l+flyControls.r ~= 0 or flyControls.f+flyControls.b ~= 0 then
            currentFlySpeed = currentFlySpeed + 0.5 + (currentFlySpeed/currentFlySpeedValue)
            if currentFlySpeed > currentFlySpeedValue then currentFlySpeed = currentFlySpeedValue end
        elseif currentFlySpeed ~= 0 then
            currentFlySpeed = currentFlySpeed - 1
            if currentFlySpeed < 0 then currentFlySpeed = 0 end
        end
        if (flyControls.l+flyControls.r)~=0 or (flyControls.f+flyControls.b)~=0 then
            local look = workspace.CurrentCamera.CFrame.lookVector
            local side = (workspace.CurrentCamera.CFrame * CFrame.new(flyControls.l+flyControls.r, (flyControls.f+flyControls.b)*0.2, 0).p) - workspace.CurrentCamera.CFrame.p
            flyBodyVelocity.velocity = (look*(flyControls.f+flyControls.b) + side) * currentFlySpeed
            lastFlyControls = {f=flyControls.f,b=flyControls.b,l=flyControls.l,r=flyControls.r}
        elseif currentFlySpeed ~= 0 then
            local look = workspace.CurrentCamera.CFrame.lookVector
            local side = (workspace.CurrentCamera.CFrame * CFrame.new(lastFlyControls.l+lastFlyControls.r, (lastFlyControls.f+lastFlyControls.b)*0.2, 0).p) - workspace.CurrentCamera.CFrame.p
            flyBodyVelocity.velocity = (look*(lastFlyControls.f+lastFlyControls.b) + side) * currentFlySpeed
        else
            flyBodyVelocity.velocity = Vector3.new(0,0,0)
        end
        flyBodyGyro.cframe = workspace.CurrentCamera.CFrame
        return
    end

    if tweenMoveEnabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local target = Mouse.Hit.Position
        if hrp then
            cleanupMarkers()
            local marker = createMarker(target)
            if activeTween then activeTween:Cancel() end
            local dist = (target - hrp.Position).Magnitude
            local dur = dist / (targetSpeed * 2)
            activeTween = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = CFrame.new(target + Vector3.new(0,3,0))})
            activeTween:Play()
            activeTween.Completed:Connect(function() marker:Destroy() activeTween = nil end)
            allowTempTeleport(dur + 0.5)
        end
    end

    updateYStabilizer()
    updateStrength()
    updateLegitCollide(dt)
    updateCollideMethod()

    if not hrp then return end

    if speedMethod == "Off" then
        humanoid.WalkSpeed = BASE_WALK_SPEED
    elseif speedMethod == "BodyVelocity" then
        ensureBodyVelocity()
        if bodyVelocity then bodyVelocity.Velocity = dir * targetSpeed end
        humanoid.WalkSpeed = BASE_WALK_SPEED
    elseif speedMethod == "WalkSpeed" then
        destroyAllSpeedControllers()
        humanoid.WalkSpeed = targetSpeed
    elseif speedMethod == "CFrame" then
        destroyAllSpeedControllers()
        humanoid.WalkSpeed = BASE_WALK_SPEED
        if dir.Magnitude > 0 then
            local y = hrp.Position.Y
            hrp.CFrame = hrp.CFrame + (dir * targetSpeed * dt)
            hrp.CFrame = CFrame.new(hrp.Position.X, y, hrp.Position.Z)
        end
    elseif speedMethod == "Collide" then
        humanoid.WalkSpeed = BASE_WALK_SPEED
    elseif speedMethod == "Tween" then
        destroyAllSpeedControllers()
        humanoid.WalkSpeed = BASE_WALK_SPEED
        if dir.Magnitude > 0 and not activeTween then
            local targetPos = hrp.Position + (dir * targetSpeed * 0.1)
            activeTween = TweenService:Create(hrp, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
            activeTween:Play()
            activeTween.Completed:Connect(function() activeTween = nil end)
            allowTempTeleport(0.1)
        end
    elseif speedMethod == "Velocity" then
        destroyAllSpeedControllers()
        if dir.Magnitude > 0 then
            hrp.Velocity = dir * targetSpeed
        else
            hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
        end
        humanoid.WalkSpeed = BASE_WALK_SPEED
    elseif speedMethod == "Strength" then
        if bodyVelocity then bodyVelocity.Velocity = Vector3.new(0,0,0) end
        humanoid.WalkSpeed = BASE_WALK_SPEED
    end
end

local function applyJumpBoost()
    if humanoid:GetState() == Enum.HumanoidStateType.Jumping then
        if hrp and not hrp:FindFirstChild("JumpBoost") then
            local at = Instance.new("Attachment", hrp)
            local vf = Instance.new("VectorForce")
            vf.Name = "JumpBoost"
            vf.Force = Vector3.new(0, BASE_JUMP * currentJumpMult * 25, 0)
            vf.RelativeTo = Enum.ActuatorRelativeTo.World
            vf.ApplyAtCenterOfMass = true
            vf.Attachment0 = at
            vf.Parent = hrp
            Debris:AddItem(vf, 0.2)
            Debris:AddItem(at, 0.2)
        end
    end
end

local drag = {speed=false, jump=false, flySpeed=false}
sliders.speed.button.MouseButton1Down:Connect(function() drag.speed=true end)
sliders.jump.button.MouseButton1Down:Connect(function() drag.jump=true end)
sliders.flySpeed.button.MouseButton1Down:Connect(function() drag.flySpeed=true end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if drag.speed then
        local pos = input.Position.X - sliders.speed.slider.AbsolutePosition.X
        local ratio = math.clamp(pos / sliders.speed.slider.AbsoluteSize.X, 0, 1)
        local logMin = math.log10(0.001)
        local logMax = math.log10(8e9)
        currentSpeedMult = 10^(logMin + ratio*(logMax-logMin))
        currentSpeedMult = math.clamp(currentSpeedMult, 0.001, 8e9)
        sliders.speed.box.Text = string.format("%.3f", currentSpeedMult)
        updateSliderUI(sliders.speed, currentSpeedMult, 8e9, 0.001, true)
        if speedMethod == "WalkSpeed" then humanoid.WalkSpeed = BASE_WALK_SPEED * currentSpeedMult end
    elseif drag.jump then
        local pos = input.Position.X - sliders.jump.slider.AbsolutePosition.X
        local ratio = math.clamp(pos / sliders.jump.slider.AbsoluteSize.X, 0, 1)
        currentJumpMult = math.floor(ratio * 99) + 1
        updateSliderUI(sliders.jump, currentJumpMult, 100, 1, false)
    elseif drag.flySpeed then
        local pos = input.Position.X - sliders.flySpeed.slider.AbsolutePosition.X
        local ratio = math.clamp(pos / sliders.flySpeed.slider.AbsoluteSize.X, 0, 1)
        local logMin = math.log10(0.001)
        local logMax = math.log10(1500)
        flySpeedMult = 10^(logMin + ratio*(logMax-logMin))
        flySpeedMult = math.clamp(flySpeedMult, 0.001, 1500)
        sliders.flySpeed.box.Text = string.format("%.3f", flySpeedMult)
        updateSliderUI(sliders.flySpeed, flySpeedMult, 1500, 0.001, true)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = {speed=false, jump=false, flySpeed=false}
    end
end)

sliders.speed.box.FocusLost:Connect(function()
    currentSpeedMult = clampVal(sliders.speed.box.Text, 0.001, 8e9)
    updateSliderUI(sliders.speed, currentSpeedMult, 8e9, 0.001, true)
    if speedMethod == "WalkSpeed" then humanoid.WalkSpeed = BASE_WALK_SPEED * currentSpeedMult end
end)
sliders.jump.box.FocusLost:Connect(function()
    currentJumpMult = clampVal(sliders.jump.box.Text, 1, 100)
    updateSliderUI(sliders.jump, currentJumpMult, 100, 1, false)
end)
sliders.flySpeed.box.FocusLost:Connect(function()
    flySpeedMult = clampVal(sliders.flySpeed.box.Text, 0.001, 1500)
    updateSliderUI(sliders.flySpeed, flySpeedMult, 1500, 0.001, true)
end)

local function updateTextSizes()
    local scale = math.min(1.5, math.max(0.7, frame.Size.X.Scale / 0.32))
    for _,btn in pairs(buttons) do
        if btn and btn.Parent then btn.TextSize = math.floor(10 * scale) end
    end
    for _,sld in pairs(sliders) do
        if sld.label and sld.label.Parent then sld.label.TextSize = math.floor(11 * scale) end
        if sld.box and sld.box.Parent then sld.box.TextSize = math.floor(11 * scale) end
    end
    if title and title.Parent then title.TextSize = math.floor(16 * scale) end
    if closeButton and closeButton.Parent then closeButton.TextSize = math.floor(14 * scale) end
    if instructionLabel and instructionLabel.Parent then instructionLabel.TextSize = math.floor(12 * scale) end
end
frame:GetPropertyChangedSignal("Size"):Connect(function()
    updateAllSliders()
    updateTextSizes()
end)

local resizing = false
local startSize, startMouse
resizeHandle.MouseButton1Down:Connect(function()
    resizing = true
    startMouse = UIS:GetMouseLocation()
    startSize = frame.Size
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if resizing then
            local delta = UIS:GetMouseLocation() - startMouse
            frame.Size = UDim2.new(
                math.max(0.2, startSize.X.Scale + delta.X / gui.AbsoluteSize.X), 0,
                math.max(0.35, startSize.Y.Scale + delta.Y / gui.AbsoluteSize.Y), 0
            )
        else
            conn:Disconnect()
        end
    end)
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = false
    end
end)

buttons.fullbright.MouseButton1Click:Connect(function()
    _G.FullBrightEnabled = not _G.FullBrightEnabled
    setButtonActive(buttons.fullbright, _G.FullBrightEnabled)
end)
buttons.infJump.MouseButton1Click:Connect(function()
    _G.InfiniteJumpEnabled = not _G.InfiniteJumpEnabled
    setButtonActive(buttons.infJump, _G.InfiniteJumpEnabled)
end)

buttons.speedMethod.MouseButton1Click:Connect(function()
    local methods = {"Off", "BodyVelocity", "WalkSpeed", "CFrame", "Collide", "Legit", "Tween", "Velocity", "Strength"}
    local idx = 1
    for i,m in ipairs(methods) do if m == speedMethod then idx = i break end end
    idx = idx % #methods + 1
    local newMethod = methods[idx]
    
    if newMethod == "Off" then
        if moveStabEnabled then
            moveStabEnabled = false
            setButtonActive(buttons.stabilize, false)
            buttons.stabilize.Text = "Move Stab OFF"
            resetStabilization()
        end
        if yStabEnabled then
            yStabEnabled = false
            setButtonActive(buttons.yStab, false)
            buttons.yStab.Text = "Y-Stab OFF"
            destroyYStabilizer()
        end
        destroyAllSpeedControllers()
    end
    
    speedMethod = newMethod
    
    if newMethod ~= "Off" then
        destroyAllSpeedControllers()
    end
    
    if flyEnabled then
        flyEnabled = false
        disableFlyEXVS()
        setButtonActive(buttons.fly, false)
    end
    
    humanoid.WalkSpeed = BASE_WALK_SPEED
    if hrp then
        hrp.Massless = false
        hrp:SetAttribute("OriginalMass", nil)
    end
    resetStabilization()
    legitCurrentSpeed = 0
    legitLastMoveTime = tick()

    if speedMethod == "BodyVelocity" then
        ensureBodyVelocity()
        buttons.speedMethod.Text = "BodyVelocity"
    elseif speedMethod == "WalkSpeed" then
        buttons.speedMethod.Text = "WalkSpeed"
        humanoid.WalkSpeed = BASE_WALK_SPEED * currentSpeedMult
    elseif speedMethod == "CFrame" then
        buttons.speedMethod.Text = "CFrame"
    elseif speedMethod == "Collide" then
        buttons.speedMethod.Text = "Collide"
        createCollidePlatform()
    elseif speedMethod == "Legit" then
        buttons.speedMethod.Text = "Legit"
        createCollidePlatform()
        legitCurrentSpeed = 0
        legitLastMoveTime = tick()
    elseif speedMethod == "Tween" then
        buttons.speedMethod.Text = "Tween"
    elseif speedMethod == "Velocity" then
        buttons.speedMethod.Text = "Velocity"
    elseif speedMethod == "Strength" then
        buttons.speedMethod.Text = "Strength"
        ensureStrengthVelocity()
    else
        buttons.speedMethod.Text = "Speed OFF"
    end
    setButtonActive(buttons.speedMethod, true)
    if speedMethod ~= "Tween" and activeTween then activeTween:Cancel() activeTween = nil end
end)

buttons.fly.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    setButtonActive(buttons.fly, flyEnabled)
    if flyEnabled then
        destroyAllSpeedControllers()
        humanoid.WalkSpeed = BASE_WALK_SPEED
        if hrp then hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0) end
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.P = 9e4
        flyBodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
        flyBodyGyro.CFrame = hrp.CFrame
        flyBodyGyro.Parent = hrp
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.new(0,0,0)
        flyBodyVelocity.MaxForce = Vector3.new(9e9,9e9,9e9)
        flyBodyVelocity.Parent = hrp
        humanoid.PlatformStand = true
        resetStabilization()
    else
        disableFlyEXVS()
    end
end)

buttons.esp.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    setButtonActive(buttons.esp, espEnabled)
    buttons.esp.Text = espEnabled and "ESP ON" or "ESP OFF"
    if espEnabled then updateESP() else cleanupESP() end
end)

buttons.clickTP.MouseButton1Click:Connect(function()
    clickTPEnabled = not clickTPEnabled
    setButtonActive(buttons.clickTP, clickTPEnabled)
    if clickTPEnabled then
        clickTPConnection = UIS.InputBegan:Connect(function(input, processed)
            if processed or not clickTPEnabled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local target = Mouse.Hit.Position
                if hrp then
                    hrp.CFrame = CFrame.new(target + Vector3.new(0,3,0))
                    allowTempTeleport(0.5)
                    resetStabilization()
                end
            end
        end)
    else
        if clickTPConnection then clickTPConnection:Disconnect() clickTPConnection = nil end
    end
end)

buttons.tweenMove.MouseButton1Click:Connect(function()
    tweenMoveEnabled = not tweenMoveEnabled
    setButtonActive(buttons.tweenMove, tweenMoveEnabled)
    if not tweenMoveEnabled then cleanupMarkers() end
end)

buttons.fling.MouseButton1Click:Connect(function()
    flingEnabled = not flingEnabled
    setButtonActive(buttons.fling, flingEnabled)
    buttons.fling.Text = flingEnabled and "Fling ON" or "Fling OFF"
    if flingEnabled then enableFling() else disableFling() end
end)

buttons.noclip.MouseButton1Click:Connect(function()
    setNoclip(not noclipEnabled)
    setButtonActive(buttons.noclip, noclipEnabled)
    buttons.noclip.Text = noclipEnabled and "Noclip ON" or "Noclip OFF"
end)

buttons.yStab.MouseButton1Click:Connect(function()
    yStabEnabled = not yStabEnabled
    setButtonActive(buttons.yStab, yStabEnabled)
    buttons.yStab.Text = yStabEnabled and "Y-Stab ON" or "Y-Stab OFF"
    if yStabEnabled then createYStabilizer() else destroyYStabilizer() end
end)

buttons.stabilize.MouseButton1Click:Connect(function()
    moveStabEnabled = not moveStabEnabled
    setButtonActive(buttons.stabilize, moveStabEnabled)
    buttons.stabilize.Text = moveStabEnabled and "Move Stab ON" or "Move Stab OFF"
    resetStabilization()
end)

buttons.aimbot.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    setButtonActive(buttons.aimbot, aimbotEnabled)
    buttons.aimbot.Text = aimbotEnabled and "AimBot ON" or "AimBot OFF"
    setupAimbot()
end)

buttons.puncher.MouseButton1Click:Connect(function()
    puncherEnabled = not puncherEnabled
    setButtonActive(buttons.puncher, puncherEnabled)
    buttons.puncher.Text = puncherEnabled and "Puncher ON" or "Puncher OFF"
    enablePuncher()
end)

buttons.grabber.MouseButton1Click:Connect(function()
    grabberTool = createGrabberTool()
    Notify("Grabber tool added to backpack!", "Grabber", 2)
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed or not flyEnabled then return end
    if input.KeyCode == Enum.KeyCode.W then flyControls.f = 1
    elseif input.KeyCode == Enum.KeyCode.S then flyControls.b = -1
    elseif input.KeyCode == Enum.KeyCode.A then flyControls.l = -1
    elseif input.KeyCode == Enum.KeyCode.D then flyControls.r = 1 end
end)
UIS.InputEnded:Connect(function(input)
    if not flyEnabled then return end
    if input.KeyCode == Enum.KeyCode.W then flyControls.f = 0
    elseif input.KeyCode == Enum.KeyCode.S then flyControls.b = 0
    elseif input.KeyCode == Enum.KeyCode.A then flyControls.l = 0
    elseif input.KeyCode == Enum.KeyCode.D then flyControls.r = 0 end
end)

lastUpdateTime = tick()
lastUpdateStabTime = tick()
resetStabilization()

RunService.Heartbeat:Connect(function()
    applySpeed()
    applyJumpBoost()
    if espEnabled then updateESP() end
    if moveStabEnabled then updateStabilization() end
end)

Players.PlayerAdded:Connect(function() if espEnabled then updateESP() end end)
Players.PlayerRemoving:Connect(function(p)
    if espHighlights[p] then espHighlights[p]:Destroy() espHighlights[p]=nil end
    if espBeams[p] then
        espBeams[p].Beam:Destroy()
        espBeams[p].Att0:Destroy()
        espBeams[p].Att1:Destroy()
        espBeams[p]=nil
    end
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    hrp = newChar:WaitForChild("HumanoidRootPart")
    head = newChar:FindFirstChild("Head") or newChar:WaitForChild("Head")
    BASE_WALK_SPEED = humanoid.WalkSpeed
    destroyAllSpeedControllers()
    disableFlyEXVS()
    flyEnabled = false
    setButtonActive(buttons.fly, false)
    if noclipEnabled then setNoclip(true) end
    if yStabEnabled then
        destroyYStabilizer()
        createYStabilizer()
    end
    if speedMethod == "Collide" or speedMethod == "Legit" then
        createCollidePlatform()
        if speedMethod == "Legit" then legitCurrentSpeed = 0 end
    elseif speedMethod == "BodyVelocity" then ensureBodyVelocity()
    elseif speedMethod == "Strength" then ensureStrengthVelocity()
    end
    if speedMethod == "WalkSpeed" then humanoid.WalkSpeed = BASE_WALK_SPEED * currentSpeedMult
    else humanoid.WalkSpeed = BASE_WALK_SPEED end
    if clickTPConnection then clickTPConnection:Disconnect() clickTPConnection = nil end
    if activeTween then activeTween:Cancel() activeTween = nil end
    cleanupMarkers()
    cleanupESP()
    updateAllSliders()
    setButtonActive(buttons.speedMethod, true)
    setButtonActive(buttons.clickTP, false)
    setButtonActive(buttons.tweenMove, false)
    setButtonActive(buttons.fly, false)
    setButtonActive(buttons.fullbright, false)
    setButtonActive(buttons.infJump, false)
    setButtonActive(buttons.fling, false)
    setButtonActive(buttons.noclip, noclipEnabled)
    setButtonActive(buttons.yStab, yStabEnabled)
    setButtonActive(buttons.stabilize, moveStabEnabled)
    setButtonActive(buttons.aimbot, aimbotEnabled)
    setButtonActive(buttons.puncher, puncherEnabled)
    buttons.fling.Text = "Fling OFF"
    buttons.noclip.Text = noclipEnabled and "Noclip ON" or "Noclip OFF"
    buttons.yStab.Text = yStabEnabled and "Y-Stab ON" or "Y-Stab OFF"
    buttons.stabilize.Text = moveStabEnabled and "Move Stab ON" or "Move Stab OFF"
    buttons.aimbot.Text = aimbotEnabled and "AimBot ON" or "AimBot OFF"
    buttons.puncher.Text = puncherEnabled and "Puncher ON" or "Puncher OFF"
    if espEnabled then updateESP() end
    lastUpdateTime = tick()
    lastUpdateStabTime = tick()
    resetStabilization()
    setupAimbot()
    if puncherEnabled then enablePuncher() end
end)

closeButton.MouseButton1Click:Connect(function()
    _G.FullBrightEnabled = false
    _G.InfiniteJumpEnabled = false
    destroyAllSpeedControllers()
    destroyYStabilizer()
    humanoid.WalkSpeed = BASE_WALK_SPEED
    if activeTween then activeTween:Cancel() end
    disableFlyEXVS()
    if clickTPConnection then clickTPConnection:Disconnect() end
    cleanupMarkers()
    cleanupESP()
    if flingEnabled then disableFling() end
    setNoclip(false)
    if aimbotConnection then aimbotConnection:Disconnect() end
    if puncherEnabled then
        puncherEnabled = false
        enablePuncher()
    end
    if fusedPanel then fusedPanel:Destroy() end
    gui:Destroy()
end)

updateAllSliders()
updateTextSizes()

UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

local function loadFusedFunctions()
    local FunctionManager = {
        CategorizedFunctions = { All = {} },
        Categories          = { "All" },
        CurrentCategoryIndex= 1,
        Descriptions        = {},
        OnFunctionAdded     = Instance.new("BindableEvent"),
    }

    function FunctionManager:register(name, callback, category, description)
        category = category or "General"
        if not self.CategorizedFunctions[category] then
            self.CategorizedFunctions[category] = {}
            table.insert(self.Categories, category)
        end
        self.CategorizedFunctions[category][name] = callback
        self.CategorizedFunctions.All[name]        = callback
        self.Descriptions[name]                    = description or ""
        self.OnFunctionAdded:Fire(category, name, callback)
        self.OnFunctionAdded:Fire("All",      name, callback)
    end

    function FunctionManager:getCurrentCategory()
        return self.Categories[self.CurrentCategoryIndex]
    end

    function FunctionManager:cycleCategory()
        self.CurrentCategoryIndex = self.CurrentCategoryIndex % #self.Categories + 1
        return self:getCurrentCategory()
    end

    function FunctionManager:getFunctionsInCategory(cat)
        return self.CategorizedFunctions[cat] or {}
    end

    local fusedLoader = loadstring(game:HttpGet("https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/fused.lua"))()
    local deps = {
        FunctionManager = FunctionManager,
        player = player,
        character = character,
        humanoid = humanoid,
        hrp = hrp,
        head = head,
        Mouse = Mouse,
        UIS = UIS,
        RunService = RunService,
        TweenService = TweenService,
        HttpService = HttpService,
        TeleportService = TeleportService,
        ReplicatedStorage = ReplicatedStorage,
        SoundService = SoundService,
        Lighting = Lighting,
        Players = Players,
        CollectionService = CollectionService,
        Debris = Debris,
        PlaceId = PlaceId,
        JobId = JobId,
        Notify = Notify,
        NotifyERROR = NotifyERROR,
        gui = gui,
        BASE_WALK_SPEED = BASE_WALK_SPEED,
        BASE_JUMP = BASE_JUMP,
    }
    fusedLoader(deps)
    return FunctionManager
end

local FusedManager = loadFusedFunctions()

local fusedPanel = nil
buttons.fused.MouseButton1Click:Connect(function()
    if fusedPanel and fusedPanel.Parent then
        fusedPanel:Destroy()
        fusedPanel = nil
        return
    end

    fusedPanel = Instance.new("Frame")
    fusedPanel.Name = "FusedPanel"
    fusedPanel.Size = UDim2.new(0, 500, 0, 400)
    fusedPanel.Position = UDim2.new(0.05, 0, 0.4, 0)
    fusedPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    fusedPanel.BackgroundTransparency = 0.35
    fusedPanel.BorderSizePixel = 0
    fusedPanel.Active = true
    fusedPanel.Draggable = true
    fusedPanel.ZIndex = 100
    fusedPanel.Parent = gui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0.03, 0)
    panelCorner.Parent = fusedPanel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromRGB(0, 200, 0)
    panelStroke.Thickness = 1.5
    panelStroke.Transparency = 0.4
    panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    panelStroke.Parent = fusedPanel

    local titleBarFused = Instance.new("Frame")
    titleBarFused.Size = UDim2.new(1,0,0,30)
    titleBarFused.BackgroundColor3 = Color3.fromRGB(0, 60, 0)
    titleBarFused.BorderSizePixel = 0
    titleBarFused.Parent = fusedPanel
    local titleBarCorner = Instance.new("UICorner")
    titleBarCorner.CornerRadius = UDim.new(0.03, 0)
    titleBarCorner.Parent = titleBarFused

    local titleFused = Instance.new("TextLabel")
    titleFused.Size = UDim2.new(1, -60, 1, 0)
    titleFused.Position = UDim2.new(0, 4, 0, 0)
    titleFused.BackgroundTransparency = 1
    titleFused.Text = "Fused Menu"
    titleFused.Font = Enum.Font.GothamBold
    titleFused.TextSize = 18
    titleFused.TextColor3 = Color3.new(1,1,1)
    titleFused.TextXAlignment = Enum.TextXAlignment.Left
    titleFused.Parent = titleBarFused

    local closeFused = Instance.new("TextButton")
    closeFused.Size = UDim2.new(0, 30, 1, 0)
    closeFused.Position = UDim2.new(1, -30, 0, 0)
    closeFused.Text = "X"
    closeFused.Font = Enum.Font.GothamBold
    closeFused.TextSize = 16
    closeFused.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeFused.BackgroundTransparency = 0.2
    closeFused.TextColor3 = Color3.new(1,1,1)
    closeFused.AutoButtonColor = false
    closeFused.Parent = titleBarFused
    closeFused.MouseButton1Click:Connect(function()
        fusedPanel:Destroy()
        fusedPanel = nil
    end)

    local catNavFused = Instance.new("Frame")
    catNavFused.Size = UDim2.new(1,0,0,30)
    catNavFused.Position = UDim2.new(0,0,0,30)
    catNavFused.BackgroundTransparency = 1
    catNavFused.Parent = fusedPanel

    local leftCatF = Instance.new("TextButton")
    leftCatF.Size = UDim2.new(0,50,1,0)
    leftCatF.Text = "<"
    leftCatF.Font = Enum.Font.GothamBold
    leftCatF.TextSize = 24
    leftCatF.TextColor3 = Color3.new(1,1,1)
    leftCatF.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    leftCatF.BackgroundTransparency = 0.2
    leftCatF.BorderSizePixel = 0
    leftCatF.Parent = catNavFused
    local leftCatCorner = Instance.new("UICorner")
    leftCatCorner.CornerRadius = UDim.new(0.2, 0)
    leftCatCorner.Parent = leftCatF

    local catLabelF = Instance.new("TextLabel")
    catLabelF.Size = UDim2.new(1, -100, 1, 0)
    catLabelF.Position = UDim2.new(0, 50, 0, 0)
    catLabelF.BackgroundTransparency = 1
    catLabelF.Text = "All"
    catLabelF.Font = Enum.Font.GothamBold
    catLabelF.TextSize = 18
    catLabelF.TextColor3 = Color3.new(1,1,1)
    catLabelF.Parent = catNavFused

    local rightCatF = leftCatF:Clone()
    rightCatF.Parent = catNavFused
    rightCatF.Position = UDim2.new(1, -50, 0, 0)
    rightCatF.Text = ">"

    local gridFused = Instance.new("ScrollingFrame")
    gridFused.Size = UDim2.new(1, -8, 1, -76)
    gridFused.Position = UDim2.new(0, 4, 0, 68)
    gridFused.BackgroundTransparency = 1
    gridFused.CanvasSize = UDim2.new(0,0,0,0)
    gridFused.ScrollBarThickness = 6
    gridFused.Parent = fusedPanel

    local gridLayoutF = Instance.new("UIGridLayout")
    gridLayoutF.CellSize = UDim2.new(0, (500 - 16 - (4-1)*4)/4, 0, 40)
    gridLayoutF.CellPadding = UDim2.new(0, 4, 0, 4)
    gridLayoutF.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayoutF.Parent = gridFused

    local function updateGridFused()
        for _, child in ipairs(gridFused:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local cat = FusedManager:getCurrentCategory()
        catLabelF.Text = cat
        for name, cb in pairs(FusedManager:getFunctionsInCategory(cat)) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1,0,1,0)
            btn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
            btn.BackgroundTransparency = 0.2
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Text = name
            btn.TextWrapped = true
            btn.Parent = gridFused
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0.2, 0)
            btnCorner.Parent = btn
            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
            end)
            btn.MouseButton1Click:Connect(function()
                pcall(cb)
            end)
        end
        gridFused.CanvasSize = UDim2.new(0,0,0, gridLayoutF.AbsoluteContentSize.Y)
    end

    leftCatF.MouseButton1Click:Connect(function()
        FusedManager.CurrentCategoryIndex = (FusedManager.CurrentCategoryIndex - 2) % #FusedManager.Categories + 1
        updateGridFused()
    end)
    rightCatF.MouseButton1Click:Connect(function()
        FusedManager:cycleCategory()
        updateGridFused()
    end)
    updateGridFused()
end)

Notify("EXVS Multi Tool Active!", "System", 3)
