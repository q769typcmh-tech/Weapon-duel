-- Moon Hub | Jailbird
-- No Kill Aura
-- Made by mr larper

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Moon Hub | Jailbird",
    Footer = "by mr larper",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Combat = Window:AddTab("Combat", "crosshair"),
    Player = Window:AddTab("Player", "user"),
    Mobile = Window:AddTab("Mobile", "smartphone"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Misc = Window:AddTab("Misc", "settings"),
    Settings = Window:AddTab("Settings", "settings"),
}

local ESPEnabled = false
local ShowBoxes = true
local ShowCorners = true
local ShowSkeleton = false
local ShowTracers = false
local ShowHealth = false
local ESPColor = Color3.fromRGB(170, 0, 255)
local TracerOrigin = "Bottom"

local AimbotEnabled = false
local AimbotActive = false
local AimbotMode = "Hold"
local AimKey = Enum.UserInputType.MouseButton2
local AimFOV = 120
local AimSmooth = 0.2
local ShowFOV = false

local WallCheck = true
local TeamCheck = true

local TriggerbotEnabled = false
local TriggerbotFOV = 40
local TriggerbotDelay = 0.08
local lastShot = 0

local NoRecoilEnabled = false
local RecoilStrength = 0
local Shooting = false
local lastPitch = 0
local recoilTables = {}

local SpeedEnabled = false
local SpeedValue = 24
local NoclipEnabled = false
local noclipConn = nil

local ShowPerf = true

local KEY_MAP = {
    MB1 = Enum.UserInputType.MouseButton1,
    MB2 = Enum.UserInputType.MouseButton2,
    E = Enum.KeyCode.E,
    Q = Enum.KeyCode.Q,
    F = Enum.KeyCode.F,
}

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Shooting = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Shooting = false
    end
end)

local function isAlive(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not TeamCheck then return true end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    return true
end

local function isSkipPart(part)
    if not part then return true end
    if part.Transparency >= 0.85 then return true end
    local n = string.lower(part.Name)
    local full = string.lower(part:GetFullName())
    if string.find(full, "cameramodel", 1, true) then return true end
    if string.find(full, "workspace.camera", 1, true) then return true end
    if string.find(n, "viewmodel", 1, true) then return true end
    if string.find(n, "arms", 1, true) then return true end
    if string.find(n, "anim", 1, true) and string.find(full, "camera", 1, true) then return true end
    return false
end

local function isVisible(player)
    if not WallCheck then return true end
    local char = player.Character
    if not char then return false end
    local head = char:FindFirstChild("Head")
    if not head then return false end

    local myChar = LocalPlayer.Character
    local filterList = {char}
    if myChar then table.insert(filterList, myChar) end
    local wsCam = workspace:FindFirstChild("Camera")
    if wsCam then table.insert(filterList, wsCam) end
    if Camera then table.insert(filterList, Camera) end

    local origin = Camera.CFrame.Position
    local goal = head.Position
    local totalDir = goal - origin
    local totalDist = totalDir.Magnitude
    if totalDist <= 0 then return true end

    local direction = totalDir.Unit
    local traveled = 0
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = filterList
    params.IgnoreWater = true

    for _ = 1, 8 do
        local remaining = totalDist - traveled
        if remaining <= 0.05 then return true end
        local result = workspace:Raycast(origin, direction * remaining, params)
        if not result then return true end
        local hit = result.Instance
        local hitDist = (result.Position - origin).Magnitude
        if isSkipPart(hit) then
            table.insert(filterList, hit)
            params.FilterDescendantsInstances = filterList
            origin = result.Position + direction * 0.15
            traveled = traveled + hitDist + 0.15
        else
            return false
        end
    end
    return false
end

local function getClosest(maxFOV, requireVisible)
    local closest, shortest = nil, maxFOV
    local center = Camera.ViewportSize / 2
    for _, player in pairs(Players:GetPlayers()) do
        if isEnemy(player) and player.Character and isAlive(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortest then
                        if (not requireVisible) or isVisible(player) then
                            shortest = dist
                            closest = head
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- SPEED
RunService.Heartbeat:Connect(function()
    if not SpeedEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 and hum.WalkSpeed ~= SpeedValue then
        hum.WalkSpeed = SpeedValue
    end
end)

pcall(function()
    if hookmetamethod and newcclosure then
        local old
        old = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
            if SpeedEnabled and key == "WalkSpeed" and typeof(self) == "Instance" and self:IsA("Humanoid") then
                local char = LocalPlayer.Character
                if char and self == char:FindFirstChildOfClass("Humanoid") then
                    return old(self, key, SpeedValue)
                end
            end
            return old(self, key, value)
        end))
    end
end)

-- NOCLIP
local function setNoclip(on)
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    if not on then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        return
    end
    noclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    if SpeedEnabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = SpeedValue end
    end
    if NoclipEnabled then setNoclip(true) end
end)

-- NO RECOIL
local function scanRecoilTables()
    recoilTables = {}
    if not getgc then return end
    pcall(function()
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                local has = rawget(v, "Recoil") or rawget(v, "recoil")
                    or rawget(v, "Kick") or rawget(v, "kick")
                    or rawget(v, "CameraKick") or rawget(v, "RecoilPower")
                    or rawget(v, "VerticalRecoil") or rawget(v, "RecoilUp")
                if has then table.insert(recoilTables, v) end
            end
        end
    end)
end

task.spawn(function()
    task.wait(2)
    scanRecoilTables()
end)

RunService.RenderStepped:Connect(function()
    if not NoRecoilEnabled then
        lastPitch = select(1, Camera.CFrame:ToOrientation())
        return
    end
    for _, t in ipairs(recoilTables) do
        pcall(function()
            for _, key in ipairs({"Recoil","recoil","Kick","kick","CameraKick","RecoilPower","VerticalRecoil","RecoilUp","RecoilX","RecoilY"}) do
                local val = rawget(t, key)
                if type(val) == "number" then rawset(t, key, val * RecoilStrength) end
            end
        end)
    end
    if Shooting and RecoilStrength < 1 then
        local cf = Camera.CFrame
        local pitch, yaw, roll = cf:ToOrientation()
        if pitch > lastPitch then
            local mixed = lastPitch + (pitch - lastPitch) * RecoilStrength
            Camera.CFrame = CFrame.new(cf.Position) * CFrame.fromOrientation(mixed, yaw, roll)
            pitch = mixed
        end
        lastPitch = pitch
    else
        lastPitch = select(1, Camera.CFrame:ToOrientation())
    end
end)

-- FPS + MS
local function makeText(size, color)
    local t = Drawing.new("Text")
    t.Size = size
    t.Center = false
    t.Outline = true
    t.OutlineColor = Color3.new(0, 0, 0)
    t.Color = color
    t.Font = 2
    t.Visible = false
    return t
end

local fpsLabel = makeText(22, Color3.fromRGB(180, 180, 180))
local fpsValue = makeText(28, Color3.fromRGB(0, 255, 170))
local msLabel = makeText(22, Color3.fromRGB(180, 180, 180))
local msValue = makeText(28, Color3.fromRGB(0, 200, 255))
local hubTag = makeText(16, Color3.fromRGB(170, 0, 255))
local fpsFrames, fpsLast, currentFPS = 0, tick(), 0

RunService.RenderStepped:Connect(function()
    fpsFrames += 1
    if tick() - fpsLast >= 1 then
        currentFPS = fpsFrames
        fpsFrames = 0
        fpsLast = tick()
    end
    local right = Camera.ViewportSize.X - 18
    fpsLabel.Position = Vector2.new(right - 110, 14)
    fpsValue.Position = Vector2.new(right - 55, 10)
    msLabel.Position = Vector2.new(right - 110, 44)
    msValue.Position = Vector2.new(right - 55, 40)
    hubTag.Position = Vector2.new(right - 100, 74)
    if ShowPerf then
        local ms = 0
        pcall(function()
            ms = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        fpsLabel.Text = "FPS"
        fpsLabel.Visible = true
        fpsValue.Text = tostring(currentFPS)
        fpsValue.Color = currentFPS >= 50 and Color3.fromRGB(0, 255, 160)
            or currentFPS >= 30 and Color3.fromRGB(255, 210, 40)
            or Color3.fromRGB(255, 55, 55)
        fpsValue.Visible = true
        msLabel.Text = "MS"
        msLabel.Visible = true
        msValue.Text = tostring(ms)
        msValue.Color = ms <= 80 and Color3.fromRGB(80, 200, 255)
            or ms <= 150 and Color3.fromRGB(255, 210, 40)
            or Color3.fromRGB(255, 55, 55)
        msValue.Visible = true
        hubTag.Text = "✦ MOON HUB"
        hubTag.Visible = true
    else
        fpsLabel.Visible = false
        fpsValue.Visible = false
        msLabel.Visible = false
        msValue.Visible = false
        hubTag.Visible = false
    end
end)

-- AIMBOT
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.NumSides = 64
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Transparency = 0.7
fovCircle.Visible = false

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Camera.ViewportSize / 2
    fovCircle.Radius = AimFOV
    fovCircle.Visible = ShowFOV and AimbotEnabled
    local active = AimbotActive or AimbotMode == "Always"
    if AimbotEnabled and active then
        local target = getClosest(AimFOV, true)
        if target then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), AimSmooth)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not AimbotEnabled or AimbotMode == "Always" then return end
    if input.UserInputType == AimKey or input.KeyCode == AimKey then
        if AimbotMode == "Hold" then
            AimbotActive = true
        else
            AimbotActive = not AimbotActive
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if AimbotMode == "Hold" and (input.UserInputType == AimKey or input.KeyCode == AimKey) then
        AimbotActive = false
    end
end)

local function doShoot()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
    end
    pcall(function()
        local pos = UserInputService:GetMouseLocation()
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait()
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
end

RunService.RenderStepped:Connect(function()
    if not TriggerbotEnabled then return end
    local target = getClosest(TriggerbotFOV, WallCheck)
    if target and tick() - lastShot >= TriggerbotDelay then
        lastShot = tick()
        doShoot()
    end
end)

-- ESP
local ESP = {}
local SKELETON_BONES = {
    {"Head", "UpperTorso"}, {"Head", "Torso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"UpperTorso", "RightUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"}, {"RightUpperArm", "RightLowerArm"},
    {"LeftLowerArm", "LeftHand"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LowerTorso", "RightUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"}, {"RightUpperLeg", "RightLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"}, {"RightLowerLeg", "RightFoot"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local function removeESP(player)
    local data = ESP[player]
    if not data then return end
    pcall(function()
        if data.Box then data.Box:Remove() end
        if data.Tracer then data.Tracer:Remove() end
        if data.HealthBox then data.HealthBox:Remove() end
        if data.HealthFill then data.HealthFill:Remove() end
        for _, l in pairs(data.Lines or {}) do if l then l:Remove() end end
        for _, l in pairs(data.Bones or {}) do if l then l:Remove() end end
    end)
    ESP[player] = nil
end

local function createESP(player)
    if ESP[player] then return end
    local function dnew(t)
        local ok, o = pcall(function() return Drawing.new(t) end)
        return ok and o or nil
    end
    local box = dnew("Square")
    if not box then return end
    box.Thickness = 1.5
    box.Filled = false
    box.Color = ESPColor
    box.Visible = false
    local lines = {}
    for i = 1, 8 do
        local l = dnew("Line")
        if l then l.Thickness = 1.5; l.Color = ESPColor; l.Visible = false; lines[i] = l end
    end
    local bones = {}
    for i = 1, #SKELETON_BONES do
        local l = dnew("Line")
        if l then l.Thickness = 1.5; l.Color = ESPColor; l.Visible = false; bones[i] = l end
    end
    local tracer = dnew("Line")
    if tracer then tracer.Thickness = 1.5; tracer.Color = ESPColor; tracer.Visible = false end
    local healthBox = dnew("Square")
    if healthBox then healthBox.Thickness = 1; healthBox.Filled = false; healthBox.Color = Color3.new(0,0,0); healthBox.Visible = false end
    local healthFill = dnew("Square")
    if healthFill then healthFill.Thickness = 1; healthFill.Filled = true; healthFill.Color = Color3.fromRGB(0,255,0); healthFill.Visible = false end
    ESP[player] = {Box = box, Lines = lines, Bones = bones, Tracer = tracer, HealthBox = healthBox, HealthFill = healthFill}
end

local function hookPlayer(player)
    if player == LocalPlayer then return end
    local function onCharacter(char)
        removeESP(player)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.Died:Connect(function() removeESP(player) end)
        end
        char.AncestryChanged:Connect(function(_, parent)
            if not parent then removeESP(player) end
        end)
    end
    if player.Character then onCharacter(player.Character) end
    player.CharacterAdded:Connect(onCharacter)
    player.CharacterRemoving:Connect(function() removeESP(player) end)
end

for _, p in pairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(removeESP)

task.spawn(function()
    while true do
        task.wait(0.5)
        for player in pairs(ESP) do
            if not player.Parent or not isAlive(player) or not isEnemy(player) then
                removeESP(player)
            end
        end
    end
end)

local function getTracerStart()
    local vs = Camera.ViewportSize
    if TracerOrigin == "Center" then return vs / 2 end
    if TracerOrigin == "Mouse" then return UserInputService:GetMouseLocation() end
    return Vector2.new(vs.X / 2, vs.Y)
end

RunService.RenderStepped:Connect(function()
    if not ESPEnabled then
        for p in pairs(ESP) do removeESP(p) end
        return
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if isEnemy(player) and player.Character and isAlive(player) then
            if not ESP[player] then createESP(player) end
            local data = ESP[player]
            if not data then continue end
            local char = player.Character
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not root or not head then removeESP(player) continue end
            local vector, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.2, 0))
                local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.8, 0))
                local height = math.abs(bottom.Y - top.Y)
                local width = math.clamp(height / 1.8, 8, 120)
                local size = Vector2.new(width, height)
                local pos = Vector2.new(vector.X - size.X / 2, top.Y)
                local cl = math.clamp(size.X * 0.25, 4, 14)

                if ShowBoxes then
                    data.Box.Size = size
                    data.Box.Position = pos
                    data.Box.Color = ESPColor
                    data.Box.Visible = true
                else
                    data.Box.Visible = false
                end

                if ShowCorners and data.Lines[1] then
                    local L = data.Lines
                    L[1].From = pos; L[1].To = Vector2.new(pos.X, pos.Y + cl)
                    L[2].From = pos; L[2].To = Vector2.new(pos.X + cl, pos.Y)
                    L[3].From = Vector2.new(pos.X + size.X, pos.Y); L[3].To = Vector2.new(pos.X + size.X, pos.Y + cl)
                    L[4].From = Vector2.new(pos.X + size.X, pos.Y); L[4].To = Vector2.new(pos.X + size.X - cl, pos.Y)
                    L[5].From = Vector2.new(pos.X, pos.Y + size.Y); L[5].To = Vector2.new(pos.X, pos.Y + size.Y - cl)
                    L[6].From = Vector2.new(pos.X, pos.Y + size.Y); L[6].To = Vector2.new(pos.X + cl, pos.Y + size.Y)
                    L[7].From = Vector2.new(pos.X + size.X, pos.Y + size.Y); L[7].To = Vector2.new(pos.X + size.X, pos.Y + size.Y - cl)
                    L[8].From = Vector2.new(pos.X + size.X, pos.Y + size.Y); L[8].To = Vector2.new(pos.X + size.X - cl, pos.Y + size.Y)
                    for i = 1, 8 do if L[i] then L[i].Color = ESPColor; L[i].Visible = true end end
                else
                    for _, l in pairs(data.Lines) do if l then l.Visible = false end end
                end

                if ShowSkeleton then
                    for i, bone in ipairs(SKELETON_BONES) do
                        local line = data.Bones[i]
                        if line then
                            local p0 = char:FindFirstChild(bone[1])
                            local p1 = char:FindFirstChild(bone[2])
                            if p0 and p1 then
                                local a, oa = Camera:WorldToViewportPoint(p0.Position)
                                local b, ob = Camera:WorldToViewportPoint(p1.Position)
                                if oa and ob then
                                    line.From = Vector2.new(a.X, a.Y)
                                    line.To = Vector2.new(b.X, b.Y)
                                    line.Color = ESPColor
                                    line.Visible = true
                                else
                                    line.Visible = false
                                end
                            else
                                line.Visible = false
                            end
                        end
                    end
                else
                    for _, l in pairs(data.Bones) do if l then l.Visible = false end end
                end

                if ShowTracers and data.Tracer then
                    local feet = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))
                    data.Tracer.From = getTracerStart()
                    data.Tracer.To = Vector2.new(feet.X, feet.Y)
                    data.Tracer.Color = ESPColor
                    data.Tracer.Visible = true
                elseif data.Tracer then
                    data.Tracer.Visible = false
                end

                if ShowHealth and hum and data.HealthBox and data.HealthFill then
                    local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    data.HealthBox.Size = Vector2.new(3, size.Y)
                    data.HealthBox.Position = Vector2.new(pos.X - 6, pos.Y)
                    data.HealthBox.Visible = true
                    local fillH = size.Y * pct
                    data.HealthFill.Size = Vector2.new(2, fillH)
                    data.HealthFill.Position = Vector2.new(pos.X - 5.5, pos.Y + (size.Y - fillH))
                    data.HealthFill.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
                    data.HealthFill.Visible = true
                else
                    if data.HealthBox then data.HealthBox.Visible = false end
                    if data.HealthFill then data.HealthFill.Visible = false end
                end
            else
                data.Box.Visible = false
                for _, l in pairs(data.Lines) do if l then l.Visible = false end end
                for _, l in pairs(data.Bones) do if l then l.Visible = false end end
                if data.Tracer then data.Tracer.Visible = false end
                if data.HealthBox then data.HealthBox.Visible = false end
                if data.HealthFill then data.HealthFill.Visible = false end
            end
        else
            removeESP(player)
        end
    end
end)

-- Potato
local oldLighting, materialCache = {}, {}
local function enablePotato()
    oldLighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    }
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 2
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    materialCache = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local skip = false
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character and v:IsDescendantOf(plr.Character) then skip = true break end
            end
            if not skip then
                materialCache[v] = v.Material
                pcall(function()
                    v.Material = Enum.Material.SmoothPlastic
                    v.Reflectance = 0
                end)
            end
        end
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
            pcall(function() v.Enabled = false end)
        end
    end
end

local function disablePotato()
    pcall(function()
        if oldLighting.GlobalShadows ~= nil then
            Lighting.GlobalShadows = oldLighting.GlobalShadows
            Lighting.FogEnd = oldLighting.FogEnd
            Lighting.Brightness = oldLighting.Brightness
            Lighting.EnvironmentDiffuseScale = oldLighting.EnvironmentDiffuseScale
            Lighting.EnvironmentSpecularScale = oldLighting.EnvironmentSpecularScale
        end
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end)
    for part, mat in pairs(materialCache) do
        if part and part.Parent then pcall(function() part.Material = mat end) end
    end
    materialCache = {}
end

-- UI
local CombatBox = Tabs.Combat:AddLeftGroupbox("Aimbot")
CombatBox:AddToggle("Aimbot", {Text = "Aimbot", Default = false, Callback = function(v) AimbotEnabled = v; if not v then AimbotActive = false end end})
CombatBox:AddDropdown("AimKey", {Text = "Aim Key", Values = {"MB1","MB2","E","Q","F"}, Default = 2, Callback = function(v) AimKey = KEY_MAP[v] or Enum.UserInputType.MouseButton2 end})
CombatBox:AddDropdown("AimMode", {Text = "Aim Mode", Values = {"Hold","Toggle","Always"}, Default = 1, Callback = function(v) AimbotMode = v; AimbotActive = (v == "Always") end})
CombatBox:AddSlider("AimFOV", {Text = "Aim FOV", Default = 120, Min = 40, Max = 350, Rounding = 0, Callback = function(v) AimFOV = v end})
CombatBox:AddSlider("AimSmooth", {Text = "Aim Smooth", Default = 0.2, Min = 0.05, Max = 1, Rounding = 2, Callback = function(v) AimSmooth = v end})
CombatBox:AddToggle("ShowFOV", {Text = "Show FOV", Default = false, Callback = function(v) ShowFOV = v end})
CombatBox:AddToggle("WallCheck", {Text = "Wall Check", Default = true, Callback = function(v) WallCheck = v end})
CombatBox:AddToggle("TeamCheck", {Text = "Team Check", Default = true, Callback = function(v) TeamCheck = v end})

local RecoilBox = Tabs.Combat:AddLeftGroupbox("Recoil")
RecoilBox:AddToggle("NoRecoil", {Text = "No Recoil", Default = false, Callback = function(v)
    NoRecoilEnabled = v
    if v then scanRecoilTables() end
end})
RecoilBox:AddSlider("RecoilControl", {Text = "Recoil Amount (0=none)", Default = 0, Min = 0, Max = 1, Rounding = 2, Callback = function(v) RecoilStrength = v end})

local TriggerBox = Tabs.Combat:AddRightGroupbox("Triggerbot")
TriggerBox:AddToggle("Triggerbot", {Text = "Triggerbot", Default = false, Callback = function(v) TriggerbotEnabled = v end})
TriggerBox:AddSlider("TriggerFOV", {Text = "Trigger FOV", Default = 40, Min = 10, Max = 120, Rounding = 0, Callback = function(v) TriggerbotFOV = v end})
TriggerBox:AddSlider("TriggerDelay", {Text = "Shoot Delay", Default = 0.08, Min = 0.03, Max = 0.3, Rounding = 2, Callback = function(v) TriggerbotDelay = v end})

local PlayerBox = Tabs.Player:AddLeftGroupbox("Movement")
PlayerBox:AddToggle("Speed", {Text = "Speed", Default = false, Callback = function(v)
    SpeedEnabled = v
    if not v then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end})
PlayerBox:AddSlider("SpeedValue", {Text = "Speed Value", Default = 24, Min = 16, Max = 80, Rounding = 0, Callback = function(v) SpeedValue = v end})
PlayerBox:AddToggle("Noclip", {Text = "Noclip", Default = false, Callback = function(v)
    NoclipEnabled = v
    setNoclip(v)
end})

local MobileBox = Tabs.Mobile:AddLeftGroupbox("Mobile")
MobileBox:AddToggle("MobileAimbot", {Text = "Aimbot Always On", Default = false, Callback = function(v)
    AimbotEnabled = v
    if v then AimbotMode = "Always"; AimbotActive = true else AimbotActive = false end
end})
MobileBox:AddToggle("MobileNoRecoil", {Text = "No Recoil", Default = false, Callback = function(v)
    NoRecoilEnabled = v
    if v then scanRecoilTables() end
end})
MobileBox:AddToggle("MobileSpeed", {Text = "Speed", Default = false, Callback = function(v) SpeedEnabled = v end})
MobileBox:AddToggle("MobileNoclip", {Text = "Noclip", Default = false, Callback = function(v)
    NoclipEnabled = v
    setNoclip(v)
end})

local VisualBox = Tabs.Visuals:AddLeftGroupbox("ESP")
VisualBox:AddToggle("ESP", {Text = "ESP Enabled", Default = false, Callback = function(v)
    ESPEnabled = v
    if not v then for p in pairs(ESP) do removeESP(p) end end
end})
VisualBox:AddToggle("Boxes", {Text = "Boxes", Default = true, Callback = function(v) ShowBoxes = v end})
VisualBox:AddToggle("Corners", {Text = "Corner Boxes", Default = true, Callback = function(v) ShowCorners = v end})
VisualBox:AddToggle("Skeleton", {Text = "Skeleton", Default = false, Callback = function(v) ShowSkeleton = v end})
VisualBox:AddToggle("Tracers", {Text = "Tracers", Default = false, Callback = function(v) ShowTracers = v end})
VisualBox:AddDropdown("TracerOrigin", {Text = "Tracer Origin", Values = {"Bottom","Center","Mouse"}, Default = 1, Callback = function(v) TracerOrigin = v end})
VisualBox:AddToggle("Health", {Text = "Health Bar", Default = false, Callback = function(v) ShowHealth = v end})
VisualBox:AddLabel("ESPColor"):AddColorPicker("ESPColor", {Default = ESPColor, Title = "ESP Color", Callback = function(c) ESPColor = c end})

local MiscBox = Tabs.Misc:AddLeftGroupbox("Performance")
MiscBox:AddToggle("ShowPerf", {Text = "Show FPS + MS", Default = true, Callback = function(v) ShowPerf = v end})
MiscBox:AddToggle("Potato", {Text = "SmoothPlastic FPS Boost", Default = false, Callback = function(v)
    if v then enablePotato() else disablePotato() end
end})

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("MoonHub/Jailbird")
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:Notify("Jailbird |  ", 3)
print("Moon Hub | Jailbird Loaded")
