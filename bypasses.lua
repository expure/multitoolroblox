local BypassModule = {}
local activeHooks = {}
local isBypassActive = false
local lastValidPos = nil
local restoreThread = nil

local function canUseMetatables()
    local success, mt = pcall(getrawmetatable, game)
    return success and mt ~= nil
end

local useAdvanced = canUseMetatables()

local function restorePositionLoop()
    while isBypassActive do
        task.wait(0.05)
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and lastValidPos then
            local currentPos = hrp.Position
            local dist = (currentPos - lastValidPos).Magnitude
            if dist > 15 then
                hrp.CFrame = CFrame.new(lastValidPos)
                hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
            elseif dist > 3 then
                hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(lastValidPos), 0.7)
            else
                lastValidPos = currentPos
            end
        elseif hrp and not lastValidPos then
            lastValidPos = hrp.Position
        end
    end
end

local originalNewIndex = nil
local originalIndex = nil

local function setupAntiTeleport()
    if activeHooks.antiTeleport then return end
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    lastValidPos = hrp.Position
    if restoreThread then coroutine.close(restoreThread) end
    restoreThread = coroutine.create(restorePositionLoop)
    coroutine.resume(restoreThread)
    if useAdvanced then
        local mt = getrawmetatable(hrp)
        if mt then
            originalNewIndex = mt.__newindex
            originalIndex = mt.__index
            local newmt = {}
            for k, v in pairs(mt) do newmt[k] = v end
            newmt.__newindex = function(self, key, val)
                if key == "CFrame" or key == "Position" then
                    return nil
                end
                if originalNewIndex then
                    return originalNewIndex(self, key, val)
                else
                    rawset(self, key, val)
                end
            end
            newmt.__index = function(self, key)
                if key == "Position" then
                    return lastValidPos or (originalIndex and originalIndex(self, key) or self.Position)
                end
                if key == "Velocity" then
                    return Vector3.new(0,0,0)
                end
                return originalIndex and originalIndex(self, key) or rawget(self, key)
            end
            pcall(setrawmetatable, hrp, newmt)
        end
    end
    activeHooks.antiTeleport = true
end

local function removeAntiTeleport()
    if not activeHooks.antiTeleport then return end
    if restoreThread then coroutine.close(restoreThread) restoreThread = nil end
    if useAdvanced then
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local mt = getrawmetatable(hrp)
            if mt then
                local restored = {}
                for k, v in pairs(mt) do restored[k] = v end
                restored.__newindex = originalNewIndex
                restored.__index = originalIndex
                pcall(setrawmetatable, hrp, restored)
            end
        end
    end
    originalNewIndex = nil
    originalIndex = nil
    activeHooks.antiTeleport = false
    lastValidPos = nil
end

local function setupSpeedBypass()
    if activeHooks.speedBypass then return end
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if useAdvanced then
        local mt = getrawmetatable(hrp)
        if mt and mt.__newindex then
            local oldNew = mt.__newindex
            local newmt = {}
            for k, v in pairs(mt) do newmt[k] = v end
            newmt.__newindex = function(self, key, val)
                if key == "Velocity" then
                    local limited = Vector3.new(
                        math.clamp(val.X, -60, 60),
                        math.clamp(val.Y, -60, 60),
                        math.clamp(val.Z, -60, 60)
                    )
                    return oldNew(self, key, limited)
                end
                return oldNew(self, key, val)
            end
            pcall(setrawmetatable, hrp, newmt)
        end
    end
    activeHooks.speedBypass = true
end

local function removeSpeedBypass()
    if not activeHooks.speedBypass then return end
    activeHooks.speedBypass = false
end

local function setupFlyBypass()
    if activeHooks.flyBypass then return end
    local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid and useAdvanced then
        local mt = getrawmetatable(humanoid)
        if mt then
            local newmt = {}
            for k, v in pairs(mt) do newmt[k] = v end
            newmt.__index = function(self, key)
                if key == "FloorMaterial" then
                    return Enum.Material.Grass
                end
                return mt.__index(self, key)
            end
            pcall(setrawmetatable, humanoid, newmt)
        end
    end
    activeHooks.flyBypass = true
end

local function removeFlyBypass()
    activeHooks.flyBypass = false
end

local originalKick = nil
local originalTeleport = nil

local function setupAntiKickTransfer()
    if activeHooks.antiKickTransfer then return end
    local localPlayer = game.Players.LocalPlayer
    if localPlayer and localPlayer.Kick then
        originalKick = hookfunction(localPlayer.Kick, function() return nil end)
    end
    local ts = game:GetService("TeleportService")
    if ts and ts.Teleport then
        originalTeleport = hookfunction(ts.Teleport, function() return nil end)
    end
    activeHooks.antiKickTransfer = true
end

local function removeAntiKickTransfer()
    if not activeHooks.antiKickTransfer then return end
    local localPlayer = game.Players.LocalPlayer
    if localPlayer and originalKick then hookfunction(localPlayer.Kick, originalKick) end
    local ts = game:GetService("TeleportService")
    if ts and originalTeleport then hookfunction(ts.Teleport, originalTeleport) end
    activeHooks.antiKickTransfer = false
end

local scriptVars = {"FullBrightEnabled", "FullBrightExecuted", "InfiniteJumpEnabled", "NormalLightingSettings", "flingRotateTask", "FlyEnabled", "Speed", "EXVS_Loaded", "ESP_Enabled", "FlySpeed"}
local savedGlobals = {}

local function setupHideGlobals()
    if activeHooks.hideGlobals then return end
    for _, v in ipairs(scriptVars) do
        if _G[v] ~= nil then
            savedGlobals[v] = _G[v]
            _G[v] = nil
        end
        local env = getgenv()
        if env and env[v] ~= nil then
            savedGlobals["env_" .. v] = env[v]
            env[v] = nil
        end
    end
    activeHooks.hideGlobals = true
end

local function removeHideGlobals()
    if not activeHooks.hideGlobals then return end
    for v, val in pairs(savedGlobals) do
        if v:sub(1,4) == "env_" then
            local name = v:sub(5)
            local env = getgenv()
            if env then env[name] = val end
        else
            _G[v] = val
        end
    end
    savedGlobals = {}
    activeHooks.hideGlobals = false
end

local function setupViolationBlock()
    if activeHooks.violationBlock then return end
    local targetTables = {_G, getgenv()}
    local renv = getrenv()
    if renv and type(renv) == "table" then table.insert(targetTables, renv) end
    for _, tbl in ipairs(targetTables) do
        if tbl and type(tbl) == "table" and not activeHooks["vb_" .. tostring(tbl)] then
            local success, mt = pcall(getrawmetatable, tbl)
            if success and mt then
                local newmt = {}
                for k, v in pairs(mt) do newmt[k] = v end
                newmt.__newindex = function(self, key, val)
                    if type(key) == "string" and (key:lower():find("violation") or key:lower():find("flag") or key:lower():find("cheat") or key:lower():find("detect")) then
                        return nil
                    end
                    rawset(self, key, val)
                end
                newmt.__index = function(self, key)
                    if type(key) == "string" and (key:lower():find("violation") or key:lower():find("flag") or key:lower():find("cheat") or key:lower():find("detect")) then
                        return nil
                    end
                    return rawget(self, key)
                end
                pcall(setrawmetatable, tbl, newmt)
                activeHooks["vb_" .. tostring(tbl)] = true
            end
        end
    end
    activeHooks.violationBlock = true
end

local function removeViolationBlock()
    if not activeHooks.violationBlock then return end
    local targetTables = {_G, getgenv()}
    local renv = getrenv()
    if renv and type(renv) == "table" then table.insert(targetTables, renv) end
    for _, tbl in ipairs(targetTables) do
        local key = "vb_" .. tostring(tbl)
        if tbl and activeHooks[key] then
            local success, mt = pcall(getrawmetatable, tbl)
            if success and mt then
                local restored = {}
                for k, v in pairs(mt) do restored[k] = v end
                restored.__newindex = nil
                restored.__index = nil
                pcall(setrawmetatable, tbl, restored)
            end
            activeHooks[key] = nil
        end
    end
    activeHooks.violationBlock = false
end

local characterAddedConn = nil

local function setupCharacterHook()
    if activeHooks.characterHook then return end
    local plr = game.Players.LocalPlayer
    local conn
    conn = plr.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        if isBypassActive then
            removeAntiTeleport()
            removeSpeedBypass()
            removeFlyBypass()
            task.wait(0.1)
            setupAntiTeleport()
            setupSpeedBypass()
            setupFlyBypass()
        end
    end)
    activeHooks.characterHook = conn
end

local function removeCharacterHook()
    if activeHooks.characterHook then
        activeHooks.characterHook:Disconnect()
        activeHooks.characterHook = nil
    end
end

function BypassModule.enable()
    if isBypassActive then return true end
    setupAntiTeleport()
    setupSpeedBypass()
    setupFlyBypass()
    setupAntiKickTransfer()
    setupHideGlobals()
    setupViolationBlock()
    setupCharacterHook()
    isBypassActive = true
    return true
end

function BypassModule.disable()
    if not isBypassActive then return end
    removeAntiTeleport()
    removeSpeedBypass()
    removeFlyBypass()
    removeAntiKickTransfer()
    removeHideGlobals()
    removeViolationBlock()
    removeCharacterHook()
    isBypassActive = false
end

function BypassModule.isEnabled() return isBypassActive end
function BypassModule.updateValidPosition(pos)
    if pos then lastValidPos = pos end
end

return BypassModule
