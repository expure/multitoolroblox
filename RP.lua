local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
if  _G.sourcecheckexvs ~= "source" then 
    warn("https://rscripts.net/script/multi-tool-hub-X0cu")
    error("The script source is not supported! Please use EXVS Hub from link upper!", 0)
end
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SCRIPT_URL = "https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/RP.lua"

local skippedPromptNames = {}

local persistedAutoFarm = false

pcall(function()
	if type(getgenv) == "function" then
		persistedAutoFarm = getgenv().AutoFixAutoFarm == true
			or getgenv().AutoFixAutoSetupGame == true
	end
end)

local function findPath(root, names)
	local current = root

	for _, childName in ipairs(names) do
		if not current then
			return nil
		end

		current = current:FindFirstChild(childName)

		if not current then
			return nil
		end
	end

	return current
end

local instanceCache = {}

local function getCachedInstance(cacheKey, root, names)
	local cached = instanceCache[cacheKey]

	if cached and cached.Parent then
		return cached
	end

	local found = findPath(root, names)

	if found then
		instanceCache[cacheKey] = found
		return found
	end

	instanceCache[cacheKey] = nil
	return nil
end

local function isValidRemote(instance)
	return instance ~= nil
		and typeof(instance) == "Instance"
		and instance:IsA("RemoteEvent")
end

local function getRemote(cacheKey, root, names)
	local remote = getCachedInstance(cacheKey, root, names)

	if isValidRemote(remote) then
		return remote
	end

	instanceCache[cacheKey] = nil
	return nil
end

local function getLightRemote()
	return getRemote(
		"Remote_Light",
		playerGui,
		{"FixLightMinigame", "Minigame2", "FixLight"}
	)
end

local function getHoleRemote()
	return getRemote(
		"Remote_Hole",
		ReplicatedStorage,
		{"HoleFix"}
	)
end

local function getFireRemote()
	return getRemote(
		"Remote_Fire",
		ReplicatedStorage,
		{"FixFire"}
	)
end

local function getO2Remote()
	return getRemote(
		"Remote_O2",
		Workspace,
		{"Values", "RepumpAirEvent"}
	)
end

local function getNavRemote()
	return getRemote(
		"Remote_Nav",
		ReplicatedStorage,
		{"FixNav"}
	)
end

local function getWindowRemote()
	return getRemote(
		"Remote_Window",
		ReplicatedStorage,
		{"WindowMinigame"}
	)
end

local function getEngineRemote()
	return getRemote(
		"Remote_Engine",
		ReplicatedStorage,
		{"EngineFixEvents", "FixEngineMinigame"}
	)
end

local function getTempRemote()
	return getRemote(
		"Remote_ACTemp",
		ReplicatedStorage,
		{"ACTempChange"}
	)
end

local function getLightsContainer()
	return getCachedInstance(
		"Container_Lights",
		Workspace,
		{"Plane", "Lights"}
	)
end

local function getHolesContainer()
	return getCachedInstance(
		"Container_Holes",
		Workspace,
		{"Plane", "Holes"}
	)
end

local function getFireContainer()
	return getCachedInstance(
		"Container_Fire",
		Workspace,
		{"Plane", "Fire"}
	)
end

local function getWindowsContainer()
	return getCachedInstance(
		"Container_Windows",
		Workspace,
		{"Plane", "Window"}
	)
end

local automations = {
	Lights = {
		enabled = false,
		budget = 4,
		acc = 0,
		index = 0,
		needsTarget = true,
		getRemote = getLightRemote,
		getContainer = getLightsContainer,
	},

	Holes = {
		enabled = false,
		budget = 30,
		acc = 0,
		index = 0,
		needsTarget = true,
		getRemote = getHoleRemote,
		getContainer = getHolesContainer,
	},

	Fire = {
		enabled = false,
		budget = 15,
		acc = 0,
		index = 0,
		needsTarget = true,
		getRemote = getFireRemote,
		getContainer = getFireContainer,
	},

	O2 = {
		enabled = false,
		budget = 65,
		acc = 0,
		needsTarget = false,
		getRemote = getO2Remote,
	},

	Nav = {
		enabled = false,
		budget = 1,
		acc = 0,
		needsTarget = false,
		getRemote = getNavRemote,
	},

	Fuel = {
		enabled = false,
		budget = 0,
		acc = 0,
	},

	Windows = {
		enabled = false,
		budget = 15,
		acc = 0,
		index = 0,
		needsTarget = true,
		extraArgs = {true},
		getRemote = getWindowRemote,
		getContainer = getWindowsContainer,
	},

	Engines = {
		enabled = false,
		budget = 2,
		acc = 0,
		needsTarget = false,
		engineState = false,
		getRemote = getEngineRemote,
	},

	Temp = {
		enabled = false,
		budget = 0,
		acc = 0,
	},

	AutoFarm = {
		enabled = persistedAutoFarm,
		budget = 0,
		acc = 0,
	},
}

local function trySend(data)
	local remote = data.getRemote()

	if not remote then
		return false
	end

	if data.customSend then
		return data.customSend(data, remote)
	end

	if data.needsTarget then
		local container = data.getContainer and data.getContainer() or nil

		if not container then
			return false
		end

		local children = container:GetChildren()

		if #children == 0 then
			return false
		end

		data.index = (data.index % #children) + 1

		local target = children[data.index]

		if not target then
			return false
		end

		if data.extraArgs then
			return pcall(remote.FireServer, remote, target.Name, table.unpack(data.extraArgs))
		end

		return pcall(remote.FireServer, remote, target.Name)
	else
		return pcall(remote.FireServer, remote)
	end
end

automations.Engines.customSend = function(data, remote)
	data.engineState = not data.engineState
	return pcall(remote.FireServer, remote, data.engineState)
end

local function waitForHumanoidRootPart(timeout)
	local startTime = os.clock()

	while os.clock() - startTime < timeout do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")

		if hrp then
			return hrp
		end

		task.wait(0.05)
	end

	return nil
end

local function teleportToCFrame(cf)
	local hrp = waitForHumanoidRootPart(2)

	if not hrp then
		return false
	end

	pcall(function()
		hrp.CFrame = cf
	end)

	return true
end

local function teleportToInstance(instance)
	if not instance then
		return false
	end

	local cf

	if instance:IsA("BasePart") then
		cf = instance.CFrame
	elseif instance:IsA("Model") then
		local ok, pivot = pcall(function()
			return instance:GetPivot()
		end)

		if ok and pivot then
			cf = pivot
		else
			local primary = instance.PrimaryPart

			if primary then
				cf = primary.CFrame
			else
				local part = instance:FindFirstChildWhichIsA("BasePart", true)

				if part then
					cf = part.CFrame
				else
					return false
				end
			end
		end
	else
		local part = instance:FindFirstChildWhichIsA("BasePart", true)

		if part then
			cf = part.CFrame
		else
			return false
		end
	end

	return teleportToCFrame(cf)
end

local function teleportToPath(root, names, timeout)
	local startTime = os.clock()

	while os.clock() - startTime < timeout do
		local instance = findPath(root, names)

		if instance and teleportToInstance(instance) then
			return true
		end

		task.wait(0.1)
	end

	return false
end

local managedPrompts = {}
local managedPromptSet = {}

local function setPromptProperties(prompt)
	prompt.Enabled = true
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.MaxInteractionDistance = 9999
end

local executorFireProximityPrompt = nil

local function getFireProximityPromptFunction()
	if executorFireProximityPrompt then
		return executorFireProximityPrompt
	end

	pcall(function()
		if type(fireproximityprompt) == "function" then
			executorFireProximityPrompt = fireproximityprompt
		end
	end)

	return executorFireProximityPrompt
end

local function pressPrompt(prompt)
	local fn = getFireProximityPromptFunction()

	if fn then
		pcall(fn, prompt)
	else
		pcall(prompt.InputHoldBegin, prompt)
	end
end

local function addManagedPrompt(prompt)
	if not prompt or managedPromptSet[prompt] then
		return
	end

	if table.find(skippedPromptNames, prompt.Name) then
		return
	end

	managedPromptSet[prompt] = true
	table.insert(managedPrompts, prompt)
end

local function configureAndPressPrompt(prompt)
	if not prompt or not prompt.Parent then
		return
	end

	if table.find(skippedPromptNames, prompt.Name) then
		return
	end

	addManagedPrompt(prompt)

	pcall(setPromptProperties, prompt)
	pressPrompt(prompt)
end

local function collectProximityPrompts(root)
	local prompts = {}

	if not root then
		return prompts
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			table.insert(prompts, descendant)
		end
	end

	return prompts
end

local function activateAllProximityPrompts(root)
	local prompts = collectProximityPrompts(root)

	for _, prompt in ipairs(prompts) do
		configureAndPressPrompt(prompt)
		task.wait(0.1)
	end
end

local function waitForPromptAtPath(root, names, timeout)
	local startTime = os.clock()

	while os.clock() - startTime < timeout do
		local obj = findPath(root, names)

		if obj then
			local prompt = nil

			if obj:IsA("ProximityPrompt") then
				prompt = obj
			else
				prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
			end

			if prompt then
				return prompt
			end
		end

		task.wait(0.1)
	end

	return nil
end

local function triggerPromptAtPath(root, names, timeout)
	local startTime = os.clock()

	while os.clock() - startTime < timeout do
		local obj = findPath(root, names)

		if obj then
			local prompt = nil

			if obj:IsA("ProximityPrompt") then
				prompt = obj
			else
				prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
			end

			if prompt then
				configureAndPressPrompt(prompt)
				return true
			end
		end

		task.wait(0.1)
	end

	return false
end

local promptEnabledProtected = {}
local enabledProtectionInstalled = false

local function installEnabledProtection()
	if enabledProtectionInstalled then
		return true
	end

	pcall(function()
		if type(getrawmetatable) ~= "function" then
			return
		end

		if type(setreadonly) ~= "function" then
			return
		end

		if type(newcclosure) ~= "function" then
			return
		end

		local mt = getrawmetatable(game)

		if not mt then
			return
		end

		local oldNewIndex = mt.__newindex

		if type(oldNewIndex) ~= "function" then
			return
		end

		setreadonly(mt, false)

		mt.__newindex = newcclosure(function(obj, prop, value)
			if
				typeof(obj) == "Instance"
				and prop == "Enabled"
				and value == false
				and promptEnabledProtected[obj]
			then
				return
			end

			return oldNewIndex(obj, prop, value)
		end)

		setreadonly(mt, true)
		enabledProtectionInstalled = true
	end)

	return enabledProtectionInstalled
end

local function protectPromptEnabled(prompt)
	if not prompt then
		return
	end

	pcall(function()
		prompt.Enabled = true
	end)

	promptEnabledProtected[prompt] = true
	installEnabledProtection()
end

RunService.Heartbeat:Connect(function()
	for i = #managedPrompts, 1, -1 do
		local prompt = managedPrompts[i]

		if not prompt or not prompt.Parent then
			managedPromptSet[prompt] = nil
			table.remove(managedPrompts, i)
		else
			pcall(setPromptProperties, prompt)
		end
	end
end)

local FIX_FUNCTION_KEYS = {
	"Lights",
	"Holes",
	"Fire",
	"O2",
	"Nav",
	"Fuel",
	"Windows",
	"Engines",
}

local function anyFixFunctionEnabled()
	for _, key in ipairs(FIX_FUNCTION_KEYS) do
		local data = automations[key]

		if data and data.enabled then
			return true
		end
	end

	return false
end

local instantInteractionEnabled = false
local instantLocked = false
local instantSavedHold = {}
local instantPrompts = {}
local instantPromptSet = {}
local instantButton = nil

local function refreshInstantPrompts()
	local roots = {Workspace, playerGui}

	for _, root in ipairs(roots) do
		pcall(function()
			for _, descendant in ipairs(root:GetDescendants()) do
				if descendant:IsA("ProximityPrompt") and not instantPromptSet[descendant] then
					instantPromptSet[descendant] = true
					table.insert(instantPrompts, descendant)
				end
			end
		end)
	end

	for i = #instantPrompts, 1, -1 do
		local prompt = instantPrompts[i]

		if not prompt or not prompt.Parent then
			instantPromptSet[prompt] = nil
			table.remove(instantPrompts, i)
		end
	end
end

local function restoreInstantHold()
	for prompt, original in pairs(instantSavedHold) do
		if prompt and prompt.Parent then
			pcall(function()
				prompt.HoldDuration = original
			end)
		end
	end

	table.clear(instantSavedHold)
end

local function updateInstantVisual()
	if not instantButton then
		return
	end

	if instantLocked then
		instantButton.Active = false
		instantButton.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
		instantButton.TextColor3 = Color3.fromRGB(120, 120, 120)
		instantButton.Text = "Instant Interaction: LOCKED"
	else
		instantButton.Active = true
		instantButton.TextColor3 = Color3.fromRGB(235, 235, 235)
		instantButton.Text = "Instant Interaction: " .. (instantInteractionEnabled and "ON" or "OFF")
		instantButton.BackgroundColor3 = instantInteractionEnabled
			and Color3.fromRGB(35, 105, 65)
			or Color3.fromRGB(42, 42, 52)
	end
end

local function setInstantInteraction(enabled)
	if instantInteractionEnabled == enabled then
		return
	end

	instantInteractionEnabled = enabled

	if enabled then
		refreshInstantPrompts()
	else
		restoreInstantHold()
		table.clear(instantPrompts)
		table.clear(instantPromptSet)
	end

	updateInstantVisual()
end

local function refreshInstantLock()
	local locked = anyFixFunctionEnabled()

	if locked == instantLocked then
		return
	end

	instantLocked = locked

	if locked and instantInteractionEnabled then
		instantInteractionEnabled = false
		restoreInstantHold()
		table.clear(instantPrompts)
		table.clear(instantPromptSet)
	end

	updateInstantVisual()
end

RunService.RenderStepped:Connect(function()
	if not instantInteractionEnabled then
		return
	end

	for _, prompt in ipairs(instantPrompts) do
		if prompt and prompt.Parent then
			if instantSavedHold[prompt] == nil then
				local okRead, current = pcall(function()
					return prompt.HoldDuration
				end)

				if okRead then
					instantSavedHold[prompt] = current
				end
			end

			pcall(function()
				prompt.HoldDuration = 0
			end)
		end
	end
end)

task.spawn(function()
	while true do
		if instantInteractionEnabled then
			refreshInstantPrompts()
		end

		task.wait(2)
	end
end)

task.spawn(function()
	while true do
		refreshInstantLock()
		task.wait(0.25)
	end
end)

local TOOL_SWITCH_INTERVAL = 1

local function equipToolsSequentially()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return 0
	end

	local backpack = player:FindFirstChildOfClass("Backpack")

	if not backpack then
		return 0
	end

	local equipped = 0

	for _, inst in ipairs(backpack:GetChildren()) do
		if inst:IsA("Tool") then
			pcall(function()
				humanoid:EquipTool(inst)
			end)

			equipped += 1
			task.wait(TOOL_SWITCH_INTERVAL)
		end
	end

	return equipped
end

local function anyFunctionEnabled()
	for key, data in pairs(automations) do
		if key ~= "AutoFarm" and data.enabled then
			return true
		end
	end

	return false
end

local function cycleToolsOnce()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false
	end

	local tools = {}
	local seen = {}

	local function addFrom(container)
		if not container then
			return
		end

		for _, inst in ipairs(container:GetChildren()) do
			if inst:IsA("Tool") and not seen[inst] then
				seen[inst] = true
				table.insert(tools, inst)
			end
		end
	end

	addFrom(player:FindFirstChildOfClass("Backpack"))
	addFrom(character)

	if #tools == 0 then
		return false
	end

	for _, tool in ipairs(tools) do
		if tool.Parent then
			pcall(function()
				humanoid:EquipTool(tool)
			end)

			task.wait(TOOL_SWITCH_INTERVAL)
		end
	end

	return true
end

local pauseToolCycling = false

task.spawn(function()
	while true do
		if anyFunctionEnabled() and not pauseToolCycling then
			local cycled = cycleToolsOnce()

			if not cycled then
				task.wait(0.25)
			end
		else
			task.wait(0.25)
		end
	end
end)

local function clickGuiButton(button)
	if not button then
		return false
	end

	local clicked = false

	pcall(function()
		if type(getconnections) == "function" then
			local signals = {button.MouseButton1Click, button.Activated}

			for _, signal in ipairs(signals) do
				local conns = getconnections(signal)

				if conns then
					for _, conn in ipairs(conns) do
						local ok = false

						if type(conn.Function) == "function" then
							ok = pcall(conn.Function)
						end

						if not ok then
							ok = pcall(function()
								conn:Fire()
							end)
						end

						if ok then
							clicked = true
						end
					end
				end
			end
		end
	end)

	if not clicked then
		local ok = pcall(function()
			button.MouseButton1Click:Fire()
		end)

		if ok then
			clicked = true
		end
	end

	if not clicked then
		local ok = pcall(function()
			button.Activated:Fire()
		end)

		if ok then
			clicked = true
		end
	end

	return clicked
end

local function getSkipButton()
	local button = findPath(playerGui, {"CutsceneDialogue", "Frame1", "SkipButton"})

	if not button then
		button = findPath(StarterGui, {"CutsceneDialogue", "Frame1", "SkipButton"})
	end

	if not button then
		pcall(function()
			button = playerGui:FindFirstChild("SkipButton", true)
		end)
	end

	if not button then
		pcall(function()
			button = StarterGui:FindFirstChild("SkipButton", true)
		end)
	end

	return button
end

local TARGET_TEMP = 22
local TEMP_TOLERANCE = 0.5

local function parseTemperature(text)
	if type(text) ~= "string" then
		return nil
	end

	local num = text:match("%-?%d+[%,%.]?%d*")

	if not num then
		return nil
	end

	num = num:gsub(",", ".")

	return tonumber(num)
end

local AC_FRAME_PATH = {
	"Plane",
	"Machines",
	"AirConditionner",
	"Screen",
	"SurfaceGui",
	"Frame",
}

local function readCurrentTemp()
	local frame = findPath(Workspace, AC_FRAME_PATH)
	local label = frame and frame:FindFirstChild("TemperatureLabel")

	if not label then
		return nil
	end

	local ok, text = pcall(function()
		return label.Text
	end)

	if not ok then
		return nil
	end

	return parseTemperature(text)
end

local function sendTempChange(raise)
	local remote = getTempRemote()

	if not remote then
		return false
	end

	return pcall(remote.FireServer, remote, raise and true or false)
end

task.spawn(function()
	while true do
		if automations.Temp.enabled then
			local temp = readCurrentTemp()

			if temp then
				local diff = temp - TARGET_TEMP

				if diff < -TEMP_TOLERANCE then
					sendTempChange(true)
					task.wait(0.4)
				elseif diff > TEMP_TOLERANCE then
					sendTempChange(false)
					task.wait(0.4)
				else
					task.wait(0.5)
				end
			else
				task.wait(0.5)
			end
		else
			task.wait(0.25)
		end
	end
end)

local function getQueueFunction()
	if type(queueonteleport) == "function" then
		return queueonteleport
	end

	if type(queueteleport) == "function" then
		return queueteleport
	end

	return nil
end

local function clearTeleportQueue()
	pcall(function()
		if type(clearqueueonteleport) == "function" then
			clearqueueonteleport()
			return
		end

		if type(clearteleportqueue) == "function" then
			clearteleportqueue()
		end
	end)
end

local function buildSelfPayload(statePrefix)
	local payload =
		(statePrefix or "")
		.. 'if not game:IsLoaded() then game.Loaded:Wait() end\n'
		.. 'local Players = game:GetService("Players")\n'
		.. 'while not Players.LocalPlayer do task.wait(0.1) end\n'
		.. 'local player = Players.LocalPlayer\n'
		.. 'while not player:FindFirstChild("PlayerGui") or not player.Character do task.wait(0.1) end\n'
		.. 'print("Auto Farm: restarting on new server")\n'
		.. 'local success, err = pcall(function()\n'
		.. '	 _G.sourcecheckexvs = "source"\n'
		.. '    loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()\n'
		.. 'end)\n'
		.. 'if not success then warn("Auto Farm Error: "..tostring(err)) end\n'

	return payload
end

local function queueSelfPayload(statePrefix)
	local queueFunc = getQueueFunction()

	if not queueFunc then
		return false
	end

	clearTeleportQueue()

	return pcall(queueFunc, buildSelfPayload(statePrefix))
end

local function persistAutoFarmState(enabled)
	pcall(function()
		if type(getgenv) == "function" then
			getgenv().AutoFixAutoFarm = enabled and true or false
		end
	end)

	local statePrefix = enabled
		and 'if getgenv then getgenv().AutoFixAutoFarm = true end\n'
		or 'if getgenv then getgenv().AutoFixAutoFarm = false end\n'

	queueSelfPayload(statePrefix)
end

local toggleUpdaters = {}

local function enableAllFunctions()
	for key, data in pairs(automations) do
		if key ~= "AutoFarm" then
			data.enabled = true
			data.acc = 0

			local updater = toggleUpdaters[key]

			if updater then
				updater()
			end
		end
	end
end

local function getNumberFromPath(root, names)
	local obj = findPath(root, names)

	if not obj then
		return nil
	end

	local ok, value = pcall(function()
		return obj.Value
	end)

	if ok and typeof(value) == "number" then
		return value
	end

	return nil
end

local function collectTools(set)
	local function scan(container)
		if not container then
			return
		end

		for _, inst in ipairs(container:GetChildren()) do
			if inst:IsA("Tool") then
				set[inst] = true
			end
		end
	end

	scan(player:FindFirstChildOfClass("Backpack"))
	scan(player.Character)
end

local function getToolSet()
	local set = {}
	collectTools(set)
	return set
end

local function findBestTool(set)
	local fallback = nil

	for tool in pairs(set) do
		local nameLower = tool.Name:lower()

		if
			string.find(nameLower, "gas")
			or string.find(nameLower, "can")
			or string.find(nameLower, "fuel")
		then
			return tool
		end

		if not fallback then
			fallback = tool
		end
	end

	return fallback
end

local function waitForNewTool(oldSet, timeout)
	local startTime = os.clock()

	while os.clock() - startTime < timeout do
		local currentSet = {}
		collectTools(currentSet)

		local newSet = {}

		for tool in pairs(currentSet) do
			if not oldSet[tool] then
				newSet[tool] = true
			end
		end

		local bestTool = findBestTool(newSet)

		if bestTool then
			return bestTool
		end

		task.wait(0.05)
	end

	return nil
end

local function equipTool(tool)
	for _ = 1, 20 do
		if not tool or not tool.Parent then
			return false
		end

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			pcall(function()
				humanoid:EquipTool(tool)
			end)

			return true
		end

		task.wait(0.05)
	end

	return false
end

local fuelBusy = false

local function runFuelSequence()
	if not automations.Fuel.enabled then
		return
	end

	if not teleportToPath(Workspace, {"PlaneTHUMBNAIL", "GrabGasCan"}, 6) then
		return
	end

	task.wait(0.7)

	if not automations.Fuel.enabled then
		return
	end

	local oldTools = getToolSet()

	triggerPromptAtPath(
		Workspace,
		{"PlaneTHUMBNAIL", "GrabGasCan", "GrabCan"},
		4
	)

	local tool = waitForNewTool(oldTools, 6)

	if not tool then
		local currentTools = {}
		collectTools(currentTools)
		tool = findBestTool(currentTools)
	end

	if tool then
		equipTool(tool)
	end

	task.wait(0.15)

	if not automations.Fuel.enabled then
		return
	end

	if not teleportToPath(Workspace, {"Plane", "Machines", "Generator", "DumpFuel"}, 6) then
		return
	end

	task.wait(0.7)

	if tool then
		equipTool(tool)
	end

	triggerPromptAtPath(
		Workspace,
		{"Plane", "Machines", "Generator", "DumpFuel", "FuelUp"},
		4
	)

	task.wait(1)
end

task.spawn(function()
	while true do
		if automations.Fuel.enabled and not fuelBusy then
			local fuel = getNumberFromPath(Workspace, {"Values", "Fuel"})
			local maxFuel = getNumberFromPath(Workspace, {"Values", "MaxFuel"})

			if fuel and maxFuel and (maxFuel - fuel > 10) then
				fuelBusy = true
				pauseToolCycling = true

				task.spawn(function()
					pcall(runFuelSequence)
					task.wait(1)
					fuelBusy = false
					pauseToolCycling = false
				end)
			end
		end

		task.wait(1)
	end
end)

task.spawn(function()
	while true do
		if automations.AutoFarm.enabled then
			local frame = findPath(playerGui, {"DeathScreen", "Frame"})
			local playAgain = findPath(playerGui, {"DeathScreen", "Frame", "PlayAgain"})

			if frame and playAgain and frame.Visible == true then
				clickGuiButton(playAgain)
			end
		end

		task.wait(0.25)
	end
end)

local setupBusy = false
local setupWasRun = false

local function runSetupGame()
	if setupBusy then
		return
	end

	setupBusy = true
	setupWasRun = true

	enableAllFunctions()

	local hardPrompt = waitForPromptAtPath(
		Workspace,
		{"Plane", "InfoScreen", "HardMode", "HardModeProx"},
		15
	)

	local normalPrompt = waitForPromptAtPath(
		Workspace,
		{"Plane", "InfoScreen", "NormalMode", "NormalModeProx"},
		15
	)

	local startPrompt = waitForPromptAtPath(
		Workspace,
		{"Plane", "InfoScreen", "StartButton", "StartGameProx"},
		15
	)

	for _, prompt in ipairs({hardPrompt, normalPrompt, startPrompt}) do
		if prompt then
			addManagedPrompt(prompt)
			protectPromptEnabled(prompt)
			pcall(setPromptProperties, prompt)
		end
	end

	if hardPrompt then
		for _ = 1, 3 do
			pressPrompt(hardPrompt)
			task.wait(0.2)
		end
	end

	if normalPrompt then
		for _ = 1, 3 do
			pressPrompt(normalPrompt)
			task.wait(0.2)
		end
	end

	if startPrompt then
		for _ = 1, 25 do
			pressPrompt(startPrompt)
			task.wait(1 / 25)
		end
	end

	teleportToPath(
		Workspace,
		{"Plane", "Stepladder", "LadderCenter"},
		10
	)

	task.wait(0.25)

	local plane = Workspace:FindFirstChild("Plane")
	local tools = plane and plane:FindFirstChild("Tools")

	if tools then
		activateAllProximityPrompts(tools)
	end

	task.wait(0.5)
	equipToolsSequentially()

	task.wait(3)

	local skipEndTime = os.clock() + 30

	while os.clock() < skipEndTime do
		local skipButton = getSkipButton()

		if skipButton then
			clickGuiButton(skipButton)
		end

		task.wait(1 / 3)
	end

	setupBusy = false
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFixGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(270, 505)
main.Position = UDim2.new(0.5, -135, 0.5, -252)
main.BackgroundColor3 = Color3.fromRGB(23, 23, 28)
main.BorderSizePixel = 0
main.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(65, 65, 78)
mainStroke.Thickness = 1
mainStroke.Parent = main

local titleBar = Instance.new("TextButton")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(33, 33, 41)
titleBar.BorderSizePixel = 0
titleBar.Text = "Auto Fix Panel"
titleBar.TextColor3 = Color3.fromRGB(240, 240, 240)
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 15
titleBar.Parent = main

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "Buttons"
buttonContainer.Size = UDim2.new(1, -16, 1, -40)
buttonContainer.Position = UDim2.new(0, 8, 0, 34)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = main

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 7)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = buttonContainer

local function makeDraggable(handle, frame)
	local dragging = false
	local dragStart = nil
	local startPos = nil

	handle.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - dragStart

			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
end

makeDraggable(titleBar, main)

local function createToggle(key, text, order, onChange)
	local button = Instance.new("TextButton")
	button.Name = key
	button.Size = UDim2.new(1, 0, 0, 32)
	button.BackgroundColor3 = Color3.fromRGB(42, 42, 52)
	button.BorderSizePixel = 0
	button.Text = text .. ": OFF"
	button.TextColor3 = Color3.fromRGB(235, 235, 235)
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 14
	button.AutoButtonColor = false
	button.LayoutOrder = order
	button.Parent = buttonContainer

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	local function updateVisual()
		local enabled = automations[key].enabled

		button.Text = text .. ": " .. (enabled and "ON" or "OFF")

		button.BackgroundColor3 = enabled
			and Color3.fromRGB(35, 105, 65)
			or Color3.fromRGB(42, 42, 52)
	end

	toggleUpdaters[key] = updateVisual

	button.MouseButton1Click:Connect(function()
		automations[key].enabled = not automations[key].enabled
		automations[key].acc = 0
		updateVisual()

		if onChange then
			onChange(automations[key].enabled)
		end
	end)

	updateVisual()
end

createToggle("Lights", "Auto Fix Lights", 1)
createToggle("Holes", "Auto Fix Holes", 2)
createToggle("Fire", "Auto Fire Pipe Fix", 3)
createToggle("O2", "Infinite O2", 4)
createToggle("Nav", "Auto Fix Nav", 5)
createToggle("Fuel", "Auto Fuel", 6)
createToggle("Windows", "Auto Windows Fix", 7)
createToggle("Engines", "Auto Engines Fix", 8)

createToggle("AutoFarm", "Auto Farm", 9, function(enabled)
	persistAutoFarmState(enabled)

	if enabled and not setupWasRun then
		task.spawn(runSetupGame)
	end
end)

instantButton = Instance.new("TextButton")
instantButton.Name = "InstantInteraction"
instantButton.Size = UDim2.new(1, 0, 0, 32)
instantButton.BackgroundColor3 = Color3.fromRGB(42, 42, 52)
instantButton.BorderSizePixel = 0
instantButton.Text = "Instant Interaction: OFF"
instantButton.TextColor3 = Color3.fromRGB(235, 235, 235)
instantButton.Font = Enum.Font.GothamMedium
instantButton.TextSize = 14
instantButton.AutoButtonColor = false
instantButton.LayoutOrder = 10
instantButton.Parent = buttonContainer

local instantCorner = Instance.new("UICorner")
instantCorner.CornerRadius = UDim.new(0, 8)
instantCorner.Parent = instantButton

instantButton.MouseButton1Click:Connect(function()
	if instantLocked then
		return
	end

	setInstantInteraction(not instantInteractionEnabled)
end)

updateInstantVisual()

createToggle("Temp", "Set Temp", 11)

local setupButton = Instance.new("TextButton")
setupButton.Name = "SetupGame"
setupButton.Size = UDim2.new(1, 0, 0, 32)
setupButton.BackgroundColor3 = Color3.fromRGB(60, 50, 30)
setupButton.BorderSizePixel = 0
setupButton.Text = "Setup Game"
setupButton.TextColor3 = Color3.fromRGB(235, 235, 235)
setupButton.Font = Enum.Font.GothamMedium
setupButton.TextSize = 14
setupButton.AutoButtonColor = false
setupButton.LayoutOrder = 12
setupButton.Parent = buttonContainer

local setupButtonCorner = Instance.new("UICorner")
setupButtonCorner.CornerRadius = UDim.new(0, 8)
setupButtonCorner.Parent = setupButton

setupButton.MouseButton1Click:Connect(function()
	task.spawn(runSetupGame)
end)

task.spawn(function()
	local plane = Workspace:WaitForChild("Plane", 15)
	local tools = plane and plane:WaitForChild("Tools", 15) or nil

	if automations.AutoFarm.enabled then
		task.spawn(runSetupGame)
	end

	if tools then
		for _, prompt in ipairs(collectProximityPrompts(tools)) do
			addManagedPrompt(prompt)
		end

		tools.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("ProximityPrompt") then
				addManagedPrompt(descendant)
			end
		end)
	end
end)

queueSelfPayload(nil)

RunService.Heartbeat:Connect(function(deltaTime)
	for _, data in pairs(automations) do
		if data.budget and data.budget > 0 then
			if data.enabled then
				data.acc = math.min(data.acc + deltaTime * data.budget, data.budget)

				local maxFrameBurst = math.max(1, math.floor(data.budget / 5))
				local sends = math.min(math.floor(data.acc), maxFrameBurst)

				for _ = 1, sends do
					local ok = trySend(data)

					if ok then
						data.acc -= 1
					else
						data.acc = math.min(data.acc, 1)
						break
					end
				end
			else
				data.acc = 0
			end
		else
			data.acc = 0
		end
	end
end)
