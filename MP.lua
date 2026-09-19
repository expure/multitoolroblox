local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local RemoteFolder = ReplicatedStorage:WaitForChild("Remote")
local NpcFolder = RemoteFolder:WaitForChild("NPC")
local InteractEvent = NpcFolder:WaitForChild("Interact")
local NpcHoldEvent = RemoteFolder:WaitForChild("NpcHold")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Regions = Assets:WaitForChild("Regions")
local City = Regions:WaitForChild("City")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoHelperGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 210, 0, 132)
frame.Position = UDim2.new(0, 20, 0, 200)
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -26, 0, 26)
title.BackgroundTransparency = 1
title.Text = "Auto Helper"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.new(0, 10, 0, 0)
title.Parent = frame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 22, 0, 22)
closeButton.Position = UDim2.new(1, -26, 0, 4)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.BorderSizePixel = 0
closeButton.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 18)
statusLabel.Position = UDim2.new(0, 10, 0, 24)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: idle"
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local toggleJail = Instance.new("TextButton")
toggleJail.Size = UDim2.new(1, -20, 0, 32)
toggleJail.Position = UDim2.new(0, 10, 0, 48)
toggleJail.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
toggleJail.Text = "Auto Jail: OFF"
toggleJail.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleJail.Font = Enum.Font.GothamBold
toggleJail.TextSize = 14
toggleJail.BorderSizePixel = 0
toggleJail.Parent = frame

local toggleJailCorner = Instance.new("UICorner")
toggleJailCorner.CornerRadius = UDim.new(0, 6)
toggleJailCorner.Parent = toggleJail

local toggleClean = Instance.new("TextButton")
toggleClean.Size = UDim2.new(1, -20, 0, 32)
toggleClean.Position = UDim2.new(0, 10, 0, 86)
toggleClean.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
toggleClean.Text = "Auto Clean: OFF"
toggleClean.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleClean.Font = Enum.Font.GothamBold
toggleClean.TextSize = 14
toggleClean.BorderSizePixel = 0
toggleClean.Parent = frame

local toggleCleanCorner = Instance.new("UICorner")
toggleCleanCorner.CornerRadius = UDim.new(0, 6)
toggleCleanCorner.Parent = toggleClean

local dragging = false
local dragStart = nil
local startPos = nil

local function beginDrag(input)
    dragging = true
    dragStart = input.Position
    startPos = frame.Position
end

local function updateDrag(input)
    if not dragging then return end
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

local function endDrag()
    dragging = false
end

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        beginDrag(input)
    end
end)

title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        endDrag()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        endDrag()
    end
end)

local MIN_DIST_FROM_CONCRETE = 100
local MAX_DIST_FROM_CITY = 150
local REQUIRED_TAG = "SmallSecurity"

local SPAWN_SCAN_TIMEOUT = 6
local SCAN_INTERVAL = 0.25
local GRAB_DELAY = 0.5
local ARRIVE_DISTANCE = 3

local FLY_SPEED = 30
local FLY_UPDATE_RATE = 55

local HRP_HEIGHT = 3
local GROUND_RAY_UP = 3
local GROUND_RAY_DOWN = 50

local CLEAN_GARBAGE_THRESHOLD = 6
local CLEAN_TUNNEL_THRESHOLD = 2

local autoJail = false
local autoClean = false
local loopRunning = false
local noclipRunning = false
local isFlying = false

local cityParts = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function setStatus(text)
    statusLabel.Text = "Status: " .. text
end

local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildWhichIsA("Humanoid")
end

local function uprightCFrame(pos, lookDir)
    local flat = Vector3.new(lookDir.X, 0, lookDir.Z)
    if flat.Magnitude < 1e-4 then
        flat = Vector3.new(0, 0, -1)
    end
    return CFrame.lookAt(pos, pos + flat.Unit)
end

local function getYaw(cf)
    local _, y = cf:ToEulerAnglesYXZ()
    return y
end

local function disableCollisions(char)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function startNoclipLoop()
    if noclipRunning then return end
    noclipRunning = true

    task.spawn(function()
        while noclipRunning do
            local char = LocalPlayer.Character
            if char then
                disableCollisions(char)
            end
            RunService.Stepped:Wait()
        end
    end)
end

local function stopNoclipLoop()
    noclipRunning = false
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

local function updateNoclip()
    if autoJail or autoClean then
        startNoclipLoop()
    else
        stopNoclipLoop()
    end
end

local function setFlyPhysics(state)
    local humanoid = getHumanoid()
    local hrp = getHRP()
    if humanoid then
        humanoid.PlatformStand = state
        humanoid.AutoRotate = not state
    end
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function setHRPPosition(hrp, cf)
    hrp.CFrame = cf
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local function collectParts(root, out)
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(out, child)
        elseif child:IsA("Model") or child:IsA("Folder") then
            collectParts(child, out)
        end
    end
end

collectParts(City, cityParts)

local function isNearCity(pos)
    for _, part in ipairs(cityParts) do
        if part.Parent then
            if (part.Position - pos).Magnitude <= MAX_DIST_FROM_CITY then
                return true
            end
        end
    end
    return false
end

local function lerpTo(targetPos, arriveDist)
    arriveDist = arriveDist or ARRIVE_DISTANCE

    local hrp = getHRP()
    if not hrp then return false end

    local startPos = hrp.Position
    local diff = targetPos - startPos
    local distance = diff.Magnitude

    if distance <= arriveDist then
        return true
    end

    local dir = diff.Unit
    local stepTime = 1 / FLY_UPDATE_RATE
    local traveled = 0
    local acc = 0
    local endDist = distance - arriveDist

    isFlying = true
    setFlyPhysics(true)

    while traveled < endDist and (autoJail or autoClean) do
        local dt = RunService.Heartbeat:Wait()
        acc = acc + dt

        hrp = getHRP()
        if not hrp then break end

        while acc >= stepTime and traveled < endDist do
            acc = acc - stepTime
            traveled = math.min(traveled + FLY_SPEED * stepTime, endDist)
            local newPos = startPos + dir * traveled
            setHRPPosition(hrp, uprightCFrame(newPos, dir))
        end
    end

    hrp = getHRP()
    if hrp then
        local finalPos = startPos + dir * endDist
        setHRPPosition(hrp, uprightCFrame(finalPos, dir))
    end

    isFlying = false
    setFlyPhysics(false)
    return true
end

local function getRandomCityPoint()
    if #cityParts == 0 then return nil end
    local part = cityParts[math.random(1, #cityParts)]
    if not part.Parent then return nil end
    return part.Position
end

local function extractNpcNumber(name)
    local num = string.match(name, "^NPC_(%d+)$")
    if num then
        return tonumber(num)
    end
    return nil
end

local function hasSecurityTag(model)
    local nameTag = model:FindFirstChild("NameTag")
    if not nameTag then return false end
    local textLabel = nameTag:FindFirstChild("TextLabel")
    if not textLabel then return false end
    if textLabel:IsA("GuiObject") or textLabel:IsA("TextLabel") then
        return textLabel.Text == REQUIRED_TAG
    end
    return false
end

local function ownerMatches(owner, name)
    if not owner then return false end
    local val = owner.Value
    return val == name or (typeof(val) == "Instance" and val.Name == name)
end

local function getFriendNames()
    local names = {}
    local ok, err = pcall(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local isFriend = false
                local ok2, res = pcall(function()
                    return LocalPlayer:IsFriendsWith(plr.UserId)
                end)
                if ok2 then
                    isFriend = res
                end
                if isFriend then
                    table.insert(names, plr.Name)
                end
            end
        end
    end)
    if not ok then
        warn("[AutoHelper] getFriendNames error: " .. tostring(err))
    end
    return names
end

local function findPlotByOwnerNames(names)
    local plots = Workspace:FindFirstChild("PLOTS")
    if not plots then return nil end

    for _, plot in ipairs(plots:GetChildren()) do
        local owner = plot:FindFirstChild("Owner")
        if owner then
            for _, name in ipairs(names) do
                if ownerMatches(owner, name) then
                    return plot, name
                end
            end
        end
    end
    return nil
end

local function findOurPlot()
    local plots = Workspace:FindFirstChild("PLOTS")
    if not plots then return nil end

    for _, plot in ipairs(plots:GetChildren()) do
        local owner = plot:FindFirstChild("Owner")
        if owner then
            if ownerMatches(owner, LocalPlayer) or ownerMatches(owner, LocalPlayer.Name) then
                return plot
            end
        end
    end

    local friendNames = getFriendNames()
    if #friendNames > 0 then
        local plot, name = findPlotByOwnerNames(friendNames)
        if plot then
            setStatus("using friend's plot: " .. name)
            return plot
        end
    end

    return nil
end

local function findConcreteTarget(plot)
    if not plot then return nil end

    local floors = plot:FindFirstChild("Floors")
    if not floors then return nil end

    local floor2 = floors:FindFirstChild("2")
    if not floor2 then return nil end

    local floors2 = floor2:FindFirstChild("Floors")
    if not floors2 then return nil end

    local candidates = {}
    for _, child in ipairs(floors2:GetChildren()) do
        if child.Name == "60" then
            table.insert(candidates, child)
        end
    end
    if #candidates == 0 then return nil end

    for _, c in ipairs(candidates) do
        local concrete = c:FindFirstChild("Concrete")
        if concrete then
            if concrete:IsA("BasePart") then
                return concrete
            elseif concrete:IsA("Model") then
                local p = concrete.PrimaryPart or concrete:FindFirstChildWhichIsA("BasePart")
                if p then return p end
            end
        end
    end

    return nil
end

local function getNpcPart(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart")
end

local function scanNpcs(concretePos)
    local npcRoot = Workspace:FindFirstChild("NPCs")
    if not npcRoot then return {} end

    local candidates = {}
    for _, obj in ipairs(npcRoot:GetChildren()) do
        if obj:IsA("Model") then
            local num = extractNpcNumber(obj.Name)
            if num and hasSecurityTag(obj) then
                local part = getNpcPart(obj)
                if part then
                    local npcPos = part.Position
                    local distToConcrete = (npcPos - concretePos).Magnitude
                    if distToConcrete >= MIN_DIST_FROM_CONCRETE and isNearCity(npcPos) then
                        table.insert(candidates, {
                            model = obj,
                            number = num,
                            part = part,
                        })
                    end
                end
            end
        end
    end
    return candidates
end

local function getNearestNpc(candidates)
    local hrp = getHRP()
    if not hrp then return nil end
    local myPos = hrp.Position

    local best = nil
    local bestDist = math.huge

    for _, c in ipairs(candidates) do
        if c.model.Parent and c.part.Parent then
            local d = (c.part.Position - myPos).Magnitude
            if d < bestDist then
                bestDist = d
                best = c
            end
        end
    end

    return best
end

local function countGarbage(plot)
    if not plot then return 0 end
    local garbage = plot:FindFirstChild("Garbage")
    if not garbage then return 0 end

    local n = 0
    for _, child in ipairs(garbage:GetChildren()) do
        local prompt = child:FindFirstChildOfClass("ProximityPrompt")
        if not prompt then
            prompt = child:FindFirstChildOfClass("ProximityPrompt", true)
        end
        if prompt then
            n = n + 1
        end
    end
    return n
end

local function countTunnels(plot)
    if not plot then return 0 end
    local tunnels = plot:FindFirstChild("Tunnels")
    if not tunnels then return 0 end

    local n = 0
    for _, child in ipairs(tunnels:GetChildren()) do
        if child:IsA("Model") then
            if child:FindFirstChildOfClass("ProximityPrompt") then
                n = n + 1
            end
        end
    end
    return n
end

local function shouldAbortJail()
    if not autoJail then return true end
    if not autoClean then return false end

    local plot = findOurPlot()
    if not plot then return false end

    local g = countGarbage(plot)
    local t = countTunnels(plot)

    return g > CLEAN_GARBAGE_THRESHOLD or t > CLEAN_TUNNEL_THRESHOLD
end

local function flyToCityUntilNpcs(cityPoint, concretePos)
    local hrp = getHRP()
    if not hrp then return nil end

    local startPos = hrp.Position
    local diff = cityPoint - startPos
    local distance = diff.Magnitude
    local dir = distance > 0 and diff.Unit or Vector3.new(0, 0, -1)
    local stepTime = 1 / FLY_UPDATE_RATE
    local traveled = 0
    local acc = 0
    local arrived = false
    local waited = 0
    local scanCooldown = 0

    isFlying = true
    setFlyPhysics(true)

    while autoJail and not shouldAbortJail() do
        local dt = RunService.Heartbeat:Wait()

        scanCooldown = scanCooldown + dt
        if scanCooldown >= SCAN_INTERVAL then
            scanCooldown = 0
            local candidates = scanNpcs(concretePos)
            if #candidates > 0 then
                isFlying = false
                setFlyPhysics(false)
                return candidates
            end
        end

        if not arrived then
            hrp = getHRP()
            if not hrp then break end

            acc = acc + dt
            while acc >= stepTime and traveled < distance do
                acc = acc - stepTime
                traveled = math.min(traveled + FLY_SPEED * stepTime, distance)
                local newPos = startPos + dir * traveled
                setHRPPosition(hrp, uprightCFrame(newPos, dir))
            end

            if traveled >= distance then
                arrived = true
                isFlying = false
                setFlyPhysics(false)
                setStatus("waiting for NPCs in City...")
            end
        else
            waited = waited + dt
            if waited >= SPAWN_SCAN_TIMEOUT then
                return nil
            end
            setStatus(string.format("waiting for NPCs... (%.1fs)", waited))
        end
    end

    isFlying = false
    setFlyPhysics(false)
    return nil
end

local function doJailStep()
    local plot = findOurPlot()
    if not plot then
        setStatus("plot not found")
        task.wait(0.6)
        return
    end

    local concrete = findConcreteTarget(plot)
    if not concrete then
        setStatus("Concrete not found")
        task.wait(0.6)
        return
    end

    local cityPoint = getRandomCityPoint()
    if not cityPoint then
        setStatus("City empty")
        task.wait(0.6)
        return
    end

    setStatus("flying to City")
    local candidates = flyToCityUntilNpcs(cityPoint, concrete.Position)
    if shouldAbortJail() then return end

    if not candidates or #candidates == 0 then
        setStatus("no SmallSecurity near City")
        task.wait(0.5)
        return
    end

    local chosen = getNearestNpc(candidates)
    if not chosen then
        setStatus("no nearest NPC found")
        task.wait(0.5)
        return
    end

    local npcNumber = chosen.number
    local npcPart = chosen.part

    setStatus("flying to NPC_" .. npcNumber .. " (nearest)")

    if not lerpTo(npcPart.Position) then return end
    if shouldAbortJail() then return end

    setStatus("pause before grab...")
    task.wait(GRAB_DELAY)
    if shouldAbortJail() then return end

    setStatus("Interact " .. npcNumber)
    InteractEvent:FireServer(npcNumber, "PromptTriggered")
    task.wait(0.35)
    if shouldAbortJail() then return end

    plot = findOurPlot()
    concrete = plot and findConcreteTarget(plot) or nil
    if not concrete then
        setStatus("Concrete lost")
        task.wait(0.4)
        return
    end

    setStatus("flying to plot")
    if not lerpTo(concrete.Position) then return end
    if shouldAbortJail() then return end

    setStatus("Release")
    NpcHoldEvent:FireServer("Release")
    task.wait(0.25)
end

local function getPromptPos(prompt)
    local parent = prompt.Parent
    if not parent then return nil end

    if parent:IsA("BasePart") then
        return parent.Position
    end

    if parent:IsA("Model") then
        local p = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
        if p then return p.Position end
    end

    local ancestor = parent.Parent
    while ancestor and ancestor ~= Workspace do
        if ancestor:IsA("Model") then
            local p = ancestor.PrimaryPart or ancestor:FindFirstChildWhichIsA("BasePart")
            if p then return p.Position end
        end
        ancestor = ancestor.Parent
    end

    return nil
end

local function collectPromptsFromGarbage(plot, out)
    local garbage = plot:FindFirstChild("Garbage")
    if not garbage then return end

    for _, child in ipairs(garbage:GetChildren()) do
        local prompt = child:FindFirstChildOfClass("ProximityPrompt")
        if not prompt then
            prompt = child:FindFirstChildOfClass("ProximityPrompt", true)
        end
        if prompt then
            table.insert(out, prompt)
        end
    end
end

local function collectPromptsFromTunnels(plot, out)
    local tunnels = plot:FindFirstChild("Tunnels")
    if not tunnels then return end

    for _, child in ipairs(tunnels:GetChildren()) do
        if child:IsA("Model") then
            local prompt = child:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                table.insert(out, prompt)
            end
        end
    end
end

local function findCleanPrompts()
    local plot = findOurPlot()
    if not plot then return nil, nil end

    local prompts = {}
    collectPromptsFromGarbage(plot, prompts)
    collectPromptsFromTunnels(plot, prompts)

    return plot, prompts
end

local function doCleanStep()
    local _, prompts = findCleanPrompts()
    if not prompts then
        setStatus("plot not found")
        task.wait(0.6)
        return
    end

    if #prompts == 0 then
        setStatus("nothing to clean")
        task.wait(0.4)
        return
    end

    local hrp = getHRP()
    local myPos = hrp and hrp.Position or Vector3.zero

    local best = nil
    local bestDist = math.huge

    for _, prompt in ipairs(prompts) do
        if prompt.Parent then
            local pos = getPromptPos(prompt)
            if pos then
                local d = (pos - myPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = prompt
                end
            end
        end
    end

    if not best then
        setStatus("no target found")
        task.wait(0.3)
        return
    end

    local targetPos = getPromptPos(best)
    if not targetPos then
        task.wait(0.2)
        return
    end

    setStatus("cleaning (" .. #prompts .. ")")

    if not lerpTo(targetPos) then return end
    if not autoClean then return end

    task.wait(0.15)
    if not autoClean then return end
    if not best.Parent then return end

    pcall(function()
        best.HoldDuration = 0
    end)

    pcall(function()
        best:InputHoldBegin()
    end)

    task.wait(0.05)

    pcall(function()
        best:InputHoldEnd()
    end)

    task.wait(0.2)
end

local function mainLoop()
    while autoJail or autoClean do
        if autoJail and autoClean then
            local plot = findOurPlot()
            local g = countGarbage(plot)
            local t = countTunnels(plot)

            if g > CLEAN_GARBAGE_THRESHOLD or t > CLEAN_TUNNEL_THRESHOLD then
                doCleanStep()
            else
                doJailStep()
            end
        elseif autoClean then
            doCleanStep()
        elseif autoJail then
            doJailStep()
        else
            task.wait(0.1)
        end
    end

    setStatus("stopped")
end

local function ensureLoop()
    if loopRunning then return end
    loopRunning = true
    task.spawn(function()
        local ok, err = pcall(mainLoop)
        if not ok then
            warn("[AutoHelper] Error: " .. tostring(err))
            setStatus("error: " .. tostring(err))
        end
        loopRunning = false
    end)
end

toggleJail.MouseButton1Click:Connect(function()
    autoJail = not autoJail

    if autoJail then
        toggleJail.Text = "Auto Jail: ON"
        toggleJail.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        setStatus("Auto Jail ON")
    else
        toggleJail.Text = "Auto Jail: OFF"
        toggleJail.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        setStatus("Auto Jail OFF")
    end

    updateNoclip()
    if autoJail or autoClean then
        ensureLoop()
    end
end)

toggleClean.MouseButton1Click:Connect(function()
    autoClean = not autoClean

    if autoClean then
        toggleClean.Text = "Auto Clean: ON"
        toggleClean.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        setStatus("Auto Clean ON")
    else
        toggleClean.Text = "Auto Clean: OFF"
        toggleClean.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        setStatus("Auto Clean OFF")
    end

    updateNoclip()
    if autoJail or autoClean then
        ensureLoop()
    end
end)

closeButton.MouseButton1Click:Connect(function()
    autoJail = false
    autoClean = false
    stopNoclipLoop()
    setFlyPhysics(false)
    screenGui:Destroy()
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    task.wait(0.1)
    if autoJail or autoClean then
        startNoclipLoop()
    end
end)

RunService.RenderStepped:Connect(function()
    if not autoClean then return end
    local _, prompts = findCleanPrompts()
    if not prompts then return end
    for _, prompt in ipairs(prompts) do
        if prompt.Parent then
            prompt.HoldDuration = 0
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not (autoJail or autoClean) then return end
    if isFlying then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    rayParams.FilterDescendantsInstances = {char}

    local origin = hrp.Position + Vector3.new(0, GROUND_RAY_UP, 0)
    local result = Workspace:Raycast(origin, Vector3.new(0, -GROUND_RAY_DOWN, 0), rayParams)
    if result then
        local minY = result.Position.Y + HRP_HEIGHT
        if hrp.Position.Y < minY then
            local yaw = getYaw(hrp.CFrame)
            local pos = Vector3.new(hrp.Position.X, minY, hrp.Position.Z)
            hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end
end)
