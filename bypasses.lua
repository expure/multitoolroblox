local BypassModule = {}
local activeHooks = {}
local isBypassActive = false

local function canUseBypasses()
    local success, rawmeta = pcall(getrawmetatable, game)
    if not success then return false end
    local success, hookfunc = pcall(hookfunction, print, function() end)
    if not success then return false end
    return true
end

local function safeHookFunction(target, hook)
    if not target then return nil end
    local success, original = pcall(hookfunction, target, hook)
    if success then return original end
    return nil
end

local function safeUnhookFunction(target, original)
    if target and original then pcall(hookfunction, target, original) end
end

local originalGetState = nil
local originalFloorMaterial = nil

local function setupFlyBypass()
    if activeHooks.flyBypass then return end
    local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    originalGetState = safeHookFunction(humanoid.GetState, function(self)
        local state = originalGetState(self)
        if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
            return Enum.HumanoidStateType.Running
        end
        return state
    end)
    originalFloorMaterial = safeHookFunction(humanoid.FloorMaterial, function(self) return Enum.Material.Grass end)
    activeHooks.flyBypass = true
end

local function removeFlyBypass()
    if not activeHooks.flyBypass then return end
    local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        if originalGetState then safeUnhookFunction(humanoid.GetState, originalGetState) end
        if originalFloorMaterial then safeUnhookFunction(humanoid.FloorMaterial, originalFloorMaterial) end
    end
    activeHooks.flyBypass = false
end

local originalKick = nil

local function setupAntiKick()
    if activeHooks.antiKick then return end
    local localPlayer = game.Players.LocalPlayer
    if localPlayer and localPlayer.Kick then
        originalKick = safeHookFunction(localPlayer.Kick, function() return nil end)
    end
    activeHooks.antiKick = true
end

local function removeAntiKick()
    if not activeHooks.antiKick then return end
    local localPlayer = game.Players.LocalPlayer
    if localPlayer and originalKick then safeUnhookFunction(localPlayer.Kick, originalKick) end
    activeHooks.antiKick = false
end

local spoofedPosition = nil
local spoofedVelocity = nil
local hrpIndexBackup = nil

local function setupPositionSpoofing()
    if activeHooks.positionSpoof then return end
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local success, mt = pcall(getrawmetatable, hrp)
    if not success or not mt then return end
    hrpIndexBackup = mt.__index
    spoofedPosition = hrp.Position
    spoofedVelocity = Vector3.new(0,0,0)
    local newmt = {}
    for k, v in pairs(mt) do newmt[k] = v end
    newmt.__index = function(self, key)
        if key == "Position" then return spoofedPosition end
        if key == "Velocity" then return spoofedVelocity end
        if hrpIndexBackup then return hrpIndexBackup(self, key) end
        return nil
    end
    pcall(setrawmetatable, hrp, newmt)
    activeHooks.positionSpoof = true
end

local function removePositionSpoofing()
    if not activeHooks.positionSpoof then return end
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local success, mt = pcall(getrawmetatable, hrp)
        if success and mt then
            local restored = {}
            for k, v in pairs(mt) do restored[k] = v end
            if hrpIndexBackup then restored.__index = hrpIndexBackup end
            pcall(setrawmetatable, hrp, restored)
        end
    end
    hrpIndexBackup = nil
    activeHooks.positionSpoof = false
    spoofedPosition = nil
    spoofedVelocity = nil
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
        task.wait(0.2)
        if isBypassActive then
            if activeHooks.flyBypass then
                removeFlyBypass()
                setupFlyBypass()
            end
            if activeHooks.positionSpoof then
                removePositionSpoofing()
                setupPositionSpoofing()
            end
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
    if not canUseBypasses() then return false end
    setupFlyBypass()
    setupAntiKick()
    setupPositionSpoofing()
    setupHideGlobals()
    setupViolationBlock()
    setupCharacterHook()
    isBypassActive = true
    return true
end

function BypassModule.disable()
    if not isBypassActive then return end
    removeFlyBypass()
    removeAntiKick()
    removePositionSpoofing()
    removeHideGlobals()
    removeViolationBlock()
    removeCharacterHook()
    isBypassActive = false
end

function BypassModule.isEnabled() return isBypassActive end
function BypassModule.updateSpoofedPosition(pos)
    if pos then spoofedPosition = pos
    else
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then spoofedPosition = hrp.Position end
    end
end
function BypassModule.updateSpoofedVelocity(vel)
    if vel then spoofedVelocity = vel else spoofedVelocity = Vector3.new(0,0,0) end
end

return BypassModule
