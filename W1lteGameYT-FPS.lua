print("[W1lteGameYT FPS] Loading... v1.0")

local success, err = pcall(function()

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/Vape.txt"))()
local win = lib:Window("W1lteGameYT FPS Boost", Color3.fromRGB(44, 120, 224), Enum.KeyCode.F10)

local FPS = {}

FPS.Settings = {
    Quality = 0,
    Shadows = false,
    Fog = false,
    Effects = false,
    Particles = false,
    Bright = true,
    FPSLimit = 0,
    ShowFPS = true
}

FPS.Originals = {}
FPS.Warned = false

local Atmosphere = Workspace:FindFirstChildOfClass("Atmosphere")
local EffectsList = {}
local ParticleList = {}

for _, item in ipairs(Workspace:GetDescendants()) do
    local cn = item.ClassName
    if cn == "ParticleEmitter" or cn == "Beam" or cn == "Trail" or cn == "Smoke" or cn == "Fire" or cn == "Sparkles" then
        table.insert(ParticleList, item)
    end
end
for _, item in ipairs(Lighting:GetChildren()) do
    local cn = item.ClassName
    if cn == "BloomEffect" or cn == "SunRaysEffect" or cn == "ColorCorrectionEffect" or cn == "BlurEffect" or cn == "DepthOfFieldEffect" then
        table.insert(EffectsList, item)
    end
end
for _, item in ipairs(Workspace:GetChildren()) do
    local cn = item.ClassName
    if cn == "BloomEffect" or cn == "SunRaysEffect" or cn == "ColorCorrectionEffect" or cn == "BlurEffect" or cn == "DepthOfFieldEffect" then
        table.insert(EffectsList, item)
    end
end

local Terrain = Workspace:FindFirstChildOfClass("Terrain")

function FPS:SaveOriginals()
    pcall(function()
        self.Originals.RenderQuality = settings().RenderQualityLevel
    end)
    pcall(function()
        self.Originals.GlobalShadows = Lighting.GlobalShadows
        self.Originals.Ambient = Lighting.Ambient
        self.Originals.OutdoorAmbient = Lighting.OutdoorAmbient
        self.Originals.Brightness = Lighting.Brightness
        self.Originals.ClockTime = Lighting.ClockTime
        self.Originals.FogStart = Lighting.FogStart
        self.Originals.FogEnd = Lighting.FogEnd
        self.Originals.Technology = Lighting.Technology
    end)
    pcall(function()
        self.Originals.AtmosphereEnabled = Atmosphere and Atmosphere.Enabled
    end)
    for _, eff in ipairs(EffectsList) do
        self.Originals[eff] = eff.Enabled
    end
    for _, part in ipairs(ParticleList) do
        self.Originals[part] = part.Enabled
    end
end

function FPS:ApplyQuality()
    local q = math.clamp(math.floor(self.Settings.Quality), 0, 10)
    pcall(function()
        settings().RenderQualityLevel = q
    end)
    pcall(function()
        game:GetService("QualitySettings"):SetQualityLevel(q)
    end)
    pcall(function()
        Lighting.Technology = (q <= 1) and Enum.Technology.Compatibility or self.Originals.Technology
    end)
end

function FPS:ApplyShadows()
    pcall(function()
        Lighting.GlobalShadows = self.Settings.Shadows
    end)
end

function FPS:ApplyFog()
    if self.Settings.Fog then
        pcall(function()
            Lighting.FogStart = 100000
            Lighting.FogEnd = 100000
        end)
    else
        pcall(function()
            Lighting.FogStart = self.Originals.FogStart
            Lighting.FogEnd = self.Originals.FogEnd
        end)
    end
end

function FPS:ApplyLighting()
    if self.Settings.Bright then
        pcall(function()
            Lighting.Ambient = Color3.fromRGB(190, 190, 190)
            Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
            Lighting.Brightness = 1
            Lighting.ClockTime = 14
        end)
    else
        pcall(function()
            Lighting.Ambient = self.Originals.Ambient
            Lighting.OutdoorAmbient = self.Originals.OutdoorAmbient
            Lighting.Brightness = self.Originals.Brightness
            Lighting.ClockTime = self.Originals.ClockTime
        end)
    end
end

function FPS:ApplyEffects()
    for _, eff in ipairs(EffectsList) do
        pcall(function()
            eff.Enabled = self.Settings.Effects
        end)
    end
    pcall(function()
        if Atmosphere then
            Atmosphere.Enabled = self.Settings.Effects
        end
    end)
    pcall(function()
        if Terrain then
            if not self.Settings.Effects then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
            end
        end
    end)
end

function FPS:ApplyParticles()
    for _, part in ipairs(ParticleList) do
        pcall(function()
            part.Enabled = self.Settings.Particles
        end)
    end
end

function FPS:ApplyFPSLimit()
    local limit = self.Settings.FPSLimit
    local fn = setfpscap or _G.setfpscap
    if fn then
        pcall(fn, (limit <= 0) and 999 or limit)
    elseif not self.Warned then
        self.Warned = true
        warn("[W1lteGameYT FPS] setfpscap не поддерживается этим эксплоитом")
    end
end

function FPS:ApplyAll()
    self:ApplyQuality()
    self:ApplyShadows()
    self:ApplyFog()
    self:ApplyLighting()
    self:ApplyEffects()
    self:ApplyParticles()
    self:ApplyFPSLimit()
end

function FPS:RestoreAll()
    pcall(function()
        settings().RenderQualityLevel = self.Originals.RenderQuality
    end)
    pcall(function()
        Lighting.GlobalShadows = self.Originals.GlobalShadows
        Lighting.Ambient = self.Originals.Ambient
        Lighting.OutdoorAmbient = self.Originals.OutdoorAmbient
        Lighting.Brightness = self.Originals.Brightness
        Lighting.ClockTime = self.Originals.ClockTime
        Lighting.FogStart = self.Originals.FogStart
        Lighting.FogEnd = self.Originals.FogEnd
        Lighting.Technology = self.Originals.Technology
    end)
    pcall(function()
        if Atmosphere then
            Atmosphere.Enabled = self.Originals.AtmosphereEnabled
        end
    end)
    for _, eff in ipairs(EffectsList) do
        pcall(function()
            eff.Enabled = self.Originals[eff]
        end)
    end
    for _, part in ipairs(ParticleList) do
        pcall(function()
            part.Enabled = self.Originals[part]
        end)
    end
end

FPS:SaveOriginals()

Workspace.DescendantAdded:Connect(function(item)
    if not FPS.Settings.Particles then
        local cn = item.ClassName
        if cn == "ParticleEmitter" or cn == "Beam" or cn == "Trail" then
            pcall(function()
                item.Enabled = false
            end)
        end
    end
end)

local mainTab = win:Tab("Основное")

mainTab:Label("> W1lteGameYT FPS Boost v1.0")
mainTab:Label("F10 - открыть/закрыть меню")

local fpsLabel = mainTab:Label("FPS: --")

mainTab:Dropdown("Пресет", {"Макс FPS", "Низкое", "Среднее", "Высокое", "Оригинал"}, function(value)
    if value == "Оригинал" then
        FPS:RestoreAll()
        return
    end
    local p = {
        ["Макс FPS"] = { Quality = 0, Shadows = false, Fog = true, Effects = false, Particles = false, Bright = true, FPSLimit = 0 },
        ["Низкое"] = { Quality = 2, Shadows = false, Fog = true, Effects = false, Particles = false, Bright = true, FPSLimit = 144 },
        ["Среднее"] = { Quality = 5, Shadows = true, Fog = false, Effects = true, Particles = true, Bright = true, FPSLimit = 60 },
        ["Высокое"] = { Quality = 10, Shadows = true, Fog = false, Effects = true, Particles = true, Bright = false, FPSLimit = 60 }
    }
    local s = p[value]
    if not s then return end
    FPS.Settings.Quality = s.Quality
    FPS.Settings.Shadows = s.Shadows
    FPS.Settings.Fog = s.Fog
    FPS.Settings.Effects = s.Effects
    FPS.Settings.Particles = s.Particles
    FPS.Settings.Bright = s.Bright
    FPS.Settings.FPSLimit = s.FPSLimit
    FPS:ApplyAll()
end)

mainTab:Slider("Качество графики (0-10)", 0, 10, FPS.Settings.Quality, function(value)
    FPS.Settings.Quality = math.floor(value)
    FPS:ApplyQuality()
end)

mainTab:Toggle("Тени", FPS.Settings.Shadows, function(val)
    FPS.Settings.Shadows = val
    FPS:ApplyShadows()
end)

mainTab:Toggle("Убрать туман", FPS.Settings.Fog, function(val)
    FPS.Settings.Fog = val
    FPS:ApplyFog()
end)

mainTab:Toggle("Убрать эффекты и атмосферу", FPS.Settings.Effects, function(val)
    FPS.Settings.Effects = val
    FPS:ApplyEffects()
end)

mainTab:Toggle("Убрать частицы", FPS.Settings.Particles, function(val)
    FPS.Settings.Particles = val
    FPS:ApplyParticles()
end)

mainTab:Toggle("Яркий свет (игроков видно отлично)", FPS.Settings.Bright, function(val)
    FPS.Settings.Bright = val
    FPS:ApplyLighting()
end)

mainTab:Slider("Лимит FPS (0 = без лимита)", 0, 1000, FPS.Settings.FPSLimit, function(value)
    FPS.Settings.FPSLimit = math.floor(value)
    FPS:ApplyFPSLimit()
end)

mainTab:Toggle("Показывать FPS", FPS.Settings.ShowFPS, function(val)
    FPS.Settings.ShowFPS = val
end)

mainTab:Button("Сбросить всё (вернуть оригинал)", function()
    FPS:RestoreAll()
end)

FPS:ApplyAll()

local frameCount = 0
local lastFpsTime = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = os.clock()
    if now - lastFpsTime >= 0.25 then
        local fps = math.floor((frameCount / (now - lastFpsTime)) + 0.5)
        frameCount = 0
        lastFpsTime = now
        if FPS.Settings.ShowFPS and fpsLabel and fpsLabel.ButtonTitle then
            pcall(function()
                fpsLabel.ButtonTitle.Text = "FPS: " .. fps
            end)
        end
    end
end)

end)

if not success then
    warn("[W1lteGameYT FPS] Ошибка загрузки: " .. tostring(err))
end

print("[W1lteGameYT FPS] Loaded v1.0! F10 = UI.")
