local BypassModule = {}

local originalFunctions = {}
local originalMetatables = {}
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
    local success, original = pcall(hookfunction, target, hook)
    if success then
        return original
    end
    return nil
end

local function safeUnhookFunction(target, original)
    if original then
        pcall(hookfunction, target, original)
    end
end

local function hookMetamethod(obj, metamethod, hook)
    local success, mt = pcall(getrawmetatable, obj)
    if not success then return nil end
    if not originalMetatables[obj] then
        originalMetatables[obj] = {mt = mt, metamethods = {}}
    end
    if not originalMetatables[obj].metamethods[metamethod] then
        originalMetatables[obj].metamethods[metamethod] = mt[metamethod]
    end
    local original = mt[metamethod]
    local newmt = {}
    for k,v in pairs(mt) do
        newmt[k] = v
    end
    newmt[metamethod] = hook
    pcall(setrawmetatable, obj, newmt)
    return original
end

local function unhookMetamethod(obj, metamethod)
    if not originalMetatables[obj] then return end
    local originalData = originalMetatables[obj]
    if originalData.metamethods[metamethod] then
        local restoredMt = {}
        local currentMt = getrawmetatable(obj)
        for k,v in pairs(currentMt) do
            restoredMt[k] = v
        end
        restoredMt[metamethod] = originalData.metamethods[metamethod]
        pcall(setrawmetatable, obj, restoredMt)
        originalData.metamethods[metamethod] = nil
    end
    if next(originalData.metamethods) == nil then
        pcall(setrawmetatable, obj, originalData.mt)
        originalMetatables[obj] = nil
    end
end

local originalGetState = nil
local originalFloorMaterial = nil

local function setupFlyBypass()
    if activeHooks.flyBypass then return end
    local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    local hum = humanoid
    originalGetState = safeHookFunction(hum.GetState, function(self)
        local state = originalGetState(self)
        if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
            return Enum.HumanoidStateType.Running
        end
        return state
    end)
    originalFloorMaterial = safeHookFunction(hum.FloorMaterial, function(self)
        return Enum.Material.Grass
    end)
    activeHooks.flyBypass = true
end

local function removeFlyBypass()
    if not activeHooks.flyBypass then return end
    local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        if originalGetState then
            safeUnhookFunction(humanoid.GetState, originalGetState)
            originalGetState = nil
        end
        if originalFloorMaterial then
            safeUnhookFunction(humanoid.FloorMaterial, originalFloorMaterial)
            originalFloorMaterial = nil
        end
    end
    activeHooks.flyBypass = false
end

local originalMoveTo = nil
local originalKick = nil
local teleportBlocked = false

local function setupAntiKickTeleport()
    if activeHooks.antiKick then return end
    local playersService = game:GetService("Players")
    local localPlayer = playersService.LocalPlayer
    if localPlayer and localPlayer.Kick then
        originalKick = safeHookFunction(localPlayer.Kick, function(self, message)
            return nil
        end)
    end
    activeHooks.antiKick = true
end

local function removeAntiKickTeleport()
    if not activeHooks.antiKick then return end
    local playersService = game:GetService("Players")
    local localPlayer = playersService.LocalPlayer
    if localPlayer and originalKick then
        safeUnhookFunction(localPlayer.Kick, originalKick)
        originalKick = nil
    end
    activeHooks.antiKick = false
end

local originalGetPosition = nil
local originalGetVelocity = nil
local spoofedPosition = nil
local spoofedVelocity = nil

local function setupPositionSpoofing()
    if activeHooks.positionSpoof then return end
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local realPosition = hrp.Position
    spoofedPosition = realPosition
    spoofedVelocity = Vector3.new(0,0,0)
    local mt = getrawmetatable(hrp)
    originalMetatables["HRP_INDEX"] = mt.__index
    local newmt = {}
    for k,v in pairs(mt) do
        newmt[k] = v
    end
    newmt.__index = function(self, key)
        if key == "Position" then
            return spoofedPosition
        elseif key == "Velocity" then
            return spoofedVelocity
        end
        if originalMetatables["HRP_INDEX"] then
            return originalMetatables["HRP_INDEX"](self, key)
        end
        return nil
    end
    pcall(setrawmetatable, hrp, newmt)
    activeHooks.positionSpoof = true
end

local function removePositionSpoofing()
    if not activeHooks.positionSpoof then return end
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and originalMetatables["HRP_INDEX"] then
        local mt = getrawmetatable(hrp)
        local restoredMt = {}
        for k,v in pairs(mt) do
            restoredMt[k] = v
        end
        restoredMt.__index = originalMetatables["HRP_INDEX"]
        pcall(setrawmetatable, hrp, restoredMt)
        originalMetatables["HRP_INDEX"] = nil
    end
    activeHooks.positionSpoof = false
end

local violationsTable = nil
local originalNewIndex = nil

local function setupViolationBlock()
    if activeHooks.violationBlock then return end
    local targetTables = {_G, getgenv(), getrenv()}
    for _, tbl in ipairs(targetTables) do
        if tbl and not originalMetatables[tbl] then
            local success, mt = pcall(getrawmetatable, tbl)
            if success then
                originalMetatables[tbl] = {mt = mt, oldNewIndex = mt.__newindex}
                local newmt = {}
                for k,v in pairs(mt) do
                    newmt[k] = v
                end
                newmt.__newindex = function(self, key, value)
                    if type(key) == "string" and (string.lower(key):find("violation") or string.lower(key):find("flag") or string.lower(key):find("cheat") or string.lower(key):find("detect")) then
                        if type(value) == "boolean" then
                            return nil
                        elseif type(value) == "number" then
                            return nil
                        end
                    end
                    if originalMetatables[tbl].oldNewIndex then
                        return originalMetatables[tbl].oldNewIndex(self, key, value)
                    else
                        rawset(self, key, value)
                    end
                end
                pcall(setrawmetatable, tbl, newmt)
            end
        end
    end
    activeHooks.violationBlock = true
end

local function removeViolationBlock()
    if not activeHooks.violationBlock then return end
    local targetTables = {_G, getgenv(), getrenv()}
    for _, tbl in ipairs(targetTables) do
        if tbl and originalMetatables[tbl] then
            pcall(setrawmetatable, tbl, originalMetatables[tbl].mt)
            originalMetatables[tbl] = nil
        end
    end
    activeHooks.violationBlock = false
end

local scriptVariables = {
    "FullBrightEnabled", "FullBrightExecuted", "InfiniteJumpEnabled",
    "NormalLightingSettings", "flingRotateTask", "FlyEnabled", "Speed",
    "EXVS_Loaded", "ESP_Enabled", "FlySpeed"
}

local originalGlobals = {}

local function setupCheckEvasion()
    if activeHooks.checkEvasion then return end
    for _, varName in ipairs(scriptVariables) do
        if _G[varName] ~= nil then
            originalGlobals[varName] = _G[varName]
            _G[varName] = nil
        end
    end
    local function hideVariables(tbl)
        if not tbl then return end
        for _, varName in ipairs(scriptVariables) do
            if rawget(tbl, varName) then
                rawset(tbl, varName, nil)
            end
        end
    end
    hideVariables(_G)
    hideVariables(getgenv())
    activeHooks.checkEvasion = true
end

local function removeCheckEvasion()
    if not activeHooks.checkEvasion then return end
    for varName, originalValue in pairs(originalGlobals) do
        _G[varName] = originalValue
    end
    originalGlobals = {}
    activeHooks.checkEvasion = false
end

local characterAddedConn = nil
local hrpAddedConn = nil

local function setupDynamicCharacterHooks()
    if characterAddedConn then characterAddedConn:Disconnect() end
    characterAddedConn = game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
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
end

function BypassModule.enable()
    if isBypassActive then
        return true
    end
    if not canUseBypasses() then
        warn("Bypass module: required executor functions not available")
        return false
    end
    setupFlyBypass()
    setupAntiKickTeleport()
    setupPositionSpoofing()
    setupViolationBlock()
    setupCheckEvasion()
    setupDynamicCharacterHooks()
    isBypassActive = true
    return true
end

function BypassModule.disable()
    if not isBypassActive then
        return
    end
    removeFlyBypass()
    removeAntiKickTeleport()
    removePositionSpoofing()
    removeViolationBlock()
    removeCheckEvasion()
    if characterAddedConn then
        characterAddedConn:Disconnect()
        characterAddedConn = nil
    end
    isBypassActive = false
end

function BypassModule.isEnabled()
    return isBypassActive
end

function BypassModule.updateSpoofedPosition(pos)
    if pos then
        spoofedPosition = pos
    else
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            spoofedPosition = hrp.Position
        end
    end
end

function BypassModule.updateSpoofedVelocity(vel)
    if vel then
        spoofedVelocity = vel
    else
        spoofedVelocity = Vector3.new(0,0,0)
    end
end

return BypassModule
