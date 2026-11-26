-- Luau / LocalScript / Delta Executor (Android) / Toilet Tower Defense
-- Архітектура: Інтерцепція RemoteEvent + UI для трейду/продажу/гри в режимах

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- КОНФІГУРАЦІЯ ТА СТАН
-- ==========================================
local Config = {
    AutoSellRarity = "Common", -- Автоматичний продаж нижче цієї рідкості
    TradeTargetPlayer = "",    -- Нікнейм гравця для трейду
    GameMode = "Survival"      -- Режим для авто-запуску
}

local State = {
    Trading = false,
    Selling = false,
    Playing = false
}

-- ==========================================
-- МОДУЛЬ 1: ПОШУК REMOTE EVENTS
-- TTD часто оновлює шляхи, тому використовуємо динамічний пошук
-- ==========================================
local Remotes = {}

local function FindRemotes()
    local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes") 
        or ReplicatedStorage:FindFirstChild("Events")
        or ReplicatedStorage
    
    if not remoteFolder then return end
    
    for _, obj in ipairs(remoteFolder:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("sell") then Remotes.Sell = obj end
            if name:find("trade") then Remotes.Trade = obj end
            if name:find("play") or name:find("start") or name:find("mode") then Remotes.Play = obj end
            if name:find("inventory") or name:find("unit") then Remotes.Inventory = obj end
        end
    end
end

FindRemotes()

-- ==========================================
-- МОДУЛЬ 2: ФУНКЦІОНАЛ (ПРОДАЖ, ТРЕЙД, ГРА)
-- ==========================================
local function SellUnit(unitId)
    if not Remotes.Sell then warn("[Breadcrumb] Sell remote не знайдено") return end
    pcall(function()
        Remotes.Sell:FireServer(unitId)
    end)
end

local function TradeUnit(unitId, targetPlayerName)
    if not Remotes.Trade then warn("[Breadcrumb] Trade remote не знайдено") return end
    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    if not targetPlayer then warn("[Breadcrumb] Гравця не знайдено") return end
    
    pcall(function()
        -- Більшість TTD трейдів вимагають послідовність: Request -> Confirm
        Remotes.Trade:FireServer("RequestTrade", targetPlayer.UserId)
        task.wait(0.5)
        Remotes.Trade:FireServer("AddUnit", unitId)
        task.wait(0.3)
        Remotes.Trade:FireServer("ConfirmTrade")
    end)
end

local function StartGameMode(modeName)
    if not Remotes.Play then warn("[Breadcrumb] Play remote не знайдено") return end
    pcall(function()
        Remotes.Play:FireServer(modeName)
    end)
end

-- ==========================================
-- МОДУЛЬ 3: DELTA ANDROID UI
-- ==========================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "Breadcrumb_TTD_Manager"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if syn and syn.protect_gui then
    syn.protect_gui(Gui)
    Gui.Parent = CoreGui
elseif gethui then
    Gui.Parent = gethui()
else
    Gui.Parent = CoreGui
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 480)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = Gui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(60, 60, 80)
Stroke.Thickness = 1.5

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "TTD MANAGER // BREADCRUMB"
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Parent = MainFrame

-- Кнопка продажу
local SellBtn = Instance.new("TextButton")
SellBtn.Size = UDim2.new(1, -20, 0, 40)
SellBtn.Position = UDim2.new(0, 10, 0, 60)
SellBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
SellBtn.Text = "ПРОДАТИ ОБРАНИЙ ЮНІТ"
SellBtn.Font = Enum.Font.GothamBold
SellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SellBtn.TextSize = 13
SellBtn.Parent = MainFrame
Instance.new("UICorner", SellBtn).CornerRadius = UDim.new(0, 6)

SellBtn.MouseButton1Click:Connect(function()
    -- У реальному використанні тут має бути інтеграція з інвентарем гри
    -- Для прикладу викликаємо функцію з ID юніта (потрібно отримати з GUI гри)
    warn("[Breadcrumb] Оберіть юніт в інвентарі гри перед продажем")
end)

-- Поле введення для трейду
local TradeInput = Instance.new("TextBox")
TradeInput.Size = UDim2.new(1, -20, 0, 35)
TradeInput.Position = UDim2.new(0, 10, 0, 120)
TradeInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TradeInput.PlaceholderText = "Нік гравця для трейду..."
TradeInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
TradeInput.Text = ""
TradeInput.Font = Enum.Font.Gotham
TradeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
TradeInput.TextSize = 13
TradeInput.Parent = MainFrame
Instance.new("UICorner", TradeInput).CornerRadius = UDim.new(0, 6)

-- Кнопка трейду
local TradeBtn = Instance.new("TextButton")
TradeBtn.Size = UDim2.new(1, -20, 0, 40)
TradeBtn.Position = UDim2.new(0, 10, 0, 165)
TradeBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 180)
TradeBtn.Text = "ВІДПРАВИТИ ТРЕЙД"
TradeBtn.Font = Enum.Font.GothamBold
TradeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TradeBtn.TextSize = 13
TradeBtn.Parent = MainFrame
Instance.new("UICorner", TradeBtn).CornerRadius = UDim.new(0, 6)

TradeBtn.MouseButton1Click:Connect(function()
    local target = TradeInput.Text
    if target == "" then warn("[Breadcrumb] Введіть нік гравця") return end
    TradeUnit("SELECTED_UNIT_ID", target)
end)

-- Кнопка старту режиму
local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(1, -20, 0, 40)
PlayBtn.Position = UDim2.new(0, 10, 0, 225)
PlayBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
PlayBtn.Text = "ГРАТИ В SURVIVAL"
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.TextSize = 13
PlayBtn.Parent = MainFrame
Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 6)

PlayBtn.MouseButton1Click:Connect(function()
    StartGameMode(Config.GameMode)
end)

-- Лог дій
local LogFrame = Instance.new("ScrollingFrame")
LogFrame.Size = UDim2.new(1, -20, 1, -290)
LogFrame.Position = UDim2.new(0, 10, 0, 280)
LogFrame.BackgroundTransparency = 1
LogFrame.ScrollBarThickness = 4
LogFrame.Parent = MainFrame

local LogLayout = Instance.new("UIListLayout", LogFrame)
LogLayout.Padding = UDim.new(0, 4)

local function AddLog(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 20)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "> " .. text
    label.Font = Enum.Font.Code
    label.TextColor3 = Color3.fromRGB(180, 180, 190)
    label.TextSize = 11
    label.Parent = LogFrame
    LogFrame.CanvasPosition = Vector2.new(0, LogFrame.AbsoluteCanvasSize.Y)
end

AddLog("Система ініціалізована")
AddLog("Remotes знайдені: " .. tostring(#Remotes))
Add
