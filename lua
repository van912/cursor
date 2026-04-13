return function(state)
-- MenuGroup:AddButton("Unload", function() Library:Unload() end) -- Перенес анлоад вниз для корректной очистки

-- =========================================================
-- === ЛОГИКА КАСТОМНОГО КУРСОРA (ИНТЕГРАЦИЯ) ===
-- =========================================================

-- === НАСТРОЙКИ ЭФФЕКТА ===
local LINE_COUNT = 4           
local ROTATION_SPEED = 3    
local PULSE_SPEED = 4          
local RADIUS_BASE = 12         
local RADIUS_AMPLITUDE = 3     
local LINE_SIZE = UDim2.new(0, 6, 0, 2) 

-- Переменные для хранения текущего состояния
local CursorEnabled = true
local CursorColor = Color3.fromRGB(255, 255, 255)

-- === СОЗДАНИЕ GUI ===
local ParentContainer = CoreGui
local success, _ = pcall(function() local t = Instance.new("Frame"); t.Parent = CoreGui; t:Destroy() end)
if not success then
    ParentContainer = Players.LocalPlayer:WaitForChild("PlayerGui")
end

if ParentContainer:FindFirstChild("CrazyDiamondCursor") then
    ParentContainer:FindFirstChild("CrazyDiamondCursor"):Destroy()
end

local CursorGui = Instance.new("ScreenGui")
CursorGui.Name = "CrazyDiamondCursor"
CursorGui.DisplayOrder = 9999999
CursorGui.IgnoreGuiInset = true 
CursorGui.Enabled = CursorEnabled 
CursorGui.Parent = ParentContainer

-- Функция для создания сверхмаленького контура
local function AddStroke(parent, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Transparency = 0.2 -- Легкая прозрачность для мягкости
    stroke.Parent = parent
    return stroke
end

-- Центральная точка
local CenterDot = Instance.new("Frame")
CenterDot.Size = UDim2.new(0, 2, 0, 2) -- Чуть увеличил, чтобы контур был виден
CenterDot.AnchorPoint = Vector2.new(0.5, 0.5)
CenterDot.BackgroundColor3 = CursorColor
CenterDot.BorderSizePixel = 0
CenterDot.ZIndex = 10
CenterDot.Parent = CursorGui

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = CenterDot
AddStroke(CenterDot, 0.8) -- Контур для точки

local OrbitLines = {}

for i = 1, LINE_COUNT do
    local line = Instance.new("Frame")
    line.Size = LINE_SIZE
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = CursorColor
    line.BorderSizePixel = 0
    line.ZIndex = 9
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = line
    
    -- Добавляем контур один раз при создании
    AddStroke(line, 0.8)
    
    line.Parent = CursorGui
    table.insert(OrbitLines, line)
end

-- === УПРАВЛЕНИЕ В GUI ===
CursorGroup:AddToggle('UseCustomCursor', {
    Text = 'Enable Custom Cursor',
    Default = true,
    Tooltip = 'Toggles the animated orbital cursor',
})

Toggles.UseCustomCursor:OnChanged(function()
    CursorEnabled = Toggles.UseCustomCursor.Value
    CursorGui.Enabled = CursorEnabled
    if not CursorEnabled then
        UserInputService.MouseIconEnabled = true
    end
end)

CursorGroup:AddLabel('Cursor Color'):AddColorPicker('CursorColorPicker', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Cursor Color',
})

Options.CursorColorPicker:OnChanged(function()
    CursorColor = Options.CursorColorPicker.Value
    CenterDot.BackgroundColor3 = CursorColor
    for _, line in ipairs(OrbitLines) do
        line.BackgroundColor3 = CursorColor
    end
end)

-- === ОБНОВЛЕННАЯ ЛОГИКА (Орбиты) ===
local timePassed = 0

local cursorConnection = RunService.RenderStepped:Connect(function(dt)
    if not CursorEnabled then return end
    
    UserInputService.MouseIconEnabled = false
    timePassed = timePassed + dt
    local mousePos = UserInputService:GetMouseLocation()
    
    CenterDot.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
    
    local currentRadius = RADIUS_BASE + math.cos(timePassed * PULSE_SPEED) * RADIUS_AMPLITUDE
    local currentTransparency = 0.1 + (math.sin(timePassed * PULSE_SPEED) * 0.1)
    
    for i, line in ipairs(OrbitLines) do
        local angle = (timePassed * ROTATION_SPEED) + (i * (math.pi * 2 / LINE_COUNT))
        local offsetX = math.cos(angle) * currentRadius
        local offsetY = math.sin(angle) * currentRadius

        line.Position = UDim2.new(0, mousePos.X + offsetX, 0, mousePos.Y + offsetY)
        line.Rotation = math.deg(angle)
        line.BackgroundTransparency = currentTransparency
        
        -- Синхронизируем прозрачность контура с линией
        if line:FindFirstChild("UIStroke") then
            line.UIStroke.Transparency = currentTransparency + 0.1
        end
    end
end)

-- === ОЧИСТКА ===
local function Cleanup()
    if cursorConnection then cursorConnection:Disconnect() end
    UserInputService.MouseIconEnabled = true
    if CursorGui then CursorGui:Destroy() end
    Library:Unload()
end

MenuGroup:AddButton("Unload", Cleanup)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKey", "UseCustomCursor", "CursorColorPicker" }) 

ThemeManager:SetFolder("ObsidianSoft")
SaveManager:SetFolder("ObsidianSoft/main")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

script.Destroying:Connect(Cleanup)
end
