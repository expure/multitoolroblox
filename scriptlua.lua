-- ==============================================
-- EXVS ► Multi Tool
-- ==============================================

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
local ContextActionService = game:GetService("ContextActionService")
local PhysicsService = game:GetService("PhysicsService")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

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
instructionLabel.Text = "Recommended speed-up method: Legit. Use Strength mode to push/pull heavy objects. If Grabber or Puncher don't respond, nudge, jump, or touch the target until they activate. Y‑Stab counteracts unintended upward impulses (e.g., from high speed), keeping you grounded while running. Move‑Stab prevents rubberbanding or movement without your input. AimBot: hold RMB to snap camera to the nearest player. The Fused tab contains various scripts – some may be broken or low quality, use with caution."
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
        hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
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
        destroyAllSpeedControllers()
        humanoid.WalkSpeed = BASE_WALK_SPEED
        hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
    elseif speedMethod == "BodyVelocity" then
        ensureBodyVelocity()
        if bodyVelocity then bodyVelocity.Velocity = dir * targetSpeed end
        humanoid.WalkSpeed = BASE_WALK_SPEED
        hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
    elseif speedMethod == "WalkSpeed" then
        destroyAllSpeedControllers()
        humanoid.WalkSpeed = targetSpeed
        hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
    elseif speedMethod == "CFrame" then
        destroyAllSpeedControllers()
        humanoid.WalkSpeed = BASE_WALK_SPEED
        if dir.Magnitude > 0 then
            local y = hrp.Position.Y
            hrp.CFrame = hrp.CFrame + (dir * targetSpeed * dt)
            hrp.CFrame = CFrame.new(hrp.Position.X, y, hrp.Position.Z)
        else
            hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
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
        hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
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
    speedMethod = methods[idx]
    destroyAllSpeedControllers()
    if flyEnabled then
        flyEnabled = false
        disableFlyEXVS()
        setButtonActive(buttons.fly, false)
    end
    humanoid.WalkSpeed = BASE_WALK_SPEED
    if hrp then
        hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
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

FunctionManager:register("Decal Spam", function()
    local decalID = 8408806737
    local function exPro(root)
        for _, v in pairs(root:GetChildren()) do
            if v:IsA("Decal") and v.Texture ~= "http://www.roblox.com/asset/?id="..decalID then
                v.Parent = nil
            elseif v:IsA("BasePart") then
                v.Material = "Plastic"
                v.Transparency = 0
                local One = Instance.new("Decal", v)
                local Two = Instance.new("Decal", v)
                local Three = Instance.new("Decal", v)
                local Four = Instance.new("Decal", v)
                local Five = Instance.new("Decal", v)
                local Six = Instance.new("Decal", v)
                One.Texture = "http://www.roblox.com/asset/?id="..decalID
                Two.Texture = "http://www.roblox.com/asset/?id="..decalID
                Three.Texture = "http://www.roblox.com/asset/?id="..decalID
                Four.Texture = "http://www.roblox.com/asset/?id="..decalID
                Five.Texture = "http://www.roblox.com/asset/?id="..decalID
                Six.Texture = "http://www.roblox.com/asset/?id="..decalID
                One.Face = "Front"
                Two.Face = "Back"
                Three.Face = "Right"
                Four.Face = "Left"
                Five.Face = "Top"
                Six.Face = "Bottom"
            end
            exPro(v)
        end
    end
    local function asdf(root)
        for _, v in pairs(root:GetChildren()) do
            asdf(v)
        end
    end
    exPro(game.Workspace)
    asdf(game.Workspace)

    local s = Instance.new("Sky")
    s.Name = "Sky"
    s.Parent = game.Lighting
    local skyboxID = 8408806737
    s.SkyboxBk = "http://www.roblox.com/asset/?id="..skyboxID
    s.SkyboxDn = "http://www.roblox.com/asset/?id="..skyboxID
    s.SkyboxFt = "http://www.roblox.com/asset/?id="..skyboxID
    s.SkyboxLf = "http://www.roblox.com/asset/?id="..skyboxID
    s.SkyboxRt = "http://www.roblox.com/asset/?id="..skyboxID
    s.SkyboxUp = "http://www.roblox.com/asset/?id="..skyboxID
    game.Lighting.TimeOfDay = 12

    for i, v in pairs(game.Players:GetChildren()) do
        local emit = Instance.new("ParticleEmitter")
        if v.Character and v.Character:FindFirstChild("Torso") then
            emit.Parent = v.Character.Torso
            emit.Texture = "http://www.roblox.com/asset/?id=8408806737"
            emit.VelocitySpread = 20
        end
    end
    coroutine.wrap(function()
        while true do
            game.Lighting.Ambient = Color3.new(math.random(), math.random(), math.random())
            task.wait(0.2)
            game.Lighting.ShadowColor = Color3.new(math.random(), math.random(), math.random())
            task.wait(0.2)
        end
    end)()
end, "Troll", "NOT FE")

FunctionManager:register("JOHN DOE", function()
    local redSkyboxAssetId = "rbxassetid://1012887"
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky", Lighting)
    end
    sky.SkyboxBk = redSkyboxAssetId
    sky.SkyboxDn = redSkyboxAssetId
    sky.SkyboxFt = redSkyboxAssetId
    sky.SkyboxLf = redSkyboxAssetId
    sky.SkyboxRt = redSkyboxAssetId
    sky.SkyboxUp = redSkyboxAssetId

    if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
        local detection = Instance.new("Decal")
        detection.Name = "juisdfj0i32i0eidsuf0iok"
        detection.Parent = ReplicatedStorage
    end

    local soundGui = Instance.new("ScreenGui")
    soundGui.Name = "PersistentSoundGui"
    soundGui.ResetOnSpawn = false
    soundGui.Parent = player:WaitForChild("PlayerGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 150, 0, 50)
    button.Position = UDim2.new(0.02, 0, 0.477, 0)
    button.Text = "Sound Toggle"
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 20
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = soundGui

    local backgroundSound = SoundService:FindFirstChild("PersistentBGSound")
    if not backgroundSound then
        backgroundSound = Instance.new("Sound")
        backgroundSound.Name = "PersistentBGSound"
        backgroundSound.SoundId = "rbxassetid://19094700"
        backgroundSound.PlaybackSpeed = 0.221
        backgroundSound.Looped = true
        backgroundSound.Volume = 1
        backgroundSound.Parent = SoundService
        backgroundSound:Play()
    end

    button.Activated:Connect(function()
        backgroundSound.Playing = not backgroundSound.Playing
    end)

    local function setupCharacter(char)
        local hum = char:WaitForChild("Humanoid")
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        local hrpPart = char:WaitForChild("HumanoidRootPart")

        local tool = Instance.new("Tool")
        tool.Name = "Slash"
        tool.RequiresHandle = false
        tool.Parent = player.Backpack

        tool.Activated:Connect(function()
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://186934658"
            local track = hum:LoadAnimation(anim)
            track:Play()
            track:AdjustSpeed(2)

            local s = Instance.new("Sound", torso)
            s.SoundId = "rbxassetid://28144425"
            s:Play()

            task.wait(0.2)

            local s2 = Instance.new("Sound", torso)
            s2.SoundId = "rbxassetid://429400881"
            s2.Volume = 0.2
            s2:Play()
        end)

        local naeeym = Instance.new("BillboardGui", char)
        naeeym.Size = UDim2.new(0, 100, 0, 40)
        naeeym.StudsOffset = Vector3.new(0, 2, 0)
        naeeym.Adornee = char:WaitForChild("Head")

        local tecks = Instance.new("TextLabel", naeeym)
        tecks.BackgroundTransparency = 1
        tecks.BorderSizePixel = 0
        tecks.Font = Enum.Font.Fantasy
        tecks.TextSize = 24
        tecks.TextStrokeTransparency = 0
        tecks.TextStrokeColor3 = Color3.new(0, 0, 0)
        tecks.TextColor3 = Color3.new(0, 0, 0)
        tecks.Size = UDim2.new(1, 0, 0.5, 0)
        tecks.Text = "John Doe"

        local function changeName(newName)
            tecks.Text = newName
        end

        local function shakeTag()
            local originalOffset = naeeym.StudsOffset
            for _ = 1, 10 do
                naeeym.StudsOffset = originalOffset + Vector3.new(math.random(-1,1), math.random(-1,1), math.random(-1,1))
                task.wait(0.05)
            end
            naeeym.StudsOffset = originalOffset
        end

        coroutine.wrap(function()
            while char:IsDescendantOf(workspace) do
                changeName("BURN IN HELL")
                shakeTag()
                task.wait(0.2)
                changeName("STOP")
                task.wait(0.1)
                changeName("JUST GIVE UP")
                shakeTag()
                task.wait(0.2)
                changeName("STOP")
                shakeTag()
                task.wait(0.2)
                changeName("JOHN DOE")
                shakeTag()
                task.wait(0.3)
                changeName("HOPELESS")
                shakeTag()
                task.wait(0.3)
            end
        end)()

        local footPartSize = Vector3.new(10, 0.5, 10)
        local floorPartColor = BrickColor.Black()
        local floorMaterial = Enum.Material.Neon
        local yOffset = -2.8
        local lastPosition = hrpPart.Position
        local standingTimer = 0

        RunService.Heartbeat:Connect(function(dt)
            if not char:IsDescendantOf(workspace) then return end
            local currentPosition = hrpPart.Position
            standingTimer = standingTimer + dt
            local distanceMoved = (currentPosition - lastPosition).Magnitude
            local stepPosition = Vector3.new(currentPosition.X, hrpPart.Position.Y + yOffset, currentPosition.Z)

            local function createFootstep(position)
                local part = Instance.new("Part")
                part.Size = footPartSize
                part.Position = position
                part.Anchored = true
                part.CanCollide = false
                part.BrickColor = floorPartColor
                part.Material = floorMaterial
                part.Transparency = 0.5
                part.Parent = workspace
                task.spawn(function()
                    for i = 1, 10 do
                        part.Transparency = i * 0.03
                        task.wait(0.05)
                    end
                end)
                Debris:AddItem(part, 1)
            end

            if distanceMoved > 1 then
                createFootstep(stepPosition)
                lastPosition = currentPosition
                standingTimer = 0
            elseif standingTimer > 0.5 then
                createFootstep(stepPosition)
                standingTimer = 0
            end
        end)

        local movel = 0.1
        local hiddenfling = true

        local function fling()
            while hiddenfling and char:IsDescendantOf(workspace) do
                if hrpPart then
                    local originalVelocity = hrpPart.Velocity
                    hrpPart.Velocity = originalVelocity * 10000 + Vector3.new(0, 10000, 0)
                    RunService.RenderStepped:Wait()
                    hrpPart.Velocity = originalVelocity
                    RunService.Stepped:Wait()
                    hrpPart.Velocity = originalVelocity + Vector3.new(0, movel, 0)
                    movel = -movel
                end
                RunService.Heartbeat:Wait()
            end
        end
        coroutine.wrap(fling)()
    end

    player.CharacterAdded:Connect(setupCharacter)
    if player.Character then
        setupCharacter(player.Character)
    end

    local function teleportToMousePosition()
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local target = Mouse.Hit
        if target then
            char:MoveTo(target.Position)
        end
    end

    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.T then
            teleportToMousePosition()
        end
    end)
end, "Trolling", "BROKEN")

FunctionManager:register("Invis gui", function()
    loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))()
end, "Trolling", "Credits to the original maker!")

FunctionManager:register("DANCE", function()
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://27789359"
    local track = humanoid:LoadAnimation(anim)
    track:Play()
end, "Fun", "DANCE DANCE")

FunctionManager:register("Sound GUI", function()
    local sgui = player.PlayerGui:FindFirstChild("SoundGui")
    if sgui then sgui:Destroy() return end
    local SoundGui = Instance.new("ScreenGui")
    local Frame = Instance.new("Frame")
    local AddSoundId = Instance.new("TextButton")
    local SoundIds = Instance.new("TextBox")
    local Default = Instance.new("TextButton")
    local Credits = Instance.new("TextLabel")
    local Title = Instance.new("TextLabel")
    local Swap = Instance.new("ImageButton")
    local PlayBackSpeed = Instance.new("TextBox")
    local Volume = Instance.new("TextBox")
    local Looped = Instance.new("TextBox")
    local Exit = Instance.new("ImageButton")
    local Frame2 = Instance.new("Frame")
    local Open = Instance.new("ImageButton")
    local spoky = Instance.new("Sound")
    local c00lflag = Instance.new("Sound")
    local drag = Instance.new("UIDragDetector")
    drag.Parent = Frame
    c00lflag.Name = "c00lsound23sas"
    c00lflag.Parent = Frame
    spoky.Parent = Frame
    spoky.SoundId = "rbxassetid://95156028272944"
    spoky.Volume = 3
    spoky.PlaybackSpeed = 0.2
    spoky.Name = "spoky"

    SoundGui.Name = "SoundGui"
    SoundGui.Parent = player:WaitForChild("PlayerGui")
    SoundGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SoundGui.ResetOnSpawn = false

    Frame.Parent = SoundGui
    Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Frame.BorderColor3 = Color3.fromRGB(255, 0, 4)
    Frame.BorderSizePixel = 2
    Frame.Position = UDim2.new(0, 700, 0, 300)
    Frame.Size = UDim2.new(0, 398, 0, 206)

    AddSoundId.Name = "AddSoundId"
    AddSoundId.Parent = Frame
    AddSoundId.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    AddSoundId.BorderColor3 = Color3.fromRGB(255, 0, 0)
    AddSoundId.BorderSizePixel = 2
    AddSoundId.Position = UDim2.new(0.118090451, 0, 0.718446612, 0)
    AddSoundId.Size = UDim2.new(0, 307, 0, 36)
    AddSoundId.Font = Enum.Font.Arial
    AddSoundId.Text = "Add Sound!"
    AddSoundId.TextColor3 = Color3.fromRGB(255, 255, 255)
    AddSoundId.TextSize = 29

    SoundIds.Name = "SoundIds"
    SoundIds.Parent = Frame
    SoundIds.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    SoundIds.BorderColor3 = Color3.fromRGB(255, 0, 0)
    SoundIds.BorderSizePixel = 2
    SoundIds.Position = UDim2.new(0.118090451, 0, 0.305825233, 0)
    SoundIds.Size = UDim2.new(0, 307, 0, 33)
    SoundIds.Font = Enum.Font.Arial
    SoundIds.PlaceholderText = "Add a sound ID here!, No rbx://"
    SoundIds.Text = ""
    SoundIds.TextColor3 = Color3.fromRGB(255, 255, 255)
    SoundIds.TextScaled = true
    SoundIds.TextSize = 14
    SoundIds.TextWrapped = true

    Default.Name = "Default"
    Default.Parent = Frame
    Default.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Default.BorderColor3 = Color3.fromRGB(255, 0, 0)
    Default.BorderSizePixel = 2
    Default.Position = UDim2.new(0.118090451, 0, 0.529126227, 0)
    Default.Size = UDim2.new(0, 307, 0, 28)
    Default.Font = Enum.Font.Arial
    Default.Text = "Spooky Scary Skeletons!"
    Default.TextColor3 = Color3.fromRGB(255, 255, 255)
    Default.TextSize = 23

    Credits.Name = "Credits"
    Credits.Parent = Frame
    Credits.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Credits.BackgroundTransparency = 1
    Credits.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Credits.BorderSizePixel = 0
    Credits.Position = UDim2.new(0.577889442, 0, 0.9174757, 0)
    Credits.Size = UDim2.new(0, 153, 0, 17)
    Credits.Font = Enum.Font.SourceSans
    Credits.Text = "made by: 1known. On discord!"
    Credits.TextColor3 = Color3.fromRGB(255, 255, 255)
    Credits.TextSize = 14

    Title.Name = "Title"
    Title.Parent = Frame
    Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Title.BackgroundTransparency = 1
    Title.BorderColor3 = Color3.fromRGB(255, 0, 4)
    Title.BorderSizePixel = 2
    Title.Position = UDim2.new(0.208542719, 0, 0.0291262139, 0)
    Title.Size = UDim2.new(0, 231, 0, 48)
    Title.Font = Enum.Font.Arial
    Title.Text = "c00lSound GUI!"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 33
    Title.TextWrapped = true

    Swap.Name = "Swap"
    Swap.Parent = Frame
    Swap.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Swap.BorderColor3 = Color3.fromRGB(255, 0, 0)
    Swap.BorderSizePixel = 0
    Swap.Position = UDim2.new(0.904522598, 0, 0.33495146, 0)
    Swap.Size = UDim2.new(0, 23, 0, 21)
    Swap.Image = "rbxassetid://2500573769"

    PlayBackSpeed.Name = "PlayBackSpeed"
    PlayBackSpeed.Parent = Frame
    PlayBackSpeed.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    PlayBackSpeed.BorderColor3 = Color3.fromRGB(255, 0, 0)
    PlayBackSpeed.BorderSizePixel = 2
    PlayBackSpeed.Position = UDim2.new(0.118090451, 0, 0.305825233, 0)
    PlayBackSpeed.Size = UDim2.new(0, 307, 0, 33)
    PlayBackSpeed.Visible = false
    PlayBackSpeed.Font = Enum.Font.Arial
    PlayBackSpeed.PlaceholderText = "Playback speed, Enter a number!"
    PlayBackSpeed.Text = "1"
    PlayBackSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayBackSpeed.TextScaled = true
    PlayBackSpeed.TextSize = 14
    PlayBackSpeed.TextWrapped = true

    Volume.Name = "Volume"
    Volume.Parent = Frame
    Volume.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Volume.BorderColor3 = Color3.fromRGB(255, 0, 0)
    Volume.BorderSizePixel = 2
    Volume.Position = UDim2.new(0.118090451, 0, 0.305825233, 0)
    Volume.Size = UDim2.new(0, 307, 0, 33)
    Volume.Visible = false
    Volume.Font = Enum.Font.Arial
    Volume.PlaceholderText = "Volume! Enter a number."
    Volume.Text = "0.5"
    Volume.TextColor3 = Color3.fromRGB(255, 255, 255)
    Volume.TextScaled = true
    Volume.TextSize = 14
    Volume.TextWrapped = true

    Looped.Name = "Looped"
    Looped.Parent = Frame
    Looped.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Looped.BorderColor3 = Color3.fromRGB(255, 0, 0)
    Looped.BorderSizePixel = 2
    Looped.Position = UDim2.new(0.118090451, 0, 0.305825233, 0)
    Looped.Size = UDim2.new(0, 307, 0, 33)
    Looped.Visible = false
    Looped.Font = Enum.Font.Arial
    Looped.PlaceholderText = "Is it looped?, Type: False or True"
    Looped.Text = "False"
    Looped.TextColor3 = Color3.fromRGB(255, 255, 255)
    Looped.TextScaled = true
    Looped.TextSize = 14
    Looped.TextWrapped = true

    Exit.Name = "Exit"
    Exit.Parent = Frame
    Exit.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Exit.BorderColor3 = Color3.fromRGB(255, 0, 0)
    Exit.BorderSizePixel = 2
    Exit.Position = UDim2.new(0.921999991, 0, 0.0289999992, 0)
    Exit.Size = UDim2.new(0, 25, 0, 23)
    Exit.Image = "rbxassetid://14930908086"

    Frame2.Name = "Frame2"
    Frame2.Parent = SoundGui
    Frame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Frame2.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Frame2.BorderSizePixel = 0
    Frame2.Position = UDim2.new(0.984443069, 0, 0.841666639, 0)
    Frame2.Size = UDim2.new(0, 25, 0, 23)
    Frame2.Visible = false

    Open.Name = "Open"
    Open.Parent = Frame2
    Open.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Open.BorderColor3 = Color3.fromRGB(255, 0, 0)
    Open.BorderSizePixel = 2
    Open.Position = UDim2.new(-0.0312646478, 0, -0.0113339629, 0)
    Open.Size = UDim2.new(0, 25, 0, 23)
    Open.Image = "rbxassetid://14930908086"

    AddSoundId.Activated:Connect(function()
        local SoundId = SoundIds.Text
        local Playbackspeed = PlayBackSpeed.Text
        local VolumeVal = Volume.Text
        local loopedVal = Looped.Text
        if SoundId == "" then
            AddSoundId.Text = "No Sound ID!"
            task.wait(2)
            AddSoundId.Text = "Add Sound!"
            return
        end
        local id = "rbxassetid://" .. SoundId
        local speed = tonumber(Playbackspeed) or 1
        local existingSound = workspace:FindFirstChild("c00lsound23sas")
        if existingSound then
            existingSound.SoundId = id
            existingSound.PlaybackSpeed = speed
            existingSound.Volume = VolumeVal
            existingSound.Looped = (loopedVal == "True")
            existingSound:Play()
        else
            local clonedSound = spoky:Clone()
            clonedSound.Parent = workspace
            clonedSound.SoundId = id
            clonedSound.PlaybackSpeed = speed
            clonedSound.Volume = VolumeVal
            clonedSound.Looped = (loopedVal == "True")
            clonedSound:Play()
        end
        AddSoundId.Text = "Injected Sound Successfully!"
        AddSoundId.TextScaled = true
        task.wait(3.5)
        AddSoundId.TextScaled = false
        AddSoundId.Text = "Add Sound!"
    end)

    Default.Activated:Connect(function()
        if spoky.Playing then spoky:Stop() else spoky:Play() end
    end)

    Swap.Activated:Connect(function()
        if SoundIds.Visible then
            SoundIds.Visible = false
            PlayBackSpeed.Visible = true
            Volume.Visible = false
            Looped.Visible = false
        elseif PlayBackSpeed.Visible then
            PlayBackSpeed.Visible = false
            SoundIds.Visible = false
            Volume.Visible = true
            Looped.Visible = false
        elseif Volume.Visible then
            SoundIds.Visible = false
            PlayBackSpeed.Visible = false
            Volume.Visible = false
            Looped.Visible = true
        elseif Looped.Visible then
            SoundIds.Visible = true
            PlayBackSpeed.Visible = false
            Volume.Visible = false
            Looped.Visible = false
        end
    end)

    Exit.Activated:Connect(function()
        Frame2.Visible = true
        Frame.Visible = false
    end)

    Open.Activated:Connect(function()
        Frame.Visible = true
        Frame2.Visible = false
    end)
end, "General", "NOT FE")

local bindFrame = nil
local bindConn = nil
local waitingBindFunction = nil
local customBinds = {}

FunctionManager:register("Bind Key", function()
    if bindFrame then return end
    local screenGui = gui
    bindFrame = Instance.new("Frame")
    bindFrame.Name = generate_string(10)
    bindFrame.Size = UDim2.new(1,0,1,0)
    bindFrame.BackgroundColor3 = Color3.new(0,0,0)
    bindFrame.BackgroundTransparency = 0.5
    bindFrame.ZIndex = 50
    bindFrame.Parent = screenGui

    local panel = Instance.new("Frame")
    panel.Name = generate_string(10)
    panel.Size = UDim2.new(0, 300, 0, 400)
    panel.Position = UDim2.new(0.5, -150, 0.5, -200)
    panel.BackgroundColor3 = Color3.fromRGB(35,35,35)
    panel.BorderSizePixel = 0
    panel.ZIndex = 51
    panel.Parent = bindFrame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 60, 0, 24)
    closeBtn.Position = UDim2.new(1, -64, 0, 4)
    closeBtn.Text = "Close"
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 14
    closeBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.ZIndex = 52
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        bindFrame:Destroy()
        bindFrame = nil
        if bindConn then bindConn:Disconnect(); bindConn = nil end
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -8, 0, 24)
    title.Position = UDim2.new(0, 4, 0, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextColor3 = Color3.new(1,1,1)
    title.Text = "Bind Key to Function"
    title.ZIndex = 52
    title.Parent = panel

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, -8, 1, -40)
    list.Position = UDim2.new(0, 4, 0, 32)
    list.CanvasSize = UDim2.new(0,0,0,0)
    list.ScrollBarThickness = 6
    list.ZIndex = 51
    list.Parent = panel

    local uiList = Instance.new("UIListLayout")
    uiList.Padding = UDim.new(0,4)
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Parent = list

    local function refreshList()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        for _, cat in ipairs(FunctionManager.Categories) do
            local hdr = Instance.new("TextLabel")
            hdr.Size = UDim2.new(1,0,0,24)
            hdr.BackgroundTransparency = 1
            hdr.Font = Enum.Font.SourceSansBold
            hdr.TextSize = 16
            hdr.TextColor3 = Color3.new(1,1,0)
            hdr.Text = "["..cat.."]"
            hdr.ZIndex = 51
            hdr.Parent = list

            for name, cb in pairs(FunctionManager:getFunctionsInCategory(cat)) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1,0,0,24)
                btn.Font = Enum.Font.SourceSans
                btn.TextSize = 14
                btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
                btn.TextColor3 = Color3.new(1,1,1)
                btn.ZIndex = 51

                local bound = {}
                for key, fn in pairs(customBinds) do
                    if fn == cb then table.insert(bound, tostring(key)) end
                end
                local suffix = #bound>0 and " ("..table.concat(bound, ",")..")" or ""
                btn.Text = name..suffix
                btn.Parent = list

                btn.MouseButton1Click:Connect(function()
                    waitingBindFunction = { cb = cb, btn = btn, name = name }
                    btn.Text = name.." → [Press a key]"
                end)
            end
        end

        list.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 8)
    end

    bindConn = UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not waitingBindFunction then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            customBinds[input.KeyCode] = waitingBindFunction.cb
            waitingBindFunction.btn.Text = waitingBindFunction.name.." ("..tostring(input.KeyCode)..")"
            waitingBindFunction = nil
        end
    end)
    refreshList()
end, "Utility", "BUGGED")

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local fn = customBinds[input.KeyCode]
        if fn and type(fn) == "function" then
            pcall(fn)
        end
    end
end)

FunctionManager:register("JumpUp", function()
    if hrp then hrp.Velocity = Vector3.new(0, 100, 0) end
end, "Movement", "Leap into the air!")

FunctionManager:register("Sit", function()
    if humanoid then humanoid.Sit = true end
end, "Movement", "SIT DOWN")

local infJumpEnabledFused = false
local infJumpConnectionFused = nil
FunctionManager:register("INF JUMP", function()
    infJumpEnabledFused = not infJumpEnabledFused
    if infJumpEnabledFused then
        local debounce = false
        infJumpConnectionFused = UIS.JumpRequest:Connect(function()
            if debounce then return end
            debounce = true
            local hum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            task.wait()
            debounce = false
        end)
    else
        if infJumpConnectionFused then
            infJumpConnectionFused:Disconnect()
            infJumpConnectionFused = nil
        end
    end
    Notify("INF JUMP " .. (infJumpEnabledFused and "ON" or "OFF"), "Fused", 2)
end, "Movement", "Jump Forever!")

FunctionManager:register("WalkSpeed Slider", function()
    if gui:FindFirstChild("WalkSpeedModal") then return end
    local overlay = Instance.new("Frame")
    overlay.Name = "WalkSpeedModal"
    overlay.Size = UDim2.new(1,0,1,0)
    overlay.Position = UDim2.new(0,0,0,0)
    overlay.BackgroundColor3 = Color3.new(0,0,0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 50
    overlay.Parent = gui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 300, 0, 100)
    panel.Position = UDim2.new(0.5, -150, 0.5, -50)
    panel.BackgroundColor3 = Color3.fromRGB(40,40,40)
    panel.BorderSizePixel = 0
    panel.ZIndex = 51
    panel.Parent = overlay

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,60,0,24)
    closeBtn.Position = UDim2.new(1,-64,0,4)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 14
    closeBtn.Text = "Close"
    closeBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.ZIndex = 52
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        overlay:Destroy()
    end)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-8,0,24)
    label.Position = UDim2.new(0,4,0,4)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.TextColor3 = Color3.new(1,1,1)
    label.Text = "WalkSpeed: " .. tostring(humanoid.WalkSpeed)
    label.ZIndex = 52
    label.Parent = panel

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-16,0,20)
    track.Position = UDim2.new(0,8,0,40)
    track.BackgroundColor3 = Color3.fromRGB(60,60,60)
    track.BorderSizePixel = 0
    track.ZIndex = 51
    track.Parent = panel

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(math.clamp((humanoid.WalkSpeed - 8)/(100-8),0,1), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100,200,100)
    fill.BorderSizePixel = 0
    fill.ZIndex = 52
    fill.Parent = track

    local dragging = false
    local minS, maxS = 8, 100
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0,1)
        local v = math.floor(minS + (maxS-minS)*rel)
        humanoid.WalkSpeed = v
        label.Text = "WalkSpeed: "..v
        fill.Size = UDim2.new(rel,0,1,0)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(i.Position.X)
        end
    end)
    track.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
end, "Movement", "Control your walkspeed!")

FunctionManager:register("Server Hop", function()
    local success, res = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
    end)
    if not success then return NotifyERROR("[Server Hop] HTTP request failed") end
    local body
    local ok, err = pcall(function() body = HttpService:JSONDecode(res) end)
    if not ok or type(body) ~= "table" or type(body.data) ~= "table" then
        return NotifyERROR("[Server Hop] Invalid JSON response")
    end
    local servers = {}
    for _, v in ipairs(body.data) do
        if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= JobId then
            table.insert(servers, v.id)
        end
    end
    if #servers == 0 then return NotifyERROR("[Server Hop] No available servers found") end
    local choice = servers[math.random(1, #servers)]
    TeleportService:TeleportToPlaceInstance(PlaceId, choice, player)
end, "Utility", "Changes Servers")

FunctionManager:register("TP Behind Closest", function()
    if not hrp then return end
    local closestPlayer, shortestDistance = nil, math.huge
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local distance = (otherRoot.Position - hrp.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = otherPlayer
                end
            end
        end
    end
    if closestPlayer and closestPlayer.Character then
        local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local behindPosition = targetRoot.CFrame.Position - targetRoot.CFrame.LookVector * 3
            hrp.CFrame = CFrame.new(behindPosition, targetRoot.Position)
        end
    else
        NotifyERROR("No nearby player found.")
    end
end, "Movement", "Owai moi, shinderu. NANI?")

FunctionManager:register("Scare Closest Player", function()
    if not hrp then return end
    local closestPlayer, closestDistance = nil, math.huge
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local dist = (otherRoot.Position - hrp.Position).Magnitude
                if dist < closestDistance then
                    closestDistance = dist
                    closestPlayer = otherPlayer
                end
            end
        end
    end
    if closestPlayer and closestPlayer.Character then
        local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local oldPos = hrp.CFrame
            hrp.CFrame = targetRoot.CFrame + targetRoot.CFrame.LookVector * 2
            hrp.CFrame = CFrame.new(hrp.Position, targetRoot.Position)
            task.wait(0.5)
            hrp.CFrame = oldPos
        end
    else
        NotifyERROR("No target player nearby.")
    end
end, "Fun", "FNAF reference")

local espOn = false
FunctionManager:register("ESP Toggle", function()
    espOn = not espOn
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and plr ~= player then
            local headPart = plr.Character:FindFirstChild("Head")
            if headPart then
                local bb = headPart:FindFirstChild("ESP") or Instance.new("BillboardGui", headPart)
                bb.Name = "ESP"
                bb.Size = UDim2.new(0,80,0,20)
                bb.AlwaysOnTop = true
                local lbl = bb:FindFirstChild("Name") or Instance.new("TextLabel", bb)
                lbl.Name = "Name"
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.TextColor3 = Color3.new(1,0,0)
                lbl.TextScaled = true
                lbl.Text = plr.Name
                bb.Enabled = espOn
            end
        end
    end
    Notify("ESP " .. (espOn and "Enabled" or "Disabled"), "SYSTEM", 3)
end, "Visual", "ur cooked i just got wallhacks")

FunctionManager:register("JumpPowerSlider", function()
    if gui:FindFirstChild("JumpPowerModal") then return end
    humanoid.UseJumpPower = true
    local overlay = Instance.new("Frame")
    overlay.Name = "JumpPowerModal"
    overlay.Size = UDim2.new(1,0,1,0)
    overlay.Position = UDim2.new(0,0,0,0)
    overlay.BackgroundColor3 = Color3.new(0,0,0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 50
    overlay.Parent = gui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 300, 0, 100)
    panel.Position = UDim2.new(0.5, -150, 0.5, -50)
    panel.BackgroundColor3 = Color3.fromRGB(40,40,40)
    panel.BorderSizePixel = 0
    panel.ZIndex = 51
    panel.Parent = overlay

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,60,0,24)
    closeBtn.Position = UDim2.new(1,-64,0,4)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 14
    closeBtn.Text = "Close"
    closeBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.ZIndex = 52
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function() overlay:Destroy() end)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-8,0,24)
    label.Position = UDim2.new(0,4,0,4)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.TextColor3 = Color3.new(1,1,1)
    label.Text = "JumpPower: " .. tostring(humanoid.JumpPower)
    label.ZIndex = 52
    label.Parent = panel

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-16,0,20)
    track.Position = UDim2.new(0,8,0,40)
    track.BackgroundColor3 = Color3.fromRGB(60,60,60)
    track.BorderSizePixel = 0
    track.ZIndex = 51
    track.Parent = panel

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(math.clamp((humanoid.JumpPower - 50)/(200-50),0,1), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100,200,100)
    fill.BorderSizePixel = 0
    fill.ZIndex = 52
    fill.Parent = track

    local dragging = false
    local minJ, maxJ = 50, 200
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0,1)
        local v = math.floor(minJ + (maxJ-minJ)*rel)
        humanoid.JumpPower = v
        label.Text = "JumpPower: "..v
        fill.Size = UDim2.new(rel,0,1,0)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(i.Position.X)
        end
    end)
    track.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
end, "Movement", "Control your jumppower")

local spinOn = false
local spinBAV, lockBP
FunctionManager:register("Spin Bot", function()
    spinOn = not spinOn
    if spinOn then
        if not hrp then return NotifyERROR("No HRP!") end
        lockBP = Instance.new("BodyPosition")
        lockBP.Name = "SpinLockBP"
        lockBP.Position = hrp.Position
        lockBP.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        lockBP.P = 1e5
        lockBP.D = 0
        lockBP.Parent = hrp

        spinBAV = Instance.new("BodyAngularVelocity")
        spinBAV.Name = "SpinBAV"
        spinBAV.AngularVelocity = Vector3.new(0, 10000, 0)
        spinBAV.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        spinBAV.P = 1e5
        spinBAV.Parent = hrp
        NotifyERROR("Spin Bot On")
    else
        if spinBAV then spinBAV:Destroy() spinBAV = nil end
        if lockBP then lockBP:Destroy() lockBP = nil end
        NotifyERROR("Spin Bot Off")
    end
end, "Visual", "Speeeeen")

FunctionManager:register("TP To Mouse", function()
    local ray = workspace.CurrentCamera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local hit, pos = workspace:FindPartOnRay(ray, character)
    if hit then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end, "Movement", "BUGGED")

local savedCFrame = nil
FunctionManager:register("Save Position", function()
    if hrp then savedCFrame = hrp.CFrame end
    Notify("Position Saved", "SYSTEM", 3)
end, "Utility", "Checkpoint")

FunctionManager:register("Load Position", function()
    if savedCFrame then
        hrp.CFrame = savedCFrame
        Notify("Position Loaded", "SYSTEM", 3)
    else
        NotifyERROR("No Position Saved")
    end
end, "Utility", "Reload")

local noclipOn = false
local hoverHeight
FunctionManager:register("No‑Clip", function()
    noclipOn = not noclipOn
    if noclipOn then
        hoverHeight = hrp.Position.Y
        task.spawn(function()
            while noclipOn do
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
                hrp.CFrame = CFrame.new(hrp.Position.X, hoverHeight, hrp.Position.Z)
                task.wait(0.01)
            end
        end)
        Notify("No‑Clip ON (locked at height)", "SYSTEM", 3)
    else
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
        Notify("No‑Clip OFF", "SYSTEM", 3)
    end
end, "Movement", "NOCLIP")

FunctionManager:register("DarkDex", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua", true))()
end, "General", "Take a peek under the hood")

FunctionManager:register("Teleport to lobby", function()
    if character then character:MoveTo(Vector3.new(0, 50, 0)) end
end, "General", "Teleports you to lobby")

FunctionManager:register("Fling All", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/4nDpRkZU"))()
end, "Trolling", "Fling All But A little Bugged")

FunctionManager:register("c00lkidd Rises", function()
    local userId = 8035096399
    local function spawnC00lkidd()
        local model = Players:CreateHumanoidModelFromUserId(userId)
        model.Name = "c00lkidd"
        model.Parent = workspace
        local root = hrp
        if root and model.PrimaryPart then
            model:SetPrimaryPartCFrame(root.CFrame * CFrame.new(math.random(-5,5), 0, math.random(-5,5)))
        end
        local cRoot = model:FindFirstChild("HumanoidRootPart")
        if cRoot then
            local bp = Instance.new("BodyPosition", cRoot)
            bp.Position = cRoot.Position + Vector3.new(0,5,0)
            bp.MaxForce = Vector3.new(0,5000,0)
            bp.D = 100
            bp.P = 3000
            Instance.new("Fire", cRoot).Heat = 10
            Instance.new("Smoke", cRoot).Color = Color3.new(0,0,0)
        end
        local hum = model:FindFirstChild("Humanoid")
        if hum then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://235542946"
            local track = hum:LoadAnimation(anim)
            track.Looped = true
            track:Play()
        end
        return model
    end
    spawnC00lkidd()
    local hint = Instance.new("Hint", workspace)
    for i = 100,1,-1 do hint.Text = "Countdown: " .. i; wait(1) end
    hint:Destroy()
    for _, p in pairs(Players:GetPlayers()) do p:Kick("Server Shutdown") end
end, "Fun", "Holy c00lkidd!")

FunctionManager:register("SimpleSpy", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
end, "Catch remotes")

FunctionManager:register("Orbit All Nearby Parts", function()
    local radius = 20
    local height = 3
    local orbitSpeed = 2
    if not hrp then return end
    local origin = hrp.Position
    local orbitParts = {}
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(workspace.Terrain) then
            local isInCharacter = false
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl.Character and part:IsDescendantOf(pl.Character) then isInCharacter = true; break end
            end
            if not isInCharacter and (part.Position - origin).Magnitude <= radius then
                if not CollectionService:HasTag(part, "OrbitPart") then
                    if part:CanSetNetworkOwnership() then part:SetNetworkOwner(player) end
                    part.CanCollide = false
                    CollectionService:AddTag(part, "OrbitPart")
                    table.insert(orbitParts, part)
                end
            end
        end
    end
    if #orbitParts == 0 then return end
    local angleOffset = 2 * math.pi / #orbitParts
    for i, part in ipairs(orbitParts) do
        local angle = angleOffset * i
        part.Position = hrp.Position + Vector3.new(math.cos(angle)*radius, height, math.sin(angle)*radius)
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
        bodyGyro.P = 1e4
        bodyGyro.CFrame = CFrame.new(part.Position, hrp.Position)
        bodyGyro.Parent = part
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
        bodyVel.P = 1e4
        bodyVel.Parent = part
        local conn
        conn = RunService.Heartbeat:Connect(function(dt)
            if not hrp or not hrp.Parent then conn:Disconnect() return end
            angle = angle + orbitSpeed * dt
            local orbitCenter = hrp.Position
            local orbitPoint = orbitCenter + Vector3.new(math.cos(angle)*radius, height, math.sin(angle)*radius)
            local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle)).Unit * orbitSpeed * radius
            bodyVel.Velocity = tangent
            bodyGyro.CFrame = CFrame.new(part.Position, orbitCenter)
            part.Position = orbitPoint
        end)
    end
end, "Fun", "You have to be near the parts for a while for it to work")

local invisRunning = false
local function toggleInvisibility()
    if invisRunning then return end
    invisRunning = true
    local originalChar = character
    originalChar.Archivable = true
    local invisibleChar = originalChar:Clone()
    invisibleChar.Name = ""
    invisibleChar.Parent = Lighting
    for _, part in ipairs(invisibleChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = (part.Name == "HumanoidRootPart") and 1 or 0.5
        end
    end
    local voidConn, deathConn, steppedConn
    local function Respawn()
        invisRunning = false
        if steppedConn then steppedConn:Disconnect() end
        if deathConn then deathConn:Disconnect() end
        player.Character = originalChar
        originalChar.Parent = workspace
        local clonedHum = originalChar:FindFirstChildWhichIsA("Humanoid")
        if clonedHum then clonedHum:Destroy() end
        invisibleChar.Parent = nil
    end
    local voidY = workspace.FallenPartsDestroyHeight
    steppedConn = RunService.Stepped:Connect(function()
        local hrpPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrpPart then return end
        local y = hrpPart.Position.Y
        if (voidY < 0 and y <= voidY) or (voidY >= 0 and y >= voidY) then
            Respawn()
        end
    end)
    local clonedHum = invisibleChar:FindFirstChildWhichIsA("Humanoid")
    if clonedHum then
        deathConn = clonedHum.Died:Connect(Respawn)
    end
    local camCF = workspace.CurrentCamera.CFrame
    local hrpCF = originalChar.HumanoidRootPart.CFrame
    originalChar:MoveTo(Vector3.new(0, math.pi*1e6, 0))
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    task.wait(0.2)
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    invisibleChar.Parent = workspace
    invisibleChar.HumanoidRootPart.CFrame = hrpCF
    player.Character = invisibleChar
    for _, a in ipairs(player.Character:GetDescendants()) do
        if a.Name == "Animate" and a:IsA("Model") then
            a.Disabled = true; a.Disabled = false
        end
    end
    workspace.CurrentCamera:remove()
    wait(0.1)
    repeat wait() until player.Character ~= nil
    workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChildWhichIsA('Humanoid')
    workspace.CurrentCamera.CameraType = "Custom"
    player.CameraMinZoomDistance = 0.5
    player.CameraMaxZoomDistance = 400
    player.CameraMode = "Classic"
    if player.Character.Head then player.Character.Head.Anchored = false end
    if player.Character.Animate then
        player.Character.Animate.Enabled = false
        player.Character.Animate.Enabled = true
    end
    Notify("You are now invisible!", "System", 3)
end
FunctionManager:register("Invisible", toggleInvisibility, "Fun", "Make your character invisible until you respawn or die")

local flyingEnabledFused = false
local flyBG, flyBV, flyConnFused
FunctionManager:register("Fly", function()
    if not hrp then return end
    flyingEnabledFused = not flyingEnabledFused
    if flyingEnabledFused then
        flyBG = Instance.new("BodyGyro")
        flyBG.P = 9e4
        flyBG.MaxTorque = Vector3.new(9e4,9e4,9e4)
        flyBG.CFrame = hrp.CFrame
        flyBG.Parent = hrp
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(9e4,9e4,9e4)
        flyBV.Velocity = Vector3.new(0,0,0)
        flyBV.Parent = hrp
        flyConnFused = RunService.Heartbeat:Connect(function()
            local camCF = workspace.CurrentCamera.CFrame
            local dir = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
            if dir.Magnitude > 0 then dir = dir.Unit * 50 end
            flyBV.Velocity = dir
            flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
        end)
    else
        if flyConnFused then flyConnFused:Disconnect() flyConnFused = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
        if flyBV then flyBV:Destroy() flyBV = nil end
    end
end, "Movement", "Fly around!")

FunctionManager:register("HatHub", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/inkdupe/hat-scripts/refs/heads/main/updatedhathub.lua"))()
end, "Troll", "Credits to original maker!")

FunctionManager:register("Hitbox Extender", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/AAPVdev/scripts/refs/heads/main/UI_LimbExtender.lua'))()
end, "Troll", "Extends hitboxes")

FunctionManager:register("Part Grab", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/v0c0n1337/scripts/refs/heads/main/Unachored_parts_controller_v2.lua.txt"))()
end, "Troll", "Much better part grab")

FunctionManager:register("Hat Script", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ocfi/Scp-096-Obfuscated/refs/heads/main/obuf"))()
end, "Troll", "HATS")

FunctionManager:register("PART ORBIT", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/aZjaAr6F", true))()
end, "Troll", "Probs better orbit")

FunctionManager:register("Unban VoiceChat", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/aDFhvMC4", true))()
end, "Utility", "Credits to the original maker!")

FunctionManager:register("Fling GUI", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/VynRhxJV", true))()
end, "Troll", "Credits to the original maker!")

FunctionManager:register("Invis gui V2", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/hracJzLa"))()
end, "Trolling", "Credits to the original maker!")

FunctionManager:register("Thomas Train", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/dcywCSCs"))()
end, "Troll", "Become Thomas the Dank Engine!")

FunctionManager:register("I..... Am Steve", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/miABMATi"))()
end, "Trolling", "Who are you? I... Am Steve..")

FunctionManager:register("TP Tool", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/WUwLqAzr"))()
end, "Utility", "It's a teleport tool")

FunctionManager:register("GOD Mode Toggle", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/eD8HBXGS"))()
end, "Utility", "GOD Mode Toggle GUI")

FunctionManager:register("Control NPC GUI", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/fe-source/refs/heads/main/NPC/source/main.Luau"))()
end, "Trolling", "Credits to original script maker")

FunctionManager:register("Fake VR (hat method)", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/Qwerty/refs/heads/main/qwerty46.lua"))()
end, "Trolling", "Credits to original script maker")

FunctionManager:register("Telekinesis Powers", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/Qwerty/refs/heads/main/qwerty1.lua"))()
end, "Troll", "Credits to original script maker!")

FunctionManager:register("Infinite Yield", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end, "General", "The classic admin commands script!")

FunctionManager:register("Nameless Admin", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua"))()
end, "General", "Slight differences from infiniteyield admin")

FunctionManager:register("Drift Car", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/AstraOutlight/my-scripts/refs/heads/main/fe%20car%20v3"))()
end, "Fun", "Invisible Car :O")

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
    fusedPanel.Position = UDim2.new(0.5, -250, 0.5, -200)
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
        local cat = FunctionManager:getCurrentCategory()
        catLabelF.Text = cat
        for name, cb in pairs(FunctionManager:getFunctionsInCategory(cat)) do
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
        FunctionManager.CurrentCategoryIndex = (FunctionManager.CurrentCategoryIndex - 2) % #FunctionManager.Categories + 1
        updateGridFused()
    end)
    rightCatF.MouseButton1Click:Connect(function()
        FunctionManager:cycleCategory()
        updateGridFused()
    end)
    updateGridFused()
end)

Notify("EXVS Multi Tool Active!", "System", 3)
