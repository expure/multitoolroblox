return function(deps)
    local FunctionManager = deps.FunctionManager
    local player = deps.player
    local character = deps.character
    local humanoid = deps.humanoid
    local hrp = deps.hrp
    local head = deps.head
    local Mouse = deps.Mouse
    local UIS = deps.UIS
    local RunService = deps.RunService
    local TweenService = deps.TweenService
    local HttpService = deps.HttpService
    local TeleportService = deps.TeleportService
    local ReplicatedStorage = deps.ReplicatedStorage
    local SoundService = deps.SoundService
    local Lighting = deps.Lighting
    local Players = deps.Players
    local CollectionService = deps.CollectionService
    local Debris = deps.Debris
    local PlaceId = deps.PlaceId
    local JobId = deps.JobId
    local Notify = deps.Notify
    local NotifyERROR = deps.NotifyERROR
    local gui = deps.gui
    local BASE_WALK_SPEED = deps.BASE_WALK_SPEED
    local BASE_JUMP = deps.BASE_JUMP

    local function generate_string(length)
        local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        local result = ""
        for _ = 1, length or 10 do
            result = result .. charset:sub(math.random(1, #charset), math.random(1, #charset))
        end
        return result
    end

    FunctionManager:register("Decal Spam", function()
        local decalID = 8408806737
        local function exPro(root)
            for _, v in pairs(root:GetChildren()) do
                if v:IsA("Decal") and v.Texture ~= "http://www.roblox.com/asset/?id="..decalID then
                    v.Parent = nil
                elseif v:IsA("BasePart") then
                    v.Material = "Plastic"
                    v.Transparency = 0
                    local One = Instance.new("Decal", v)
                    local Two = Instance.new("Decal", v)
                    local Three = Instance.new("Decal", v)
                    local Four = Instance.new("Decal", v)
                    local Five = Instance.new("Decal", v)
                    local Six = Instance.new("Decal", v)
                    One.Texture = "http://www.roblox.com/asset/?id="..decalID
                    Two.Texture = "http://www.roblox.com/asset/?id="..decalID
                    Three.Texture = "http://www.roblox.com/asset/?id="..decalID
                    Four.Texture = "http://www.roblox.com/asset/?id="..decalID
                    Five.Texture = "http://www.roblox.com/asset/?id="..decalID
                    Six.Texture = "http://www.roblox.com/asset/?id="..decalID
                    One.Face = "Front"
                    Two.Face = "Back"
                    Three.Face = "Right"
                    Four.Face = "Left"
                    Five.Face = "Top"
                    Six.Face = "Bottom"
                end
                exPro(v)
            end
        end
        local function asdf(root)
            for _, v in pairs(root:GetChildren()) do
                asdf(v)
            end
        end
        exPro(game.Workspace)
        asdf(game.Workspace)

        local s = Instance.new("Sky")
        s.Name = "Sky"
        s.Parent = game.Lighting
        local skyboxID = 8408806737
        s.SkyboxBk = "http://www.roblox.com/asset/?id="..skyboxID
        s.SkyboxDn = "http://www.roblox.com/asset/?id="..skyboxID
        s.SkyboxFt = "http://www.roblox.com/asset/?id="..skyboxID
        s.SkyboxLf = "http://www.roblox.com/asset/?id="..skyboxID
        s.SkyboxRt = "http://www.roblox.com/asset/?id="..skyboxID
        s.SkyboxUp = "http://www.roblox.com/asset/?id="..skyboxID
        game.Lighting.TimeOfDay = 12

        for i, v in pairs(game.Players:GetChildren()) do
            local emit = Instance.new("ParticleEmitter")
            if v.Character and v.Character:FindFirstChild("Torso") then
                emit.Parent = v.Character.Torso
                emit.Texture = "http://www.roblox.com/asset/?id=8408806737"
                emit.VelocitySpread = 20
            end
        end
        coroutine.wrap(function()
            while true do
                game.Lighting.Ambient = Color3.new(math.random(), math.random(), math.random())
                task.wait(0.2)
                game.Lighting.ShadowColor = Color3.new(math.random(), math.random(), math.random())
                task.wait(0.2)
            end
        end)()
    end, "Troll", "NOT FE")

    FunctionManager:register("JOHN DOE", function()
        local redSkyboxAssetId = "rbxassetid://1012887"
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if not sky then
            sky = Instance.new("Sky", Lighting)
        end
        sky.SkyboxBk = redSkyboxAssetId
        sky.SkyboxDn = redSkyboxAssetId
        sky.SkyboxFt = redSkyboxAssetId
        sky.SkyboxLf = redSkyboxAssetId
        sky.SkyboxRt = redSkyboxAssetId
        sky.SkyboxUp = redSkyboxAssetId

        if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
            local detection = Instance.new("Decal")
            detection.Name = "juisdfj0i32i0eidsuf0iok"
            detection.Parent = ReplicatedStorage
        end

        local soundGui = Instance.new("ScreenGui")
        soundGui.Name = "PersistentSoundGui"
        soundGui.ResetOnSpawn = false
        soundGui.Parent = player:WaitForChild("PlayerGui")

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 150, 0, 50)
        button.Position = UDim2.new(0.02, 0, 0.477, 0)
        button.Text = "Sound Toggle"
        button.Font = Enum.Font.SourceSansBold
        button.TextSize = 20
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Parent = soundGui

        local backgroundSound = SoundService:FindFirstChild("PersistentBGSound")
        if not backgroundSound then
            backgroundSound = Instance.new("Sound")
            backgroundSound.Name = "PersistentBGSound"
            backgroundSound.SoundId = "rbxassetid://19094700"
            backgroundSound.PlaybackSpeed = 0.221
            backgroundSound.Looped = true
            backgroundSound.Volume = 1
            backgroundSound.Parent = SoundService
            backgroundSound:Play()
        end

        button.Activated:Connect(function()
            backgroundSound.Playing = not backgroundSound.Playing
        end)

        local function setupCharacter(char)
            local hum = char:WaitForChild("Humanoid")
            local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            local hrpPart = char:WaitForChild("HumanoidRootPart")

            local tool = Instance.new("Tool")
            tool.Name = "Slash"
            tool.RequiresHandle = false
            tool.Parent = player.Backpack

            tool.Activated:Connect(function()
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://186934658"
                local track = hum:LoadAnimation(anim)
                track:Play()
                track:AdjustSpeed(2)

                local s = Instance.new("Sound", torso)
                s.SoundId = "rbxassetid://28144425"
                s:Play()

                task.wait(0.2)

                local s2 = Instance.new("Sound", torso)
                s2.SoundId = "rbxassetid://429400881"
                s2.Volume = 0.2
                s2:Play()
            end)

            local naeeym = Instance.new("BillboardGui", char)
            naeeym.Size = UDim2.new(0, 100, 0, 40)
            naeeym.StudsOffset = Vector3.new(0, 2, 0)
            naeeym.Adornee = char:WaitForChild("Head")

            local tecks = Instance.new("TextLabel", naeeym)
            tecks.BackgroundTransparency = 1
            tecks.BorderSizePixel = 0
            tecks.Font = Enum.Font.Fantasy
            tecks.TextSize = 24
            tecks.TextStrokeTransparency = 0
            tecks.TextStrokeColor3 = Color3.new(0, 0, 0)
            tecks.TextColor3 = Color3.new(0, 0, 0)
            tecks.Size = UDim2.new(1, 0, 0.5, 0)
            tecks.Text = "John Doe"

            local function changeName(newName)
                tecks.Text = newName
            end

            local function shakeTag()
                local originalOffset = naeeym.StudsOffset
                for _ = 1, 10 do
                    naeeym.StudsOffset = originalOffset + Vector3.new(math.random(-1,1), math.random(-1,1), math.random(-1,1))
                    task.wait(0.05)
                end
                naeeym.StudsOffset = originalOffset
            end

            coroutine.wrap(function()
                while char:IsDescendantOf(workspace) do
                    changeName("BURN IN HELL")
                    shakeTag()
                    task.wait(0.2)
                    changeName("STOP")
                    task.wait(0.1)
                    changeName("JUST GIVE UP")
                    shakeTag()
                    task.wait(0.2)
                    changeName("STOP")
                    shakeTag()
                    task.wait(0.2)
                    changeName("JOHN DOE")
                    shakeTag()
                    task.wait(0.3)
                    changeName("HOPELESS")
                    shakeTag()
                    task.wait(0.3)
                end
            end)()

            local footPartSize = Vector3.new(10, 0.5, 10)
            local floorPartColor = BrickColor.Black()
            local floorMaterial = Enum.Material.Neon
            local yOffset = -2.8
            local lastPosition = hrpPart.Position
            local standingTimer = 0

            RunService.Heartbeat:Connect(function(dt)
                if not char:IsDescendantOf(workspace) then return end
                local currentPosition = hrpPart.Position
                standingTimer = standingTimer + dt
                local distanceMoved = (currentPosition - lastPosition).Magnitude
                local stepPosition = Vector3.new(currentPosition.X, hrpPart.Position.Y + yOffset, currentPosition.Z)

                local function createFootstep(position)
                    local part = Instance.new("Part")
                    part.Size = footPartSize
                    part.Position = position
                    part.Anchored = true
                    part.CanCollide = false
                    part.BrickColor = floorPartColor
                    part.Material = floorMaterial
                    part.Transparency = 0.5
                    part.Parent = workspace
                    task.spawn(function()
                        for i = 1, 10 do
                            part.Transparency = i * 0.03
                            task.wait(0.05)
                        end
                    end)
                    Debris:AddItem(part, 1)
                end

                if distanceMoved > 1 then
                    createFootstep(stepPosition)
                    lastPosition = currentPosition
                    standingTimer = 0
                elseif standingTimer > 0.5 then
                    createFootstep(stepPosition)
                    standingTimer = 0
                end
            end)

            local movel = 0.1
            local hiddenfling = true

            local function fling()
                while hiddenfling and char:IsDescendantOf(workspace) do
                    if hrpPart then
                        local originalVelocity = hrpPart.Velocity
                        hrpPart.Velocity = originalVelocity * 10000 + Vector3.new(0, 10000, 0)
                        RunService.RenderStepped:Wait()
                        hrpPart.Velocity = originalVelocity
                        RunService.Stepped:Wait()
                        hrpPart.Velocity = originalVelocity + Vector3.new(0, movel, 0)
                        movel = -movel
                    end
                    RunService.Heartbeat:Wait()
                end
            end
            coroutine.wrap(fling)()
        end

        player.CharacterAdded:Connect(setupCharacter)
        if player.Character then
            setupCharacter(player.Character)
        end

        local function teleportToMousePosition()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local target = Mouse.Hit
            if target then
                char:MoveTo(target.Position)
            end
        end

        UIS.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.T then
                teleportToMousePosition()
            end
        end)
    end, "Trolling", "BROKEN")

    FunctionManager:register("Invis gui", function()
        loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))()
    end, "Trolling", "Credits to the original maker!")

    FunctionManager:register("DANCE", function()
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://27789359"
        local track = humanoid:LoadAnimation(anim)
        track:Play()
    end, "Fun", "DANCE DANCE")

    FunctionManager:register("Sound GUI", function()
        local sgui = player.PlayerGui:FindFirstChild("SoundGui")
        if sgui then sgui:Destroy() return end
        local SoundGui = Instance.new("ScreenGui")
        local Frame = Instance.new("Frame")
        local AddSoundId = Instance.new("TextButton")
        local SoundIds = Instance.new("TextBox")
        local Default = Instance.new("TextButton")
        local Credits = Instance.new("TextLabel")
        local Title = Instance.new("TextLabel")
        local Swap = Instance.new("ImageButton")
        local PlayBackSpeed = Instance.new("TextBox")
        local Volume = Instance.new("TextBox")
        local Looped = Instance.new("TextBox")
        local Exit = Instance.new("ImageButton")
        local Frame2 = Instance.new("Frame")
        local Open = Instance.new("ImageButton")
        local spoky = Instance.new("Sound")
        local c00lflag = Instance.new("Sound")
        local drag = Instance.new("UIDragDetector")
        drag.Parent = Frame
        c00lflag.Name = "c00lsound23sas"
        c00lflag.Parent = Frame
        spoky.Parent = Frame
        spoky.SoundId = "rbxassetid://95156028272944"
        spoky.Volume = 3
        spoky.PlaybackSpeed = 0.2
        spoky.Name = "spoky"

        SoundGui.Name = "SoundGui"
        SoundGui.Parent = player:WaitForChild("PlayerGui")
        SoundGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        SoundGui.ResetOnSpawn = false

        Frame.Parent = SoundGui
        Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Frame.BorderColor3 = Color3.fromRGB(255, 0, 4)
        Frame.BorderSizePixel = 2
        Frame.Position = UDim2.new(0, 700, 0, 300)
        Frame.Size = UDim2.new(0, 398, 0, 206)

        AddSoundId.Name = "AddSoundId"
        AddSoundId.Parent = Frame
        AddSoundId.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        AddSoundId.BorderColor3 = Color3.fromRGB(255, 0, 0)
        AddSoundId.BorderSizePixel = 2
        AddSoundId.Position = UDim2.new(0.118090451, 0, 0.718446612, 0)
        AddSoundId.Size = UDim2.new(0, 307, 0, 36)
        AddSoundId.Font = Enum.Font.Arial
        AddSoundId.Text = "Add Sound!"
        AddSoundId.TextColor3 = Color3.fromRGB(255, 255, 255)
        AddSoundId.TextSize = 29

        SoundIds.Name = "SoundIds"
        SoundIds.Parent = Frame
        SoundIds.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        SoundIds.BorderColor3 = Color3.fromRGB(255, 0, 0)
        SoundIds.BorderSizePixel = 2
        SoundIds.Position = UDim2.new(0.118090451, 0, 0.305825233, 0)
        SoundIds.Size = UDim2.new(0, 307, 0, 33)
        SoundIds.Font = Enum.Font.Arial
        SoundIds.PlaceholderText = "Add a sound ID here!, No rbx://"
        SoundIds.Text = ""
        SoundIds.TextColor3 = Color3.fromRGB(255, 255, 255)
        SoundIds.TextScaled = true
        SoundIds.TextSize = 14
        SoundIds.TextWrapped = true

        Default.Name = "Default"
        Default.Parent = Frame
        Default.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Default.BorderColor3 = Color3.fromRGB(255, 0, 0)
        Default.BorderSizePixel = 2
        Default.Position = UDim2.new(0.118090451, 0, 0.529126227, 0)
        Default.Size = UDim2.new(0, 307, 0, 28)
        Default.Font = Enum.Font.Arial
        Default.Text = "Spooky Scary Skeletons!"
        Default.TextColor3 = Color3.fromRGB(255, 255, 255)
        Default.TextSize = 23

        Credits.Name = "Credits"
        Credits.Parent = Frame
        Credits.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Credits.BackgroundTransparency = 1
        Credits.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Credits.BorderSizePixel = 0
        Credits.Position = UDim2.new(0.577889442, 0, 0.9174757, 0)
        Credits.Size = UDim2.new(0, 153, 0, 17)
        Credits.Font = Enum.Font.SourceSans
        Credits.Text = "made by: 1known. On discord!"
        Credits.TextColor3 = Color3.fromRGB(255, 255, 255)
        Credits.TextSize = 14

        Title.Name = "Title"
        Title.Parent = Frame
        Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Title.BackgroundTransparency = 1
        Title.BorderColor3 = Color3.fromRGB(255, 0, 4)
        Title.BorderSizePixel = 2
        Title.Position = UDim2.new(0.208542719, 0, 0.0291262139, 0)
        Title.Size = UDim2.new(0, 231, 0, 48)
        Title.Font = Enum.Font.Arial
        Title.Text = "c00lSound GUI!"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextSize = 33
        Title.TextWrapped = true

        Swap.Name = "Swap"
        Swap.Parent = Frame
        Swap.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Swap.BorderColor3 = Color3.fromRGB(255, 0, 0)
        Swap.BorderSizePixel = 0
        Swap.Position = UDim2.new(0.904522598, 0, 0.33495146, 0)
        Swap.Size = UDim2.new(0, 23, 0, 21)
        Swap.Image = "rbxassetid://2500573769"

        PlayBackSpeed.Name = "PlayBackSpeed"
        PlayBackSpeed.Parent = Frame
        PlayBackSpeed.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        PlayBackSpeed.BorderColor3 = Color3.fromRGB(255, 0, 0)
        PlayBackSpeed.BorderSizePixel = 2
        PlayBackSpeed.Position = UDim2.new(0.118090451, 0, 0.305825233, 0)
        PlayBackSpeed.Size = UDim2.new(0, 307, 0, 33)
        PlayBackSpeed.Visible = false
        PlayBackSpeed.Font = Enum.Font.Arial
        PlayBackSpeed.PlaceholderText = "Playback speed, Enter a number!"
        PlayBackSpeed.Text = "1"
        PlayBackSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
        PlayBackSpeed.TextScaled = true
        PlayBackSpeed.TextSize = 14
        PlayBackSpeed.TextWrapped = true

        Volume.Name = "Volume"
        Volume.Parent = Frame
        Volume.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Volume.BorderColor3 = Color3.fromRGB(255, 0, 0)
        Volume.BorderSizePixel = 2
        Volume.Position = UDim2.new(0.118090451, 0, 0.305825233, 0)
        Volume.Size = UDim2.new(0, 307, 0, 33)
        Volume.Visible = false
        Volume.Font = Enum.Font.Arial
        Volume.PlaceholderText = "Volume! Enter a number."
        Volume.Text = "0.5"
        Volume.TextColor3 = Color3.fromRGB(255, 255, 255)
        Volume.TextScaled = true
        Volume.TextSize = 14
        Volume.TextWrapped = true

        Looped.Name = "Looped"
        Looped.Parent = Frame
        Looped.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Looped.BorderColor3 = Color3.fromRGB(255, 0, 0)
        Looped.BorderSizePixel = 2
        Looped.Position = UDim2.new(0.118090451, 0, 0.305825233, 0)
        Looped.Size = UDim2.new(0, 307, 0, 33)
        Looped.Visible = false
        Looped.Font = Enum.Font.Arial
        Looped.PlaceholderText = "Is it looped?, Type: False or True"
        Looped.Text = "False"
        Looped.TextColor3 = Color3.fromRGB(255, 255, 255)
        Looped.TextScaled = true
        Looped.TextSize = 14
        Looped.TextWrapped = true

        Exit.Name = "Exit"
        Exit.Parent = Frame
        Exit.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Exit.BorderColor3 = Color3.fromRGB(255, 0, 0)
        Exit.BorderSizePixel = 2
        Exit.Position = UDim2.new(0.921999991, 0, 0.0289999992, 0)
        Exit.Size = UDim2.new(0, 25, 0, 23)
        Exit.Image = "rbxassetid://14930908086"

        Frame2.Name = "Frame2"
        Frame2.Parent = SoundGui
        Frame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Frame2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Frame2.BorderSizePixel = 0
        Frame2.Position = UDim2.new(0.984443069, 0, 0.841666639, 0)
        Frame2.Size = UDim2.new(0, 25, 0, 23)
        Frame2.Visible = false

        Open.Name = "Open"
        Open.Parent = Frame2
        Open.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Open.BorderColor3 = Color3.fromRGB(255, 0, 0)
        Open.BorderSizePixel = 2
        Open.Position = UDim2.new(-0.0312646478, 0, -0.0113339629, 0)
        Open.Size = UDim2.new(0, 25, 0, 23)
        Open.Image = "rbxassetid://14930908086"

        AddSoundId.Activated:Connect(function()
            local SoundId = SoundIds.Text
            local Playbackspeed = PlayBackSpeed.Text
            local VolumeVal = Volume.Text
            local loopedVal = Looped.Text
            if SoundId == "" then
                AddSoundId.Text = "No Sound ID!"
                task.wait(2)
                AddSoundId.Text = "Add Sound!"
                return
            end
            local id = "rbxassetid://" .. SoundId
            local speed = tonumber(Playbackspeed) or 1
            local existingSound = workspace:FindFirstChild("c00lsound23sas")
            if existingSound then
                existingSound.SoundId = id
                existingSound.PlaybackSpeed = speed
                existingSound.Volume = VolumeVal
                existingSound.Looped = (loopedVal == "True")
                existingSound:Play()
            else
                local clonedSound = spoky:Clone()
                clonedSound.Parent = workspace
                clonedSound.SoundId = id
                clonedSound.PlaybackSpeed = speed
                clonedSound.Volume = VolumeVal
                clonedSound.Looped = (loopedVal == "True")
                clonedSound:Play()
            end
            AddSoundId.Text = "Injected Sound Successfully!"
            AddSoundId.TextScaled = true
            task.wait(3.5)
            AddSoundId.TextScaled = false
            AddSoundId.Text = "Add Sound!"
        end)

        Default.Activated:Connect(function()
            if spoky.Playing then spoky:Stop() else spoky:Play() end
        end)

        Swap.Activated:Connect(function()
            if SoundIds.Visible then
                SoundIds.Visible = false
                PlayBackSpeed.Visible = true
                Volume.Visible = false
                Looped.Visible = false
            elseif PlayBackSpeed.Visible then
                PlayBackSpeed.Visible = false
                SoundIds.Visible = false
                Volume.Visible = true
                Looped.Visible = false
            elseif Volume.Visible then
                SoundIds.Visible = false
                PlayBackSpeed.Visible = false
                Volume.Visible = false
                Looped.Visible = true
            elseif Looped.Visible then
                SoundIds.Visible = true
                PlayBackSpeed.Visible = false
                Volume.Visible = false
                Looped.Visible = false
            end
        end)

        Exit.Activated:Connect(function()
            Frame2.Visible = true
            Frame.Visible = false
        end)

        Open.Activated:Connect(function()
            Frame.Visible = true
            Frame2.Visible = false
        end)
    end, "General", "NOT FE")

    local bindFrame = nil
    local bindConn = nil
    local waitingBindFunction = nil
    local customBinds = {}

    FunctionManager:register("Bind Key", function()
        if bindFrame then return end
        local screenGui = gui
        bindFrame = Instance.new("Frame")
        bindFrame.Name = generate_string(10)
        bindFrame.Size = UDim2.new(1,0,1,0)
        bindFrame.BackgroundColor3 = Color3.new(0,0,0)
        bindFrame.BackgroundTransparency = 0.5
        bindFrame.ZIndex = 50
        bindFrame.Parent = screenGui

        local panel = Instance.new("Frame")
        panel.Name = generate_string(10)
        panel.Size = UDim2.new(0, 300, 0, 400)
        panel.Position = UDim2.new(0.5, -150, 0.5, -200)
        panel.BackgroundColor3 = Color3.fromRGB(35,35,35)
        panel.BorderSizePixel = 0
        panel.ZIndex = 51
        panel.Parent = bindFrame

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 60, 0, 24)
        closeBtn.Position = UDim2.new(1, -64, 0, 4)
        closeBtn.Text = "Close"
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.TextSize = 14
        closeBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)
        closeBtn.TextColor3 = Color3.new(1,1,1)
        closeBtn.ZIndex = 52
        closeBtn.Parent = panel
        closeBtn.MouseButton1Click:Connect(function()
            bindFrame:Destroy()
            bindFrame = nil
            if bindConn then bindConn:Disconnect(); bindConn = nil end
        end)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -8, 0, 24)
        title.Position = UDim2.new(0, 4, 0, 4)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.SourceSansBold
        title.TextSize = 18
        title.TextColor3 = Color3.new(1,1,1)
        title.Text = "Bind Key to Function"
        title.ZIndex = 52
        title.Parent = panel

        local list = Instance.new("ScrollingFrame")
        list.Size = UDim2.new(1, -8, 1, -40)
        list.Position = UDim2.new(0, 4, 0, 32)
        list.CanvasSize = UDim2.new(0,0,0,0)
        list.ScrollBarThickness = 6
        list.ZIndex = 51
        list.Parent = panel

        local uiList = Instance.new("UIListLayout")
        uiList.Padding = UDim.new(0,4)
        uiList.SortOrder = Enum.SortOrder.LayoutOrder
        uiList.Parent = list

        local function refreshList()
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("TextButton") or child:IsA("TextLabel") then
                    child:Destroy()
                end
            end

            for _, cat in ipairs(FunctionManager.Categories) do
                local hdr = Instance.new("TextLabel")
                hdr.Size = UDim2.new(1,0,0,24)
                hdr.BackgroundTransparency = 1
                hdr.Font = Enum.Font.SourceSansBold
                hdr.TextSize = 16
                hdr.TextColor3 = Color3.new(1,1,0)
                hdr.Text = "["..cat.."]"
                hdr.ZIndex = 51
                hdr.Parent = list

                for name, cb in pairs(FunctionManager:getFunctionsInCategory(cat)) do
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1,0,0,24)
                    btn.Font = Enum.Font.SourceSans
                    btn.TextSize = 14
                    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
                    btn.TextColor3 = Color3.new(1,1,1)
                    btn.ZIndex = 51

                    local bound = {}
                    for key, fn in pairs(customBinds) do
                        if fn == cb then table.insert(bound, tostring(key)) end
                    end
                    local suffix = #bound>0 and " ("..table.concat(bound, ",")..")" or ""
                    btn.Text = name..suffix
                    btn.Parent = list

                    btn.MouseButton1Click:Connect(function()
                        waitingBindFunction = { cb = cb, btn = btn, name = name }
                        btn.Text = name.." → [Press a key]"
                    end)
                end
            end

            list.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 8)
        end

        bindConn = UIS.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not waitingBindFunction then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                customBinds[input.KeyCode] = waitingBindFunction.cb
                waitingBindFunction.btn.Text = waitingBindFunction.name.." ("..tostring(input.KeyCode)..")"
                waitingBindFunction = nil
            end
        end)
        refreshList()
    end, "Utility", "BUGGED")

    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local fn = customBinds[input.KeyCode]
            if fn and type(fn) == "function" then
                pcall(fn)
            end
        end
    end)

    FunctionManager:register("JumpUp", function()
        if hrp then hrp.Velocity = Vector3.new(0, 100, 0) end
    end, "Movement", "Leap into the air!")

    FunctionManager:register("Sit", function()
        if humanoid then humanoid.Sit = true end
    end, "Movement", "SIT DOWN")

    local infJumpEnabledFused = false
    local infJumpConnectionFused = nil
    FunctionManager:register("INF JUMP", function()
        infJumpEnabledFused = not infJumpEnabledFused
        if infJumpEnabledFused then
            local debounce = false
            infJumpConnectionFused = UIS.JumpRequest:Connect(function()
                if debounce then return end
                debounce = true
                local hum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                task.wait()
                debounce = false
            end)
        else
            if infJumpConnectionFused then
                infJumpConnectionFused:Disconnect()
                infJumpConnectionFused = nil
            end
        end
        Notify("INF JUMP " .. (infJumpEnabledFused and "ON" or "OFF"), "Fused", 2)
    end, "Movement", "Jump Forever!")

    FunctionManager:register("WalkSpeed Slider", function()
        if gui:FindFirstChild("WalkSpeedModal") then return end
        local overlay = Instance.new("Frame")
        overlay.Name = "WalkSpeedModal"
        overlay.Size = UDim2.new(1,0,1,0)
        overlay.Position = UDim2.new(0,0,0,0)
        overlay.BackgroundColor3 = Color3.new(0,0,0)
        overlay.BackgroundTransparency = 0.5
        overlay.ZIndex = 50
        overlay.Parent = gui

        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(0, 300, 0, 100)
        panel.Position = UDim2.new(0.5, -150, 0.5, -50)
        panel.BackgroundColor3 = Color3.fromRGB(40,40,40)
        panel.BorderSizePixel = 0
        panel.ZIndex = 51
        panel.Parent = overlay

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0,60,0,24)
        closeBtn.Position = UDim2.new(1,-64,0,4)
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.TextSize = 14
        closeBtn.Text = "Close"
        closeBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)
        closeBtn.TextColor3 = Color3.new(1,1,1)
        closeBtn.ZIndex = 52
        closeBtn.Parent = panel
        closeBtn.MouseButton1Click:Connect(function()
            overlay:Destroy()
        end)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,-8,0,24)
        label.Position = UDim2.new(0,4,0,4)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 18
        label.TextColor3 = Color3.new(1,1,1)
        label.Text = "WalkSpeed: " .. tostring(humanoid.WalkSpeed)
        label.ZIndex = 52
        label.Parent = panel

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1,-16,0,20)
        track.Position = UDim2.new(0,8,0,40)
        track.BackgroundColor3 = Color3.fromRGB(60,60,60)
        track.BorderSizePixel = 0
        track.ZIndex = 51
        track.Parent = panel

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(math.clamp((humanoid.WalkSpeed - 8)/(100-8),0,1), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(100,200,100)
        fill.BorderSizePixel = 0
        fill.ZIndex = 52
        fill.Parent = track

        local dragging = false
        local minS, maxS = 8, 100
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0,1)
            local v = math.floor(minS + (maxS-minS)*rel)
            humanoid.WalkSpeed = v
            label.Text = "WalkSpeed: "..v
            fill.Size = UDim2.new(rel,0,1,0)
        end
        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                update(i.Position.X)
            end
        end)
        track.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                update(i.Position.X)
            end
        end)
    end, "Movement", "Control your walkspeed!")

    FunctionManager:register("Server Hop", function()
        local success, res = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
        end)
        if not success then return NotifyERROR("[Server Hop] HTTP request failed") end
        local body
        local ok, err = pcall(function() body = HttpService:JSONDecode(res) end)
        if not ok or type(body) ~= "table" or type(body.data) ~= "table" then
            return NotifyERROR("[Server Hop] Invalid JSON response")
        end
        local servers = {}
        for _, v in ipairs(body.data) do
            if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= JobId then
                table.insert(servers, v.id)
            end
        end
        if #servers == 0 then return NotifyERROR("[Server Hop] No available servers found") end
        local choice = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(PlaceId, choice, player)
    end, "Utility", "Changes Servers")

    FunctionManager:register("TP Behind Closest", function()
        if not hrp then return end
        local closestPlayer, shortestDistance = nil, math.huge
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                if otherRoot then
                    local distance = (otherRoot.Position - hrp.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = otherPlayer
                    end
                end
            end
        end
        if closestPlayer and closestPlayer.Character then
            local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local behindPosition = targetRoot.CFrame.Position - targetRoot.CFrame.LookVector * 3
                hrp.CFrame = CFrame.new(behindPosition, targetRoot.Position)
            end
        else
            NotifyERROR("No nearby player found.")
        end
    end, "Movement", "Owai moi, shinderu. NANI?")

    FunctionManager:register("Scare Closest Player", function()
        if not hrp then return end
        local closestPlayer, closestDistance = nil, math.huge
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                if otherRoot then
                    local dist = (otherRoot.Position - hrp.Position).Magnitude
                    if dist < closestDistance then
                        closestDistance = dist
                        closestPlayer = otherPlayer
                    end
                end
            end
        end
        if closestPlayer and closestPlayer.Character then
            local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local oldPos = hrp.CFrame
                hrp.CFrame = targetRoot.CFrame + targetRoot.CFrame.LookVector * 2
                hrp.CFrame = CFrame.new(hrp.Position, targetRoot.Position)
                task.wait(0.5)
                hrp.CFrame = oldPos
            end
        else
            NotifyERROR("No target player nearby.")
        end
    end, "Fun", "FNAF reference")

    local espOn = false
    FunctionManager:register("ESP Toggle", function()
        espOn = not espOn
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and plr ~= player then
                local headPart = plr.Character:FindFirstChild("Head")
                if headPart then
                    local bb = headPart:FindFirstChild("ESP") or Instance.new("BillboardGui", headPart)
                    bb.Name = "ESP"
                    bb.Size = UDim2.new(0,80,0,20)
                    bb.AlwaysOnTop = true
                    local lbl = bb:FindFirstChild("Name") or Instance.new("TextLabel", bb)
                    lbl.Name = "Name"
                    lbl.BackgroundTransparency = 1
                    lbl.Size = UDim2.new(1,0,1,0)
                    lbl.TextColor3 = Color3.new(1,0,0)
                    lbl.TextScaled = true
                    lbl.Text = plr.Name
                    bb.Enabled = espOn
                end
            end
        end
        Notify("ESP " .. (espOn and "Enabled" or "Disabled"), "SYSTEM", 3)
    end, "Visual", "ur cooked i just got wallhacks")

    FunctionManager:register("JumpPowerSlider", function()
        if gui:FindFirstChild("JumpPowerModal") then return end
        humanoid.UseJumpPower = true
        local overlay = Instance.new("Frame")
        overlay.Name = "JumpPowerModal"
        overlay.Size = UDim2.new(1,0,1,0)
        overlay.Position = UDim2.new(0,0,0,0)
        overlay.BackgroundColor3 = Color3.new(0,0,0)
        overlay.BackgroundTransparency = 0.5
        overlay.ZIndex = 50
        overlay.Parent = gui

        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(0, 300, 0, 100)
        panel.Position = UDim2.new(0.5, -150, 0.5, -50)
        panel.BackgroundColor3 = Color3.fromRGB(40,40,40)
        panel.BorderSizePixel = 0
        panel.ZIndex = 51
        panel.Parent = overlay

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0,60,0,24)
        closeBtn.Position = UDim2.new(1,-64,0,4)
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.TextSize = 14
        closeBtn.Text = "Close"
        closeBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)
        closeBtn.TextColor3 = Color3.new(1,1,1)
        closeBtn.ZIndex = 52
        closeBtn.Parent = panel
        closeBtn.MouseButton1Click:Connect(function() overlay:Destroy() end)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,-8,0,24)
        label.Position = UDim2.new(0,4,0,4)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 18
        label.TextColor3 = Color3.new(1,1,1)
        label.Text = "JumpPower: " .. tostring(humanoid.JumpPower)
        label.ZIndex = 52
        label.Parent = panel

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1,-16,0,20)
        track.Position = UDim2.new(0,8,0,40)
        track.BackgroundColor3 = Color3.fromRGB(60,60,60)
        track.BorderSizePixel = 0
        track.ZIndex = 51
        track.Parent = panel

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(math.clamp((humanoid.JumpPower - 50)/(200-50),0,1), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(100,200,100)
        fill.BorderSizePixel = 0
        fill.ZIndex = 52
        fill.Parent = track

        local dragging = false
        local minJ, maxJ = 50, 200
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0,1)
            local v = math.floor(minJ + (maxJ-minJ)*rel)
            humanoid.JumpPower = v
            label.Text = "JumpPower: "..v
            fill.Size = UDim2.new(rel,0,1,0)
        end
        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                update(i.Position.X)
            end
        end)
        track.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                update(i.Position.X)
            end
        end)
    end, "Movement", "Control your jumppower")

    local spinOn = false
    local spinBAV, lockBP
    FunctionManager:register("Spin Bot", function()
        spinOn = not spinOn
        if spinOn then
            if not hrp then return NotifyERROR("No HRP!") end
            lockBP = Instance.new("BodyPosition")
            lockBP.Name = "SpinLockBP"
            lockBP.Position = hrp.Position
            lockBP.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            lockBP.P = 1e5
            lockBP.D = 0
            lockBP.Parent = hrp

            spinBAV = Instance.new("BodyAngularVelocity")
            spinBAV.Name = "SpinBAV"
            spinBAV.AngularVelocity = Vector3.new(0, 10000, 0)
            spinBAV.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            spinBAV.P = 1e5
            spinBAV.Parent = hrp
            NotifyERROR("Spin Bot On")
        else
            if spinBAV then spinBAV:Destroy() spinBAV = nil end
            if lockBP then lockBP:Destroy() lockBP = nil end
            NotifyERROR("Spin Bot Off")
        end
    end, "Visual", "Speeeeen")

    FunctionManager:register("TP To Mouse", function()
        local ray = workspace.CurrentCamera:ScreenPointToRay(Mouse.X, Mouse.Y)
        local hit, pos = workspace:FindPartOnRay(ray, character)
        if hit then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        end
    end, "Movement", "BUGGED")

    local savedCFrame = nil
    FunctionManager:register("Save Position", function()
        if hrp then savedCFrame = hrp.CFrame end
        Notify("Position Saved", "SYSTEM", 3)
    end, "Utility", "Checkpoint")

    FunctionManager:register("Load Position", function()
        if savedCFrame then
            hrp.CFrame = savedCFrame
            Notify("Position Loaded", "SYSTEM", 3)
        else
            NotifyERROR("No Position Saved")
        end
    end, "Utility", "Reload")

    local noclipOn = false
    local hoverHeight
    FunctionManager:register("No‑Clip", function()
        noclipOn = not noclipOn
        if noclipOn then
            hoverHeight = hrp.Position.Y
            task.spawn(function()
                while noclipOn do
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                    hrp.CFrame = CFrame.new(hrp.Position.X, hoverHeight, hrp.Position.Z)
                    task.wait(0.01)
                end
            end)
            Notify("No‑Clip ON (locked at height)", "SYSTEM", 3)
        else
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
            Notify("No‑Clip OFF", "SYSTEM", 3)
        end
    end, "Movement", "NOCLIP")

    FunctionManager:register("DarkDex", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua", true))()
    end, "General", "Take a peek under the hood")

    FunctionManager:register("Teleport to lobby", function()
        if character then character:MoveTo(Vector3.new(0, 50, 0)) end
    end, "General", "Teleports you to lobby")

    FunctionManager:register("Fling All", function()
        loadstring(game:HttpGet("https://pastebin.com/raw/4nDpRkZU"))()
    end, "Trolling", "Fling All But A little Bugged")

    FunctionManager:register("c00lkidd Rises", function()
        local userId = 8035096399
        local function spawnC00lkidd()
            local model = Players:CreateHumanoidModelFromUserId(userId)
            model.Name = "c00lkidd"
            model.Parent = workspace
            local root = hrp
            if root and model.PrimaryPart then
                model:SetPrimaryPartCFrame(root.CFrame * CFrame.new(math.random(-5,5), 0, math.random(-5,5)))
            end
            local cRoot = model:FindFirstChild("HumanoidRootPart")
            if cRoot then
                local bp = Instance.new("BodyPosition", cRoot)
                bp.Position = cRoot.Position + Vector3.new(0,5,0)
                bp.MaxForce = Vector3.new(0,5000,0)
                bp.D = 100
                bp.P = 3000
                Instance.new("Fire", cRoot).Heat = 10
                Instance.new("Smoke", cRoot).Color = Color3.new(0,0,0)
            end
            local hum = model:FindFirstChild("Humanoid")
            if hum then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://235542946"
                local track = hum:LoadAnimation(anim)
                track.Looped = true
                track:Play()
            end
            return model
        end
        spawnC00lkidd()
        local hint = Instance.new("Hint", workspace)
        for i = 100,1,-1 do hint.Text = "Countdown: " .. i; wait(1) end
        hint:Destroy()
        for _, p in pairs(Players:GetPlayers()) do p:Kick("Server Shutdown") end
    end, "Fun", "Holy c00lkidd!")

    FunctionManager:register("SimpleSpy", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
    end, "Catch remotes")

    FunctionManager:register("Orbit All Nearby Parts", function()
        local radius = 20
        local height = 3
        local orbitSpeed = 2
        if not hrp then return end
        local origin = hrp.Position
        local orbitParts = {}
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(workspace.Terrain) then
                local isInCharacter = false
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character and part:IsDescendantOf(pl.Character) then isInCharacter = true; break end
                end
                if not isInCharacter and (part.Position - origin).Magnitude <= radius then
                    if not CollectionService:HasTag(part, "OrbitPart") then
                        if part:CanSetNetworkOwnership() then part:SetNetworkOwner(player) end
                        part.CanCollide = false
                        CollectionService:AddTag(part, "OrbitPart")
                        table.insert(orbitParts, part)
                    end
                end
            end
        end
        if #orbitParts == 0 then return end
        local angleOffset = 2 * math.pi / #orbitParts
        for i, part in ipairs(orbitParts) do
            local angle = angleOffset * i
            part.Position = hrp.Position + Vector3.new(math.cos(angle)*radius, height, math.sin(angle)*radius)
            local bodyGyro = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
            bodyGyro.P = 1e4
            bodyGyro.CFrame = CFrame.new(part.Position, hrp.Position)
            bodyGyro.Parent = part
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
            bodyVel.P = 1e4
            bodyVel.Parent = part
            local conn
            conn = RunService.Heartbeat:Connect(function(dt)
                if not hrp or not hrp.Parent then conn:Disconnect() return end
                angle = angle + orbitSpeed * dt
                local orbitCenter = hrp.Position
                local orbitPoint = orbitCenter + Vector3.new(math.cos(angle)*radius, height, math.sin(angle)*radius)
                local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle)).Unit * orbitSpeed * radius
                bodyVel.Velocity = tangent
                bodyGyro.CFrame = CFrame.new(part.Position, orbitCenter)
                part.Position = orbitPoint
            end)
        end
    end, "Fun", "You have to be near the parts for a while for it to work")

    local invisRunning = false
    local function toggleInvisibility()
        if invisRunning then return end
        invisRunning = true
        local originalChar = character
        originalChar.Archivable = true
        local invisibleChar = originalChar:Clone()
        invisibleChar.Name = ""
        invisibleChar.Parent = Lighting
        for _, part in ipairs(invisibleChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = (part.Name == "HumanoidRootPart") and 1 or 0.5
            end
        end
        local voidConn, deathConn, steppedConn
        local function Respawn()
            invisRunning = false
            if steppedConn then steppedConn:Disconnect() end
            if deathConn then deathConn:Disconnect() end
            player.Character = originalChar
            originalChar.Parent = workspace
            local clonedHum = originalChar:FindFirstChildWhichIsA("Humanoid")
            if clonedHum then clonedHum:Destroy() end
            invisibleChar.Parent = nil
        end
        local voidY = workspace.FallenPartsDestroyHeight
        steppedConn = RunService.Stepped:Connect(function()
            local hrpPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not hrpPart then return end
            local y = hrpPart.Position.Y
            if (voidY < 0 and y <= voidY) or (voidY >= 0 and y >= voidY) then
                Respawn()
            end
        end)
        local clonedHum = invisibleChar:FindFirstChildWhichIsA("Humanoid")
        if clonedHum then
            deathConn = clonedHum.Died:Connect(Respawn)
        end
        local camCF = workspace.CurrentCamera.CFrame
        local hrpCF = originalChar.HumanoidRootPart.CFrame
        originalChar:MoveTo(Vector3.new(0, math.pi*1e6, 0))
        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        task.wait(0.2)
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        invisibleChar.Parent = workspace
        invisibleChar.HumanoidRootPart.CFrame = hrpCF
        player.Character = invisibleChar
        for _, a in ipairs(player.Character:GetDescendants()) do
            if a.Name == "Animate" and a:IsA("Model") then
                a.Disabled = true; a.Disabled = false
            end
        end
        workspace.CurrentCamera:remove()
        wait(0.1)
        repeat wait() until player.Character ~= nil
        workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChildWhichIsA('Humanoid')
        workspace.CurrentCamera.CameraType = "Custom"
        player.CameraMinZoomDistance = 0.5
        player.CameraMaxZoomDistance = 400
        player.CameraMode = "Classic"
        if player.Character.Head then player.Character.Head.Anchored = false end
        if player.Character.Animate then
            player.Character.Animate.Enabled = false
            player.Character.Animate.Enabled = true
        end
        Notify("You are now invisible!", "System", 3)
    end
    FunctionManager:register("Invisible", toggleInvisibility, "Fun", "Make your character invisible until you respawn or die")

    local flyingEnabledFused = false
    local flyBG, flyBV, flyConnFused
    FunctionManager:register("Fly", function()
        if not hrp then return end
        flyingEnabledFused = not flyingEnabledFused
        if flyingEnabledFused then
            flyBG = Instance.new("BodyGyro")
            flyBG.P = 9e4
            flyBG.MaxTorque = Vector3.new(9e4,9e4,9e4)
            flyBG.CFrame = hrp.CFrame
            flyBG.Parent = hrp
            flyBV = Instance.new("BodyVelocity")
            flyBV.MaxForce = Vector3.new(9e4,9e4,9e4)
            flyBV.Velocity = Vector3.new(0,0,0)
            flyBV.Parent = hrp
            flyConnFused = RunService.Heartbeat:Connect(function()
                local camCF = workspace.CurrentCamera.CFrame
                local dir = Vector3.new()
                if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
                if dir.Magnitude > 0 then dir = dir.Unit * 50 end
                flyBV.Velocity = dir
                flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
            end)
        else
            if flyConnFused then flyConnFused:Disconnect() flyConnFused = nil end
            if flyBG then flyBG:Destroy() flyBG = nil end
            if flyBV then flyBV:Destroy() flyBV = nil end
        end
    end, "Movement", "Fly around!")

    FunctionManager:register("HatHub", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/inkdupe/hat-scripts/refs/heads/main/updatedhathub.lua"))()
    end, "Troll", "Credits to original maker!")

    FunctionManager:register("Hitbox Extender", function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/AAPVdev/scripts/refs/heads/main/UI_LimbExtender.lua'))()
    end, "Troll", "Extends hitboxes")

    FunctionManager:register("Part Grab", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/v0c0n1337/scripts/refs/heads/main/Unachored_parts_controller_v2.lua.txt"))()
    end, "Troll", "Much better part grab")

    FunctionManager:register("Hat Script", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ocfi/Scp-096-Obfuscated/refs/heads/main/obuf"))()
    end, "Troll", "HATS")

    FunctionManager:register("PART ORBIT", function()
        loadstring(game:HttpGet("https://pastebin.com/raw/aZjaAr6F", true))()
    end, "Troll", "Probs better orbit")

    FunctionManager:register("Unban VoiceChat", function()
        loadstring(game:HttpGet("https://pastebin.com/raw/aDFhvMC4", true))()
    end, "Utility", "Credits to the original maker!")

    FunctionManager:register("Fling GUI", function()
        loadstring(game:HttpGet("https://pastebin.com/raw/VynRhxJV", true))()
    end, "Troll", "Credits to the original maker!")

    FunctionManager:register("Invis gui V2", function()
        loadstring(game:HttpGet("https://pastebin.com/raw/hracJzLa"))()
    end, "Trolling", "Credits to the original maker!")

    FunctionManager:register("Thomas Train", function()
        loadstring(game:HttpGet("https://pastebin.com/raw/dcywCSCs"))()
    end, "Troll", "Become Thomas the Dank Engine!")

    FunctionManager:register("I..... Am Steve", function()
        loadstring(game:HttpGet("https://pastebin.com/raw/miABMATi"))()
    end, "Trolling", "Who are you? I... Am Steve..")

    FunctionManager:register("TP Tool", function()
        loadstring(game:HttpGet("https://pastebin.com/raw/WUwLqAzr"))()
    end, "Utility", "It's a teleport tool")

    FunctionManager:register("GOD Mode Toggle", function()
        loadstring(game:HttpGet("https://pastebin.com/raw/eD8HBXGS"))()
    end, "Utility", "GOD Mode Toggle GUI")

    FunctionManager:register("Control NPC GUI", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/fe-source/refs/heads/main/NPC/source/main.Luau"))()
    end, "Trolling", "Credits to original script maker")

    FunctionManager:register("Fake VR (hat method)", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/Qwerty/refs/heads/main/qwerty46.lua"))()
    end, "Trolling", "Credits to original script maker")

    FunctionManager:register("Telekinesis Powers", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/Qwerty/refs/heads/main/qwerty1.lua"))()
    end, "Troll", "Credits to original script maker!")

    FunctionManager:register("Infinite Yield", function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end, "General", "The classic admin commands script!")

    FunctionManager:register("Nameless Admin", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua"))()
    end, "General", "Slight differences from infiniteyield admin")

    FunctionManager:register("Drift Car", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/AstraOutlight/my-scripts/refs/heads/main/fe%20car%20v3"))()
    end, "Fun", "Invisible Car :O")

    return FunctionManager
end
