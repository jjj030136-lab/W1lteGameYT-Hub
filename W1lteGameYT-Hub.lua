print("[W1lteGameYT Hub] Loading... v2.2")

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
        AimPart = "Head",
        AimHeight = -0.5,
        Mode = "Mouse",
        VisibleCheck = false,
        MaxMovePerFrame = 40,
        Noise = 0.35
    },
    ESP = {
        Enabled = true,
        ShowBoxes = true,
        ShowLines = true,
        ShowNames = true,
        ShowDistance = true,
        UseTeamColor = false
    },
    Privacy = {
        AntiSpectate = true
    }
}

AdvanceTech.State = {
    Aimbot = {
        IsKeyDown = false,
        KeyDownTimestamp = 0,
        LastTime = 0
    },
    ESP = {
        Pools = {}
    },
    Privacy = {
        OriginalTransparencies = {}
    },
    UI = {
        IsVisible = true,
        FOVCircle = HasDrawing and Drawing.new("Circle") or nil
    }
}

local RNG = Random.new()

function AdvanceTech:IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    local check = self.Settings.Aimbot.TeamCheck
    if check == "FFA" or check == "Everyone" then return true end
    if check == "Team-Based" and player.Team ~= LocalPlayer.Team then return true end
    return false
end

function AdvanceTech:GetAimPart(character)
    local aimPart = self.Settings.Aimbot.AimPart
    return character:FindFirstChild(aimPart) or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

function AdvanceTech:GetBestTarget()
    local bestTarget = nil
    local smallestMagnitude = self.Settings.Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if self:IsEnemy(player) and character and humanoid and humanoid.Health > 0 then
            local targetPart = self:GetAimPart(character)

            if targetPart then
                local aimPosition = targetPart.Position + Vector3.new(0, self.Settings.Aimbot.AimHeight, 0)
                local screenPos, onScreen = Camera:WorldToScreenPoint(aimPosition)

                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distance < smallestMagnitude then
                        smallestMagnitude = distance
                        bestTarget = { AimPosition = aimPosition, Part = targetPart }
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

function AdvanceTech:RestoreAppearance()
    for part, transparency in pairs(self.State.Privacy.OriginalTransparencies) do
        if part and part.Parent then
            part.LocalTransparencyModifier = transparency
        end
    end
    self.State.Privacy.OriginalTransparencies = {}
end

function AdvanceTech:ApplyInvisibility()
    local character = LocalPlayer.Character
    if not character then return end

    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant:IsA("Decal") then
            if not self.State.Privacy.OriginalTransparencies[descendant] then
                self.State.Privacy.OriginalTransparencies[descendant] = descendant.LocalTransparencyModifier
            end
            descendant.LocalTransparencyModifier = 1
        end
    end
end

function AdvanceTech:GetSmoothFactor(smoothing, dt)
    local rate = 50 / math.max(smoothing, 1)
    return 1 - math.exp(-rate * dt)
end

function AdvanceTech:GetESPPool(player)
    local pool = self.State.ESP.Pools[player]
    if not pool then
        pool = {
            Box = Drawing.new("Square"),
            Line = Drawing.new("Line"),
            Text = Drawing.new("Text")
        }
        pool.Box.Thickness = 1
        pool.Box.Filled = false
        pool.Box.Color = Color3.fromRGB(255, 50, 50)
        pool.Line.Thickness = 1
        pool.Line.Color = Color3.fromRGB(255, 50, 50)
        pool.Text.Size = 13
        pool.Text.Center = true
        pool.Text.Outline = true
        pool.Text.Color = Color3.fromRGB(255, 255, 255)
        AdvanceTech.State.ESP.Pools[player] = pool
    end
    return pool
end

function AdvanceTech:ResetESPPool(pool)
    pool.Box.Visible = false
    pool.Line.Visible = false
    pool.Text.Visible = false
end

-- Main Tab
local mainTab = win:Tab("Main")
mainTab:Label("> Aimbot / Target Lock")
mainTab:Toggle("Enable Aimbot", AdvanceTech.Settings.Aimbot.Enabled, function(val) AdvanceTech.Settings.Aimbot.Enabled = val end)
mainTab:Slider("FOV Radius", 10, 500, AdvanceTech.Settings.Aimbot.FOV, function(val) AdvanceTech.Settings.Aimbot.FOV = val end)
mainTab:Slider("Aim Smoothing", 1, 50, AdvanceTech.Settings.Aimbot.Smoothing, function(val) AdvanceTech.Settings.Aimbot.Smoothing = val end)
mainTab:Slider("Activation Delay", 0, 50, AdvanceTech.Settings.Aimbot.ActivationDelay * 100, function(val) AdvanceTech.Settings.Aimbot.ActivationDelay = val / 100 end)
mainTab:Slider("Aim Height (-2 = lower, +2 = higher)", -2, 2, AdvanceTech.Settings.Aimbot.AimHeight, function(val) AdvanceTech.Settings.Aimbot.AimHeight = val end)
mainTab:Dropdown("Aim Part", {"Head", "Torso"}, function(val) AdvanceTech.Settings.Aimbot.AimPart = (val == "Torso") and "HumanoidRootPart" or "Head" end)
mainTab:Dropdown("Aim Mode", {"Mouse", "Silent"}, function(val) AdvanceTech.Settings.Aimbot.Mode = val end)
mainTab:Toggle("Visible Check (no aim through walls)", AdvanceTech.Settings.Aimbot.VisibleCheck, function(val) AdvanceTech.Settings.Aimbot.VisibleCheck = val end)
mainTab:Dropdown("Team Check", {"FFA", "Team-Based", "Everyone"}, function(val) AdvanceTech.Settings.Aimbot.TeamCheck = val end)
mainTab:Toggle("Show FOV Circle", AdvanceTech.Settings.Aimbot.ShowFOVCircle, function(val) AdvanceTech.Settings.Aimbot.ShowFOVCircle = val end)
mainTab:Toggle("Anti Spectate (invisible)", AdvanceTech.Settings.Privacy.AntiSpectate, function(val) AdvanceTech.Settings.Privacy.AntiSpectate = val end)
mainTab:Label("> Wallhack / ESP")
mainTab:Toggle("Enable ESP", AdvanceTech.Settings.ESP.Enabled, function(val) AdvanceTech.Settings.ESP.Enabled = val end)
mainTab:Toggle("Boxes", AdvanceTech.Settings.ESP.ShowBoxes, function(val) AdvanceTech.Settings.ESP.ShowBoxes = val end)
mainTab:Toggle("Tracer Lines", AdvanceTech.Settings.ESP.ShowLines, function(val) AdvanceTech.Settings.ESP.ShowLines = val end)
mainTab:Toggle("Names", AdvanceTech.Settings.ESP.ShowNames, function(val) AdvanceTech.Settings.ESP.ShowNames = val end)
mainTab:Toggle("Distance", AdvanceTech.Settings.ESP.ShowDistance, function(val) AdvanceTech.Settings.ESP.ShowDistance = val end)
mainTab:Toggle("Team Color", AdvanceTech.Settings.ESP.UseTeamColor, function(val) AdvanceTech.Settings.ESP.UseTeamColor = val end)
mainTab:Label("Hold Right-Click to Activate Aimbot.")
mainTab:Label("Aimbot works through walls (Visible Check = off).")
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

LocalPlayer.CharacterRemoving:Connect(function()
    AdvanceTech:RestoreAppearance()
end)

RunService:BindToRenderStep("AdvanceTechRender", Enum.RenderPriority.Camera.Value + 1, function()
    pcall(function()
        if AdvanceTech.Settings.Privacy.AntiSpectate then
            AdvanceTech:ApplyInvisibility()
        end

        local aimbot = AdvanceTech.Settings.Aimbot
        local aimbotState = AdvanceTech.State.Aimbot
        local espSettings = AdvanceTech.Settings.ESP

        if FOVCircle then
            FOVCircle.Visible = aimbot.Enabled and aimbot.ShowFOVCircle and aimbotState.IsKeyDown
            if FOVCircle.Visible then
                FOVCircle.Position = UserInputService:GetMouseLocation()
                FOVCircle.Radius = aimbot.FOV
            end
        end

        if espSettings.Enabled and HasDrawing then
            local seen = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if AdvanceTech:IsEnemy(player) then
                    local character = player.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                    if character and humanoid and humanoid.Health > 0 then
                        local head = character:FindFirstChild("Head")
                        local hrp = character:FindFirstChild("HumanoidRootPart")

                        if head and hrp then
                            local topPos, topOn = Camera:WorldToScreenPoint(head.Position + Vector3.new(0, 0.5, 0))
                            local botPos, botOn = Camera:WorldToScreenPoint(hrp.Position - Vector3.new(0, 2, 0))

                            if topOn and botOn then
                                seen[player] = true
                                local pool = AdvanceTech:GetESPPool(player)

                                local height = math.max(topPos.Y - botPos.Y, 10)
                                local width = height * 0.7
                                local centerX = (topPos.X + botPos.X) / 2
                                local boxX = centerX - width / 2
                                local boxY = topPos.Y

                                local color = espSettings.UseTeamColor and player.TeamColor.Color or Color3.fromRGB(255, 50, 50)
                                pool.Box.Color = color
                                pool.Line.Color = color

                                pool.Box.Visible = espSettings.ShowBoxes
                                if pool.Box.Visible then
                                    pool.Box.Position = Vector2.new(boxX, boxY)
                                    pool.Box.Size = Vector2.new(width, height)
                                end

                                pool.Line.Visible = espSettings.ShowLines
                                if pool.Line.Visible then
                                    pool.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                    pool.Line.To = Vector2.new(centerX, botPos.Y)
                                end

                                pool.Text.Visible = espSettings.ShowNames
                                if pool.Text.Visible then
                                    local text = player.Name
                                    if espSettings.ShowDistance then
                                        local dist = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                                        text = text .. " [" .. dist .. "m]"
                                    end
                                    pool.Text.Text = text
                                    pool.Text.Position = Vector2.new(centerX, boxY - 15)
                                end
                            end
                        end
                    end
                end
            end

            for player, pool in pairs(AdvanceTech.State.ESP.Pools) do
                if not seen[player] then
                    AdvanceTech:ResetESPPool(pool)
                end
                if player.Parent == nil then
                    pool.Box:Remove()
                    pool.Line:Remove()
                    pool.Text:Remove()
                    AdvanceTech.State.ESP.Pools[player] = nil
                end
            end
        else
            for _, pool in pairs(AdvanceTech.State.ESP.Pools) do
                AdvanceTech:ResetESPPool(pool)
            end
        end

        if aimbot.Enabled and aimbotState.IsKeyDown and (tick() - aimbotState.KeyDownTimestamp > aimbot.ActivationDelay) then
            local now = tick()
            local dt = math.min(now - aimbotState.LastTime, 0.1)
            aimbotState.LastTime = now

            local target = AdvanceTech:GetBestTarget()
            if target and (not aimbot.VisibleCheck or AdvanceTech:IsTargetVisible(target.Part)) then
                local factor = AdvanceTech:GetSmoothFactor(aimbot.Smoothing, dt)

                if aimbot.Mode == "Silent" then
                    local desired = CFrame.lookAt(Camera.CFrame.Position, target.AimPosition)
                    local angle = math.deg(math.acos(math.clamp(desired.LookVector:Dot(Camera.CFrame.LookVector), -1, 1)))
                    if angle > 0.05 then
                        Camera.CFrame = Camera.CFrame:Lerp(desired, factor)
                    end
                else
                    local targetScreenPos, onScreen = Camera:WorldToScreenPoint(target.AimPosition)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local moveVector = Vector2.new(targetScreenPos.X - mousePos.X, targetScreenPos.Y - mousePos.Y)

                        if moveVector.Magnitude > 0.5 and mousemoverel then
                            local maxMove = aimbot.MaxMovePerFrame
                            local dx = math.clamp(moveVector.X * factor, -maxMove, maxMove)
                            local dy = math.clamp(moveVector.Y * factor, -maxMove, maxMove)

                            if aimbot.Noise > 0 then
                                dx = dx + RNG:NextNumber(-aimbot.Noise, aimbot.Noise)
                                dy = dy + RNG:NextNumber(-aimbot.Noise, aimbot.Noise)
                            end

                            mousemoverel(dx, dy)
                        end
                    end
                end
            end
        end
    end)
end)

print("[W1lteGameYT Hub] Loaded v2.2! Press Right Shift or P to open/close the UI.")

end)

if not success then
    warn("[W1lteGameYT Hub] Error: " .. tostring(err))
    warn("[W1lteGameYT Hub] Tip: enable HTTP requests (request) in your executor settings and use a PC executor like Fluxus/Synapse X.")
end