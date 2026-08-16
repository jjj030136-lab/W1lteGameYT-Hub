print("[W1lteGameYT Hub] Loading... v8.0 (Exunys-based)")

local success, err = pcall(function()

local HasDrawing = pcall(function() local d = Drawing.new("Circle") d:Remove() end)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/Vape.txt"))()
local win = lib:Window("W1lteGameYT Hub", Color3.fromRGB(44, 120, 224), Enum.KeyCode.P)

local Aimbot = {}

Aimbot.Settings = {
    Enabled = true,
    TeamCheck = "FFA",
    AliveCheck = true,
    WallCheck = true,
    Smoothing = 0.15,
    Mode = "Camera",
    MouseSensitivity = 3,
    TriggerKey = Enum.UserInputType.MouseButton2,
    LockPart = "Head",
    AimHeight = 0,
    FOV = 120,
    ShowFOVCircle = true
}

Aimbot.State = {
    Running = false,
    Locked = nil,
    Animation = nil,
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
    local part = character:FindFirstChild(self.Settings.LockPart)
    if not part then return nil end
    return part.Position + Vector3.new(0, self.Settings.AimHeight, 0)
end

function Aimbot:CancelLock()
    self.State.Locked = nil
    if self.State.Animation then
        self.State.Animation:Cancel()
        self.State.Animation = nil
    end
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
        if not onScreen or distance > self.Settings.FOV then
            self:CancelLock()
        end
    end
end

-- UI
local mainTab = win:Tab("Main")
mainTab:Label("> Aimbot (Exunys-based)")
mainTab:Toggle("Enable Aimbot", Aimbot.Settings.Enabled, function(val) Aimbot.Settings.Enabled = val end)
mainTab:Slider("FOV Radius", 10, 500, Aimbot.Settings.FOV, function(val) Aimbot.Settings.FOV = val end)
mainTab:Slider("Smoothness (0 = instant)", 0, 100, Aimbot.Settings.Smoothing * 100, function(val) Aimbot.Settings.Smoothing = val / 100 end)
mainTab:Slider("Mouse Speed (Mouse mode)", 10, 50, Aimbot.Settings.MouseSensitivity * 10, function(val) Aimbot.Settings.MouseSensitivity = val / 10 end)
mainTab:Slider("Aim Height (-2 = lower, +2 = higher)", -2, 2, Aimbot.Settings.AimHeight, function(val) Aimbot.Settings.AimHeight = val end)
mainTab:Dropdown("Aim Mode", {"Camera", "Mouse"}, function(val) Aimbot.Settings.Mode = val end)
mainTab:Dropdown("Team Check", {"FFA", "Team-Based", "Everyone"}, function(val) Aimbot.Settings.TeamCheck = val end)
mainTab:Toggle("Visible Check (no aim through walls)", Aimbot.Settings.WallCheck, function(val) Aimbot.Settings.WallCheck = val end)
mainTab:Toggle("Show FOV Circle", Aimbot.Settings.ShowFOVCircle, function(val) Aimbot.Settings.ShowFOVCircle = val end)
mainTab:Label("Aims exactly at Head. Hold Right-Click to lock.")
mainTab:Label("Press Right Shift to Open/Close the UI.")

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
        if Aimbot.Settings.Enabled and Aimbot.FOVCircle then
            Aimbot.FOVCircle.Visible = Aimbot.Settings.ShowFOVCircle and (Aimbot.State.Running or Aimbot.State.Locked ~= nil)
            if Aimbot.FOVCircle.Visible then
                Aimbot.FOVCircle.Radius = Aimbot.Settings.FOV
                Aimbot.FOVCircle.Position = UserInputService:GetMouseLocation()
            end
        elseif Aimbot.FOVCircle then
            Aimbot.FOVCircle.Visible = false
        end

        if Aimbot.State.Running and Aimbot.Settings.Enabled then
            Aimbot:GetClosestPlayer()

            if Aimbot.State.Locked then
                local character = Aimbot.State.Locked.Character
                local aimPosition = Aimbot:GetAimPosition(character)
                if aimPosition then
                    if Aimbot.Settings.Mode == "Mouse" and mousemoverel then
                        local vector = Camera:WorldToViewportPoint(aimPosition)
                        local mousePos = UserInputService:GetMouseLocation()
                        local sens = math.clamp(Aimbot.Settings.MouseSensitivity, 0.1, 5)
                        mousemoverel((vector.X - mousePos.X) * sens, (vector.Y - mousePos.Y) * sens)
                    else
                        if Aimbot.Settings.Smoothing > 0 then
                            if Aimbot.State.Animation then
                                Aimbot.State.Animation:Cancel()
                            end
                            Aimbot.State.Animation = TweenService:Create(Camera, TweenInfo.new(Aimbot.Settings.Smoothing, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                                CFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
                            })
                            Aimbot.State.Animation:Play()
                        else
                            Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
                        end
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

print("[W1lteGameYT Hub] Loaded v8.0! Hold Right-Click to lock on head. Right Shift to toggle UI.")

end)

if not success then
    warn("[W1lteGameYT Hub] Error: " .. tostring(err))
    warn("[W1lteGameYT Hub] Tip: enable HTTP requests (request) in your executor settings.")
end