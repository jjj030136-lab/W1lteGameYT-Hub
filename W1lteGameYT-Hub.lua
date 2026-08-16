print("[W1lteGameYT Hub] Loading... v9.0")

local success, err = pcall(function()

local HasDrawing = pcall(function() local d = Drawing.new("Circle") d:Remove() end)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/Vape.txt"))()
local win = lib:Window("W1lteGameYT Hub", Color3.fromRGB(44, 120, 224), Enum.KeyCode.P)

local Aimbot = {}

Aimbot.Settings = {
    Enabled = true,
    TeamCheck = "FFA",
    WallCheck = true,
    Smoothing = 10,
    Mode = "Mouse",
    TriggerKey = Enum.UserInputType.MouseButton2,
    AimPoint = "Neck",
    AimHeight = -0.8,
    FOV = 120,
    ShowFOVCircle = true,
    DebugPrint = false
}

Aimbot.State = {
    Running = false,
    Locked = nil,
    LastTime = 0,
    LastDebug = 0,
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

function Aimbot:IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    local check = self.Settings.TeamCheck
    if check == "FFA" or check == "Everyone" then return true end
    if check == "Team-Based" and player.Team ~= LocalPlayer.Team then return true end
    return false
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
                    if self.Settings.WallCheck and #(Camera:GetPartsObscuringTarget({aimPosition}, character:GetDescendants())) > 0 then
                        continue
                    end

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

        if not character or not humanoid or humanoid.Health <= 0 then
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
    local rate = 50 / math.max(self.Settings.Smoothing, 1)
    return 1 - math.exp(-rate * dt)
end

-- UI
local mainTab = win:Tab("Main")
mainTab:Label("> Aimbot v9.0")
mainTab:Toggle("Enable Aimbot", Aimbot.Settings.Enabled, function(val) Aimbot.Settings.Enabled = val end)
mainTab:Slider("FOV Radius", 10, 500, Aimbot.Settings.FOV, function(val) Aimbot.Settings.FOV = val end)
mainTab:Slider("Aim Smoothing", 1, 50, Aimbot.Settings.Smoothing, function(val) Aimbot.Settings.Smoothing = val end)
mainTab:Slider("Aim Height (-2 = lower, +2 = higher)", -2, 2, Aimbot.Settings.AimHeight, function(val) Aimbot.Settings.AimHeight = val end)
mainTab:Dropdown("Aim Point", {"Head", "Neck", "Chest"}, function(val) Aimbot.Settings.AimPoint = val end)
mainTab:Dropdown("Aim Mode", {"Mouse", "Camera"}, function(val) Aimbot.Settings.Mode = val end)
mainTab:Dropdown("Team Check", {"FFA", "Team-Based", "Everyone"}, function(val) Aimbot.Settings.TeamCheck = val end)
mainTab:Toggle("Visible Check (no aim through walls)", Aimbot.Settings.WallCheck, function(val) Aimbot.Settings.WallCheck = val end)
mainTab:Toggle("Show FOV Circle", Aimbot.Settings.ShowFOVCircle, function(val) Aimbot.Settings.ShowFOVCircle = val end)
mainTab:Toggle("Debug Print", Aimbot.Settings.DebugPrint, function(val) Aimbot.Settings.DebugPrint = val end)
mainTab:Label("Hold Right-Click to lock on. Right Shift = UI.")

-- Input
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Aimbot.State.UI.IsVisible = not Aimbot.State.UI.IsVisible
        win.Enabled = Aimbot.State.UI.IsVisible
    end
    if input.UserInputType == Aimbot.Settings.TriggerKey then
        Aimbot.State.Running = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Aimbot.Settings.TriggerKey then
        Aimbot.State.Running = false
        Aimbot:CancelLock()
    end
end)

-- Main loop
RunService.RenderStepped:Connect(function()
    pcall(function()
        if Aimbot.FOVCircle then
            Aimbot.FOVCircle.Visible = Aimbot.Settings.Enabled and Aimbot.Settings.ShowFOVCircle and Aimbot.State.Running
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
                if aimPosition then
                    local now = tick()
                    local dt = math.min(now - Aimbot.State.LastTime, 0.1)
                    Aimbot.State.LastTime = now

                    if Aimbot.Settings.Mode == "Mouse" and mousemoverel then
                        local vector = Camera:WorldToViewportPoint(aimPosition)
                        local mousePos = UserInputService:GetMouseLocation()
                        local dx = vector.X - mousePos.X
                        local dy = vector.Y - mousePos.Y
                        local magnitude = math.sqrt(dx * dx + dy * dy)

                        if Aimbot.Settings.DebugPrint and (now - Aimbot.State.LastDebug) > 2 then
                            Aimbot.State.LastDebug = now
                            print(string.format("[W1lte] Aim=%.0f,%.0f Mouse=%.0f,%.0f Delta=%.0f,%.0f Mag=%.1f Point=%s",
                                vector.X, vector.Y, mousePos.X, mousePos.Y, dx, dy, magnitude, Aimbot.Settings.AimPoint))
                        end

                        if magnitude > 0.7 then
                            local factor = Aimbot:GetSmoothFactor(dt)
                            local mx = dx * factor
                            local my = dy * factor
                            local m2 = math.sqrt(mx * mx + my * my)

                            if m2 < 2 then
                                local scale = 2 / math.max(m2, 0.01)
                                mx = mx * scale
                                my = my * scale
                            end

                            mx = math.clamp(mx, -25, 25)
                            my = math.clamp(my, -25, 25)
                            mousemoverel(mx, my)
                        end
                    else
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
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
end)

print("[W1lteGameYT Hub] Loaded v9.0! Hold Right-Click to lock on. Right Shift to toggle UI.")

end)

if not success then
    warn("[W1lteGameYT Hub] Error: " .. tostring(err))
    warn("[W1lteGameYT Hub] Tip: enable HTTP requests (request) in your executor settings.")
end