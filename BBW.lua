local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local boatsFolder=workspace:WaitForChild("Boats")
local camera=workspace.CurrentCamera
local Lighting=game:GetService("Lighting")
local function sp(t)
    if type(t)=="table"then return pairs(t)end;
    return function()return nil end;
end;

local CANNON_VELOCITY_MULT={
    Standard=1,Ironshot=1,Needler=2,Longbarrel=1.5,Hornet=1,Mortar=0.8,
    Siegebreaker=1,Titan=1.25,Colossus=2,SplitBarrel=1,TriBarrel=1,
    Annihilator=1.5,Vortex=3,Obliterator=0.8,Railgun=7,Spray=1,Battleship=2,
}
local function normalizeCannonName(name)
    if not name then return "" end;
    return name:gsub("%s+",""):gsub("%-",""):gsub("Cannon","");
end;

local ROGUE_RGB=Color3.fromRGB(27,42,53)
local ROGUE_RGB_TOL=0.02

local CFG={
    AIM_PART_NAMES={"Torso","UpperTorso","LowerTorso","HumanoidRootPart"},
    AIM_HRP_OFFSET_Y=-1.5,
    AK_OFFSET_BEHIND=5,
    AK_Y_OFFSET=10,
    AK_FIRE_DELAY=0.4,
    AK_LEAD_FACTOR=0.75,
    AK_LAG_PING_MULT=1.5,
    AK_LAG_BASE=0.15,
    AK_LAG_BIAS_STEP=0.005,
    AK_LAG_BIAS_MAX=0.5,
    AK_LAG_BIAS_AGREE_FRAMES=3,
    AK_LAG_BIAS_DECAY=0.02,
    AK_TIMEOUT=30,
    AK_BLACKLIST_TIME=120,
    AK_BLACKLIST_MULT=1.5,
    AK_BUMPER_COLOR_TOLERANCE=0.1,
    PROJECTILE_SPEED_BASE=205,
    BARREL_CACHE_TTL=0.15,
    DOTS_SCAN_INTERVAL=2,
    AIM_HEAVY_INTERVAL=2,
    CALIB_INTERVAL=20,
    CHAR_BOAT_CACHE_TTL=0.5,
    MOUSE_DEADZONE=0.04,
    MOUSE_RAY_DIST=5000,
    SPEED_DIVISOR=1000,
    FAST_ROT_RATE=math.rad(270),
    MAX_YAW_RATE=math.rad(3600),
    MAX_PITCH_RATE=math.rad(3600),
    SNAP_YAW=math.rad(8),
    SNAP_PITCH=math.rad(8),
    LEGACY_ROT_KP=12.0,
    LEGACY_ROT_RATE_MAX=20.0,
    LEGACY_AV_MAX_TORQUE=1e18,
    FLING_DURATION=12,
    FLING_SPIN_VEL=100000,
    FLING_MAP_DIST=1200,
    FLING_MAP_RETURN_DIST=800,
    FLING_CHECK_INTERVAL=0.25,
    GRAVITY_OVERRIDE=nil,
    GRAVITY_MULT=1.0,
    GRAVITY_SAMPLE_EMA=0.20,
    GRAVITY_SANITY_MIN=0,
    GRAVITY_SANITY_MAX=3000,
    GRAVITY_DIST_MIN=60,
    GRAVITY_DIST_FULL=220,
    AUTO_CALIBRATE=true,
    TRAJ_CALIB_COOLDOWN=0.10,
    TRAJ_CALIB_AGREE_FRAMES=4,
    TRAJ_LANDING_HEIGHT_MARGIN=20,
    PITCH_BIAS_STEP_DEG=0.2,
    PITCH_BIAS_MAX_DEG=20.0,
    PITCH_BIAS_DECAY_RATE=0.3,
    AIM_BARREL_UP_THRESHOLD=0.25,
    LEAD_MAX_BASE=5.0,
    LEAD_DIST_PER=1/50,
    VEL_GAIN_BASE=1.4,
    VEL_GAIN_MAX=3.0,
    FT_SCAN_BASE=80,
    FT_SCAN_PER_SEC=60,
    FT_SCAN_MAX=400,
    FT_BISECT_ITER=40,
    FT_NEWTON_ITER=8,
    FT_EPSILON_BASE=2e-4,
    FT_FDN_H=0.01,
    TRAJ_HIT_RADIUS=12,
    TRAJ_HIT_RADIUS_BOAT=20,
    TRAJ_CLOSE_RADIUS=30,
    TRAJ_MAX_FROM_MUZZLE=2000,
    BUOY_TIMEOUT=10.0,
    BUOY_SUNK_DIST=15,
    AUTO_LERP_RATE=8.0,
    AUTO_MAX_SPEED=4000,
    ESP_BOX=Color3.fromRGB(0,255,120),
    ESP_NAME=Color3.fromRGB(255,255,255),
    ESP_DIST=Color3.fromRGB(200,200,200),
    ESP_OUTLINE=Color3.fromRGB(0,0,0),
    ESP_PREDICT_ARROW_COLOR=Color3.fromRGB(255,100,255),
    ESP_PREDICT_START_DOT_COLOR=Color3.fromRGB(255,255,255),
    ESP_PREDICT_PHANTOM_FILL=Color3.fromRGB(255,60,255),
    ESP_PREDICT_PHANTOM_OUTLINE=Color3.fromRGB(255,255,255),
    ESP_PREDICT_PHANTOM_TRANSP=0.15,
    ESP_PREDICT_ARROW_THICKNESS=3,
    ESP_PREDICT_END_DOT_RADIUS=6,
    ESP_PREDICT_START_DOT_RADIUS=3,
    ESP_PREDICT_MAX_T=5.0,
    DOTS_HL_NORMAL_FILL=Color3.fromRGB(0,255,120),
    DOTS_HL_NORMAL_OUTLINE=Color3.fromRGB(0,120,60),
    DOTS_HL_RED_FILL=Color3.fromRGB(255,40,40),
    DOTS_HL_RED_OUTLINE=Color3.fromRGB(255,255,255),
    DOTS_HL_RED_SCALE=10,
    DOTS_RED_THRESHOLD=0.6,
    DOTS_MIN_VISIBLE_TRANSP=0.95,
    DOTS_MAX_DIM=40,
    DOTS_MIN_WORLD_Y=-200,
    DOTS_MAX_DIST_FROM_CAM=4000,
    DOTS_POOL_HARD_CAP=800,
    AUTOFARM_CHECK_INTERVAL=1.0,
    CROWN_NEAR_DIST=40,
    KOTH_THREAT_RADIUS=150,
    KOTH_ZONE_RADIUS=60,
    KOTH_IDLE_BEFORE_BALLS=10,
    FARM_COLLECT_DT=1/60,
}

local S={
    projectileSpeed=200,
    gEffValue=workspace.Gravity,
    gEffSamples={},
    flightTimeCache=setmetatable({},{__mode="k"}),
    calibShortStreak=0,
    calibLongStreak=0,
    lastCalibTime=0,
    lastAimTarget=nil,
    aimWasActiveLastFrame=false,
    pitchBias=0,
    frameCounter=0,
    aimBiasInvert=false,
    barrelCache=setmetatable({},{__mode="k"}),
    charBoatCache=setmetatable({},{__mode="k"}),
    boatBumperCache=setmetatable({},{__mode="k"}),
    barrelAlignQCache=setmetatable({},{__mode="k"}),
    trajDotsCache={},
    trajDotsCacheFrame=-9999,
    aimCacheAge=999,
    aimCachedHrp=nil,
    aimCachedYaw=nil,
    aimCachedPitch=nil,
    akTarget=nil,
    akTargetSince=0,
    akBlacklist=setmetatable({},{__mode="k"}),
    akBlacklistCount=setmetatable({},{__mode="k"}),
    akLastFire=0,
    akActive=false,
    akBoat=nil,
    akDesiredCF=setmetatable({},{__mode="k"}),
    akLagCompVec=Vector3.zero,
    akTargetSpeed=0,
    akTotalLag=0,
    akPingHalf=0,
    lagBias=0,
    lagShortStreak=0,
    lagLongStreak=0,
    cachedPing=0,
    cachedPingTime=0,
    flingAll=false,
    flingActive=false,
    flingTarget=nil,
    flingBoat=nil,
    flingStartTime=0,
    flingedBlacklist=setmetatable({},{__mode="k"}),
    autoFarm=false,
    autoFarmGui=nil,
    autoFarmSquare=nil,
    lastFarmCheck=0,
    gamemode={mode="none",zonePos=nil,crownPos=nil,crownPart=nil,crownHolder=nil,crownIsOurs=false,lastCheck=0},
    afZoneEnterTime=0,
    afFarmMode="idle",
    acInited=false,
    acCurrentBuoy=nil,
    acBuoyStartTime=0,
    acBuoyBlacklist=setmetatable({},{__mode="k"}),
    acBuoySpawnY=setmetatable({},{__mode="k"}),
    islandsCenter=nil,
    islandsCenterTime=0,
    disabledConstraints=setmetatable({},{__mode="k"}),
    angularConstraintsDisabled=setmetatable({},{__mode="k"}),
    noCollideSaved=setmetatable({},{__mode="k"}),
    speedhack=false,
    speedhackMode="rage",
    immediateStop=false,
    fastRot=false,
    mouseControl=false,
    aimbot=false,
    autoCollect=false,
    autoKill=false,
    fullbright=false,
    esp=false,
    unexecuted=false,
    dotsHighlight=false,
    espAccelPredict=false,
    currentValue=200000,
    acting=false,
    writing=setmetatable({},{__mode="k"}),
    protectedKeys=setmetatable({},{__mode="k"}),
    cframeCache=setmetatable({},{__mode="k"}),
    hookData={},
    motionPos=setmetatable({},{__mode="k"}),
    rotState=setmetatable({},{__mode="k"}),
    targetMotion=setmetatable({},{__mode="k"}),
    espData=setmetatable({},{__mode="k"}),
    fullbrightSaved=nil,
    myBoat=nil,
    myBumperColor=nil,
    myIsRogue=false,
    myBumperCheckedAt=0,
    dotsPoolFolder=nil,
    dotsPool={},
    dotsUsedLast=0,
    espPredictData=setmetatable({},{__mode="k"}),
    phantomFolder=nil,
    boatSizeCache=setmetatable({},{__mode="k"}),
    connections={},
    pendingCF=nil,
    legacyPendingVF=nil,
    legacyPendingForce=nil,
    legacyPendingPhys=nil,
    legacyPendingAV=nil,
    legacyPendingAngVel=nil,
    highlightSphere=nil,
    highlightBB=nil,
    highlightLabel=nil,
    lagLabel=nil,
}

local function track(c)table.insert(S.connections,c);return c end;

local character=player.Character or player.CharacterAdded:Wait();
local humanoidRootPart=character:WaitForChild("HumanoidRootPart");
track(player.CharacterAdded:Connect(function(char)
    character=char;
    humanoidRootPart=char:WaitForChild("HumanoidRootPart");
end));

local _getrawmetatable=rawget(_G,"getrawmetatable");
local _setreadonly=rawget(_G,"setreadonly") or function()end;
local _getreadonly=rawget(_G,"getreadonly") or function()return false end;

local function installHook(instance)
    if not _getrawmetatable then return false end;
    local mt;
    local ok=pcall(function()mt=_getrawmetatable(instance)end);
    if not ok or type(mt)~="table" then return false end;
    if S.hookData[mt] then return true end;
    local oldNewIndex=mt.__newindex;
    local oldIndex=mt.__index;
    local oldReadonly=false;
    pcall(function()oldReadonly=_getreadonly(mt)end);
    pcall(function()_setreadonly(mt,false)end);
    local capturedOld=oldNewIndex;
    mt.__newindex=function(t,k,v)
        local set=S.protectedKeys[t];
        if set and set[k] and not S.writing[t] then return end;
        if capturedOld then return capturedOld(t,k,v) end;
        return nil;
    end;
    mt.__index=function(t,k)
        if k=="CFrame" then
            local cached=S.cframeCache[t];
            if cached then return cached end;
        end;
        if oldIndex then return oldIndex(t,k) end;
        return nil;
    end;
    pcall(function()_setreadonly(mt,true)end);
    S.hookData[mt]={oldNewIndex=oldNewIndex,oldIndex=oldIndex,oldReadonly=oldReadonly};
    return true;
end;

local function uninstallHook(mt)
    local d=S.hookData[mt];
    if not d then return end;
    pcall(function()_setreadonly(mt,false)end);
    mt.__newindex=d.oldNewIndex;
    mt.__index=d.oldIndex;
    pcall(function()_setreadonly(mt,d.oldReadonly)end);
    S.hookData[mt]=nil;
end;

local function protectKey(instance,key)
    if not instance then return end;
    installHook(instance);
    local set=S.protectedKeys[instance];
    if not set then set={};S.protectedKeys[instance]=set end;
    set[key]=true;
end;

local function unprotectKey(instance,key)
    if not instance then return end;
    local set=S.protectedKeys[instance];
    if not set then return end;
    set[key]=nil;
end;

local function setProtected(instance,key,value)
    if not instance or not instance.Parent then return end;
    S.writing[instance]=true;
    pcall(function()instance[key]=value end);
    S.writing[instance]=false;
    if key=="CFrame" then S.cframeCache[instance]=value end;
end;

local function getPingSeconds()
    local now=os.clock();
    if now-S.cachedPingTime<1.0 and S.cachedPingTime>0 then
        return S.cachedPing;
    end
    S.cachedPingTime=now;
    local ok,p=pcall(function()return player:GetNetworkPing()end);
    if ok and type(p)=="number" and p>0 then
        S.cachedPing=p;
    end
    return S.cachedPing;
end;

local function getAutoLagTime()
    local ping=getPingSeconds();
    local base=ping*CFG.AK_LAG_PING_MULT+CFG.AK_LAG_BASE;
    return base+S.lagBias;
end;

do
    local p=Instance.new("Part");
    p.Name="__AimTargetSphere";
    p.Shape=Enum.PartType.Ball;
    p.Size=Vector3.new(5,5,5);
    p.Material=Enum.Material.Neon;
    p.Color=Color3.fromRGB(255,50,50);
    p.Transparency=0.25;
    p.CanCollide=false;
    p.CanQuery=false;
    p.CanTouch=false;
    p.Anchored=true;
    p.CastShadow=false;
    p.Parent=workspace;
    local bb=Instance.new("BillboardGui");
    bb.Size=UDim2.new(0,200,0,40);
    bb.StudsOffset=Vector3.new(0,4,0);
    bb.AlwaysOnTop=true;
    bb.Adornee=p;
    bb.Parent=p;
    local lb=Instance.new("TextLabel");
    lb.Size=UDim2.new(1,0,1,0);
    lb.BackgroundTransparency=1;
    lb.TextColor3=Color3.fromRGB(255,80,80);
    lb.TextStrokeTransparency=0;
    lb.TextStrokeColor3=Color3.fromRGB(0,0,0);
    lb.Font=Enum.Font.GothamBold;
    lb.TextSize=18;
    lb.Parent=bb;
    S.highlightSphere=p;
    S.highlightBB=bb;
    S.highlightLabel=lb;
end;

local function updateHighlight(targetHrp)
    if targetHrp and targetHrp.Parent then
        S.highlightSphere.CFrame=CFrame.new(targetHrp.Position);
        S.highlightSphere.Transparency=0.25;
        S.highlightBB.Enabled=true;
        S.highlightLabel.Text=targetHrp.Parent.Name or "TARGET";
    else
        S.highlightBB.Enabled=false;
        S.highlightSphere.Transparency=1;
    end;
end;

local screenGui=Instance.new("ScreenGui");
screenGui.Name="BoatForceGui";
screenGui.ResetOnSpawn=false;
screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;
screenGui.Parent=player:WaitForChild("PlayerGui");

local frame=Instance.new("Frame");
frame.Size=UDim2.new(0,320,0,600);
frame.Position=UDim2.new(0,20,0,20);
frame.BackgroundColor3=Color3.fromRGB(30,30,30);
frame.BorderSizePixel=0;
frame.Active=true;
frame.Draggable=true;
frame.Parent=screenGui;

local title=Instance.new("TextLabel");
title.Size=UDim2.new(1,0,0,28);
title.BackgroundColor3=Color3.fromRGB(50,50,50);
title.Text="Boat Speedhack [CFrame]";
title.TextColor3=Color3.fromRGB(255,255,255);
title.Font=Enum.Font.GothamBold;
title.TextSize=13;
title.BorderSizePixel=0;
title.Parent=frame;

local valueLabel=Instance.new("TextLabel");
valueLabel.Size=UDim2.new(1,-20,0,22);
valueLabel.Position=UDim2.new(0,10,0,32);
valueLabel.BackgroundTransparency=1;
valueLabel.TextColor3=Color3.fromRGB(255,255,255);
valueLabel.Font=Enum.Font.Gotham;
valueLabel.TextSize=14;
valueLabel.TextXAlignment=Enum.TextXAlignment.Left;
valueLabel.Text="Speed: 200";
valueLabel.Parent=frame;

local sliderFrame=Instance.new("Frame");
sliderFrame.Size=UDim2.new(1,-20,0,14);
sliderFrame.Position=UDim2.new(0,10,0,58);
sliderFrame.BackgroundColor3=Color3.fromRGB(60,60,60);
sliderFrame.BorderSizePixel=0;
sliderFrame.Parent=frame;

local sliderFill=Instance.new("Frame");
sliderFill.Size=UDim2.new(0,0,1,0);
sliderFill.BackgroundColor3=Color3.fromRGB(0,170,255);
sliderFill.BorderSizePixel=0;
sliderFill.Parent=sliderFrame;

local sliderKnob=Instance.new("TextButton");
sliderKnob.Size=UDim2.new(0,14,0,22);
sliderKnob.Position=UDim2.new(0,0,0.5,0);
sliderKnob.AnchorPoint=Vector2.new(0.5,0.5);
sliderKnob.BackgroundColor3=Color3.fromRGB(255,255,255);
sliderKnob.BorderSizePixel=0;
sliderKnob.Text="";
sliderKnob.AutoButtonColor=false;
sliderKnob.Parent=sliderFrame;

local MIN_VAL,MAX_VAL=0,800000;

local function applyValue(v)
    S.currentValue=math.clamp(v,MIN_VAL,MAX_VAL);
    local a=(S.currentValue-MIN_VAL)/(MAX_VAL-MIN_VAL);
    sliderFill.Size=UDim2.new(a,0,1,0);
    sliderKnob.Position=UDim2.new(a,0,0.5,0);
    valueLabel.Text=string.format("Speed: %d",math.floor(S.currentValue));
end;

local function valueFromMouseX(absX)
    local a=math.clamp((absX-sliderFrame.AbsolutePosition.X)/sliderFrame.AbsoluteSize.X,0,1);
    applyValue(MIN_VAL+a*(MAX_VAL-MIN_VAL));
end;

local draggingSlider=false;
track(sliderFrame.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        draggingSlider=true;
        valueFromMouseX(input.Position.X);
    end;
end));
track(sliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        draggingSlider=true;
        valueFromMouseX(input.Position.X);
    end;
end));
track(UIS.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        valueFromMouseX(input.Position.X);
    end;
end));
track(UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then draggingSlider=false end;
end));
applyValue(200000);

local hitIndicator=Instance.new("TextLabel");
hitIndicator.Size=UDim2.new(0,300,0,18);
hitIndicator.Position=UDim2.new(0,10,0,2);
hitIndicator.BackgroundTransparency=1;
hitIndicator.TextColor3=Color3.fromRGB(255,255,255);
hitIndicator.Font=Enum.Font.GothamBold;
hitIndicator.TextSize=12;
hitIndicator.Text="";
hitIndicator.Parent=frame;

local applyFullbright,restoreFullbright,espShow,espHideAll;
local setAutoFarm
local autoKillBtnRef=nil

local function makeToggle(idx,label,key)
    local yPos=90+(idx-1)*25;
    local btn=Instance.new("TextButton");
    btn.Size=UDim2.new(1,-20,0,24);
    btn.Position=UDim2.new(0,10,0,yPos);
    btn.BackgroundColor3=Color3.fromRGB(70,70,70);
    btn.TextColor3=Color3.fromRGB(255,255,255);
    btn.Font=Enum.Font.Gotham;
    btn.TextSize=14;
    btn.BorderSizePixel=0;
    btn.Text=label..": OFF";
    btn.Parent=frame;
    btn.MouseButton1Click:Connect(function()
        S[key]=not S[key];
        btn.Text=label..": "..(S[key] and "ON" or "OFF");
        btn.BackgroundColor3=S[key] and Color3.fromRGB(0,150,80) or Color3.fromRGB(70,70,70);
        if key=="fullbright" then
            if S.fullbright then if applyFullbright then applyFullbright() end;
            else if restoreFullbright then restoreFullbright() end end;
        elseif key=="esp" then
            if S.esp then if espShow then espShow() end;
            else if espHideAll then espHideAll() end end;
        elseif key=="espAccelPredict" then
            if not S.espAccelPredict then
                for _,d in sp(S.espPredictData) do
                    if d.line then d.line.Visible=false end;
                    if d.endDot then d.endDot.Visible=false end;
                    if d.startDot then d.startDot.Visible=false end;
                    if d.phantomHL then d.phantomHL.Enabled=false end;
                    if d.phantomSel then d.phantomSel.Visible=false end;
                    if d.phantom then d.phantom.Transparency=1 end;
                end;
            end;
        elseif key=="autoKill" then
            if not S.autoKill then
                S.akActive=false;
                S.akTarget=nil;
                S.akBoat=nil;
                S.akDesiredCF=setmetatable({},{__mode="k"});
                S.akLastFire=0;
                S.akTargetSince=0;
                S.akBlacklist=setmetatable({},{__mode="k"});
                S.akBlacklistCount=setmetatable({},{__mode="k"});
                updateHighlight(nil);
                hitIndicator.Text="";
            end;
        elseif key=="flingAll" then
            if not S.flingAll then
                S.flingActive=false;
                S.flingTarget=nil;
                hitIndicator.Text="";
            end;
        end;
    end);
    if key=="autoKill" then autoKillBtnRef=btn end
    return btn;
end;

makeToggle(1,"Speedhack (W)","speedhack");

local modeBtn=Instance.new("TextButton");
modeBtn.Size=UDim2.new(1,-20,0,24);
modeBtn.Position=UDim2.new(0,10,0,115);
modeBtn.BackgroundColor3=Color3.fromRGB(0,120,200);
modeBtn.TextColor3=Color3.fromRGB(255,255,255);
modeBtn.Font=Enum.Font.GothamBold;
modeBtn.TextSize=14;
modeBtn.BorderSizePixel=0;
modeBtn.Text="Mode: Rage";
modeBtn.Parent=frame;
modeBtn.MouseButton1Click:Connect(function()
    if S.speedhackMode=="rage" then
        S.speedhackMode="legacy";
        modeBtn.Text="Mode: Legacy";
        modeBtn.BackgroundColor3=Color3.fromRGB(200,110,0);
    else
        S.speedhackMode="rage";
        modeBtn.Text="Mode: Rage";
        modeBtn.BackgroundColor3=Color3.fromRGB(0,120,200);
    end;
end);

makeToggle(3,"Immediate Stop (Legacy)","immediateStop");
makeToggle(4,"Fast Rot (A/D)","fastRot");
makeToggle(5,"Mouse Control","mouseControl");
makeToggle(6,"Silent Aim (Q)","aimbot");
makeToggle(7,"Auto Balls Collect","autoCollect");
makeToggle(8,"Auto Kill (BEHIND)","autoKill");
makeToggle(9,"Fullbright","fullbright");
makeToggle(10,"ESP","esp");
makeToggle(11,"Dots Highlight","dotsHighlight");
makeToggle(12,"Accel Predict ESP","espAccelPredict");
makeToggle(13,"FLING ALL","flingAll");

local autoFarmBtn=Instance.new("TextButton");
autoFarmBtn.Size=UDim2.new(1,-20,0,24);
autoFarmBtn.Position=UDim2.new(0,10,0,90+13*25);
autoFarmBtn.BackgroundColor3=Color3.fromRGB(70,70,70);
autoFarmBtn.TextColor3=Color3.fromRGB(255,255,255);
autoFarmBtn.Font=Enum.Font.Gotham;
autoFarmBtn.TextSize=14;
autoFarmBtn.BorderSizePixel=0;
autoFarmBtn.Text="Auto Farm: OFF";
autoFarmBtn.Parent=frame;
autoFarmBtn.MouseButton1Click:Connect(function()
    if not S.autoFarm then
        if setAutoFarm then setAutoFarm(true) end;
    else
        if setAutoFarm then setAutoFarm(false) end;
    end;
end);

S.lagLabel=Instance.new("TextLabel");
S.lagLabel.Size=UDim2.new(1,-20,0,22);
S.lagLabel.Position=UDim2.new(0,10,0,90+14*25+4);
S.lagLabel.BackgroundTransparency=1;
S.lagLabel.TextColor3=Color3.fromRGB(255,220,120);
S.lagLabel.Font=Enum.Font.Gotham;
S.lagLabel.TextSize=12;
S.lagLabel.TextXAlignment=Enum.TextXAlignment.Left;
S.lagLabel.Text="AUTO-LAG: ping=--ms lag=--ms bias=--ms";
S.lagLabel.Parent=frame;

applyFullbright=function()
    if S.fullbrightSaved then return end;
    S.fullbrightSaved={
        Ambient=Lighting.Ambient,
        OutdoorAmbient=Lighting.OutdoorAmbient,
        Brightness=Lighting.Brightness,
        ClockTime=Lighting.ClockTime,
        GlobalShadows=Lighting.GlobalShadows,
        FogEnd=Lighting.FogEnd,
        FogStart=Lighting.FogStart,
        EnvironmentDiffuseScale=Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale=Lighting.EnvironmentSpecularScale,
    };
    Lighting.Ambient=Color3.fromRGB(255,255,255);
    Lighting.OutdoorAmbient=Color3.fromRGB(255,255,255);
    Lighting.Brightness=2;
    Lighting.ClockTime=14;
    Lighting.GlobalShadows=false;
    Lighting.FogEnd=1e6;
    Lighting.FogStart=1e6;
    Lighting.EnvironmentDiffuseScale=1;
    Lighting.EnvironmentSpecularScale=1;
end;

restoreFullbright=function()
    if not S.fullbrightSaved then return end;
    for k,v in sp(S.fullbrightSaved) do pcall(function()Lighting[k]=v end) end;
    S.fullbrightSaved=nil;
end;

local ALL_PHYS_CLASSES={"AlignOrientation","BodyGyro","Torque","AngularVelocity","BodyAngularVelocity","AlignPosition","BodyPosition","LinearVelocity"}
local ANG_ONLY_CLASSES={"AngularVelocity","BodyAngularVelocity","BodyGyro","AlignOrientation"}

local function disableClassList(physical,classes)
    if not physical then return nil end;
    local saved={};
    local assembly=physical.AssemblyRootPart or physical;
    local parts=assembly:GetConnectedParts(true);
    table.insert(parts,assembly);
    for _,part in ipairs(parts) do
        for _,cls in ipairs(classes) do
            for _,c in ipairs(part:GetChildren()) do
                if c:IsA(cls) then
                    if c.Name=="__LegacyAV" or c.Name=="__FlingAV" then
                    else
                        local ok,en=pcall(function()return c.Enabled end);
                        if ok and en then
                            table.insert(saved,{obj=c,prop="Enabled",value=true});
                            pcall(function()c.Enabled=false end);
                        end;
                    end;
                end;
            end;
        end;
    end;
    return saved;
end;

local function restoreSavedList(saved)
    if not saved then return end;
    for _,e in ipairs(saved) do
        if e.obj and e.obj.Parent then pcall(function()e.obj[e.prop]=e.value end) end;
    end;
end;

local function disableConstraints(physical)
    if not physical then return end;
    if S.disabledConstraints[physical] then return end;
    S.disabledConstraints[physical]=disableClassList(physical,ALL_PHYS_CLASSES);
end;

local function restoreConstraints(physical)
    if not physical then return end;
    local s=S.disabledConstraints[physical];
    if not s then return end;
    restoreSavedList(s);
    S.disabledConstraints[physical]=nil;
end;

local function disableAngularConstraints(physical)
    if not physical then return end;
    if S.angularConstraintsDisabled[physical] then return end;
    S.angularConstraintsDisabled[physical]=disableClassList(physical,ANG_ONLY_CLASSES);
end;

local function restoreAngularConstraints(physical)
    if not physical then return end;
    local s=S.angularConstraintsDisabled[physical];
    if not s then return end;
    restoreSavedList(s);
    S.angularConstraintsDisabled[physical]=nil;
end;

local function disableBoatCollisions(physical)
    if not physical or S.noCollideSaved[physical] then return end;
    local saved={};
    local assembly=physical.AssemblyRootPart or physical;
    local parts=assembly:GetConnectedParts(true);
    table.insert(parts,assembly);
    for _,p in ipairs(parts) do
        if p.CanCollide then
            table.insert(saved,p);
            pcall(function()p.CanCollide=false end);
        end;
    end;
    S.noCollideSaved[physical]=saved;
end;

local function restoreBoatCollisions(physical)
    if not physical then return end;
    local saved=S.noCollideSaved[physical];
    if not saved then return end;
    for _,p in ipairs(saved) do
        if p and p.Parent then pcall(function()p.CanCollide=true end) end;
    end;
    S.noCollideSaved[physical]=nil;
end;

local function getAimPosOfCharacter(char)
    if not char then return nil end;
    for _,name in ipairs(CFG.AIM_PART_NAMES) do
        local p=char:FindFirstChild(name);
        if p and p:IsA("BasePart") then return p.Position,p end;
    end;
    local hrp=char:FindFirstChild("HumanoidRootPart");
    if hrp then return hrp.Position+Vector3.new(0,CFG.AIM_HRP_OFFSET_Y,0),hrp end;
    return nil;
end;

local function getMouseClosestPlayerWithAim()
    if not camera then return nil end;
    local mousePos=UIS:GetMouseLocation();
    local bestChar,bestHrp,bestAimPos=nil,nil,nil;
    local bd=math.huge;
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=player then
            local char=plr.Character;
            if char then
                local hum=char:FindFirstChildOfClass("Humanoid");
                local hrp=char:FindFirstChild("HumanoidRootPart");
                if hrp and hum and hum.Health>0 then
                    local aimPos=getAimPosOfCharacter(char);
                    if aimPos then
                        local sPos,on=camera:WorldToViewportPoint(aimPos);
                        if on and sPos.Z>0 then
                            local dx,dy=sPos.X-mousePos.X,sPos.Y-mousePos.Y;
                            local d=dx*dx+dy*dy;
                            if d<bd then
                                bd=d;
                                bestChar=char;
                                bestHrp=hrp;
                                bestAimPos=aimPos;
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
    return bestChar,bestAimPos,bestHrp;
end;

local function ensureRotState(physical)
    local rs=S.rotState[physical];
    if not rs then
        local look=physical.CFrame.LookVector;
        rs={yaw=math.atan2(look.X,look.Z),pitch=math.asin(math.clamp(look.Y,-1,1))};
        S.rotState[physical]=rs;
    end;
    return rs;
end;

local function writeCFrameDirect(physical,cf)
    if not physical or not physical.Parent then return end;
    pcall(function()physical.AssemblyAngularVelocity=Vector3.zero end);
    pcall(function()physical.AssemblyLinearVelocity=Vector3.zero end);
    pcall(function()physical.RotVelocity=Vector3.zero end);
    pcall(function()physical.Velocity=Vector3.zero end);
    setProtected(physical,"CFrame",cf);
end;

local function findBarrels(boat)
    if not boat then return {} end;
    local barrels={};
    for _,child in ipairs(boat:GetChildren()) do
        if child:IsA("Model") or child:IsA("Folder") then
            local hasSeat=child:FindFirstChildWhichIsA("VehicleSeat",true);
            if hasSeat then
                for _,d in ipairs(child:GetDescendants()) do
                    if d.Name=="Barrel" and d:IsA("BasePart") then table.insert(barrels,d) end;
                end;
                if #barrels>0 then return barrels end;
            end;
        end;
    end;
    for _,d in ipairs(boat:GetDescendants()) do
        if d.Name=="Barrel" and d:IsA("BasePart") then table.insert(barrels,d) end;
    end;
    return barrels;
end;

local function getMuzzlePosFor(barrel)
    if not barrel then return nil end;
    for _,name in ipairs({"Muzzle","MuzzlePoint","Tip","MuzzleAttachment","End"}) do
        local c=barrel:FindFirstChild(name,true);
        if c then
            if c:IsA("BasePart") then return c.Position end;
            if c:IsA("Attachment") then return c.WorldPosition end;
        end;
    end;
    return barrel.Position;
end;

local function getBarrelWorldDirFor(barrel)
    if not barrel then return nil,"?" end;
    for _,d in ipairs(barrel:GetDescendants()) do
        if d:IsA("Decal") or d:IsA("Texture") then
            local parent=d.Parent;
            if parent and parent:IsA("BasePart") then
                local wd=parent.CFrame:VectorToWorldSpace(Vector3.FromNormalId(d.Face));
                if wd.Magnitude>0.001 then return wd.Unit,tostring(d.Face) end;
            end;
        end;
    end;
    if barrel.CFrame.LookVector.Magnitude>0.001 then return barrel.CFrame.LookVector.Unit,"LookV" end;
    return nil,"?";
end;

local function getBarrelAlignQ(barrel)
    if not barrel then return CFrame.new() end;
    local cached=S.barrelAlignQCache[barrel];
    if cached then return cached end;
    local wd=getBarrelWorldDirFor(barrel);
    local fdLocal;
    if wd then fdLocal=barrel.CFrame:VectorToObjectSpace(wd);
    else fdLocal=Vector3.new(0,0,-1) end;
    if fdLocal.Magnitude<0.001 then fdLocal=Vector3.new(0,0,-1) else fdLocal=fdLocal.Unit end;
    local to=Vector3.new(0,0,-1);
    local dot=math.clamp(fdLocal:Dot(to),-1,1);
    local q;
    if dot>0.9999 then q=CFrame.new()
    else
        local axis=fdLocal:Cross(to);
        if axis.Magnitude<1e-5 then axis=Vector3.new(0,1,0) else axis=axis.Unit end;
        q=CFrame.fromAxisAngle(axis,math.acos(dot));
    end;
    S.barrelAlignQCache[barrel]=q;
    return q;
end;

local function getAverageMuzzlePos(barrels)
    if #barrels==0 then return nil end;
    local sum,count=Vector3.zero,0;
    for _,b in ipairs(barrels) do
        local p=getMuzzlePosFor(b);
        if p then sum=sum+p;count=count+1 end;
    end;
    if count==0 then return nil end;
    return sum/count;
end;

local function getAverageBarrelWorldDir(barrels)
    if #barrels==0 then return nil,"?" end;
    local sum=Vector3.zero;
    local face="?";
    local n=0;
    for _,b in ipairs(barrels) do
        local d,f=getBarrelWorldDirFor(b);
        if d then sum=sum+d;n=n+1 end;
        if f~="?" then face=f end;
    end;
    if n==0 or sum.Magnitude<0.001 then return nil,face end;
    return sum.Unit,face;
end;

local function getCachedBarrels(boat,physical)
    if not boat or not physical then return {},nil,Vector3.new(0,0,-1),nil,"?" end;
    local now=os.clock();
    local c=S.barrelCache[boat];
    if not c or now-c.time>CFG.BARREL_CACHE_TTL then
        local barrels=findBarrels(boat);
        local muzzle=(#barrels>0) and getAverageMuzzlePos(barrels) or nil;
        local wd,face=nil,"?";
        local ld=Vector3.new(0,0,-1);
        if #barrels>0 then
            wd,face=getAverageBarrelWorldDir(barrels);
            if wd then
                local l=physical.CFrame:VectorToObjectSpace(wd);
                if l.Magnitude>0.001 then ld=l.Unit end;
            end;
        end;
        c={barrels=barrels,muzzle=muzzle,localDir=ld,worldDir=wd,face=face,time=now};
        S.barrelCache[boat]=c;
    end;
    return c.barrels,c.muzzle,c.localDir,c.worldDir,c.face;
end;

local function getProjectileSpeedForBoat(boat,physical)
    if not boat or not physical then return CFG.PROJECTILE_SPEED_BASE end;
    local barrels=getCachedBarrels(boat,physical);
    if #barrels==0 then return CFG.PROJECTILE_SPEED_BASE end;
    local parent=barrels[1].Parent;
    local key=parent and normalizeCannonName(parent.Name) or "";
    local mult=CANNON_VELOCITY_MULT[key] or 1;
    return CFG.PROJECTILE_SPEED_BASE*mult;
end;

local function getBoatBoundingSize(boat)
    if not boat then return Vector3.new(10,5,20) end;
    local cached=S.boatSizeCache[boat];
    if cached then return cached end;
    local min,max;
    for _,p in ipairs(boat:GetDescendants()) do
        if p:IsA("BasePart") then
            local cf,sz=p.CFrame,p.Size;
            for sx=-1,1,2 do
                for sy=-1,1,2 do
                    for sz2=-1,1,2 do
                        local wc=(cf*CFrame.new(sx*sz.X/2,sy*sz.Y/2,sz2*sz.Z/2)).Position;
                        if not min then min,max=wc,wc;
                        else
                            min=Vector3.new(math.min(min.X,wc.X),math.min(min.Y,wc.Y),math.min(min.Z,wc.Z));
                            max=Vector3.new(math.max(max.X,wc.X),math.max(max.Y,wc.Y),math.max(max.Z,wc.Z));
                        end;
                    end;
                end;
            end;
        end;
    end;
    local size=(min and max) and (max-min) or Vector3.new(10,5,20);
    size=Vector3.new(math.max(size.X,4),math.max(size.Y,4),math.max(size.Z,4));
    S.boatSizeCache[boat]=size;
    return size;
end;

local function getPlayerBoat(char)
    if not char then return nil end;
    local cached=S.charBoatCache[char];
    if cached and (os.clock()-cached.time)<CFG.CHAR_BOAT_CACHE_TTL then
        if cached.boat and cached.boat.Parent then return cached.boat end;
    end;
    local hum=char:FindFirstChildOfClass("Humanoid");
    if not hum or not hum.SeatPart then
        S.charBoatCache[char]={boat=nil,time=os.clock()};
        return nil;
    end;
    local seatRoot=hum.SeatPart.AssemblyRootPart or hum.SeatPart;
    for _,boat in ipairs(boatsFolder:GetChildren()) do
        if boat.Name=="Boat" then
            local phys=boat:FindFirstChild("Physical");
            if phys and phys:IsA("BasePart") then
                local physRoot=phys.AssemblyRootPart or phys;
                if physRoot==seatRoot then
                    S.charBoatCache[char]={boat=boat,time=os.clock()};
                    return boat;
                end;
            end;
        end;
    end;
    S.charBoatCache[char]={boat=nil,time=os.clock()};
    return nil;
end;

local function getMyBoat()
    if not character or not character.Parent then return nil end;
    return getPlayerBoat(character);
end;

local function getBoatBumper(boat)
    if not boat then return nil end;
    local cached=S.boatBumperCache[boat];
    if cached and cached.Parent then return cached end;
    local result=nil;
    for _,d in ipairs(boat:GetDescendants()) do
        if d:IsA("VehicleSeat") then
            local base=d.Parent;
            if base then
                local b1=base:FindFirstChild("Bumper");
                if b1 and b1:IsA("BasePart") then result=b1;break end;
                if base.Parent and base.Parent~=boat then
                    local b2=base.Parent:FindFirstChild("Bumper");
                    if b2 and b2:IsA("BasePart") then result=b2;break end;
                end;
            end;
            break;
        end;
    end;
    if not result then
        for _,d in ipairs(boat:GetDescendants()) do
            if d.Name=="Bumper" and d:IsA("BasePart") then result=d;break end;
        end;
    end;
    if result then S.boatBumperCache[boat]=result end;
    return result;
end;

local function colorsMatch(c1,c2,tol)
    tol=tol or CFG.AK_BUMPER_COLOR_TOLERANCE;
    if not c1 or not c2 then return false end;
    return math.abs(c1.R-c2.R)<tol and math.abs(c1.G-c2.G)<tol and math.abs(c1.B-c2.B)<tol;
end;

local function isRogueBumper(bumper)
    if not bumper then return false end;
    local c=bumper.Color;
    if not c then return false end;
    return math.abs(c.R-ROGUE_RGB.R)<ROGUE_RGB_TOL
       and math.abs(c.G-ROGUE_RGB.G)<ROGUE_RGB_TOL
       and math.abs(c.B-ROGUE_RGB.B)<ROGUE_RGB_TOL;
end;

local function updateMyBoat(now)
    if now-S.myBumperCheckedAt<0.5 and S.myBoat and S.myBoat.Parent then return end;
    S.myBumperCheckedAt=now;
    S.myBoat=getMyBoat();
    if S.myBoat then
        local bumper=getBoatBumper(S.myBoat);
        if bumper then
            S.myBumperColor=bumper.Color;
            S.myIsRogue=isRogueBumper(bumper);
        else
            S.myBumperColor=nil;
            S.myIsRogue=false;
        end;
    else
        S.myBumperColor=nil;
        S.myIsRogue=false;
    end;
end;

local function isEnemyBoat(eb)
    if not eb then return false end;
    if S.myIsRogue then return true end;
    local bumper=getBoatBumper(eb);
    if not bumper then return true end;
    if isRogueBumper(bumper) then return true end;
    if not S.myBumperColor then return true end;
    return not colorsMatch(S.myBumperColor,bumper.Color);
end;

local VEL_SAMPLES_MAX=12
local function updateTargetMotion(obj,now)
    local v=obj.AssemblyLinearVelocity;
    local rec=S.targetMotion[obj];
    if not rec then
        rec={vel=v,time=now,velSamples={v},velAvg=v};
        S.targetMotion[obj]=rec;
        return rec;
    end;
    rec.vel=v;
    rec.time=now;
    table.insert(rec.velSamples,v);
    if #rec.velSamples>VEL_SAMPLES_MAX then
        table.remove(rec.velSamples,1);
    end;
    local sum=Vector3.zero;
    for i=1,#rec.velSamples do
        sum=sum+rec.velSamples[i];
    end;
    rec.velAvg=sum/#rec.velSamples;
    return rec;
end;

local function computeVelGain(hrp,aimPos,originPos)
    local rec=S.targetMotion[hrp];
    if not rec then return CFG.VEL_GAIN_BASE end;
    local los=aimPos-originPos;
    local losLen=los.Magnitude;
    local losUnit=losLen>0.001 and los.Unit or Vector3.new(0,0,1);
    local v=rec.velAvg or rec.vel;
    local radialVel=v:Dot(losUnit);
    local speedMag=v.Magnitude;
    local distFactor=math.clamp(losLen/200,0.8,2.0);
    local speedFactor=math.clamp(speedMag/40,0.8,1.8);
    local radialFactor=1.0;
    if radialVel>0 then radialFactor=1.0+math.clamp(radialVel/100,0,0.8) end;
    return math.clamp(CFG.VEL_GAIN_BASE*distFactor*speedFactor*radialFactor,CFG.VEL_GAIN_BASE,CFG.VEL_GAIN_MAX);
end;

local function targetPosAt(hrp,aimPos,originPos,t,vg)
    local rec=S.targetMotion[hrp];
    if not rec then return aimPos end;
    local lt=math.min(t,CFG.LEAD_MAX_BASE*3);
    vg=vg or CFG.VEL_GAIN_BASE;
    local v=rec.velAvg or rec.vel;
    return aimPos+v*(lt*vg);
end;

local function computeMaxT(muzzlePos,aimPos,v)
    local dist=(aimPos-muzzlePos).Magnitude;
    local baseT=CFG.LEAD_MAX_BASE;
    local distT=dist*CFG.LEAD_DIST_PER;
    local minFlightT=dist/math.max(v,1);
    local safeT=minFlightT*2.5+1.0;
    return math.max(baseT,math.min(distT,safeT));
end;

local function solveFlightTime(muzzlePos,aimPos,hrp,v,gEff,maxT,vg)
    if v<=0 or maxT<=0 then return nil end;
    local yVec=Vector3.new(0,1,0);
    local function f(t)
        local P=targetPosAt(hrp,aimPos,muzzlePos,t,vg);
        local vec=P-muzzlePos+yVec*(0.5*gEff*t*t);
        return vec.Magnitude-v*t;
    end;
    local eps=CFG.FT_EPSILON_BASE*math.max(1,maxT/4);
    local cached=S.flightTimeCache[hrp];
    if cached and cached<=maxT then
        if math.abs(f(cached))<2.0 then
            local t=cached;
            for _=1,CFG.FT_NEWTON_ITER do
                local ft=f(t);
                if math.abs(ft)<eps then return t end;
                local dt=CFG.FT_FDN_H;
                local dfdt=(f(t+dt)-f(t-dt))/(2*dt);
                if math.abs(dfdt)<1e-6 then break end;
                local step=math.clamp(ft/dfdt,-0.5,0.5);
                t=math.clamp(t-step,0.01,maxT);
            end;
            if math.abs(f(t))<1.0 then return t end;
        end;
    end;
    local N=math.floor(CFG.FT_SCAN_BASE+maxT*CFG.FT_SCAN_PER_SEC);
    N=math.clamp(N,CFG.FT_SCAN_BASE,CFG.FT_SCAN_MAX);
    local tMin=0.02;
    local roots={};
    local prevT,prevF=tMin,f(tMin);
    if math.abs(prevF)<eps then table.insert(roots,prevT) end;
    for i=1,N do
        local t=tMin+(maxT-tMin)*i/N;
        local fv=f(t);
        if math.abs(fv)<eps then
            table.insert(roots,t);
        elseif prevF*fv<0 then
            local a,b,fa=prevT,t,prevF;
            for _=1,CFG.FT_BISECT_ITER do
                local m=(a+b)*0.5;
                local fm=f(m);
                if math.abs(fm)<eps then a,b=m,m;break end;
                if fa*fm<0 then b=m else a=m end;
                if fa*fm>=0 then fa=fm end;
            end;
            local root=(a+b)*0.5;
            for _=1,CFG.FT_NEWTON_ITER do
                local ft=f(root);
                if math.abs(ft)<eps then break end;
                local dt=CFG.FT_FDN_H;
                local dfdt=(f(root+dt)-f(root-dt))/(2*dt);
                if math.abs(dfdt)<1e-6 then break end;
                local step=math.clamp(ft/dfdt,-0.5,0.5);
                local newRoot=math.clamp(root-step,0.01,maxT);
                if math.abs(newRoot-root)<eps*0.1 then root=newRoot;break end;
                root=newRoot;
            end;
            table.insert(roots,root);
        end;
        prevT,prevF=t,fv;
    end;
    if #roots==0 then
        local fMin,fMax=f(tMin),f(maxT);
        if fMin>0 and fMax>0 then return nil end;
        return tMin;
    end;
    table.sort(roots);
    S.flightTimeCache[hrp]=roots[1];
    return roots[1];
end;

local function dirForTime(muzzlePos,aimPos,hrp,t,v,gEff,vg)
    local P=targetPosAt(hrp,aimPos,muzzlePos,t,vg);
    local vec=P-muzzlePos+Vector3.new(0,1,0)*(0.5*gEff*t*t);
    if vec.Magnitude<1e-4 then return nil end;
    return vec.Unit;
end;

local function dotIsValid(d)
    if not d:IsA("BasePart") then return false end;
    if d.Transparency>=CFG.DOTS_MIN_VISIBLE_TRANSP then return false end;
    local sz=d.Size;
    if sz.X>CFG.DOTS_MAX_DIM or sz.Y>CFG.DOTS_MAX_DIM or sz.Z>CFG.DOTS_MAX_DIM then return false end;
    local pos=d.Position;
    if pos.Y<CFG.DOTS_MIN_WORLD_Y then return false end;
    if camera then
        if (pos-camera.CFrame.Position).Magnitude>CFG.DOTS_MAX_DIST_FROM_CAM then return false end;
    end;
    return true;
end;

local function refreshTrajDotsCache(force)
    if not force and (S.frameCounter-S.trajDotsCacheFrame)<CFG.DOTS_SCAN_INTERVAL then return end;
    local folder=workspace:FindFirstChild("TrajectoryDots");
    local list={};
    if folder then
        for _,obj in ipairs(folder:GetDescendants()) do
            if dotIsValid(obj) then table.insert(list,obj) end;
        end;
    end;
    S.trajDotsCache=list;
    S.trajDotsCacheFrame=S.frameCounter;
end;

local function evaluateTrajectory(aimPos,muzzlePos,targetHrp)
    local folder=workspace:FindFirstChild("TrajectoryDots");
    if not folder then return nil end;
    refreshTrajDotsCache(false);
    local dots=S.trajDotsCache;
    local validDots={};
    for _,obj in ipairs(dots) do
        if (obj.Position-muzzlePos).Magnitude<CFG.TRAJ_MAX_FROM_MUZZLE then
            table.insert(validDots,obj.Position);
        end;
    end;
    if #validDots==0 then return nil end;
    local landingDot,minY=nil,math.huge;
    for _,pos in ipairs(validDots) do
        if pos.Y<minY then minY=pos.Y;landingDot=pos end;
    end;
    local minD=math.huge;
    if targetHrp and targetHrp.Parent then
        local tp=targetHrp.Position;
        local r=math.max(targetHrp.Size.X,targetHrp.Size.Y,targetHrp.Size.Z)*0.5;
        for _,dot in ipairs(validDots) do
            local raw=(dot-tp).Magnitude;
            local sd=math.max(0,raw-r);
            if sd<minD then minD=sd end;
        end;
    else
        for _,pos in ipairs(validDots) do
            local d=(pos-aimPos).Magnitude;
            if d<minD then minD=d end;
        end;
    end;
    local aimDist=Vector3.new(aimPos.X-muzzlePos.X,0,aimPos.Z-muzzlePos.Z).Magnitude;
    local landDist=Vector3.new(landingDot.X-muzzlePos.X,0,landingDot.Z-muzzlePos.Z).Magnitude;
    local diff=landDist-aimDist;
    local beyond,short=false,false;
    local above=landingDot.Y-aimPos.Y;
    local isRealLanding=above<CFG.TRAJ_LANDING_HEIGHT_MARGIN;
    if not isRealLanding then short=true;
    else
        if diff>CFG.TRAJ_HIT_RADIUS then beyond=true;
        elseif diff<-CFG.TRAJ_HIT_RADIUS then short=true end;
    end;
    return minD,#validDots,beyond,short,isRealLanding,diff,landDist,aimDist;
end;

local function submitGEffSample(s)
    if s<CFG.GRAVITY_SANITY_MIN or s>CFG.GRAVITY_SANITY_MAX then return end;
    table.insert(S.gEffSamples,s);
    if #S.gEffSamples>80 then table.remove(S.gEffSamples,1) end;
    local sorted={};
    for _,v in ipairs(S.gEffSamples) do table.insert(sorted,v) end;
    table.sort(sorted);
    local med=sorted[math.floor(#sorted/2)+1];
    S.gEffValue=S.gEffValue*(1-CFG.GRAVITY_SAMPLE_EMA)+med*CFG.GRAVITY_SAMPLE_EMA;
end;

local function getGEffMax()
    if CFG.GRAVITY_OVERRIDE then return CFG.GRAVITY_OVERRIDE end;
    return S.gEffValue*CFG.GRAVITY_MULT;
end;

local function getGEffForDistance(dist)
    if CFG.GRAVITY_OVERRIDE then return CFG.GRAVITY_OVERRIDE end;
    if dist<=CFG.GRAVITY_DIST_MIN then return 0 end;
    if dist>=CFG.GRAVITY_DIST_FULL then return getGEffMax() end;
    local t=(dist-CFG.GRAVITY_DIST_MIN)/(CFG.GRAVITY_DIST_FULL-CFG.GRAVITY_DIST_MIN);
    return getGEffMax()*t;
end;

local function calibrateGEffFromDots(muzzlePos,dir,v)
    if not muzzlePos or not dir then return end;
    local dirHoriz=math.sqrt(dir.X*dir.X+dir.Z*dir.Z);
    if dirHoriz<0.15 then return end;
    local vHoriz=v*dirHoriz;
    if vHoriz<5 then return end;
    local samples={};
    for _,obj in ipairs(S.trajDotsCache) do
        local d=obj.Position-muzzlePos;
        local dHoriz=math.sqrt(d.X*d.X+d.Z*d.Z);
        if dHoriz>40 and dHoriz<1000 then
            local t=dHoriz/vHoriz;
            if t>0.05 and t<12 then
                table.insert(samples,2*(dir.Y*v*t-d.Y)/(t*t));
            end;
        end;
    end;
    if #samples==0 then return end;
    table.sort(samples);
    submitGEffSample(samples[math.floor(#samples/2)+1]);
end;

local function getMouseWorldPoint(physical)
    if not camera then return nil end;
    local mousePos=UIS:GetMouseLocation();
    local vpSize=camera.ViewportSize;
    if vpSize.X<=0 or vpSize.Y<=0 then return nil end;
    local dx=(mousePos.X-vpSize.X*0.5)/(vpSize.X*0.5);
    local dy=(mousePos.Y-vpSize.Y*0.5)/(vpSize.Y*0.5);
    if math.abs(dx)<CFG.MOUSE_DEADZONE and math.abs(dy)<CFG.MOUSE_DEADZONE then return nil end;
    local ray=camera:ViewportPointToRay(mousePos.X,mousePos.Y);
    return ray.Origin+ray.Direction*CFG.MOUSE_RAY_DIST;
end;

local function fireShot()
    if not S.autoKill or not S.akActive then return false end
    local ok=pcall(function()
        local Event=game:GetService("ReplicatedStorage").Shared.CustomPackages.Packet.RemoteEvent
        Event:FireServer(
            (function(bytes)
                local b=buffer.create(#bytes)
                for i=1,#bytes do
                    buffer.writeu8(b,i-1,bytes[i])
                end
                return b
            end)({ 4, 1, 49 })
        )
    end)
    return ok
end

local espFolder=Instance.new("Folder");
espFolder.Name="BoatESP_Folder";
espFolder.Parent=screenGui;

local function espGetOrCreate(plr)
    local d=S.espData[plr];
    if d then return d end;
    d={box=Drawing.new("Square"),name=Drawing.new("Text"),dist=Drawing.new("Text")};
    d.box.Thickness=1;
    d.box.Filled=false;
    d.box.Color=CFG.ESP_BOX;
    d.box.Transparency=1;
    d.name.Center=true;
    d.name.Outline=true;
    d.name.OutlineColor=CFG.ESP_OUTLINE;
    d.name.Color=CFG.ESP_NAME;
    d.name.Size=14;
    d.name.Font=2;
    d.dist.Center=true;
    d.dist.Outline=true;
    d.dist.OutlineColor=CFG.ESP_OUTLINE;
    d.dist.Color=CFG.ESP_DIST;
    d.dist.Size=12;
    d.dist.Font=2;
    S.espData[plr]=d;
    return d;
end;

local function espHideOne(plr)
    local d=S.espData[plr];
    if not d then return end;
    d.box.Visible=false;
    d.name.Visible=false;
    d.dist.Visible=false;
end;

espHideAll=function()
    for _,d in sp(S.espData) do
        d.box.Visible=false;
        d.name.Visible=false;
        d.dist.Visible=false;
    end;
end;

local function espRemove(plr)
    local d=S.espData[plr];
    if not d then return end;
    d.box:Remove();
    d.name:Remove();
    d.dist:Remove();
    S.espData[plr]=nil;
end;

espShow=function() end;

local function getOrCreatePhantomFolder()
    if S.phantomFolder and S.phantomFolder.Parent then return S.phantomFolder end;
    local f=Instance.new("Folder");
    f.Name="__ESP_Phantom";
    f.Parent=workspace;
    S.phantomFolder=f;
    return f;
end;

local function espRemovePredict(plr)
    local d=S.espPredictData[plr];
    if not d then return end;
    if d.line then pcall(function()d.line:Remove()end) end;
    if d.endDot then pcall(function()d.endDot:Remove()end) end;
    if d.startDot then pcall(function()d.startDot:Remove()end) end;
    if d.phantomSel then pcall(function()d.phantomSel:Destroy()end) end;
    if d.phantom and d.phantom.Parent then pcall(function()d.phantom:Destroy()end) end;
    S.espPredictData[plr]=nil;
end;

local function getOrCreatePredictData(plr)
    local d=S.espPredictData[plr];
    if d then return d end;
    d={};
    d.line=Drawing.new("Line");
    d.line.Thickness=CFG.ESP_PREDICT_ARROW_THICKNESS;
    d.line.Color=CFG.ESP_PREDICT_ARROW_COLOR;
    d.line.Transparency=0.85;
    d.line.Visible=false;
    d.endDot=Drawing.new("Circle");
    d.endDot.Radius=CFG.ESP_PREDICT_END_DOT_RADIUS;
    d.endDot.NumSides=20;
    d.endDot.Filled=true;
    d.endDot.Color=CFG.ESP_PREDICT_ARROW_COLOR;
    d.endDot.Transparency=0.7;
    d.endDot.Visible=false;
    d.startDot=Drawing.new("Circle");
    d.startDot.Radius=CFG.ESP_PREDICT_START_DOT_RADIUS;
    d.startDot.NumSides=16;
    d.startDot.Filled=true;
    d.startDot.Color=CFG.ESP_PREDICT_START_DOT_COLOR;
    d.startDot.Transparency=0.6;
    d.startDot.Visible=false;
    local folder=getOrCreatePhantomFolder();
    local p=Instance.new("Part");
    p.Name="__Phantom_"..plr.Name;
    p.Shape=Enum.PartType.Block;
    p.Size=Vector3.new(10,5,20);
    p.Anchored=true;
    p.CanCollide=false;
    p.CanQuery=false;
    p.CanTouch=false;
    p.CastShadow=false;
    p.Material=Enum.Material.Neon;
    p.Color=CFG.ESP_PREDICT_PHANTOM_FILL;
    p.Transparency=CFG.ESP_PREDICT_PHANTOM_TRANSP;
    p.Parent=folder;
    local hl=Instance.new("Highlight");
    hl.Name="__PhantomHL";
    hl.FillColor=CFG.ESP_PREDICT_PHANTOM_FILL;
    hl.OutlineColor=CFG.ESP_PREDICT_PHANTOM_OUTLINE;
    hl.FillTransparency=0.15;
    hl.OutlineTransparency=0;
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;
    hl.Adornee=p;
    hl.Enabled=false;
    hl.Parent=p;
    local selBox=Instance.new("SelectionBox");
    selBox.Name="__PhantomSel";
    selBox.Color3=CFG.ESP_PREDICT_PHANTOM_OUTLINE;
    selBox.LineThickness=0.15;
    selBox.SurfaceTransparency=1;
    selBox.Adornee=p;
    selBox.Transparency=0;
    selBox.Visible=false;
    selBox.Parent=p;
    local bb=Instance.new("BillboardGui");
    bb.Size=UDim2.new(0,220,0,32);
    bb.StudsOffset=Vector3.new(0,0,0);
    bb.AlwaysOnTop=true;
    bb.Adornee=p;
    bb.Parent=p;
    local lbl=Instance.new("TextLabel");
    lbl.Size=UDim2.new(1,0,1,0);
    lbl.BackgroundTransparency=1;
    lbl.TextColor3=CFG.ESP_PREDICT_ARROW_COLOR;
    lbl.TextStrokeTransparency=0;
    lbl.TextStrokeColor3=Color3.fromRGB(0,0,0);
    lbl.Font=Enum.Font.GothamBold;
    lbl.TextSize=14;
    lbl.Text="";
    lbl.Parent=bb;
    d.phantom=p;
    d.phantomHL=hl;
    d.phantomSel=selBox;
    d.phantomLabel=lbl;
    S.espPredictData[plr]=d;
    return d;
end;

local function hidePredictFor(plr)
    local d=S.espPredictData[plr];
    if not d then return end;
    if d.line then d.line.Visible=false end;
    if d.endDot then d.endDot.Visible=false end;
    if d.startDot then d.startDot.Visible=false end;
    if d.phantomHL then d.phantomHL.Enabled=false end;
    if d.phantomSel then d.phantomSel.Visible=false end;
    if d.phantom then d.phantom.Transparency=1 end;
end;

local function getMyMuzzlePos(fallbackPos)
    local myBoat=getMyBoat();
    if myBoat then
        local phys=myBoat:FindFirstChild("Physical");
        if phys then
            local _,muzzle=getCachedBarrels(myBoat,phys);
            if muzzle then return muzzle end;
        end;
    end;
    return fallbackPos or (camera and camera.CFrame.Position) or Vector3.zero;
end;

local function predictTargetPosition(obj,t)
    local rec=S.targetMotion[obj];
    local vel=rec and (rec.velAvg or rec.vel) or obj.AssemblyLinearVelocity;
    if t>CFG.ESP_PREDICT_MAX_T then t=CFG.ESP_PREDICT_MAX_T end;
    return obj.Position+vel*t;
end;

local function drawPredictForPlayer(plr)
    if not S.espAccelPredict then return end;
    if S.autoKill or S.flingAll then hidePredictFor(plr);return end;
    local char=plr.Character;
    if not char then hidePredictFor(plr);return end;
    local hum=char:FindFirstChildOfClass("Humanoid");
    if not hum or hum.Health<=0 then hidePredictFor(plr);return end;
    local tb=getPlayerBoat(char);
    if not tb or not tb.Parent then hidePredictFor(plr);return end;
    local tPhys=tb:FindFirstChild("Physical");
    if not tPhys or not tPhys:IsA("BasePart") then hidePredictFor(plr);return end;
    updateTargetMotion(tPhys,os.clock());
    local muzzlePos=getMyMuzzlePos();
    local targetPos=tPhys.Position;
    local dist=(targetPos-muzzlePos).Magnitude;
    local v=math.max(S.projectileSpeed,1);
    local t=dist/v;
    if t>CFG.ESP_PREDICT_MAX_T then t=CFG.ESP_PREDICT_MAX_T end;
    local predPos=predictTargetPosition(tPhys,t);
    local sp1,on1=camera:WorldToViewportPoint(targetPos);
    local sp2,on2=camera:WorldToViewportPoint(predPos);
    local d=getOrCreatePredictData(plr);
    if on1 and on2 and sp1.Z>0 and sp2.Z>0 then
        d.line.From=Vector2.new(sp1.X,sp1.Y);
        d.line.To=Vector2.new(sp2.X,sp2.Y);
        d.line.Visible=true;
        d.endDot.Position=Vector2.new(sp2.X,sp2.Y);
        d.endDot.Visible=true;
        d.startDot.Position=Vector2.new(sp1.X,sp1.Y);
        d.startDot.Visible=true;
    else
        d.line.Visible=false;
        d.endDot.Visible=false;
        d.startDot.Visible=false;
    end;
    if d.phantom and d.phantom.Parent then
        local bs=getBoatBoundingSize(tb);
        d.phantom.Size=bs;
        d.phantom.CFrame=CFrame.new(predPos)*tPhys.CFrame.Rotation;
        d.phantom.Transparency=CFG.ESP_PREDICT_PHANTOM_TRANSP;
        d.phantomHL.Enabled=true;
        if d.phantomSel then d.phantomSel.Visible=true end;
        local rogueTag="";
        local bumper=getBoatBumper(tb);
        if bumper and isRogueBumper(bumper) then rogueTag=" [ROGUE]" end;
        d.phantomLabel.Text=string.format("%s%s  t=%.2fs",plr.Name,rogueTag,t);
    end;
end;

track(Players.PlayerRemoving:Connect(function(plr)espRemove(plr);espRemovePredict(plr)end));

local function drawESPOne(plr)
    local char=plr.Character;
    if not char then espHideOne(plr);return end;
    local hrp=char:FindFirstChild("HumanoidRootPart");
    local hum=char:FindFirstChildOfClass("Humanoid");
    if not hrp or not hum or hum.Health<=0 then espHideOne(plr);return end;
    local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge;
    local anyV=false;
    local c,hs=hrp.Position,hrp.Size*0.5;
    for sx=-1,1,2 do
        for sy=-1,1,2 do
            for sz=-1,1,2 do
                local wc=c+Vector3.new(sx*hs.X,sy*hs.Y,sz*hs.Z);
                local s,on=camera:WorldToViewportPoint(wc);
                if on and s.Z>0 then
                    anyV=true;
                    if s.X<minX then minX=s.X end;
                    if s.Y<minY then minY=s.Y end;
                    if s.X>maxX then maxX=s.X end;
                    if s.Y>maxY then maxY=s.Y end;
                end;
            end;
        end;
    end;
    local d=espGetOrCreate(plr);
    if not anyV then espHideOne(plr);return end;
    d.box.Position=Vector2.new(minX,minY);
    d.box.Size=Vector2.new(maxX-minX,maxY-minY);
    d.box.Visible=true;
    d.name.Text=plr.Name;
    d.name.Position=Vector2.new((minX+maxX)*0.5,minY-16);
    d.name.Visible=true;
    local myPos=humanoidRootPart and humanoidRootPart.Position or Vector3.new();
    d.dist.Text=string.format("%d studs",math.floor((hrp.Position-myPos).Magnitude));
    d.dist.Position=Vector2.new((minX+maxX)*0.5,maxY+2);
    d.dist.Visible=true;
end;

track(RunService.RenderStepped:Connect(function()
    if S.unexecuted then return end;
    if not S.esp and not S.espAccelPredict then return end;
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=player then
            if S.esp then drawESPOne(plr) else espHideOne(plr) end;
            if S.espAccelPredict then drawPredictForPlayer(plr) else hidePredictFor(plr) end;
        end
    end
end));

local function isRedColor(c)
    if not c then return false end;
    local r,g,b=c.R,c.G,c.B;
    if r<=0.3 then return false end;
    local rg=r-math.max(g,b);
    if rg<CFG.DOTS_RED_THRESHOLD*0.6 then return false end;
    if g+b>r*0.9 then return false end;
    return true;
end;

local function ensureDotsPoolFolder()
    if S.dotsPoolFolder and S.dotsPoolFolder.Parent then return end;
    local folder=Instance.new("Folder");
    folder.Name="__DotsHL_Pool";
    folder.Parent=workspace;
    S.dotsPoolFolder=folder;
end;

local function allocDotSlot(idx)
    local p=Instance.new("Part");
    p.Name="__DotsHL_"..idx;
    p.Shape=Enum.PartType.Ball;
    p.Material=Enum.Material.Neon;
    p.Anchored=true;
    p.CanCollide=false;
    p.CanQuery=false;
    p.CanTouch=false;
    p.CastShadow=false;
    p.Transparency=1;
    p.Color=CFG.DOTS_HL_NORMAL_FILL;
    p.Size=Vector3.new(1,1,1);
    p.Parent=S.dotsPoolFolder;
    local hl=Instance.new("Highlight");
    hl.Name="__DotsHL";
    hl.Adornee=p;
    hl.FillTransparency=1;
    hl.OutlineTransparency=1;
    hl.Enabled=false;
    hl.Parent=p;
    return {part=p,hl=hl};
end;

local function clearDotsPool()
    if S.dotsPoolFolder then pcall(function()S.dotsPoolFolder:Destroy()end) end;
    S.dotsPoolFolder=nil;
    S.dotsPool={};
    S.dotsUsedLast=0;
end;

local function updateDotsHighlight()
    ensureDotsPoolFolder();
    refreshTrajDotsCache(false);
    local dots=S.trajDotsCache;
    local pool=S.dotsPool;
    local used=0;
    for _,d in ipairs(dots) do
        used=used+1;
        local slot=pool[used];
        if not slot then
            if used>CFG.DOTS_POOL_HARD_CAP then break end;
            slot=allocDotSlot(used);
            pool[used]=slot;
        end;
        local p=slot.part;
        local hl=slot.hl;
        if not p or not p.Parent then
            slot=allocDotSlot(used);
            pool[used]=slot;
            p=slot.part;
            hl=slot.hl;
        end;
        local red=isRedColor(d.Color);
        local sz=d.Size;
        local pos=d.Position;
        p.Transparency=0;
        p.Position=pos;
        if red then
            p.Size=sz*CFG.DOTS_HL_RED_SCALE;
            p.Color=CFG.DOTS_HL_RED_FILL;
        else
            p.Size=sz;
            p.Color=CFG.DOTS_HL_NORMAL_FILL;
        end;
        if not hl.Enabled then hl.Enabled=true end;
        if red then
            hl.FillColor=CFG.DOTS_HL_RED_FILL;
            hl.OutlineColor=CFG.DOTS_HL_RED_OUTLINE;
            hl.FillTransparency=0;
            hl.OutlineTransparency=0;
            hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;
        else
            hl.FillColor=CFG.DOTS_HL_NORMAL_FILL;
            hl.OutlineColor=CFG.DOTS_HL_NORMAL_OUTLINE;
            hl.FillTransparency=0.5;
            hl.OutlineTransparency=0.2;
            hl.DepthMode=Enum.HighlightDepthMode.Occluded;
        end;
    end;
    S.dotsUsedLast=used;
    for i=used+1,#pool do
        local slot=pool[i];
        if slot and slot.part and slot.part.Parent then
            slot.part.Transparency=1;
            slot.hl.Enabled=false;
        end;
    end;
end;

local function getBuoysFolder()return workspace:FindFirstChild("Buoys")end;

local function getNearestBuoy(originPos,blacklist)
    local folder=getBuoysFolder();
    if not folder then return nil,math.huge end;
    local now=os.clock();
    local nearest,nd=nil,math.huge;
    for _,child in ipairs(folder:GetChildren()) do
        if child.Name=="CannonballBuoy" then
            local b=child:FindFirstChild("Buoy");
            if b and b:IsA("BasePart") then
                local pos=b.Position;
                local spawnY=S.acBuoySpawnY[b];
                if not spawnY then
                    spawnY=pos.Y;
                    S.acBuoySpawnY[b]=spawnY;
                elseif pos.Y>spawnY then
                    spawnY=pos.Y;
                    S.acBuoySpawnY[b]=spawnY;
                end
                if pos.Y < spawnY-CFG.BUOY_SUNK_DIST then
                    S.acBuoyBlacklist[b]=math.huge;
                end
                local d=(pos-originPos).Magnitude;
                local exp=blacklist and blacklist[b];
                if not(exp and now<exp) and d<nd then
                    nd=d;
                    nearest=b;
                end;
            end;
        end;
    end;
    return nearest,nd;
end;

local function computeAutoCollect(boat,physical,dt,curPos,curYaw)
    if not S.acInited then
        S.acInited=true;
        S.acCurrentBuoy=nil;
        S.acBuoyStartTime=0;
    end;
    local buoy=getNearestBuoy(curPos,S.acBuoyBlacklist);
    if not buoy then return curPos,CFrame.Angles(0,curYaw,0).Rotation end;
    local now=os.clock();
    if S.acCurrentBuoy~=buoy then
        S.acCurrentBuoy=buoy;
        S.acBuoyStartTime=now;
    end;
    if now-S.acBuoyStartTime>CFG.BUOY_TIMEOUT then
        S.acBuoyBlacklist[buoy]=math.huge;
        S.acCurrentBuoy=nil;
        S.acBuoyStartTime=0;
        return curPos,CFrame.Angles(0,curYaw,0).Rotation;
    end;
    local targetPos=buoy.Position;
    local toTarget=targetPos-curPos;
    local dist=toTarget.Magnitude;
    local newYaw=curYaw;
    if dist>0.01 then newYaw=math.atan2(toTarget.X,toTarget.Z) end;
    if dist<0.1 then return curPos,CFrame.Angles(0,newYaw,0).Rotation end;
    local alpha=1-math.exp(-CFG.AUTO_LERP_RATE*dt);
    local step=dist*alpha;
    local maxStep=CFG.AUTO_MAX_SPEED*dt;
    if step>maxStep then step=maxStep end;
    if step>dist then step=dist end;
    local newPos=curPos+toTarget.Unit*step;
    return newPos,CFrame.Angles(0,newYaw,0).Rotation;
end;

local function isTargetAlive(hrp)
    if not hrp or not hrp.Parent then return false end;
    local hum=hrp.Parent:FindFirstChildOfClass("Humanoid");
    return hum and hum.Health>0;
end;

local function isValidAutoKillTarget(hrp)
    if not isTargetAlive(hrp) then return false end;
    local char=hrp.Parent;
    if not char then return false end;
    local tb=getPlayerBoat(char);
    if not tb then return false end;
    if not isEnemyBoat(tb) then return false end;
    return true;
end;

-- ===== GAMEMODE HELPERS =====

local function partFromObj(obj)
    if not obj then return nil end;
    if obj:IsA("BasePart") then return obj end;
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end;
        local ok,cf=pcall(function()return obj:GetPivot()end);
        if ok and cf then
            local p=Instance.new("Part");
            p.Anchored=true;
            p.CanCollide=false;
            p.CanQuery=false;
            p.CanTouch=false;
            p.Transparency=1;
            p.Size=Vector3.new(0.1,0.1,0.1);
            p.CFrame=cf;
            p.Parent=workspace;
            return p;
        end;
    end;
    for _,d in ipairs(obj:GetDescendants()) do
        if d:IsA("BasePart") then return d end;
    end;
    return nil;
end;

local function findCrownPart()
    if character then
        local c3=character:FindFirstChild("Crown",true);
        if c3 then
            local p=partFromObj(c3);
            if p then return p,player,true end;
        end;
    end;
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=player and plr.Character then
            local c2=plr.Character:FindFirstChild("Crown",true);
            if c2 then
                local p=partFromObj(c2);
                if p then return p,plr,false end;
            end;
        end;
    end;
    local c=workspace:FindFirstChild("Crown");
    if c then
        local p=partFromObj(c);
        if p then return p,nil,false end;
    end;
    local bf=workspace:FindFirstChild("Boats");
    if bf then
        local cb=bf:FindFirstChild("Crown",true);
        if cb then
            local p=partFromObj(cb);
            if p then return p,nil,false end;
        end;
    end;
    return nil,nil,false;
end;

local function findHillZonePart()
    local mapFolder=workspace:FindFirstChild("Map");
    if not mapFolder then return nil end;
    for _,city in ipairs(mapFolder:GetChildren()) do
        local gmp=city:FindFirstChild("GamemodeParts");
        if gmp then
            local koth=gmp:FindFirstChild("KingOfTheHill");
            if koth then
                local hz=koth:FindFirstChild("HillZone",true);
                local p=partFromObj(hz) or partFromObj(koth);
                if p then return p end;
            end;
        end;
    end;
    return nil;
end;

local function findBlackTeamCollider()
    local mapFolder=workspace:FindFirstChild("Map");
    if not mapFolder then return nil end;
    for _,place in ipairs(mapFolder:GetChildren()) do
        local tc=place:FindFirstChild("TeamColliders");
        if tc then
            local b=tc:FindFirstChild("Black");
            if b then return b end;
        end;
    end;
    return nil;
end;

local function getMapIslandsCenter()
    local now=os.clock()
    if S.islandsCenter and (now-S.islandsCenterTime)<2.0 then
        return S.islandsCenter
    end
    S.islandsCenterTime=now
    local map=workspace:FindFirstChild("Map")
    if not map then S.islandsCenter=nil return nil end
    local islands=map:FindFirstChild("Islands")
    if not islands then S.islandsCenter=nil return nil end
    local center=nil
    if islands:IsA("Model") then
        local ok,cf=pcall(function()return islands:GetPivot()end)
        if ok and cf then center=cf.Position end
        if not center then
            local ok2,cf2=pcall(function()return islands:GetBoundingBox()end)
            if ok2 and cf2 then center=cf2.Position end
        end
    end
    if not center then
        local sum,n=Vector3.zero,0
        for _,d in ipairs(islands:GetDescendants()) do
            if d:IsA("BasePart") then sum=sum+d.Position;n=n+1 end
        end
        if n>0 then center=sum/n end
    end
    S.islandsCenter=center
    return center
end

local function updateGamemode()
    local now=os.clock();
    if now-S.gamemode.lastCheck<1.0 and S.gamemode.lastCheck>0 then return end;
    S.gamemode.lastCheck=now;
    S.gamemode.mode="none";
    S.gamemode.zonePos=nil;
    S.gamemode.crownPos=nil;
    S.gamemode.crownPart=nil;
    S.gamemode.crownHolder=nil;
    S.gamemode.crownIsOurs=false;
    local hz=findHillZonePart();
    if hz then
        S.gamemode.mode="koth";
        S.gamemode.zonePos=hz.Position;
        return;
    end;
    local crown,holder,isOurs=findCrownPart();
    if crown then
        S.gamemode.mode="crown";
        S.gamemode.crownPart=crown;
        S.gamemode.crownPos=crown.Position;
        S.gamemode.crownHolder=holder;
        S.gamemode.crownIsOurs=isOurs;
    end;
end;

-- ===== END GAMEMODE HELPERS =====

local function pickAutoKillTarget()
    local myPos;
    if S.myBoat and S.myBoat.Parent then
        local phys=S.myBoat:FindFirstChild("Physical");
        if phys and phys:IsA("BasePart") then myPos=phys.Position end;
    end
    if not myPos then
        myPos=humanoidRootPart and humanoidRootPart.Position or Vector3.zero;
    end
    local refPos=myPos;
    local kothZone=nil;
    if S.autoFarm then
        local gm=S.gamemode;
        if gm.mode=="koth" and gm.zonePos then
            refPos=gm.zonePos;
            kothZone=gm.zonePos;
        elseif gm.mode=="crown" and gm.crownPos then
            if not gm.crownIsOurs then
                refPos=gm.crownPos;
            end;
        end;
    end
    local best,bd=nil,math.huge;
    local now=os.clock();
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=player then
            local bl=S.akBlacklist[plr];
            if not(bl and now<bl)then
                local char=plr.Character;
                if char then
                    local hrp=char:FindFirstChild("HumanoidRootPart");
                    local hum=char:FindFirstChildOfClass("Humanoid");
                    if hrp and hum and hum.Health>0 then
                        if isValidAutoKillTarget(hrp) then
                            local isThreat=true;
                            if kothZone and (hrp.Position-kothZone).Magnitude>CFG.KOTH_THREAT_RADIUS then
                                isThreat=false;
                            end
                            if isThreat then
                                local d=(hrp.Position-refPos).Magnitude;
                                if d<bd then bd=d;best=hrp end;
                            end
                        end;
                    end;
                end;
            end;
        end;
    end;
    return best;
end;

local function pickRandomEnemyBoat()
    local candidates={};
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=player then
            if not S.flingedBlacklist[plr] then
                local char=plr.Character;
                if char then
                    local hum=char:FindFirstChildOfClass("Humanoid");
                    if hum and hum.Health>0 then
                        local tb=getPlayerBoat(char);
                        if tb and isEnemyBoat(tb) then
                            local phys=tb:FindFirstChild("Physical");
                            if phys and phys:IsA("BasePart") and phys.Parent then
                                table.insert(candidates,{boat=tb,phys=phys});
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
    if #candidates==0 then return nil end;
    return candidates[math.random(1,#candidates)];
end;

local function computeAKDesiredCF(boat,physical,targetHrp,barrel)
    if not(boat and physical and targetHrp and targetHrp.Parent and barrel)then return nil end;
    local char=targetHrp.Parent;
    local torsoPart=nil;
    for _,name in ipairs({"Torso","UpperTorso","LowerTorso"}) do
        local p=char:FindFirstChild(name);
        if p and p:IsA("BasePart") then torsoPart=p;break end;
    end;
    local torsoPos=(torsoPart and torsoPart.Position) or targetHrp.Position;
    local rec=S.targetMotion[targetHrp];
    local vel=rec and (rec.velAvg or rec.vel) or targetHrp.AssemblyLinearVelocity;
    local speedSps=vel.Magnitude;
    local totalLag=getAutoLagTime();
    S.akTargetSpeed=speedSps;
    S.akTotalLag=totalLag;
    S.akPingHalf=getPingSeconds();
    local dist0=(torsoPos-physical.Position).Magnitude;
    local flightT=dist0/math.max(S.projectileSpeed,1);
    local leadT=flightT*CFG.AK_LEAD_FACTOR;
    local totalT=leadT+totalLag;
    local aimPos=torsoPos+Vector3.new(vel.X*totalT,vel.Y*totalT*0.5,vel.Z*totalT);
    S.akLagCompVec=Vector3.new(vel.X*totalLag,vel.Y*totalLag*0.5,vel.Z*totalLag);

    local look=targetHrp.CFrame.LookVector;
    local fl=Vector3.new(look.X,0,look.Z);
    if fl.Magnitude<0.001 then fl=Vector3.new(0,0,1) else fl=fl.Unit end;
    local desiredBarrelPos=targetHrp.Position-fl*CFG.AK_OFFSET_BEHIND;
    desiredBarrelPos=Vector3.new(desiredBarrelPos.X,targetHrp.Position.Y+CFG.AK_Y_OFFSET,desiredBarrelPos.Z);
    local barrelLocalCF=physical.CFrame:ToObjectSpace(barrel.CFrame);
    local Q=getBarrelAlignQ(barrel);
    local desiredBarrelCF=CFrame.lookAt(desiredBarrelPos,aimPos)*Q;
    local desiredPhysicalCF=desiredBarrelCF*barrelLocalCF:Inverse();
    local dist=(aimPos-desiredBarrelPos).Magnitude;
    return desiredPhysicalCF,dist,tostring(barrel.Name);
end;

local function findVectorForce(physical)
    if not physical then return nil end;
    return physical:FindFirstChild("VectorForce") or physical:FindFirstChildWhichIsA("VectorForce",true);
end;

local function applyLegacySpeedhack(physical,pressingW)
    if not physical or not physical.Parent then return end;
    local vf=findVectorForce(physical);
    if not vf then return end;
    if S.speedhack or S.immediateStop then
        protectKey(vf,"Force");
        protectKey(physical,"AssemblyLinearVelocity");
        protectKey(physical,"Velocity");
        local force;
        if pressingW and S.speedhack then force=Vector3.new(S.currentValue,0,0);
        else force=Vector3.zero end;
        S.legacyPendingVF=vf;
        S.legacyPendingForce=force;
        S.legacyPendingPhys=physical;
        setProtected(vf,"Force",force);
        if S.immediateStop and not pressingW then
            setProtected(physical,"AssemblyLinearVelocity",Vector3.zero);
            setProtected(physical,"Velocity",Vector3.zero);
        end;
    else
        unprotectKey(vf,"Force");
        unprotectKey(physical,"AssemblyLinearVelocity");
        unprotectKey(physical,"Velocity");
        S.legacyPendingVF=nil;
        S.legacyPendingForce=nil;
        S.legacyPendingPhys=nil;
    end;
end;

local function applyLegacyRotationVec(physical,curDir,targetDir)
    if not physical or not physical.Parent then return end;
    if not curDir or not targetDir then return end;
    local root=physical.AssemblyRootPart or physical;
    pcall(function()
        if root:GetNetworkOwner()~=player then root:SetNetworkOwner(player) end;
    end);
    local av=root:FindFirstChild("__LegacyAV");
    if not av then
        av=Instance.new("AngularVelocity");
        av.Name="__LegacyAV";
        av.RelativeTo=Enum.ActuatorRelativeTo.World;
        av.MaxTorque=0;
        av.AngularVelocity=Vector3.zero;
        av.Parent=root;
    end;
    local cd=curDir;
    local td=targetDir;
    if cd.Magnitude<1e-5 then cd=Vector3.new(0,0,-1) else cd=cd.Unit end;
    if td.Magnitude<1e-5 then td=Vector3.new(0,0,-1) else td=td.Unit end;
    local axis=cd:Cross(td);
    local sinA=axis.Magnitude;
    local cosA=math.clamp(cd:Dot(td),-1,1);
    local angle=math.atan2(sinA,cosA);
    local angVel;
    if angle<1e-4 then
        angVel=Vector3.zero;
    elseif sinA<1e-5 then
        local perp=cd:Cross(Vector3.new(0,1,0));
        if perp.Magnitude<1e-3 then perp=cd:Cross(Vector3.new(1,0,0)) end;
        angVel=perp.Unit*CFG.LEGACY_ROT_RATE_MAX;
    else
        local rate=math.clamp(angle*CFG.LEGACY_ROT_KP,-CFG.LEGACY_ROT_RATE_MAX,CFG.LEGACY_ROT_RATE_MAX);
        angVel=axis.Unit*rate;
    end;
    protectKey(av,"AngularVelocity");
    protectKey(av,"MaxTorque");
    setProtected(av,"MaxTorque",CFG.LEGACY_AV_MAX_TORQUE);
    setProtected(av,"AngularVelocity",angVel);
    S.legacyPendingAV=av;
    S.legacyPendingAngVel=angVel;
    S.legacyPendingPhys=root;
end;

local function clearLegacyRotation(physical)
    if not physical then return end;
    local root=physical.AssemblyRootPart or physical;
    local av=root:FindFirstChild("__LegacyAV");
    if av then
        pcall(function()av.MaxTorque=0 end);
        pcall(function()av.AngularVelocity=Vector3.zero end);
        unprotectKey(av,"AngularVelocity");
        unprotectKey(av,"MaxTorque");
    end;
    S.legacyPendingAV=nil;
    S.legacyPendingAngVel=nil;
end;

local function tickAim(boat,physical,curPos,now,dt,inYaw,inPitch)
    if not(S.aimbot and UIS:IsKeyDown(Enum.KeyCode.Q))then
        if S.pitchBias>0 then
            S.pitchBias=math.max(0,S.pitchBias-math.rad(CFG.PITCH_BIAS_DECAY_RATE)*dt);
        elseif S.pitchBias<0 then
            S.pitchBias=math.min(0,S.pitchBias+math.rad(CFG.PITCH_BIAS_DECAY_RATE)*dt);
        end;
        if S.lagBias>0 then
            S.lagBias=math.max(0,S.lagBias-CFG.AK_LAG_BIAS_DECAY*dt);
        elseif S.lagBias<0 then
            S.lagBias=math.min(0,S.lagBias+CFG.AK_LAG_BIAS_DECAY*dt);
        end;
        S.aimCachedHrp=nil;
        S.aimCachedYaw=nil;
        S.aimCachedPitch=nil;
        S.aimCacheAge=999;
        return nil,inYaw,inPitch;
    end;
    S.aimCacheAge=S.aimCacheAge+1;
    if S.aimCacheAge>=CFG.AIM_HEAVY_INTERVAL then
        S.aimCacheAge=0;
        local tChar,aimPos,hrp=getMouseClosestPlayerWithAim();
        if not(tChar and aimPos and hrp)then
            updateHighlight(nil);
            S.aimCachedHrp=nil;
            S.aimCachedYaw=nil;
            S.aimCachedPitch=nil;
            return nil,inYaw,inPitch;
        end;
        local tb=getPlayerBoat(tChar);
        if tb and not isEnemyBoat(tb)then
            updateHighlight(nil);
            S.aimCachedHrp=nil;
            S.aimCachedYaw=nil;
            S.aimCachedPitch=nil;
            return nil,inYaw,inPitch;
        end;
        S.aimCachedHrp=hrp;
        updateHighlight(hrp);
        S.lastAimTarget=hrp;
        updateTargetMotion(hrp,now);
        local _,muzzleAvg,mLocal,wd=getCachedBarrels(boat,physical);
        local originPos=muzzleAvg or curPos;
        if mLocal and mLocal.Y>CFG.AIM_BARREL_UP_THRESHOLD then S.aimBiasInvert=true
        else S.aimBiasInvert=false end;
        if not CFG.GRAVITY_OVERRIDE and wd and (S.frameCounter%CFG.CALIB_INTERVAL==0)then
            calibrateGEffFromDots(originPos,wd,S.projectileSpeed);
        end;
        local vg=computeVelGain(hrp,aimPos,originPos);
        local maxT=computeMaxT(originPos,aimPos,S.projectileSpeed);
        local sDist=(aimPos-originPos).Magnitude;
        local gEff=getGEffForDistance(sDist);
        local ft=solveFlightTime(originPos,aimPos,hrp,S.projectileSpeed,gEff,maxT,vg);
        local wdT;
        if ft then
            wdT=dirForTime(originPos,aimPos,hrp,ft,S.projectileSpeed,gEff,vg);
        else
            local toT=aimPos-originPos;
            local fl=Vector3.new(toT.X,0,toT.Z);
            if fl.Magnitude>0.01 then
                local fu=fl.Unit;
                wdT=(fu*math.cos(math.rad(45))+Vector3.new(0,math.sin(math.rad(45)),0)).Unit;
                ft=maxT;
            end;
        end;
        if wdT then
            local tYaw=math.atan2(wdT.X,wdT.Z);
            local bTP=math.asin(math.clamp(wdT.Y,-1,1));
            local tPitch=bTP+S.pitchBias;
            tPitch=math.clamp(tPitch,-math.rad(85),math.rad(85));
            S.aimCachedYaw=tYaw;
            S.aimCachedPitch=tPitch;
        end;
        local predAim=aimPos;
        if ft then predAim=targetPosAt(hrp,aimPos,originPos,ft,vg) or aimPos end;
        local rec=S.targetMotion[hrp];
        if rec then
            local vLead=rec.velAvg or rec.vel;
            local lagT=getAutoLagTime();
            predAim=predAim+vLead*lagT;
        end;
        local minD,dc,lB,lS,irl,_,ld,ad=evaluateTrajectory(predAim,originPos,hrp);
        if minD then
            local maxHR=math.max(CFG.TRAJ_HIT_RADIUS,CFG.TRAJ_HIT_RADIUS_BOAT);
            local invTag=S.aimBiasInvert and "^" or "";
            if minD<CFG.TRAJ_HIT_RADIUS then
                hitIndicator.Text=string.format("HIT(%d) t=%.1f v=%d bias=%.1f%s°",dc,ft or 0,math.floor(S.projectileSpeed),math.deg(S.pitchBias),invTag);
                hitIndicator.TextColor3=Color3.fromRGB(0,255,100);
            elseif minD<maxHR then
                hitIndicator.Text=string.format("HIT-BOAT d=%.0f bias=%.1f%s°",minD,math.deg(S.pitchBias),invTag);
                hitIndicator.TextColor3=Color3.fromRGB(150,255,100);
            elseif minD<CFG.TRAJ_CLOSE_RADIUS then
                hitIndicator.Text=string.format("CLOSE d=%.0f bias=%.1f%s°",minD,math.deg(S.pitchBias),invTag);
                hitIndicator.TextColor3=Color3.fromRGB(255,220,60);
            else
                local tag="?";
                if lS then tag="SHORT" elseif lB then tag="LONG" end;
                if not irl then tag=tag.."*" end;
                hitIndicator.Text=string.format("MISS d=%.0f %s bias=%.1f%s° lagBias=%.2f",minD,tag,math.deg(S.pitchBias),invTag,S.lagBias);
                hitIndicator.TextColor3=Color3.fromRGB(255,70,70);
            end;
            if lS then
                S.lagShortStreak=S.lagShortStreak+1;
                S.lagLongStreak=0;
            elseif lB then
                S.lagLongStreak=S.lagLongStreak+1;
                S.lagShortStreak=0;
            else
                S.lagShortStreak=0;
                S.lagLongStreak=0;
            end;
            if S.lagShortStreak>=CFG.AK_LAG_BIAS_AGREE_FRAMES then
                S.lagBias=math.min(S.lagBias+CFG.AK_LAG_BIAS_STEP,CFG.AK_LAG_BIAS_MAX);
                S.lagShortStreak=0;
            end;
            if S.lagLongStreak>=CFG.AK_LAG_BIAS_AGREE_FRAMES then
                S.lagBias=math.max(S.lagBias-CFG.AK_LAG_BIAS_STEP,-CFG.AK_LAG_BIAS_MAX);
                S.lagLongStreak=0;
            end;
            if lS then S.calibShortStreak=S.calibShortStreak+1;S.calibLongStreak=0;
            elseif lB then S.calibLongStreak=S.calibLongStreak+1;S.calibShortStreak=0;
            else S.calibShortStreak=0;S.calibLongStreak=0 end;
            if CFG.AUTO_CALIBRATE and now-S.lastCalibTime>CFG.TRAJ_CALIB_COOLDOWN then
                local dS=S.calibShortStreak>=CFG.TRAJ_CALIB_AGREE_FRAMES;
                local dL=S.calibLongStreak>=CFG.TRAJ_CALIB_AGREE_FRAMES;
                if (dS or dL)and ad and ad>5 then
                    S.lastCalibTime=now;
                    local sR=math.rad(CFG.PITCH_BIAS_STEP_DEG);
                    local mR=math.rad(CFG.PITCH_BIAS_MAX_DEG);
                    local sign=S.aimBiasInvert and -1 or 1;
                    if dS then S.pitchBias=math.clamp(S.pitchBias+sign*sR,-mR,mR) end;
                    if dL then S.pitchBias=math.clamp(S.pitchBias-sign*sR,-mR,mR) end;
                    S.calibShortStreak=0;
                    S.calibLongStreak=0;
                    for k in sp(S.flightTimeCache) do S.flightTimeCache[k]=nil end;
                end;
            end;
        else
            hitIndicator.Text=string.format("no dots v=%d bias=%.1f° lagBias=%.2f",math.floor(S.projectileSpeed),math.deg(S.pitchBias),S.lagBias);
            hitIndicator.TextColor3=Color3.fromRGB(180,180,180);
            S.calibShortStreak=0;
            S.calibLongStreak=0;
            S.lagShortStreak=0;
            S.lagLongStreak=0;
        end;
    end;
    local newYaw,newPitch=inYaw,inPitch;
    if S.aimCachedYaw and S.aimCachedPitch then
        local dYaw=S.aimCachedYaw-newYaw;
        while dYaw>math.pi do dYaw=dYaw-2*math.pi end;
        while dYaw<-math.pi do dYaw=dYaw+2*math.pi end;
        if math.abs(dYaw)<=CFG.SNAP_YAW then newYaw=S.aimCachedYaw
        else newYaw=newYaw+math.clamp(dYaw,-CFG.MAX_YAW_RATE*dt,CFG.MAX_YAW_RATE*dt) end;
        local dP=S.aimCachedPitch-newPitch;
        if math.abs(dP)<=CFG.SNAP_PITCH then newPitch=S.aimCachedPitch
        else newPitch=newPitch+math.clamp(dP,-CFG.MAX_PITCH_RATE*dt,CFG.MAX_PITCH_RATE*dt) end;
    end;
    return "aim",newYaw,newPitch;
end;

local function tickMain(dt,now)
    local pressingW=UIS:IsKeyDown(Enum.KeyCode.W);
    local pressingA=UIS:IsKeyDown(Enum.KeyCode.A);
    local pressingD=UIS:IsKeyDown(Enum.KeyCode.D);
    local boat=getMyBoat();
    if not boat then
        hitIndicator.Text="";
        updateHighlight(nil);
        if S.akActive then
            S.akActive=false;
            S.akTarget=nil;
            S.akBoat=nil;
            S.akDesiredCF=setmetatable({},{__mode="k"});
        end;
        S.flingActive=false;
        return;
    end;
    local physical=boat:FindFirstChild("Physical");
    if not physical or not physical:IsA("BasePart") then
        hitIndicator.Text="";
        updateHighlight(nil);
        return;
    end;
    updateMyBoat(now);
    S.projectileSpeed=getProjectileSpeedForBoat(boat,physical);
    local isLegacy=(S.speedhackMode=="legacy");

    if S.flingAll then
        S.acting=true;
        S.flingActive=true;
        S.flingBoat=boat;
        return;
    end;
    if not S.flingAll and S.flingActive then
        S.flingActive=false;
        S.flingTarget=nil;
        local root=physical.AssemblyRootPart or physical;
        local fav=root:FindFirstChild("__FlingAV");
        if fav then pcall(function()fav:Destroy()end) end;
        restoreBoatCollisions(physical);
        restoreConstraints(physical);
        updateHighlight(nil);
        hitIndicator.Text="";
    end;

    if S.autoKill then
        S.acting=true;
        S.akActive=true;
        S.akBoat=boat;
        return;
    end;
    if not S.autoKill and S.akActive then
        S.akActive=false;
        S.akTarget=nil;
        S.akBoat=nil;
        S.akDesiredCF[physical]=nil;
        restoreBoatCollisions(physical);
        updateHighlight(nil);
        hitIndicator.Text="";
    end;

    local barrels=getCachedBarrels(boat,physical);
    local barrel=barrels[1];
    local curDir=nil;
    local refOriginPos=physical.Position;
    if barrel then
        curDir=getBarrelWorldDirFor(barrel);
        if not curDir then curDir=physical.CFrame.LookVector end;
        local bp=getMuzzlePosFor(barrel);
        if bp then refOriginPos=bp end;
    end;
    if not curDir then curDir=physical.CFrame.LookVector end;
    curDir=curDir.Unit;

    local curPos=physical.Position;
    S.motionPos[physical]=curPos;
    local rs=ensureRotState(physical);
    local realLook=physical.CFrame.LookVector;
    local curRealYaw=math.atan2(realLook.X,realLook.Z);
    local curRealPitch=math.asin(math.clamp(realLook.Y,-1,1));
    local newPos=curPos;
    local newYaw,newPitch;
    local rotSystemUsed=nil;

    if S.autoCollect then
        hitIndicator.Text="";
        updateHighlight(nil);
        local curRefYaw=math.atan2(curDir.X,curDir.Z);
        local np,rot=computeAutoCollect(boat,physical,dt,curPos,curRefYaw);
        newPos=np;
        local lv=rot.LookVector;
        newYaw=math.atan2(lv.X,lv.Z);
        newPitch=0;
        rotSystemUsed="auto";
    else
        if S.acInited then
            S.acInited=false;
            S.acCurrentBuoy=nil;
            S.acBuoyStartTime=0;
        end;
        local curRefYaw=math.atan2(curDir.X,curDir.Z);
        local curRefPitch=math.asin(math.clamp(curDir.Y,-1,1));
        newYaw=curRefYaw;
        newPitch=curRefPitch;
        rotSystemUsed,newYaw,newPitch=tickAim(boat,physical,curPos,now,dt,newYaw,newPitch);
        if not rotSystemUsed and S.aimWasActiveLastFrame then
            hitIndicator.Text="";
            S.calibShortStreak=0;
            S.calibLongStreak=0;
            updateHighlight(nil);
            if S.lastAimTarget then S.flightTimeCache[S.lastAimTarget]=nil end;
            S.lastAimTarget=nil;
        end;
        S.aimWasActiveLastFrame=(rotSystemUsed=="aim");
        if not rotSystemUsed and S.mouseControl then
            local mp=getMouseWorldPoint(physical);
            if mp then
                local originForMouse;
                if isLegacy then
                    originForMouse=physical.Position;
                else
                    originForMouse=refOriginPos;
                end;
                local d=mp-originForMouse;
                if d.Magnitude>0.01 then
                    rotSystemUsed="mouse";
                    newYaw=math.atan2(d.X,d.Z);
                    newPitch=math.asin(math.clamp(d.Y/math.max(d.Magnitude,1e-6),-1,1));
                end;
            end;
        end;
        if not rotSystemUsed and S.fastRot then
            rotSystemUsed="av";
            if pressingA and not pressingD then
                newYaw=curRefYaw+CFG.FAST_ROT_RATE*dt;
                newPitch=curRefPitch;
            elseif pressingD and not pressingA then
                newYaw=curRefYaw-CFG.FAST_ROT_RATE*dt;
                newPitch=curRefPitch;
            end;
        end;
    end;

    S.acting=(rotSystemUsed~=nil) or S.autoCollect or (S.speedhack and pressingW) or S.immediateStop;
    if S.acting then
        pcall(function()
            if physical:GetNetworkOwner()~=player then physical:SetNetworkOwner(player) end;
        end);
    end;

    if isLegacy then
        restoreConstraints(physical);
        if rotSystemUsed and rotSystemUsed~="auto" then
            disableAngularConstraints(physical);
            local cp=math.cos(newPitch);
            local targetDir=Vector3.new(cp*math.sin(newYaw),math.sin(newPitch),cp*math.cos(newYaw));
            local hullLook=physical.CFrame.LookVector;
            applyLegacyRotationVec(physical,hullLook,targetDir);
        else
            restoreAngularConstraints(physical);
            clearLegacyRotation(physical);
        end;
        applyLegacySpeedhack(physical,pressingW);
        local yaw=math.atan2(curDir.X,curDir.Z);
        local pitch=math.asin(math.clamp(curDir.Y,-1,1));
        rs.yaw=yaw;
        rs.pitch=pitch;
        S.motionPos[physical]=physical.Position;
    else
        restoreAngularConstraints(physical);
        restoreConstraints(physical);
        S.legacyPendingVF=nil;
        S.legacyPendingForce=nil;
        S.legacyPendingPhys=nil;
        if S.legacyPendingAV then
            local av=S.legacyPendingAV;
            if av and av.Parent then
                pcall(function()av.MaxTorque=0 end);
                pcall(function()av.AngularVelocity=Vector3.zero end);
                unprotectKey(av,"AngularVelocity");
                unprotectKey(av,"MaxTorque");
            end;
        end;
        S.legacyPendingAV=nil;
        S.legacyPendingAngVel=nil;

        local finalYaw, finalPitch;
        if rotSystemUsed then
            finalYaw, finalPitch = newYaw, newPitch;
        else
            local hl = physical.CFrame.LookVector;
            finalYaw = math.atan2(hl.X, hl.Z);
            finalPitch = math.asin(math.clamp(hl.Y, -1, 1));
        end;

        local moveSpeed=0;
        local controlsCF=S.autoCollect or (rotSystemUsed~=nil) or (S.speedhack and pressingW);

        if controlsCF then
            disableBoatCollisions(physical);
            disableConstraints(physical);
            protectKey(physical,"CFrame");
        else
            restoreBoatCollisions(physical);
        end;

        if S.speedhack and pressingW then moveSpeed=S.currentValue/CFG.SPEED_DIVISOR end;
        if moveSpeed>0 then
            newPos=newPos+Vector3.new(math.sin(finalYaw),0,math.cos(finalYaw))*moveSpeed*dt;
        end;
        if controlsCF then
            rs.yaw=finalYaw;
            rs.pitch=finalPitch;
            local cp=math.cos(finalPitch);
            local dir=Vector3.new(cp*math.sin(finalYaw),math.sin(finalPitch),cp*math.cos(finalYaw));
            local up=(math.abs(dir.Y)>0.99) and Vector3.new(0,0,1) or Vector3.new(0,1,0);
            S.motionPos[physical]=newPos;
            S.pendingCF={physical=physical,cf=CFrame.lookAt(newPos,newPos+dir,up)};
        else
            S.motionPos[physical]=physical.Position;
        end;
    end;
end;

setAutoFarm=function(enabled)
    S.autoFarm=enabled
    autoFarmBtn.Text="Auto Farm: "..(enabled and "ON" or "OFF")
    autoFarmBtn.BackgroundColor3=enabled and Color3.fromRGB(0,150,80) or Color3.fromRGB(70,70,70)
    if enabled then
        frame.Visible=false
        if not S.autoKill then S.autoKill=true end
        if autoKillBtnRef then
            autoKillBtnRef.Text="Auto Kill (BEHIND): ON"
            autoKillBtnRef.BackgroundColor3=Color3.fromRGB(0,150,80)
        end
        updateGamemode()
        S.afZoneEnterTime=0
        S.afFarmMode="idle"
        if not S.autoFarmGui then
            S.autoFarmGui=Instance.new("ScreenGui")
            S.autoFarmGui.Name="AutoFarmGui"
            S.autoFarmGui.ResetOnSpawn=false
            S.autoFarmGui.Parent=player:WaitForChild("PlayerGui")
            local square=Instance.new("TextButton")
            square.Size=UDim2.new(0,240,0,100)
            square.Position=UDim2.new(0.5,-120,0.5,-50)
            square.BackgroundColor3=Color3.fromRGB(40,40,40)
            square.Text="Auto Farm Active!\nBy EXVS"
            square.TextColor3=Color3.fromRGB(255,255,255)
            square.TextSize=20
            square.Font=Enum.Font.GothamBold
            square.Parent=S.autoFarmGui
            square.MouseButton1Click:Connect(function()
                if setAutoFarm then setAutoFarm(false) end
            end)
            S.autoFarmSquare=square
        else
            S.autoFarmGui.Enabled=true
        end
    else
        frame.Visible=true
        if S.autoKill then
            S.autoKill=false
            if autoKillBtnRef then
                autoKillBtnRef.Text="Auto Kill (BEHIND): OFF"
                autoKillBtnRef.BackgroundColor3=Color3.fromRGB(70,70,70)
            end
            S.akActive=false
            S.akTarget=nil
            S.akBoat=nil
            S.akDesiredCF=setmetatable({},{__mode="k"})
            S.akLastFire=0
            S.akTargetSince=0
            updateHighlight(nil)
        end
        S.afZoneEnterTime=0
        S.afFarmMode="idle"
        if S.autoFarmGui then
            S.autoFarmGui.Enabled=false
        end
    end
end

track(RunService.Heartbeat:Connect(function(dt)
    if S.unexecuted then return end;
    if dt<=0 then dt=1/60 end;
    S.frameCounter=S.frameCounter+1;
    tickMain(dt,os.clock());
end));

track(RunService.Heartbeat:Connect(function(dt)
    if S.unexecuted or not S.autoFarm then return end
    local now=os.clock()
    if now-S.lastFarmCheck<CFG.AUTOFARM_CHECK_INTERVAL then return end
    S.lastFarmCheck=now
    if not getMyBoat() then
        if findBlackTeamCollider() then
            pcall(function()
                local Event=game:GetService("ReplicatedStorage").Shared.CustomPackages.Packet.RemoteEvent
                Event:FireServer(
                    (function(bytes)
                        local b=buffer.create(#bytes)
                        for i=1,#bytes do
                            buffer.writeu8(b,i-1,bytes[i])
                        end
                        return b
                    end)({ 27, 6, 82, 111, 103, 117, 101, 115 })
                )
            end)
        end
        pcall(function()
            local Event=game:GetService("ReplicatedStorage").Shared.CustomPackages.Packet.RemoteEvent
            Event:FireServer(
                (function(bytes)
                    local b=buffer.create(#bytes)
                    for i=1,#bytes do
                        buffer.writeu8(b,i-1,bytes[i])
                    end
                    return b
                end)({ 14 })
            )
        end)
    end
end))

-- FLING passive blacklist tracker (doesn't touch fling logic itself)
local flingCheckAccum=0
track(RunService.Heartbeat:Connect(function(dt)
    if S.unexecuted then return end
    if not S.flingAll then return end
    flingCheckAccum=flingCheckAccum+dt
    if flingCheckAccum<CFG.FLING_CHECK_INTERVAL then return end
    flingCheckAccum=0
    local islandsCenter=getMapIslandsCenter()
    if not islandsCenter then return end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=player then
            local char=plr.Character
            if char then
                local hrp=char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d=(hrp.Position-islandsCenter).Magnitude
                    if d>CFG.FLING_MAP_DIST then
                        S.flingedBlacklist[plr]=true
                    elseif S.flingedBlacklist[plr] and d<CFG.FLING_MAP_RETURN_DIST then
                        S.flingedBlacklist[plr]=nil
                    end
                end
            end
        end
    end
end))

local lagDisplayAccum=0
track(RunService.Heartbeat:Connect(function(dt)
    if S.unexecuted then return end;
    lagDisplayAccum=lagDisplayAccum+dt;
    if lagDisplayAccum<0.2 then return end;
    lagDisplayAccum=0;
    if S.lagLabel then
        local ping=getPingSeconds();
        local lag=getAutoLagTime();
        local gmTag=S.gamemode.mode~="none" and (" ["..string.upper(S.gamemode.mode).."]") or "";
        S.lagLabel.Text=string.format("AUTO-LAG: ping=%dms lag=%dms bias=%+dms%s",
            math.floor(ping*1000),math.floor(lag*1000),math.floor(S.lagBias*1000),gmTag);
    end;
end));

RunService:BindToRenderStep("LegacyEnforce",199,function()
    if S.unexecuted then return end;
    if S.legacyPendingVF and S.legacyPendingVF.Parent and S.legacyPendingForce then
        S.writing[S.legacyPendingVF]=true;
        pcall(function()S.legacyPendingVF.Force=S.legacyPendingForce end);
        S.writing[S.legacyPendingVF]=false;
    end;
    if S.legacyPendingAV and S.legacyPendingAV.Parent and S.legacyPendingAngVel then
        S.writing[S.legacyPendingAV]=true;
        pcall(function()
            S.legacyPendingAV.MaxTorque=CFG.LEGACY_AV_MAX_TORQUE;
            S.legacyPendingAV.AngularVelocity=S.legacyPendingAngVel;
        end);
        S.writing[S.legacyPendingAV]=false;
        local root=S.legacyPendingAV.Parent;
        if root and root:IsA("BasePart") then
            S.writing[root]=true;
            pcall(function()
                root.AssemblyAngularVelocity=S.legacyPendingAngVel;
            end);
            S.writing[root]=false;
        end;
    end;
end);

RunService:BindToRenderStep("DotsHL",203,function()
    if S.unexecuted or not S.dotsHighlight then return end;
    updateDotsHighlight();
end);

RunService:BindToRenderStep("CFrameLock",201,function()
    if S.unexecuted then return end;

    -- FLING ALL: original working version (no interference from blacklist)
    if S.flingAll and S.flingActive then
        local now=os.clock();
        local boat=S.flingBoat;
        if not(boat and boat.Parent)then boat=getMyBoat();S.flingBoat=boat end;
        if boat then
            local physical=boat:FindFirstChild("Physical");
            if physical and physical:IsA("BasePart") then
                local root=physical.AssemblyRootPart or physical;
                pcall(function()
                    if physical:GetNetworkOwner()~=player then physical:SetNetworkOwner(player) end;
                end);
                pcall(function()
                    if root:GetNetworkOwner()~=player then root:SetNetworkOwner(player) end;
                end);
                disableBoatCollisions(physical);
                disableConstraints(physical);
                protectKey(physical,"CFrame");
                protectKey(physical,"AssemblyLinearVelocity");
                protectKey(physical,"Velocity");

                if not S.flingTarget or not S.flingTarget.phys or not S.flingTarget.phys.Parent then
                    S.flingTarget=pickRandomEnemyBoat();
                    S.flingStartTime=now;
                end;
                local target=S.flingTarget;
                if now-S.flingStartTime>CFG.FLING_DURATION then
                    S.flingTarget=pickRandomEnemyBoat();
                    S.flingStartTime=now;
                    target=S.flingTarget;
                end;

                if target and target.phys and target.phys.Parent then
                    local tPos=target.phys.Position;
                    local newPos=tPos;
                    local lookDir=tPos-physical.Position;
                    if lookDir.Magnitude<0.01 then lookDir=Vector3.new(0,0,1) end;
                    local newCF=CFrame.lookAt(newPos,newPos+lookDir.Unit);
                    writeCFrameDirect(physical,newCF);
                    S.motionPos[physical]=newPos;
                    pcall(function()physical.AssemblyLinearVelocity=Vector3.zero end);
                    pcall(function()physical.Velocity=Vector3.zero end);

                    local spin=Vector3.new(CFG.FLING_SPIN_VEL,CFG.FLING_SPIN_VEL,CFG.FLING_SPIN_VEL);
                    local fav=root:FindFirstChild("__FlingAV");
                    if not fav then
                        fav=Instance.new("AngularVelocity");
                        fav.Name="__FlingAV";
                        fav.RelativeTo=Enum.ActuatorRelativeTo.World;
                        fav.MaxTorque=CFG.LEGACY_AV_MAX_TORQUE;
                        fav.AngularVelocity=spin;
                        fav.Parent=root;
                    else
                        pcall(function()fav.MaxTorque=CFG.LEGACY_AV_MAX_TORQUE;fav.AngularVelocity=spin end);
                    end;
                    pcall(function()root.AssemblyAngularVelocity=spin end);
                    pcall(function()physical.AssemblyAngularVelocity=spin end);

                    local tPlr=Players:GetPlayerFromCharacter(target.phys.Parent);
                    local flingedTag=(tPlr and S.flingedBlacklist[tPlr]) and " [FLINGED]" or "";
                    local name=target.phys.Parent and target.phys.Parent.Name or "?";
                    local rem=CFG.FLING_DURATION-(now-S.flingStartTime);
                    hitIndicator.Text=string.format("FLING->%s%s (%.1fs) INSIDE+SPIN",name,flingedTag,rem);
                    hitIndicator.TextColor3=Color3.fromRGB(255,80,255);
                else
                    hitIndicator.Text="FLING: no target";
                    hitIndicator.TextColor3=Color3.fromRGB(180,180,180);
                end;
            end;
        end;
        return;
    end;

    if S.autoKill and S.akActive then
        local now=os.clock();
        updateGamemode();
        local boat=S.akBoat;
        if not(boat and boat.Parent)then boat=getMyBoat();S.akBoat=boat end;
        if boat then
            local physical=boat:FindFirstChild("Physical");
            if physical and physical:IsA("BasePart") then
                pcall(function()
                    if physical:GetNetworkOwner()~=player then physical:SetNetworkOwner(player) end;
                end);
                local barrels=getCachedBarrels(boat,physical);
                local barrel=barrels[1];
                if barrel and boat.PrimaryPart~=barrel then pcall(function()boat.PrimaryPart=barrel end) end;
                local targetHrp=S.akTarget;
                if targetHrp and not isValidAutoKillTarget(targetHrp)then
                    targetHrp=nil;
                    S.akTarget=nil;
                end;
                if targetHrp then
                    local tPlayer=Players:GetPlayerFromCharacter(targetHrp.Parent);
                    if tPlayer and (now-S.akTargetSince)>CFG.AK_TIMEOUT then
                        local count=(S.akBlacklistCount[tPlayer] or 0)+1
                        S.akBlacklistCount[tPlayer]=count
                        S.akBlacklist[tPlayer]=now+CFG.AK_BLACKLIST_TIME*(CFG.AK_BLACKLIST_MULT^(count-1))
                        targetHrp=nil;
                        S.akTarget=nil;
                        S.akTargetSince=now;
                    end;
                end;
                if not targetHrp then
                    targetHrp=pickAutoKillTarget();
                    S.akTarget=targetHrp;
                    S.akTargetSince=now;
                end;
                if targetHrp and barrel then
                    S.afFarmMode="idle";
                    S.afZoneEnterTime=0;
                    disableBoatCollisions(physical);
                    disableConstraints(physical);
                    protectKey(physical,"CFrame");
                    updateHighlight(targetHrp);
                    local desiredCF,dist,faceName=computeAKDesiredCF(boat,physical,targetHrp,barrel);
                    if desiredCF then
                        S.akDesiredCF[physical]=desiredCF;
                        writeCFrameDirect(physical,desiredCF);
                        S.motionPos[physical]=desiredCF.Position;
                        local rs=ensureRotState(physical);
                        local lv=desiredCF.LookVector;
                        rs.yaw=math.atan2(lv.X,lv.Z);
                        rs.pitch=math.asin(math.clamp(lv.Y,-1,1));
                        hitIndicator.Text=string.format("AK:%s d=%.0f spd=%.0f lag=%dms",
                            targetHrp.Parent.Name,dist,S.akTargetSpeed,math.floor(S.akTotalLag*1000));
                        hitIndicator.TextColor3=Color3.fromRGB(255,80,80);
                        if now-S.akLastFire>=CFG.AK_FIRE_DELAY then
                            S.akLastFire=now;
                            fireShot();
                        end;
                    end;
                else
                    updateHighlight(nil);
                    if S.autoFarm then
                        local gm=S.gamemode;
                        local holdPos=nil;
                        local collectBalls=false;
                        local statusText="AUTO FARM";

                        if gm.mode=="koth" and gm.zonePos then
                            if S.afFarmMode=="collect" then
                                collectBalls=true;
                                statusText="AUTO FARM: BALLS (KOTH)";
                            else
                                local distToZone=(physical.Position-gm.zonePos).Magnitude;
                                if distToZone<CFG.KOTH_ZONE_RADIUS then
                                    if S.afZoneEnterTime==0 then S.afZoneEnterTime=now end
                                else
                                    S.afZoneEnterTime=0
                                end
                                if S.afZoneEnterTime>0 and (now-S.afZoneEnterTime)>=CFG.KOTH_IDLE_BEFORE_BALLS then
                                    S.afFarmMode="collect";
                                    collectBalls=true;
                                    statusText="AUTO FARM: BALLS (KOTH)";
                                else
                                    holdPos=gm.zonePos
                                    local rem=CFG.KOTH_IDLE_BEFORE_BALLS-(S.afZoneEnterTime>0 and (now-S.afZoneEnterTime) or 0)
                                    if rem<0 then rem=0 end
                                    statusText=string.format("AUTO FARM: HOLD HILL (%.0fs)",rem)
                                end
                            end
                        elseif gm.mode=="crown" and gm.crownPos then
                            if gm.crownIsOurs then
                                collectBalls=true
                                statusText="AUTO FARM: BALLS (crown ours)"
                            else
                                holdPos=gm.crownPos
                                statusText="AUTO FARM: HOLD CROWN"
                            end
                        else
                            collectBalls=true
                            statusText="AUTO FARM: BALLS (no work)"
                        end

                        local didCollect=false;
                        if collectBalls then
                            local nearestBuoy=getNearestBuoy(physical.Position,S.acBuoyBlacklist);
                            if nearestBuoy then
                                disableBoatCollisions(physical);
                                disableConstraints(physical);
                                protectKey(physical,"CFrame");
                                local curDir=getBarrelWorldDirFor(barrel) or physical.CFrame.LookVector;
                                local curYaw=math.atan2(curDir.X,curDir.Z);
                                local np,rot=computeAutoCollect(boat,physical,CFG.FARM_COLLECT_DT,physical.Position,curYaw);
                                local lv=rot.LookVector;
                                local nCF=CFrame.lookAt(np,np+lv);
                                writeCFrameDirect(physical,nCF);
                                S.motionPos[physical]=np;
                                hitIndicator.Text=statusText;
                                hitIndicator.TextColor3=Color3.fromRGB(255,220,80);
                                didCollect=true;
                            else
                                S.afFarmMode="idle";
                                S.afZoneEnterTime=0;
                                if gm.mode=="koth" and gm.zonePos then
                                    holdPos=gm.zonePos;
                                    statusText="AUTO FARM: HOLD HILL (0s)";
                                elseif gm.mode=="crown" and gm.crownPos then
                                    holdPos=gm.crownPos;
                                    statusText="AUTO FARM: HOLD CROWN";
                                else
                                    statusText="AUTO FARM: idle";
                                end
                            end
                        end

                        if not didCollect and holdPos then
                            disableBoatCollisions(physical);
                            disableConstraints(physical);
                            protectKey(physical,"CFrame");
                            local newCF=CFrame.new(holdPos)*physical.CFrame.Rotation;
                            writeCFrameDirect(physical,newCF);
                            S.motionPos[physical]=holdPos;
                            hitIndicator.Text=statusText;
                            hitIndicator.TextColor3=Color3.fromRGB(120,220,255);
                        elseif not didCollect and not holdPos then
                            restoreBoatCollisions(physical);
                            restoreConstraints(physical);
                            hitIndicator.Text=statusText;
                            hitIndicator.TextColor3=Color3.fromRGB(180,180,180);
                        end
                    else
                        restoreBoatCollisions(physical);
                        restoreConstraints(physical);
                        hitIndicator.Text="AUTO KILL: no target";
                        hitIndicator.TextColor3=Color3.fromRGB(180,180,180);
                    end;
                    S.akDesiredCF[physical]=nil;
                end;
            end;
        end;
        return;
    end;
    if S.pendingCF then
        local p=S.pendingCF;
        S.pendingCF=nil;
        writeCFrameDirect(p.physical,p.cf);
    end;
end);

track(RunService.Stepped:Connect(function()
    if S.unexecuted then return end;
    if S.flingAll and S.flingActive then
        local boat=S.flingBoat;
        if boat and boat.Parent then
            local physical=boat:FindFirstChild("Physical");
            if physical and physical:IsA("BasePart") and S.flingTarget and S.flingTarget.phys and S.flingTarget.phys.Parent then
                local tPos=S.flingTarget.phys.Position;
                local cf=CFrame.new(tPos)*physical.CFrame.Rotation;
                S.writing[physical]=true;
                pcall(function()physical.CFrame=cf end);
                S.writing[physical]=false;
                S.cframeCache[physical]=cf;
                pcall(function()physical.AssemblyLinearVelocity=Vector3.zero end);
                pcall(function()physical.Velocity=Vector3.zero end);
                local root=physical.AssemblyRootPart or physical;
                local spin=Vector3.new(CFG.FLING_SPIN_VEL,CFG.FLING_SPIN_VEL,CFG.FLING_SPIN_VEL);
                pcall(function()root.AssemblyAngularVelocity=spin end);
            end;
        end;
        return;
    end;
    if S.autoKill and S.akActive then
        for phys,cf in sp(S.akDesiredCF) do
            if phys and phys.Parent then writeCFrameDirect(phys,cf) end;
        end;
    end;
end));

local unexecBtn=Instance.new("TextButton");
unexecBtn.Size=UDim2.new(1,-20,0,26);
unexecBtn.Position=UDim2.new(0,10,0,90+14*25+30);
unexecBtn.BackgroundColor3=Color3.fromRGB(160,40,40);
unexecBtn.TextColor3=Color3.fromRGB(255,255,255);
unexecBtn.Font=Enum.Font.GothamBold;
unexecBtn.TextSize=14;
unexecBtn.BorderSizePixel=0;
unexecBtn.Text="UNEXECUTE";
unexecBtn.Parent=frame;

local function unexecute()
    if S.unexecuted then return end;
    S.unexecuted=true;
    S.autoKill=false;
    S.akActive=false;
    S.acting=false;
    S.akTargetSince=0;
    S.akBlacklist=setmetatable({},{__mode="k"});
    S.akBlacklistCount=setmetatable({},{__mode="k"});
    S.flingAll=false;
    S.flingActive=false;
    S.flingTarget=nil;
    S.flingedBlacklist=setmetatable({},{__mode="k"});
    S.autoFarm=false;
    S.afFarmMode="idle";
    S.afZoneEnterTime=0;
    if S.autoFarmGui then
        pcall(function()S.autoFarmGui:Destroy()end)
        S.autoFarmGui=nil
    end
    S.legacyPendingVF=nil;
    S.legacyPendingForce=nil;
    S.legacyPendingPhys=nil;
    S.legacyPendingAV=nil;
    S.legacyPendingAngVel=nil;
    if restoreFullbright then restoreFullbright() end;
    clearDotsPool();
    for plr in sp(S.espData) do espRemove(plr) end;
    for plr in sp(S.espPredictData) do espRemovePredict(plr) end;
    if S.phantomFolder then
        pcall(function()S.phantomFolder:Destroy()end);
        S.phantomFolder=nil;
    end;
    for obj in sp(S.disabledConstraints) do pcall(function()restoreConstraints(obj)end) end;
    for obj in sp(S.angularConstraintsDisabled) do pcall(function()restoreAngularConstraints(obj)end) end;
    for obj in sp(S.noCollideSaved) do pcall(function()restoreBoatCollisions(obj)end) end;
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=player then
            local char=plr.Character;
            if char then
                local hum=char:FindFirstChildOfClass("Humanoid");
                if hum and hum.SeatPart then
                    local root=hum.SeatPart.AssemblyRootPart or hum.SeatPart;
                    local av=root:FindFirstChild("__LegacyAV");
                    if av then pcall(function()av:Destroy()end) end;
                    local fav=root:FindFirstChild("__FlingAV");
                    if fav then pcall(function()fav:Destroy()end) end;
                end;
            end;
        end;
    end;
    if S.highlightSphere then
        pcall(function()S.highlightSphere:Destroy()end);
        S.highlightSphere=nil;
    end;
    for obj in sp(S.protectedKeys) do S.protectedKeys[obj]=nil end;
    local mts={};
    for mt in sp(S.hookData) do table.insert(mts,mt) end;
    for _,mt in ipairs(mts) do pcall(uninstallHook,mt) end;
    for _,c in ipairs(S.connections) do pcall(function()c:Disconnect()end) end;
    S.connections={};
    pcall(function()RunService:UnbindFromRenderStep("CFrameLock")end);
    pcall(function()RunService:UnbindFromRenderStep("DotsHL")end);
    pcall(function()RunService:UnbindFromRenderStep("LegacyEnforce")end);
    if screenGui and screenGui.Parent then screenGui:Destroy() end;
end;

unexecBtn.MouseButton1Click:Connect(unexecute);
