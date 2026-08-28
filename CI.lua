local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PathfindingService = game:GetService("PathfindingService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

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
	FARM_HOVER = 20,
	LEGIT_WALKSPEED = 85,
	LEGIT_REPATH_TIME = 1.5,
	TP_OFFSET = CFrame.new(0, 2, 0),
	TARGET_REFRESH = 0.2,
	SHOP_SESSION_INTERVAL = 2,
	UPGRADE_COOLDOWN = 0.5,
	WALL_MAX_TIME = 2.5,
	ARMOR_MAX_TIME = 2.5,
	ARMOR_COOLDOWN = 1,
	PROMPT_PRESS_DELAY = 0.3,
	HOLD_BUY_TIME = 0.8,
	MAX_DT = 0.05,
	Q_PRESS_INTERVAL = 6,
}

local IGNORED_ATTACK_TOOLS = {
	["Slingshot"] = true,
	["Caveman Club"] = true,
}

local player = Players.LocalPlayer
local autoKillEnabled = false
local rangeKillEnabled = false
local autoHealEnabled = false
local autoUpgradeEnabled = false
local autoFarmEnabled = false
local legitMoveEnabled = false
local hBindEnabled = true
local retreatMode = false
local upgradeBusy = false

local moveGoal = nil
local moveLook = nil
local savedWalkSpeed = nil
local statusText = "M:- P:- | IDLE"

local targetCache = {}
local lastScan = 0
local lastClick = 0
local lastEat = 0
local lastFleePick = 0
local lastRepair = 0
local lastSession = 0
local cachedMoney = nil
local lastMoneyScan = 0

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local noclipOn = false
local function setNoclip(active)
	if noclipOn == active then return end
	noclipOn = active
	if not character then return end
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.CanCollide = not active
		end
	end
end

local function setLegit(on)
	legitMoveEnabled = on
	if on then rangeKillEnabled = false end
	if humanoid then
		if on then
			savedWalkSpeed = humanoid.WalkSpeed
			humanoid.WalkSpeed = CONFIG.LEGIT_WALKSPEED
		else
			humanoid.WalkSpeed = savedWalkSpeed or 16
		end
	end
end

local function setFarm(on)
	autoFarmEnabled = on
	if on then
		autoKillEnabled = false
		rangeKillEnabled = false
		legitMoveEnabled = false
	end
	if rootPart then
		rootPart.Anchored = on and true or false
	end
end

local function setRangeKill(on)
	rangeKillEnabled = on
	if on then
		autoFarmEnabled = false
		legitMoveEnabled = false
		if rootPart then rootPart.Anchored = false end
	end
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

local function screenClick()
	local cam = workspace.CurrentCamera
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
		if humanoid then humanoid:EquipTool(food) end
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
		if coins then cachedMoney = coins.Value return cachedMoney end
		for _, v in ipairs(ls:GetChildren()) do
			if (v:IsA("IntValue") or v:IsA("NumberValue")) and v.Name:lower():find("coin",1,true) then
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
	if obj:IsA("BindableEvent") then obj:Fire() return true end
	if obj:IsA("RemoteEvent") then pcall(function() obj:FireServer() end) return true end
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

local function getDisplay(category)
	local pg = player:FindFirstChild("PlayerGui")
	return pg and resolvePath(pg, "UI.WeaponsHUD.DisplayInfo." .. category)
end

local function readItemPrice(item)
	local priceObj = item:FindFirstChild("Price")
	if not priceObj then return nil end
	local display = priceObj:FindFirstChild("Display")
	if not display then return nil end
	return parsePrice(tostring(display.Text))
end

local function scanAffordable(category, money)
	local display = getDisplay(category)
	if not display or not money then return false end
	for _, item in ipairs(display:GetChildren()) do
		if item:IsA("Frame") then
			local p = readItemPrice(item)
			if p and money >= p then return true end
		end
	end
	return false
end

local function selectCategory(category)
	local pg = player:FindFirstChild("PlayerGui")
	local cat = pg and resolvePath(pg, "UI.WeaponsHUD.Categories." .. category)
	if not cat then return end
	local click = cat:FindFirstChild("Click")
	local selected = cat:FindFirstChild("Selected")
	for i = 1, 2 do
		if selected and selected.Visible then return end
		pressControl(click)
		task.wait(0.25)
	end
end

local function buyCategory(category)
	selectCategory(category)
	task.wait(0.2)
	local display = getDisplay(category)
	if not display then return end
	local pl = display:FindFirstChildWhichIsA("UIPageLayout")
	local money = getMoney()
	local target = nil
	local current = pl and pl.CurrentPage
	if current and current:IsA("Frame") then
		local p = readItemPrice(current)
		if p and money and money >= p then target = current end
	end
	if not target then
		for _, item in ipairs(display:GetChildren()) do
			if item:IsA("Frame") then
				local p = readItemPrice(item)
				if p and money and money >= p then target = item break end
			end
		end
	end
	if not target then return end
	local upg = target:FindFirstChild("Upgrade")
	local ctl = upg and (upg:FindFirstChild("Click") or upg)
	if ctl and (not upg or upg.Visible ~= false) and pressControl(ctl) then task.wait(0.3) return end
	local purch = target:FindFirstChild("Purchase")
	if purch and purch.Visible then pressHold(purch, CONFIG.HOLD_BUY_TIME) task.wait(0.3) return end
	if ctl then pressControl(ctl) task.wait(0.3) end
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

local function pressPrompt(prompt)
	local ok = pcall(function() fireproximityprompt(prompt) end)
	if not ok then pcall(function() prompt:InputHoldBegin() end) end
end

local function tryWallUpgrade(money)
	local price = parsePrice(getWallPriceText())
	if not price or money < price then return false end
	local prompt, holder = getWallUpgradeObjects()
	if not prompt or not holder or not rootPart then return false end
	local baseText = getWallPriceText()
	local oldAnchor = rootPart.Anchored
	rootPart.Anchored = false
	rootPart.CFrame = holder.CFrame * CFrame.new(0, 3, 0)
	task.wait(0.3)
	local startT = tick()
	local lp = 0
	while tick() - startT < CONFIG.WALL_MAX_TIME do
		if getWallPriceText() ~= baseText then break end
		if tick() - lp >= CONFIG.PROMPT_PRESS_DELAY then lp = tick() pressPrompt(prompt) end
		task.wait(0.05)
	end
	rootPart.Anchored = oldAnchor
	return true
end

local function tryArmorUpgrade(money)
	local priceText = getPriceText()
	local price = priceText and parsePrice(priceText)
	if not price or money < price or price == 79 then return false end
	local headHolder, prompt, holderPart = getArmorUpgradeObjects()
	local anchor = holderPart or headHolder
	if not anchor or not rootPart then return false end
	local baseText = priceText
	local oldAnchor = rootPart.Anchored
	rootPart.Anchored = false
	rootPart.CFrame = anchor.CFrame * CFrame.new(0, 3, 0)
	task.wait(0.3)
	local startT = tick()
	local lp = 0
	while tick() - startT < CONFIG.ARMOR_MAX_TIME do
		if getPriceText() ~= baseText then break end
		if prompt and tick() - lp >= CONFIG.PROMPT_PRESS_DELAY then lp = tick() pressPrompt(prompt) end
		task.wait(0.05)
	end
	if prompt then pcall(function() prompt:InputHoldEnd() end) end
	rootPart.Anchored = oldAnchor
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
	local map = workspace:FindFirstChild("_Map")
	local a, b = nil, nil
	if map then
		local cats = map:FindFirstChild("Cats")
		local sp = cats and cats:FindFirstChild("Spawners")
		local s1 = sp and sp:FindFirstChild("1")
		if s1 then
			local p = s1:FindFirstChildOfClass("Part") or s1:FindFirstChildOfClass("MeshPart")
			if p then a = p.Position end
		end
		local g = map:FindFirstChild("Game")
		local f = g and g:FindFirstChild("Food")
		local ft = f and f:FindFirstChild("Target")
		if ft then b = ft.Position end
	end
	if a and b then
		return (a + b) / 2 + Vector3.new(0, CONFIG.FARM_HOVER, 0)
	end
	if rootPart then
		return rootPart.Position + Vector3.new(0, CONFIG.FARM_HOVER, 0)
	end
	return Vector3.new(0, CONFIG.FARM_HOVER, 0)
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
					if d:IsA("BasePart") then part = d break end
				end
			end
			if part then table.insert(targetCache, part) end
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
			if d < bd then bd = d best = part end
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
	local map = workspace:FindFirstChild("_Map")
	local fort = map and map:FindFirstChild("Fortress")
	local walls = fort and fort:FindFirstChild("Walls")
	if not walls then return nil, nil end
	for _, wm in ipairs(walls:GetChildren()) do
		local hb = wm:FindFirstChild("WallHitbox")
		local p = hb and hb:FindFirstChild("BuildPrompt")
		if p and p:IsA("ProximityPrompt") and p.Enabled then
			return p, hb
		end
	end
	return nil, nil
end

local legitWaypoints = {}
local legitWaypointIndex = 1
local legitTargetPoint = nil
local lastRepath = 0

task.spawn(function()
	while true do
		task.wait(0.05)
		if not (legitMoveEnabled and moveGoal and rootPart and humanoid and humanoid.Health > 0) then
			legitWaypoints = {} legitWaypointIndex = 1 legitTargetPoint = nil
			continue
		end
		if humanoid.WalkSpeed ~= CONFIG.LEGIT_WALKSPEED then humanoid.WalkSpeed = CONFIG.LEGIT_WALKSPEED end
		local now = tick()
		local need = false
		if #legitWaypoints == 0 or legitWaypointIndex > #legitWaypoints then need = true
		elseif (moveGoal - legitTargetPoint).Magnitude > 12 then need = true
		elseif now - lastRepath > CONFIG.LEGIT_REPATH_TIME then need = true end
		if need then
			lastRepath = now
			legitTargetPoint = moveGoal
			pcall(function()
				local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
				path:ComputeAsync(rootPart.Position, legitTargetPoint)
				if path.Status == Enum.PathStatus.Success then
					legitWaypoints = path:GetWaypoints() legitWaypointIndex = 1
				else legitWaypoints = {} legitWaypointIndex = 1 end
			end)
		end
		local goal = moveGoal
		local jump = false
		if legitWaypointIndex <= #legitWaypoints then
			local wp = legitWaypoints[legitWaypointIndex]
			goal = wp.Position
			if wp.Action == Enum.PathWaypointAction.Jump then jump = true end
		end
		if (rootPart.Position - goal).Magnitude > 2 then
			humanoid:MoveTo(goal)
			if jump then humanoid.Jump = true end
		end
		if legitWaypointIndex <= #legitWaypoints then
			if (rootPart.Position - legitWaypoints[legitWaypointIndex].Position).Magnitude < 4 then
				legitWaypointIndex = legitWaypointIndex + 1
			end
		end
	end
end)

RunService.RenderStepped:Connect(function(dtRaw)
	if not rootPart then return end
	local dt = math.min(dtRaw or 0.016, CONFIG.MAX_DT)

	if rangeKillEnabled and humanoid and humanoid.Health > 0 then
		local t = getAttackTarget()
		if t then
			local cam = workspace.CurrentCamera
			cam.CFrame = CFrame.lookAt(cam.CFrame.Position, t.Position + Vector3.new(0, 1, 0))
		end
		return
	end

	if autoFarmEnabled and humanoid and humanoid.Health > 0 then
		local hover = getFarmHoverPoint()
		local t = getAttackTarget()
		local look = t and (t.Position + Vector3.new(0, 1, 0)) or hover
		rootPart.Anchored = true
		rootPart.CFrame = CFrame.lookAt(hover, look)
		local cam = workspace.CurrentCamera
		cam.CFrame = CFrame.lookAt(cam.CFrame.Position, look)
		return
	end

	if legitMoveEnabled then return end

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

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.H then
		if hBindEnabled then
			setRangeKill(not rangeKillEnabled)
			syncButtons()
		end
	end
	if input.KeyCode == Enum.KeyCode.Backspace then
		if autoFarmEnabled then
			setFarm(false)
			syncButtons()
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
		if not upgradeBusy then
			sendKey(true, Enum.KeyCode.Q)
			task.wait(0.06)
			sendKey(false, Enum.KeyCode.Q)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.2)
		local ok, err = pcall(function()
			if not (autoUpgradeEnabled and not retreatMode and not upgradeBusy and humanoid and rootPart and humanoid.Health > 0) then return end
			local money = getMoney()
			if not money then return end
			local ownsFood = findToolByTooltip(CONFIG.FOOD_TOOLTIP) ~= nil
			local foodFirst = not ownsFood and scanAffordable("Food", money)
			local weaponAfford = scanAffordable("Melee", money)
			local wallAfford = (function() local p = parsePrice(getWallPriceText()) return p ~= nil and money >= p end)()
			local foodAfford = scanAffordable("Food", money)
			local armorAfford = (function() local p = parsePrice(getPriceText()) return p ~= nil and p ~= 79 and money >= p end)()

			local action = nil
			if foodFirst then action = "food"
			elseif weaponAfford then action = "weapon"
			elseif wallAfford then action = "wall"
			elseif foodAfford then action = "food"
			elseif armorAfford then action = "armor" end
			if not action then return end

			if action == "food" or action == "weapon" then
				if tick() - lastSession < CONFIG.SHOP_SESSION_INTERVAL then return end
				lastSession = tick()
				upgradeBusy = true
				pressControl(getControl("UI.HUD.LeftButtons.Weapons.Click"))
				task.wait(0.4)
				if action == "weapon" then buyCategory("Melee") else buyCategory("Food") end
				pressControl(getControl("UI.WeaponsHUD.Back.Click"))
				task.wait(0.2)
				upgradeBusy = false
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
		local ok, err = pcall(function()
			if not (rootPart and humanoid) then return end
			if humanoid.Health <= 0 then moveGoal = nil moveLook = nil return end
			local now = tick()
			local maxHp = humanoid.MaxHealth
			local hpPct = maxHp > 0 and (humanoid.Health / maxHp) or 1

			if autoHealEnabled then
				if hpPct < CONFIG.RETREAT_ENTER and not retreatMode then retreatMode = true lastFleePick = 0
				elseif retreatMode and hpPct >= CONFIG.RETREAT_EXIT then retreatMode = false moveGoal = nil moveLook = nil end
			else retreatMode = false end

			if retreatMode then
				local n = getNearestTarget()
				if n then
					if now - lastFleePick >= CONFIG.FLEE_REPICK then
						lastFleePick = now
						local dir = rootPart.Position - n.Position
						dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(1, 0, 0)
						moveGoal = rootPart.Position + dir * CONFIG.FLEE_DISTANCE
						moveLook = moveGoal
					end
				else moveGoal = nil moveLook = nil end
				if now - lastEat >= CONFIG.EAT_DELAY then if tryEat() then lastEat = now end end
				statusText = string.format("M:%s P:%s | RETREAT", tostring(getMoney() or "-"), tostring(parsePrice(getPriceText()) or "-"))
				return
			end

			if autoHealEnabled and hpPct < CONFIG.EAT_THRESHOLD and now - lastEat >= CONFIG.EAT_DELAY then
				if tryEat() then lastEat = now end
			end

			local st = "IDLE"
			if autoFarmEnabled then st = "FARM"
			elseif rangeKillEnabled then st = "RANGE"
			elseif upgradeBusy then st = "UPG"
			elseif autoKillEnabled then st = "KILL" end
			statusText = string.format("M:%s P:%s | %s", tostring(getMoney() or "-"), tostring(parsePrice(getPriceText()) or "-"), st)

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
						screenClick()
					end
				end
			elseif autoFarmEnabled and not upgradeBusy then
				moveGoal = nil
				moveLook = nil
				local rtool = getRangedTool()
				if rtool and character:FindFirstChild(rtool.Name) ~= rtool then
					humanoid:EquipTool(rtool)
				end
				if now - lastClick >= CONFIG.CLICK_DELAY then
					lastClick = now
					screenClick()
				end
				local rp, rpart = getWallRepairPrompt()
				if rp and rpart then
					local d = (rootPart.Position - rpart.Position).Magnitude
					if d <= 10 and now - lastRepair >= CONFIG.PROMPT_PRESS_DELAY then
						lastRepair = now
						pressPrompt(rp)
					end
				end
			elseif autoKillEnabled and not upgradeBusy then
				local target = getAttackTarget()
				if target then
					moveGoal = (target.CFrame * CONFIG.TP_OFFSET).Position
					moveLook = target.Position
					local dist = (rootPart.Position - moveGoal).Magnitude
					if dist <= CONFIG.ATTACK_RANGE then
						local tool = findToolByTooltip(CONFIG.MELEE_TOOLTIP)
						if tool then
							if character:FindFirstChild(tool.Name) == tool then
								if now - lastClick >= CONFIG.CLICK_DELAY then lastClick = now screenClick() end
							else humanoid:EquipTool(tool) end
						end
					end
					local rp, rpart = getWallRepairPrompt()
					if rp and rpart then
						local d = (rootPart.Position - rpart.Position).Magnitude
						if d <= 8 and now - lastRepair >= CONFIG.PROMPT_PRESS_DELAY then
							lastRepair = now
							pressPrompt(rp)
						end
					end
				else moveGoal = nil moveLook = nil end
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

local UIrefs = {}

local function syncButtons()
	if UIrefs.kill then
		UIrefs.kill.Text = autoKillEnabled and "Auto Kill: ON" or "Auto Kill: OFF"
		UIrefs.kill.BackgroundColor3 = autoKillEnabled and Color3.fromRGB(40,180,60) or Color3.fromRGB(180,40,40)
	end
	if UIrefs.range then
		UIrefs.range.Text = rangeKillEnabled and "☑ Range Kill" or "☐ Range Kill"
		UIrefs.range.BackgroundColor3 = rangeKillEnabled and Color3.fromRGB(200,120,40) or Color3.fromRGB(60,60,60)
	end
	if UIrefs.legit then
		UIrefs.legit.Text = legitMoveEnabled and "☑ Legit Move" or "☐ Legit Move"
		UIrefs.legit.BackgroundColor3 = legitMoveEnabled and Color3.fromRGB(140,100,40) or Color3.fromRGB(60,60,60)
	end
	if UIrefs.heal then
		UIrefs.heal.Text = autoHealEnabled and "☑ Auto Heal" or "☐ Auto Heal"
		UIrefs.heal.BackgroundColor3 = autoHealEnabled and Color3.fromRGB(40,140,180) or Color3.fromRGB(60,60,60)
	end
	if UIrefs.upg then
		UIrefs.upg.Text = autoUpgradeEnabled and "☑ Auto Upgr." or "☐ Auto Upgr."
		UIrefs.upg.BackgroundColor3 = autoUpgradeEnabled and Color3.fromRGB(120,60,160) or Color3.fromRGB(60,60,60)
	end
	if UIrefs.farm then
		UIrefs.farm.Text = autoFarmEnabled and "Stop - Backspace" or "☐ Auto Farm"
		UIrefs.farm.BackgroundColor3 = autoFarmEnabled and Color3.fromRGB(0,160,255) or Color3.fromRGB(60,60,60)
	end
end

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
	frame.Size = UDim2.new(0, 560, 0, 70)
	frame.Position = UDim2.new(1, -570, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1,-10,0,16)
	statusLabel.Position = UDim2.new(0,5,0,48)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = statusText
	statusLabel.TextColor3 = Color3.fromRGB(180,180,180)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 11
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = frame

	task.spawn(function()
		while true do
			if statusLabel.Parent then statusLabel.Text = statusText end
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
		b.TextColor3 = Color3.new(1,1,1)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 10
		b.AutoButtonColor = false
		b.Parent = frame
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
		b.MouseButton1Click:Connect(onClick)
		UIrefs[key] = b
		return b
	end

	makeButton("kill", "KillBtn", 88, 5, "Auto Kill: OFF", Color3.fromRGB(180,40,40), function()
		autoKillEnabled = not autoKillEnabled
		syncButtons()
	end)

	makeButton("range", "RangeBtn", 88, 98, "☐ Range Kill", Color3.fromRGB(60,60,60), function()
		setRangeKill(not rangeKillEnabled)
		syncButtons()
	end)

	makeButton("legit", "LegitBtn", 84, 191, "☐ Legit Move", Color3.fromRGB(60,60,60), function()
		setLegit(not legitMoveEnabled)
		syncButtons()
	end)

	makeButton("heal", "HealBtn", 84, 280, "☐ Auto Heal", Color3.fromRGB(60,60,60), function()
		autoHealEnabled = not autoHealEnabled
		if not autoHealEnabled then retreatMode = false end
		syncButtons()
	end)

	makeButton("upg", "UpgradeBtn", 88, 369, "☐ Auto Upgr.", Color3.fromRGB(60,60,60), function()
		autoUpgradeEnabled = not autoUpgradeEnabled
		syncButtons()
	end)

	makeButton("farm", "FarmBtn", 96, 462, "☐ Auto Farm", Color3.fromRGB(60,60,60), function()
		setFarm(not autoFarmEnabled)
		syncButtons()
	end)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 24, 0, 24)
	closeBtn.Position = UDim2.new(1, -28, 0, 4)
	closeBtn.BackgroundColor3 = Color3.fromRGB(120,30,30)
	closeBtn.Text = "✖"
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 12
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = frame
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)
	closeBtn.MouseButton1Click:Connect(function()
		hBindEnabled = false
		rangeKillEnabled = false
		setFarm(false)
		if screenGui then screenGui.Enabled = false end
	end)

	syncButtons()
end

createUI()
