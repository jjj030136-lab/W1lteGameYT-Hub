print("[W1lteGameYT Hub] Loading... v14.0")

local success, err = pcall(function()

local HasDrawing = pcall(function() local d = Drawing.new("Circle") d:Remove() end)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/Vape.txt"))()
local win = lib:Window("W1lteGameYT Hub", Color3.fromRGB(44, 120, 224), Enum.KeyCode.F10)

local Aimbot = {}

Aimbot.Settings = {
    Enabled = true,
    TeamCheck = true,
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
    for _, p in ipairs(Players:GetPlayers()) do
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
    return teamCount, colorCount
end

function Aimbot:IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    if not self.Settings.TeamCheck then return true end

    -- real team mode: 2+ distinct team objects
    if self.TeamCount >= 2 then
        return player.Team ~= LocalPlayer.Team
    end

    -- Rivals: everyone shares ONE Team object, but teams differ by TeamColor
    if self.ColorCount >= 2 then
        local myColor = LocalPlayer.TeamColor
        if myColor and myColor ~= BrickColor.new("Medium stone grey") then
            return player.TeamColor ~= myColor
        end
    end

    -- no team info at all -> FFA, everyone is an enemy
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

-- Menu
local mainTab = win:Tab("Main")
mainTab:Label("> Aimbot v14.0")
mainTab:Toggle("Enable Aimbot", Aimbot.Settings.Enabled, function(val) Aimbot.Settings.Enabled = val end)
mainTab:Toggle("Team Check (skip teammates)", Aimbot.Settings.TeamCheck, function(val) Aimbot.Settings.TeamCheck = val end)
mainTab:Dropdown("Aim Point", {"Neck", "Head", "Chest"}, function(val) Aimbot.Settings.AimPoint = val end)
mainTab:Slider("Aim Height (-2 = lower, +2 = higher)", -2, 2, Aimbot.Settings.AimHeight, function(val) Aimbot.Settings.AimHeight = val end)
mainTab:Slider("Aim Speed (1 = slow, 50 = fast)", 1, 50, Aimbot.Settings.AimSpeed, function(val) Aimbot.Settings.AimSpeed = val end)
mainTab:Slider("FOV Size", 10, 500, Aimbot.Settings.FOV, function(val) Aimbot.Settings.FOV = val end)
local debugLabel = mainTab:Label("Teams: ... | Colors: ...")
mainTab:Button("Debug: dump players to console", function()
    print("[W1lteGameYT] ---- PLAYERS DUMP ----")
    for _, p in ipairs(Players:GetPlayers()) do
        local t = p.Team and p.Team.Name or "none"
        print(p.Name .. " | Team: " .. t .. " | Color: " .. p.TeamColor.Name)
    end
    print("[W1lteGameYT] ---- END DUMP ----")
end)
mainTab:Label("Aims at ENEMIES only (team check on).")
mainTab:Label("Open/Close UI: Right Shift only.")
mainTab:Label("Hold Right-Click to lock on.")

-- Input (Right Shift only)
UserInputService.InputBegan:Connect(function(input, gpe)
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
end)

-- Main loop
local errorsReported = 0

RunService.RenderStepped:Connect(function()
    pcall(function()
        Aimbot.TeamCount, Aimbot.ColorCount = Aimbot:CountTeams()
        pcall(function()
            debugLabel:Text("Teams: " .. tostring(Aimbot.TeamCount) .. " | Colors: " .. tostring(Aimbot.ColorCount) ..
                " | MyTeam: " .. tostring(LocalPlayer.Team and LocalPlayer.Team.Name or "none") ..
                " | MyColor: " .. tostring(LocalPlayer.TeamColor and LocalPlayer.TeamColor.Name or "none"))
        end)
    end)

    local ok, err = pcall(function()
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
    end)
    if not ok and errorsReported < 5 then
        errorsReported = errorsReported + 1
        warn("[W1lteGameYT Hub] Loop error: " .. tostring(err))
    end
end)

print("[W1lteGameYT Hub] Loaded v14.0! Right Shift = UI. RMB = aim. Debug label shows team/color counts.")

end)

if not success then
    warn("[W1lteGameYT Hub] Error: " .. tostring(err))
    warn("[W1lteGameYT Hub] Tip: enable HTTP requests (request) in your executor settings.")
end