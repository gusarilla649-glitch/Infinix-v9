--// INFINIX HUB | ULTIMATE EDITION v9
--// High-Quality Auras (Meshes), Blizzard Snow, Tab Animations, Particle Trails

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

pcall(function() CoreGui = game:GetService("CoreGui") end)

local CONFIG = {
    Fly = { Enabled = false, Speed = 70 },
    Noclip = { Enabled = true },
    Speed = { Enabled = false, Value = 16, Default = 16 },
    Jump = { Enabled = false, Value = 50, Default = 50 },
    Aimbot = { Enabled = false, FOV = 300, Smoothness = 0.25, TargetPart = "Head", TeamCheck = true, WallCheck = true },
    Ragebot = { Enabled = false },
    ESP = { Enabled = true, ShowHealth = true, ShowDistance = true },
    Visuals = {
        SelfChams = false, BoxESP = true, Chams = true, FOV = 70,
        Weather = { Snow = false, Rain = false, Night = false },
        SelfChamsFill = 0.5, SelfChamsOutline = 0.1,
        TrailType = "None", -- "None", "Neon", "Fire", "Ice", "Rainbow", "Sparkle"
        Aura = "None" -- "None", "Halo", "Wings", "Crown", "Orb"
    },
    Fling = { Target = nil, Velocity = 80000 },
    Theme = { Primary = Color3.fromRGB(180, 0, 255), Secondary = Color3.fromRGB(255, 150, 255) }
}

local flyBV, flyBG, flyConn = nil, nil, nil
local noclipStepped, noclipHeartbeat = nil, nil
local espObjects = {}
local fovCircle = nil
local aimbotConn, ragebotConn = nil, nil
local selfHighlight = nil
local weatherFolder = nil
local colorCorrection, atmosphere = nil, nil
local rainbowConn = nil
local allGradients = {}
local allToggles = {}
local auraObjects = {}
local trailObject = nil
local originalLighting = { ClockTime = Lighting.ClockTime, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }

local function safeDestroy(inst) if inst and inst.Parent then inst:Destroy() end end

--// NOCLIP
local function noclipTick()
    if not CONFIG.Noclip.Enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end

local function enableNoclip()
    CONFIG.Noclip.Enabled = true
    if not noclipStepped then noclipStepped = RunService.Stepped:Connect(noclipTick) end
    if not noclipHeartbeat then noclipHeartbeat = RunService.Heartbeat:Connect(noclipTick) end
end

local function disableNoclip()
    CONFIG.Noclip.Enabled = false
    if noclipStepped then noclipStepped:Disconnect(); noclipStepped = nil end
    if noclipHeartbeat then noclipHeartbeat:Disconnect(); noclipHeartbeat = nil end
    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
        end
    end
end

--// FLY
local function startFly()
    if CONFIG.Fly.Enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or root
    local hum = char:FindFirstChildOfClass("Humanoid")
    CONFIG.Fly.Enabled = true
    
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = torso
    
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P = 9e4
    flyBG.Parent = torso
    
    flyConn = RunService.RenderStepped:Connect(function()
        if not CONFIG.Fly.Enabled or not flyBV or not flyBV.Parent then return end
        local cam = Camera.CFrame
        local md = hum and hum.MoveDirection or Vector3.zero
        local vel = Vector3.zero
        if md.Magnitude > 0.01 then
            local look = cam.LookVector
            local right = cam.RightVector
            local flatLook = Vector3.new(look.X, 0, look.Z).Unit
            local fwd = md:Dot(flatLook)
            local side = md:Dot(right)
            if fwd > 0.01 then vel = look * (fwd * CONFIG.Fly.Speed)
            elseif fwd < -0.01 then vel = -look * (-fwd * CONFIG.Fly.Speed) end
            vel = vel + right * (side * CONFIG.Fly.Speed)
            if vel.Magnitude > 0.01 then vel = vel.Unit * CONFIG.Fly.Speed else vel = Vector3.zero end
        end
        flyBV.Velocity = vel
        flyBG.CFrame = cam
    end)
end

local function stopFly()
    CONFIG.Fly.Enabled = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    safeDestroy(flyBV); safeDestroy(flyBG)
    flyBV, flyBG = nil, nil
end

--// SPEED & JUMP
local function applySpeed()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = CONFIG.Speed.Enabled and CONFIG.Speed.Value or CONFIG.Speed.Default end
end

local function applyJump()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if CONFIG.Jump.Enabled then hum.UseJumpPower = true; hum.JumpPower = CONFIG.Jump.Value
        else hum.JumpPower = CONFIG.Jump.Default end
    end
end

--// VISUALS: SELF CHAMS & AURAS & TRAILS
local function updateSelfChams()
    local char = LocalPlayer.Character
    if not char then return end
    if CONFIG.Visuals.SelfChams then
        if not selfHighlight or selfHighlight.Parent ~= char then
            safeDestroy(selfHighlight)
            selfHighlight = Instance.new("Highlight")
            selfHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            selfHighlight.Parent = char
        end
        selfHighlight.FillColor = CONFIG.Theme.Primary
        selfHighlight.OutlineColor = CONFIG.Theme.Secondary
        selfHighlight.FillTransparency = CONFIG.Visuals.SelfChamsFill
        selfHighlight.OutlineTransparency = CONFIG.Visuals.SelfChamsOutline
    else
        safeDestroy(selfHighlight)
        selfHighlight = nil
    end
end

local function updateAura()
    for _, obj in pairs(auraObjects) do safeDestroy(obj) end
    table.clear(auraObjects)
    local char = LocalPlayer.Character
    if not char or CONFIG.Visuals.Aura == "None" then return end
    
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not head or not torso then return end
    
    if CONFIG.Visuals.Aura == "Halo" then
        local halo = Instance.new("Part")
        halo.Size = Vector3.new(2, 2, 2)
        halo.Transparency = 0.5
        halo.Color = CONFIG.Theme.Primary
        halo.Material = Enum.Material.Neon
        halo.CanCollide = false
        halo.Massless = true
        
        local mesh = Instance.new("SpecialMesh", halo)
        mesh.MeshId = "rbxassetid://3270017" -- Тор (Кольцо)
        mesh.Scale = Vector3.new(3, 1, 3)
        
        halo.CFrame = head.CFrame * CFrame.new(0, 1.5, 0)
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = halo
        weld.Part1 = head
        weld.Parent = halo
        halo.Parent = char
        table.insert(auraObjects, halo)
        
        -- Спиннинг для кольца
        task.spawn(function()
            while halo.Parent do
                halo.CFrame = halo.CFrame * CFrame.Angles(0, math.rad(5), 0)
                task.wait(0.05)
            end
        end)

    elseif CONFIG.Visuals.Aura == "Wings" then
        for i, side in ipairs({-1, 1}) do
            local wing = Instance.new("Part")
            wing.Size = Vector3.new(2, 2, 2)
            wing.Transparency = 0.3
            wing.Color = CONFIG.Theme.Primary
            wing.Material = Enum.Material.Neon
            wing.CanCollide = false
            wing.Massless = true
            
            local mesh = Instance.new("SpecialMesh", wing)
            mesh.MeshId = "rbxassetid://217695298" -- Mesh "Sparkle Wings"
            mesh.Scale = Vector3.new(4, 4, 4)
            
            wing.CFrame = torso.CFrame * CFrame.new(side * 2, 1, 1) * CFrame.Angles(0, math.rad(90 * side), math.rad(20 * side))
            
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = wing
            weld.Part1 = torso
            weld.Parent = wing
            wing.Parent = char
            table.insert(auraObjects, wing)
        end
        
    elseif CONFIG.Visuals.Aura == "Crown" then
        local crown = Instance.new("Part")
        crown.Size = Vector3.new(2, 2, 2)
        crown.Transparency = 0.2
        crown.Color = Color3.fromRGB(255, 215, 0)
        crown.Material = Enum.Material.Neon
        crown.CanCollide = false
        crown.Massless = true
        
        local mesh = Instance.new("SpecialMesh", crown)
        mesh.MeshId = "rbxassetid://1127828571" -- Mesh "Crown"
        mesh.Scale = Vector3.new(1.5, 1.5, 1.5)
        
        crown.CFrame = head.CFrame * CFrame.new(0, 1, 0)
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = crown
        weld.Part1 = head
        weld.Parent = crown
        crown.Parent = char
        table.insert(auraObjects, crown)
        
    elseif CONFIG.Visuals.Aura == "Orb" then
        local orb = Instance.new("Part")
        orb.Shape = Enum.PartType.Ball
        orb.Size = Vector3.new(2, 2, 2)
        orb.Transparency = 0.5
        orb.Color = CONFIG.Theme.Primary
        orb.Material = Enum.Material.Neon
        orb.CanCollide = false
        orb.Massless = true
        orb.CFrame = torso.CFrame * CFrame.new(0, 3, 0)
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = orb
        weld.Part1 = torso
        weld.Parent = orb
        orb.Parent = char
        table.insert(auraObjects, orb)
        
        local sparkles = Instance.new("ParticleEmitter", orb)
        sparkles.Texture = "rbxassetid://1316045217"
        sparkles.Rate = 100
        sparkles.Speed = NumberRange.new(1, 3)
        sparkles.Lifetime = NumberRange.new(0.5, 1)
        sparkles.Color = ColorSequence.new(CONFIG.Theme.Secondary)
        sparkles.Size = NumberSequence.new(0.5)
    end
end

local function updateTrail()
    safeDestroy(trailObject)
    trailObject = nil
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if CONFIG.Visuals.TrailType == "None" then return end
    
    local a0 = Instance.new("Attachment", hrp); a0.Position = Vector3.new(0, 2, 0)
    local a1 = Instance.new("Attachment", hrp); a1.Position = Vector3.new(0, -2, 0)
    local t = Instance.new("Trail", hrp)
    trailObject = t
    t.Attachment0 = a0; t.Attachment1 = a1
    t.Lifetime = 1
    t.WidthScale = NumberSequence.new(1.5, 0)
    t.FaceCamera = true
    
    if CONFIG.Visuals.TrailType == "Neon" then
        t.Color = ColorSequence.new(CONFIG.Theme.Primary, CONFIG.Theme.Secondary)
        t.Texture = "rbxassetid://446111271"
        t.LightEmission = 1
        
    elseif CONFIG.Visuals.TrailType == "Fire" then
        t.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 0, 0))
        t.Texture = "rbxassetid://446111271"
        t.LightEmission = 2
        
        local fire = Instance.new("ParticleEmitter", hrp)
        fire.Name = "FireTrailParticles"
        fire.Texture = "rbxassetid://1316045217"
        fire.Rate = 50
        fire.Speed = NumberRange.new(2, 5)
        fire.Lifetime = NumberRange.new(0.5, 1)
        fire.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
        fire.Size = NumberSequence.new(1)
        
    elseif CONFIG.Visuals.TrailType == "Ice" then
        t.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255), Color3.new(1,1,1))
        t.Texture = "rbxassetid://446111271"
        t.LightEmission = 1
        
    elseif CONFIG.Visuals.TrailType == "Rainbow" then
        t.Texture = "rbxassetid://446111271"
        t.LightEmission = 1
        task.spawn(function()
            while trailObject and trailObject.Parent do
                local h = tick() % 1
                trailObject.Color = ColorSequence.new(Color3.fromHSV(h, 1, 1), Color3.fromHSV((h + 0.5) % 1, 1, 1))
                task.wait(0.1)
            end
        end)
        
    elseif CONFIG.Visuals.TrailType == "Sparkle" then
        t.Color = ColorSequence.new(CONFIG.Theme.Primary, Color3.new(1,1,1))
        t.Texture = "rbxassetid://1316045217"
        t.LightEmission = 1
        t.Lifetime = 1.5
    end
end

--// VISUALS: WEATHER
local function resetWeather()
    if weatherFolder then safeDestroy(weatherFolder) end
    if colorCorrection then safeDestroy(colorCorrection) end
    if atmosphere then safeDestroy(atmosphere) end
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.Ambient = originalLighting.Ambient
    Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
end

local function updateWeather()
    resetWeather()
    if CONFIG.Visuals.Weather.Night then
        Lighting.ClockTime = 1
        Lighting.Ambient = Color3.fromRGB(50, 50, 70)
        Lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 80)
        colorCorrection = Instance.new("ColorCorrectionEffect", Lighting)
        colorCorrection.Brightness = 0.1
        colorCorrection.TintColor = Color3.fromRGB(120, 120, 180)
        atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.3
        atmosphere.Offset = 0.25
        atmosphere.Color = Color3.fromRGB(100, 120, 150)
    end
    
    if CONFIG.Visuals.Weather.Snow or CONFIG.Visuals.Weather.Rain then
        weatherFolder = Instance.new("Folder", workspace)
        local spawnPart = Instance.new("Part")
        spawnPart.Size = Vector3.new(1000, 1000, 1000) 
        spawnPart.Transparency = 1
        spawnPart.CanCollide = false
        spawnPart.Anchored = true
        spawnPart.Parent = weatherFolder
        
        if CONFIG.Visuals.Weather.Snow then
            local snow = Instance.new("ParticleEmitter", spawnPart)
            snow.Texture = "rbxassetid://1316045217"
            snow.Rate = 8000 -- Усиленный снегопад (в 4 раза больше)
            snow.Lifetime = NumberRange.new(5, 10)
            snow.Speed = NumberRange.new(5, 15)
            snow.SpreadAngle = Vector2.new(180, 180)
            snow.Acceleration = Vector3.new(3, -15, 3) -- Сильный ветер
            snow.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
            snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
            snow.RotSpeed = NumberRange.new(-180, 180)
            snow.EmissionDirection = Enum.NormalId.Top
        end
        
        if CONFIG.Visuals.Weather.Rain then
            local rain = Instance.new("ParticleEmitter", spawnPart)
            rain.Texture = "rbxassetid://9175180343"
            rain.Rate = 5000 -- Усиленный дождь
            rain.Lifetime = NumberRange.new(1, 2)
            rain.Speed = NumberRange.new(150, 200)
            rain.SpreadAngle = Vector2.new(0, 0)
            rain.Acceleration = Vector3.new(0, -250, 0)
            rain.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.2)})
            rain.Transparency = NumberSequence.new(0.3)
            rain.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
            rain.EmissionDirection = Enum.NormalId.Bottom 
        end
        
        task.spawn(function()
            while weatherFolder and weatherFolder.Parent and spawnPart.Parent do
                spawnPart.CFrame = Camera.CFrame * CFrame.new(0, 100, 0)
                task.wait()
            end
        end)
    end
end

--// ESP
local function createESP(player)
    if player == LocalPlayer then return end
    local function setup(char)
        if not char or not CONFIG.ESP.Enabled then return end
        local head = char:WaitForChild("Head", 5)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        if not head or not hrp or not hum then return end
        
        if espObjects[player] then
            safeDestroy(espObjects[player].highlight)
            safeDestroy(espObjects[player].billboard)
        end
        
        local hl = Instance.new("Highlight")
        hl.FillColor = CONFIG.Theme.Primary
        hl.FillTransparency = 0.6
        hl.OutlineColor = CONFIG.Theme.Secondary
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled = CONFIG.Visuals.Chams
        hl.Parent = char
        
        local bg = Instance.new("BillboardGui")
        bg.Adornee = head
        bg.Size = UDim2.new(0, 200, 0, 50)
        bg.StudsOffset = Vector3.new(0, 3, 0)
        bg.AlwaysOnTop = true
        bg.Enabled = CONFIG.Visuals.BoxESP
        bg.Parent = head
        
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextColor3 = CONFIG.Theme.Secondary
        nameLbl.TextSize = 13
        nameLbl.Font = Enum.Font.Code
        nameLbl.TextStrokeTransparency = 0
        nameLbl.Text = player.Name
        nameLbl.Parent = bg
        
        local infoLbl = Instance.new("TextLabel")
        infoLbl.Size = UDim2.new(1, 0, 0.5, 0)
        infoLbl.Position = UDim2.new(0, 0, 0.5, 0)
        infoLbl.BackgroundTransparency = 1
        infoLbl.TextColor3 = Color3.new(1,1,1)
        infoLbl.TextSize = 11
        infoLbl.Font = Enum.Font.Code
        infoLbl.TextStrokeTransparency = 0
        infoLbl.Parent = bg
        
        espObjects[player] = { highlight = hl, billboard = bg, infoLabel = infoLbl, nameLabel = nameLbl, humanoid = hum, root = hrp }
        
        task.spawn(function()
            while infoLbl.Parent and infoLbl.Parent.Parent do
                local txt = ""
                if CONFIG.ESP.ShowHealth then txt = txt .. string.format("HP:%d ", math.floor(hum.Health)) end
                if CONFIG.ESP.ShowDistance then
                    txt = txt .. string.format("[%dm]", math.floor((hrp.Position - Camera.CFrame.Position).Magnitude))
                end
                infoLbl.Text = txt
                task.wait(0.2)
            end
        end)
    end
    if player.Character then setup(player.Character) end
    if espObjects[player] and espObjects[player].conn then espObjects[player].conn:Disconnect() end
    if not espObjects[player] then espObjects[player] = {} end
    espObjects[player].conn = player.CharacterAdded:Connect(setup)
end

local function refreshESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then createESP(p) end
    end
end

Players.PlayerAdded:Connect(function(plr)
    if CONFIG.ESP.Enabled then createESP(plr) end
end)

--// FOV & AIMBOT
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "INF_FOV"; fovGui.ResetOnSpawn = false; fovGui.Parent = CoreGui
fovCircle = Instance.new("Frame")
fovCircle.Size = UDim2.new(0, CONFIG.Aimbot.FOV, 0, CONFIG.Aimbot.FOV)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.Parent = fovGui
local fovCorner = Instance.new("UICorner"); fovCorner.CornerRadius = UDim.new(1, 0); fovCorner.Parent = fovCircle
local fovStroke = Instance.new("UIStroke"); fovStroke.Color = CONFIG.Theme.Primary; fovStroke.Thickness = 2; fovStroke.Transparency = 0.3; fovStroke.Parent = fovCircle

local function updateFOVVisual()
    fovCircle.Size = UDim2.new(0, CONFIG.Aimbot.FOV, 0, CONFIG.Aimbot.FOV)
    fovCircle.Visible = CONFIG.Aimbot.Enabled
end

local function hasLineOfSight(targetPart)
    if not CONFIG.Aimbot.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera, weatherFolder}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel and Players:GetPlayerFromCharacter(hitModel) == Players:GetPlayerFromCharacter(targetPart.Parent) then
            return true 
        end
        return false 
    end
    return true 
end

local function getClosestTarget()
    local closest, closestDist = nil, math.huge
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                local targetPart = char:FindFirstChild(CONFIG.Aimbot.TargetPart) or root
                if hum and root and targetPart and hum.Health > 0 then
                    if not (CONFIG.Aimbot.TeamCheck and plr.Team == LocalPlayer.Team) then
                        if hasLineOfSight(targetPart) then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                            if onScreen then
                                local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                                if distToCenter <= CONFIG.Aimbot.FOV/2 then
                                    local worldDist = (root.Position - myRoot.Position).Magnitude
                                    if worldDist < closestDist then
                                        closestDist = worldDist
                                        closest = targetPart
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function startAimbot()
    if aimbotConn then aimbotConn:Disconnect() end
    CONFIG.Aimbot.Enabled = true; updateFOVVisual()
    aimbotConn = RunService.RenderStepped:Connect(function()
        if not CONFIG.Aimbot.Enabled then return end
        local t = getClosestTarget()
        if not t then return end
        local desired = CFrame.lookAt(Camera.CFrame.Position, t.Position)
        Camera.CFrame = Camera.CFrame:Lerp(desired, CONFIG.Aimbot.Smoothness)
    end)
end

local function stopAimbot()
    CONFIG.Aimbot.Enabled = false
    if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
    updateFOVVisual()
end

local function startRagebot()
    if ragebotConn then ragebotConn:Disconnect() end
    CONFIG.Ragebot.Enabled = true
    ragebotConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.Ragebot.Enabled then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local target = getClosestTarget()
        if target then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)
            local tool = myChar:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end
    end)
end

local function stopRagebot()
    CONFIG.Ragebot.Enabled = false
    if ragebotConn then ragebotConn:Disconnect(); ragebotConn = nil end
end

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InfinixHub"; ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 480)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 12); mc.Parent = Main
local MainStroke = Instance.new("UIStroke"); MainStroke.Color = CONFIG.Theme.Primary; MainStroke.Thickness = 2; MainStroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "♾️  INFINIX HUB  ♾️"
Title.TextColor3 = Color3.new(1,1,1); Title.TextSize = 15
Title.Font = Enum.Font.Code; Title.TextStrokeTransparency = 0; Title.Parent = Main
local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, CONFIG.Theme.Primary), ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, CONFIG.Theme.Primary)})
titleGrad.Rotation = 0
titleGrad.Parent = Title
table.insert(allGradients, titleGrad)

--// ВКЛАДКИ
local TabFrame = Instance.new("ScrollingFrame")
TabFrame.Size = UDim2.new(0.92, 0, 0, 28)
TabFrame.Position = UDim2.new(0.04, 0, 0, 32)
TabFrame.BackgroundTransparency = 1; TabFrame.BorderSizePixel = 0
TabFrame.ScrollBarThickness = 0
TabFrame.ScrollingDirection = Enum.ScrollingDirection.X
TabFrame.CanvasSize = UDim2.new(0, 500, 0, 0); TabFrame.Parent = Main
local tl = Instance.new("UIListLayout"); tl.FillDirection = Enum.FillDirection.Horizontal; tl.Padding = UDim.new(0, 4); tl.Parent = TabFrame

local Content = Instance.new("Frame")
Content.Size = UDim2.new(0.92, 0, 0, 380)
Content.Position = UDim2.new(0.04, 0, 0, 64)
Content.BackgroundTransparency = 1; Content.Parent = Main

local function makeTab(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundColor3 = Color3.fromRGB(20, 8, 35)
    sf.BackgroundTransparency = 0.4; sf.BorderSizePixel = 0
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.ScrollBarThickness = 4
    sf.Visible = false; sf.Parent = Content
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = sf
    local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0, 5); l.Parent = sf
    
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 20)
    end)
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 10, 60)
    btn.TextColor3 = Color3.new(1,1,1); btn.TextSize = 11; btn.Font = Enum.Font.Code; btn.Text = name
    btn.Parent = TabFrame
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn
    
    local bg = Instance.new("UIGradient")
    bg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, CONFIG.Theme.Primary), ColorSequenceKeypoint.new(0.5, CONFIG.Theme.Secondary), ColorSequenceKeypoint.new(1, CONFIG.Theme.Primary)})
    bg.Rotation = 0
    bg.Parent = btn
    table.insert(allGradients, bg)
    
    btn.MouseButton1Click:Connect(function()
        for _, v in ipairs(Content:GetChildren()) do 
            if v:IsA("ScrollingFrame") then 
                v.Visible = false 
            end 
        end
        sf.Visible = true
        for _, v in ipairs(TabFrame:GetChildren()) do 
            if v:IsA("TextButton") then 
                v.BackgroundColor3 = Color3.fromRGB(40, 10, 60) 
            end 
        end
        btn.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
        
        -- Анимация появления (Fade-in)
        sf.BackgroundTransparency = 1
        for _, v in ipairs(sf:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") then v.TextTransparency = 1 end
            if v:IsA("UIStroke") then v.Transparency = 1 end
        end
        
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(sf, tweenInfo, {BackgroundTransparency = 0.4}):Play()
        for _, v in ipairs(sf:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") then 
                TweenService:Create(v, tweenInfo, {TextTransparency = 0}):Play() 
            end
            if v:IsA("UIStroke") then 
                TweenService:Create(v, tweenInfo, {Transparency = 0.5}):Play() 
            end
        end
        
        if name == "FLING" then refreshPlayerList() end
    end)
    return sf
end

local Sc = makeTab("MAIN")
local CSc = makeTab("COMBAT")
local VSc = makeTab("VISUALS")
local GSc = makeTab("GUI")
local FSc = makeTab("FLING")
Sc.Visible = true

--// UI ELEMENTS
local function addToggle(text, initial, callback, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 32)
    btn.BackgroundColor3 = initial and Color3.fromRGB(120, 20, 200) or Color3.fromRGB(30, 12, 45)
    btn.TextColor3 = Color3.new(1,1,1); btn.TextSize = 12; btn.Font = Enum.Font.Code
    btn.Text = text .. ": " .. (initial and "ON" or "OFF")
    btn.BorderSizePixel = 0; btn.TextStrokeTransparency = 0.5; btn.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = btn
    local s = Instance.new("UIStroke"); s.Color = initial and Color3.new(1,1,1) or CONFIG.Theme.Primary; s.Thickness = 1; s.Transparency = initial and 0.3 or 0.7; s.Parent = btn
    
    table.insert(allToggles, btn)
    
    if initial then 
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, CONFIG.Theme.Primary), ColorSequenceKeypoint.new(0.5, CONFIG.Theme.Secondary), ColorSequenceKeypoint.new(1, CONFIG.Theme.Primary)})
        g.Parent = btn
        table.insert(allGradients, g)
    end
    
    btn.MouseButton1Click:Connect(function()
        local state = not (string.find(btn.Text, "ON") ~= nil)
        btn.Text = text .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(120, 20, 200) or Color3.fromRGB(30, 12, 45)
        s.Color = state and Color3.new(1,1,1) or CONFIG.Theme.Primary
        s.Transparency = state and 0.3 or 0.7
        for _, g in ipairs(btn:GetChildren()) do if g:IsA("UIGradient") then g:Destroy() end end
        if state then 
            local g = Instance.new("UIGradient")
            g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, CONFIG.Theme.Primary), ColorSequenceKeypoint.new(0.5, CONFIG.Theme.Secondary), ColorSequenceKeypoint.new(1, CONFIG.Theme.Primary)})
            g.Parent = btn
            table.insert(allGradients, g)
        end
        callback(state)
    end)
    return btn
end

local function addInput(label, value, callback, parent)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -8, 0, 50)
    container.BackgroundTransparency = 1; container.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16); lbl.BackgroundTransparency = 1
    lbl.Text = label; lbl.TextColor3 = CONFIG.Theme.Secondary; lbl.TextSize = 11
    lbl.Font = Enum.Font.Code; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = container
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 30); box.Position = UDim2.new(0, 0, 0, 18)
    box.BackgroundColor3 = Color3.fromRGB(25, 10, 38); box.TextColor3 = Color3.new(1,1,1)
    box.TextSize = 13; box.Font = Enum.Font.Code; box.Text = tostring(value)
    box.BorderSizePixel = 0; box.Parent = container
    
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = box
    local s = Instance.new("UIStroke"); s.Color = CONFIG.Theme.Primary; s.Thickness = 1; s.Transparency = 0.5; s.Parent = box
    
    box.FocusLost:Connect(function()
        local v = tonumber(box.Text)
        if v then callback(v) else box.Text = tostring(value) end
    end)
    return box
end

local function addButton(text, callback, parent, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -8, 0, 30)
    b.BackgroundColor3 = color or Color3.fromRGB(30, 12, 45)
    b.TextColor3 = Color3.new(1,1,1); b.TextSize = 12; b.Font = Enum.Font.Code; b.Text = text
    b.BorderSizePixel = 0; b.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = b
    b.MouseButton1Click:Connect(callback)
    return b
end

--// MAIN TAB
addToggle("FLY", CONFIG.Fly.Enabled, function(s) if s then startFly() else stopFly() end end, Sc)
addInput("FLY SPEED", CONFIG.Fly.Speed, function(v) CONFIG.Fly.Speed = math.clamp(v, 10, 500) end, Sc)
addToggle("NOCLIP", CONFIG.Noclip.Enabled, function(s) if s then enableNoclip() else disableNoclip() end end, Sc)
addToggle("SPEED HACK", CONFIG.Speed.Enabled, function(s) CONFIG.Speed.Enabled = s; applySpeed() end, Sc)
addInput("WALK SPEED", CONFIG.Speed.Value, function(v) CONFIG.Speed.Value = math.clamp(v, 1, 500); applySpeed() end, Sc)
addToggle("JUMP HACK", CONFIG.Jump.Enabled, function(s) CONFIG.Jump.Enabled = s; applyJump() end, Sc)
addInput("JUMP POWER", CONFIG.Jump.Value, function(v) CONFIG.Jump.Value = math.clamp(v, 1, 500); applyJump() end, Sc)

--// COMBAT TAB
addToggle("AIMBOT", CONFIG.Aimbot.Enabled, function(s) if s then startAimbot() else stopAimbot() end end, CSc)
addToggle("WALL CHECK", CONFIG.Aimbot.WallCheck, function(s) CONFIG.Aimbot.WallCheck = s end, CSc)
addInput("AIMBOT FOV", CONFIG.Aimbot.FOV, function(v) CONFIG.Aimbot.FOV = math.clamp(v, 20, 800); updateFOVVisual() end, CSc)
addInput("AIM SMOOTH", CONFIG.Aimbot.Smoothness, function(v) CONFIG.Aimbot.Smoothness = math.clamp(v, 0.05, 1) end, CSc)
addToggle("RAGEBOT (AUTO SHOOT)", CONFIG.Ragebot.Enabled, function(s) if s then startRagebot() else stopRagebot() end end, CSc)

--// VISUALS TAB
addToggle("SELF CHAMS", CONFIG.Visuals.SelfChams, function(s) CONFIG.Visuals.SelfChams = s; updateSelfChams() end, VSc)
addInput("SELF CHAMS FILL", CONFIG.Visuals.SelfChamsFill, function(v) CONFIG.Visuals.SelfChamsFill = math.clamp(v, 0, 1); updateSelfChams() end, VSc)
addInput("SELF CHAMS OUTLINE", CONFIG.Visuals.SelfChamsOutline, function(v) CONFIG.Visuals.SelfChamsOutline = math.clamp(v, 0, 1); updateSelfChams() end, VSc)
addToggle("ESP BOX", CONFIG.Visuals.BoxESP, function(s) CONFIG.Visuals.BoxESP = s; for _, o in pairs(espObjects) do if o.billboard then o.billboard.Enabled = s end end end, VSc)
addToggle("PLAYER CHAMS", CONFIG.Visuals.Chams, function(s) CONFIG.Visuals.Chams = s; for _, o in pairs(espObjects) do if o.highlight then o.highlight.Enabled = s end end end, VSc)
addInput("CAMERA FOV", CONFIG.Visuals.FOV, function(v) CONFIG.Visuals.FOV = math.clamp(v, 20, 120); Camera.FieldOfView = CONFIG.Visuals.FOV end, VSc)

-- Auras
local auraLbl = Instance.new("TextLabel")
auraLbl.Size = UDim2.new(1, -8, 0, 16); auraLbl.BackgroundTransparency = 1
auraLbl.Text = "SELECT AURA"; auraLbl.TextColor3 = CONFIG.Theme.Secondary; auraLbl.TextSize = 11
auraLbl.Font = Enum.Font.Code; auraLbl.TextXAlignment = Enum.TextXAlignment.Left; auraLbl.Parent = VSc

local auraFrame = Instance.new("Frame")
auraFrame.Size = UDim2.new(1, -8, 0, 30)
auraFrame.BackgroundTransparency = 1; auraFrame.Parent = VSc
local al = Instance.new("UIListLayout"); al.FillDirection = Enum.FillDirection.Horizontal; al.Padding = UDim.new(0, 4); al.Parent = auraFrame

for _, aName in ipairs({"None", "Halo", "Wings", "Crown", "Orb"}) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.19, 0, 1, 0)
    b.BackgroundColor3 = (CONFIG.Visuals.Aura == aName) and Color3.fromRGB(100, 0, 150) or Color3.fromRGB(30, 12, 45)
    b.TextColor3 = Color3.new(1,1,1); b.TextSize = 9; b.Font = Enum.Font.Code; b.Text = aName
    b.Parent = auraFrame
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 4); c.Parent = b
    b.MouseButton1Click:Connect(function()
        CONFIG.Visuals.Aura = aName
        for _, btn in ipairs(auraFrame:GetChildren()) do
            if btn:IsA("TextButton") then btn.BackgroundColor3 = (btn.Text == aName) and Color3.fromRGB(100, 0, 150) or Color3.fromRGB(30, 12, 45) end
        end
        updateAura()
    end)
end

-- Trails
local trailLbl = Instance.new("TextLabel")
trailLbl.Size = UDim2.new(1, -8, 0, 16); trailLbl.BackgroundTransparency = 1
trailLbl.Text = "SELECT TRAIL"; trailLbl.TextColor3 = CONFIG.Theme.Secondary; trailLbl.TextSize = 11
trailLbl.Font = Enum.Font.Code; trailLbl.TextXAlignment = Enum.TextXAlignment.Left; trailLbl.Parent = VSc

local trailFrame = Instance.new("Frame")
trailFrame.Size = UDim2.new(1, -8, 0, 30)
trailFrame.BackgroundTransparency = 1; trailFrame.Parent = VSc
local trl = Instance.new("UIListLayout"); trl.FillDirection = Enum.FillDirection.Horizontal; trl.Padding = UDim.new(0, 4); trl.Parent = trailFrame

for _, tName in ipairs({"None", "Neon", "Fire", "Ice", "Rainbow", "Sparkle"}) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.15, 0, 1, 0)
    b.BackgroundColor3 = (CONFIG.Visuals.TrailType == tName) and Color3.fromRGB(100, 0, 150) or Color3.fromRGB(30, 12, 45)
    b.TextColor3 = Color3.new(1,1,1); b.TextSize = 8; b.Font = Enum.Font.Code; b.Text = tName
    b.Parent = trailFrame
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 4); c.Parent = b
    b.MouseButton1Click:Connect(function()
        CONFIG.Visuals.TrailType = tName
        for _, btn in ipairs(trailFrame:GetChildren()) do
            if btn:IsA("TextButton") then btn.BackgroundColor3 = (btn.Text == tName) and Color3.fromRGB(100, 0, 150) or Color3.fromRGB(30, 12, 45) end
        end
        updateTrail()
    end)
end

-- Weather
addToggle("SNOW", CONFIG.Visuals.Weather.Snow, function(s) CONFIG.Visuals.Weather.Snow = s; updateWeather() end, VSc)
addToggle("RAIN", CONFIG.Visuals.Weather.Rain, function(s) CONFIG.Visuals.Weather.Rain = s; updateWeather() end, VSc)
addToggle("NIGHT", CONFIG.Visuals.Weather.Night, function(s) CONFIG.Visuals.Weather.Night = s; updateWeather() end, VSc)

--// GUI TAB (THEME CHANGER)
local function applyTheme(p, s)
    CONFIG.Theme.Primary = p
    CONFIG.Theme.Secondary = s
    
    Main.BackgroundColor3 = Color3.new(p.R * 0.1, p.G * 0.1, p.B * 0.1) 
    MainStroke.Color = p
    fovStroke.Color = p
    Reopen.BackgroundColor3 = p
    
    for _, v in ipairs(Content:GetChildren()) do
        if v:IsA("ScrollingFrame") then
            v.BackgroundColor3 = Color3.new(p.R * 0.08, p.G * 0.08, p.B * 0.08)
            v.ScrollBarImageColor3 = p
        end
    end
    
    for _, g in ipairs(allGradients) do
        if g and g.Parent then
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, p),
                ColorSequenceKeypoint.new(0.5, s),
                ColorSequenceKeypoint.new(1, p)
            })
        end
    end
    
    for _, obj in ipairs(Main:GetDescendants()) do
        if obj:IsA("UIStroke") and obj ~= MainStroke then
            if obj.Color ~= Color3.fromRGB(60,0,20) then obj.Color = p end
        end
        if obj:IsA("TextBox") then
            obj.BackgroundColor3 = Color3.new(p.R * 0.05, p.G * 0.05, p.B * 0.05)
        end
        if obj:IsA("TextLabel") and obj.TextColor3 ~= Color3.new(1,1,1) then
            obj.TextColor3 = s
        end
    end
    
    for _, btn in ipairs(allToggles) do
        local isOn = string.find(btn.Text, "ON") ~= nil
        if isOn then
            btn.BackgroundColor3 = Color3.new(p.R * 0.5, p.G * 0.5, p.B * 0.5)
        else
            btn.BackgroundColor3 = Color3.fromRGB(30, 12, 45)
        end
        for _, child in ipairs(btn:GetChildren()) do
            if child:IsA("UIStroke") then child.Color = p end
        end
    end
    
    for _, o in pairs(espObjects) do
        if o.highlight then o.highlight.FillColor = p; o.highlight.OutlineColor = s end
        if o.nameLabel then o.nameLabel.TextColor3 = s end
    end
    
    if selfHighlight then selfHighlight.FillColor = p; selfHighlight.OutlineColor = s end
    
    for _, obj in pairs(auraObjects) do
        if obj:IsA("BasePart") then obj.Color = p end
    end
    updateTrail()
end

local function startRainbow()
    stopRainbow()
    rainbowConn = RunService.RenderStepped:Connect(function()
        local h = (tick() * 0.1) % 1
        local c1 = Color3.fromHSV(h, 0.8, 1)
        local c2 = Color3.fromHSV((h + 0.3) % 1, 0.8, 1)
        applyTheme(c1, c2)
    end)
end

local function stopRainbow()
    if rainbowConn then rainbowConn:Disconnect(); rainbowConn = nil end
end

local themeNames = {"Purple/Pink", "Red/Orange", "Blue/Cyan", "Green/Lime"}
local themeData = {
    ["Purple/Pink"] = {Color3.fromRGB(180, 0, 255), Color3.fromRGB(255, 150, 255)},
    ["Red/Orange"] = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 150, 0)},
    ["Blue/Cyan"] = {Color3.fromRGB(0, 100, 255), Color3.fromRGB(0, 255, 255)},
    ["Green/Lime"] = {Color3.fromRGB(0, 255, 0), Color3.fromRGB(150, 255, 0)}
}

for _, tName in ipairs(themeNames) do
    addButton(tName, function()
        stopRainbow()
        local colors = themeData[tName]
        applyTheme(colors[1], colors[2])
    end, GSc)
end

addToggle("RAINBOW MODE", false, function(s)
    if s then startRainbow() else stopRainbow() end
end, GSc)

--// FLING TAB
local pL = Instance.new("UIListLayout"); pL.Padding = UDim.new(0, 4); pL.Parent = FSc
local flingBtn = Instance.new("TextButton")
flingBtn.Size = UDim2.new(1, -8, 0, 40)
flingBtn.Position = UDim2.new(0, 0, 1, -40)
flingBtn.Text = "FLING SELECTED"
flingBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
flingBtn.TextColor3 = Color3.new(1,1,1); flingBtn.TextSize = 14; flingBtn.Font = Enum.Font.Code; flingBtn.Parent = FSc

function refreshPlayerList()
    for _, v in ipairs(FSc:GetChildren()) do
        if v:IsA("TextButton") and v ~= flingBtn then v:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -8, 0, 30)
            b.BackgroundColor3 = Color3.fromRGB(30, 12, 45)
            b.TextColor3 = Color3.new(1,1,1); b.TextSize = 12; b.Font = Enum.Font.Code; b.Text = p.Name
            b.Parent = FSc
            b.MouseButton1Click:Connect(function()
                CONFIG.Fling.Target = p
                flingBtn.Text = "FLING: " .. p.Name
                for _, bt in ipairs(FSc:GetChildren()) do
                    if bt:IsA("TextButton") and bt ~= flingBtn then bt.BackgroundColor3 = Color3.fromRGB(30, 12, 45) end
                end
                b.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
            end)
        end
    end
    FSc.CanvasSize = UDim2.new(0, 0, 0, pL.AbsoluteContentSize.Y + 10)
end

local function executeFling(target)
    if not target or not target.Character then return end
    local myChar = LocalPlayer.Character
    local tChar = target.Character
    if not myChar or not tChar then return end
    local r1 = myChar:FindFirstChild("HumanoidRootPart")
    local torso = tChar:FindFirstChild("UpperTorso") or tChar:FindFirstChild("Torso") or tChar:FindFirstChild("HumanoidRootPart")
    if not r1 or not torso then return end
    
    local origCF = r1.CFrame
    local wasNoclip = CONFIG.Noclip.Enabled
    if wasNoclip then disableNoclip() end
    
    for _, v in ipairs(myChar:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = true end end
    for _, v in ipairs(tChar:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = true end end
    
    pcall(function() torso:SetNetworkOwner(LocalPlayer) end)
    local bav = Instance.new("BodyAngularVelocity")
    bav.AngularVelocity = Vector3.new(1e5, 1e5, 1e5)
    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bav.Parent = torso
    
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(CONFIG.Fling.Velocity, CONFIG.Fling.Velocity, CONFIG.Fling.Velocity)
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = torso
    
    local startTime = tick()
    while tick() - startTime < 3 do
        if not r1.Parent or not torso.Parent then break end
        local ox = math.random(-20, 20) / 10
        local oz = math.random(-20, 20) / 10
        r1.CFrame = torso.CFrame * CFrame.new(ox, 0, oz)
        r1.AssemblyLinearVelocity = Vector3.new(math.random(-5000, 5000), 5000, math.random(-5000, 5000))
        task.wait(0.02)
    end
    
    safeDestroy(bav); safeDestroy(bv)
    r1.CFrame = origCF
    r1.AssemblyLinearVelocity = Vector3.zero
    r1.Velocity = Vector3.zero
    if wasNoclip then enableNoclip() end
end

flingBtn.MouseButton1Click:Connect(function()
    if CONFIG.Fling.Target then task.spawn(function() executeFling(CONFIG.Fling.Target) end) end
end)

--// CLOSE / OPEN & CUBE
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 20)
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.TextSize = 15; CloseBtn.Font = Enum.Font.Code; CloseBtn.Text = "X"
CloseBtn.BorderSizePixel = 0; CloseBtn.ZIndex = 10; CloseBtn.Parent = Main
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 5); cc.Parent = CloseBtn

local Reopen = Instance.new("TextButton")
Reopen.Size = UDim2.new(0, 50, 0, 50)
Reopen.Position = UDim2.new(0.5, -25, 0.5, -25)
Reopen.BackgroundColor3 = CONFIG.Theme.Primary
Reopen.TextColor3 = Color3.new(1,1,1); Reopen.TextSize = 24; Reopen.Font = Enum.Font.Code
Reopen.Text = "♾️"; Reopen.BorderSizePixel = 0; Reopen.TextStrokeTransparency = 0.5
Reopen.Parent = ScreenGui; Reopen.Visible = false
local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 10); rc.Parent = Reopen
local rs = Instance.new("UIStroke"); rs.Color = Color3.new(1,1,1); rs.Thickness = 2; rs.Transparency = 0.4; rs.Parent = Reopen
local rGrad = Instance.new("UIGradient")
rGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, CONFIG.Theme.Primary), ColorSequenceKeypoint.new(1, CONFIG.Theme.Secondary)})
rGrad.Rotation = 135
rGrad.Parent = Reopen
table.insert(allGradients, rGrad)

CloseBtn.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    })
    tween:Play()
    tween.Completed:Wait()
    Main.Visible = false
    Main.Size = UDim2.new(0, 300, 0, 480)
    Main.BackgroundTransparency = 0
    Reopen.Visible = true
end)

-- Логика куба
local cubeDragging = false
local cubeStartPos = nil
local cubeMoved = false
local TAP_THRESHOLD = 8

Reopen.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        cubeDragging = true
        cubeMoved = false
        cubeStartPos = i.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then
                cubeDragging = false
                if not cubeMoved then
                    Reopen.Visible = false
                    Main.Visible = true
                    Main.Size = UDim2.new(0, 0, 0, 0)
                    local tween = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 300, 0, 480)
                    })
                    tween:Play()
                end
            end
        end)
    end
end)

Reopen.InputChanged:Connect(function(i)
    if cubeDragging and i.UserInputType == Enum.UserInputType.Touch and cubeStartPos then
        local d = i.Position - cubeStartPos
        if d.Magnitude > TAP_THRESHOLD then
            cubeMoved = true
        end
        if cubeMoved then
            Reopen.Position = UDim2.new(0, Reopen.AbsolutePosition.X + d.X, 0, Reopen.AbsolutePosition.Y + d.Y)
            Reopen.AnchorPoint = Vector2.new(0, 0)
            cubeStartPos = i.Position
        end
    end
end)

--// MOBILE DRAG (Main)
local drag, dStart, sPos
Title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        drag = true; dStart = i.Position; sPos = Main.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end)
    end
end)
Title.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - dStart
        Main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
    end
end)

--// INIT
enableNoclip()
refreshESP()
applySpeed()
applyJump()
updateFOVVisual()
updateSelfChams()
updateAura()
updateTrail()
updateWeather()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if CONFIG.Noclip.Enabled then enableNoclip() end
    if CONFIG.Speed.Enabled then applySpeed() end
    if CONFIG.Jump.Enabled then applyJump() end
    if CONFIG.Fly.Enabled then stopFly(); startFly() end
    if CONFIG.Visuals.SelfChams then updateSelfChams() end
    updateAura()
    updateTrail()
end)

print("[InfinixHub] Ultimate Edition v9 (High-Quality Visuals).")