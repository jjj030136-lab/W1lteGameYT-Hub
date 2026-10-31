print("[W1lteGameYT Hub] Loading... v19.6")

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
--  ESP  (GUI backend - works without the Drawing API)
-- ============================================================
local Esp = {}

Esp.Settings = {
    Enabled     = true,
    Box         = true,
    BoxFill     = true,
    Name        = true,
    Distance    = true,
    Health      = true,
    HealthText  = true,
    Tracer      = false,
    TeamCheck   = false,     -- off by default: draw everyone, no team guessing
    MaxDistance = 1500,
    TextSize    = 14,
    Thickness   = 1,
    VisibleTint = true,
}

Esp.State = { entries = {} }

Esp.EnemyColor   = Color3.fromRGB(255, 60, 60)
Esp.TeamColor    = Color3.fromRGB(80, 220, 120)
Esp.OccludedMul  = 0.45

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function ensureGui()
    local gui = Esp.Gui
    if gui and gui.Parent then
        return gui
    end
    gui = Instance.new("ScreenGui")
    gui.Name = "W1lteESP"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui

    -- on-screen heartbeat: if this text shows, the GUI itself is alive
    local info = Instance.new("TextLabel")
    info.Name = "info"
    info.BackgroundTransparency = 1
    info.Position = UDim2.fromOffset(10, 10)
    info.Size = UDim2.fromOffset(520, 22)
    info.Font = Enum.Font.Code
    info.TextSize = 14
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextColor3 = Color3.fromRGB(80, 255, 120)
    info.TextStrokeTransparency = 0.4
    info.Text = "ESP loading..."
    info.Parent = gui

    Esp.Gui = gui
    Esp.Info = info
    return gui
end

local function newFrame(parent, name)
    local f = Instance.new("Frame")
    f.Name = name
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Parent = parent
    return f
end

local function newLabel(parent, name, size, bold)
    local t = Instance.new("TextLabel")
    t.Name = name
    t.BackgroundTransparency = 1
    t.BorderSizePixel = 0
    t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    t.TextSize = size
    t.TextColor3 = Color3.new(1, 1, 1)
    t.TextStrokeTransparency = 0.35
    t.TextXAlignment = Enum.TextXAlignment.Center
    t.TextYAlignment = Enum.TextYAlignment.Top
    t.Parent = parent
    return t
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
        return Color3.new(base.R * self.OccludedMul, base.G * self.OccludedMul, base.B * self.OccludedMul)
    end
    return base
end

function Esp:Acquire(player)
    local entry = self.State.entries[player]
    if entry then return entry end

    local gui = ensureGui()
    local root = newFrame(gui, "p_" .. tostring(player.UserId))

    local box = newFrame(root, "box")
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = self.Settings.Thickness
    stroke.Color = self.EnemyColor
    stroke.Parent = box

    local fill = newFrame(root, "fill")
    fill.BackgroundColor3 = self.EnemyColor
    fill.BackgroundTransparency = 0.82

    local hpBack = newFrame(root, "hpBack")
    hpBack.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    hpBack.BackgroundTransparency = 0.45

    local hpBar = newFrame(root, "hpBar")
    hpBar.BackgroundColor3 = Color3.fromRGB(90, 255, 90)

    local tracer = newFrame(root, "tracer")
    tracer.BackgroundColor3 = self.EnemyColor
    tracer.AnchorPoint = Vector2.new(0, 0.5)

    local name = newLabel(root, "name", self.Settings.TextSize, true)
    local dist = newLabel(root, "dist", math.max(self.Settings.TextSize - 2, 8), false)

    entry = {
        root = root,
        box = box,
        stroke = stroke,
        fill = fill,
        hpBack = hpBack,
        hpBar = hpBar,
        tracer = tracer,
        name = name,
        dist = dist,
    }
    self.State.entries[player] = entry
    return entry
end

function Esp:Release(player)
    local entry = self.State.entries[player]
    if not entry then return end
    if entry.root then pcall(function() entry.root:Destroy() end) end
    self.State.entries[player] = nil
end

function Esp:ClearAll()
    for player in pairs(self.State.entries) do
        self:Release(player)
    end
    if self.Gui then
        pcall(function() self.Gui:Destroy() end)
        self.Gui = nil
    end
    self.Info = nil
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

function Esp:UpdateEntry(entry, player, character, humanoid, head, rootPart, cam, vp, camPos)
    local headPos, headOn = cam:WorldToViewportPoint(head.Position)
    local rootPos, rootOn = cam:WorldToViewportPoint(rootPart.Position + Vector3.new(0, -1.2, 0))
    if not (headOn and rootOn) then
        entry.root.Visible = false
        return false
    end

    local height = math.abs(rootPos.Y - headPos.Y)
    if height < 8 then height = 8 end
    local width = math.max(height * 0.52, 20)
    local x = headPos.X - width * 0.5
    local y = headPos.Y
    local visible = self:Visible(head, character)
    local color = self:ColorFor(player, visible)

    entry.root.Visible = true

    entry.box.Visible = self.Settings.Box
    entry.box.Position = UDim2.fromOffset(x, y)
    entry.box.Size = UDim2.fromOffset(width, height)
    entry.stroke.Color = color
    entry.stroke.Thickness = self.Settings.Thickness

    entry.fill.Visible = self.Settings.BoxFill and self.Settings.Box
    entry.fill.Position = UDim2.fromOffset(x, y)
    entry.fill.Size = UDim2.fromOffset(width, height)
    entry.fill.BackgroundColor3 = color

    local hp = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)

    entry.hpBack.Visible = self.Settings.Health
    entry.hpBack.Position = UDim2.fromOffset(x - 6, y)
    entry.hpBack.Size = UDim2.fromOffset(3, height)

    entry.hpBar.Visible = self.Settings.Health
    entry.hpBar.Position = UDim2.fromOffset(x - 6, y + height * (1 - hp))
    entry.hpBar.Size = UDim2.fromOffset(3, math.max(height * hp, 1))
    entry.hpBar.BackgroundColor3 = Color3.new(1 - hp, hp, 0.25)

    local labelY = y + height + 2
    local text = player.Name
    if self.Settings.HealthText then
        text = string.format("%s [%d]", player.Name, math.floor(humanoid.Health))
    end

    entry.name.Visible = self.Settings.Name
    entry.name.Text = text
    entry.name.Position = UDim2.fromOffset(x + width * 0.5 - width, labelY)
    entry.name.Size = UDim2.fromOffset(width * 2, self.Settings.TextSize + 2)
    entry.name.TextSize = self.Settings.TextSize
    entry.name.TextColor3 = color

    entry.dist.Visible = self.Settings.Distance
    entry.dist.Text = string.format("%dm", math.floor((head.Position - camPos).Magnitude))
    entry.dist.Position = UDim2.fromOffset(x + width * 0.5 - width, labelY + self.Settings.TextSize + 1)
    entry.dist.Size = UDim2.fromOffset(width * 2, self.Settings.TextSize)
    entry.dist.TextSize = math.max(self.Settings.TextSize - 2, 8)
    entry.dist.TextColor3 = color

    if self.Settings.Tracer then
        local fromX, fromY = vp.X * 0.5, vp.Y
        local toX, toY = headPos.X, y + height
        local dx, dy = toX - fromX, toY - fromY
        local length = math.sqrt(dx * dx + dy * dy)
        entry.tracer.Visible = length > 1
        entry.tracer.Position = UDim2.fromOffset(fromX, fromY)
        entry.tracer.Size = UDim2.fromOffset(length, 1)
        entry.tracer.Rotation = math.deg(math.atan2(dy, dx))
        entry.tracer.BackgroundColor3 = color
    else
        entry.tracer.Visible = false
    end

    return true
end

function Esp:Update()
    if not self.Settings.Enabled then
        if self.Gui and self.Gui.Enabled then
            self.Gui.Enabled = false
        end
        return
    end

    local cam = self:GetCamera()
    if not cam then return end
    local vp = cam.ViewportSize
    local camPos = cam.CFrame.Position

    local gui = ensureGui()
    gui.Enabled = true

    local seen = {}
    local drawn = 0
    local seenPlayers = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            seenPlayers = seenPlayers + 1
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local head = character and character:FindFirstChild("Head")
            local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))

            local ok = humanoid and head and rootPart and humanoid.Health > 0
                and self:IsEnemy(player)
                and (head.Position - camPos).Magnitude <= self.Settings.MaxDistance

            local entry = self.State.entries[player]
            if ok then
                local okDraw, err = pcall(function()
                    entry = entry or self:Acquire(player)
                    return self:UpdateEntry(entry, player, character, humanoid, head, rootPart, cam, vp, camPos)
                end)
                if okDraw and entry and entry.root.Visible then
                    seen[player] = true
                    drawn = drawn + 1
                elseif not okDraw then
                    self.State.LastError = tostring(err)
                    if not self.State.ErrorReported then
                        self.State.ErrorReported = true
                        warn("[ESP] draw error: " .. tostring(err))
                    end
                end
                if entry and not okDraw then entry.root.Visible = false end
            elseif entry then
                entry.root.Visible = false
            end
        end
    end

    for player, entry in pairs(self.State.entries) do
        if not seen[player] then
            entry.root.Visible = false
            if not player.Parent or not player.Character then
                self:Release(player)
            end
        end
    end

    self.State.Drawn = drawn
    self.State.Seen = seenPlayers

    if self.Info then
        self.Info.Text = string.format("ESP ON | players:%d drawn:%d | cam:%s | err:%s",
            seenPlayers, drawn, tostring(cam ~= nil), tostring(self.State.LastError or "none"))
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

espTab:Button("Diagnose (print why nothing draws)", function()
    local cam = Esp:GetCamera()
    local camPos = cam and cam.CFrame.Position or Vector3.new()
    print("[ESP] ---- DIAG ----")
    print("  enabled      : " .. tostring(Esp.Settings.Enabled))
    print("  gui          : " .. tostring(Esp.Gui ~= nil))
    print("  gui parent   : " .. tostring(Esp.Gui and Esp.Gui.Parent and Esp.Gui.Parent:GetFullName() or "none"))
    print("  camera       : " .. tostring(cam ~= nil))
    print("  teamCount    : " .. tostring(Aimbot.TeamCount) .. " | colorCount: " .. tostring(Aimbot.ColorCount))
    print("  myTeam       : " .. tostring(LocalPlayer.Team and LocalPlayer.Team.Name or "none"))
    print("  players      : " .. tostring(#Players:GetPlayers()))
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local ch = p.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local head = ch and ch:FindFirstChild("Head")
            local dist = head and (head.Position - camPos).Magnitude or -1
            print(string.format("  %s | char=%s | hp=%s | head=%s | dist=%.0f | enemy=%s",
                p.Name, tostring(ch ~= nil), tostring(hum and hum.Health or 0),
                tostring(head ~= nil), dist, tostring(Esp:IsEnemy(p))))
        end
    end
    print("[ESP] ---- END ----")
end)

espTab:Label("Backend: Roblox GUI (works without Drawing API).")

-- ============================================================
--  input & loop
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    -- trigger key is read before the gameProcessed guard: Rivals binds plenty of keys
    if input.KeyCode == Triggerbot.Settings.Key then
        Triggerbot.State.Running = true
    end
    -- G = hard toggle for the ESP, independent of the UI lib
    if input.KeyCode == Enum.KeyCode.G then
        Esp.Settings.Enabled = not Esp.Settings.Enabled
        print("[ESP] " .. (Esp.Settings.Enabled and "ON" or "OFF"))
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
            for _ in pairs(Esp.State.entries) do count = count + 1 end
            if Esp.Settings.Enabled then
                espStatus.ButtonTitle.Text = string.format("status: on | drawn: %d | cached: %d",
                    Esp.State.Drawn or 0, count)
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

print("[W1lteGameYT Hub] Loaded v19.6! Right Shift = UI. RMB = aim. Triggerbot tab = auto-fire. ESP tab = boxes.")

end)

if not success then
    warn("[W1lteGameYT Hub] Error: " .. tostring(err))
    warn("[W1lteGameYT Hub] Tip: enable HTTP requests (request) in your executor settings.")
end
