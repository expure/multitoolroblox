local BypassModule = {}
local activeHooks = {}
local isBypassActive = false

local function canUseMetatables()
    local success, mt = pcall(getrawmetatable, game)
    return success and mt ~= nil
end

local useAdvanced = canUseMetatables()

local originalGetState = nil
local originalFloorMaterial = nil
local lastValidPosition = nil
local positionRestoreThread = nil

local function restorePositionLoop()
    while isBypassActive and positionRestoreThread do
        task.wait(0.05)
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and lastValidPosition then
            local currentPos = hrp.Position
            local delta = (currentPos - lastValidPosition).Magnitude
            if delta > 15 then
                hrp.CFrame = CFrame.new(lastValidPosition)
                hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
            elseif delta > 3 then
                hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(lastValidPosition), 0.7)
            else
                lastValidPosition = currentPos
            end
        elseif hrp and not lastValidPosition then
            lastValidPosition = hrp.Position
        end
    end
end

local function setupAntiTeleport()
    if activeHooks.antiTeleport then return end
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    lastValidPosition = hrp.Position
    positionRestoreThread = coroutine.create(restorePositionLoop)
    coroutine.resume(positionRestoreThread)
    if useAdvanced then
        local mt = getrawmetatable(hrp)
        if mt then
            originalGetState = mt.__newindex
            local newmt = {}
            for k, v in pairs(mt) do newmt[k] = v end
            newmt.__newindex = function(self, key, val)
                if key == "CFrame" or key == "Position" then
                    return nil
                end
                if originalGetState then
                    return originalGetState(self, key, val)
                else
                    rawset(self, key, val)
                end
            end
            pcall(setrawmetatable, hrp, newmt)
        end
    end
    activeHooks.antiTeleport = true
end

local function removeAntiTeleport()
    if not activeHooks.antiTeleport then return end
    positionRestoreThread = nil
    if useAdvanced then
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local mt = getrawmetatable(hrp)
            if mt and originalGetState then
                local restored = {}
                for k, v in pairs(mt) do restored[k] = v end
                restored.__newindex = originalGetState
                pcall(setrawmetatable, hrp, restored)
            end
        end
    end
    originalGetState = nil
    activeHooks.antiTeleport = false
    lastValidPosition = nil
end

local originalVelocityWrite = nil

local function setupSpeedDetectionBypass()
    if activeHooks.speedBypass then return end
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if useAdvanced then
        local mt = getrawmetatable(hrp)
        if mt and mt.__newindex then
            originalVelocityWrite = mt.__newindex
            local newmt = {}
            for k, v in pairs(mt) do newmt[k] = v end
            newmt.__newindex = function(self, key, val)
                if key == "Velocity" then
                    local limited = Vector3.new(
                        math.clamp(val.X, -80, 80),
                        math.clamp(val.Y, -80, 80),
                        math.clamp(val.Z, -80, 80)
                    )
                    return originalVelocityWrite(self, key, limited)
                end
                return originalVelocityWrite(self, key, val)
            end
            pcall(setrawmetatable, hrp, newmt)
        end
    end
    activeHooks.speedBypass = true
end

local function removeSpeedDetectionBypass()
    if not activeHooks.speedBypass then return end
    if useAdvanced and originalVelocityWrite then
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local mt = getrawmetatable(hrp)
            if mt then
                local restored = {}
                for k, v in pairs(mt) do restored[k] = v end
                restored.__newindex = originalVelocityWrite
                pcall(setrawmetatable, hrp, restored)
            end
        end
    end
    activeHooks.speedBypass = false
end

local function setupFlyBypass()
    if activeHooks.flyBypass then return end
    local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    if useAdvanced then
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
    if not activeHooks.flyBypass then return end
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
        if tbl and type(tbl) == "table" then
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
            end
        end
    end
    activeHooks.violationBlock = true
end

local function removeViolationBlock()
    if not activeHooks.violationBlock then return end
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
            removeSpeedDetectionBypass()
            removeFlyBypass()
            task.wait(0.1)
            setupAntiTeleport()
            setupSpeedDetectionBypass()
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
    setupSpeedDetectionBypass()
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
    removeSpeedDetectionBypass()
    removeFlyBypass()
    removeAntiKickTransfer()
    removeHideGlobals()
    removeViolationBlock()
    removeCharacterHook()
    isBypassActive = false
end

function BypassModule.isEnabled() return isBypassActive end
function BypassModule.updateValidPosition(pos)
    if pos then lastValidPosition = pos end
end

return BypassModule
