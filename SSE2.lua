local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local C = {
    ClickDelay = 0.05, MaxClicksPerFrame = 10, SellEvent = "SellRocks", BuyToolEvent = "BuyTool",
    SellInterval = 5, PawnShopPath = "PawnShop.Insanity", TeleportDelayShop = 1.5, MaxRetries = 3,
    RetryDelay = 0.5, TargetCoords = Vector3.new(-24110, -4959, 24371), ExplosiveName = "Explosive",
    BallName = "BallLightning", MoonStoneName = "MoonStone", ShockStoneName = "Shockstone",
    RedMatterSourceName = "RedMatterSource", RedMatterName = "RedMatter", WaitForBallTimeout = 1,
    WaitForRedMatterTimeout = 2, WaitForItemTimeout = 3, BuyWaitTime = 0.55, RuinItem = "Explosive",
    Brightness = 15, Radius = 2000, GridStep = 4000, GridBounds = 10000, CollectAllDelay = 0.01,
    BaseWalkSpeed = 16, RedMatterTeleportDistance = 30, RedMatterTweenDuration = 0.3,
    RedMatterTweenInterval = 2.3
}

local FLY_MIN, FLY_MAX = 0.1, 20000
local clamp = math.clamp or function(v, min, max) return math.min(max, math.max(min, v)) end

local BODY_DISTANCES = {
    sun = 9644, mercury = 778, venus = 2058, earth = 2058, moon = 522, mars = 1034,
    alcaeus = 138, ceres = 266, jupiter = 9644, io = 522, europa = 522, ganymede = 778,
    callisto = 778, saturn = 7596, mimas = 138, enceladus = 138, tethys = 266, dione = 266,
    rhea = 266, titan = 778, iapetus = 266, uranus = 5548, miranda = 138, ariel = 266,
    umbriel = 266, titania = 266, oberon = 266, neptune = 5548, triton = 522, proteus = 138,
    pluto = 266, charon = 138, haumea = 266, makemake = 266, nibiru = 7598
}

local MESH_GIANTS = {sun = true, jupiter = true, saturn = true, uranus = true, neptune = true, nibiru = true}
local PACK_ORDER = {"Colonizer Pack", "Terraform+Colonize Pack", "Space Station Pack"}
local PACK_ITEMS = {
    ["Colonizer Pack"] = {"Factory","Factory","Miner","Miner","Mill","Depot","Fracker","Fracker","Pickaxe","CustomSpawn"},
    ["Terraform+Colonize Pack"] = {"Factory","Factory","Miner","Miner","Mill","Depot","Fracker","Fracker","Pickaxe","CustomSpawn","Terraformer","Terraformer","Terraformer","Terraformer","Terraformer","Terraformer","Terraformer","Terraformer","Terraformer","Terraformer"},
    ["Space Station Pack"] = {"Dome","Depot","Factory","Factory","Factory","Factory","Mill","StationMill","Junction","Junction","CustomSpawn"}
}
local DIRECT_BUY_ITEMS = {"Factory","Miner","Mill","Fracker","Dome","Junction","Pickaxe","StationMill","Depot","Terraformer"}
local TELEPORT_CATEGORIES = {"Planets", "Spawns", "Saffra", "Monoliths", "Players"}
local MONOLITHS = {
    {name = "Ganymede", pos = Vector3.new(26635, 1024, 22718.5)},
    {name = "Europa", pos = Vector3.new(47102.496, 207.581, -6649.320)}
}
local SAFFRA_CFRAME = CFrame.new(36897.1484, 2381.97827, 41866.0742, -0.965365767, 0.09295021, -0.24378109, 0.166502506, 0.938856542, -0.301372439, 0.200862825, -0.331524789, -0.921816409)

local isPack = function(name) return PACK_ITEMS[name] ~= nil end

local state = {
    moneyRunning=false, moneyProcessing=false, moneyQueue={}, moneyCollected=0, moneySold=0, moneySoldFlag=false, moneyScanConn=nil, moneySellCoroutine=nil,
    ballRunning=false, ballClicked=0, ballTeleported=false,
    fullBrightRunning=false, fullBrightLights={},
    buyTarget="Explosive", autoBuyEnabled=false,
    ruinEnabled=false, explosiveFastPlaceRunning=false,
    autoRedMatterRunning=false, redMatterClicked=0, redMatterTeleported=false,
    espEnabled=false, espConnections={}, espPlayerAddedConn=nil,
    flyEnabled=false, flySpeedMultiplier=1, flyBodyVelocity=nil, flyConnection=nil,
    controlEnabled=false, controlTarget="Phobos", controlSatellite=nil, controlBodyVelocity=nil, controlConnection=nil,
    teleportCategory="Planets", teleportTarget=nil,
    walkSpeed = 16,
    gravity = 196.2
}

local guiElements = {}
local getChar = function() return player.Character or player.CharacterAdded:Wait() end
local getRoot = function() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

local teleport = function(pos) local r = getRoot() if r then r.CFrame = CFrame.new(pos) return true end return false end
local teleportCFrame = function(cf) local r = getRoot() if r then r.CFrame = cf return true end return false end

local teleportWithTween = function(targetPos, duration)
    local r = getRoot()
    if not r then return false end
    duration = duration or C.RedMatterTweenDuration
    local tween = TweenService:Create(r, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()
    return true
end

local findByName = function(name)
    local res = {}
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o.Name == name then res[#res+1] = o end
    end
    return res
end

local hasDetector = function(o)
    if not o then return false end
    local ok, d = pcall(function() return o:FindFirstChildWhichIsA("ClickDetector", true) end)
    return ok and d ~= nil
end

local isValid = function(o) return o and o.Parent and hasDetector(o) end

local fireDetector = function(detector)
    if not detector then return false end
    if type(fireclickdetector) == "function" then return pcall(fireclickdetector, detector) end
    return pcall(function() detector.FireClickDetector(detector, 0, Vector3.new(0, 0, 0)) end)
end

local clickObj = function(o)
    if not o then return false end
    local d = nil
    pcall(function() d = o:FindFirstChildWhichIsA("ClickDetector", true) end)
    return d and fireDetector(d) or false
end

local showNotification = function(text, duration, isError)
    duration = duration or 4
    local sg = Instance.new("ScreenGui")
    sg.Name = "AutoNotif"
    sg.ResetOnSpawn = false
    sg.Parent = player.PlayerGui
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 400, 0, 60)
    f.Position = UDim2.new(0.5, -200, 0.5, 0)
    f.BackgroundColor3 = isError and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(30, 30, 50)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Parent = sg
    Instance.new("UICorner", f).CornerRadius = UDim.new(0.02, 0)
    local s = Instance.new("UIStroke", f)
    s.Color = isError and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 100, 150)
    s.Thickness = 1
    s.Transparency = 0.5
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -20, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.TextColor3 = Color3.fromRGB(255, 255, 255)
    l.Text = text
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.TextYAlignment = Enum.TextYAlignment.Center
    TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -200, 0.4, 0), BackgroundTransparency = 0.2}):Play()
    task.delay(duration, function()
        TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1, Position = UDim2.new(0.5, -200, 0.3, 0)}):Play()
        task.delay(0.3, function() sg:Destroy() end)
    end)
end

local getLoadstringFn = function()
    if type(loadstring) == "function" then return loadstring end
    local ok, env = pcall(getfenv)
    if ok and env and type(env.loadstring) == "function" then return env.loadstring end
    return nil
end

local runExternalScript = function(url, name)
    task.spawn(function()
        showNotification("Loading " .. name .. "...", 2)
        local okCode, code = pcall(function() return game:HttpGet(url, true) end)
        if not okCode or type(code) ~= "string" or code == "" then
            showNotification("Failed to download " .. name, 3, true)
            return
        end
        local loadFn = getLoadstringFn()
        if not loadFn then
            showNotification("loadstring not available", 3, true)
            return
        end
        local fn, compileErr = loadFn(code)
        if not fn then
            showNotification(name .. " compile error: " .. tostring(compileErr), 4, true)
            return
        end
        local okRun, runErr = pcall(fn)
        if not okRun then
            showNotification(name .. " run error: " .. tostring(runErr), 4, true)
        else
            showNotification(name .. " executed", 2)
        end
    end)
end

local EXTERNAL_SCRIPTS = {
    {name = "Anti AFK", url = "https://raw.githubusercontent.com/ArgetnarYT/scripts/main/AntiAfk2.lua"},
    {name = "Infinite Yield", url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"},
    {name = "Multitool", url = "https://raw.githubusercontent.com/expure/multitoolroblox/main/scriptlua.lua"},
    {name = "Fling ALL", url = "https://pastebin.com/raw/zqyDSUWX"}
}

local getFactories = function()
    local res = {}
    for _, f in ipairs(findByName("Factory")) do
        if f.Parent and f.Parent.Name == "Structures" then res[#res+1] = f end
    end
    return res
end

local getButtonDetector = function(factory, item)
    local btns = factory:FindFirstChild("Buttons")
    if not btns then return nil end
    local b = btns:FindFirstChild(item)
    if not b then return nil end
    return b:FindFirstChildOfClass("ClickDetector")
end

local pressFactory = function(factory, item)
    local d = getButtonDetector(factory, item)
    if d then return fireDetector(d) end
    return false
end

local hasItem = function(name)
    local c = getChar()
    if c and c:FindFirstChild(name) then return true end
    local bp = player:FindFirstChildOfClass("Backpack")
    if bp and bp:FindFirstChild(name) then return true end
    return false
end

local normalizeItemName = function(name)
    if type(name) ~= "string" then return name end
    if name == "Spawn" then return "CustomSpawn" end
    return name
end

local buyItem = function(name)
    name = normalizeItemName(name)
    if isPack(name) then return false end
    local factories = getFactories()
    if #factories == 0 then
        showNotification("No factories!", 2, true)
        return false
    end
    for i = #factories, 2, -1 do
        local j = math.random(1, i)
        factories[i], factories[j] = factories[j], factories[i]
    end
    for _, f in ipairs(factories) do
        if pressFactory(f, name) then
            local t = 0
            while t < C.BuyWaitTime do
                if hasItem(name) then
                    showNotification("Bought " .. name, 2)
                    return true
                end
                task.wait(0.1)
                t = t + 0.1
            end
        end
    end
    showNotification("Failed to buy " .. name, 2, true)
    return false
end

local buyToolDirect = function(name)
    local ev = ReplicatedStorage:FindFirstChild(C.BuyToolEvent)
    if not ev then
        showNotification("BuyTool event not found!", 2, true)
        return false
    end
    local ok = pcall(function()
        if ev:IsA("RemoteEvent") then ev:FireServer(name)
        elseif ev:IsA("RemoteFunction") then ev:InvokeServer(name)
        else ev:Fire(name) end
    end)
    if ok then
        showNotification("Bought " .. name, 2)
        return true
    else
        showNotification("Failed to buy " .. name, 2, true)
        return false
    end
end

local getAvailableItems = function()
    local items = {}
    for _, f in ipairs(getFactories()) do
        local btns = f:FindFirstChild("Buttons")
        if btns then
            for _, ch in ipairs(btns:GetChildren()) do
                if ch:FindFirstChildOfClass("ClickDetector") then items[#items+1] = ch.Name end
            end
        end
    end
    local uniq = {}
    local res = {}
    for _, n in ipairs(items) do
        if not uniq[n] then
            uniq[n] = true
            res[#res+1] = n
        end
    end
    return res
end

local buyPack = function(name)
    local items = PACK_ITEMS[name]
    if not items then
        showNotification("Unknown pack", 2, true)
        return false
    end
    local count = 0
    for _, it in ipairs(items) do
        if buyItem(it) then count = count + 1 end
        task.wait(0.2)
    end
    showNotification("Bought " .. count .. "/" .. #items .. " from " .. name, 2)
    return count == #items
end

local getPawnPart = function()
    local parts = string.split(C.PawnShopPath, ".")
    local cur = Workspace
    for _, p in ipairs(parts) do
        if cur then cur = cur:FindFirstChild(p) else break end
    end
    if cur then
        if cur:IsA("Model") then return cur.PrimaryPart or cur:FindFirstChildWhichIsA("BasePart")
        elseif cur:IsA("BasePart") then return cur
        else return cur:FindFirstChildWhichIsA("BasePart") end
    end
    return nil
end

local sellRocks = function()
    local pp = getPawnPart()
    if not pp then
        showNotification("Pawn shop not found!", 5, true)
        return false
    end
    local r = getRoot()
    if not r then return false end
    r.CFrame = pp.CFrame + Vector3.new(0, 2, 0)
    local waited = 0
    while waited < C.TeleportDelayShop do
        if not state.moneyRunning then return false end
        task.wait(0.1)
        waited = waited + 0.1
    end
    if not state.moneyRunning then return false end
    local ev = ReplicatedStorage:FindFirstChild(C.SellEvent)
    if not ev then
        showNotification("Sell event missing!", 3, true)
        return false
    end
    pcall(function()
        if ev:IsA("RemoteEvent") then ev:FireServer(C.ShockStoneName, C.MoonStoneName)
        elseif ev:IsA("RemoteFunction") then ev:InvokeServer(C.ShockStoneName, C.MoonStoneName)
        else ev:Fire(C.ShockStoneName, C.MoonStoneName) end
    end)
    state.moneySold = state.moneySold + 1
    return true
end

local processMoneyQueue = function()
    if state.moneyProcessing then return end
    state.moneyProcessing = true
    task.spawn(function()
        local processed = 0
        while #state.moneyQueue > 0 and processed < C.MaxClicksPerFrame do
            local obj = table.remove(state.moneyQueue, 1)
            if isValid(obj) then
                if clickObj(obj) then state.moneyCollected = state.moneyCollected + 1 end
                processed = processed + 1
                task.wait(C.ClickDelay)
            end
        end
        state.moneyProcessing = false
        if #state.moneyQueue == 0 and state.moneyRunning then
            local moonStones = findByName(C.MoonStoneName)
            local shockStones = findByName(C.ShockStoneName)
            local valid = {}
            for _, s in ipairs(moonStones) do if isValid(s) then valid[#valid+1] = s end end
            for _, s in ipairs(shockStones) do if isValid(s) then valid[#valid+1] = s end end
            if #valid > 0 then
                state.moneySoldFlag = false
                for _, s in ipairs(valid) do
                    local already = false
                    for _, q in ipairs(state.moneyQueue) do if q == s then already = true break end end
                    if not already then state.moneyQueue[#state.moneyQueue+1] = s end
                end
                if #state.moneyQueue > 0 then processMoneyQueue() end
            elseif not state.moneySoldFlag then
                sellRocks()
                state.moneySoldFlag = true
            end
        end
    end)
end

local scanMoney = function()
    if not state.moneyRunning then return end
    local moonStones = findByName(C.MoonStoneName)
    local shockStones = findByName(C.ShockStoneName)
    local added = false
    for _, s in ipairs(moonStones) do
        if isValid(s) then
            local already = false
            for _, q in ipairs(state.moneyQueue) do if q == s then already = true break end end
            if not already then state.moneyQueue[#state.moneyQueue+1] = s added = true end
        end
    end
    for _, s in ipairs(shockStones) do
        if isValid(s) then
            local already = false
            for _, q in ipairs(state.moneyQueue) do if q == s then already = true break end end
            if not already then state.moneyQueue[#state.moneyQueue+1] = s added = true end
        end
    end
    if added then
        state.moneySoldFlag = false
        processMoneyQueue()
    end
end

local startMoney = function()
    if state.moneyRunning then return end
    if not getPawnPart() then
        showNotification("Pawn shop not found!", 5, true)
        return
    end
    state.moneyRunning = true
    state.moneyQueue = {}
    state.moneyProcessing = false
    state.moneyCollected = 0
    state.moneySold = 0
    state.moneySoldFlag = false
    scanMoney()
    state.moneyScanConn = RunService.Heartbeat:Connect(scanMoney)
    state.moneySellCoroutine = task.spawn(function()
        while state.moneyRunning do
            for _ = 1, C.SellInterval do
                if not state.moneyRunning then return end
                task.wait(1)
            end
            if state.moneyRunning then
                local moonStones = findByName(C.MoonStoneName)
                local shockStones = findByName(C.ShockStoneName)
                local has = false
                for _, s in ipairs(moonStones) do if isValid(s) then has = true break end end
                if not has then for _, s in ipairs(shockStones) do if isValid(s) then has = true break end end end
                if not has and not state.moneySoldFlag then
                    sellRocks()
                    state.moneySoldFlag = true
                end
            end
        end
    end)
    showNotification("Auto Money started", 2)
end

local stopMoney = function()
    if not state.moneyRunning then return end
    state.moneyRunning = false
    if state.moneyScanConn then state.moneyScanConn:Disconnect() state.moneyScanConn = nil end
    state.moneyQueue = {}
    state.moneyProcessing = false
    state.moneySellCoroutine = nil
    showNotification("Auto Money stopped", 2)
end

local getExplosive = function()
    if hasItem(C.ExplosiveName) then return true end
    for _, f in ipairs(getFactories()) do
        if not state.ballRunning then return false end
        if pressFactory(f, C.ExplosiveName) then
            local t = 0
            while t < C.WaitForItemTimeout and state.ballRunning do
                if hasItem(C.ExplosiveName) then return true end
                task.wait(0.5)
                t = t + 0.5
            end
        end
    end
    return false
end

local useExplosive = function()
    local c = getChar()
    if not c then return false end
    local tool = c:FindFirstChild(C.ExplosiveName)
    if not tool then
        local bp = player:FindFirstChildOfClass("Backpack")
        if bp then tool = bp:FindFirstChild(C.ExplosiveName) end
        if tool then tool.Parent = c task.wait(0.1) end
    end
    if tool then return pcall(function() tool:Activate() end) end
    return false
end

local ballClick = function(o) return clickObj(o) end

local startBall = function()
    if state.ballRunning then return end
    state.ballRunning = true
    state.ballClicked = 0
    state.ballTeleported = false
    task.spawn(function()
        while state.ballRunning do
            if not hasItem(C.ExplosiveName) then
                if not getExplosive() then task.wait(1) state.ballTeleported = false end
            end
            if hasItem(C.ExplosiveName) then
                if not state.ballTeleported then
                    teleport(C.TargetCoords)
                    state.ballTeleported = true
                    task.wait(0.5)
                end
                if useExplosive() then
                    local t = 0
                    while t < C.WaitForBallTimeout and state.ballRunning do
                        local balls = findByName(C.BallName)
                        if #balls > 0 then
                            for _, b in ipairs(balls) do
                                if ballClick(b) then state.ballClicked = state.ballClicked + 1 end
                                task.wait(C.ClickDelay)
                            end
                            state.ballTeleported = false
                            break
                        end
                        task.wait(0.1)
                        t = t + 0.1
                    end
                    state.ballTeleported = false
                else task.wait(1) end
            else task.wait(0.5) end
        end
    end)
    showNotification("Auto Ball started", 2)
end

local stopBall = function()
    if not state.ballRunning then return end
    state.ballRunning = false
    showNotification("Auto Ball stopped", 2)
end

local startExplosiveFastPlace = function()
    if state.explosiveFastPlaceRunning then return end
    state.explosiveFastPlaceRunning = true
    task.spawn(function()
        while state.explosiveFastPlaceRunning do
            local c = getChar()
            if not c then break end
            local tool = c:FindFirstChild(C.ExplosiveName)
            if not tool then
                local bp = player:FindFirstChildOfClass("Backpack")
                if bp then
                    local t = bp:FindFirstChild(C.ExplosiveName)
                    if t then t.Parent = c tool = t task.wait(0.1) end
                end
            end
            if tool then
                pcall(function() tool:Activate() end)
                task.wait(0.05)
            else break end
        end
        if state.explosiveFastPlaceRunning then
            state.explosiveFastPlaceRunning = false
            if rawget(guiElements, "explosiveFastPlaceToggle") then
                guiElements.explosiveFastPlaceToggle.Text = "START"
                guiElements.explosiveFastPlaceToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
            end
            showNotification("Explosive Fast Place finished", 2)
        end
    end)
    showNotification("Explosive Fast Place started", 2)
end

local stopExplosiveFastPlace = function()
    if not state.explosiveFastPlaceRunning then return end
    state.explosiveFastPlaceRunning = false
    showNotification("Explosive Fast Place stopped", 2)
end

local toggleExplosiveFastPlace = function()
    if state.explosiveFastPlaceRunning then stopExplosiveFastPlace() else startExplosiveFastPlace() end
end

local getRedMatterLocationData = function()
    local holder = Workspace:FindFirstChild("RedMatterLocation")
    if not holder then return nil, nil end
    local ok, value = pcall(function() return holder.Value end)
    if not ok or value == nil then return nil, nil end
    if typeof(value) == "Vector3" then return nil, value
    elseif typeof(value) == "CFrame" then return nil, value.Position
    elseif typeof(value) == "Instance" then
        local pos = nil
        pcall(function()
            if value:IsA("BasePart") then pos = value.Position
            elseif value:IsA("Model") then
                local p = value.PrimaryPart or value:FindFirstChildWhichIsA("BasePart")
                if p then pos = p.Position end
            end
        end)
        return value, pos
    end
    return nil, nil
end

local getRedMatterTarget = function()
    local obj, pos = getRedMatterLocationData()
    if pos then return obj, pos end
    local sources = findByName(C.RedMatterSourceName)
    if #sources > 0 then
        local src = sources[1]
        local srcPos = nil
        pcall(function()
            if src:IsA("BasePart") then srcPos = src.Position
            elseif src:IsA("Model") then
                local p = src.PrimaryPart or src:FindFirstChildWhichIsA("BasePart")
                if p then srcPos = p.Position end
            end
        end)
        if srcPos then return src, srcPos end
    end
    return nil, nil
end

local redClick = function(o) return clickObj(o) end

local startAutoRedMatter = function()
    if state.autoRedMatterRunning then return end
    state.autoRedMatterRunning = true
    state.redMatterClicked = 0
    state.redMatterTeleported = false
    task.spawn(function()
        while state.autoRedMatterRunning do
            if not hasItem(C.ExplosiveName) then
                if not buyItem(C.ExplosiveName) then task.wait(1) end
            end
            if hasItem(C.ExplosiveName) then
                local _, targetPos = getRedMatterTarget()
                if targetPos then
                    teleportWithTween(targetPos, C.RedMatterTweenDuration)
                    task.wait(0.2)
                    if useExplosive() then
                        local t = 0
                        while t < C.WaitForRedMatterTimeout and state.autoRedMatterRunning do
                            local redMatters = findByName(C.RedMatterName)
                            if #redMatters > 0 then
                                for _, rm in ipairs(redMatters) do
                                    if redClick(rm) then state.redMatterClicked = state.redMatterClicked + 1 end
                                    task.wait(C.ClickDelay)
                                end
                                break
                            end
                            task.wait(0.1)
                            t = t + 0.1
                        end
                    else task.wait(1) end
                else
                    showNotification("Red Matter target not found", 2, true)
                    task.wait(2)
                end
                task.wait(C.RedMatterTweenInterval)
            else task.wait(0.5) end
        end
    end)
    showNotification("Auto Red Matter started", 2)
end

local stopAutoRedMatter = function()
    if not state.autoRedMatterRunning then return end
    state.autoRedMatterRunning = false
    showNotification("Auto Red Matter stopped", 2)
end

local toggleAutoRedMatter = function()
    if state.autoRedMatterRunning then stopAutoRedMatter() else startAutoRedMatter() end
end

local beamBetween = function(p0, p1, color, width)
    color = color or Color3.fromRGB(255, 255, 255)
    width = width or 0.5
    local a0 = Instance.new("Attachment")
    a0.Parent = p0
    a0.Position = Vector3.new(0, 0, 0)
    local a1 = Instance.new("Attachment")
    a1.Parent = p1
    a1.Position = Vector3.new(0, 0, 0)
    local b = Instance.new("Beam")
    b.Attachment0 = a0
    b.Attachment1 = a1
    b.Color = ColorSequence.new(color)
    b.Width0 = width
    b.Width1 = width
    b.Transparency = NumberSequence.new(0.3)
    b.Parent = Workspace
    return {beam = b, att0 = a0, att1 = a1}
end

local destroyBeam = function(data)
    pcall(function()
        if data.beam then data.beam:Destroy() end
        if data.att0 then data.att0:Destroy() end
        if data.att1 then data.att1:Destroy() end
    end)
end

local toggleESP = function()
    state.espEnabled = not state.espEnabled
    if state.espEnabled then
        for _, v in ipairs(state.espConnections) do
            if v.beam then destroyBeam(v) end
            if v.charConn then v.charConn:Disconnect() end
            if v.highlight then v.highlight:Destroy() end
            if v.tempPart then pcall(function() v.tempPart:Destroy() end) end
        end
        state.espConnections = {}
        local addPlayer = function(pl)
            if pl == player then return end
            local c = pl.Character
            if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart")
            local my = getRoot()
            if not hrp or not my then return end
            local data = beamBetween(my, hrp, Color3.fromRGB(255, 255, 255), 0.3)
            local conn = pl.CharacterAdded:Connect(function(nc)
                task.wait(0.1)
                local nhrp = nc:FindFirstChild("HumanoidRootPart")
                local myRoot = getRoot()
                if nhrp and myRoot then
                    destroyBeam(data)
                    local nd = beamBetween(myRoot, nhrp, Color3.fromRGB(255, 255, 255), 0.3)
                    data.beam = nd.beam
                    data.att0 = nd.att0
                    data.att1 = nd.att1
                    for _, e in ipairs(state.espConnections) do
                        if e.player == pl then
                            e.beam = nd.beam
                            e.att0 = nd.att0
                            e.att1 = nd.att1
                            break
                        end
                    end
                end
            end)
            state.espConnections[#state.espConnections+1] = {player = pl, beam = data.beam, att0 = data.att0, att1 = data.att1, charConn = conn}
        end
        for _, p in ipairs(Players:GetPlayers()) do addPlayer(p) end
        state.espPlayerAddedConn = Players.PlayerAdded:Connect(function(p) if p ~= player then addPlayer(p) end end)
        local myRoot = getRoot()
        local addedRed = false
        local addRedEspTarget = function(part, isTemporary)
            if not part then return end
            local h = Instance.new("Highlight")
            h.Parent = part
            h.FillColor = Color3.fromRGB(255, 0, 0)
            h.OutlineColor = Color3.fromRGB(255, 0, 0)
            h.FillTransparency = 0
            h.OutlineTransparency = 0
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            local entry = {highlight = h, object = part}
            if isTemporary then entry.tempPart = part end
            if myRoot then
                local redBeam = beamBetween(myRoot, part, Color3.fromRGB(255, 0, 0), 0.7)
                redBeam.beam.Transparency = NumberSequence.new(0)
                entry.beam = redBeam.beam
                entry.att0 = redBeam.att0
                entry.att1 = redBeam.att1
            end
            state.espConnections[#state.espConnections+1] = entry
            addedRed = true
        end
        local rmObj, rmPos = getRedMatterLocationData()
        if rmObj then
            local part = nil
            pcall(function()
                if rmObj:IsA("BasePart") then part = rmObj
                elseif rmObj:IsA("Model") then part = rmObj.PrimaryPart or rmObj:FindFirstChildWhichIsA("BasePart") end
            end)
            if part then addRedEspTarget(part, false)
            elseif rmPos then
                local temp = Instance.new("Part")
                temp.Size = Vector3.new(1, 1, 1)
                temp.Anchored = true
                temp.CanCollide = false
                temp.Transparency = 1
                temp.Position = rmPos
                temp.Parent = Workspace
                addRedEspTarget(temp, true)
            end
        elseif rmPos then
            local temp = Instance.new("Part")
            temp.Size = Vector3.new(1, 1, 1)
            temp.Anchored = true
            temp.CanCollide = false
            temp.Transparency = 1
            temp.Position = rmPos
            temp.Parent = Workspace
            addRedEspTarget(temp, true)
        end
        if not addedRed then
            for _, src in ipairs(findByName(C.RedMatterSourceName)) do
                local p = nil
                pcall(function()
                    if src:IsA("BasePart") then p = src
                    elseif src:IsA("Model") then p = src.PrimaryPart or src:FindFirstChildWhichIsA("BasePart") end
                end)
                if p then addRedEspTarget(p, false) end
            end
        end
    else
        for _, v in ipairs(state.espConnections) do
            if v.beam then destroyBeam(v) end
            if v.charConn then v.charConn:Disconnect() end
            if v.highlight then v.highlight:Destroy() end
            if v.tempPart then pcall(function() v.tempPart:Destroy() end) end
        end
        state.espConnections = {}
        if state.espPlayerAddedConn then state.espPlayerAddedConn:Disconnect() state.espPlayerAddedConn = nil end
    end
    showNotification("ESP " .. (state.espEnabled and "ON" or "OFF"), 2)
end

local setupFly = function()
    local c = getChar()
    if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if state.flyEnabled then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.P = 1e5
        bv.Parent = root
        state.flyBodyVelocity = bv
        hum.PlatformStand = true
        hum.AutoRotate = true
        state.flyConnection = RunService.RenderStepped:Connect(function()
            if not state.flyEnabled then return end
            local speed = (state.flySpeedMultiplier or 1) * C.BaseWalkSpeed
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local dir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
            bv.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.new(0, 0, 0)
        end)
    else
        if state.flyBodyVelocity then pcall(function() state.flyBodyVelocity:Destroy() end) state.flyBodyVelocity = nil end
        if state.flyConnection then state.flyConnection:Disconnect() state.flyConnection = nil end
        hum.PlatformStand = false
    end
end

local toggleFly = function()
    state.flyEnabled = not state.flyEnabled
    setupFly()
    showNotification("Fly " .. (state.flyEnabled and "ON" or "OFF"), 2)
end

local setFlySpeed = function(value)
    if typeof(value) ~= "number" then return end
    state.flySpeedMultiplier = clamp(value, FLY_MIN, FLY_MAX)
end

local findSat = function(name)
    local obj = Workspace:FindFirstChild(name)
    if obj and (obj:IsA("MeshPart") or obj:IsA("BasePart")) then return obj end
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o.Name == name and (o:IsA("MeshPart") or o:IsA("BasePart")) then return o end
    end
    return nil
end

local startControl = function(target)
    if state.controlEnabled then return end
    state.controlTarget = target or "Phobos"
    state.controlEnabled = true
    state.controlSatellite = findSat(state.controlTarget)
    if not state.controlSatellite then
        showNotification("Satellite not found", 3, true)
        state.controlEnabled = false
        return
    end
    task.spawn(function()
        while state.controlEnabled do
            local sat = state.controlSatellite
            if not sat or not sat.Parent then
                sat = findSat(state.controlTarget)
                if sat then state.controlSatellite = sat end
            end
            if sat and sat.Parent then
                local root = getRoot()
                if root then root.CFrame = sat.CFrame + Vector3.new(0, 2, 0) end
                if not state.flyEnabled then toggleFly() end
                if state.controlBodyVelocity and not state.controlBodyVelocity.Parent then
                    pcall(function() state.controlBodyVelocity:Destroy() end)
                    state.controlBodyVelocity = nil
                end
                if not state.controlBodyVelocity then
                    local bv = Instance.new("BodyVelocity")
                    bv.MaxForce = Vector3.new(9e99, 9e99, 9e99)
                    bv.P = 1e6
                    bv.Parent = sat
                    state.controlBodyVelocity = bv
                end
                if state.controlConnection and not state.controlConnection.Connected then state.controlConnection = nil end
                if not state.controlConnection then
                    state.controlConnection = RunService.RenderStepped:Connect(function()
                        if not state.controlEnabled then return end
                        local r = getRoot()
                        local currentSat = state.controlSatellite
                        if not r or not currentSat or not currentSat.Parent or not state.controlBodyVelocity or not state.controlBodyVelocity.Parent then return end
                        local diff = (r.Position + Vector3.new(0, -5, 0)) - currentSat.Position
                        if diff.Magnitude > 1 then state.controlBodyVelocity.Velocity = diff.Unit * math.min(diff.Magnitude * 10, 500)
                        else state.controlBodyVelocity.Velocity = Vector3.new(0, 0, 0) end
                    end)
                end
                task.wait(0.5)
            else task.wait(1) end
        end
    end)
    showNotification("Control " .. state.controlTarget .. " started", 2)
end

local stopControl = function()
    if not state.controlEnabled then return end
    state.controlEnabled = false
    if state.controlBodyVelocity then pcall(function() state.controlBodyVelocity:Destroy() end) state.controlBodyVelocity = nil end
    if state.controlConnection then state.controlConnection:Disconnect() state.controlConnection = nil end
    state.controlSatellite = nil
    showNotification("Control stopped", 2)
end

local toggleControl = function(target)
    if state.controlEnabled then stopControl() else startControl(target) end
end

local createLights = function()
    local lights = {}
    for x = -C.GridBounds, C.GridBounds, C.GridStep do
        for z = -C.GridBounds, C.GridBounds, C.GridStep do
            local light = Instance.new("PointLight")
            light.Brightness = C.Brightness
            light.Range = C.Radius
            light.Color = Color3.fromRGB(255, 255, 255)
            local anchor = Instance.new("Part")
            anchor.Size = Vector3.new(1, 1, 1)
            anchor.Anchored = true
            anchor.CanCollide = false
            anchor.Transparency = 1
            anchor.Position = Vector3.new(x, 100, z)
            anchor.Parent = Workspace
            light.Parent = anchor
            lights[#lights+1] = anchor
        end
    end
    return lights
end

local stopFullBright = function()
    if state.fullBrightRunning then
        for _, o in ipairs(state.fullBrightLights) do pcall(function() o:Destroy() end) end
        state.fullBrightLights = {}
        state.fullBrightRunning = false
        showNotification("FullBright stopped", 2)
    end
end

local startFullBright = function()
    if state.fullBrightRunning then return end
    stopFullBright()
    local newLights = createLights()
    state.fullBrightLights = newLights
    state.fullBrightRunning = true
    local r = getRoot()
    if r then
        local l = Instance.new("PointLight")
        l.Name = "FullBrightPlayerLight"
        l.Brightness = C.Brightness
        l.Range = C.Radius
        l.Color = Color3.fromRGB(255, 255, 255)
        l.Parent = r
        state.fullBrightLights[#state.fullBrightLights+1] = l
    end
    showNotification("FullBright started", 2)
end

local toggleFullBright = function()
    if state.fullBrightRunning then stopFullBright() else startFullBright() end
end

local startAutoBuy = function()
    if state.autoBuyEnabled then return end
    if not state.buyTarget or state.buyTarget == "" then
        showNotification("Select item first", 2, true)
        return
    end
    if isPack(state.buyTarget) then
        showNotification("Auto Buy cannot use packs", 2, true)
        return
    end
    state.autoBuyEnabled = true
    task.spawn(function()
        while state.autoBuyEnabled do
            local factories = getFactories()
            if #factories > 0 then
                for i = #factories, 2, -1 do
                    local j = math.random(1, i)
                    factories[i], factories[j] = factories[j], factories[i]
                end
                for _, f in ipairs(factories) do
                    if not state.autoBuyEnabled then break end
                    pressFactory(f, state.buyTarget)
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)
    showNotification("Auto Buy started", 2)
end

local stopAutoBuy = function()
    if not state.autoBuyEnabled then return end
    state.autoBuyEnabled = false
    showNotification("Auto Buy stopped", 2)
end

local toggleAutoBuy = function()
    if state.autoBuyEnabled then stopAutoBuy() else startAutoBuy() end
end

local startRuin = function()
    if state.ruinEnabled then return end
    state.ruinEnabled = true
    task.spawn(function()
        while state.ruinEnabled do
            local factories = getFactories()
            if #factories > 0 then
                for i = #factories, 2, -1 do
                    local j = math.random(1, i)
                    factories[i], factories[j] = factories[j], factories[i]
                end
                for _, f in ipairs(factories) do
                    if not state.ruinEnabled then break end
                    pressFactory(f, C.RuinItem)
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)
    showNotification("Ruin started", 2)
end

local stopRuin = function()
    if not state.ruinEnabled then return end
    state.ruinEnabled = false
    showNotification("Ruin stopped", 2)
end

local toggleRuin = function()
    if state.ruinEnabled then stopRuin() else startRuin() end
end

local collectAll = function()
    local detectors = {}
    local structures = Workspace:FindFirstChild("Structures")
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("ClickDetector") then
            local skip = false
            if structures and o:IsDescendantOf(structures) then skip = true
            else
                local p = o.Parent
                while p do
                    if p.Name == "Ship" or p.Name == "Control Panel" then skip = true break end
                    p = p.Parent
                end
            end
            if not skip then detectors[#detectors+1] = o end
        end
    end
    if #detectors == 0 then
        showNotification("No detectors", 2, true)
        return
    end
    local clicked = 0
    for _, d in ipairs(detectors) do
        if fireDetector(d) then clicked = clicked + 1 end
        task.wait(C.CollectAllDelay)
    end
    showNotification("Clicked " .. clicked .. " objects", 2)
end

local teleportToShop = function()
    local koller = Workspace:FindFirstChild("Koller")
    if koller then
        local head = koller:FindFirstChild("Head")
        if head then
            teleportCFrame(head.CFrame)
            showNotification("Teleported to shop", 2)
            return
        end
    end
    showNotification("Shop not found", 2, true)
end

local teleportToSellShop = function()
    local pawnShop = Workspace:FindFirstChild("PawnShop")
    if pawnShop then
        local pawnshopGuy = pawnShop:FindFirstChild("PawnshopGuy")
        if pawnshopGuy then
            local head = pawnshopGuy:FindFirstChild("Head")
            if head then
                teleportCFrame(head.CFrame)
                showNotification("Teleported to sell shop", 2)
                return
            end
        end
    end
    showNotification("Sell shop not found", 2, true)
end

local sellRocksManual = function()
    local ev = ReplicatedStorage:FindFirstChild(C.SellEvent)
    if not ev then
        showNotification("Sell event not found!", 2, true)
        return false
    end
    pcall(function()
        if ev:IsA("RemoteEvent") then ev:FireServer(C.ShockStoneName, C.MoonStoneName)
        elseif ev:IsA("RemoteFunction") then ev:InvokeServer(C.ShockStoneName, C.MoonStoneName)
        else ev:Fire(C.ShockStoneName, C.MoonStoneName) end
    end)
    showNotification("Rocks sold", 2)
    return true
end

local getBodyDistance = function(name)
    return BODY_DISTANCES[string.lower(name)]
end

local getBodySizeFromPivot = function(planet)
    local ok, pivot = pcall(function() return planet:GetPivot() end)
    if not ok or not pivot then return nil end
    local ok2, _, size = pcall(function() return planet:GetBoundingBox() end)
    if ok2 and size then
        local maxDim = math.max(size.X, size.Y, size.Z)
        if maxDim > 0 then return maxDim end
    end
    return nil
end

local isMeshGiant = function(name) return MESH_GIANTS[string.lower(name)] == true end

local getPlanets = function()
    local planets = {}
    local folder = Workspace:FindFirstChild("Planets")
    if folder then
        for _, p in ipairs(folder:GetChildren()) do
            if p:IsA("Model") then planets[#planets+1] = {name = p.Name, object = p} end
        end
    end
    return planets
end

local getSpawns = function()
    local spawns = {}
    local structures = Workspace:FindFirstChild("Structures")
    if structures then
        local counts = {}
        for _, child in ipairs(structures:GetChildren()) do
            if child.Name == "CustomSpawn" then
                local ap = child:FindFirstChild("AssociatedPlanet")
                local pName = "Unknown"
                if ap then
                    local val = ap.Value
                    if typeof(val) == "Instance" then pName = val.Name
                    elseif typeof(val) == "string" then pName = val
                    else pName = tostring(val) end
                end
                counts[pName] = (counts[pName] or 0) + 1
                local num = counts[pName]
                local name = "Spawn-" .. num .. "(" .. pName .. ")"
                local reqMet = child:FindFirstChild("RequirementsMet")
                local isActive = true
                if reqMet and (reqMet:IsA("BoolValue") or reqMet:IsA("ValueBase")) then
                    isActive = reqMet.Value == true
                end
                spawns[#spawns+1] = {name = name, planet = pName, object = child, active = isActive}
            end
        end
    end
    return spawns
end

local getPlayers = function()
    local players = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= player then
            local char = pl.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then players[#players+1] = {name = pl.Name, object = pl} end
        end
    end
    return players
end

local teleportToPlanet = function(planetName)
    local folder = Workspace:FindFirstChild("Planets")
    if not folder then showNotification("Planets folder not found", 2, true) return end
    local planet = folder:FindFirstChild(planetName)
    if not planet then showNotification("Planet not found: " .. planetName, 2, true) return end
    local ok, pivot = pcall(function() return planet:GetPivot() end)
    if not ok or not pivot then showNotification("Cannot get planet pivot", 2, true) return end
    local root = getRoot()
    if not root then showNotification("Character not found", 2, true) return end
    local distance = getBodyDistance(planetName)
    local source = "table"
    if not distance then
        local bodySize = getBodySizeFromPivot(planet)
        if bodySize then
            if isMeshGiant(planetName) then distance = (bodySize / 2) + 3500 source = "mesh_giant"
            else distance = (bodySize / 2) + 35 source = "surface" end
        else distance = 500 source = "fallback" end
    end
    root.CFrame = pivot + Vector3.new(0, distance, 0)
    showNotification("Teleported to " .. planetName .. " (" .. math.floor(distance) .. " studs, " .. source .. ")", 2)
end

local teleportToSpawn = function(spawnName)
    local structures = Workspace:FindFirstChild("Structures")
    if not structures then showNotification("Structures not found", 2, true) return end
    local counts = {}
    for _, child in ipairs(structures:GetChildren()) do
        if child.Name == "CustomSpawn" then
            local ap = child:FindFirstChild("AssociatedPlanet")
            local pName = "Unknown"
            if ap then
                local val = ap.Value
                if typeof(val) == "Instance" then pName = val.Name
                elseif typeof(val) == "string" then pName = val
                else pName = tostring(val) end
            end
            counts[pName] = (counts[pName] or 0) + 1
            local num = counts[pName]
            local name = "Spawn-" .. num .. "(" .. pName .. ")"
            if name == spawnName then
                local root = getRoot()
                if root then
                    local spawnPos = nil
                    if child:IsA("Model") then
                        local ok, pivot = pcall(function() return child:GetPivot() end)
                        if ok and pivot then
                            spawnPos = pivot.Position
                        else
                            local primary = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
                            if primary then spawnPos = primary.Position end
                        end
                    elseif child:IsA("BasePart") then
                        spawnPos = child.Position
                    end
                    if spawnPos then
                        root.CFrame = CFrame.new(spawnPos + Vector3.new(0, 5, 0))
                        showNotification("Teleported to spawn on " .. pName, 2)
                        return
                    end
                end
            end
        end
    end
    showNotification("Spawn not found", 2, true)
end

local teleportToSaffra = function()
    local root = getRoot()
    if root then root.CFrame = SAFFRA_CFRAME showNotification("Teleported to Saffra", 2)
    else showNotification("Character not found", 2, true) end
end

local teleportToMonolith = function(monolithName)
    local monolith = nil
    for _, m in ipairs(MONOLITHS) do if m.name == monolithName then monolith = m break end end
    if not monolith then showNotification("Monolith not found", 2, true) return end
    local root = getRoot()
    if root then root.CFrame = CFrame.new(monolith.pos) showNotification("Teleported to " .. monolithName, 2)
    else showNotification("Character not found", 2, true) end
end

local teleportToPlayer = function(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer then showNotification("Player not found", 2, true) return end
    local char = targetPlayer.Character
    if not char then showNotification("Player has no character", 2, true) return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then showNotification("Player has no HumanoidRootPart", 2, true) return end
    local root = getRoot()
    if root then root.CFrame = hrp.CFrame + Vector3.new(0, 0, 5) showNotification("Teleported to " .. playerName, 2)
    else showNotification("Character not found", 2, true) end
end

player.CharacterAdded:Connect(function()
    task.wait(0.5)
    local c = player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = state.walkSpeed end
    end
end)

local emergencyAirEnabled = false
local emergencyAirThread = nil
local emergencyActive = false

local PLANET_PRIORITY = {
    mercury = 3, venus = 3, earth = 3, mars = 3, alcaeus = 3, ceres = 3, pluto = 3, haumea = 3, makemake = 3, nibiru = 3,
    moon = 2, io = 2, europa = 2, ganymede = 2, callisto = 2, mimas = 2, enceladus = 2, tethys = 2, dione = 2, rhea = 2, titan = 2, iapetus = 2, miranda = 2, ariel = 2, umbriel = 2, titania = 2, oberon = 2, triton = 2, proteus = 2, charon = 2,
    sun = 1, jupiter = 1, saturn = 1, uranus = 1, neptune = 1
}

local getSpawnPriority = function(spawnData)
    local pName = string.lower(spawnData.planet or "unknown")
    return PLANET_PRIORITY[pName] or 0
end

local getAirValue = function()
    local lopl = Workspace:FindFirstChild("loplp010")
    local airObj = lopl and lopl:FindFirstChild("Air")
    if airObj and (airObj:IsA("IntValue") or airObj:IsA("NumberValue")) then
        return airObj.Value
    end
    return 100
end

local getHealthData = function()
    local c = getChar()
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health, hum.MaxHealth end
    return 100, 100
end

local stopAllFarms = function()
    local saved = {}
    if state.moneyRunning then stopMoney() saved.money = true end
    if state.ballRunning then stopBall() saved.ball = true end
    if state.autoRedMatterRunning then stopAutoRedMatter() saved.redMatter = true end
    if state.explosiveFastPlaceRunning then stopExplosiveFastPlace() saved.efp = true end
    if state.autoBuyEnabled then stopAutoBuy() saved.autoBuy = true end
    if state.ruinEnabled then stopRuin() saved.ruin = true end
    return saved
end

local startSavedFarms = function(saved)
    if saved.money then startMoney() end
    if saved.ball then startBall() end
    if saved.redMatter then startAutoRedMatter() end
    if saved.efp then startExplosiveFastPlace() end
    if saved.autoBuy then startAutoBuy() end
    if saved.ruin then startRuin() end
end

local triggerEmergencyAir = function()
    if emergencyActive then return end
    emergencyActive = true
    local savedStates = stopAllFarms()
    local spawns = getSpawns()
    if #spawns == 0 then
        showNotification("Emergency Air: No spawns!", 3, true)
        emergencyActive = false
        return
    end
    local bestPriority = -1
    local bestSpawns = {}
    for _, s in ipairs(spawns) do
        local p = getSpawnPriority(s)
        if p > bestPriority then
            bestPriority = p
            bestSpawns = {s}
        elseif p == bestPriority then
            bestSpawns[#bestSpawns+1] = s
        end
    end
    local chosenSpawn = bestSpawns[math.random(1, #bestSpawns)]
    teleportToSpawn(chosenSpawn.name)
    showNotification("Emergency Air! TP to " .. chosenSpawn.planet, 3)
    task.spawn(function()
        while emergencyActive and emergencyAirEnabled do
            local airVal = getAirValue()
            local hp, maxHp = getHealthData()
            if airVal >= 100 and hp >= maxHp then break end
            task.wait(1)
        end
        if emergencyAirEnabled then
            startSavedFarms(savedStates)
            showNotification("Air resolved! Farms restarted.", 3)
        end
        emergencyActive = false
    end)
end

local toggleEmergencyAir = function()
    emergencyAirEnabled = not emergencyAirEnabled
    if emergencyAirEnabled then
        if emergencyAirThread then task.cancel(emergencyAirThread) end
        emergencyAirThread = task.spawn(function()
            while emergencyAirEnabled do
                local airVal = getAirValue()
                local hp, maxHp = getHealthData()
                if airVal == 0 and (maxHp - hp) >= 50 and not emergencyActive then
                    triggerEmergencyAir()
                end
                task.wait(1)
            end
        end)
    else
        if emergencyAirThread then
            task.cancel(emergencyAirThread)
            emergencyAirThread = nil
        end
    end
end

local createGUI = function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "AutoFarmGUI"
    sg.ResetOnSpawn = false
    sg.Parent = player.PlayerGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 480, 0, 750)
    frame.Position = UDim2.new(0.5, -240, 0.5, -375)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local frameStroke = Instance.new("UIStroke", frame)
    frameStroke.Color = Color3.fromRGB(100, 100, 150)
    frameStroke.Thickness = 1
    frameStroke.Transparency = 0.4
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -50, 0, 34)
    title.Position = UDim2.new(0, 10, 0, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "SSE2 Ultimate"
    title.TextXAlignment = Enum.TextXAlignment.Left
    local close = Instance.new("TextButton", frame)
    close.Size = UDim2.new(0, 32, 0, 26)
    close.Position = UDim2.new(1, -40, 0, 6)
    close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    close.BackgroundTransparency = 0.15
    close.BorderSizePixel = 0
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Text = "X"
    close.AutoButtonColor = false
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
    local status = Instance.new("TextLabel", frame)
    status.Size = UDim2.new(1, -16, 0, 20)
    status.Position = UDim2.new(0, 8, 1, -24)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 11
    status.TextColor3 = Color3.fromRGB(160, 160, 170)
    status.Text = "Idle"
    status.TextXAlignment = Enum.TextXAlignment.Left

    local tabBar = Instance.new("Frame", frame)
    tabBar.Size = UDim2.new(1, -10, 0, 34)
    tabBar.Position = UDim2.new(0, 5, 0, 40)
    tabBar.BackgroundTransparency = 1
    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 3)
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size = UDim2.new(1, -10, 1, -102)
    scroll.Position = UDim2.new(0, 5, 0, 78)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

    local TAB_NAMES = {"Auto Farm", "Buy", "Teleports", "Basic Hacks", "Other", "External"}
    local catFrames = {}
    local catLayouts = {}
    local catOrders = {}
    local currentTab = "Auto Farm"

    for _, name in ipairs(TAB_NAMES) do
        local f = Instance.new("Frame", scroll)
        f.Name = name
        f.Size = UDim2.new(1, 0, 0, 0)
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.Visible = (name == currentTab)
        local ord = 0
        for i, n in ipairs(TAB_NAMES) do if n == name then ord = i break end end
        f.LayoutOrder = ord
        local l = Instance.new("UIListLayout", f)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Padding = UDim.new(0, 6)
        local p = Instance.new("UIPadding", f)
        p.PaddingTop = UDim.new(0, 2)
        p.PaddingBottom = UDim.new(0, 2)
        p.PaddingLeft = UDim.new(0, 2)
        p.PaddingRight = UDim.new(0, 2)
        l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            f.Size = UDim2.new(1, 0, 0, l.AbsoluteContentSize.Y + 8)
        end)
        catFrames[name] = f
        catLayouts[name] = l
        catOrders[name] = 0
    end

    local updateCanvas = function()
        if not scroll.Parent then return end
        local totalHeight = 0
        for _, name in ipairs(TAB_NAMES) do
            if catFrames[name].Visible then
                local l = catLayouts[name]
                totalHeight = totalHeight + l.AbsoluteContentSize.Y + 12
            end
        end
        scroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    end

    for _, name in ipairs(TAB_NAMES) do
        catLayouts[name]:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            task.defer(updateCanvas)
        end)
    end

    local newFrame = function(category, height, visible)
        catOrders[category] = catOrders[category] + 1
        local f = Instance.new("Frame", catFrames[category])
        f.Size = UDim2.new(1, 0, 0, height or 30)
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.LayoutOrder = catOrders[category]
        if visible == nil then f.Visible = true else f.Visible = visible end
        return f
    end

    local makeCorner = function(parent, radius)
        local c = Instance.new("UICorner", parent)
        c.CornerRadius = UDim.new(0, radius or 8)
        return c
    end

    local makeStroke = function(parent, color)
        local s = Instance.new("UIStroke", parent)
        s.Color = color or Color3.fromRGB(80, 80, 110)
        s.Thickness = 1
        s.Transparency = 0.5
        return s
    end

    local styleRow = function(f, transparency)
        f.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        f.BackgroundTransparency = transparency or 0.35
        f.BorderSizePixel = 0
        makeCorner(f, 8)
        makeStroke(f, Color3.fromRGB(80, 80, 110))
    end

    local createTextLabel = function(parent, text, size, position, color, textSize, align)
        local l = Instance.new("TextLabel", parent)
        l.Size = size
        l.Position = position
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.TextSize = textSize or 13
        l.TextColor3 = color or Color3.fromRGB(220, 220, 220)
        l.Text = text
        l.TextXAlignment = align or Enum.TextXAlignment.Left
        l.TextWrapped = true
        return l
    end

    local createButton = function(parent, text, size, position, color, textSize)
        local b = Instance.new("TextButton", parent)
        b.Size = size
        b.Position = position
        b.BackgroundColor3 = color or Color3.fromRGB(0, 150, 200)
        b.BackgroundTransparency = 0.15
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamBold
        b.TextSize = textSize or 12
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Text = text
        b.AutoButtonColor = false
        makeCorner(b, 8)
        return b
    end

    local updateStatus = function()
        local parts = {}
        if state.moneyRunning then parts[#parts+1] = "Money" end
        if state.ballRunning then parts[#parts+1] = "Ball" end
        if state.fullBrightRunning then parts[#parts+1] = "FullBright" end
        if state.autoBuyEnabled then parts[#parts+1] = "AutoBuy" end
        if state.ruinEnabled then parts[#parts+1] = "Ruin" end
        if state.explosiveFastPlaceRunning then parts[#parts+1] = "EFP" end
        if state.espEnabled then parts[#parts+1] = "ESP" end
        if state.autoRedMatterRunning then parts[#parts+1] = "RedMatter" end
        if state.flyEnabled then parts[#parts+1] = "Fly" end
        if state.controlEnabled then parts[#parts+1] = "Control" end
        status.Text = #parts > 0 and ("Running: " .. table.concat(parts, " + ")) or "Idle"
    end

    local addPlainLabelRow = function(category, text, color, textSize, height)
        local row = newFrame(category, height or 22)
        return createTextLabel(row, text, UDim2.new(1, -8, 1, 0), UDim2.new(0, 8, 0, 0), color, textSize, Enum.TextXAlignment.Left)
    end

    local addToggleRow = function(category, labelText, callback, getState, labelColor)
        local row = newFrame(category, 34)
        styleRow(row)
        createTextLabel(row, labelText, UDim2.new(0.66, -8, 1, 0), UDim2.new(0, 8, 0, 0), labelColor, 13, Enum.TextXAlignment.Left)
        local btn = createButton(row, "START", UDim2.new(0.28, 0, 0, 26), UDim2.new(0.70, 0, 0.5, -13), Color3.fromRGB(0, 150, 200), 12)
        local refresh = function()
            local on = getState and getState() or false
            btn.Text = on and "STOP" or "START"
            btn.BackgroundColor3 = on and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(0, 150, 200)
        end
        btn.MouseButton1Click:Connect(function() callback() refresh() updateStatus() end)
        refresh()
        return btn, refresh
    end

    local dropdowns = {}
    local addDropdownList = function(category)
        local list = newFrame(category, 0, false)
        styleRow(list, 0.15)
        local dl = Instance.new("UIListLayout", list)
        dl.SortOrder = Enum.SortOrder.LayoutOrder
        dl.Padding = UDim.new(0, 2)
        local dp = Instance.new("UIPadding", list)
        dp.PaddingTop = UDim.new(0, 3)
        dp.PaddingBottom = UDim.new(0, 3)
        dp.PaddingLeft = UDim.new(0, 3)
        dp.PaddingRight = UDim.new(0, 3)
        dropdowns[#dropdowns+1] = list
        return list
    end

    local fillListFrame = function(list, items, onPress)
        for _, ch in ipairs(list:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
        if #items == 0 then items = {{display = "Empty", value = "Empty"}} end
        for _, item in ipairs(items) do
            local isTable = type(item) == "table"
            local displayText = isTable and item.display or item
            local value = isTable and item.value or item
            local textColor = isTable and item.color or nil
            local b = createButton(list, displayText, UDim2.new(1, -6, 0, 22), UDim2.new(0, 0, 0, 0), Color3.fromRGB(45, 45, 70), 12)
            if textColor then b.TextColor3 = textColor end
            b.MouseButton1Click:Connect(function()
                onPress(value)
                list.Visible = false
                task.defer(updateCanvas)
            end)
        end
        list.Size = UDim2.new(1, 0, 0, (#items * 24) + 10)
        task.defer(updateCanvas)
    end

    local function createSliderRow(category, label, minVal, maxVal, defaultVal, applyFunc, formatFunc)
        local row = newFrame(category, 54)
        styleRow(row)
        local lbl = createTextLabel(row, label .. ": " .. (formatFunc and formatFunc(defaultVal) or tostring(math.floor(defaultVal + 0.5))), UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 4), Color3.fromRGB(220, 220, 220), 12, Enum.TextXAlignment.Left)
        local bg = Instance.new("TextButton", row)
        bg.Size = UDim2.new(1, -20, 0, 12)
        bg.Position = UDim2.new(0, 10, 0, 32)
        bg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        bg.BorderSizePixel = 0
        bg.Text = ""
        bg.AutoButtonColor = false
        makeCorner(bg, 6)
        makeStroke(bg, Color3.fromRGB(80, 80, 110))
        local fill = Instance.new("Frame", bg)
        fill.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
        fill.BorderSizePixel = 0
        makeCorner(fill, 6)
        local knob = Instance.new("TextButton", bg)
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Text = ""
        knob.AutoButtonColor = false
        makeCorner(knob, 8)
        local dragging = false
        local currentVal = defaultVal
        local function updateUI()
            local rel = (currentVal - minVal) / (maxVal - minVal)
            rel = clamp(rel, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -8, 0.5, -8)
            local displayVal = formatFunc and formatFunc(currentVal) or tostring(math.floor(currentVal + 0.5))
            lbl.Text = label .. ": " .. displayVal
        end
        local function setFromX(x)
            local bgX = bg.AbsolutePosition.X
            local bgW = bg.AbsoluteSize.X
            if bgW <= 0 then return end
            local rel = clamp((x - bgX) / bgW, 0, 1)
            currentVal = minVal + rel * (maxVal - minVal)
            applyFunc(currentVal)
            updateUI()
        end
        bg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                setFromX(input.Position.X)
            end
        end)
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                setFromX(input.Position.X)
            end
        end)
        local changedConn = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                setFromX(input.Position.X)
            end
        end)
        local endedConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        updateUI()
        return {
            update = function(val)
                currentVal = val
                applyFunc(val)
                updateUI()
            end,
            getValue = function() return currentVal end,
            connections = {changedConn, endedConn}
        }
    end

    local applyWalkSpeed = function(val)
        state.walkSpeed = val
        local c = getChar()
        if c then
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val end
        end
    end

    local applyGravity = function(val)
        state.gravity = val
        Workspace.Gravity = val
    end

    addPlainLabelRow("Auto Farm", "Money (Moonstone + Shockstone)", Color3.fromRGB(255, 200, 100), 15, 24)
    addToggleRow("Auto Farm", "Auto Collect & Sell", function() if state.moneyRunning then stopMoney() else startMoney() end end, function() return state.moneyRunning end, Color3.fromRGB(255, 200, 100))
    local moneyStats = addPlainLabelRow("Auto Farm", "Collected: 0 | Sold: 0", Color3.fromRGB(200, 200, 200), 12, 20)
    addPlainLabelRow("Auto Farm", "Ball Lightning", Color3.fromRGB(150, 200, 255), 15, 24)
    addToggleRow("Auto Farm", "Auto Ball Lightning", function() if state.ballRunning then stopBall() else startBall() end end, function() return state.ballRunning end, Color3.fromRGB(150, 200, 255))
    local ballStats = addPlainLabelRow("Auto Farm", "Clicked: 0", Color3.fromRGB(200, 200, 200), 12, 20)
    addPlainLabelRow("Auto Farm", "Red Matter", Color3.fromRGB(255, 100, 255), 15, 24)
    addToggleRow("Auto Farm", "Auto Red Matter", toggleAutoRedMatter, function() return state.autoRedMatterRunning end, Color3.fromRGB(255, 100, 255))
    local redMatterStats = addPlainLabelRow("Auto Farm", "Clicked: 0", Color3.fromRGB(200, 200, 200), 12, 20)

    local collectRow = newFrame("Auto Farm", 36)
    styleRow(collectRow)
    createTextLabel(collectRow, "Collect ALL", UDim2.new(0.55, 0, 1, 0), UDim2.new(0, 8, 0, 0), Color3.fromRGB(255, 100, 100), 14, Enum.TextXAlignment.Left)
    local collectBtn = createButton(collectRow, "GO!", UDim2.new(0.28, 0, 0, 26), UDim2.new(0.68, 0, 0.5, -13), Color3.fromRGB(200, 100, 0), 12)
    collectBtn.MouseButton1Click:Connect(collectAll)

    addPlainLabelRow("Buy", "Factory / Packs", Color3.fromRGB(100, 255, 100), 15, 24)
    local factoryRow = newFrame("Buy", 36)
    styleRow(factoryRow)
    createTextLabel(factoryRow, "Item / Pack", UDim2.new(0.22, 0, 1, 0), UDim2.new(0, 8, 0, 0), Color3.fromRGB(220, 220, 220), 12, Enum.TextXAlignment.Left)
    local factoryDrop = createButton(factoryRow, state.buyTarget or "Select item", UDim2.new(0.42, 0, 0, 26), UDim2.new(0.25, 0, 0.5, -13), Color3.fromRGB(45, 45, 70), 11)
    local factoryBuy = createButton(factoryRow, "Buy", UDim2.new(0.20, 0, 0, 26), UDim2.new(0.70, 0, 0.5, -13), Color3.fromRGB(0, 180, 0), 12)
    local factoryList = addDropdownList("Buy")
    factoryDrop.MouseButton1Click:Connect(function()
        factoryList.Visible = not factoryList.Visible
        if factoryList.Visible then
            local items = getAvailableItems()
            for _, packName in ipairs(PACK_ORDER) do items[#items+1] = packName end
            fillListFrame(factoryList, items, function(name)
                if name ~= "Empty" then state.buyTarget = name factoryDrop.Text = name end
            end)
        end
        task.defer(updateCanvas)
    end)
    factoryBuy.MouseButton1Click:Connect(function()
        local target = state.buyTarget
        if not target or target == "" or target == "Empty" then
            showNotification("Select item or pack first", 2, true)
            return
        end
        if isPack(target) then task.spawn(function() buyPack(target) end) else buyItem(target) end
    end)

    addPlainLabelRow("Buy", "Direct Buy", Color3.fromRGB(100, 255, 200), 15, 24)
    local directBuyRow = newFrame("Buy", 36)
    styleRow(directBuyRow)
    createTextLabel(directBuyRow, "Item", UDim2.new(0.15, 0, 1, 0), UDim2.new(0, 8, 0, 0), Color3.fromRGB(220, 220, 220), 12, Enum.TextXAlignment.Left)
    local directDrop = createButton(directBuyRow, "Select item", UDim2.new(0.45, 0, 0, 26), UDim2.new(0.18, 0, 0.5, -13), Color3.fromRGB(45, 45, 70), 11)
    local directBuyBtn = createButton(directBuyRow, "Buy Direct", UDim2.new(0.22, 0, 0, 26), UDim2.new(0.68, 0, 0.5, -13), Color3.fromRGB(0, 150, 100), 11)
    local directList = addDropdownList("Buy")
    local selectedDirectItem = "Factory"
    directDrop.MouseButton1Click:Connect(function()
        directList.Visible = not directList.Visible
        if directList.Visible then
            fillListFrame(directList, DIRECT_BUY_ITEMS, function(name)
                if name ~= "Empty" then selectedDirectItem = name directDrop.Text = name end
            end)
        end
        task.defer(updateCanvas)
    end)
    directBuyBtn.MouseButton1Click:Connect(function()
        if selectedDirectItem and selectedDirectItem ~= "Empty" then buyToolDirect(selectedDirectItem)
        else showNotification("Select item first", 2, true) end
    end)

    addToggleRow("Buy", "Auto Buy", toggleAutoBuy, function() return state.autoBuyEnabled end, Color3.fromRGB(200, 200, 200))
    addToggleRow("Buy", "Ruin Factories", toggleRuin, function() return state.ruinEnabled end, Color3.fromRGB(200, 200, 200))

    addPlainLabelRow("Teleports", "Teleports", Color3.fromRGB(255, 180, 100), 15, 24)
    local teleportRow1 = newFrame("Teleports", 36)
    styleRow(teleportRow1)
    local tpShopBtn = createButton(teleportRow1, "Shop (Koller)", UDim2.new(0.45, 0, 0, 26), UDim2.new(0.03, 0, 0.5, -13), Color3.fromRGB(100, 150, 200), 11)
    local tpSellBtn = createButton(teleportRow1, "Sell Shop (Eric)", UDim2.new(0.45, 0, 0, 26), UDim2.new(0.52, 0, 0.5, -13), Color3.fromRGB(150, 100, 200), 11)
    tpShopBtn.MouseButton1Click:Connect(teleportToShop)
    tpSellBtn.MouseButton1Click:Connect(teleportToSellShop)
    local teleportRow2 = newFrame("Teleports", 36)
    styleRow(teleportRow2)
    local sellBtn = createButton(teleportRow2, "Sell Rocks", UDim2.new(0.45, 0, 0, 26), UDim2.new(0.03, 0, 0.5, -13), Color3.fromRGB(200, 150, 0), 11)
    sellBtn.MouseButton1Click:Connect(sellRocksManual)

    addPlainLabelRow("Teleports", "Advanced Teleports", Color3.fromRGB(100, 200, 255), 15, 24)
    local advTeleportRow = newFrame("Teleports", 72)
    styleRow(advTeleportRow)
    createTextLabel(advTeleportRow, "Category", UDim2.new(0.18, 0, 0, 18), UDim2.new(0, 8, 0, 6), Color3.fromRGB(220, 220, 220), 11, Enum.TextXAlignment.Left)
    local categoryDrop = createButton(advTeleportRow, state.teleportCategory, UDim2.new(0.35, 0, 0, 24), UDim2.new(0.22, 0, 0, 4), Color3.fromRGB(45, 45, 70), 11)
    createTextLabel(advTeleportRow, "Target", UDim2.new(0.18, 0, 0, 18), UDim2.new(0, 8, 0, 38), Color3.fromRGB(220, 220, 220), 11, Enum.TextXAlignment.Left)
    local targetDrop = createButton(advTeleportRow, "Select target", UDim2.new(0.35, 0, 0, 24), UDim2.new(0.22, 0, 0, 36), Color3.fromRGB(45, 45, 70), 11)
    local teleportBtn = createButton(advTeleportRow, "Teleport", UDim2.new(0.25, 0, 0, 26), UDim2.new(0.65, 0, 0.5, -13), Color3.fromRGB(0, 150, 200), 12)
    local categoryList = addDropdownList("Teleports")
    local targetList = addDropdownList("Teleports")
    local updateTargetList = function()
        local targets = {}
        if state.teleportCategory == "Planets" then
            local planets = getPlanets()
            for _, p in ipairs(planets) do targets[#targets+1] = {display = p.name, value = p.name} end
        elseif state.teleportCategory == "Spawns" then
            local spawns = getSpawns()
            for _, s in ipairs(spawns) do
                if s.active then
                    targets[#targets+1] = {display = s.name, value = s.name}
                else
                    targets[#targets+1] = {display = s.name .. " (INACTIVE)", value = s.name, color = Color3.fromRGB(255, 255, 0)}
                end
            end
        elseif state.teleportCategory == "Saffra" then targets = {{display = "Saffra", value = "Saffra"}}
        elseif state.teleportCategory == "Monoliths" then
            for _, m in ipairs(MONOLITHS) do targets[#targets+1] = {display = m.name, value = m.name} end
        elseif state.teleportCategory == "Players" then
            local players = getPlayers()
            for _, p in ipairs(players) do targets[#targets+1] = {display = p.name, value = p.name} end
        end
        return targets
    end
    categoryDrop.MouseButton1Click:Connect(function()
        categoryList.Visible = not categoryList.Visible
        targetList.Visible = false
        if categoryList.Visible then
            fillListFrame(categoryList, TELEPORT_CATEGORIES, function(name)
                if name ~= "Empty" then state.teleportCategory = name categoryDrop.Text = name state.teleportTarget = nil targetDrop.Text = "Select target" end
            end)
        end
        task.defer(updateCanvas)
    end)
    targetDrop.MouseButton1Click:Connect(function()
        targetList.Visible = not targetList.Visible
        categoryList.Visible = false
        if targetList.Visible then
            local targets = updateTargetList()
            fillListFrame(targetList, targets, function(name)
                if name ~= "Empty" then state.teleportTarget = name targetDrop.Text = name end
            end)
        end
        task.defer(updateCanvas)
    end)
    teleportBtn.MouseButton1Click:Connect(function()
        if not state.teleportTarget then showNotification("Select target first", 2, true) return end
        if state.teleportCategory == "Planets" then teleportToPlanet(state.teleportTarget)
        elseif state.teleportCategory == "Spawns" then teleportToSpawn(state.teleportTarget)
        elseif state.teleportCategory == "Saffra" then teleportToSaffra()
        elseif state.teleportCategory == "Monoliths" then teleportToMonolith(state.teleportTarget)
        elseif state.teleportCategory == "Players" then teleportToPlayer(state.teleportTarget) end
    end)

    addToggleRow("Basic Hacks", "ESP", toggleESP, function() return state.espEnabled end, Color3.fromRGB(255, 255, 100))
    addToggleRow("Basic Hacks", "FullBright", toggleFullBright, function() return state.fullBrightRunning end, Color3.fromRGB(255, 255, 150))
    local flyToggleBtn, flyRefresh = addToggleRow("Basic Hacks", "Fly", toggleFly, function() return state.flyEnabled end, Color3.fromRGB(100, 200, 255))
    flyToggleBtn.Size = UDim2.new(0, 80, 0, 26)
    flyToggleBtn.Position = UDim2.new(1, -124, 0.5, -13)
    local flyKeybindBtn = createButton(flyToggleBtn.Parent, "?", UDim2.new(0, 36, 0, 26), UDim2.new(1, -40, 0.5, -13), Color3.fromRGB(50, 50, 70), 12)
    flyKeybindBtn.BackgroundTransparency = 0.6
    local flyKeybind = nil
    local flyKeybindListening = false
    local flyKeybindThread = nil
    flyKeybindBtn.MouseButton1Click:Connect(function()
        if flyKeybind then
            flyKeybind = nil
            flyKeybindBtn.Text = "?"
            flyKeybindBtn.BackgroundTransparency = 0.6
            return
        end
        flyKeybindListening = true
        flyKeybindBtn.Text = "..."
        flyKeybindBtn.BackgroundTransparency = 0.3
        if flyKeybindThread then task.cancel(flyKeybindThread) end
        flyKeybindThread = task.spawn(function()
            task.wait(3)
            if flyKeybindListening then
                flyKeybindListening = false
                flyKeybindBtn.Text = "?"
                flyKeybindBtn.BackgroundTransparency = 0.6
            end
        end)
    end)
    local keybindInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if flyKeybindListening then
            flyKeybindListening = false
            if flyKeybindThread then task.cancel(flyKeybindThread) flyKeybindThread = nil end
            local keyName = "?"
            if input.UserInputType == Enum.UserInputType.Keyboard then
                flyKeybind = input.KeyCode
                keyName = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                flyKeybind = Enum.UserInputType.MouseButton1
                keyName = "M1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                flyKeybind = Enum.UserInputType.MouseButton2
                keyName = "M2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                flyKeybind = Enum.UserInputType.MouseButton3
                keyName = "M3"
            end
            flyKeybindBtn.Text = keyName
            flyKeybindBtn.BackgroundTransparency = 0.6
        end
    end)
    local keybindFlyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not flyKeybindListening and flyKeybind then
            if input.KeyCode == flyKeybind or input.UserInputType == flyKeybind then
                toggleFly()
                flyRefresh()
                updateStatus()
            end
        end
    end)
    local flyInputChangedConn = nil
    local flyInputEndedConn = nil
    local flyDragging = false
    local flySliderRow = newFrame("Basic Hacks", 54)
    styleRow(flySliderRow)
    local flySpeedLabel = createTextLabel(flySliderRow, "Fly speed: 1", UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 4), Color3.fromRGB(220, 220, 220), 12, Enum.TextXAlignment.Left)
    local sliderBg = Instance.new("TextButton", flySliderRow)
    sliderBg.Size = UDim2.new(1, -20, 0, 12)
    sliderBg.Position = UDim2.new(0, 10, 0, 32)
    sliderBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    sliderBg.BorderSizePixel = 0
    sliderBg.Text = ""
    sliderBg.AutoButtonColor = false
    makeCorner(sliderBg, 6)
    makeStroke(sliderBg, Color3.fromRGB(80, 80, 110))
    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.Size = UDim2.new(0.25, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    sliderFill.BorderSizePixel = 0
    makeCorner(sliderFill, 6)
    local sliderKnob = Instance.new("TextButton", sliderBg)
    sliderKnob.Size = UDim2.new(0, 16, 0, 16)
    sliderKnob.Position = UDim2.new(0.25, -8, 0.5, -8)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.BorderSizePixel = 0
    sliderKnob.Text = ""
    sliderKnob.AutoButtonColor = false
    makeCorner(sliderKnob, 8)
    local logMin = math.log(FLY_MIN)
    local logMax = math.log(FLY_MAX)
    local formatFlyValue = function(v)
        if v < 1 then return string.format("%.1f", v) end
        local rounded = math.floor(v + 0.5)
        if rounded >= 5000 then
            if rounded < 10000 then return "OD"
            elseif rounded < 15000 then return "ODx2"
            elseif rounded < 20000 then return "ODx3"
            else return "ODx4" end
        end
        return tostring(rounded)
    end
    local valueToRatio = function(v)
        v = clamp(v or 1, FLY_MIN, FLY_MAX)
        return (math.log(v) - logMin) / (logMax - logMin)
    end
    local ratioToValue = function(r)
        r = clamp(r or 0, 0, 1)
        local v = math.exp(logMin + r * (logMax - logMin))
        if v < 1 then return math.floor(v * 10 + 0.5) / 10 else return math.floor(v + 0.5) end
    end
    local updateFlySlider = function()
        local v = state.flySpeedMultiplier or 1
        local rel = valueToRatio(v)
        sliderFill.Size = UDim2.new(rel, 0, 1, 0)
        sliderKnob.Position = UDim2.new(rel, -8, 0.5, -8)
        flySpeedLabel.Text = "Fly speed: " .. formatFlyValue(v)
    end
    local setFlyFromX = function(x)
        local bgX = sliderBg.AbsolutePosition.X
        local bgW = sliderBg.AbsoluteSize.X
        if bgW <= 0 then return end
        local rel = clamp((x - bgX) / bgW, 0, 1)
        state.flySpeedMultiplier = ratioToValue(rel)
        updateFlySlider()
    end
    local onSliderInputBegan = function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            flyDragging = true
            setFlyFromX(input.Position.X)
        end
    end
    sliderBg.InputBegan:Connect(onSliderInputBegan)
    sliderKnob.InputBegan:Connect(onSliderInputBegan)
    flyInputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if flyDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then setFlyFromX(input.Position.X) end
    end)
    flyInputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then flyDragging = false end
    end)
    updateFlySlider()

    local wsSlider = createSliderRow("Basic Hacks", "Walkspeed", 16, 500, 16, applyWalkSpeed)
    local grSlider = createSliderRow("Basic Hacks", "Gravity", -1000, 1000, 196.2, applyGravity, function(v) return tostring(math.floor(v + 0.5)) end)

    local restoreRow = newFrame("Basic Hacks", 36)
    styleRow(restoreRow)
    createTextLabel(restoreRow, "Reset Mods", UDim2.new(0.55, 0, 1, 0), UDim2.new(0, 8, 0, 0), Color3.fromRGB(255, 150, 150), 13, Enum.TextXAlignment.Left)
    local restoreBtn = createButton(restoreRow, "Restore values", UDim2.new(0.35, 0, 0, 26), UDim2.new(0.60, 0, 0.5, -13), Color3.fromRGB(180, 80, 80), 11)
    restoreBtn.MouseButton1Click:Connect(function()
        wsSlider.update(16)
        grSlider.update(196.2)
        state.flySpeedMultiplier = 1
        updateFlySlider()
    end)

    addToggleRow("Other", "Explosive Fast Place", toggleExplosiveFastPlace, function() return state.explosiveFastPlaceRunning end, Color3.fromRGB(255, 100, 50))
    guiElements.explosiveFastPlaceToggle = nil

    addToggleRow("Other", "Emergency Air", toggleEmergencyAir, function() return emergencyAirEnabled end, Color3.fromRGB(255, 80, 80))

    addPlainLabelRow("Other", "Control (Phobos/Deimos)", Color3.fromRGB(200, 200, 255), 15, 24)
    local controlRow = newFrame("Other", 36)
    styleRow(controlRow)
    createTextLabel(controlRow, "Satellite", UDim2.new(0.20, 0, 1, 0), UDim2.new(0, 8, 0, 0), Color3.fromRGB(220, 220, 220), 13, Enum.TextXAlignment.Left)
    local controlDrop = createButton(controlRow, state.controlTarget, UDim2.new(0.30, 0, 0, 26), UDim2.new(0.24, 0, 0.5, -13), Color3.fromRGB(45, 45, 70), 12)
    local controlBtn = createButton(controlRow, "START", UDim2.new(0.28, 0, 0, 26), UDim2.new(0.58, 0, 0.5, -13), Color3.fromRGB(0, 150, 200), 12)
    local controlList = addDropdownList("Other")
    local refreshControlBtn = function()
        local on = state.controlEnabled
        controlBtn.Text = on and "STOP" or "START"
        controlBtn.BackgroundColor3 = on and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(0, 150, 200)
    end
    controlDrop.MouseButton1Click:Connect(function()
        controlList.Visible = not controlList.Visible
        if controlList.Visible then
            fillListFrame(controlList, {"Phobos", "Deimos"}, function(name)
                state.controlTarget = name
                controlDrop.Text = name
            end)
        end
        task.defer(updateCanvas)
    end)
    controlBtn.MouseButton1Click:Connect(function()
        if state.controlEnabled then stopControl() else startControl(state.controlTarget) end
        refreshControlBtn()
        updateStatus()
    end)
    refreshControlBtn()

    addPlainLabelRow("External", "External Scripts", Color3.fromRGB(180, 140, 255), 15, 24)
    for _, scriptInfo in ipairs(EXTERNAL_SCRIPTS) do
        local extRow = newFrame("External", 36)
        styleRow(extRow)
        createTextLabel(extRow, scriptInfo.name, UDim2.new(0.55, 0, 1, 0), UDim2.new(0, 8, 0, 0), Color3.fromRGB(220, 220, 220), 13, Enum.TextXAlignment.Left)
        local execBtn = createButton(extRow, "EXECUTE", UDim2.new(0.32, 0, 0, 26), UDim2.new(0.62, 0, 0.5, -13), Color3.fromRGB(120, 80, 200), 11)
        execBtn.MouseButton1Click:Connect(function() runExternalScript(scriptInfo.url, scriptInfo.name) end)
    end

    local tabBtns = {}
    for _, name in ipairs(TAB_NAMES) do
        local btn = Instance.new("TextButton", tabBar)
        btn.Size = UDim2.new(0, 0, 0, 28)
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundColor3 = (name == currentTab) and Color3.fromRGB(0, 120, 180) or Color3.fromRGB(45, 45, 70)
        btn.BackgroundTransparency = 0.15
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = (name == currentTab) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        btn.Text = name
        btn.AutoButtonColor = false
        local ord = 0
        for i, n in ipairs(TAB_NAMES) do if n == name then ord = i break end end
        btn.LayoutOrder = ord
        makeCorner(btn, 6)
        local padding = Instance.new("UIPadding", btn)
        padding.PaddingLeft = UDim.new(0, 8)
        padding.PaddingRight = UDim.new(0, 8)
        btn.MouseButton1Click:Connect(function()
            for n, b in pairs(tabBtns) do
                catFrames[n].Visible = (n == name)
                b.BackgroundColor3 = (n == name) and Color3.fromRGB(0, 120, 180) or Color3.fromRGB(45, 45, 70)
                b.TextColor3 = (n == name) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
            end
            for _, d in ipairs(dropdowns) do d.Visible = false end
            task.defer(updateCanvas)
        end)
        tabBtns[name] = btn
    end

    local updateStats = function()
        if moneyStats then moneyStats.Text = "Collected: " .. state.moneyCollected .. " | Sold: " .. state.moneySold end
        if ballStats then ballStats.Text = "Clicked: " .. state.ballClicked end
        if redMatterStats then redMatterStats.Text = "Clicked: " .. state.redMatterClicked end
        updateStatus()
    end
    local statsConn = RunService.Heartbeat:Connect(updateStats)
    updateCanvas()
    updateStats()

    local cleaned = false
    local cleanup = function()
        if cleaned then return end
        cleaned = true
        stopMoney()
        stopBall()
        stopFullBright()
        stopAutoBuy()
        stopRuin()
        stopExplosiveFastPlace()
        stopAutoRedMatter()
        if state.espEnabled then toggleESP() end
        if state.flyEnabled then toggleFly() end
        if state.controlEnabled then stopControl() end
        if emergencyAirEnabled then toggleEmergencyAir() end
        pcall(function() statsConn:Disconnect() end)
        pcall(function()
            if flyInputChangedConn then flyInputChangedConn:Disconnect() end
            if flyInputEndedConn then flyInputEndedConn:Disconnect() end
            if keybindInputConn then keybindInputConn:Disconnect() end
            if keybindFlyConn then keybindFlyConn:Disconnect() end
            if flyKeybindThread then task.cancel(flyKeybindThread) end
            if wsSlider and wsSlider.connections then
                for _, c in ipairs(wsSlider.connections) do pcall(function() c:Disconnect() end) end
            end
            if grSlider and grSlider.connections then
                for _, c in ipairs(grSlider.connections) do pcall(function() c:Disconnect() end) end
            end
            if emergencyAirThread then task.cancel(emergencyAirThread) end
        end)
    end

    close.MouseButton1Click:Connect(function() cleanup() sg:Destroy() end)
    sg.AncestryChanged:Connect(function() if not sg.Parent then cleanup() end end)
    return {gui = sg, updateStatus = updateStatus}
end

local gui = createGUI()
gui.updateStatus()
