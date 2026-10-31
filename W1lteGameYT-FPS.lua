print("[W1lteGameYT FPS] Loading... v1.2")

local success, err = pcall(function()

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

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
    Blurred = false,
    BlurSize = 20,
    Flatten = true,
    ShowFPS = true
}

FPS.Originals = {}
FPS.Warned = false
FPS.BlurInstance = nil

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

local FlattenList = {}

local function IsCharacterPart(part)
    local model = part:FindFirstAncestorOfClass("Model")
    return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

for _, item in ipairs(Workspace:GetDescendants()) do
    if item:IsA("BasePart") and not IsCharacterPart(item) then
        table.insert(FlattenList, item)
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
    pcall(function()
        self.Originals.MaximumLOD = gethiddenproperty(Camera, "MaximumLOD")
    end)
    for _, eff in ipairs(EffectsList) do
        self.Originals[eff] = eff.Enabled
    end
    for _, part in ipairs(ParticleList) do
        self.Originals[part] = part.Enabled
    end
    for _, part in ipairs(FlattenList) do
        pcall(function()
            self.Originals[part] = {
                Material = part.Material,
                MaterialVariant = part.MaterialVariant,
                TextureID = part.TextureID
            }
        end)
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
    pcall(function()
        sethiddenproperty(Camera, "MaximumLOD", (q <= 1) and 0 or (self.Originals.MaximumLOD or 1000))
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

function FPS:ApplyBlur()
    if self.Settings.Blurred then
        if not self.BlurInstance then
            pcall(function()
                self.BlurInstance = Instance.new("BlurEffect", Lighting)
            end)
        end
        if self.BlurInstance then
            pcall(function()
                self.BlurInstance.Size = self.Settings.BlurSize
            end)
        end
    elseif self.BlurInstance then
        pcall(function()
            self.BlurInstance:Destroy()
        end)
        self.BlurInstance = nil
    end
end

function FPS:ApplyFlatten()
    for _, part in ipairs(FlattenList) do
        pcall(function()
            local orig = self.Originals[part]
            local sa = part:FindFirstChildOfClass("SurfaceAppearance")
            if self.Settings.Flatten then
                part.Material = Enum.Material.SmoothPlastic
                part.MaterialVariant = ""
                part.TextureID = ""
                if sa then
                    sa.Enabled = false
                end
            elseif orig then
                part.Material = orig.Material
                part.MaterialVariant = orig.MaterialVariant
                part.TextureID = orig.TextureID
                if sa then
                    sa.Enabled = true
                end
            end
        end)
    end
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
        warn("[W1lteGameYT FPS] setfpscap РЅРµ РїРѕРґРґРµСЂР¶РёРІР°РµС‚СЃСЏ СЌС‚РёРј СЌРєСЃРїР»РѕРёС‚РѕРј")
    end
end

function FPS:ApplyAll()
    self:ApplyQuality()
    self:ApplyShadows()
    self:ApplyFog()
    self:ApplyLighting()
    self:ApplyEffects()
    self:ApplyParticles()
    self:ApplyFlatten()
    self:ApplyBlur()
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
    pcall(function()
        sethiddenproperty(Camera, "MaximumLOD", self.Originals.MaximumLOD or 1000)
    end)
    if self.BlurInstance then
        pcall(function()
            self.BlurInstance:Destroy()
        end)
        self.BlurInstance = nil
    end
    for _, part in ipairs(FlattenList) do
        pcall(function()
            local orig = self.Originals[part]
            if orig then
                part.Material = orig.Material
                part.MaterialVariant = orig.MaterialVariant
                part.TextureID = orig.TextureID
                local sa = part:FindFirstChildOfClass("SurfaceAppearance")
                if sa then
                    sa.Enabled = true
                end
            end
        end)
    end
end

FPS:SaveOriginals()

Workspace.DescendantAdded:Connect(function(item)
    local cn = item.ClassName
    if cn == "ParticleEmitter" or cn == "Beam" or cn == "Trail" then
        if not FPS.Settings.Particles then
            pcall(function()
                item.Enabled = false
            end)
        end
    elseif item:IsA("BasePart") and FPS.Settings.Flatten and not IsCharacterPart(item) then
        pcall(function()
            item.Material = Enum.Material.SmoothPlastic
            item.MaterialVariant = ""
            item.TextureID = ""
            local sa = item:FindFirstChildOfClass("SurfaceAppearance")
            if sa then
                sa.Enabled = false
            end
        end)
    end
end)

local mainTab = win:Tab("РћСЃРЅРѕРІРЅРѕРµ")

mainTab:Label("> W1lteGameYT FPS Boost v1.2")
mainTab:Label("F10 - РѕС‚РєСЂС‹С‚СЊ/Р·Р°РєСЂС‹С‚СЊ РјРµРЅСЋ")

local fpsLabel = mainTab:Label("FPS: --")

mainTab:Dropdown("РџСЂРµСЃРµС‚", {"РњР°РєСЃ FPS (РјС‹Р»Рѕ)", "РќРёР·РєРѕРµ", "РЎСЂРµРґРЅРµРµ", "Р’С‹СЃРѕРєРѕРµ", "РћСЂРёРіРёРЅР°Р»"}, function(value)
    if value == "РћСЂРёРіРёРЅР°Р»" then
        FPS:RestoreAll()
        return
    end
    local p = {
        ["РњР°РєСЃ FPS (РјС‹Р»Рѕ)"] = { Quality = 0, Shadows = false, Fog = true, Effects = false, Particles = false, Bright = true, FPSLimit = 0, Blurred = false, BlurSize = 20, Flatten = true },
        ["РќРёР·РєРѕРµ"] = { Quality = 2, Shadows = false, Fog = true, Effects = false, Particles = false, Bright = true, FPSLimit = 144, Blurred = false, BlurSize = 0, Flatten = false },
        ["РЎСЂРµРґРЅРµРµ"] = { Quality = 5, Shadows = true, Fog = false, Effects = true, Particles = true, Bright = true, FPSLimit = 60, Blurred = false, BlurSize = 0, Flatten = false },
        ["Р’С‹СЃРѕРєРѕРµ"] = { Quality = 10, Shadows = true, Fog = false, Effects = true, Particles = true, Bright = false, FPSLimit = 60, Blurred = false, BlurSize = 0, Flatten = false }
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
    FPS.Settings.Blurred = s.Blurred
    FPS.Settings.BlurSize = s.BlurSize
    FPS.Settings.Flatten = s.Flatten
    FPS:ApplyAll()
end)

mainTab:Slider("РљР°С‡РµСЃС‚РІРѕ РіСЂР°С„РёРєРё (0-10)", 0, 10, FPS.Settings.Quality, function(value)
    FPS.Settings.Quality = math.floor(value)
    FPS:ApplyQuality()
end)

mainTab:Toggle("РўРµРЅРё", FPS.Settings.Shadows, function(val)
    FPS.Settings.Shadows = val
    FPS:ApplyShadows()
end)

mainTab:Toggle("РЈР±СЂР°С‚СЊ С‚СѓРјР°РЅ", FPS.Settings.Fog, function(val)
    FPS.Settings.Fog = val
    FPS:ApplyFog()
end)

mainTab:Toggle("РЈР±СЂР°С‚СЊ СЌС„С„РµРєС‚С‹ Рё Р°С‚РјРѕСЃС„РµСЂСѓ", FPS.Settings.Effects, function(val)
    FPS.Settings.Effects = val
    FPS:ApplyEffects()
end)

mainTab:Toggle("РЈР±СЂР°С‚СЊ С‡Р°СЃС‚РёС†С‹", FPS.Settings.Particles, function(val)
    FPS.Settings.Particles = val
    FPS:ApplyParticles()
end)

mainTab:Toggle("РњС‹Р»СЊРЅС‹Рµ С‚РµРєСЃС‚СѓСЂС‹ РјРёСЂР° (РїРѕР»С‹/СЃС‚РµРЅС‹)", FPS.Settings.Flatten, function(val)
    FPS.Settings.Flatten = val
    FPS:ApplyFlatten()
end)

mainTab:Toggle("Р Р°Р·РјС‹С‚РёРµ СЌРєСЂР°РЅР°", FPS.Settings.Blurred, function(val)
    FPS.Settings.Blurred = val
    FPS:ApplyBlur()
end)

mainTab:Slider("РЎРёР»Р° СЂР°Р·РјС‹С‚РёСЏ (0-40)", 0, 40, FPS.Settings.BlurSize, function(value)
    FPS.Settings.BlurSize = math.floor(value)
    FPS:ApplyBlur()
end)

mainTab:Toggle("РЇСЂРєРёР№ СЃРІРµС‚ (РёРіСЂРѕРєРѕРІ РІРёРґРЅРѕ РѕС‚Р»РёС‡РЅРѕ)", FPS.Settings.Bright, function(val)
    FPS.Settings.Bright = val
    FPS:ApplyLighting()
end)

mainTab:Slider("Р›РёРјРёС‚ FPS (0 = Р±РµР· Р»РёРјРёС‚Р°)", 0, 1000, FPS.Settings.FPSLimit, function(value)
    FPS.Settings.FPSLimit = math.floor(value)
    FPS:ApplyFPSLimit()
end)

mainTab:Toggle("РџРѕРєР°Р·С‹РІР°С‚СЊ FPS", FPS.Settings.ShowFPS, function(val)
    FPS.Settings.ShowFPS = val
end)

mainTab:Button("РЎР±СЂРѕСЃРёС‚СЊ РІСЃС‘ (РІРµСЂРЅСѓС‚СЊ РѕСЂРёРіРёРЅР°Р»)", function()
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
    warn("[W1lteGameYT FPS] РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё: " .. tostring(err))
end

print("[W1lteGameYT FPS] Loaded v1.2! F10 = UI.")
