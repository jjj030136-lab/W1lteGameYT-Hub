print("[W1lteGameYT Hub] Loading... v4.0")

local success, err = pcall(function()

local HasDrawing = pcall(function() local d = Drawing.new("Circle") d:Remove() end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/Vape.txt"))()
local win = lib:Window("W1lteGameYT Hub", Color3.fromRGB(44, 120, 224), Enum.KeyCode.P)

local AdvanceTech = {}

AdvanceTech.Settings = {
    Aimbot = {
        Enabled = true,
        TeamCheck = "FFA",
        FOV = 120,
        ShowFOVCircle = true,
        Smoothing = 10,
        ActivationDelay = 0.07,
        ActivationKey = Enum.UserInputType.MouseButton2,
        AimHeight = -0.35,
        VisibleCheck = true
    }
}

AdvanceTech.State = {
    Aimbot = {
        IsKeyDown = false,
        KeyDownTimestamp = 0,
        LastTime = 0
    },
    UI = {
        IsVisible = true,
        FOVCircle = HasDrawing and Drawing.new("Circle") or nil
    }
}

function AdvanceTech:IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    local check = self.Settings.Aimbot.TeamCheck
    if check == "FFA" or check == "Everyone" then return true end
    if check == "Team-Based" and player.Team ~= LocalPlayer.Team then return true end
    return false
end

function AdvanceTech:GetBestTarget()
    local bestTarget = nil
    local smallestMagnitude = self.Settings.Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if self:IsEnemy(player) and character and humanoid and humanoid.Health > 0 then
            local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")

            if head then
                local aimPosition = head.Position + Vector3.new(0, self.Settings.Aimbot.AimHeight, 0)
                local screenPos, onScreen = Camera:WorldToScreenPoint(aimPosition)

                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distance < smallestMagnitude then
                        smallestMagnitude = distance
                        bestTarget = { AimPosition = aimPosition, Part = head }
                    end
                end
            end
        end
    end
    return bestTarget
end

function AdvanceTech:IsTargetVisible(part)
    if not part or not part.Parent then return true end

    local filters = {}
    if LocalPlayer.Character then
        filters[#filters + 1] = LocalPlayer.Character
    end
    filters[#filters + 1] = part.Parent

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = filters

    local origin = Camera.CFrame.Position
    local result = workspace:Raycast(origin, part.Position - origin, rayParams)
    return result == nil or (result.Instance and result.Instance:IsDescendantOf(part.Parent))
end

function AdvanceTech:GetSmoothFactor(smoothing, dt)
    local rate = 50 / math.max(smoothing, 1)
    return 1 - math.exp(-rate * dt)
end

-- Main Tab
local mainTab = win:Tab("Main")
mainTab:Label("> Aimbot (Camera Lock / Head)")
mainTab:Toggle("Enable Aimbot", AdvanceTech.Settings.Aimbot.Enabled, function(val) AdvanceTech.Settings.Aimbot.Enabled = val end)
mainTab:Slider("FOV Radius", 10, 500, AdvanceTech.Settings.Aimbot.FOV, function(val) AdvanceTech.Settings.Aimbot.FOV = val end)
mainTab:Slider("Aim Smoothing", 1, 50, AdvanceTech.Settings.Aimbot.Smoothing, function(val) AdvanceTech.Settings.Aimbot.Smoothing = val end)
mainTab:Slider("Activation Delay", 0, 50, AdvanceTech.Settings.Aimbot.ActivationDelay * 100, function(val) AdvanceTech.Settings.Aimbot.ActivationDelay = val / 100 end)
mainTab:Slider("Aim Height (-2 = lower, +2 = higher)", -2, 2, AdvanceTech.Settings.Aimbot.AimHeight, function(val) AdvanceTech.Settings.Aimbot.AimHeight = val end)
mainTab:Dropdown("Team Check", {"FFA", "Team-Based", "Everyone"}, function(val) AdvanceTech.Settings.Aimbot.TeamCheck = val end)
mainTab:Toggle("Visible Check (no aim through walls)", AdvanceTech.Settings.Aimbot.VisibleCheck, function(val) AdvanceTech.Settings.Aimbot.VisibleCheck = val end)
mainTab:Toggle("Show FOV Circle", AdvanceTech.Settings.Aimbot.ShowFOVCircle, function(val) AdvanceTech.Settings.Aimbot.ShowFOVCircle = val end)
mainTab:Label("Camera always locks on the Head.")
mainTab:Label("Hold Right-Click to Activate Aimbot.")
mainTab:Label("Press Right Shift to Open/Close the UI.")

local FOVCircle = AdvanceTech.State.UI.FOVCircle
if FOVCircle then
    FOVCircle.Visible = false; FOVCircle.Thickness = 1; FOVCircle.Color = Color3.fromRGB(255, 255, 255); FOVCircle.Filled = false; FOVCircle.NumSides = 64
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        AdvanceTech.State.UI.IsVisible = not AdvanceTech.State.UI.IsVisible
        win.Enabled = AdvanceTech.State.UI.IsVisible
    end
    if input.UserInputType == AdvanceTech.Settings.Aimbot.ActivationKey then
        AdvanceTech.State.Aimbot.IsKeyDown = true
        AdvanceTech.State.Aimbot.KeyDownTimestamp = tick()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == AdvanceTech.Settings.Aimbot.ActivationKey then
        AdvanceTech.State.Aimbot.IsKeyDown = false
    end
end)

RunService:BindToRenderStep("AdvanceTechRender", Enum.RenderPriority.Camera.Value + 1, function()
    pcall(function()
        local aimbot = AdvanceTech.Settings.Aimbot
        local aimbotState = AdvanceTech.State.Aimbot

        if FOVCircle then
            FOVCircle.Visible = aimbot.Enabled and aimbot.ShowFOVCircle and aimbotState.IsKeyDown
            if FOVCircle.Visible then
                FOVCircle.Position = UserInputService:GetMouseLocation()
                FOVCircle.Radius = aimbot.FOV
            end
        end

        if aimbot.Enabled and aimbotState.IsKeyDown and (tick() - aimbotState.KeyDownTimestamp > aimbot.ActivationDelay) then
            local now = tick()
            local dt = math.min(now - aimbotState.LastTime, 0.1)
            aimbotState.LastTime = now

            local target = AdvanceTech:GetBestTarget()
            if target and (not aimbot.VisibleCheck or AdvanceTech:IsTargetVisible(target.Part)) then
                local desired = CFrame.lookAt(Camera.CFrame.Position, target.AimPosition)
                local angle = math.deg(math.acos(math.clamp(desired.LookVector:Dot(Camera.CFrame.LookVector), -1, 1)))

                if angle > 0.02 then
                    local factor = AdvanceTech:GetSmoothFactor(aimbot.Smoothing, dt)
                    Camera.CFrame = Camera.CFrame:Lerp(desired, factor)
                end
            end
        end
    end)
end)

print("[W1lteGameYT Hub] Loaded v4.0! Press Right Shift or P to open/close the UI.")

end)

if not success then
    warn("[W1lteGameYT Hub] Error: " .. tostring(err))
    warn("[W1lteGameYT Hub] Tip: enable HTTP requests (request) in your executor settings and use a PC executor like Fluxus/Synapse X.")
end