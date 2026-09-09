local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if _G.sourcecheckexvs ~= "source" then
    warn("https://rscripts.net/script/multi-tool-hub-X0cu")
    error("The script source is not supported! Please use EXVS Hub from link upper!", 0)
end

local CONFIG = {
    MELEE_TOOLTIP = "Melee Weapon",
    RANGE_TOOLTIP = "Ranged Weapon",
    FOOD_TOOLTIP = "Food Weapon",
    CLICK_DELAY = 1 / 8,
    EAT_DELAY = 0.4,
    EAT_THRESHOLD = 0.80,
    RETREAT_ENTER = 0.20,
    RETREAT_EXIT = 0.80,
    FLEE_DISTANCE = 50,
    FLEE_REPICK = 2,
    ATTACK_RANGE = 5,
    MOVE_SPEED = 180,
    FARM_HOVER_POINT = Vector3.new(0, 15, -17),
    FARM_LERP_STIFFNESS = 8,
    FARM_LERP_LOOK_STIFFNESS = 12,
    FARM_MAX_SAFE_DISTANCE = 200,
    FARM_GROUND_INTERVAL = 10,
    FARM_GROUND_DURATION = 5,
    FARM_WALL_REPAIR_INTERVAL = 10,
    BULLET_SPEED = 500,
    TP_OFFSET = CFrame.new(0, 2, 0),
    TARGET_REFRESH = 0.2,
    UPGRADE_COOLDOWN = 0.5,
    WALL_MAX_TIME = 2.5,
    ARMOR_MAX_TIME = 2.5,
    ARMOR_COOLDOWN = 1,
    PROMPT_PRESS_DELAY = 0.3,
    MAX_DT = 0.05,
    Q_PRESS_INTERVAL = 6,
    ATTACK_RECENT_WINDOW = 15,
    FOOD_UPGRADE_MELEE_WINDOW = 45,
    AURA_FIRE_INTERVAL = 0.05,
    GAME_OVER_POLL = 0.5,
    STARTUP_WAIT = 10,
    LOBBY_STATUS_POLL = 0.5,
    UI_POLL = 0.1,
    PARTY_JOIN_WAIT = 15,
}

local SCRIPT_URL = "https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/CI.lua"

local IGNORED_ATTACK_TOOLS = {
    ["Slingshot"] = true,
    ["Caveman Club"] = true,
}

local player = Players.LocalPlayer
local autoKillEnabled = _G.autoKillState or false
local rangeKillEnabled = false
local autoHealEnabled = false
local autoUpgradeEnabled = _G.autoUpgradeState or false
local autoFarmEnabled = _G.autoFarmState or false
local attackAuraEnabled = _G.attackAuraState or false
local hBindEnabled = true
local retreatMode = false
local upgradeBusy = false
local upgradeInPhysicalAction = false
local farmGrounding = false
local wallRepairActive = false

local moveGoal = nil
local moveLook = nil
local statusText = "M:- P:- | IDLE"

local targetCache = {}
local lastScan = 0
local lastClick = 0
local lastEat = 0
local lastFleePick = 0
local lastRepair = 0
local cachedMoney = nil
local lastMoneyScan = 0

local lastRangedAttack = 0
local lastMeleeAttack = 0

local shopOpenedOnce = false
local purchasedItems = {}

local savedGravity = workspace.Gravity
local farmBodyVelocity = nil
local farmBodyGyro = nil
local noclipOn = false
local UIrefs = {
    kill = nil,
    range = nil,
    heal = nil,
    upg = nil,
    farm = nil,
    aura = nil,
}

local farmOverlayGui = nil
local farmBox = nil

local setNoclip
local setGravity
local destroyFarmBodyMovers
local createFarmBodyMovers
local setFarmOverlayVisible
local createFarmOverlay
local syncButtons
local setFarm
local setRangeKill

local function isLobby()
    local parties = workspace:FindFirstChild("Parties")
    return parties ~= nil
end

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    if autoFarmEnabled and not farmGrounding and not isLobby() then
        createFarmBodyMovers()
        setGravity(0)
        setNoclip(true)
    end
end)

local function rnd(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = obj
    return corner
end

local function collectEnvs()
    local envs = {}
    pcall(function()
        if getgenv then table.insert(envs, getgenv()) end
    end)
    pcall(function()
        if getrenv then table.insert(envs, getrenv()) end
    end)
    pcall(function()
        table.insert(envs, getfenv(0))
    end)
    pcall(function()
        table.insert(envs, getfenv())
    end)
    table.insert(envs, _G)
    return envs
end

local function findInEnvs(name)
    for _, env in ipairs(collectEnvs()) do
        if type(env) == "table" then
            local val = rawget(env, name)
            if val ~= nil then
                return val
            end
        end
    end
    return nil
end

local function findNestedInEnvs(path)
    for _, env in ipairs(collectEnvs()) do
        if type(env) == "table" then
            local cur = env
            local ok = true
            for seg in path:gmatch("[^%.]+") do
                if type(cur) ~= "table" then
                    ok = false
                    break
                end
                cur = rawget(cur, seg)
                if cur == nil then
                    ok = false
                    break
                end
            end
            if ok and cur ~= nil then
                return cur
            end
        end
    end
    return nil
end

local function getQueueOnTeleport()
    local qot = findInEnvs("queue_on_teleport")
    if type(qot) == "function" then return qot end
    qot = findInEnvs("queueonteleport")
    if type(qot) == "function" then return qot end

    local paths = {
        "syn.queue_on_teleport",
        "wave.queue_on_teleport",
        "fluxus.queue_on_teleport",
        "delta.queue_on_teleport",
        "crypt.queue_on_teleport",
        "secureqot.queue_on_teleport",
        "valyseus.queue_on_teleport",
        "codeX.queue_on_teleport",
        "syn.queueonteleport",
        "wave.queueonteleport",
    }
    for _, p in ipairs(paths) do
        local fn = findNestedInEnvs(p)
        if type(fn) == "function" then
            return fn
        end
    end
    return nil
end

local function getHookFunction()
    local hf = findInEnvs("hookfunction")
    if type(hf) == "function" then return hf end
    hf = findNestedInEnvs("syn.hookfunction")
    if type(hf) == "function" then return hf end
    return nil
end

pcall(function()
    local payload =
        'if not game:IsLoaded() then game.Loaded:Wait() end\n' ..
        'local Players = game:GetService("Players")\n' ..
        'while not Players.LocalPlayer do task.wait(0.1) end\n' ..
        'local player = Players.LocalPlayer\n' ..
        'while not player:FindFirstChild("PlayerGui") or not player.Character do task.wait(0.1) end\n' ..
        'print("Auto Farm: restarting on new server")\n' ..
        'local success, err = pcall(function()\n' ..
        '    _G.sourcecheckexvs = "source"\n' ..
        '    _G.autoFarmState = ' .. tostring(autoFarmEnabled) .. '\n' ..
        '    _G.autoKillState = ' .. tostring(autoKillEnabled) .. '\n' ..
        '    _G.autoUpgradeState = ' .. tostring(autoUpgradeEnabled) .. '\n' ..
        '    _G.attackAuraState = ' .. tostring(attackAuraEnabled) .. '\n' ..
        '    loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()\n' ..
        'end)\n' ..
        'if not success then warn("Auto Farm Error: " .. tostring(err)) end\n'

    local qot = getQueueOnTeleport()
    if qot then
        pcall(qot, payload)
        return
    end

    local hookFn = getHookFunction()
    if hookFn then
        local oldTeleport
        oldTeleport = hookFn(TeleportService.Teleport, function(self, ...)
            _G.autoFarmState = autoFarmEnabled
            _G.autoKillState = autoKillEnabled
            _G.autoUpgradeState = autoUpgradeEnabled
            _G.attackAuraState = attackAuraEnabled
            return oldTeleport(self, ...)
        end)
    end
end)

setNoclip = function(active)
    if noclipOn == active then return end
    noclipOn = active
    if not character then return end
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not active
        end
    end
end

setGravity = function(value)
    pcall(function() workspace.Gravity = value end)
end

destroyFarmBodyMovers = function()
    if farmBodyVelocity and farmBodyVelocity.Parent then
        pcall(function() farmBodyVelocity:Destroy() end)
    end
    farmBodyVelocity = nil
    if farmBodyGyro and farmBodyGyro.Parent then
        pcall(function() farmBodyGyro:Destroy() end)
    end
    farmBodyGyro = nil
end

createFarmBodyMovers = function()
    if not rootPart then return end
    destroyFarmBodyMovers()

    farmBodyVelocity = Instance.new("BodyVelocity")
    farmBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    farmBodyVelocity.Velocity = Vector3.zero
    farmBodyVelocity.P = 12500
    farmBodyVelocity.Parent = rootPart

    farmBodyGyro = Instance.new("BodyGyro")
    farmBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    farmBodyGyro.P = 10000
    farmBodyGyro.D = 500
    farmBodyGyro.CFrame = rootPart.CFrame
    farmBodyGyro.Parent = rootPart
end

setFarmOverlayVisible = function(visible)
    if farmOverlayGui then
        farmOverlayGui.Enabled = visible
    end
end

createFarmOverlay = function()
    if farmOverlayGui then
        farmOverlayGui:Destroy()
        farmOverlayGui = nil
        farmBox = nil
    end

    local playerGui = player:WaitForChild("PlayerGui")

    farmOverlayGui = Instance.new("ScreenGui")
    farmOverlayGui.Name = "FarmOverlay"
    farmOverlayGui.ResetOnSpawn = false
    farmOverlayGui.DisplayOrder = 20
    farmOverlayGui.Enabled = false
    farmOverlayGui.Parent = playerGui

    farmBox = Instance.new("TextButton")
    farmBox.AnchorPoint = Vector2.new(0.5, 0.5)
    farmBox.Position = UDim2.new(0.5, 0, 0.5, 0)
    farmBox.Size = UDim2.new(0.1, 0, 0.1, 0)
    farmBox.BackgroundColor3 = Color3.fromRGB(15, 35, 20)
    farmBox.AutoButtonColor = false
    farmBox.Text = ""
    farmBox.Parent = farmOverlayGui
    rnd(farmBox, 10)

    local farmTitle = Instance.new("TextLabel")
    farmTitle.Size = UDim2.new(1, 0, 0.45, 0)
    farmTitle.Position = UDim2.new(0, 0, 0.08, 0)
    farmTitle.BackgroundTransparency = 1
    farmTitle.Text = "Auto Farm Active!"
    farmTitle.TextColor3 = Color3.fromRGB(140, 255, 170)
    farmTitle.TextScaled = true
    farmTitle.Font = Enum.Font.GothamBold
    farmTitle.Parent = farmBox

    local farmSubtitle = Instance.new("TextLabel")
    farmSubtitle.Size = UDim2.new(1, 0, 0.5, 0)
    farmSubtitle.Position = UDim2.new(0, 0, 0.5, 0)
    farmSubtitle.BackgroundTransparency = 1
    farmSubtitle.Text = "By EXVS"
    farmSubtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    farmSubtitle.TextScaled = true
    farmSubtitle.Font = Enum.Font.GothamBlack
    farmSubtitle.Parent = farmBox

    farmBox.MouseButton1Click:Connect(function()
        if setFarm then
            setFarm(false)
        end
    end)
end

syncButtons = function()
    local farmLock = autoFarmEnabled

    local lockedButtons = {"kill", "range", "heal", "upg", "aura"}
    for _, key in ipairs(lockedButtons) do
        local btn = UIrefs[key]
        if btn then
            if farmLock then
                btn.Active = false
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                btn.TextColor3 = Color3.fromRGB(100, 100, 100)
            else
                btn.Active = true
                btn.TextColor3 = Color3.new(1, 1, 1)
            end
        end
    end

    if UIrefs.kill then
        if autoKillEnabled then
            UIrefs.kill.Text = "Auto Kill: ON"
            if not farmLock then
                UIrefs.kill.BackgroundColor3 = Color3.fromRGB(40, 180, 60)
            end
        else
            UIrefs.kill.Text = "Auto Kill: OFF"
            if not farmLock then
                UIrefs.kill.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            end
        end
    end
    if UIrefs.range then
        if rangeKillEnabled then
            UIrefs.range.Text = "☑ Range Kill"
            if not farmLock then
                UIrefs.range.BackgroundColor3 = Color3.fromRGB(200, 120, 40)
            end
        else
            UIrefs.range.Text = "☐ Range Kill"
            if not farmLock then
                UIrefs.range.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end
    end
    if UIrefs.heal then
        if autoHealEnabled then
            UIrefs.heal.Text = "☑ Auto Heal"
            if not farmLock then
                UIrefs.heal.BackgroundColor3 = Color3.fromRGB(40, 140, 180)
            end
        else
            UIrefs.heal.Text = "☐ Auto Heal"
            if not farmLock then
                UIrefs.heal.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end
    end
    if UIrefs.upg then
        if autoUpgradeEnabled then
            UIrefs.upg.Text = "☑ Auto Upgr."
            if not farmLock then
                UIrefs.upg.BackgroundColor3 = Color3.fromRGB(120, 60, 160)
            end
        else
            UIrefs.upg.Text = "☐ Auto Upgr."
            if not farmLock then
                UIrefs.upg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end
    end
    if UIrefs.farm then
        if autoFarmEnabled then
            local label = "Stop - Backspace"
            if isLobby() then
                label = "QUEUING GAME..."
            elseif farmGrounding then
                label = "BYPASSING ANTI-FLY..."
            elseif wallRepairActive then
                label = "REPAIRING WALLS..."
            end
            UIrefs.farm.Text = label
            UIrefs.farm.BackgroundColor3 = isLobby() and Color3.fromRGB(60, 120, 60) or (farmGrounding and Color3.fromRGB(120, 80, 20) or Color3.fromRGB(0, 160, 255))
        else
            UIrefs.farm.Text = "☐ Auto Farm"
            UIrefs.farm.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
    end
    if UIrefs.aura then
        if attackAuraEnabled then
            UIrefs.aura.Text = "☑ Attack Aura"
            if not farmLock then
                UIrefs.aura.BackgroundColor3 = Color3.fromRGB(220, 60, 120)
            end
        else
            UIrefs.aura.Text = "☐ Attack Aura"
            if not farmLock then
                UIrefs.aura.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end
    end

    setFarmOverlayVisible(autoFarmEnabled)
end

setFarm = function(on)
    autoFarmEnabled = on
    farmGrounding = false
    wallRepairActive = false
    if on then
        autoKillEnabled = false
        rangeKillEnabled = false
        autoUpgradeEnabled = true
        if not isLobby() then
            setGravity(0)
            setNoclip(true)
            createFarmBodyMovers()
        end
    else
        autoUpgradeEnabled = false
        destroyFarmBodyMovers()
        setGravity(savedGravity)
        setNoclip(false)
    end
    syncButtons()
end

setRangeKill = function(on)
    rangeKillEnabled = on
    if on then
        autoFarmEnabled = false
        destroyFarmBodyMovers()
        setGravity(savedGravity)
        setNoclip(false)
    end
    syncButtons()
end

local function findToolByTooltip(tooltip)
    local containers = {player:FindFirstChild("Backpack"), character}
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and item.ToolTip == tooltip then
                    if not IGNORED_ATTACK_TOOLS[item.Name] then
                        return item
                    end
                end
            end
        end
    end
    return nil
end

local function getRangedTool()
    return findToolByTooltip(CONFIG.RANGE_TOOLTIP)
end

local function getMeleeTool()
    return findToolByTooltip(CONFIG.MELEE_TOOLTIP)
end

local function sendAttack(targetPart)
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then return false end
    local event = events:FindFirstChild("WeaponEvent")
    if not event then return false end

    local dir
    if targetPart and rootPart and targetPart:IsA("BasePart") then
        local targetPos = targetPart.Position
        local velocity = Vector3.zero
        pcall(function()
            velocity = targetPart.AssemblyLinearVelocity or targetPart.Velocity or Vector3.zero
        end)
        local distance = (targetPos - rootPart.Position).Magnitude
        local travelTime = distance / CONFIG.BULLET_SPEED
        local predicted = targetPos + velocity * travelTime
        local diff = predicted - rootPart.Position
        if diff.Magnitude > 0.01 then
            dir = diff.Unit
        else
            dir = rootPart.CFrame.LookVector
        end
    elseif rootPart then
        dir = rootPart.CFrame.LookVector
    else
        dir = Vector3.new(0, 0, -1)
    end

    local ok = pcall(function()
        event:FireServer(dir, true)
    end)
    return ok
end

local function screenClick()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
    task.delay(0.02, function()
        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
    end)
end

local function tryEat()
    local food = findToolByTooltip(CONFIG.FOOD_TOOLTIP)
    if not food then return false end
    if character:FindFirstChild(food.Name) ~= food then
        if humanoid then
            humanoid:EquipTool(food)
        end
        return false
    end
    screenClick()
    return true
end

local function getVest()
    local map = workspace:FindFirstChild("_Map")
    return map and map:FindFirstChild("Banshee Vest")
end

local function getPriceText()
    local vest = getVest()
    local holder = vest and vest:FindFirstChild("HeadHolder")
    local board = holder and holder:FindFirstChild("ArmorBillboard")
    local display = board and board:FindFirstChild("PriceDisplay")
    if not display then return nil end
    return tostring(display.Text)
end

local function getWallPriceText()
    local map = workspace:FindFirstChild("_Map")
    local uw = map and map:FindFirstChild("UpgradeWall")
    local holder = uw and uw:FindFirstChild("HolderPart")
    local board = holder and holder:FindFirstChild("WallDisplay")
    local display = board and board:FindFirstChild("PriceDisplay")
    if not display then return nil end
    return tostring(display.Text)
end

local function parsePrice(text)
    if not text then return nil end
    local digits = text:gsub("[^%d]", "")
    if digits == "" then return nil end
    return tonumber(digits)
end

local function getMoney()
    if tick() - lastMoneyScan < 0.2 then return cachedMoney end
    lastMoneyScan = tick()
    cachedMoney = nil
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        local coins = ls:FindFirstChild("💰 Coins")
        if coins then
            cachedMoney = coins.Value
            return cachedMoney
        end
        for _, v in ipairs(ls:GetChildren()) do
            if (v:IsA("IntValue") or v:IsA("NumberValue")) and v.Name:lower():find("coin", 1, true) then
                cachedMoney = v.Value
                return cachedMoney
            end
        end
    end
    return cachedMoney
end

local function resolvePath(base, path)
    local cur = base
    for seg in path:gmatch("[^%.]+") do
        cur = cur and cur:FindFirstChild(seg)
        if not cur then return nil end
    end
    return cur
end

local function getControl(path)
    local pg = player:FindFirstChild("PlayerGui")
    local obj = nil
    if pg then obj = resolvePath(pg, path) end
    if not obj then obj = resolvePath(StarterGui, path) end
    if obj then return obj end
    local parentPath = path:match("^(.*)%.[^%.]+$")
    if parentPath then
        if pg then obj = resolvePath(pg, parentPath) end
        if not obj then obj = resolvePath(StarterGui, parentPath) end
    end
    return obj
end

local function guiPos(obj)
    local inset = GuiService:GetGuiInset()
    return obj.AbsolutePosition + obj.AbsoluteSize / 2 + inset
end

local function pressControl(obj)
    if not obj then return false end
    if obj:IsA("BindableEvent") then
        obj:Fire()
        return true
    end
    if obj:IsA("RemoteEvent") then
        pcall(function() obj:FireServer() end)
        return true
    end
    if obj:IsA("GuiObject") then
        local pos = guiPos(obj)
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        task.delay(0.02, function()
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end)
        return true
    end
    return false
end

local function pressHold(obj, holdTime)
    if not obj or not obj:IsA("GuiObject") then return false end
    local pos = guiPos(obj)
    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
    task.delay(holdTime, function()
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
    end)
    return true
end

local function pressPrompt(prompt)
    local ok = pcall(function() fireproximityprompt(prompt) end)
    if not ok then
        pcall(function() prompt:InputHoldBegin() end)
    end
end

local function getWallUpgradeObjects()
    local map = workspace:FindFirstChild("_Map")
    local uw = map and map:FindFirstChild("UpgradeWall")
    local holder = uw and uw:FindFirstChild("HolderPart")
    if not holder then return nil, nil end
    local attachment = holder:FindFirstChild("Attachment")
    return attachment and attachment:FindFirstChild("UpgradeWallPrompt"), holder
end

local function getArmorUpgradeObjects()
    local vest = getVest()
    if not vest then return nil, nil, nil end
    local headHolder = vest:FindFirstChild("HeadHolder")
    local holderPart = vest:FindFirstChild("HoldePart") or vest:FindFirstChild("HolderPart")
    local prompt = nil
    if holderPart then
        local attachment = holderPart:FindFirstChild("Attachment")
        prompt = attachment and attachment:FindFirstChild("UpgradePrompt")
    end
    return headHolder, prompt, holderPart
end

local function tryWallUpgrade(money)
    local price = parsePrice(getWallPriceText())
    if not price or money < price then return false end
    local prompt, holder = getWallUpgradeObjects()
    if not prompt or not holder or not rootPart then return false end

    upgradeInPhysicalAction = true
    destroyFarmBodyMovers()
    setNoclip(false)
    setGravity(savedGravity)

    local baseText = getWallPriceText()
    local oldAnchor = rootPart.Anchored
    rootPart.Anchored = false
    rootPart.CFrame = holder.CFrame * CFrame.new(0, 3, 0)
    task.wait(0.3)
    local startT = tick()
    local lp = 0
    while tick() - startT < CONFIG.WALL_MAX_TIME do
        if getWallPriceText() ~= baseText then break end
        if tick() - lp >= CONFIG.PROMPT_PRESS_DELAY then
            lp = tick()
            pressPrompt(prompt)
        end
        task.wait(0.05)
    end
    rootPart.Anchored = oldAnchor

    if autoFarmEnabled and not isLobby() then
        setGravity(0)
        setNoclip(true)
        createFarmBodyMovers()
    end
    upgradeInPhysicalAction = false
    return true
end

local function tryArmorUpgrade(money)
    local priceText = getPriceText()
    local price = priceText and parsePrice(priceText)
    if not price or money < price or price == 79 then return false end
    local headHolder, prompt, holderPart = getArmorUpgradeObjects()
    local anchor = holderPart or headHolder
    if not anchor or not rootPart then return false end

    upgradeInPhysicalAction = true
    destroyFarmBodyMovers()
    setNoclip(false)
    setGravity(savedGravity)

    local baseText = priceText
    local oldAnchor = rootPart.Anchored
    rootPart.Anchored = false
    rootPart.CFrame = anchor.CFrame * CFrame.new(0, 3, 0)
    task.wait(0.3)
    local startT = tick()
    local lp = 0
    while tick() - startT < CONFIG.ARMOR_MAX_TIME do
        if getPriceText() ~= baseText then break end
        if prompt and tick() - lp >= CONFIG.PROMPT_PRESS_DELAY then
            lp = tick()
            pressPrompt(prompt)
        end
        task.wait(0.05)
    end
    if prompt then
        pcall(function() prompt:InputHoldEnd() end)
    end
    rootPart.Anchored = oldAnchor

    if autoFarmEnabled and not isLobby() then
        setGravity(0)
        setNoclip(true)
        createFarmBodyMovers()
    end
    upgradeInPhysicalAction = false
    return true
end

local function getCatsFolder()
    local map = workspace:FindFirstChild("_Map")
    if not map then return nil end
    local cats = map:FindFirstChild("Cats")
    if not cats then return nil end
    return cats:FindFirstChild("ClientCats")
end

local function getFoodTarget()
    local map = workspace:FindFirstChild("_Map")
    local g = map and map:FindFirstChild("Game")
    local f = g and g:FindFirstChild("Food")
    return f and f:FindFirstChild("Target")
end

local function getFarmHoverPoint()
    return CONFIG.FARM_HOVER_POINT
end

local function refreshTargetCache()
    targetCache = {}
    local folder = getCatsFolder()
    if not folder then return end
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            local part = model.PrimaryPart
            if not part or not part:IsA("BasePart") then
                for _, d in ipairs(model:GetDescendants()) do
                    if d:IsA("BasePart") then
                        part = d
                        break
                    end
                end
            end
            if part then
                table.insert(targetCache, part)
            end
        end
    end
end

local function refreshIfNeeded()
    if tick() - lastScan > CONFIG.TARGET_REFRESH then
        lastScan = tick()
        refreshTargetCache()
    end
end

local function pickTarget(anchor)
    local best, bd = nil, math.huge
    for _, part in ipairs(targetCache) do
        if part.Parent then
            local d = (part.Position - anchor).Magnitude
            if d < bd then
                bd = d
                best = part
            end
        end
    end
    return best
end

local function getAttackTarget()
    refreshIfNeeded()
    local ft = getFoodTarget()
    if ft then return pickTarget(ft.Position) end
    if rootPart then return pickTarget(rootPart.Position) end
    return nil
end

local function getNearestTarget()
    refreshIfNeeded()
    if not rootPart then return nil end
    return pickTarget(rootPart.Position)
end

local function getWallRepairPrompt()
    local fortress = workspace:FindFirstChild("Fortress")
    local walls = fortress and fortress:FindFirstChild("Walls")
    if not walls then return nil, nil end
    for _, wallModel in ipairs(walls:GetChildren()) do
        if wallModel:IsA("Model") then
            local hb = wallModel:FindFirstChild("WallHitbox")
            local p = hb and hb:FindFirstChild("BuildPrompt")
            if p and p:IsA("ProximityPrompt") and p.Enabled then
                return p, hb
            end
        end
    end
    return nil, nil
end

local function getSmartCategory()
    local now = tick()
    local rangedRecent = (now - lastRangedAttack) < CONFIG.ATTACK_RECENT_WINDOW
    local meleeRecent = (now - lastMeleeAttack) < CONFIG.ATTACK_RECENT_WINDOW

    if rangedRecent and meleeRecent then
        if lastRangedAttack > lastMeleeAttack then
            return "Ranged"
        else
            return "Melee"
        end
    elseif rangedRecent then
        return "Ranged"
    elseif meleeRecent then
        return "Melee"
    end
    return "Melee"
end

local function openShopOnce()
    if shopOpenedOnce then return end
    shopOpenedOnce = true

    upgradeBusy = true

    pressControl(getControl("UI.HUD.LeftButtons.Weapons.Click"))
    task.wait(0.5)

    local categories = {"Food", "Melee", "Ranged"}
    for _, cat in ipairs(categories) do
        local catClick = getControl("UI.WeaponsHUD.Categories." .. cat .. ".Click")
        if catClick then
            pressControl(catClick)
            task.wait(0.4)
        end
    end

    pressControl(getControl("UI.WeaponsHUD.Back.Click"))
    task.wait(0.3)

    upgradeBusy = false
end

local function getItemPrice(frame)
    local priceObj = frame:FindFirstChild("Price")
    if not priceObj then return nil end
    local display = priceObj:FindFirstChild("Display")
    if not display then return nil end
    if display:IsA("TextLabel") or display:IsA("TextBox") then
        return parsePrice(display.Text)
    end
    local textLabel = display:FindFirstChildWhichIsA("TextLabel")
    if textLabel then
        return parsePrice(textLabel.Text)
    end
    local ok, text = pcall(function() return display.Text end)
    if ok and text then
        return parsePrice(tostring(text))
    end
    return nil
end

local function getAvailableUpgrades()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return {} end
    local displayInfo = resolvePath(pg, "UI.WeaponsHUD.DisplayInfo")
    if not displayInfo then return {} end

    local upgrades = {}
    local categories = {"Food", "Melee", "Ranged"}
    for _, category in ipairs(categories) do
        local categoryFolder = displayInfo:FindFirstChild(category)
        if categoryFolder then
            for _, frame in ipairs(categoryFolder:GetChildren()) do
                if frame:IsA("Frame") then
                    local itemName = frame.Name
                    if not purchasedItems[itemName] then
                        local price = getItemPrice(frame)
                        if price and price > 0 then
                            table.insert(upgrades, {
                                name = itemName,
                                category = category,
                                price = price,
                            })
                        end
                    end
                end
            end
        end
    end
    return upgrades
end

local function findCheapestAffordable(upgrades, money)
    local best = nil
    for _, upg in ipairs(upgrades) do
        if upg.price <= money then
            if not best or upg.price < best.price then
                best = upg
            end
        end
    end
    return best
end

local function meleeUsedRecently()
    return (tick() - lastMeleeAttack) < CONFIG.FOOD_UPGRADE_MELEE_WINDOW
end

RunService.RenderStepped:Connect(function(dtRaw)
    if not rootPart then return end
    local dt = math.min(dtRaw or 0.016, CONFIG.MAX_DT)

    if upgradeInPhysicalAction then
        setNoclip(false)
        return
    end

    if farmGrounding or wallRepairActive then
        return
    end

    if autoFarmEnabled and humanoid and humanoid.Health > 0 then
        if isLobby() then
            return
        end

        if not farmBodyVelocity or not farmBodyVelocity.Parent then
            createFarmBodyMovers()
            setGravity(0)
            setNoclip(true)
        end

        local hover = getFarmHoverPoint()
        local t = getAttackTarget()
        local lookPos = t and (t.Position + Vector3.new(0, 1, 0)) or (rootPart.Position + rootPart.CFrame.LookVector * 10 + Vector3.new(0, 1, 0))

        if farmBodyVelocity and farmBodyVelocity.Parent == rootPart then
            local displacement = hover - rootPart.Position
            local velocity = displacement * CONFIG.FARM_LERP_STIFFNESS
            local maxSpeed = 200
            if velocity.Magnitude > maxSpeed then
                velocity = velocity.Unit * maxSpeed
            end
            farmBodyVelocity.Velocity = velocity
        end

        if farmBodyGyro and farmBodyGyro.Parent == rootPart then
            local targetCF = CFrame.lookAt(rootPart.Position, lookPos)
            farmBodyGyro.CFrame = targetCF
        end

        setNoclip(true)
        return
    end

    if moveGoal then
        local cf = rootPart.CFrame
        local pos = cf.Position
        local dir = moveGoal - pos
        local dist = dir.Magnitude
        if dist > 0.05 then
            local step = math.min(CONFIG.MOVE_SPEED * dt, dist)
            local newPos = pos + dir.Unit * step
            if moveLook and (moveLook - newPos).Magnitude > 0.1 then
                rootPart.CFrame = CFrame.lookAt(newPos, moveLook)
            else
                rootPart.CFrame = cf - cf.Position + newPos
            end
            setNoclip(true)
        else
            rootPart.Velocity = Vector3.zero
            setNoclip(false)
        end
    else
        setNoclip(false)
    end
end)

task.spawn(function()
    while true do
        task.wait(CONFIG.FARM_GROUND_INTERVAL)
        if not autoFarmEnabled then continue end
        if isLobby() then continue end
        if upgradeInPhysicalAction then continue end
        if wallRepairActive then continue end
        if not humanoid or not rootPart or humanoid.Health <= 0 then continue end

        farmGrounding = true
        syncButtons()
        destroyFarmBodyMovers()
        setNoclip(false)
        setGravity(savedGravity)

        task.wait(CONFIG.FARM_GROUND_DURATION)

        if not autoFarmEnabled then
            farmGrounding = false
            syncButtons()
            continue
        end

        farmGrounding = false
        setGravity(0)
        setNoclip(true)
        createFarmBodyMovers()
        syncButtons()
    end
end)

task.spawn(function()
    while true do
        task.wait(CONFIG.FARM_WALL_REPAIR_INTERVAL)
        if not autoFarmEnabled then continue end
        if isLobby() then continue end
        if upgradeInPhysicalAction then continue end
        if farmGrounding then continue end
        if not humanoid or not rootPart or humanoid.Health <= 0 then continue end

        wallRepairActive = true
        syncButtons()

        destroyFarmBodyMovers()
        setNoclip(true)
        setGravity(0)

        local fortress = workspace:FindFirstChild("Fortress")
        local walls = fortress and fortress:FindFirstChild("Walls")
        if walls then
            for _, wallModel in ipairs(walls:GetChildren()) do
                if not autoFarmEnabled then break end
                if wallModel:IsA("Model") then
                    local hb = wallModel:FindFirstChild("WallHitbox")
                    local prompt = hb and hb:FindFirstChild("BuildPrompt")
                    if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled and hb then
                        rootPart.Anchored = false
                        rootPart.CFrame = hb.CFrame * CFrame.new(0, 2, 4)
                        task.wait(0.25)
                        local startT = tick()
                        while tick() - startT < CONFIG.WALL_MAX_TIME do
                            if not prompt.Enabled then break end
                            if not autoFarmEnabled then break end
                            pressPrompt(prompt)
                            task.wait(CONFIG.PROMPT_PRESS_DELAY)
                        end
                    end
                end
            end
        end

        if autoFarmEnabled and not isLobby() then
            setGravity(0)
            setNoclip(true)
            createFarmBodyMovers()
        end

        wallRepairActive = false
        syncButtons()
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.H then
        if hBindEnabled and not autoFarmEnabled then
            setRangeKill(not rangeKillEnabled)
        end
    end
    if input.KeyCode == Enum.KeyCode.Backspace then
        if autoFarmEnabled then
            setFarm(false)
        end
    end
end)

local vimOrder = 1
local function sendKey(pressed, key)
    if vimOrder == 1 then
        local ok = pcall(function() VirtualInputManager:SendKeyEvent(pressed, key, false, game) end)
        if not ok then
            vimOrder = 2
            pcall(function() VirtualInputManager:SendKeyEvent(key, pressed, false, game) end)
        end
    else
        pcall(function() VirtualInputManager:SendKeyEvent(key, pressed, false, game) end)
    end
end

task.spawn(function()
    while true do
        task.wait(CONFIG.Q_PRESS_INTERVAL)
        if isLobby() then continue end
        if not upgradeBusy and not upgradeInPhysicalAction and not farmGrounding and not wallRepairActive and (autoFarmEnabled or autoKillEnabled) then
            sendKey(true, Enum.KeyCode.Q)
            task.wait(0.06)
            sendKey(false, Enum.KeyCode.Q)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        local ok, err = pcall(function()
            if isLobby() then return end
            if not (autoUpgradeEnabled and not retreatMode and not upgradeBusy and humanoid and rootPart and humanoid.Health > 0) then
                return
            end

            if not shopOpenedOnce then
                openShopOnce()
                task.wait(0.5)
            end

            local money = getMoney()
            if not money then return end

            local upgrades = getAvailableUpgrades()
            local ownsFood = findToolByTooltip(CONFIG.FOOD_TOOLTIP) ~= nil
            local weaponCat = getSmartCategory()

            local foodUpgrades = {}
            local weaponUpgrades = {}
            for _, upg in ipairs(upgrades) do
                if upg.category == "Food" then
                    table.insert(foodUpgrades, upg)
                elseif upg.category == weaponCat then
                    table.insert(weaponUpgrades, upg)
                end
            end

            local cheapestFood = findCheapestAffordable(foodUpgrades, money)
            local cheapestWeapon = findCheapestAffordable(weaponUpgrades, money)

            local wallPrice = parsePrice(getWallPriceText())
            local wallAfford = wallPrice ~= nil and money >= wallPrice
            local armorPrice = parsePrice(getPriceText())
            local armorAfford = armorPrice ~= nil and armorPrice ~= 79 and money >= armorPrice

            local action = nil
            local targetItem = nil

            if not ownsFood and cheapestFood then
                action = "food"
                targetItem = cheapestFood
            elseif cheapestWeapon then
                action = "weapon"
                targetItem = cheapestWeapon
            elseif wallAfford then
                action = "wall"
            elseif cheapestFood and meleeUsedRecently() then
                action = "food"
                targetItem = cheapestFood
            elseif armorAfford then
                action = "armor"
            end

            if not action then return end

            if action == "food" or action == "weapon" then
                local events = ReplicatedStorage:FindFirstChild("Events")
                local upgradeEvent = events and events:FindFirstChild("UpgradeWeapon")
                if not upgradeEvent then return end

                upgradeBusy = true

                if upgradeEvent:IsA("RemoteFunction") then
                    pcall(function() upgradeEvent:InvokeServer(targetItem.name) end)
                elseif upgradeEvent:IsA("RemoteEvent") then
                    pcall(function() upgradeEvent:FireServer(targetItem.name) end)
                end

                task.wait(0.3)
                upgradeBusy = false

                purchasedItems[targetItem.name] = true

                task.wait(CONFIG.UPGRADE_COOLDOWN)

            elseif action == "wall" then
                upgradeBusy = true
                tryWallUpgrade(money)
                upgradeBusy = false
                task.wait(CONFIG.ARMOR_COOLDOWN)

            elseif action == "armor" then
                upgradeBusy = true
                tryArmorUpgrade(money)
                upgradeBusy = false
                task.wait(CONFIG.ARMOR_COOLDOWN)
            end
        end)
        if not ok then warn("[Upgrade] " .. tostring(err)) end
    end
end)

task.spawn(function()
    while true do
        task.wait(CONFIG.AURA_FIRE_INTERVAL)
        if isLobby() then continue end
        if attackAuraEnabled and not upgradeBusy and humanoid and rootPart and humanoid.Health > 0 then
            local tool = getMeleeTool()
            if tool and character and character:FindFirstChild(tool.Name) == tool then
                local target = getAttackTarget()
                if sendAttack(target) then
                    lastMeleeAttack = tick()
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        local ok, err = pcall(function()
            if not (rootPart and humanoid) then return end
            if humanoid.Health <= 0 then
                moveGoal = nil
                moveLook = nil
                return
            end

            if isLobby() then
                local st = "LOBBY"
                if autoFarmEnabled then
                    st = "QUEUING"
                end
                statusText = string.format("M:%s | %s", tostring(getMoney() or "-"), st)
                moveGoal = nil
                moveLook = nil
                return
            end

            local now = tick()
            local maxHp = humanoid.MaxHealth
            local hpPct = maxHp > 0 and (humanoid.Health / maxHp) or 1

            if autoHealEnabled then
                if hpPct < CONFIG.RETREAT_ENTER and not retreatMode then
                    retreatMode = true
                    lastFleePick = 0
                elseif retreatMode and hpPct >= CONFIG.RETREAT_EXIT then
                    retreatMode = false
                    moveGoal = nil
                    moveLook = nil
                end
            else
                retreatMode = false
            end

            if retreatMode then
                local n = getNearestTarget()
                if n then
                    if now - lastFleePick >= CONFIG.FLEE_REPICK then
                        lastFleePick = now
                        local dir = rootPart.Position - n.Position
                        if dir.Magnitude > 0.1 then
                            dir = dir.Unit
                        else
                            dir = Vector3.new(1, 0, 0)
                        end
                        moveGoal = rootPart.Position + dir * CONFIG.FLEE_DISTANCE
                        moveLook = moveGoal
                    end
                else
                    moveGoal = nil
                    moveLook = nil
                end
                if now - lastEat >= CONFIG.EAT_DELAY then
                    if tryEat() then
                        lastEat = now
                    end
                end
                statusText = string.format("M:%s P:%s | RETREAT", tostring(getMoney() or "-"), tostring(parsePrice(getPriceText()) or "-"))
                return
            end

            if autoHealEnabled and hpPct < CONFIG.EAT_THRESHOLD and now - lastEat >= CONFIG.EAT_DELAY then
                if tryEat() then
                    lastEat = now
                end
            end

            local st = "IDLE"
            if wallRepairActive then
                st = "WALLFIX"
            elseif farmGrounding then
                st = "GROUND"
            elseif attackAuraEnabled then
                st = "AURA"
            elseif autoFarmEnabled then
                st = "FARM"
            elseif rangeKillEnabled then
                st = "RANGE"
            elseif upgradeBusy then
                st = "UPG"
            elseif autoKillEnabled then
                st = "KILL"
            end

            local wpnCat = getSmartCategory()
            local wpnShort = wpnCat == "Ranged" and "R" or "M"
            statusText = string.format("M:%s P:%s W:%s | %s", tostring(getMoney() or "-"), tostring(parsePrice(getPriceText()) or "-"), wpnShort, st)

            if rangeKillEnabled and not upgradeBusy then
                moveGoal = nil
                moveLook = nil
                local target = getAttackTarget()
                if target then
                    local rtool = getRangedTool()
                    if rtool and character:FindFirstChild(rtool.Name) ~= rtool then
                        humanoid:EquipTool(rtool)
                    end
                    if now - lastClick >= CONFIG.CLICK_DELAY then
                        lastClick = now
                        if sendAttack(target) then
                            lastRangedAttack = now
                        end
                    end
                end

            elseif autoFarmEnabled and not upgradeBusy then
                moveGoal = nil
                moveLook = nil
                local rtool = getRangedTool()
                if rtool and character:FindFirstChild(rtool.Name) ~= rtool then
                    humanoid:EquipTool(rtool)
                end
                local target = getAttackTarget()
                if now - lastClick >= CONFIG.CLICK_DELAY then
                    lastClick = now
                    if sendAttack(target) then
                        lastRangedAttack = now
                    end
                end

            elseif autoKillEnabled and not upgradeBusy then
                local target = getAttackTarget()
                if target then
                    moveGoal = (target.CFrame * CONFIG.TP_OFFSET).Position
                    moveLook = target.Position
                    local dist = (rootPart.Position - moveGoal).Magnitude
                    if dist <= CONFIG.ATTACK_RANGE then
                        local tool = getMeleeTool()
                        if tool then
                            if character:FindFirstChild(tool.Name) == tool then
                                if now - lastClick >= CONFIG.CLICK_DELAY then
                                    lastClick = now
                                    if sendAttack(target) then
                                        lastMeleeAttack = now
                                    end
                                end
                            else
                                humanoid:EquipTool(tool)
                            end
                        end
                    end
                else
                    moveGoal = nil
                    moveLook = nil
                end

            else
                if not rangeKillEnabled and not autoFarmEnabled then
                    moveGoal = nil
                    moveLook = nil
                end
            end
        end)
        if not ok then warn("[Brain] " .. tostring(err)) end
        task.wait(0.02)
    end
end)

task.spawn(function()
    local lastGameOverClick = 0
    while true do
        task.wait(CONFIG.GAME_OVER_POLL)
        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            if not pg then return end
            local finalScreens = pg:FindFirstChild("FinalScreens")
            if not finalScreens then return end
            local match = finalScreens:FindFirstChild("Match")
            if not match then return end
            local gameOver = match:FindFirstChild("GameOver")
            if gameOver and gameOver.Visible and (tick() - lastGameOverClick > 2) then
                local lobbyClick = resolvePath(gameOver, "Options.Lobby.Click")
                if lobbyClick then
                    task.wait(0.3)
                    if pressControl(lobbyClick) then
                        lastGameOverClick = tick()
                    end
                end
            end
        end)
    end
end)

local function getPartyPad()
    local parties = workspace:FindFirstChild("Parties")
    if not parties then return nil end
    local party1 = parties:FindFirstChild("1")
    if not party1 then return nil end
    return party1:FindFirstChild("Pad")
end

local function getPartyStatus()
    local pad = getPartyPad()
    if not pad then return nil end
    local gui = pad:FindFirstChild("Gui")
    if not gui then return nil end
    local status = gui:FindFirstChild("Status")
    if not status then return nil end
    return status.Text
end

local function waitForCreatePartyUI()
    local startTime = tick()
    while tick() - startTime < 30 do
        local result = false
        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            if not pg then return end
            local ui = pg:FindFirstChild("UI")
            if not ui then return end
            local frames = ui:FindFirstChild("Frames")
            if not frames then return end
            local createParty = frames:FindFirstChild("CreateParty")
            if createParty and createParty.Visible then
                result = true
            end
        end)
        if result then
            return true
        end
        task.wait(CONFIG.UI_POLL)
    end
    return false
end

task.spawn(function()
    while true do
        task.wait(CONFIG.LOBBY_STATUS_POLL)

        if not autoFarmEnabled then continue end
        if not isLobby() then continue end

        local statusWait = 0
        while autoFarmEnabled and isLobby() do
            local status = getPartyStatus()
            if status == "0/0" then
                break
            end
            statusWait = statusWait + CONFIG.LOBBY_STATUS_POLL
            if statusWait > 60 then break end
            task.wait(CONFIG.LOBBY_STATUS_POLL)
        end

        if not autoFarmEnabled or not isLobby() then continue end

        local pad = getPartyPad()
        if pad and rootPart then
            rootPart.Anchored = false
            rootPart.CFrame = pad.CFrame * CFrame.new(0, 3, 0)
            task.wait(1)
        end

        if not waitForCreatePartyUI() then
            continue
        end

        task.wait(1)

        local optionClick = getControl("UI.Frames.CreateParty.Container.Options.1.Click")
        if not optionClick then
            continue
        end
        pressControl(optionClick)
        task.wait(0.5)

        local maxAttempts = 20
        local attempts = 0

        local nextClick = getControl("UI.Frames.CreateParty.Container.CheckpointSelector.OptionFrame.Next.Click")
        if nextClick then
            pressControl(nextClick)
            task.wait(0.3)
        end

        while attempts < maxAttempts and autoFarmEnabled do
            attempts = attempts + 1
            local lockedObj = getControl("UI.Frames.CreateParty.Container.Create.Locked")
            if lockedObj and lockedObj.Visible then
                local prevClick = getControl("UI.Frames.CreateParty.Container.CheckpointSelector.OptionFrame.Previous.Click")
                if prevClick then
                    pressControl(prevClick)
                    task.wait(0.3)
                else
                    break
                end
            else
                break
            end
        end

        local createClick = getControl("UI.Frames.CreateParty.Container.Create.Click")
        if createClick then
            pressControl(createClick)
            local startTime = tick()
            while tick() - startTime < CONFIG.PARTY_JOIN_WAIT do
                if not isLobby() then
                    break
                end
                task.wait(0.2)
            end
        end

        if autoFarmEnabled and not isLobby() then
            setGravity(0)
            setNoclip(true)
            createFarmBodyMovers()
        end
    end
end)

task.spawn(function()
    task.wait(CONFIG.STARTUP_WAIT)
    local map = workspace:FindFirstChild("_Map")
    local teleportArea = map and map:FindFirstChild("TeleportArea")
    if teleportArea then
    else
    end
end)

local screenGui = nil

local function createUI()
    local pg = player:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("AutoToolsUI")
    if old then old:Destroy() end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoToolsUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = pg

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 580, 0, 70)
    frame.Position = UDim2.new(1, -590, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 16)
    statusLabel.Position = UDim2.new(0, 5, 0, 48)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = statusText
    statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = frame

    task.spawn(function()
        while true do
            if statusLabel.Parent then
                statusLabel.Text = statusText
            end
            task.wait(0.25)
        end
    end)

    local function makeButton(key, name, sizeX, posX, text, offColor, onClick)
        local b = Instance.new("TextButton")
        b.Name = name
        b.Size = UDim2.new(0, sizeX, 0, 40)
        b.Position = UDim2.new(0, posX, 0, 5)
        b.BackgroundColor3 = offColor
        b.Text = text
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.AutoButtonColor = false
        b.Parent = frame
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(onClick)
        UIrefs[key] = b
        return b
    end

    makeButton("kill", "KillBtn", 88, 5, "Auto Kill: OFF", Color3.fromRGB(180, 40, 40), function()
        if autoFarmEnabled then return end
        autoKillEnabled = not autoKillEnabled
        syncButtons()
    end)

    makeButton("range", "RangeBtn", 88, 98, "☐ Range Kill", Color3.fromRGB(60, 60, 60), function()
        if autoFarmEnabled then return end
        setRangeKill(not rangeKillEnabled)
    end)

    makeButton("heal", "HealBtn", 84, 191, "☐ Auto Heal", Color3.fromRGB(60, 60, 60), function()
        if autoFarmEnabled then return end
        autoHealEnabled = not autoHealEnabled
        if not autoHealEnabled then
            retreatMode = false
        end
        syncButtons()
    end)

    makeButton("upg", "UpgradeBtn", 88, 280, "☐ Auto Upgr.", Color3.fromRGB(60, 60, 60), function()
        if autoFarmEnabled then return end
        autoUpgradeEnabled = not autoUpgradeEnabled
        syncButtons()
    end)

    makeButton("farm", "FarmBtn", 96, 373, "☐ Auto Farm", Color3.fromRGB(60, 60, 60), function()
        setFarm(not autoFarmEnabled)
    end)

    makeButton("aura", "AuraBtn", 88, 474, "☐ Attack Aura", Color3.fromRGB(60, 60, 60), function()
        if autoFarmEnabled then return end
        attackAuraEnabled = not attackAuraEnabled
        syncButtons()
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -28, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
    closeBtn.Text = "✖"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = frame
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function()
        hBindEnabled = false
        rangeKillEnabled = false
        attackAuraEnabled = false
        autoKillEnabled = false
        autoHealEnabled = false
        autoUpgradeEnabled = false
        setFarm(false)
        if screenGui then
            screenGui.Enabled = false
        end
    end)

    syncButtons()
end

createFarmOverlay()
createUI()
