local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats            = game:GetService("Stats")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()
if  _G.sourcecheckexvs ~= "source" then 
    warn("https://rscripts.net/script/multi-tool-hub-X0cu")
    error("The script source is not supported! Please use EXVS Hub from link upper!", 0)
end
math.randomseed(os.clock() * 100000)

local LOG_ENABLED = true
local LOG_TAGS = {
    CORE = true, FARM = true, LINK = true, RESPAWN = true, SCAN = true, PLANE = true,
    AIM = false, SPEED = false, ESP = false,
}
local function log(tag, ...)
    if not LOG_ENABLED or not LOG_TAGS[tag] then return end
    print(("[AA][%s]"):format(tag), ...)
end

local FOV_DEGREES  = 125
local HALF_FOV     = FOV_DEGREES / 2
local MAX_DISTANCE = 700
local OWNER_TTL    = 0.3
local CAM_VEHICLE_TTL = 0.15
local CAM_SUBJECT_MAX_DIST = 50

local PRED_MAX_SAMPLES = 12
local PRED_MIN_DT      = 0.008
local PRED_LEAD_BASE   = 0.04
local PRED_MAX_TIME    = 1.2
local PING_CACHE_TTL   = 0.7
local PRED_RECENCY     = 0.82

local SPEED_MAX        = 1200
local AIMBOT_KEY       = Enum.KeyCode.C

local RAGE_SMOOTH_ALPHA      = 0.50
local RAGE_MAX_DEG_PER_FRAME = 30
local RAGE_DEADZONE_DEG      = 0.3
local TARGET_LOCK_TIME       = 0.35

local AUTOKILL_BEHIND_DIST     = 40
local AUTOKILL_LIFT            = 10
local AUTOKILL_FIRE_HOLD       = 1.5
local AUTOKILL_FIRE_GAP        = 0.15
local AUTOKILL_DEAD_TIMEOUT    = 0.8
local AUTOKILL_DEAD_MOVE_MIN   = 3.0
local AUTOKILL_LINE_CLEAR_MARG = 12
local AUTOKILL_TARGET_SMOOTH   = 0.35
local AUTOKILL_POS_SMOOTH      = 0.45

local RESPAWN_LERP_TIME      = 0.45
local RESPAWN_PICKER_TIMEOUT = 25
local RESPAWN_AFTER_PICKER   = 0.5
local RESPAWN_NO_VEHICLE_DELAY = 0.5
local RESPAWN_JOIN_GRACE     = 2.0
local RESPAWN_PLANE_WAIT     = 0.2

local PLANE_PRIORITY = { "Striker", "Tyrant", "Phantom", "Phoenix" }
local GREEN_DEPTH    = Color3.fromRGB(22, 106, 54)
local COLOR_TOL      = 0.06

local SHIELD_OUR_COLOR = Color3.fromRGB(87, 204, 236)
local SHIELD_COLOR_TOL = 0.08

local FOV_BALL_BASE_RADIUS  = 6
local FOV_BALL_COLOR        = Color3.fromRGB(255, 150, 40)
local FOV_BALL_TRANSPARENCY = 0.55

local ESP_DEPTH_MODE        = Enum.HighlightDepthMode.AlwaysOnTop
local ESP_FILL_TRANSPARENCY = 0.5

local MOVE_KEYS = {
    [Enum.KeyCode.W] = "W", [Enum.KeyCode.A] = "A",
    [Enum.KeyCode.S] = "S", [Enum.KeyCode.D] = "D",
}

local State = {
    Linked = false, Vehicle = nil, AimPart = nil,
    Mode = "Rage", AimBot = false, AimBotHeld = false,
    Priority = "Distance", Destroyed = false,
    LockedTarget = nil, LockedTargetT = 0,
    AlignCache = setmetatable({}, { __mode = "k" }),
    JoinTime = os.clock(),
    NoVehicleSince = 0,
    LastOwnerReason = nil,
    CameraVehicle = nil,
    CameraVehicleT = 0,
}

local EspState = { Enabled = false, Applied = setmetatable({}, { __mode = "k" }) }

local SpeedState = {
    Enabled = false, SPS = 0, LastPos = nil, LastT = 0,
    W = false, A = false, S = false, D = false,
}

local AutoKillState = {
    Enabled = false, Target = nil,
    FirePhase = "idle",
    FireTimer = 0,
    LastTargetPos = nil, TargetIdleT = 0,
    FovBall = nil, SavedCollide = nil,
    LastTargetName = nil,
    LastCanFire = nil,
    TargetBehindSign = 0,
    SmoothedTargetPos = nil,
    SmoothedOurPos = nil,
    TargetSize = 0,
    QTimer = 0,
}

local RespawnState = {
    Active = false,
    Phase = "idle",
    Timer = 0,
    HoldChar = nil,
    HoldCF = nil,
    StartCF = nil,
    LerpT = 0,
    PickerClicked = false,
    Clicked = false,
    ClickInitiated = false,
    LastTeamLog = nil,
    LastSpawnerLog = nil,
    PlaneSelected = false,
    PlaneWaitT = 0,
    SavedCharCollide = nil,
}

local ScanState = {
    FolderName = nil,
    LastScanT = 0,
    LastLogT = 0,
}

local selectTarget
local getTargetsList

local function isAimBotActive() return State.AimBot or State.AimBotHeld end
local function isMoveKeyActive() return SpeedState.W or SpeedState.A or SpeedState.S or SpeedState.D end

local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not playerGui then warn("[AA][CORE] PlayerGui not found."); return end
log("CORE", "PlayerGui ok")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimAssistUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 400)
frame.Position = UDim2.new(0, 20, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
frame.BackgroundTransparency = 0.08
frame.BorderSizePixel = 0
frame.Active = true
frame.Visible = true
frame.ZIndex = 10
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, -60, 0, 26)
titleBar.Position = UDim2.new(0, 10, 0, 6)
titleBar.BackgroundTransparency = 1
titleBar.Text = "Aim Assist - Waiting..."
titleBar.TextColor3 = Color3.fromRGB(240, 240, 240)
titleBar.TextXAlignment = Enum.TextXAlignment.Left
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 15
titleBar.ZIndex = 11
titleBar.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(190, 55, 55)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 12
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local function makeButton(text, y, height)
    height = height or 30
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, height)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.fromRGB(235, 235, 235)
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.Text = text
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.ZIndex = 11
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.Parent = b
    return b
end

local function addBadge(btn, badgeText, color, big)
    local b = Instance.new("TextLabel")
    b.Name = "Badge"
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.Position = UDim2.new(1, -6, 0.5, 0)
    b.Size = UDim2.new(0, big and 56 or 44, 0, big and 16 or 13)
    b.BackgroundColor3 = color
    b.BackgroundTransparency = big and 0.15 or 0.45
    b.Text = badgeText
    b.TextColor3 = big and Color3.fromRGB(255, 255, 255)
                    or Color3.fromRGB(255, 245, 200)
    b.Font = big and Enum.Font.GothamBold or Enum.Font.Gotham
    b.TextSize = big and 11 or 9
    b.BorderSizePixel = 0
    b.Visible = true
    b.ZIndex = 12
    b.Parent = btn
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = b
    return b
end

local modeBtn      = makeButton("Mode: Rage",         40)
local aimbotBtn    = makeButton("AimBot: OFF",        76)
local priorityBtn  = makeButton("Priority: Distance", 112)
local espBtn       = makeButton("ESP: OFF",           148)
local speedBtn     = makeButton("SpeedHack: OFF",     184)
local autoFarmBtn  = makeButton("AUTO FARM: OFF",     220, 60)

autoFarmBtn.TextXAlignment = Enum.TextXAlignment.Center
autoFarmBtn.Font = Enum.Font.GothamBold
autoFarmBtn.TextSize = 18
autoFarmBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 40)

local autoFarmPad = autoFarmBtn:FindFirstChildOfClass("UIPadding")
if autoFarmPad then autoFarmPad.PaddingLeft = UDim.new(0, 0) end

local modeBadge    = addBadge(modeBtn,     "RISKY", Color3.fromRGB(210, 40, 40), true)
local autoFarmBadge = addBadge(autoFarmBtn, "RISKY", Color3.fromRGB(210, 40, 40), true)
addBadge(speedBtn, "RISKY", Color3.fromRGB(200, 170, 30), false)

autoFarmBadge.AnchorPoint = Vector2.new(1, 1)
autoFarmBadge.Position    = UDim2.new(1, -6, 1, -4)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 18)
speedLabel.Position = UDim2.new(0, 10, 0, 292)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 0 SPS"
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 12
speedLabel.ZIndex = 11
speedLabel.Parent = frame

local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(1, -20, 0, 8)
sliderTrack.Position = UDim2.new(0, 10, 0, 314)
sliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sliderTrack.BorderSizePixel = 0
sliderTrack.ZIndex = 11
sliderTrack.Parent = frame
Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(90, 160, 255)
sliderFill.BorderSizePixel = 0
sliderFill.ZIndex = 11
sliderFill.Parent = sliderTrack
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local sliderHandle = Instance.new("Frame")
sliderHandle.AnchorPoint = Vector2.new(0.5, 0.5)
sliderHandle.Size = UDim2.new(0, 16, 0, 16)
sliderHandle.Position = UDim2.new(0, 0, 0.5, 0)
sliderHandle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
sliderHandle.BorderSizePixel = 0
sliderHandle.ZIndex = 12
sliderHandle.Parent = sliderTrack
Instance.new("UICorner", sliderHandle).CornerRadius = UDim.new(1, 0)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -20, 0, 20)
statusLbl.Position = UDim2.new(0, 10, 0, 336)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Status: Waiting..."
statusLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 12
statusLbl.ZIndex = 11
statusLbl.Parent = frame

local fovGui = Instance.new("ScreenGui")
fovGui.Name = "AimAssistFOV"
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true
fovGui.DisplayOrder = 5
fovGui.Parent = playerGui

local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.Size = UDim2.new(0, 200, 0, 200)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = fovGui
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 2
fovStroke.Color = Color3.fromRGB(255, 80, 80)
fovStroke.Transparency = 0.25
fovStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
fovStroke.Parent = fovCircle

do
    local dragging, dragStart, startPos
    local sliderDragging = false
    local function pointInSlider(p)
        local sp, ss = sliderTrack.AbsolutePosition, sliderTrack.AbsoluteSize
        if not sp or not ss then return false end
        return p.X >= sp.X-4 and p.X <= sp.X+ss.X+4 and p.Y >= sp.Y-10 and p.Y <= sp.Y+ss.Y+10
    end
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if pointInSlider(input.Position) then return end
            dragging, dragStart, startPos = true, input.Position, frame.Position
        end
    end)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
    local function setSliderFromX(mouseX)
        local sp, ss = sliderTrack.AbsolutePosition, sliderTrack.AbsoluteSize
        if not sp or not ss or ss.X <= 0 then return end
        local alpha = math.clamp((mouseX - sp.X) / ss.X, 0, 1)
        SpeedState.SPS = math.floor(alpha * SPEED_MAX + 0.5)
        sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
        sliderHandle.Position = UDim2.new(alpha, 0, 0.5, 0)
        speedLabel.Text = "Speed: "..SpeedState.SPS.." SPS"
    end
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging = true; setSliderFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not sliderDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            setSliderFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliderDragging = false end
    end)
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == AIMBOT_KEY then State.AimBotHeld = true end
    local mk = MOVE_KEYS[input.KeyCode]; if mk then SpeedState[mk] = true end
end)
UserInputService.InputEnded:Connect(function(input, _)
    if input.KeyCode == AIMBOT_KEY then State.AimBotHeld = false end
    local mk = MOVE_KEYS[input.KeyCode]; if mk then SpeedState[mk] = false end
end)

local function getRefPosition()
    local cam = workspace.CurrentCamera
    if cam then return cam.CFrame.Position end
    return Vector3.zero
end

local function getScreenCenter()
    local vp = Camera.ViewportSize
    return math.floor(vp.X * 0.5), math.floor(vp.Y * 0.5)
end

local function pressDown()
    local cx, cy = getScreenCenter()
    VirtualInputManager:SendMouseMoveEvent(cx, cy, workspace.CurrentCamera)
    task.wait(0.005)
    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, false)
end

local function releaseDown()
    local cx, cy = getScreenCenter()
    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, false)
end

local function clickGuiButton(btn)
    if not btn or not btn.Parent then return false end
    if typeof(firesignal) == "function" then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.Activated) end)
        return true
    end
    if typeof(getconnections) == "function" then
        pcall(function()
            for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
            for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
        end)
        return true
    end
    local pos = btn.AbsolutePosition + btn.AbsoluteSize * 0.5
    local cx, cy = math.floor(pos.X), math.floor(pos.Y)
    VirtualInputManager:SendMouseMoveEvent(cx, cy, workspace.CurrentCamera)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, false)
    task.wait(0.02)
    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, false)
    return true
end

local function isPlayerDead()
    local char = LocalPlayer.Character
    if not char then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return true end
    return false
end

local function hasOurVehicle()
    return State.Linked and State.Vehicle and State.Vehicle.Parent ~= nil
end

local function getRespawnButton()
    local ds = playerGui:FindFirstChild("DeathScreen")
    if not ds then return nil end
    local inner = ds:FindFirstChild("DeathScreen")
    if not inner then return nil end
    local buttons = inner:FindFirstChild("Buttons")
    if not buttons then return nil end
    local primary = buttons:FindFirstChild("Primary")
    if not primary then return nil end
    local respawn = primary:FindFirstChild("Respawn")
    if respawn and respawn:IsA("GuiButton") then return respawn end
    return nil
end

-- === team detection via island shield color ===
local function colorClose(a, b, tol)
    if not a or not b then return false end
    tol = tol or SHIELD_COLOR_TOL
    return math.abs(a.R - b.R) <= tol and math.abs(a.G - b.G) <= tol and math.abs(a.B - b.B) <= tol
end

local function readShieldLinesColor(lines)
    if not lines then return nil end
    if lines:IsA("BasePart") then
        return lines.Color
    elseif lines:IsA("GuiObject") then
        return lines.BackgroundColor3
    elseif lines:IsA("ImageLabel") or lines:IsA("ImageButton") then
        return lines.ImageColor3
    end
    -- На всякий случай: попробуем найти первую BasePart внутри
    for _, d in ipairs(lines:GetDescendants()) do
        if d:IsA("BasePart") then return d.Color end
    end
    return nil
end

local function islandIsOurs(islandName)
    local islands = workspace:FindFirstChild("Islands")
    if not islands then return false end
    local island = islands:FindFirstChild(islandName)
    if not island then return false end
    local shield = island:FindFirstChild("Shield")
    if not shield then return false end
    local lines = shield:FindFirstChild("Lines")
    if not lines then return false end
    local c = readShieldLinesColor(lines)
    return colorClose(c, SHIELD_OUR_COLOR)
end

local function getOurIsland()
    if islandIsOurs("4") then return "4" end
    if islandIsOurs("3") then return "3" end
    return nil
end

local function containerTouchPart(container)
    if not container then return nil end
    local tp = container:FindFirstChild("PlayerTouchPart")
    if tp and tp:IsA("BasePart") then return tp end
    return nil
end

local function spawnerSupportsPhoenix(container)
    if not container then return false end
    local vk = container:FindFirstChild("VehicleKinds")
    if not vk then return true end
    for _, c in ipairs(vk:GetChildren()) do
        if c:IsA("BoolValue") then
            if string.lower(c.Name) == "phoenix" then
                return true
            end
        end
    end
    return false
end

local function findRespawnPoint()
    local islandName = getOurIsland()
    if not islandName then
        if RespawnState.LastSpawnerLog ~= "no_island" then
            RespawnState.LastSpawnerLog = "no_island"
            log("RESPAWN", "no cyan shield (RGB 87,204,236) on Islands 3/4 → our island unknown")
        end
        return nil
    end

    local containerIdx
    if islandName == "4" then
        containerIdx = 5
    elseif islandName == "3" then
        containerIdx = 4
    else
        return nil
    end

    if RespawnState.LastTeamLog ~= islandName then
        RespawnState.LastTeamLog = islandName
        log("RESPAWN", "our island: "..islandName.." → Containers["..containerIdx.."]")
    end

    local islands = workspace:FindFirstChild("Islands")
    if not islands then return nil end
    local island = islands:FindFirstChild(islandName)
    if not island then return nil end
    local containers = island:FindFirstChild("Containers")
    if not containers then return nil end
    local children = containers:GetChildren()

    if #children >= containerIdx then
        local primary = children[containerIdx]
        local tp = containerTouchPart(primary)
        if tp and spawnerSupportsPhoenix(primary) then
            local tag = ("found_%s_%d"):format(islandName, containerIdx)
            if RespawnState.LastSpawnerLog ~= tag then
                RespawnState.LastSpawnerLog = tag
                log("RESPAWN", ("spawner: Islands['%s'].Containers[%d]"):format(islandName, containerIdx))
            end
            return tp
        else
            if tp and not spawnerSupportsPhoenix(primary) then
                local tag = ("skip_phoenix_%s_%d"):format(islandName, containerIdx)
                if RespawnState.LastSpawnerLog ~= tag then
                    RespawnState.LastSpawnerLog = tag
                    log("RESPAWN", ("skip Containers[%d] - no phoenix"):format(containerIdx))
                end
            end
        end
    end

    for i, c in ipairs(children) do
        if i ~= containerIdx then
            local tp = containerTouchPart(c)
            if tp and spawnerSupportsPhoenix(c) then
                local tag = ("fallback_%s_%d"):format(islandName, i)
                if RespawnState.LastSpawnerLog ~= tag then
                    RespawnState.LastSpawnerLog = tag
                    log("RESPAWN", ("fallback spawner: Containers[%d]"):format(i))
                end
                return tp
            end
        end
    end
    return nil
end

local function getVehiclePickerList()
    local vp = playerGui:FindFirstChild("VehiclePicker")
    if not vp then return nil end
    return vp:FindFirstChild("List")
end

local function getVehiclePickerButton()
    local vp = playerGui:FindFirstChild("VehiclePicker")
    if not vp then return nil end
    local actionRow = vp:FindFirstChild("ActionRow")
    if not actionRow then return nil end
    for _, child in ipairs(actionRow:GetChildren()) do
        if child.Name == "1" and child:IsA("TextButton") then
            return child
        end
    end
    return nil
end

local function findDepth(btn)
    if not btn then return nil end
    local d = btn:FindFirstChild("Depth")
    if d then return d end
    for _, desc in ipairs(btn:GetDescendants()) do
        if desc.Name == "Depth" then return desc end
    end
    return nil
end

local function colorMatch(c, target, tol)
    if not c then return false end
    tol = tol or COLOR_TOL
    return math.abs(c.R - target.R) <= tol
       and math.abs(c.G - target.G) <= tol
       and math.abs(c.B - target.B) <= tol
end

local function isGreenDepth(depth)
    if not depth then return false end
    if depth:IsA("GuiObject") then
        local ok, c = pcall(function() return depth.BackgroundColor3 end)
        if ok and colorMatch(c, GREEN_DEPTH) then return true end
    end
    local ok2, c2 = pcall(function() return depth.ImageColor3 end)
    if ok2 and colorMatch(c2, GREEN_DEPTH) then return true end
    return false
end

local function trySelectPlane()
    local list = getVehiclePickerList()
    if not list then return false, "no List" end
    for _, planeName in ipairs(PLANE_PRIORITY) do
        local btn = list:FindFirstChild(planeName)
        if btn and btn:IsA("TextButton") then
            local depth = findDepth(btn)
            if depth and isGreenDepth(depth) then
                clickGuiButton(btn)
                return true, planeName
            end
        end
    end
    return false, "no green plane"
end

local function disableCharCollision(char)
    if not char then return end
    if RespawnState.SavedCharCollide then return end
    RespawnState.SavedCharCollide = {}
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") and d.CanCollide then
            table.insert(RespawnState.SavedCharCollide, { part = d, canCollide = true })
            d.CanCollide = false
        end
    end
    log("RESPAWN", "char collision disabled")
end

local function restoreCharCollision()
    if not RespawnState.SavedCharCollide then return end
    for _, rec in ipairs(RespawnState.SavedCharCollide) do
        if rec.part and rec.part.Parent then
            pcall(function() rec.part.CanCollide = rec.canCollide end)
        end
    end
    RespawnState.SavedCharCollide = nil
    log("RESPAWN", "char collision restored")
end

local function releaseChar(char)
    restoreCharCollision()
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        if hum.UseJumpPower ~= nil then hum.UseJumpPower = true end
        hum.JumpHeight = 7.2
        hum.AutoRotate = true
    end
end

local function resetPlaneSelection()
    RespawnState.PlaneSelected = false
    RespawnState.PlaneWaitT = 0
end

local function abortRespawnFlow(reason)
    if not RespawnState.Active then return end
    log("RESPAWN", "abort: "..reason)
    restoreCharCollision()
    if RespawnState.HoldChar then releaseChar(RespawnState.HoldChar) end
    RespawnState.Active = false
    RespawnState.Phase = "idle"
    RespawnState.HoldChar = nil
    RespawnState.HoldCF = nil
    RespawnState.StartCF = nil
    RespawnState.LerpT = 0
    RespawnState.Clicked = false
    RespawnState.ClickInitiated = false
    RespawnState.Timer = 0
    resetPlaneSelection()
end

local function startRespawnFlow()
    if RespawnState.Active then return end
    RespawnState.Active = true
    RespawnState.Timer = 0
    RespawnState.HoldChar = nil
    RespawnState.HoldCF = nil
    RespawnState.StartCF = nil
    RespawnState.LerpT = 0
    RespawnState.PickerClicked = false
    RespawnState.Clicked = false
    RespawnState.ClickInitiated = false
    resetPlaneSelection()

    local respawnBtn = getRespawnButton()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local alive = hum and hum.Health > 0

    if char then disableCharCollision(char) end

    if respawnBtn or not alive then
        RespawnState.Phase = "waiting_button"
        log("RESPAWN", "start (dead path)")
    else
        RespawnState.Phase = "preparing_lerp"
        log("RESPAWN", "start (no vehicle path)")
    end
end

local function updateRespawnFlow(dt)
    local phase = RespawnState.Phase

    if phase == "waiting_button" then
        local btn = getRespawnButton()
        if btn then
            clickGuiButton(btn)
            log("RESPAWN", "clicked respawn button")
            RespawnState.Clicked = true
            RespawnState.ClickInitiated = true
            RespawnState.Phase = "waiting_char"
            RespawnState.Timer = 0
            return
        end

        if not RespawnState.ClickInitiated and hasOurVehicle() and not isPlayerDead() then
            abortRespawnFlow("vehicle acquired"); return
        end

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if char and hum and hum.Health > 0 then
            disableCharCollision(char)
            RespawnState.Timer += dt
            if RespawnState.Timer > 0.3 then
                RespawnState.Phase = "preparing_lerp"
                RespawnState.Timer = 0
                log("RESPAWN", "alive, no button → spawner path")
            end
        end

    elseif phase == "waiting_char" then
        if not RespawnState.ClickInitiated and hasOurVehicle() and not isPlayerDead() then
            abortRespawnFlow("vehicle acquired"); return
        end
        RespawnState.Timer += dt
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                disableCharCollision(char)
                hum.PlatformStand = true
                hum.WalkSpeed = 0
                hum.JumpPower = 0
                hum.JumpHeight = 0
                if hum.UseJumpPower ~= nil then hum.UseJumpPower = false end
                hum.AutoRotate = false
                RespawnState.Phase = "preparing_lerp"
                RespawnState.Timer = 0
                log("RESPAWN", "character ready")
            end
        end
        if RespawnState.Timer > 8 then
            RespawnState.Phase = "waiting_button"
            RespawnState.Clicked = false
            RespawnState.Timer = 0
        end

    elseif phase == "preparing_lerp" then
        if not RespawnState.ClickInitiated and hasOurVehicle() and not isPlayerDead() then
            abortRespawnFlow("vehicle acquired"); return
        end
        local char = LocalPlayer.Character
        if not char then
            RespawnState.Phase = "waiting_char"
            RespawnState.Timer = 0
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            RespawnState.Timer += dt
            if RespawnState.Timer > 3 then
                RespawnState.Phase = "waiting_char"
                RespawnState.Timer = 0
            end
            return
        end
        disableCharCollision(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = true
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.JumpHeight = 0
            if hum.UseJumpPower ~= nil then hum.UseJumpPower = false end
            hum.AutoRotate = false
        end
        local touchPart = findRespawnPoint()
        if not touchPart then
            RespawnState.Timer += dt
            if RespawnState.Timer > 5 then
                log("RESPAWN", "no touch part, abort")
                abortRespawnFlow("no touch part")
            end
            return
        end
        RespawnState.HoldChar = char
        RespawnState.StartCF = hrp.CFrame
        RespawnState.HoldCF = CFrame.new(touchPart.Position) * (hrp.CFrame - hrp.CFrame.Position)
        RespawnState.LerpT = 0
        RespawnState.Phase = "lerping"
        log("RESPAWN", "lerp start to "..tostring(touchPart.Position))

    elseif phase == "lerping" then
        if not RespawnState.ClickInitiated and hasOurVehicle() and not isPlayerDead() then
            abortRespawnFlow("vehicle acquired"); return
        end
        local char = RespawnState.HoldChar
        if not char or not char.Parent then
            RespawnState.Phase = "preparing_lerp"
            RespawnState.Timer = 0
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            RespawnState.Phase = "preparing_lerp"
            RespawnState.Timer = 0
            return
        end
        disableCharCollision(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = true
            hum.WalkSpeed = 0
        end
        RespawnState.LerpT += dt / RESPAWN_LERP_TIME
        if RespawnState.LerpT >= 1 then
            RespawnState.LerpT = 1
            hrp.CFrame = RespawnState.HoldCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            RespawnState.Phase = "holding"
            RespawnState.Timer = 0
            log("RESPAWN", "lerp done, holding")
            return
        end
        local alpha = RespawnState.LerpT
        local smooth = alpha < 0.5 and (2*alpha*alpha) or (1 - ((-2*alpha + 2)^2)/2)
        hrp.CFrame = RespawnState.StartCF:Lerp(RespawnState.HoldCF, smooth)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

    elseif phase == "holding" then
        local char = RespawnState.HoldChar
        if not char or not char.Parent then
            RespawnState.Phase = "preparing_lerp"
            RespawnState.Timer = 0
            return
        end
        disableCharCollision(char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and RespawnState.HoldCF then
            hrp.CFrame = RespawnState.HoldCF
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end

        if getVehiclePickerButton() then
            RespawnState.Phase = "clicking_picker"
            RespawnState.Timer = 0
            resetPlaneSelection()
            log("RESPAWN", "vehicle picker visible")
            return
        end

        RespawnState.Timer += dt
        if RespawnState.Timer > RESPAWN_PICKER_TIMEOUT then
            log("RESPAWN", "picker timeout")
            abortRespawnFlow("picker timeout")
        end

    elseif phase == "clicking_picker" then
        RespawnState.Timer += dt
        if RespawnState.Timer < 0.3 then return end

        if not RespawnState.PlaneSelected then
            local ok, name = trySelectPlane()
            if ok then
                RespawnState.PlaneSelected = true
                RespawnState.PlaneWaitT = 0
                log("PLANE", "selected: "..name)
                return
            end
            if RespawnState.Timer > 2.3 then
                log("PLANE", "no green plane, proceeding to click 1")
                RespawnState.PlaneSelected = true
                RespawnState.PlaneWaitT = 0
                return
            end
            return
        end

        RespawnState.PlaneWaitT += dt
        if RespawnState.PlaneWaitT < RESPAWN_PLANE_WAIT then return end

        local btn = getVehiclePickerButton()
        if btn then
            clickGuiButton(btn)
            log("RESPAWN", "clicked picker button 1")
            RespawnState.Phase = "after_picker"
            RespawnState.Timer = 0
        else
            RespawnState.Phase = "holding"
            RespawnState.Timer = 0
            resetPlaneSelection()
        end

    elseif phase == "after_picker" then
        RespawnState.Timer += dt
        if RespawnState.Timer >= RESPAWN_AFTER_PICKER then
            log("RESPAWN", "done, resume farm")
            releaseChar(RespawnState.HoldChar or LocalPlayer.Character)
            RespawnState.Active = false
            RespawnState.Phase = "idle"
            RespawnState.Clicked = false
            RespawnState.ClickInitiated = false
            RespawnState.HoldChar = nil
            RespawnState.HoldCF = nil
            RespawnState.StartCF = nil
            RespawnState.LerpT = 0
            resetPlaneSelection()
        end
    end
end

local function findVehiclesFolder()
    local entities = workspace:FindFirstChild("Entities")
    if entities then
        for _, child in ipairs(entities:GetChildren()) do
            if child:IsA("Folder") and child.Name:match("^SpawnedVehicles_") then
                if ScanState.FolderName ~= child.Name then
                    ScanState.FolderName = child.Name
                    log("SCAN", "folder found: "..child.Name)
                end
                return child
            end
        end
    end
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Folder") and child.Name:match("^SpawnedVehicles_") then
            if ScanState.FolderName ~= child.Name then
                ScanState.FolderName = child.Name
                log("SCAN", "folder found at workspace root: "..child.Name)
            end
            return child
        end
    end
    return nil
end

local function getVehicleHitbox(model)
    if not model then return nil end
    local hb = model:FindFirstChild("Hitbox")
    if hb and hb:IsA("BasePart") then return hb end
    return nil
end

local function pickAimPart(model)
    if not model then return nil end
    local body = model:FindFirstChild("Body")
    if body and body:IsA("BasePart") then return body end
    local pp = model.PrimaryPart
    if pp and pp:IsA("BasePart") and pp.Name ~= "Hitbox" then return pp end
    for _, name in ipairs({"Root","Cockpit","Nose","Fuselage"}) do
        local p = model:FindFirstChild(name)
        if p and p:IsA("BasePart") and p.Name ~= "Hitbox" then return p end
    end
    local fallback
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= "Hitbox" then
            if d.CanCollide then return d end
            fallback = fallback or d
        end
    end
    return fallback or getVehicleHitbox(model)
end

local function vehicleRefPos(model)
    if not model then return nil end
    local body = model:FindFirstChild("Body")
    if body and body:IsA("BasePart") then return body.Position end
    if model == State.Vehicle and State.AimPart and State.AimPart.Parent then return State.AimPart.Position end
    local hb = getVehicleHitbox(model); if hb then return hb.Position end
    local pp = model.PrimaryPart; if pp then return pp.Position end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then return d.Position end
    end
    return nil
end

local function vehicleDistance(model)
    local pos = vehicleRefPos(model)
    if not pos then return math.huge end
    return (pos - getRefPosition()).Magnitude
end

local function modelFromInstance(inst, folder)
    if not inst then return nil end
    if not folder then return nil end
    if inst:IsDescendantOf(folder) then
        local cur = inst
        while cur and cur.Parent and cur.Parent ~= folder do
            cur = cur.Parent
        end
        if cur and cur.Parent == folder and cur:IsA("Model") then
            return cur
        end
    end
    return nil
end

local function getCameraVehicle(folder)
    if not folder then return nil end
    local now = os.clock()
    if State.CameraVehicle
       and State.CameraVehicle.Parent
       and (now - State.CameraVehicleT) < CAM_VEHICLE_TTL then
        return State.CameraVehicle
    end
    local subject = Camera and Camera.CameraSubject
    if not subject then return nil end
    local m = modelFromInstance(subject, folder)
    if m then
        State.CameraVehicle = m
        State.CameraVehicleT = now
        return m
    end
    return nil
end

-- === ownership detection (STRICT) ===

local function hasNetworkOwnership(model)
    if not model or not model.Parent then return false end
    local parts = {}
    local body = model:FindFirstChild("Body")
    if body and body:IsA("BasePart") then parts[#parts+1] = body end
    local hb = model:FindFirstChild("Hitbox")
    if hb and hb:IsA("BasePart") then parts[#parts+1] = hb end
    local pp = model.PrimaryPart
    if pp and pp:IsA("BasePart") and pp ~= body and pp ~= hb then parts[#parts+1] = pp end
    for _, d in ipairs(parts) do
        local ok, owner = pcall(function() return d:GetNetworkOwner() end)
        if ok and owner == LocalPlayer then return true end
    end
    return false
end

local function cameraOwnsVehicle(model)
    if not model or not model.Parent then return false end
    local subject = Camera and Camera.CameraSubject
    if not subject then return false end
    if not subject:IsDescendantOf(model) then return false end
    local refPart = model:FindFirstChild("Body")
    if not (refPart and refPart:IsA("BasePart")) then
        refPart = model.PrimaryPart
    end
    if refPart and refPart:IsA("BasePart") then
        local subjPos
        if subject:IsA("BasePart") then
            subjPos = subject.Position
        elseif subject:IsA("Model") then
            local sPP = subject.PrimaryPart
            if sPP then subjPos = sPP.Position end
        elseif subject:IsA("Humanoid") then
            local sRoot = subject.RootPart
            if sRoot then subjPos = sRoot.Position end
        end
        if subjPos then
            local d = (subjPos - refPart.Position).Magnitude
            if d > CAM_SUBJECT_MAX_DIST then return false end
        end
    end
    return true
end

local function detectOwnership(model)
    if not model or not model.Parent then return false, "no model" end

    if hasNetworkOwnership(model) then
        return true, "networkowner"
    end

    if cameraOwnsVehicle(model) then
        return true, "camera"
    end

    for name, value in pairs(model:GetAttributes()) do
        local low = tostring(name):lower()
        if low:find("owner") or low:find("player") or low:find("user")
           or low:find("creator") or low:find("driver") then
            if typeof(value) == "Instance" and value:IsA("Player") then
                if value == LocalPlayer then return true, "attr_instance:"..name end
            elseif type(value) == "string" then
                if value == LocalPlayer.Name then return true, "attr_name:"..name end
                if value == tostring(LocalPlayer.UserId) then return true, "attr_userid:"..name end
                local p = Players:FindFirstChild(value)
                if p and p == LocalPlayer then return true, "attr_find:"..name end
            elseif type(value) == "number" then
                if value == LocalPlayer.UserId then return true, "attr_num:"..name end
            end
        end
    end

    for _, d in ipairs(model:GetChildren()) do
        if d:IsA("ObjectValue") and d.Value and typeof(d.Value) == "Instance" and d.Value:IsA("Player") then
            if d.Value == LocalPlayer then return true, "child_obj:"..d.Name end
        elseif d:IsA("StringValue") then
            if d.Value == LocalPlayer.Name or d.Value == tostring(LocalPlayer.UserId) then
                return true, "child_str:"..d.Name
            end
            local p = Players:FindFirstChild(d.Value)
            if p and p == LocalPlayer then return true, "child_str_p:"..d.Name end
        elseif d:IsA("IntValue") or d:IsA("NumberValue") then
            if tonumber(d.Value) == LocalPlayer.UserId then return true, "child_num:"..d.Name end
        end
    end

    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("ObjectValue") and d.Value and typeof(d.Value) == "Instance" and d.Value:IsA("Player") then
            if d.Value == LocalPlayer then return true, "deep_obj:"..d.Name end
        elseif d:IsA("StringValue") then
            if d.Value == LocalPlayer.Name or d.Value == tostring(LocalPlayer.UserId) then
                return true, "deep_str:"..d.Name
            end
        elseif d:IsA("IntValue") or d:IsA("NumberValue") then
            if tonumber(d.Value) == LocalPlayer.UserId then return true, "deep_num:"..d.Name end
        end
    end

    local n = model.Name:lower()
    if n:find(LocalPlayer.Name:lower(), 1, true) then
        return true, "name_player"
    end
    if n:find(tostring(LocalPlayer.UserId), 1, true) then
        return true, "name_userid"
    end

    return false, "no signal"
end

local isMineCache  = setmetatable({}, { __mode = "k" })
local isMineCacheT = setmetatable({}, { __mode = "k" })

local function isMyVehicleStrict(model)
    if not model or not model.Parent then return false end

    local now = os.clock()
    local cached = isMineCache[model]
    if cached == true and (now - (isMineCacheT[model] or 0)) < OWNER_TTL then
        return true
    end

    local ok, reason = detectOwnership(model)
    if ok then
        isMineCache[model] = true
        isMineCacheT[model] = now
        if State.LastOwnerReason ~= reason then
            State.LastOwnerReason = reason
            log("LINK", "ownership via "..reason.." -> "..model.Name)
        end
        return true
    end

    isMineCache[model] = false
    isMineCacheT[model] = now
    return false
end

local function getOrientationObject(model)
    local cached = State.AlignCache[model]
    if cached and cached.Parent then return cached end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("AlignOrientation") then State.AlignCache[model] = d; return d end
    end
    return nil
end

local function getRiptidePivot(model)
    if not model or not model.Parent then return nil end
    if not model.Name:find("Riptide", 1, true) then return nil end
    local turrets = model:FindFirstChild("Turrets"); if not turrets then return nil end
    local rocket = turrets:FindFirstChild("RocketTurret"); if not rocket then return nil end
    local head = rocket:FindFirstChild("Head"); if not head then return nil end
    local pivot = head:FindFirstChild("Pivot")
    if pivot and pivot:IsA("BasePart") then return pivot end
    return nil
end

local function isLinkedVehicleAlive(model)
    if not model or not model.Parent then return false end
    if not State.AimPart or not State.AimPart.Parent then
        State.AimPart = pickAimPart(model)
    end
    if not State.AimPart then return false end
    if vehicleDistance(model) > MAX_DISTANCE then return false end
    return true
end

local function findMyVehicle(folder)
    if not folder then return nil end

    local best, bestDist
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            if isMyVehicleStrict(child) then
                local d = vehicleDistance(child)
                if not bestDist or d < bestDist then
                    best, bestDist = child, d
                end
            end
        end
    end
    if best then
        if ScanState.LastLogT == 0 or (os.clock() - ScanState.LastLogT) > 2 then
            ScanState.LastLogT = os.clock()
            log("SCAN", "found: "..best.Name)
        end
    end
    return best
end

local function diagScan(folder)
    if not folder then return end
    local now = os.clock()
    if now - ScanState.LastScanT < 3 then return end
    ScanState.LastScanT = now
    local total = 0
    local myCount = 0
    local closest = math.huge
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            total += 1
            if isMyVehicleStrict(child) then myCount += 1 end
            local d = vehicleDistance(child)
            if d < closest then closest = d end
        end
    end
    local camInfo = "nil"
    if Camera and Camera.CameraSubject then
        camInfo = Camera.CameraSubject:GetFullName()
    end
    log("SCAN", ("models=%d mine=%d closest=%.1f camSubject=%s"):format(total, myCount, closest, camInfo))
end

local pingCache = { value=0, jitter=0, t=0 }
local pingSamples = {}
local function readPingSeconds()
    local okS, ms = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    if okS and type(ms) == "number" and ms > 0 then return ms/1000 end
    local p = 0
    pcall(function() p = LocalPlayer:GetNetworkPing() end)
    if type(p) == "number" and p > 0 then return p*2 end
    return 0
end
local function updatePing()
    local v = readPingSeconds()
    table.insert(pingSamples, v)
    while #pingSamples > 10 do table.remove(pingSamples, 1) end
    local sum = 0; for _, s in ipairs(pingSamples) do sum += s end
    local mean = sum / math.max(1, #pingSamples)
    local var = 0; for _, s in ipairs(pingSamples) do var += (s-mean)^2 end
    var = var / math.max(1, #pingSamples)
    pingCache.value = mean; pingCache.jitter = math.sqrt(var)
end
local function getPredictionTime()
    local now = os.clock()
    if now - pingCache.t > PING_CACHE_TTL then updatePing(); pingCache.t = now end
    return math.clamp(pingCache.value + PRED_LEAD_BASE + pingCache.jitter * 0.5, 0, PRED_MAX_TIME)
end

local Predictor = { history = setmetatable({}, { __mode = "k" }) }
function Predictor.update(model, pos)
    if not model or not pos then return end
    local h = Predictor.history[model]
    if not h then h = { samples = {} }; Predictor.history[model] = h end
    local now = os.clock()
    local last = h.samples[#h.samples]
    if last and (now - last.t) < PRED_MIN_DT then last.pos = pos; return end
    h.samples[#h.samples+1] = { t = now, pos = pos }
    while #h.samples > PRED_MAX_SAMPLES do table.remove(h.samples, 1) end
end
function Predictor.estimate(model)
    local h = Predictor.history[model]
    if not h or #h.samples < 2 then return nil, nil, nil end
    local samples = h.samples
    local n = #samples
    local wsum = 0; local w = {}
    for i = 1, n do
        local age = n - i
        local weight = PRED_RECENCY ^ age
        w[i] = weight; wsum += weight
    end
    if wsum <= 0 then return samples[n].pos, Vector3.zero, Vector3.zero end
    local tMean = 0; local pMean = Vector3.zero
    for i = 1, n do tMean += w[i]*samples[i].t; pMean += samples[i].pos*w[i] end
    tMean /= wsum; pMean /= wsum
    local numV, denV = Vector3.zero, 0
    for i = 1, n do
        local dt = samples[i].t - tMean
        numV += (samples[i].pos - pMean)*(w[i]*dt)
        denV += w[i]*dt*dt
    end
    local vel = denV > 1e-6 and (numV/denV) or Vector3.zero
    local acc = Vector3.zero
    if n >= 4 then
        local numA, denA = Vector3.zero, 0
        for i = 1, n do
            local dt = samples[i].t - tMean
            local resid = samples[i].pos - (pMean + vel*dt)
            numA += resid*(w[i]*dt*dt)
            denA += w[i]*dt^4
        end
        if denA > 1e-6 then acc = numA/denA*2 end
    end
    return pMean, vel, acc
end
function Predictor.predict(model)
    local p0, vel, acc = Predictor.estimate(model)
    if not p0 then
        local h = Predictor.history[model]
        if h and #h.samples > 0 then return h.samples[#h.samples].pos, nil, nil end
        return nil, nil, nil
    end
    local T = getPredictionTime()
    local pos = p0; local v = vel; local a = acc
    for _ = 1, 2 do
        pos = p0 + v*T + 0.5*a*T*T
        v = v + a*T*0.5
        a = a*0.9
    end
    return pos, vel, acc
end

local function getNativeHighlight(model)
    if not model then return nil end
    local h = model:FindFirstChild("Highlight")
    if h and h:IsA("Highlight") then return h end
    for _, d in ipairs(model:GetDescendants()) do if d:IsA("Highlight") then return d end end
    return nil
end
local function colorMatches(c, tR, tG, tB, tol)
    if not c then return false end
    tol = tol or 0.08
    return math.abs(c.R - tR) <= tol and math.abs(c.G - tG) <= tol and math.abs(c.B - tB) <= tol
end
local function classifyVehicleColor(model)
    local hl = getNativeHighlight(model)
    if not hl then return "unknown", nil, nil, nil end
    local outline = hl.OutlineColor
    if colorMatches(outline, 1, 0, 0) then return "enemy", hl.FillColor, outline, "Highlight" end
    if colorMatches(outline, 0, 1, 0) then return "ally",  hl.FillColor, outline, "Highlight" end
    local r, g, b = outline.R, outline.G, outline.B
    if r > g*1.25 and r > b*1.25 then return "enemy", hl.FillColor, outline, "Highlight" end
    if g > r*1.25 and g > b*1.25 then return "ally",  hl.FillColor, outline, "Highlight" end
    return "unknown", hl.FillColor, outline, "Highlight"
end

local function espApply(model, hl)
    if not hl or EspState.Applied[model] then return end
    EspState.Applied[model] = { hl=hl, depth=hl.DepthMode, fill=hl.FillTransparency }
    hl.DepthMode = ESP_DEPTH_MODE
    hl.FillTransparency = ESP_FILL_TRANSPARENCY
end
local function espRevert(model)
    local rec = EspState.Applied[model]; if not rec then return end
    local hl = rec.hl
    if hl and hl.Parent then hl.DepthMode = rec.depth; hl.FillTransparency = rec.fill end
    EspState.Applied[model] = nil
end
local function espRevertAll() for m in pairs(EspState.Applied) do espRevert(m) end end
local function espUpdate()
    if not EspState.Enabled then espRevertAll(); return end
    local folder = findVehiclesFolder(); if not folder then return end
    local seen = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") and child ~= State.Vehicle and child.Parent then
            local kind = classifyVehicleColor(child)
            if kind == "enemy" then
                local hl = getNativeHighlight(child)
                if hl then seen[child] = true; espApply(child, hl) end
            end
        end
    end
    for m in pairs(EspState.Applied) do if not seen[m] or not m.Parent then espRevert(m) end end
end

local function computeMoveDirection()
    local model = State.Vehicle; if not model or not model.Parent then return nil end
    local ref = State.AimPart
    if not ref or not ref.Parent then ref = model:FindFirstChild("Body") or model.PrimaryPart end
    if not ref or not ref:IsA("BasePart") then return nil end
    local cf = ref.CFrame
    local fwd, right = cf.LookVector, cf.RightVector
    local dir = Vector3.zero
    if SpeedState.W then dir += fwd end
    if SpeedState.S then dir -= fwd end
    if SpeedState.D then dir += right end
    if SpeedState.A then dir -= right end
    if dir.Magnitude < 1e-3 then return nil end
    return dir.Unit
end
local function speedHackUpdate(dt)
    if not SpeedState.Enabled or SpeedState.SPS <= 0 then SpeedState.LastPos = nil; return end
    if not isMoveKeyActive() then SpeedState.LastPos = nil; return end
    local model = State.Vehicle; if not model or not model.Parent then SpeedState.LastPos = nil; return end
    local part = State.AimPart
    if not part or not part.Parent then State.AimPart = pickAimPart(model); part = State.AimPart end
    if not part then return end
    local dir = computeMoveDirection(); if not dir then SpeedState.LastPos = nil; return end
    local step = dir * (SpeedState.SPS * dt)
    local goalCF = part.CFrame + step
    part.CFrame = part.CFrame:Lerp(goalCF, 1)
end

local function getTargetBody(model)
    if not model or not model.Parent then return nil end
    local body = model:FindFirstChild("Body")
    if body and body:IsA("BasePart") then return body end
    local pp = model.PrimaryPart
    if pp and pp:IsA("BasePart") and pp.Name ~= "Hitbox" then return pp end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= "Hitbox" then return d end
    end
    return getVehicleHitbox(model)
end
local function getTargetNose(model)
    local base = getTargetBody(model); if not base then return nil, nil end
    local look = base.CFrame.LookVector
    return base.Position + look * (base.Size.Z * 0.5 + 2), look
end
local function ensureFovBall()
    if AutoKillState.FovBall and AutoKillState.FovBall.Parent then return AutoKillState.FovBall end
    local ball = Instance.new("Part")
    ball.Name = "AimAssist_FOVBall"; ball.Shape = Enum.PartType.Ball
    ball.Size = Vector3.new(FOV_BALL_BASE_RADIUS*2,FOV_BALL_BASE_RADIUS*2,FOV_BALL_BASE_RADIUS*2)
    ball.Anchored = true; ball.CanCollide = false; ball.CanQuery = false; ball.CanTouch = false
    ball.Massless = true; ball.CastShadow = false
    ball.Material = Enum.Material.Neon; ball.Color = FOV_BALL_COLOR; ball.Transparency = FOV_BALL_TRANSPARENCY
    ball.Parent = workspace
    AutoKillState.FovBall = ball
    return ball
end
local function destroyFovBall()
    if AutoKillState.FovBall and AutoKillState.FovBall.Parent then AutoKillState.FovBall:Destroy() end
    AutoKillState.FovBall = nil
end
local function updateFovBall()
    if not AutoKillState.Enabled then destroyFovBall(); return end
    local target = AutoKillState.Target; if not target or not target.Parent then destroyFovBall(); return end
    local nose = getTargetNose(target); if not nose then destroyFovBall(); return end
    local ball = ensureFovBall()
    local myPos = State.AimPart and State.AimPart.Position or getRefPosition()
    local dist = (nose - myPos).Magnitude
    local radius = math.clamp(dist*0.35, FOV_BALL_BASE_RADIUS, 120)
    ball.Size = Vector3.new(radius*2,radius*2,radius*2); ball.CFrame = CFrame.new(nose)
end
local function pickRandomEnemyTarget()
    local folder = findVehiclesFolder(); if not folder then return nil end
    local list = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") and child ~= State.Vehicle and child.Parent then
            if classifyVehicleColor(child) == "enemy" and getVehicleHitbox(child) then list[#list+1] = child end
        end
    end
    if #list == 0 then return nil end
    local chosen = list[math.random(1, #list)]
    log("FARM", "new target: "..chosen.Name)
    return chosen
end
local function isTargetAlive(model, dt)
    if not model or not model.Parent then return false end
    local ref = getTargetBody(model); if not ref or not ref.Parent then return false end
    local pos = ref.Position
    if AutoKillState.LastTargetPos then
        local moved = (pos - AutoKillState.LastTargetPos).Magnitude
        local minVel = AUTOKILL_DEAD_MOVE_MIN / AUTOKILL_DEAD_TIMEOUT
        if moved / math.max(dt, 1e-4) < minVel then AutoKillState.TargetIdleT += dt
        else AutoKillState.TargetIdleT = 0 end
    end
    AutoKillState.LastTargetPos = pos
    if AutoKillState.TargetIdleT >= AUTOKILL_DEAD_TIMEOUT then return false end
    return true
end
local function disableOurCollisions()
    local model = State.Vehicle; if not model then return end
    AutoKillState.SavedCollide = {}
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") and d.CanCollide then
            table.insert(AutoKillState.SavedCollide, {part=d, canCollide=true})
            d.CanCollide = false
        end
    end
end
local function restoreOurCollisions()
    if not AutoKillState.SavedCollide then return end
    for _, rec in ipairs(AutoKillState.SavedCollide) do
        if rec.part and rec.part.Parent then rec.part.CanCollide = rec.canCollide end
    end
    AutoKillState.SavedCollide = nil
end
local function isEnemyLineClear(origin, lookDir, maxDist, targetModel)
    local folder = findVehiclesFolder(); if not folder then return true end
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") and child ~= State.Vehicle and child ~= targetModel and child.Parent then
            local body = getTargetBody(child)
            if body then
                local toB = body.Position - origin
                local along = toB:Dot(lookDir)
                if along > 1 and along < maxDist then
                    local perp = (toB - lookDir*along).Magnitude
                    if perp < (body.Size.Magnitude*0.5 + AUTOKILL_LINE_CLEAR_MARG) then return false end
                end
            end
        end
    end
    return true
end
local function resetAutoKillTarget()
    if AutoKillState.FirePhase == "holding" then
        task.spawn(releaseDown)
    end
    AutoKillState.Target = nil; AutoKillState.LastTargetPos = nil
    AutoKillState.TargetIdleT = 0
    AutoKillState.FirePhase = "idle"
    AutoKillState.FireTimer = 0
    AutoKillState.LastTargetName = nil; AutoKillState.LastCanFire = nil
    AutoKillState.TargetBehindSign = 0
    AutoKillState.SmoothedTargetPos = nil
    AutoKillState.SmoothedOurPos = nil
    AutoKillState.TargetSize = 0
end

local function pressPlaneQ()
    task.spawn(function()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Q, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end)
    end)
end

local function getPlaneName()
    local model = State.Vehicle
    if not model or not model.Parent then return nil end
    local n = model.Name
    for _, plane in ipairs(PLANE_PRIORITY) do
        if n:find(plane, 1, true) then return plane end
    end
    return nil
end

local function autoKillUpdate(dt)
    if not AutoKillState.Enabled then return end

    if hasOurVehicle() then
        State.NoVehicleSince = 0
    else
        if State.NoVehicleSince == 0 then
            State.NoVehicleSince = os.clock()
        end
    end
    local noVehicleDur = State.NoVehicleSince > 0 and (os.clock() - State.NoVehicleSince) or 0
    local timeInGame = os.clock() - State.JoinTime
    local readyToAct = timeInGame > RESPAWN_JOIN_GRACE

    if RespawnState.Active then
        updateRespawnFlow(dt)
        return
    end

    local respawnBtn = getRespawnButton()
    local pickerVisible = getVehiclePickerButton() ~= nil

    local shouldRespawn =
        respawnBtn ~= nil
        or (readyToAct and not pickerVisible and noVehicleDur > RESPAWN_NO_VEHICLE_DELAY)

    if shouldRespawn then
        if AutoKillState.FirePhase == "holding" then
            task.spawn(releaseDown)
            AutoKillState.FirePhase = "idle"
            AutoKillState.FireTimer = 0
        end
        startRespawnFlow()
        return
    end

    local model = State.Vehicle
    if not model or not model.Parent then return end
    local part = State.AimPart
    if not part or not part.Parent then State.AimPart = pickAimPart(model); part = State.AimPart end
    if not part then return end

    local plane = getPlaneName()
    if plane == "Striker" or plane == "Phantom" then
        AutoKillState.QTimer += dt
        local interval = (plane == "Striker") and 5 or 3
        if AutoKillState.QTimer >= interval then
            AutoKillState.QTimer = 0
            pressPlaneQ()
            log("FARM", "pressed Q ("..plane..", every "..interval.."s)")
        end
    else
        AutoKillState.QTimer = 0
    end

    if AutoKillState.Target and not isTargetAlive(AutoKillState.Target, dt) then
        resetAutoKillTarget(); destroyFovBall(); restoreOurCollisions()
    end
    if not AutoKillState.Target then
        AutoKillState.Target = pickRandomEnemyTarget()
        AutoKillState.LastTargetPos = nil; AutoKillState.TargetIdleT = 0
        AutoKillState.TargetBehindSign = 0
        AutoKillState.SmoothedTargetPos = nil
        if AutoKillState.Target then
            AutoKillState.LastTargetName = AutoKillState.Target.Name
            disableOurCollisions()
        end
    end
    local target = AutoKillState.Target
    if not target or not target.Parent then return end

    local targetBody = getTargetBody(target); if not targetBody then return end
    local rawTargetPos = targetBody.Position
    local targetLook = targetBody.CFrame.LookVector
    AutoKillState.TargetSize = targetBody.Size.Z

    Predictor.update(target, rawTargetPos)

    if not AutoKillState.SmoothedTargetPos then
        AutoKillState.SmoothedTargetPos = rawTargetPos
    else
        AutoKillState.SmoothedTargetPos = AutoKillState.SmoothedTargetPos:Lerp(rawTargetPos, AUTOKILL_TARGET_SMOOTH)
    end
    local targetPos = AutoKillState.SmoothedTargetPos

    if AutoKillState.TargetBehindSign == 0 then
        local noseProbe = targetPos + targetLook * (AutoKillState.TargetSize * 0.5 + 2)
        local dotA = ((noseProbe - targetLook * AUTOKILL_BEHIND_DIST) - noseProbe).Unit:Dot(targetLook)
        local dotB = ((noseProbe + targetLook * AUTOKILL_BEHIND_DIST) - noseProbe).Unit:Dot(targetLook)
        AutoKillState.TargetBehindSign = (dotA < dotB) and 1 or -1
        log("FARM", "behind sign="..AutoKillState.TargetBehindSign)
    end
    local sign = AutoKillState.TargetBehindSign
    local nose = targetPos + targetLook * (AutoKillState.TargetSize * 0.5 + 2)
    local behind = nose - targetLook * AUTOKILL_BEHIND_DIST * sign + Vector3.new(0, AUTOKILL_LIFT, 0)

    if not AutoKillState.SmoothedOurPos then
        AutoKillState.SmoothedOurPos = behind
    else
        AutoKillState.SmoothedOurPos = AutoKillState.SmoothedOurPos:Lerp(behind, AUTOKILL_POS_SMOOTH)
    end
    local ourPos = AutoKillState.SmoothedOurPos

    local goalCF = CFrame.lookAt(ourPos, targetPos)
    part.CFrame = goalCF
    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero
    local root = model.PrimaryPart
    if root and root ~= part then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    local lookDir = goalCF.LookVector
    local origin = ourPos
    local toTargetDist = (targetPos - origin).Magnitude
    local enemyClear = isEnemyLineClear(origin, lookDir, toTargetDist, target)

    if enemyClear ~= AutoKillState.LastCanFire then
        AutoKillState.LastCanFire = enemyClear
        log("FARM", enemyClear and "line clear" or "line blocked")
    end

    if enemyClear then
        if AutoKillState.FirePhase == "idle" then
            AutoKillState.FirePhase = "holding"
            AutoKillState.FireTimer = 0
            task.spawn(pressDown)
            log("FARM", "hold start")
        elseif AutoKillState.FirePhase == "holding" then
            AutoKillState.FireTimer += dt
            if AutoKillState.FireTimer >= AUTOKILL_FIRE_HOLD then
                AutoKillState.FirePhase = "gap"
                AutoKillState.FireTimer = 0
                task.spawn(releaseDown)
                log("FARM", "hold end")
            end
        elseif AutoKillState.FirePhase == "gap" then
            AutoKillState.FireTimer += dt
            if AutoKillState.FireTimer >= AUTOKILL_FIRE_GAP then
                AutoKillState.FirePhase = "idle"
                AutoKillState.FireTimer = 0
            end
        end
    else
        if AutoKillState.FirePhase == "holding" then
            task.spawn(releaseDown)
            log("FARM", "line blocked, release")
        end
        AutoKillState.FirePhase = "idle"
        AutoKillState.FireTimer = 0
    end

    updateFovBall()
end

local function rageAim()
    local model = State.Vehicle; if not model or not model.Parent then return end
    local riptidePivot = getRiptidePivot(model)
    local part
    if riptidePivot then part = riptidePivot
    else
        part = State.AimPart
        if not part or not part.Parent then State.AimPart = pickAimPart(model); part = State.AimPart end
    end
    if not part then return end
    local target = selectTarget(false); if not target then return end
    local posP = part.Position
    local toT = target.aimPos - posP
    if toT.Magnitude < 1e-3 then return end
    local goalCF = CFrame.lookAt(posP, target.aimPos)
    if not riptidePivot then
        local ao = getOrientationObject(model)
        if ao then ao.CFrame = goalCF; return end
    end
    local curCF = part.CFrame
    local dot = math.clamp(curCF.LookVector:Dot(goalCF.LookVector), -1, 1)
    local ang = math.acos(dot)
    if ang < math.rad(RAGE_DEADZONE_DEG) then return end
    local maxRad = math.rad(RAGE_MAX_DEG_PER_FRAME)
    local alpha = RAGE_SMOOTH_ALPHA
    if ang > maxRad then alpha = math.min(alpha, maxRad / ang) end
    part.CFrame = curCF:Lerp(goalCF, alpha)
end

function getTargetsList()
    local folder = findVehiclesFolder(); if not folder then return {} end
    local list = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") and child ~= State.Vehicle and child.Parent then
            if classifyVehicleColor(child) == "enemy" then
                local part = getVehicleHitbox(child) or child.PrimaryPart
                if part then
                    Predictor.update(child, part.Position)
                    local predicted, vel, acc = Predictor.predict(child)
                    list[#list+1] = {
                        model=child, part=part, position=part.Position,
                        aimPos=predicted or part.Position, velocity=vel, accel=acc,
                    }
                end
            end
        end
    end
    return list
end

local frameId = 0
local cache = { id = -1, result = nil }
function selectTarget(applyFov)
    if cache.id == frameId then return cache.result end
    local targets = getTargetsList()
    local now = os.clock()
    if State.LockedTarget and (now - State.LockedTargetT) < TARGET_LOCK_TIME then
        for _, t in ipairs(targets) do
            if t.model == State.LockedTarget and t.model.Parent then
                cache.id = frameId; cache.result = t; return t
            end
        end
        State.LockedTarget = nil
    end
    local result = nil
    if #targets > 0 then
        local camPos, lookDir = Camera.CFrame.Position, Camera.CFrame.LookVector
        local function inFov(t)
            if not applyFov then return true end
            local toT = t.position - camPos
            if toT.Magnitude < 1e-3 then return false end
            local ang = math.deg(math.acos(math.clamp(lookDir:Dot(toT.Unit), -1, 1)))
            return ang <= HALF_FOV
        end
        if State.Priority == "Mouse" then
            local mouse2D = UserInputService:GetMouseLocation()
            local best, bestVal
            for _, t in ipairs(targets) do
                if inFov(t) then
                    local sp, onScreen = Camera:WorldToScreenPoint(t.position)
                    if onScreen then
                        local v = (Vector2.new(sp.X, sp.Y) - mouse2D).Magnitude
                        if not bestVal or v < bestVal then best, bestVal = t, v end
                    end
                end
            end
            result = best
        else
            local best, bestVal
            for _, t in ipairs(targets) do
                if inFov(t) then
                    local v = (t.position - camPos).Magnitude
                    if not bestVal or v < bestVal then best, bestVal = t, v end
                end
            end
            result = best
        end
    end
    if result then State.LockedTarget = result.model; State.LockedTargetT = now end
    cache.id = frameId; cache.result = result
    return result
end

local mouseHook = { installed = false, mt = nil, originalIndex = nil }
local function callOriginal(self, key)
    local orig = mouseHook.originalIndex
    if type(orig) == "function" then return orig(self, key)
    elseif type(orig) == "table" then return orig[key] end
    return nil
end
local function installMouseHook()
    if mouseHook.installed or State.Destroyed then return end
    local mt = getrawmetatable(Mouse)
    if not mt then warn("[AA][CORE] Mouse has no metatable"); return end
    mouseHook.mt = mt; mouseHook.originalIndex = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if self == Mouse and not State.Destroyed and State.Linked and isAimBotActive()
           and State.Mode == "Legit" and not AutoKillState.Enabled then
            if key == "Hit" then
                local t = selectTarget(true); if t then return CFrame.new(t.aimPos) end
            elseif key == "Target" then
                local t = selectTarget(true); if t then return t.part end
            elseif key == "UnitRay" then
                local t = selectTarget(true)
                if t then
                    local origin = Camera.CFrame.Position
                    local dir = t.aimPos - origin
                    if dir.Magnitude < 1e-3 then dir = Camera.CFrame.LookVector else dir = dir.Unit end
                    return Ray.new(origin, dir)
                end
            end
        end
        return callOriginal(self, key)
    end)
    setreadonly(mt, true)
    mouseHook.installed = true
end
local function uninstallMouseHook()
    if not mouseHook.installed then return end
    if mouseHook.mt then
        setreadonly(mouseHook.mt, false)
        mouseHook.mt.__index = mouseHook.originalIndex
        setreadonly(mouseHook.mt, true)
    end
    mouseHook.installed = false
end
installMouseHook()

local function updateFovCircle()
    local active = State.Linked and isAimBotActive() and State.Mode == "Legit"
                   and not State.Destroyed and not AutoKillState.Enabled
    if not active then
        if fovCircle.Visible then fovCircle.Visible = false end
        return
    end
    fovCircle.Visible = true
    local halfFovRad = math.rad(HALF_FOV)
    local camHalfFovRad = math.rad(Camera.FieldOfView / 2)
    local screenH = Camera.ViewportSize.Y
    if screenH <= 0 then return end
    local radius = (screenH/2)*math.tan(halfFovRad)/math.tan(camHalfFovRad)
    local cap = math.max(Camera.ViewportSize.X, Camera.ViewportSize.Y)
    radius = math.min(radius, cap)
    fovCircle.Size = UDim2.new(0, radius*2, 0, radius*2)
end

local function destroyAll()
    if State.Destroyed then return end
    State.Destroyed = true
    log("CORE", "unload")
    AutoKillState.Enabled = false
    if AutoKillState.FirePhase == "holding" then
        task.spawn(releaseDown)
        AutoKillState.FirePhase = "idle"
    end
    restoreCharCollision()
    if RespawnState.HoldChar then releaseChar(RespawnState.HoldChar) end
    destroyFovBall()
    restoreOurCollisions()
    espRevertAll()
    State.Linked = false; State.Vehicle = nil; State.AimPart = nil
    State.AimBot = false; State.AimBotHeld = false; State.LockedTarget = nil
    EspState.Enabled = false; SpeedState.Enabled = false
    SpeedState.W = false; SpeedState.A = false; SpeedState.S = false; SpeedState.D = false
    uninstallMouseHook()
    RunService:UnbindFromRenderStep("AimAssist_Update")
    screenGui:Destroy()
    fovGui:Destroy()
end

closeBtn.MouseButton1Click:Connect(destroyAll)
modeBtn.MouseButton1Click:Connect(function()
    State.Mode = (State.Mode == "Rage") and "Legit" or "Rage"
    modeBtn.Text = "Mode: "..State.Mode
    if modeBadge then modeBadge.Visible = (State.Mode == "Rage") end
end)
aimbotBtn.MouseButton1Click:Connect(function()
    State.AimBot = not State.AimBot
    aimbotBtn.Text = "AimBot: "..(State.AimBot and "ON" or "OFF")
end)
priorityBtn.MouseButton1Click:Connect(function()
    State.Priority = (State.Priority == "Distance") and "Mouse" or "Distance"
    priorityBtn.Text = "Priority: "..State.Priority
end)
espBtn.MouseButton1Click:Connect(function()
    EspState.Enabled = not EspState.Enabled
    espBtn.Text = "ESP: "..(EspState.Enabled and "ON" or "OFF")
    if not EspState.Enabled then espRevertAll() end
end)
speedBtn.MouseButton1Click:Connect(function()
    SpeedState.Enabled = not SpeedState.Enabled
    speedBtn.Text = "SpeedHack: "..(SpeedState.Enabled and "ON" or "OFF")
end)
autoFarmBtn.MouseButton1Click:Connect(function()
    AutoKillState.Enabled = not AutoKillState.Enabled
    if AutoKillState.Enabled then
        autoFarmBtn.Text = "AUTO FARM: ON"
        autoFarmBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        resetAutoKillTarget()
        AutoKillState.QTimer = 0
        State.NoVehicleSince = 0
        log("FARM", "enabled (hold "..AUTOKILL_FIRE_HOLD.."s / gap "..AUTOKILL_FIRE_GAP.."s)")
    else
        autoFarmBtn.Text = "AUTO FARM: OFF"
        autoFarmBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
        resetAutoKillTarget()
        AutoKillState.QTimer = 0
        restoreCharCollision()
        if RespawnState.HoldChar then releaseChar(RespawnState.HoldChar) end
        RespawnState.Active = false
        RespawnState.Phase = "idle"
        RespawnState.HoldChar = nil
        RespawnState.HoldCF = nil
        RespawnState.StartCF = nil
        RespawnState.LerpT = 0
        RespawnState.ClickInitiated = false
        resetPlaneSelection()
        State.NoVehicleSince = 0
        destroyFovBall(); restoreOurCollisions()
        log("FARM", "disabled")
    end
end)

RunService:BindToRenderStep("AimAssist_Update", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if State.Destroyed then return end
    frameId += 1

    local folder = findVehiclesFolder()
    if State.Vehicle and isLinkedVehicleAlive(State.Vehicle) then
    else
        if State.Linked and State.Vehicle then
            log("LINK", "Lost!")
            State.Linked = false; State.Vehicle = nil; State.AimPart = nil
            State.LockedTarget = nil; SpeedState.LastPos = nil
            titleBar.Text = "Aim Assist - Waiting..."
            statusLbl.Text = "Status: Lost"
            statusLbl.TextColor3 = Color3.fromRGB(230, 120, 120)
            if AutoKillState.Target then
                resetAutoKillTarget()
                destroyFovBall()
                restoreOurCollisions()
            end
        end
        local candidate = findMyVehicle(folder)
        if candidate and isLinkedVehicleAlive(candidate) then
            State.Vehicle = candidate; State.AimPart = pickAimPart(candidate); State.Linked = true
            log("LINK", "Linked! -> "..candidate.Name)
            titleBar.Text = "Aim Assist - Linked"
            statusLbl.Text = "Status: Linked ("..candidate.Name..")"
            statusLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
        else
            diagScan(folder)
        end
    end

    if AutoKillState.Enabled then autoKillUpdate(dt)
    else
        if State.Linked and isAimBotActive() and State.Mode == "Rage" then rageAim() end
        if State.Linked then speedHackUpdate(dt) end
    end
    espUpdate()
    updateFovCircle()
    if State.AimBotHeld and not State.AimBot then aimbotBtn.Text = "AimBot: [C]"
    elseif not State.AimBotHeld and not State.AimBot then aimbotBtn.Text = "AimBot: OFF"
    elseif State.AimBot and not State.AimBotHeld then aimbotBtn.Text = "AimBot: ON"
    else aimbotBtn.Text = "AimBot: [C] ON" end
end)

log("CORE", "Loaded.")
