local Players=game:GetService("Players") local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService") local RS=game:GetService("ReplicatedStorage")
local SG=game:GetService("StarterGui") local HS=game:GetService("HttpService")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")

local SELF_MARKER="AIPilotHub_SelfSave_v1"
local SELF_FILE="AIPilotSelf.lua"
local STATE_FILE="AIPilotFarmState.txt"

local CFG={
 SRC="", PLANE="Plane", PASS="Passengers", FOOD="FoodCrate",
 A_TAKE="Take Food", A_FEED="Feed", A_TALK="Talk to Passenger", A_PICK="Pickup Delivery", A_ICE="Break Ice", A_SEAT="Seat",
 ICE_N=6, ICE_D=0.01, PASSOUT=10, ROLLMAX=30, FOODBUF=6,
 AMT={"Plane","FoodCrate","FoodCrate","Part","SurfaceGui","Frame","Amount"},
 SCAN=0.08, WMIN=0, WMAX=200, WDEF=16, FLYM=10, FLYL=0.6, FLYB=2, FEEDCD=0.132,
 PURW=0.2, DELW=0.54, PICKW=0.066, TSD=0.017, TTIME=1.5,
 MODELS={
  {name="Default (By EXVS)", url="https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/AIPilotModel.json"},
  {name="Smooth (BETA By Rzeinil)", url="https://raw.githubusercontent.com/expure/multitoolroblox/refs/heads/main/AIModelPilot-by-Rzeinil.json"},
 },
 MODFILE="AIPilotModel.json", HOLD=7500, LANDDIST=50, TD=5, FLARE=2.5, KNN=7,
 HDZ=15, LDZ=12, KREF=3, ROLL=1, YAW=1, ATC=2,
 KEYS={W=Enum.KeyCode.W,A=Enum.KeyCode.A,S=Enum.KeyCode.S,D=Enum.KeyCode.D},
 BEAM="PassengerESPBeam", TATT="PassengerESP_TorsoAttachment", RATT="PassengerESP_RootAttachment",
 ROOTP={humanoidrootpart=true,rootpart=true,root=true,torso=true},
}

local S={
 esp=false, fly=false, feed=false, feedTok=0,
 walk=16, restart=false, farm=false,
 ai=false, model=nil, curModel=1, landing=false, distT=0, yaw=nil,
 aip={W=false,A=false,S=false,D=false}, aih={W=0,A=0,S=0,D=0},
 aAlt=nil, aAltT=0, aVS=0, aLandT=0, sAGL=1, sI=1, aM=nil, aMT=0, aMPS=0.3,
 atc=false, atcTok=0,
 active={}, tAtt=nil, tCur=nil, flyConn=nil,
}

local function saveFarm(st) pcall(function() if type(writefile)=="function" then writefile(STATE_FILE, st and "1" or "0") end end) end
local function loadFarm()
	local on=false
	pcall(function()
		if type(readfile)=="function" and type(isfile)=="function" and isfile(STATE_FILE) then on = readfile(STATE_FILE)=="1" end
	end)
	return on
end

local function findOwnSource()
	local out=nil
	if CFG.SRC and CFG.SRC~="" then
		pcall(function() local r=game:HttpGet(CFG.SRC); if type(r)=="string" and r~="" then out=r end end)
	end
	if not out and type(readfile)=="function" and type(isfile)=="function" and isfile(SELF_FILE) then
		pcall(function() local s=readfile(SELF_FILE); if type(s)=="string" and s:find(SELF_MARKER,1,true) then out=s end end)
	end
	if not out and type(listfiles)=="function" and type(readfile)=="function" then
		pcall(function()
			local dirs={"tabs",""}
			for _,d in ipairs(dirs) do
				local ok,files=pcall(function() return listfiles(d) end)
				if ok and type(files)=="table" then
					for _,f in ipairs(files) do
						if not out and type(f)=="string" and (f:find(".luau",1,true) or f:find(".lua",1,true) or f:find(".txt",1,true)) then
							local ok2,s=pcall(function() return readfile(f) end)
							if ok2 and type(s)=="string" and #s<500000 and s:find(SELF_MARKER,1,true) then out=s end
						end
					end
				end
				if out then break end
			end
		end)
	end
	return out
end

task.spawn(function()
	local src=findOwnSource()
	if src and type(writefile)=="function" then
		pcall(function() writefile(SELF_FILE, src) end)
		print("[Hub] code saved to "..SELF_FILE)
	end
end)

local U={}
local VIM=nil; pcall(function() VIM=game:GetService("VirtualInputManager") end)
local function rnd(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=o end

local function getRoot(character)
	character=character or player.Character
	if not character then return nil end
	return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end
local function getTorso(character)
	if not character then return nil end
	return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
end
local function getRootPart(m)
	if not m or not m:IsA("Model") then return nil end
	local h=m:FindFirstChild("HumanoidRootPart"); if h and h:IsA("BasePart") then return h end
	for _,c in ipairs(m:GetChildren()) do if c:IsA("BasePart") and CFG.ROOTP[c.Name:lower()] then return c end end
	if m.PrimaryPart and m.PrimaryPart:IsA("BasePart") then return m.PrimaryPart end
	return m:FindFirstChildWhichIsA("BasePart")
end
local function getPos(i)
	if not i then return nil end
	if i:IsA("BasePart") then return i.Position end
	local r=getRootPart(i); return r and r.Position
end
local function teleport(part,off)
	local root=getRoot(player.Character); local p=getPos(part)
	if not root or not p then return false end
	off=off or Vector3.new(0,3,0); local t=p+off
	local start=root.CFrame; local goal=CFrame.new(t)
	local dur=0.35; local st=tick()
	while tick()-st<dur do
		local a=(tick()-st)/dur
		root.CFrame=start:Lerp(goal,a)
		task.wait()
	end
	root.CFrame=goal; task.wait(0.03); return true
end

do
	local o=playerGui:FindFirstChild("PassengerESPGui"); if o then o:Destroy() end
	local o2=playerGui:FindFirstChild("FarmOverlay"); if o2 then o2:Destroy() end

	U.gui=Instance.new("ScreenGui"); U.gui.Name="PassengerESPGui"; U.gui.ResetOnSpawn=false; U.gui.DisplayOrder=10; U.gui.Parent=playerGui
	U.main=Instance.new("Frame"); U.main.Size=UDim2.new(0,320,0,0); U.main.AutomaticSize=Enum.AutomaticSize.Y
	U.main.Position=UDim2.new(0,24,0,24); U.main.BackgroundColor3=Color3.fromRGB(24,24,30); U.main.Parent=U.gui; rnd(U.main,10)
	local pad=Instance.new("UIPadding"); pad.PaddingTop=UDim.new(0,10); pad.PaddingBottom=UDim.new(0,10); pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10); pad.Parent=U.main
	local lay=Instance.new("UIListLayout"); lay.Padding=UDim.new(0,8); lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Parent=U.main
	U.titleBar=Instance.new("Frame"); U.titleBar.LayoutOrder=0; U.titleBar.Size=UDim2.new(1,0,0,28); U.titleBar.BackgroundColor3=Color3.fromRGB(35,35,48); U.titleBar.Active=true; U.titleBar.Parent=U.main; rnd(U.titleBar,8)
	local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,-16,1,0); tl.Position=UDim2.new(0,8,0,0); tl.BackgroundTransparency=1; tl.Text="ESP / Feed / AI Pilot"; tl.TextColor3=Color3.fromRGB(245,245,245); tl.TextSize=14; tl.Font=Enum.Font.GothamBold; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Parent=U.titleBar
	U.close=Instance.new("TextButton"); U.close.Size=UDim2.new(0,22,0,22); U.close.Position=UDim2.new(1,-26,0,3); U.close.BackgroundColor3=Color3.fromRGB(180,50,50); U.close.Text="X"; U.close.TextColor3=Color3.fromRGB(255,255,255); U.close.Font=Enum.Font.GothamBold; U.close.TextSize=14; U.close.Parent=U.titleBar; rnd(U.close,4)
	U.walkLabel=Instance.new("TextLabel"); U.walkLabel.LayoutOrder=1; U.walkLabel.Size=UDim2.new(1,0,0,18); U.walkLabel.BackgroundTransparency=1; U.walkLabel.Text="WalkSpeed: 16"; U.walkLabel.TextColor3=Color3.fromRGB(225,225,235); U.walkLabel.TextSize=14; U.walkLabel.Font=Enum.Font.GothamMedium; U.walkLabel.TextXAlignment=Enum.TextXAlignment.Left; U.walkLabel.Parent=U.main
	U.sliderFrame=Instance.new("Frame"); U.sliderFrame.LayoutOrder=2; U.sliderFrame.Size=UDim2.new(1,0,0,18); U.sliderFrame.BackgroundColor3=Color3.fromRGB(55,55,70); U.sliderFrame.Active=true; U.sliderFrame.Parent=U.main; rnd(U.sliderFrame,6)
	U.sliderFill=Instance.new("Frame"); U.sliderFill.Size=UDim2.new(0,0,1,0); U.sliderFill.BackgroundColor3=Color3.fromRGB(70,160,255); U.sliderFill.Parent=U.sliderFrame; rnd(U.sliderFill,6)
	U.sliderKnob=Instance.new("Frame"); U.sliderKnob.AnchorPoint=Vector2.new(0.5,0.5); U.sliderKnob.Size=UDim2.new(0,14,0,14); U.sliderKnob.Position=UDim2.new(0,0,0.5,0); U.sliderKnob.BackgroundColor3=Color3.fromRGB(235,235,235); U.sliderKnob.Parent=U.sliderFrame; rnd(U.sliderKnob,7)
	local function mk(order,text,color)
		local b=Instance.new("TextButton"); b.LayoutOrder=order; b.Size=UDim2.new(1,0,0,34); b.BackgroundColor3=color
		b.Text=text; b.TextColor3=Color3.fromRGB(255,255,255); b.TextSize=14; b.Font=Enum.Font.GothamMedium; b.AutoButtonColor=true; b.Parent=U.main; rnd(b,8)
		return b
	end
	U.fly=mk(3,"Fly: OFF",Color3.fromRGB(130,40,40))
	U.esp=mk(4,"Passenger ESP: OFF",Color3.fromRGB(130,40,40))
	U.feed=mk(5,"Auto Passenger Feed: START",Color3.fromRGB(45,80,160))
	U.ai=mk(6,"AI PILOT: OFF",Color3.fromRGB(60,120,80))
	U.model=mk(7,"Model: "..CFG.MODELS[S.curModel].name,Color3.fromRGB(80,80,160))
	U.farm=mk(8,"AUTO FARM: OFF",Color3.fromRGB(160,120,40))
	U.atc=mk(9,"AUTO ATC: OFF",Color3.fromRGB(110,80,140))
	U.restart=mk(10,"RESTART AFTER LAND: OFF",Color3.fromRGB(110,80,140))
	U.status=Instance.new("TextLabel"); U.status.LayoutOrder=11; U.status.Size=UDim2.new(1,0,0,0); U.status.AutomaticSize=Enum.AutomaticSize.Y; U.status.BackgroundTransparency=1; U.status.Text="Status: Idle"; U.status.TextColor3=Color3.fromRGB(200,200,210); U.status.TextSize=12; U.status.Font=Enum.Font.Gotham; U.status.TextWrapped=true; U.status.TextXAlignment=Enum.TextXAlignment.Left; U.status.TextYAlignment=Enum.TextYAlignment.Top; U.status.Parent=U.main

	U.farmGui=Instance.new("ScreenGui"); U.farmGui.Name="FarmOverlay"; U.farmGui.ResetOnSpawn=false; U.farmGui.DisplayOrder=20; U.farmGui.Enabled=false; U.farmGui.Parent=playerGui
	U.farmBox=Instance.new("TextButton"); U.farmBox.AnchorPoint=Vector2.new(0.5,0.5); U.farmBox.Position=UDim2.new(0.5,0,0.5,0)
	U.farmBox.Size=UDim2.new(0.1,0,0.1,0); U.farmBox.BackgroundColor3=Color3.fromRGB(15,35,20); U.farmBox.AutoButtonColor=false; U.farmBox.Text=""; U.farmBox.Parent=U.farmGui; rnd(U.farmBox,10)
	local fl=Instance.new("TextLabel"); fl.Size=UDim2.new(1,0,0.45,0); fl.Position=UDim2.new(0,0,0.08,0); fl.BackgroundTransparency=1
	fl.Text="Auto Farm Active!"; fl.TextColor3=Color3.fromRGB(140,255,170); fl.TextScaled=true; fl.Font=Enum.Font.GothamBold; fl.Parent=U.farmBox
	local bl=Instance.new("TextLabel"); bl.Size=UDim2.new(1,0,0.5,0); bl.Position=UDim2.new(0,0,0.5,0); bl.BackgroundTransparency=1
	bl.Text="By EXVS"; bl.TextColor3=Color3.fromRGB(255,255,255); bl.TextScaled=true; bl.Font=Enum.Font.GothamBlack; bl.Parent=U.farmBox
end

local function setStatus(t) U.status.Text="Status: "..tostring(t) print("[Hub]",t) end
local function updWalk() local r=(S.walk-CFG.WMIN)/(CFG.WMAX-CFG.WMIN); U.sliderFill.Size=UDim2.fromScale(r,1); U.sliderKnob.Position=UDim2.fromScale(r,0.5); U.walkLabel.Text="WalkSpeed: "..S.walk end
local function applyWalk() local c=player.Character; local h=c and c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=S.walk end end
local function setWalk(v) S.walk=math.clamp(math.floor(v+0.5),CFG.WMIN,CFG.WMAX); updWalk(); applyWalk() end
local function updFly() U.fly.Text=S.fly and "Fly: ON" or "Fly: OFF"; U.fly.BackgroundColor3=S.fly and Color3.fromRGB(45,135,75) or Color3.fromRGB(130,40,40) end
local function updESP() U.esp.Text=S.esp and "Passenger ESP: ON" or "Passenger ESP: OFF"; U.esp.BackgroundColor3=S.esp and Color3.fromRGB(45,135,75) or Color3.fromRGB(130,40,40) end
local function updFeed() U.feed.Text=S.feed and "Auto Passenger Feed: STOP" or "Auto Passenger Feed: START"; U.feed.BackgroundColor3=S.feed and Color3.fromRGB(170,110,30) or Color3.fromRGB(45,80,160) end
local function updAI() U.ai.Text=S.ai and "AI PILOT: ON" or "AI PILOT: OFF"; U.ai.BackgroundColor3=S.ai and Color3.fromRGB(40,160,90) or Color3.fromRGB(60,120,80) end
local function updModel() U.model.Text="Model: "..CFG.MODELS[S.curModel].name end
local function updFarm() U.farm.Text=S.farm and "AUTO FARM: ON" or "AUTO FARM: OFF"; U.farm.BackgroundColor3=S.farm and Color3.fromRGB(60,180,120) or Color3.fromRGB(160,120,40) end
local function updATC() U.atc.Text=S.atc and "AUTO ATC: ON" or "AUTO ATC: OFF"; U.atc.BackgroundColor3=S.atc and Color3.fromRGB(60,180,120) or Color3.fromRGB(110,80,140) end
local function updRestart() U.restart.Text=S.restart and "RESTART AFTER LAND: ON" or "RESTART AFTER LAND: OFF"; U.restart.BackgroundColor3=S.restart and Color3.fromRGB(60,180,120) or Color3.fromRGB(110,80,140) end

local function setFarm(st)
	if st==S.farm then return end
	S.farm=st
	saveFarm(st)
	updFarm()
	if st then S.atc=true; updATC() end
	U.gui.Enabled = not st
	U.farmGui.Enabled = st
	setStatus(st and "Auto Farm: ON (+ATC)" or "Auto Farm: OFF")
end

RunService.RenderStepped:Connect(function()
	if S.walk~=CFG.WDEF then
		local c=player.Character; if not c then return end
		local h=c:FindFirstChildOfClass("Humanoid")
		if h and h.WalkSpeed~=S.walk then h.WalkSpeed=S.walk end
	end
end)

do
	local d={s=false,m=false,st=nil,mp=nil}
	U.sliderFrame.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d.s=true; local a=U.sliderFrame.AbsolutePosition; local w=U.sliderFrame.AbsoluteSize; setWalk(CFG.WMIN+(CFG.WMAX-CFG.WMIN)*math.clamp((i.Position.X-a.X)/math.max(w.X,1),0,1)) end end)
	U.titleBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d.m=true; d.st=i.Position; d.mp=U.main.Position end end)
	UIS.InputChanged:Connect(function(i)
		if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
		if d.s then local a=U.sliderFrame.AbsolutePosition; local w=U.sliderFrame.AbsoluteSize; setWalk(CFG.WMIN+(CFG.WMAX-CFG.WMIN)*math.clamp((i.Position.X-a.X)/math.max(w.X,1),0,1)) end
		if d.m and d.st and d.mp then local dl=i.Position-d.st; U.main.Position=UDim2.new(d.mp.X.Scale,d.mp.X.Offset+dl.X,d.mp.Y.Scale,d.mp.Y.Offset+dl.Y) end
	end)
	UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d.s=false; d.m=false end end)
end

local function camLock(part)
	local cam=workspace.CurrentCamera; if not cam then return function() end end
	local old=cam.CameraType; if old==Enum.CameraType.Scriptable then old=Enum.CameraType.Custom end
	cam.CameraType=Enum.CameraType.Scriptable
	local sz=part:IsA("BasePart") and part.Size or Vector3.new(4,4,4)
	local off=Vector3.new(0,math.max(sz.Y*0.5+2,4),math.max(sz.Z*0.5+5,8))
	local cn=RunService.RenderStepped:Connect(function() if part and part.Parent then cam.CFrame=CFrame.new(part.Position+off,part.Position) end end)
	return function() cn:Disconnect(); cam.CameraType=old end
end

local function setFly(st)
	if st==S.fly then return end
	S.fly=st
	if S.fly then
		local root=getRoot(player.Character); local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not root then S.fly=false; updFly(); return end
		if hum then hum.PlatformStand=true end
		if S.flyConn then S.flyConn:Disconnect() end
		S.flyConn=RunService.RenderStepped:Connect(function(dt)
			if not S.fly then return end
			if UIS:GetFocusedTextBox() then return end
			local root=getRoot(player.Character)
			if not root or not root.Parent then S.fly=false; if S.flyConn then S.flyConn:Disconnect() S.flyConn=nil end; updFly(); return end
			if S.feed then return end
			local cam=workspace.CurrentCamera
			local f=cam.CFrame.LookVector; local r=cam.CFrame.RightVector; local up=Vector3.new(0,1,0)
			local mv=Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W) then mv=mv+f end
			if UIS:IsKeyDown(Enum.KeyCode.S) then mv=mv-f end
			if UIS:IsKeyDown(Enum.KeyCode.D) then mv=mv+r end
			if UIS:IsKeyDown(Enum.KeyCode.A) then mv=mv-r end
			if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then mv=mv+up end
			if UIS:IsKeyDown(Enum.KeyCode.Q) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv=mv-up end
			if mv.Magnitude>0 then mv=mv.Unit end
			local sp=math.max(S.walk*CFG.FLYM,80)
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then sp=sp*CFG.FLYB end
			root.CFrame=root.CFrame:Lerp(CFrame.new(root.CFrame.Position+mv*sp*dt)*cam.CFrame.Rotation,CFG.FLYL)
			root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
		end)
	else
		if S.flyConn then S.flyConn:Disconnect(); S.flyConn=nil end
		local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand=false end
	end
	updFly()
end

local function ensureTAtt()
	local c=player.Character; if not c then return nil end
	local t=getTorso(c); if not t or not t:IsA("BasePart") then return nil end
	if S.tCur~=t or not S.tAtt or not S.tAtt.Parent then
		if S.tAtt then S.tAtt:Destroy() end
		S.tCur=t; S.tAtt=Instance.new("Attachment"); S.tAtt.Name=CFG.TATT; S.tAtt.Parent=t
	end
	return S.tAtt
end
local function rmEntry(m) local d=S.active[m]; if not d then return end; if d.beam then d.beam:Destroy() end; if d.ra then d.ra:Destroy() end; S.active[m]=nil end
local function clearAll() for m in pairs(S.active) do rmEntry(m) end; if S.tAtt then S.tAtt:Destroy(); S.tAtt=nil end; S.tCur=nil end
local function addBeam(m,a0)
	if S.active[m] then return true end
	local r=getRootPart(m); if not r then return false end
	a0=a0 or ensureTAtt(); if not a0 then return false end
	local ra=Instance.new("Attachment"); ra.Name=CFG.RATT; ra.Parent=r
	local b=Instance.new("Beam"); b.Name=CFG.BEAM; b.Attachment0=a0; b.Attachment1=ra
	b.Color=ColorSequence.new(Color3.fromRGB(255,70,70)); b.Transparency=NumberSequence.new(0.1); b.Width0=0.35; b.Width1=0.35; b.FaceCamera=true; b.LightEmission=1; b.Parent=r
	S.active[m]={beam=b,ra=ra}; return true
end
local function collectModels(c,res)
	for _,o in ipairs(c:GetChildren()) do
		if o:IsA("Model") then table.insert(res,o) elseif o:IsA("Folder") then collectModels(o,res) end
	end
end
local function scan()
	local a0=ensureTAtt(); if not a0 then clearAll() return end
	local plane=workspace:FindFirstChild(CFG.PLANE); local ps=plane and plane:FindFirstChild(CFG.PASS)
	local found={}
	if ps then
		local list={}; collectModels(ps,list)
		for _,m in ipairs(list) do found[m]=true; rmEntry(m); addBeam(m,a0) end
	end
	for m in pairs(S.active) do if not found[m] then rmEntry(m) end end
end
local espTok=0
local function setESP(st)
	if st==S.esp then return end
	S.esp=st
	if S.esp then espTok+=1; local t=espTok; task.spawn(function() while S.esp and espTok==t do pcall(scan); task.wait(CFG.SCAN) end end)
	else espTok+=1; clearAll() end
	updESP()
end

local ttR, shR
local function getTT() if ttR and ttR.Parent then return ttR end; local r=RS:FindFirstChild("Remotes"); ttR=r and r:FindFirstChild("TooltipAction"); return ttR end
local function getSH() if shR and shR.Parent then return shR end; local r=RS:FindFirstChild("Remotes"); shR=r and r:FindFirstChild("TabletShopPurchase"); return shR end
local function fireTT(a,arg) local r=getTT(); if not r then return false end; return pcall(function() r:FireServer(a,arg) end) end
local function fireSH(i,c) local r=getSH(); if not r then return false end; return pcall(function() r:FireServer(i,c) end) end

local function parseAmt(t) if typeof(t)~="string" then return nil end; local n=tonumber(t); if n then return n end; local m={t:match("(%d+)")}; return m[1] and tonumber(m[1]) end
local function foodAmt()
	local cur=workspace
	for _,n in ipairs(CFG.AMT) do if not cur then cur=nil break end; cur=cur:FindFirstChild(n) end
	if cur then local ok,t=pcall(function() return cur.Text end); if ok then local n=parseAmt(t); if n then return n end end end
	local p=workspace:FindFirstChild(CFG.PLANE); local c=p and p:FindFirstChild(CFG.FOOD)
	if c then local a=c:FindFirstChild("Amount",true); if a then local ok,t=pcall(function() return a.Text end); if ok then return parseAmt(t) end end end
	return nil
end
local function foodTargets()
	local p=workspace:FindFirstChild(CFG.PLANE); local c=p and p:FindFirstChild(CFG.FOOD)
	local t={}
	if not c then return t end
	local function col(x) for _,ch in ipairs(x:GetChildren()) do if ch:IsA("Model") or ch:IsA("BasePart") then table.insert(t,ch) elseif ch:IsA("Folder") then col(ch) end end end
	col(c); return t
end
local function partOf(x) if x:IsA("BasePart") then return x end; return getRootPart(x) end
local function findAllCrates()
	local t={}
	for _,c in ipairs(workspace:GetChildren()) do
		if c.Name:match("^DeliveryCrate_%d+$") then table.insert(t,c) end
	end
	return t
end
local function findCrate()
	local best=nil; local bd=math.huge; local root=getRoot(player.Character)
	for _,c in ipairs(findAllCrates()) do
		local p=c:IsA("BasePart") and c or getRootPart(c)
		if p then local d=root and (root.Position-p.Position).Magnitude or 0; if d<bd then bd=d; best=c end end
	end
	return best
end
local function cratePart(c) if c:IsA("BasePart") then return c end; return getRootPart(c) end
local function collectCrates(tok)
	local list=findAllCrates()
	if #list==0 then return false end
	for _,c in ipairs(list) do
		if tok and (not S.feed or S.feedTok~=tok) then return true end
		local cp=cratePart(c); if cp then
			teleport(cp,Vector3.new(0,3,0)); task.wait(0.034)
			local un=camLock(cp)
			fireTT(CFG.A_PICK,c); task.wait(CFG.PICKW); un()
		end
	end
	return true
end

local function prio(t)
	if typeof(t)~="string" then return nil end
	t=t:lower()
	if t:find("stressed",1,true) then return 4 end
	if t:find("panicked",1,true) then return 3 end
	if t:find("anxious",1,true) then return 2 end
	if t:find("cooked",1,true) then return -1 end
	if t:find("relaxed",1,true) then return 0 end
	return nil
end
local function pState(m)
	local r=m:FindFirstChild("HumanoidRootPart") or getRootPart(m); if not r then return nil,nil end
	local h=r:FindFirstChild("Health",true); if not h then return nil,r end
	local tr=h:FindFirstChild("TopRow",true); if not tr then return nil,r end
	local nl=tr:FindFirstChild("NameLabel",true); if not nl then return nil,r end
	local ok,t=pcall(function() return nl.Text end); if not ok then return nil,r end
	return prio(t),r
end
local function worstPriority()
	local p=workspace:FindFirstChild(CFG.PLANE); local ps=p and p:FindFirstChild(CFG.PASS); if not ps then return 0,nil end
	local list={}; collectModels(ps,list)
	local bp=0; local bm=nil
	for _,m in ipairs(list) do
		local pr,rt=pState(m)
		if pr and pr>0 and rt and pr>bp then bp=pr; bm=m end
	end
	return bp,bm
end
local function invSet()
	local s={}
	local bp=player:FindFirstChildOfClass("Backpack") or player:FindFirstChild("Backpack")
	if bp then for _,c in ipairs(bp:GetChildren()) do if c:IsA("Tool") then s[c]=true end end end
	local ch=player.Character
	if ch then for _,c in ipairs(ch:GetChildren()) do if c:IsA("Tool") then s[c]=true end end end
	return s
end
local function newTool(old)
	local bp=player:FindFirstChildOfClass("Backpack") or player:FindFirstChild("Backpack")
	if bp then for _,c in ipairs(bp:GetChildren()) do if c:IsA("Tool") and not old[c] then return c end end end
	local ch=player.Character
	if ch then for _,c in ipairs(ch:GetChildren()) do if c:IsA("Tool") and not old[c] then return c end end end
	return nil
end
local function hasTool()
	local ch=player.Character; if not ch then return false end
	for _,c in ipairs(ch:GetChildren()) do if c:IsA("Tool") then return true end end
	return false
end

local function restock(tok)
	local before=foodAmt() or 0
	if not fireSH("sandwich","miles") then task.wait(0.132) return false end
	task.wait(CFG.PURW)
	local crate=nil; local st=tick()
	while tick()-st<CFG.DELW do
		if not S.feed or S.feedTok~=tok then return false end
		crate=findCrate(); if crate then break end
		task.wait(0.02)
	end
	if not crate then task.wait(0.066) return false end
	local cp=cratePart(crate); if not cp then return false end
	teleport(cp,Vector3.new(0,3,0)); task.wait(0.034)
	local un=camLock(cp)
	fireTT(CFG.A_PICK,crate); task.wait(CFG.PICKW); un()
	for _=1,25 do
		if not S.feed or S.feedTok~=tok then return false end
		local now=foodAmt(); if now and now>before then return true end
		if not crate.Parent then return true end
		task.wait(0.02)
	end
	return false
end
local function takeFood(tok)
	local t=foodTargets(); if #t==0 then return false end
	local target=t[math.random(1,#t)]; local tp=partOf(target); if not tp then return false end
	teleport(tp,Vector3.new(0,3,0)); task.wait(0.034)
	local un=camLock(tp); local old=invSet()
	fireTT(CFG.A_TAKE,target); un()
	local nt=nil
	for _=1,25 do
		if not S.feed or S.feedTok~=tok then return false end
		nt=newTool(old); if nt then break end
		task.wait(0.02)
	end
	if nt then
		local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h then pcall(function() h:EquipTool(nt) end) end
		task.wait(0.02); return true
	end
	return false
end
local function ensureFood(tok)
	local fa=foodAmt()
	local low=(fa==nil) or (fa<=CFG.FOODBUF)
	if low then
		if not collectCrates(tok) then
			restock(tok)
		end
	end
	if hasTool() then return true end
	return takeFood(tok)
end
local function feedOne(pm,tok)
	local pr=pm:FindFirstChild("HumanoidRootPart") or getRootPart(pm); if not pr then return false end
	teleport(pr,Vector3.new(0,1,2)); task.wait(0.034)
	for _=1,CFG.ICE_N do fireTT(CFG.A_ICE,pm); task.wait(CFG.ICE_D) end
	local un=camLock(pr)
	for _=1,3 do
		fireTT(CFG.A_FEED,pm); fireTT(CFG.A_FEED,pr); task.wait(0.05)
	end
	fireTT(CFG.A_TALK,pm); fireTT(CFG.A_TALK,pr)
	un()
	task.wait(CFG.FEEDCD)
	return true
end
local function feedLoop(tok)
	if S.fly then setFly(false) end
	while S.feed and S.feedTok==tok do
		if not getRoot(player.Character) then task.wait(0.066) continue end
		local _,pm=worstPriority()
		if not pm then task.wait(0.334) continue end
		if not hasTool() then
			local fa=foodAmt()
			if fa~=nil and fa<=0 then if not restock(tok) then continue end end
			if not takeFood(tok) then if fa==nil then if restock(tok) then takeFood(tok) end end end
			if not hasTool() then task.wait(0.066) continue end
		end
		feedOne(pm,tok)
	end
	updFeed()
end

local function getPilotSeat()
	local p=workspace:FindFirstChild(CFG.PLANE); if not p then return nil end
	local seats=p:FindFirstChild("Seats"); if not seats then return nil end
	local ps=seats:FindFirstChild("PilotSeat"); if not ps then return nil end
	return ps:FindFirstChild("Seat")
end
local function sitInSeat(seat)
	if not seat then return end
	teleport(seat,Vector3.new(0,2,0)); task.wait(0.034)
	local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then pcall(function() seat:Sit(h) end) end
	fireTT(CFG.A_SEAT,seat)
end

local function planeTorso()
	local c=player.Character; if not c then return nil end
	return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("HumanoidRootPart")
end
local function getAlt()
	local a=workspace:FindFirstChild("ClientAltitude"); if a==nil then return 0 end
	if typeof(a)=="number" then return a end
	if typeof(a)=="Instance" then
		if a:IsA("NumberValue") or a:IsA("IntValue") then return a.Value end
		local v=a:GetAttribute("Value"); if typeof(v)=="number" then return v end
	end
	return 0
end
local function getMiles()
	local ok,v=pcall(function()
		local pg=player:FindFirstChild("PlayerGui"); local d=pg and pg:FindFirstChild("Distance")
		local c=d and d:FindFirstChild("Container"); local l=c and c:FindFirstChild("DistanceLabel")
		if not l then return nil end
		return tonumber(l.Text:match("(%d+%.?%d*)"))
	end)
	return ok and v or nil
end
local function angDiff(a,b) local d=(a-b)%360; if d>180 then d=d-360 end; return d end
local function aiKey(n,d) if S.aip[n]==d then return end; S.aip[n]=d; S.aih[n]=0; if VIM then pcall(function() VIM:SendKeyEvent(d,CFG.KEYS[n],false,game) end) end end
local function aiRelease() for k in pairs(S.aip) do aiKey(k,false) end end
local function aiRefresh(dt)
	for n in pairs(S.aih) do
		if S.aip[n] then
			S.aih[n]=S.aih[n]+dt
			if S.aih[n]>CFG.KREF then
				S.aip[n]=false; S.aih[n]=0
				if VIM then pcall(function() VIM:SendKeyEvent(false,CFG.KEYS[n],false,game) end) end
				task.delay(0.05,function() S.aip[n]=true; if VIM then pcall(function() VIM:SendKeyEvent(true,CFG.KEYS[n],false,game) end) end end)
			end
		else S.aih[n]=0 end
	end
end
local function glide(m)
	local I=0; local prev=0
	local pts={{1,0.4},{2.5,3},{5,10},{7,32},{12,55},{22,120},{34,240},{math.huge,320}}
	for _,p in ipairs(pts) do
		local up=math.min(m,p[1])
		if up>prev then I=I+(up-prev)*p[2]; prev=up end
		if m<=p[1] then break end
	end
	return I
end
local function loadModel()
	local md=CFG.MODELS[S.curModel]; local json=nil
	if md.url~="" then local ok,r=pcall(function() return game:HttpGet(md.url) end); if ok and type(r)=="string" then json=r end end
	if not json then return false,"model not found" end
	local ok,m=pcall(function() return HS:JSONDecode(json) end)
	if not ok or not m or not m.frames then return false,"broken model" end
	S.model=m; return true,#m.frames
end
local function desVS(alt)
	local step=math.max(S.model.scales.alt/40,1)
	local b=math.floor(alt/step)+1; b=math.min(math.max(b,1),41)
	return S.model.profile[b]
end
local function sitting()
	local c=player.Character; if not c then return false end
	local h=c:FindFirstChildOfClass("Humanoid"); if not h or not h.Sit then return false end
	local sp=h.SeatPart; if not sp then return false end
	local p=workspace:FindFirstChild(CFG.PLANE); if not p then return false end
	local x=sp.Parent
	while x do if x==p then return true end; x=x.Parent end
	return false
end
local function startLand()
	local p=workspace:FindFirstChild(CFG.PLANE); local ck=p and p:FindFirstChild("Cockpit")
	local g=ck and ck:FindFirstChild("LandingGear")
	if g then fireTT("Landing Gear",g) end
	S.landing=true
	local m=getMiles() or CFG.LANDDIST
	S.sAGL=math.max(getAlt()-S.model.scales.ground,1)
	S.sI=math.max(glide(m)-glide(CFG.TD),1)
end
local function holdCtl(t,alt)
	local k={W=false,A=false,S=false,D=false}
	local pitch=t.Orientation.X; local roll=t.Orientation.Z; local err=alt-CFG.HOLD

	if math.abs(roll)>60 then local s=(roll>0 and 1 or -1)*CFG.ROLL; if s>0 then k.D=true else k.A=true end; return k end

	local dv=0
	if err<-2000 then dv=60
	elseif err<-500 then dv=40
	elseif err<-100 then dv=20
	elseif err>3000 then dv=-160
	elseif err>500 then dv=-80
	elseif err>100 then dv=-30 end

	if pitch>15 and dv>0 then dv=0 end

	if S.aVS<dv-CFG.HDZ then k.W=true
	elseif S.aVS>dv+CFG.HDZ then k.S=true end

	if pitch>25 then k.W=false; k.S=true end

	local st=0
	if math.abs(roll)>5 then st=(roll>0 and 1 or -1)*CFG.ROLL
	else local ye=angDiff(t.Orientation.Y,S.yaw or t.Orientation.Y); if math.abs(ye)>12 then st=(ye>0 and 1 or -1)*CFG.YAW end end
	if st>0 then k.D=true elseif st<0 then k.A=true end

	return k
end
local function landCtl(t,alt)
	local st={alt=alt-S.model.scales.ground,pitch=t.Orientation.X,roll=t.Orientation.Z,vs=S.aVS}
	local k={W=false,A=false,S=false,D=false}
	if math.abs(st.roll)>60 then local s=(st.roll>0 and 1 or -1)*CFG.ROLL; if s>0 then k.D=true else k.A=true end; return k end
	local m=getMiles(); local dv
	if m then
		local rem=math.max(m-CFG.TD,0.5)
		local mps=(S.aMPS>0.01) and S.aMPS or 0.3
		dv=math.clamp(-(st.alt/rem)*mps,-500,60)
		if st.alt>30 then dv=math.max(dv,-math.max(st.alt*0.6,2)) end
	else
		dv=desVS(st.alt) or -40
	end
	if st.alt<=30 then dv=math.clamp(dv,-20,-6) end
	local dz=math.clamp(st.alt*0.1,3,CFG.LDZ)
	if S.aVS>dv+dz then k.S=true; k.W=false elseif S.aVS<dv-dz then k.W=true; k.S=false end
	return k
end
local function setAI(st)
	if st==S.ai then return end
	S.ai=st
	if not S.ai then S.landing=false; aiRelease() end
	updAI()
end

task.spawn(function()
	local ok,n=loadModel()
	if not ok then setStatus(n) return end
	setStatus("Model: "..CFG.MODELS[S.curModel].name.." ("..n..")")
	while U.gui and U.gui.Parent do
		if S.ai then
			if not sitting() then setStatus("left the seat"); setAI(false)
			else
				local t=planeTorso(); local alt=getAlt(); local now=tick()
				if not t then setAI(false)
				else
					if S.aAlt and now>S.aAltT then S.aVS=S.aVS*0.7+((alt-S.aAlt)/(now-S.aAltT))*0.3 end
					S.aAlt=alt; S.aAltT=now
					local m=getMiles()
					if m and S.aM and now>S.aMT then local i=(S.aM-m)/(now-S.aMT); if i>0 then S.aMPS=S.aMPS*0.7+i*0.3 end end
					S.aM=m; S.aMT=now
					if not S.landing then
						S.distT=S.distT+0.05
						if S.distT>=0.2 then S.distT=0; if m and m<CFG.LANDDIST then startLand() end end
					end
					local k=S.landing and landCtl(t,alt) or holdCtl(t,alt)
					for kk,v in pairs(k) do aiKey(kk,v) end
					aiRefresh(0.05)
					if S.landing and (alt-S.model.scales.ground)<5 and math.abs(S.aVS)<10 then
						S.aLandT=S.aLandT+0.05
						if S.aLandT>2 then
							setStatus("Landing complete"); setAI(false); S.aLandT=0
							if S.restart then
								task.spawn(function()
									task.wait(1)
									pcall(function() player:Respawn() end)
								end)
							end
						end
					else S.aLandT=0 end
					if not S.landing and math.abs(t.Orientation.Z)<10 and math.abs(t.Orientation.X)<30 then S.yaw=t.Orientation.Y end
				end
			end
		end
		task.wait(0.05)
	end
end)

local function farmFeedAll(onlyOne)
	local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then pcall(function() h.Sit=false end) end
	local tok=S.feedTok+1; S.feedTok=tok; S.feed=true

	collectCrates(tok)

	if onlyOne then
		local pr,pm=worstPriority()
		if pm and pr>0 then
			ensureFood(tok)
			feedOne(pm,tok)
		end
	else
		local guard=0
		while S.farm and guard<60 do
			guard+=1
			local pr,pm=worstPriority()
			if not pm or pr<=0 then break end
			if not ensureFood(tok) then break end
			feedOne(pm,tok)
		end
	end

	S.feed=false; updFeed()
	sitInSeat(getPilotSeat())
end

task.spawn(function()
	while true do
		if S.farm then
			if S.model and not S.ai then setAI(true) end
			local miles=getMiles()
			local pr,_=worstPriority()
			local t=planeTorso()
			local roll=t and t.Orientation.Z or 0
			local tooRoll=math.abs(roll)>CFG.ROLLMAX

			local doFeed=false
			if pr>=4 then
				doFeed = (miles~=nil and miles>5)
			elseif pr>=3 then
				doFeed = (not S.landing) and (not tooRoll) and (miles~=nil and miles>15)
			end

			if doFeed then
				local onlyOne = S.landing or tooRoll
				setStatus(string.format("Farm: getting up to feed (prio %d, mi %s, roll %.0f)%s", pr, miles and string.format("%.1f",miles) or "?", roll, onlyOne and " [stressed only]" or ""))
				setAI(false)
				farmFeedAll(onlyOne)
				if S.farm then setAI(true) end
			end
		end
		task.wait(0.5)
	end
end)

task.spawn(function()
	while true do
		if S.atc then
			local p=workspace:FindFirstChild(CFG.PLANE); local ck=p and p:FindFirstChild("Cockpit")
			local b=ck and ck:FindFirstChild("ATCButton")
			if b then fireTT("Radio",b) end
		end
		task.wait(CFG.ATC)
	end
end)

task.spawn(function()
	while true do
		pcall(function()
			local r=RS:FindFirstChild("Remotes")
			if r then local p=r:FindFirstChild("PassoutRemote"); if p then p:FireServer("wake_up") end end
		end)
		task.wait(CFG.PASSOUT)
	end
end)

do
	local queueFunc = queue_on_teleport
		or queueonteleport
		or (syn and syn.queue_on_teleport)
		or (fluxus and fluxus.queue_on_teleport)
		or (getgenv and getgenv().queue_on_teleport)

	if queueFunc then
		local payload =
			'if not game:IsLoaded() then game.Loaded:Wait() end\n' ..
			'local Players = game:GetService("Players")\n' ..
			'while not Players.LocalPlayer do task.wait(0.1) end\n' ..
			'local player = Players.LocalPlayer\n' ..
			'while not player:FindFirstChild("PlayerGui") or not player.Character do task.wait(0.1) end\n' ..
			'print("AI Pilot: restarting on new server (local buffer)")\n' ..
			'local src = nil\n' ..
			'pcall(function()\n' ..
			'    if type(isfile) == "function" and type(readfile) == "function" then\n' ..
			'        if isfile("' .. SELF_FILE .. '") then src = readfile("' .. SELF_FILE .. '") end\n' ..
			'    end\n' ..
			'end)\n' ..
			'if src then\n' ..
			'    local fn, err = loadstring(src)\n' ..
			'    if fn then pcall(fn) else warn("AI Pilot loadstring error: " .. tostring(err)) end\n' ..
			'else\n' ..
			'    warn("AI Pilot: file ' .. SELF_FILE .. ' not found")\n' ..
			'end\n'
		pcall(queueFunc, payload)
	else
		warn("queue_on_teleport not supported by this executor.")
	end
end

local function clickBtn(b)
	if not b then return false end
	local ok=false
	if type(getconnections)=="function" then
		pcall(function()
			for _,sig in ipairs({b.MouseButton1Click,b.Activated}) do
				if sig then for _,cn in ipairs(getconnections(sig)) do if type(cn.Function)=="function" then pcall(cn.Function); ok=true end end end
			end
		end)
	end
	return ok
end
task.spawn(function()
	local mr=playerGui:WaitForChild("MatchResults",30); if not mr then return end
	local function handle()
		task.spawn(function()
			task.wait(0.2)
			if not S.farm then return end
			local m=mr:FindFirstChild("Main"); if not m then return end
			local c=m:FindFirstChild("Container"); if not c then return end
			local bo=c:FindFirstChild("Bottom"); if not bo then return end
			local bu=bo:FindFirstChild("Buttons"); if not bu then return end
			local r=bu:FindFirstChild("Replay"); if not r then return end
			local b=r:FindFirstChildWhichIsA("GuiButton") or r
			if b:IsA("GuiButton") then clickBtn(b) end
		end)
	end
	if mr.Enabled then handle() end
	mr:GetPropertyChangedSignal("Enabled"):Connect(function() if mr.Enabled then handle() end end)
end)

U.fly.MouseButton1Click:Connect(function() setFly(not S.fly) end)
U.esp.MouseButton1Click:Connect(function() setESP(not S.esp) end)
U.feed.MouseButton1Click:Connect(function()
	if S.feed then S.feed=false; S.feedTok+=1; updFeed()
	else S.feed=true; S.feedTok+=1; updFeed(); local t=S.feedTok; task.spawn(function() feedLoop(t) end) end
end)
U.ai.MouseButton1Click:Connect(function()
	if not S.model then setStatus("model not loaded") return end
	setAI(not S.ai)
	if S.ai then
		local t=planeTorso()
		S.yaw=(t and math.abs(t.Orientation.Z)<15) and t.Orientation.Y or 0
		S.landing=false; S.aAlt=nil; S.aVS=0
	end
end)
U.model.MouseButton1Click:Connect(function()
	if S.ai then setStatus("turn off AI before changing model") return end
	S.curModel=S.curModel%#CFG.MODELS+1
	updModel()
	task.spawn(function()
		local ok,n=loadModel()
		setStatus(ok and ("Model: "..CFG.MODELS[S.curModel].name.." ("..n..")") or "model error")
	end)
end)
U.farm.MouseButton1Click:Connect(function()
	if not S.model then setStatus("model not loaded") return end
	setFarm(not S.farm)
end)
U.farmBox.MouseButton1Click:Connect(function() setFarm(false) end)
U.atc.MouseButton1Click:Connect(function() S.atc=not S.atc; S.atcTok+=1; updATC() end)
U.restart.MouseButton1Click:Connect(function() S.restart=not S.restart; updRestart() end)
U.close.MouseButton1Click:Connect(function()
	setESP(false); setFly(false)
	if S.feed then S.feed=false; S.feedTok+=1 end
	if S.ai then setAI(false) end
	S.farm=false; saveFarm(false); S.atc=false
	U.farmGui.Enabled=false
	U.gui.Enabled=false
end)

player.CharacterAdded:Connect(function(c) local h=c:WaitForChild("Humanoid",5); if h then h.WalkSpeed=S.walk end end)

updWalk(); updFly(); updESP(); updFeed(); updAI(); updModel(); updFarm(); updATC(); updRestart()
setStatus("Idle"); applyWalk()

if loadFarm() then
	setFarm(true)
end
