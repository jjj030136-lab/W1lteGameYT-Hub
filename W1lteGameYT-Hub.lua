print("[W1lteGameYT Hub] Loading... v19.2")

local success, err = pcall(function()

local HasDrawing = pcall(function() local d = Drawing.new("Circle") d:Remove() end)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/Vape.txt"))()
local win = lib:Window("W1lteGameYT Hub", Color3.fromRGB(44, 120, 224), Enum.KeyCode.F10)

-- ============================================================
--  AIMBOT
-- ============================================================
local Aimbot = {}

Aimbot.Settings = {
    Enabled = true,
    TeamCheck = false,
    SkipFriends = false,
    AimPoint = "Neck",
    AimHeight = -0.8,
    AimSpeed = 10,
    FOV = 120
}

Aimbot.State = {
    Running = false,
    Locked = nil,
    LastTime = 0,
    UI = { IsVisible = true }
}

Aimbot.FOVCircle = HasDrawing and Drawing.new("Circle") or nil
if Aimbot.FOVCircle then
    Aimbot.FOVCircle.Visible = false
    Aimbot.FOVCircle.Thickness = 1
    Aimbot.FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    Aimbot.FOVCircle.Filled = false
    Aimbot.FOVCircle.NumSides = 64
end

function Aimbot:CountTeams()
    local teams, colors = {}, {}
    local teamCount, colorCount = 0, 0
    local cameraPos = Camera and Camera.CFrame and Camera.CFrame.Position or Vector3.new()
    for _, p in ipairs(Players:GetPlayers()) do
        local ch = p.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dist = (hrp.Position - cameraPos).Magnitude
            if dist <= 600 then
                local t = p.Team
                if t and not teams[t] then
                    teams[t] = true
                    teamCount = teamCount + 1
                end
                local c = p.TeamColor
                if c and c ~= BrickColor.new("Medium stone grey") and not colors[c] then
                    colors[c] = true
                    colorCount = colorCount + 1
                end
            end
        end
    end
    return teamCount, colorCount
end

function Aimbot:IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    if not self.Settings.TeamCheck then
        if self.Settings.SkipFriends then
            local ok = pcall(function()
                return player:IsFriendsWith(LocalPlayer.UserId)
            end)
            if ok then
                return not player:IsFriendsWith(LocalPlayer.UserId)
            end
        end
        return true
    end

    if self.TeamCount >= 2 then
        return player.Team ~= LocalPlayer.Team
    end

    if self.ColorCount >= 2 then
        local myColor = LocalPlayer.TeamColor
        if myColor and myColor ~= BrickColor.new("Medium stone grey") then
            return player.TeamColor ~= myColor
        end
    end

    return true
end

function Aimbot:GetAimPosition(character)
    local partName = (self.Settings.AimPoint == "Chest") and "UpperTorso" or "Head"
    local part = character:FindFirstChild(partName) or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    if not part then return nil end
    local height = self.Settings.AimHeight
    if self.Settings.AimPoint == "Head" then height = 0 end
    if self.Settings.AimPoint == "Chest" then height = 0.4 end
    return part.Position + Vector3.new(0, height, 0)
end

function Aimbot:CancelLock()
    self.State.Locked = nil
    if self.FOVCircle then
        self.FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    end
end

function Aimbot:GetClosestPlayer()
    if not self.State.Locked then
        local requiredDistance = self.Settings.FOV
        local mousePos = UserInputService:GetMouseLocation()

        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if self:IsEnemy(player) and character and humanoid and humanoid.Health > 0 then
                local aimPosition = self:GetAimPosition(character)
                if aimPosition then
                    local vector, onScreen = Camera:WorldToViewportPoint(aimPosition)
                    if onScreen then
                        local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(vector.X, vector.Y)).Magnitude
                        if distance < requiredDistance then
                            requiredDistance = distance
                            self.State.Locked = player
                        end
                    end
                end
            end
        end
    else
        local character = self.State.Locked.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local mousePos = UserInputService:GetMouseLocation()

        if not character or not humanoid or humanoid.Health <= 0 or not self:IsEnemy(self.State.Locked) then
            self:CancelLock()
            return
        end

        local aimPosition = self:GetAimPosition(character)
        if not aimPosition then
            self:CancelLock()
            return
        end

        local vector, onScreen = Camera:WorldToViewportPoint(aimPosition)
        local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(vector.X, vector.Y)).Magnitude
        if not onScreen or distance > self.Settings.FOV * 1.5 then
            self:CancelLock()
        end
    end
end

function Aimbot:GetSmoothFactor(dt)
    local rate = math.max(self.Settings.AimSpeed, 1)
    return 1 - math.exp(-rate * dt)
end

function Aimbot:ToggleUI()
    self.State.UI.IsVisible = not self.State.UI.IsVisible
    local ui = game.CoreGui:FindFirstChild("ui")
    if ui then
        ui.Enabled = self.State.UI.IsVisible
    end
end

-- ============================================================
--  TRIGGERBOT
-- ============================================================
local Triggerbot = {}

Triggerbot.Settings = {
    Enabled     = false,
    TeamCheck   = true,
    SkipFriends = true,
    Mode        = "Hold",       -- "Hold" (while key down) or "Always"
    Key         = Enum.KeyCode.F,
    FOV         = 7,            -- pixels from crosshair
    FireDelay   = 0.15,         -- seconds between shots (floor, not per-frame)
    WallCheck   = true,
    HitPoint    = "Head",       -- "Head" / "Chest" / "Body"
    FireMethod  = "Mouse",      -- "Mouse" / "Tool"
    ShotMode    = "Tap",        -- "Tap" (1 per target) / "Burst" / "Auto"
    BurstShots  = 3,            -- only used by "Burst"
}

Triggerbot.State = {
    Running    = false,         -- key held
    LastFire   = 0,
    Target     = nil,
    LastTarget = nil,           -- target identity for shot-count reset
    Shots      = 0,             -- shots fired at current target
    Visible    = false,
    Status     = "idle",
}

function Triggerbot:IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    if not self.Settings.TeamCheck then
        if self.Settings.SkipFriends then
            local ok, res = pcall(function() return player:IsFriendsWith(LocalPlayer.UserId) end)
            if ok then return not res end
        end
        return true
    end
    if Aimbot.TeamCount and Aimbot.TeamCount >= 2 then
        return player.Team ~= LocalPlayer.Team
    end
    if Aimbot.ColorCount and Aimbot.ColorCount >= 2 then
        local myColor = LocalPlayer.TeamColor
        if myColor and myColor ~= BrickColor.new("Medium stone grey") then
            return player.TeamColor ~= myColor
        end
    end
    return true
end

function Triggerbot:GetHitPart(character)
    local order
    if self.Settings.HitPoint == "Head" then
        order = { "Head" }
    elseif self.Settings.HitPoint == "Chest" then
        order = { "UpperTorso", "Torso", "HumanoidRootPart" }
    else
        order = { "HumanoidRootPart", "UpperTorso", "Torso" }
    end
    for _, name in ipairs(order) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part end
    end
    return character:FindFirstChild("Head")
end

function Triggerbot:IsVisible(targetPart, character)
    if not self.Settings.WallCheck then return true end
    local camPos = Camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local localChar = LocalPlayer.Character
    params.FilterDescendantsInstances = localChar and { localChar } or {}
    local result = workspace:Raycast(camPos, targetPart.Position - camPos, params)
    if not result then return true end
    return result.Instance:IsDescendantOf(character)
end

function Triggerbot:FindTarget()
    local crosshair = UserInputService:GetMouseLocation()
    local best, bestDist = nil, self.Settings.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if character and humanoid and humanoid.Health > 0 and self:IsEnemy(player) then
                local part = self:GetHitPart(character)
                if part then
                    local v, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and v.Z > 0 then
                        local d = (Vector2.new(v.X, v.Y) - Vector2.new(crosshair.X, crosshair.Y)).Magnitude
                        if d < bestDist and self:IsVisible(part, character) then
                            bestDist = d
                            best = { player = player, character = character, part = part }
                        end
                    end
                end
            end
        end
    end
    return best
end

function Triggerbot:ShouldFireNow()
    if not self.Settings.Enabled then return false end
    -- never fire while the player is typing in chat or a textbox
    if UserInputService:GetFocusedTextBox() then return false end
    if self.Settings.Mode == "Hold" then return self.State.Running end
    return true
end

function Triggerbot:Fire()
    local now = tick()
    local delay = math.max(self.Settings.FireDelay, 0.02)
    if now - self.State.LastFire < delay then return false end

    if self.Settings.FireMethod == "Tool" then
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool then return false end
        self.State.LastFire = now
        pcall(function() tool:Activate() end)
        return true
    end

    if type(mouse1click) ~= "function" then
        return false
    end
    self.State.LastFire = now
    pcall(mouse1click)
    return true
end

function Triggerbot:ResetShotState()
    self.State.LastTarget = nil
    self.State.Shots = 0
end

function Triggerbot:CanShootAt(target)
    if not target then return false end
    local identity = target.player
    if identity ~= self.State.LastTarget then
        self.State.LastTarget = identity
        self.State.Shots = 0
    end

    local mode = self.Settings.ShotMode
    if mode == "Tap" then
        return self.State.Shots < 1
    elseif mode == "Burst" then
        return self.State.Shots < math.max(self.Settings.BurstShots, 1)
    end
    return true
end

function Triggerbot:Step()
    if self:ShouldFireNow() then
        local target = self:FindTarget()
        self.State.Target = target and target.player or nil
        self.State.Visible = target ~= nil

        if target then
            if self:CanShootAt(target) and self:Fire() then
                self.State.Shots = self.State.Shots + 1
                self.State.Status = "firing"
            else
                self.State.Status = "locked"
            end
        else
            self:ResetShotState()
            self.State.Status = "scanning"
        end
    else
        self.State.Target = nil
        self.State.Visible = false
        self:ResetShotState()
        self.State.Status = self.Settings.Enabled and "idle" or "off"
    end
end

-- ============================================================
--  UI
-- ============================================================
local mainTab = win:Tab("Main")
mainTab:Label("> Aimbot v18.0")
mainTab:Toggle("Enable Aimbot", Aimbot.Settings.Enabled, function(val) Aimbot.Settings.Enabled = val end)
local debugLabel = mainTab:Label("Teams: ... | Colors: ...")
mainTab:Toggle("Team Check (skip teammates)", Aimbot.Settings.TeamCheck, function(val) Aimbot.Settings.TeamCheck = val end)
mainTab:Toggle("Skip Friends (party teammates)", Aimbot.Settings.SkipFriends, function(val) Aimbot.Settings.SkipFriends = val end)
mainTab:Dropdown("Aim Point", {"Neck", "Head", "Chest"}, function(val) Aimbot.Settings.AimPoint = val end)
mainTab:Slider("Aim Height (-2 = lower, +2 = higher)", -2, 2, Aimbot.Settings.AimHeight, function(val) Aimbot.Settings.AimHeight = val end)
mainTab:Slider("Aim Speed (1 = slow, 50 = fast)", 1, 50, Aimbot.Settings.AimSpeed, function(val) Aimbot.Settings.AimSpeed = val end)
mainTab:Slider("FOV Size", 10, 500, Aimbot.Settings.FOV, function(val) Aimbot.Settings.FOV = val end)
mainTab:Button("Debug: dump players to console", function()
    print("[W1lteGameYT] ---- PLAYERS DUMP ----")
    for _, p in ipairs(Players:GetPlayers()) do
        local t = p.Team and p.Team.Name or "none"
        print(p.Name .. " | Team: " .. t .. " | Color: " .. p.TeamColor.Name)
    end
    print("[W1lteGameYT] ---- END DUMP ----")
end)
mainTab:Label("Hold Right-Click to lock on. Right Shift = UI.")

-- ============================================================
--  TRIGGERBOT TAB
-- ============================================================
local trigTab = win:Tab("Triggerbot")
trigTab:Label("> Triggerbot v1.1")

local trigStatus = trigTab:Label("Status: off | target: none")

trigTab:Toggle("Enable Triggerbot", Triggerbot.Settings.Enabled, function(val)
    Triggerbot.Settings.Enabled = val
    Triggerbot:ResetShotState()
    if not val then
        Triggerbot.State.Target = nil
        Triggerbot.State.Visible = false
    end
end)

trigTab:Toggle("Team Check (skip teammates)", Triggerbot.Settings.TeamCheck, function(val)
    Triggerbot.Settings.TeamCheck = val
end)

trigTab:Toggle("Skip Friends (party teammates)", Triggerbot.Settings.SkipFriends, function(val)
    Triggerbot.Settings.SkipFriends = val
end)

trigTab:Dropdown("Mode", { "Hold", "Always" }, function(val)
    Triggerbot.Settings.Mode = val
end)

trigTab:Dropdown("Hit Point", { "Head", "Chest", "Body" }, function(val)
    Triggerbot.Settings.HitPoint = val
end)

trigTab:Dropdown("Fire Method", { "Mouse", "Tool" }, function(val)
    Triggerbot.Settings.FireMethod = val
end)

trigTab:Dropdown("Shot Mode", { "Tap", "Burst", "Auto" }, function(val)
    Triggerbot.Settings.ShotMode = val
    Triggerbot:ResetShotState()
end)

trigTab:Slider("Burst Shots", 1, 10, Triggerbot.Settings.BurstShots, function(val)
    Triggerbot.Settings.BurstShots = val
end)

trigTab:Toggle("Wall Check (line of sight)", Triggerbot.Settings.WallCheck, function(val)
    Triggerbot.Settings.WallCheck = val
end)

trigTab:Slider("Trigger FOV (pixels)", 1, 100, Triggerbot.Settings.FOV, function(val)
    Triggerbot.Settings.FOV = val
end)

trigTab:Slider("Fire Delay (ms)", 0, 500, math.floor(Triggerbot.Settings.FireDelay * 1000), function(val)
    Triggerbot.Settings.FireDelay = val / 1000
end)

trigTab:Button("Set Keybind: F", function()
    Triggerbot.Settings.Key = Enum.KeyCode.F
end)

trigTab:Button("Reset Shot State", function()
    Triggerbot:ResetShotState()
    Triggerbot.State.Target = nil
    Triggerbot.State.Status = "idle"
end)

trigTab:Label("Mode Hold = trigger only while F is held.")
trigTab:Label("Mode Always = trigger on any enemy under crosshair.")
trigTab:Label("Tap = one shot per target, stops the flood.")
trigTab:Label("Burst = N shots per target. Auto = hold fire.")
trigTab:Label("Mouse = mouse1click, Tool = tool:Activate().")


-- ============================================================
--  input & loop
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Aimbot:ToggleUI()
    end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aimbot.State.Running = true
    end
    if input.KeyCode == Triggerbot.Settings.Key then
        Triggerbot.State.Running = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aimbot.State.Running = false
        Aimbot:CancelLock()
    end
    if input.KeyCode == Triggerbot.Settings.Key then
        Triggerbot.State.Running = false
    end
end)


local errorsReported = 0

RunService.RenderStepped:Connect(function()
    pcall(function()
        Aimbot.TeamCount, Aimbot.ColorCount = Aimbot:CountTeams()
        pcall(function()
            if debugLabel and debugLabel.ButtonTitle then
                debugLabel.ButtonTitle.Text = "Teams: " .. tostring(Aimbot.TeamCount) .. " | Colors: " .. tostring(Aimbot.ColorCount) ..
                    " | MyTeam: " .. tostring(LocalPlayer.Team and LocalPlayer.Team.Name or "none") ..
                    " | MyColor: " .. tostring(LocalPlayer.TeamColor and LocalPlayer.TeamColor.Name or "none")
            end
        end)
    end)

    local ok, err2 = pcall(function()

        if Aimbot.FOVCircle then
            Aimbot.FOVCircle.Visible = Aimbot.Settings.Enabled and Aimbot.State.Running
            if Aimbot.FOVCircle.Visible then
                Aimbot.FOVCircle.Radius = Aimbot.Settings.FOV
                Aimbot.FOVCircle.Position = UserInputService:GetMouseLocation()
            end
        end

        if Aimbot.State.Running and Aimbot.Settings.Enabled then
            Aimbot:GetClosestPlayer()

            if Aimbot.State.Locked then
                local character = Aimbot.State.Locked.Character
                local aimPosition = Aimbot:GetAimPosition(character)
                if aimPosition and mousemoverel then
                    local now = tick()
                    local dt = math.min(now - Aimbot.State.LastTime, 0.1)
                    Aimbot.State.LastTime = now

                    local vector = Camera:WorldToViewportPoint(aimPosition)
                    local mousePos = UserInputService:GetMouseLocation()
                    local dx = vector.X - mousePos.X
                    local dy = vector.Y - mousePos.Y
                    local magnitude = math.sqrt(dx * dx + dy * dy)

                    if magnitude > 0.7 then
                        local factor = Aimbot:GetSmoothFactor(dt)
                        local mx = math.clamp(dx * factor, -25, 25)
                        local my = math.clamp(dy * factor, -25, 25)
                        local m2 = math.sqrt(mx * mx + my * my)

                        if m2 < 2 then
                            local scale = 2 / math.max(m2, 0.01)
                            mx = mx * scale
                            my = my * scale
                        end

                        mousemoverel(mx, my)
                    end

                    if Aimbot.FOVCircle then
                        Aimbot.FOVCircle.Color = Color3.fromRGB(255, 70, 70)
                    end
                end
            end
        elseif not Aimbot.State.Running then
            Aimbot:CancelLock()
        end

        Triggerbot:Step()

        if trigStatus and trigStatus.ButtonTitle then
            local now = tick()
            if now - (Triggerbot.State.LastHud or 0) > 0.1 then
                Triggerbot.State.LastHud = now
                local targetName = Triggerbot.State.Target and Triggerbot.State.Target.Name or "none"
                trigStatus.ButtonTitle.Text = string.format("Status: %s | target: %s | %s/%s | shots: %d",
                    tostring(Triggerbot.State.Status), targetName,
                    Triggerbot.Settings.Mode, Triggerbot.Settings.ShotMode,
                    Triggerbot.State.Shots)
            end
        end
    end)
    if not ok and errorsReported < 5 then
        errorsReported = errorsReported + 1
        warn("[W1lteGameYT Hub] Loop error: " .. tostring(err2))
    end
end)

print("[W1lteGameYT Hub] Loaded v19.2! Right Shift = UI. RMB = aim. Triggerbot tab = auto-fire.")

end)

if not success then
    warn("[W1lteGameYT Hub] Error: " .. tostring(err))
    warn("[W1lteGameYT Hub] Tip: enable HTTP requests (request) in your executor settings.")
end
