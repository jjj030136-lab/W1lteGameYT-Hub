print("[W1lteGameYT Hub] Loading... v19.4")

local success, err = pcall(function()

local HasDrawing = pcall(function() local d = Drawing.new("Circle") d:Remove() end)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
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
    FOV         = 25,           -- pixels from crosshair
    FireDelay   = 0.12,         -- seconds between shots (floor, not per-frame)
    WallCheck   = true,
    HitPoint    = "Head",       -- "Head" / "Chest" / "Body"
    FireMethod  = "Mouse",      -- "Mouse" (chain) / "Tool" / "Auto"
    ShotMode    = "Auto",       -- "Tap" (1 per target) / "Burst" / "Auto"
    BurstShots  = 3,            -- only used by "Burst"
}

Triggerbot.State = {
    Running       = false,      -- key held
    LastFire      = 0,
    Target        = nil,
    LastTarget    = nil,        -- target identity for shot-count reset
    Shots         = 0,          -- shots fired at current target
    Visible       = false,
    Status        = "idle",
    Nearest       = math.huge,  -- px to nearest enemy, for the HUD
    NearestName   = "none",
    LastFireWith  = "none",     -- which fire path actually worked
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
    local cam = self:GetCamera()
    if not cam then return false end
    local camPos = cam.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local localChar = LocalPlayer.Character
    params.FilterDescendantsInstances = localChar and { localChar } or {}
    local result = workspace:Raycast(camPos, targetPart.Position - camPos, params)
    if not result then return true end
    return result.Instance:IsDescendantOf(character)
end

-- Crosshair position in viewport space (the same space WorldToViewportPoint uses).
-- First person: dead centre. Free mouse: mouse position minus the topbar inset.
function Triggerbot:GetCrosshair()
    local behavior = UserInputService.MouseBehavior
    if behavior == Enum.MouseBehavior.LockCenter or behavior == Enum.MouseBehavior.LockCurrentPosition then
        local vp = Camera.ViewportSize
        return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    end
    local m = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    return Vector2.new(m.X, m.Y - inset.Y)
end

function Triggerbot:GetCamera()
    if workspace.CurrentCamera then
        Camera = workspace.CurrentCamera
    end
    return Camera
end

function Triggerbot:FindTarget()
    local cam = self:GetCamera()
    if not cam then return nil end
    local crosshair = self:GetCrosshair()
    local best, bestDist = nil, self.Settings.FOV
    self.State.Nearest = math.huge
    self.State.NearestName = "none"

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if character and humanoid and humanoid.Health > 0 and self:IsEnemy(player) then
                local part = self:GetHitPart(character)
                if part then
                    local v, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen and v.Z > 0 then
                        local d = (Vector2.new(v.X, v.Y) - crosshair).Magnitude
                        if d < self.State.Nearest then
                            self.State.Nearest = d
                            self.State.NearestName = player.Name
                        end
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

local function mousePath()
    if type(mouse1click) == "function" then
        local ok = pcall(mouse1click)
        if ok then return "mouse1click" end
    end
    if type(mouse1press) == "function" and type(mouse1release) == "function" then
        local ok = pcall(mouse1press)
        if ok then
            task.delay(0.02, function() pcall(mouse1release) end)
            return "mouse1press"
        end
    end
    local vimOk = pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local inset = GuiService:GetGuiInset()
        local px, py = vp.X * 0.5, vp.Y * 0.5 + inset.Y
        vim:SendMouseButtonEvent(px, py, 0, true, game, 0)
        task.delay(0.02, function()
            pcall(function() vim:SendMouseButtonEvent(px, py, 0, false, game, 0) end)
        end)
    end)
    if vimOk then return "VirtualInputManager" end
    return nil
end

function Triggerbot:Fire()
    local now = tick()
    local delay = math.max(self.Settings.FireDelay, 0.02)
    if now - self.State.LastFire < delay then return false end

    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    local method = self.Settings.FireMethod
    local used = nil

    if method == "Tool" or method == "Auto" then
        if tool then
            local ok = pcall(function() tool:Activate() end)
            if ok then used = "Tool:Activate" end
        end
        if method == "Tool" and not used then return false end
    end

    if not used then
        used = mousePath()
    end

    if not used then return false end

    self.State.LastFire = now
    self.State.LastFireWith = used
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
--  ESP
-- ============================================================
local Esp = {}

Esp.Settings = {
    Enabled     = false,
    Box         = true,
    BoxFill     = true,
    Name        = true,
    Distance    = true,
    Health      = true,
    HealthText  = true,
    Tracer      = false,
    TeamCheck   = true,
    MaxDistance = 1500,
    TextSize    = 14,
    Thickness   = 1,
    VisibleTint = true,   -- occluded targets draw dimmed
}

Esp.State = { cache = {} }

Esp.EnemyColor   = Color3.fromRGB(255, 60, 60)
Esp.TeamColor    = Color3.fromRGB(80, 220, 120)
Esp.VisibleColor = Color3.fromRGB(255, 255, 255)

local function newDrawing(kind)
    if not Drawing then return nil end
    local ok, obj = pcall(function() return Drawing.new(kind) end)
    if ok then return obj end
    return nil
end

function Esp:GetCamera()
    if workspace.CurrentCamera then
        Camera = workspace.CurrentCamera
    end
    return Camera
end

function Esp:IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    if not self.Settings.TeamCheck then return true end
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

function Esp:ColorFor(player, visible)
    local base
    if self.Settings.TeamCheck and not self:IsEnemy(player) then
        base = self.TeamColor
    else
        base = self.EnemyColor
    end
    if self.Settings.VisibleTint and not visible then
        return Color3.new(base.R * 0.45, base.G * 0.45, base.B * 0.45)
    end
    return base
end

function Esp:Acquire(player)
    local entry = self.State.cache[player]
    if entry then return entry end
    entry = {
        box    = newDrawing("Square"),
        fill   = newDrawing("Square"),
        name   = newDrawing("Text"),
        dist   = newDrawing("Text"),
        hpBack = newDrawing("Square"),
        hpBar  = newDrawing("Square"),
        tracer = newDrawing("Line"),
    }
    if entry.box then
        entry.box.Thickness = self.Settings.Thickness
        entry.box.Filled = false
    end
    if entry.fill then
        entry.fill.Filled = true
        entry.fill.Transparency = 0.75
    end
    if entry.name then
        entry.name.Center = true
        entry.name.Outline = true
        entry.name.Size = self.Settings.TextSize
    end
    if entry.dist then
        entry.dist.Center = true
        entry.dist.Outline = true
        entry.dist.Size = self.Settings.TextSize
    end
    if entry.hpBack then
        entry.hpBack.Filled = true
        entry.hpBack.Color = Color3.fromRGB(20, 20, 20)
        entry.hpBack.Transparency = 0.35
    end
    if entry.hpBar then
        entry.hpBar.Filled = true
    end
    if entry.tracer then
        entry.tracer.Thickness = 1
    end
    self.State.cache[player] = entry
    return entry
end

function Esp:Release(player)
    local entry = self.State.cache[player]
    if not entry then return end
    for _, obj in pairs(entry) do
        if obj and obj.Remove then pcall(function() obj:Remove() end) end
    end
    self.State.cache[player] = nil
end

function Esp:ClearAll()
    for player in pairs(self.State.cache) do
        self:Release(player)
    end
end

function Esp:Visible(part, character)
    local cam = self:GetCamera()
    if not cam then return false end
    local camPos = cam.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local localChar = LocalPlayer.Character
    params.FilterDescendantsInstances = localChar and { localChar } or {}
    local result = workspace:Raycast(camPos, part.Position - camPos, params)
    if not result then return true end
    return result.Instance:IsDescendantOf(character)
end

local function hide(entry)
    for _, obj in pairs(entry) do
        if obj and obj.Visible ~= nil then obj.Visible = false end
    end
end

function Esp:Update()
    if not self.Settings.Enabled then
        if next(self.State.cache) then self:ClearAll() end
        return
    end
    local cam = self:GetCamera()
    if not cam then return end
    local vp = cam.ViewportSize
    local camPos = cam.CFrame.Position
    local offY = GuiService:GetGuiInset().Y   -- Drawing uses screen space, viewport point does not
    local seen = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local entry = self:Acquire(player)
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local head = character and character:FindFirstChild("Head")
            local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))

            local draw = humanoid and head and root and humanoid.Health > 0
                and (not self.Settings.TeamCheck or self:IsEnemy(player))
                and (head.Position - camPos).Magnitude <= self.Settings.MaxDistance

            if draw then
                local headPos, headOn = cam:WorldToViewportPoint(head.Position)
                local rootPos, rootOn = cam:WorldToViewportPoint(root.Position + Vector3.new(0, -1.2, 0))
                if headOn and rootOn then
                    local height = math.abs(rootPos.Y - headPos.Y)
                    if height < 6 then height = 6 end
                    local width = height * 0.52
                    local x = headPos.X - width * 0.5
                    local y = headPos.Y + offY
                    local color = self:ColorFor(player, self:Visible(head, character))
                    seen[player] = true

                    if entry.box then
                        entry.box.Visible = self.Settings.Box
                        entry.box.Position = Vector2.new(x, y)
                        entry.box.Size = Vector2.new(width, height)
                        entry.box.Color = color
                        entry.box.Thickness = self.Settings.Thickness
                    end

                    if entry.fill then
                        entry.fill.Visible = self.Settings.BoxFill and self.Settings.Box
                        entry.fill.Position = Vector2.new(x, y)
                        entry.fill.Size = Vector2.new(width, height)
                        entry.fill.Color = color
                    end

                    local labelY = y + height + 2
                    if entry.name then
                        entry.name.Visible = self.Settings.Name
                        entry.name.Text = player.Name
                        entry.name.Position = Vector2.new(headPos.X, labelY)
                        entry.name.Color = color
                        entry.name.Size = self.Settings.TextSize
                    end

                    if entry.dist then
                        entry.dist.Visible = self.Settings.Distance
                        entry.dist.Text = string.format("%dm", math.floor((head.Position - camPos).Magnitude))
                        entry.dist.Position = Vector2.new(headPos.X, labelY + self.Settings.TextSize + 1)
                        entry.dist.Color = color
                        entry.dist.Size = self.Settings.TextSize
                    end

                    local hp = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
                    if entry.hpBack then
                        entry.hpBack.Visible = self.Settings.Health
                        entry.hpBack.Position = Vector2.new(x - 5, y)
                        entry.hpBack.Size = Vector2.new(3, height)
                    end
                    if entry.hpBar then
                        entry.hpBar.Visible = self.Settings.Health
                        entry.hpBar.Position = Vector2.new(x - 5, y + height * (1 - hp))
                        entry.hpBar.Size = Vector2.new(3, height * hp)
                        entry.hpBar.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 60)
                    end

                    if entry.tracer then
                        entry.tracer.Visible = self.Settings.Tracer
                        entry.tracer.From = Vector2.new(vp.X * 0.5, vp.Y + offY)
                        entry.tracer.To = Vector2.new(headPos.X, y + height)
                        entry.tracer.Color = color
                    end

                    if not self.Settings.HealthText and entry.name then
                        entry.name.Text = player.Name
                    end
                    if self.Settings.HealthText and entry.name then
                        entry.name.Text = string.format("%s [%d]", player.Name, math.floor(humanoid.Health))
                    end
                else
                    hide(entry)
                end
            else
                hide(entry)
            end
        end
    end

    for player in pairs(self.State.cache) do
        if not seen[player] then
            local entry = self.State.cache[player]
            if entry then hide(entry) end
            if not player.Parent or not player.Character then
                self:Release(player)
            end
        end
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

trigTab:Dropdown("Fire Method", { "Mouse", "Tool", "Auto" }, function(val)
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

local trigDebug = trigTab:Label("nearest: - | crosshair: - | tool: -")

trigTab:Button("Test Fire (prints what works)", function()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    print("[Triggerbot] ---- FIRE TEST ----")
    print("  tool        : " .. (tool and tool.Name or "none"))
    print("  mouse1click : " .. tostring(type(mouse1click)))
    print("  mouse1press : " .. tostring(type(mouse1press)))
    print("  mouse behavior: " .. tostring(UserInputService.MouseBehavior))
    print("  viewport    : " .. tostring(Camera.ViewportSize))
    Triggerbot.State.LastFire = 0
    local method = Triggerbot.Settings.FireMethod
    Triggerbot.Settings.FireMethod = (method == "Tool") and "Tool" or "Mouse"
    local ok = Triggerbot:Fire()
    Triggerbot.Settings.FireMethod = method
    print("  fired       : " .. tostring(ok) .. " via " .. tostring(Triggerbot.State.LastFireWith))
    print("[Triggerbot] ---- END ----")
end)

trigTab:Button("Learn Remote (30s, shoot manually)", function()
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
        print("[Triggerbot] hookmetamethod unavailable in this executor")
        return
    end
    print("[Triggerbot] hooking FireServer for 30s - fire one shot manually now")
    local seen = {}
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
            if not seen[self] then
                seen[self] = true
                print("[Triggerbot] FireServer -> " .. self:GetFullName())
            end
        end
        return old(self, ...)
    end)
    task.delay(30, function()
        pcall(function()
            if type(restorefunction) == "function" then
                restorefunction(old)
            end
        end)
        print("[Triggerbot] hook released")
    end)
end)

trigTab:Button("Dump Distances (nearest enemy px)", function()
    local cam = Triggerbot:GetCamera()
    local ch = Triggerbot:GetCrosshair()
    print("[Triggerbot] crosshair=" .. tostring(ch) .. " behavior=" .. tostring(UserInputService.MouseBehavior))
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local part = Triggerbot:GetHitPart(p.Character)
            if part and cam then
                local v, on = cam:WorldToViewportPoint(part.Position)
                local d = (Vector2.new(v.X, v.Y) - ch).Magnitude
                print(string.format("  %s | onScreen=%s | px=%.1f | visible=%s",
                    p.Name, tostring(on), d, tostring(Triggerbot:IsVisible(part, p.Character))))
            end
        end
    end
end)

trigTab:Label("Mode Hold = trigger only while F is held.")
trigTab:Label("Mode Always = trigger on any enemy under crosshair.")
trigTab:Label("Tap = one shot per target, stops the flood.")
trigTab:Label("Burst = N shots per target. Auto = hold fire.")
trigTab:Label("Mouse = mouse1click, Tool = tool:Activate().")

-- ============================================================
--  ESP TAB
-- ============================================================
local espTab = win:Tab("ESP")
espTab:Label("> ESP v1.0")

local espStatus = espTab:Label("status: off")

espTab:Toggle("Enable ESP", Esp.Settings.Enabled, function(val)
    Esp.Settings.Enabled = val
    if not val then Esp:ClearAll() end
end)

espTab:Toggle("Box", Esp.Settings.Box, function(val) Esp.Settings.Box = val end)
espTab:Toggle("Box Fill", Esp.Settings.BoxFill, function(val) Esp.Settings.BoxFill = val end)
espTab:Toggle("Name", Esp.Settings.Name, function(val) Esp.Settings.Name = val end)
espTab:Toggle("Distance", Esp.Settings.Distance, function(val) Esp.Settings.Distance = val end)
espTab:Toggle("Health Bar", Esp.Settings.Health, function(val) Esp.Settings.Health = val end)
espTab:Toggle("Health Text", Esp.Settings.HealthText, function(val) Esp.Settings.HealthText = val end)
espTab:Toggle("Tracer", Esp.Settings.Tracer, function(val) Esp.Settings.Tracer = val end)
espTab:Toggle("Team Check (hide teammates)", Esp.Settings.TeamCheck, function(val) Esp.Settings.TeamCheck = val end)
espTab:Toggle("Dim Behind Walls", Esp.Settings.VisibleTint, function(val) Esp.Settings.VisibleTint = val end)

espTab:Slider("Max Distance (studs)", 50, 5000, Esp.Settings.MaxDistance, function(val)
    Esp.Settings.MaxDistance = val
end)

espTab:Slider("Text Size", 8, 24, Esp.Settings.TextSize, function(val)
    Esp.Settings.TextSize = val
end)

espTab:Slider("Box Thickness", 1, 4, Esp.Settings.Thickness, function(val)
    Esp.Settings.Thickness = val
end)

espTab:Button("Clear All Drawings", function()
    Esp:ClearAll()
end)

espTab:Label("Drawing API: " .. tostring(HasDrawing and "available" or "missing - boxes only"))

-- ============================================================
--  input & loop
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    -- trigger key is read before the gameProcessed guard: Rivals binds plenty of keys
    if input.KeyCode == Triggerbot.Settings.Key then
        Triggerbot.State.Running = true
    end
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Aimbot:ToggleUI()
    end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aimbot.State.Running = true
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
        Esp:Update()

        if espStatus and espStatus.ButtonTitle then
            local count = 0
            for _ in pairs(Esp.State.cache) do count = count + 1 end
            if Esp.Settings.Enabled then
                espStatus.ButtonTitle.Text = string.format("status: on | tracked: %d", count)
            else
                espStatus.ButtonTitle.Text = "status: off"
            end
        end

        if trigStatus and trigStatus.ButtonTitle then
            local now = tick()
            if now - (Triggerbot.State.LastHud or 0) > 0.1 then
                Triggerbot.State.LastHud = now
                local targetName = Triggerbot.State.Target and Triggerbot.State.Target.Name or "none"
                local nearest = Triggerbot.State.Nearest
                local nearestText = (nearest == math.huge) and "-" or string.format("%.0fpx", nearest)
                trigStatus.ButtonTitle.Text = string.format("Status: %s | target: %s | nearest: %s | %s/%s | shots: %d",
                    tostring(Triggerbot.State.Status), targetName, nearestText,
                    Triggerbot.Settings.Mode, Triggerbot.Settings.ShotMode,
                    Triggerbot.State.Shots)

                if trigDebug and trigDebug.ButtonTitle then
                    local char = LocalPlayer.Character
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    trigDebug.ButtonTitle.Text = string.format("nearest: %s | crosshair: %s | tool: %s | method: %s",
                        nearestText, tostring(UserInputService.MouseBehavior),
                        tool and tool.Name or "none", Triggerbot.State.LastFireWith)
                end
            end
        end
    end)
    if not ok and errorsReported < 5 then
        errorsReported = errorsReported + 1
        warn("[W1lteGameYT Hub] Loop error: " .. tostring(err2))
    end
end)

print("[W1lteGameYT Hub] Loaded v19.4! Right Shift = UI. RMB = aim. Triggerbot tab = auto-fire. ESP tab = boxes.")

end)

if not success then
    warn("[W1lteGameYT Hub] Error: " .. tostring(err))
    warn("[W1lteGameYT Hub] Tip: enable HTTP requests (request) in your executor settings.")
end
