-- Auto Egg Race Farm v2 - Loadstring Ready
local p = game.Players.LocalPlayer
local ws = game:GetService("Workspace")

local CONFIG = {
    SpeedFast = 150,
    SpeedNormal = 16,
    StartSlowRadius = 40,
    StartStopRadius = 8,
    EggCollectRadius = 6,
    AutoFarm = false,
    StartPosition = nil,
    SelectedRarities = {
        Common=false, Uncommon=false, Rare=false, Epic=false,
        Legendary=false, Mythic=false, Secret=false, Eternal=false, Divine=false
    },
    Priority = {
        Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5,
        Mythic=6, Secret=7, Eternal=8, Divine=9
    }
}

local char, hrp, hum
local state = "IDLE"
local targetEgg = nil

local function updateChar()
    char = p.Character
    if char then
        hrp = char:WaitForChild("HumanoidRootPart")
        hum = char:WaitForChild("Humanoid")
    end
end

local function getEggRarity(obj)
    if not obj or not obj:IsA("BasePart") then return nil end
    local name = obj.Name:lower()
    if not (name:find("egg") or name:find("telur")) then return nil end
    local map = {
        ["divine"]="Divine", ["eternal"]="Eternal", ["secret"]="Secret",
        ["mythic"]="Mythic", ["legendary"]="Legendary", ["epic"]="Epic",
        ["rare"]="Rare", ["uncommon"]="Uncommon", ["common"]="Common",
    }
    for k, v in pairs(map) do
        if name:find(k) then return v end
    end
    local attr = obj:GetAttribute("Rarity") or obj:GetAttribute("rarity")
    if attr then
        for k, v in pairs(map) do
            if tostring(attr):lower():find(k) then return v end
        end
    end
    return "Unknown"
end

local function findBestEgg()
    local best, bestScore = nil, -1
    local myPos = hrp and hrp.Position or Vector3.new()
    for _, obj in ipairs(ws:GetDescendants()) do
        if obj:IsA("BasePart") then
            local rarity = getEggRarity(obj)
            if rarity and CONFIG.SelectedRarities[rarity] then
                local dist = (obj.Position - myPos).Magnitude
                local prio = CONFIG.Priority[rarity] or 0
                local score = prio * 1000 - dist
                if score > bestScore then
                    bestScore = score
                    best = obj
                end
            end
        end
    end
    return best
end

local function moveTo(pos, speed)
    if not hrp or not hum then return end
    hum.WalkSpeed = speed
    local dir = pos - hrp.Position
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude > 0 then dir = dir.Unit end
    hrp.Velocity = dir * speed
end

local function distanceTo(pos)
    if not hrp or not pos then return math.huge end
    return (hrp.Position - pos).Magnitude
end

local function collectEgg(egg)
    if not egg then return end
    local prompt = egg:FindFirstChildOfClass("ProximityPrompt")
    if prompt then fireproximityprompt(prompt) return end
    local click = egg:FindFirstChildOfClass("ClickDetector")
    if click then fireclickdetector(click) return end
end

local function autoFarmLoop()
    while task.wait(0.05) do
        if not CONFIG.AutoFarm then continue end
        if not char or not hrp or not hum then updateChar() continue end
        if hum.Health <= 0 then continue end
        if not CONFIG.StartPosition then continue end
        
        local distToStart = distanceTo(CONFIG.StartPosition)
        
        if state == "IDLE" then
            targetEgg = findBestEgg()
            if targetEgg then state = "GO_TO_EGG" end
        elseif state == "GO_TO_EGG" then
            if not targetEgg or not targetEgg.Parent then
                state = "RETURNING" continue
            end
            if distanceTo(targetEgg.Position) <= CONFIG.EggCollectRadius then
                collectEgg(targetEgg)
                task.wait(0.1)
                state = "RETURNING"
            else
                moveTo(targetEgg.Position, CONFIG.SpeedFast)
            end
        elseif state == "RETURNING" then
            if distToStart <= CONFIG.StartSlowRadius then
                moveTo(CONFIG.StartPosition, CONFIG.SpeedNormal)
                if distToStart <= CONFIG.StartStopRadius then
                    state = "DEPOSITING"
                end
            else
                moveTo(CONFIG.StartPosition, CONFIG.SpeedFast)
            end
        elseif state == "DEPOSITING" then
            hum.WalkSpeed = CONFIG.SpeedNormal
            hrp.Velocity = Vector3.new(0,0,0)
            task.wait(0.8)
            state = "IDLE"
        end
    end
end

-- UI
local g = Instance.new("ScreenGui", p:WaitForChild("PlayerGui"))
g.ResetOnSpawn = false
g.Name = "EggFarmUI"

local main = Instance.new("Frame", g)
main.Size = UDim2.new(0, 280, 0, 530)
main.Position = UDim2.new(0, 20, 0.15, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 40, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🏁 AUTO EGG RACE"
title.TextColor3 = Color3.fromRGB(255, 200, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() g:Destroy() end)

local statusLbl = Instance.new("TextLabel", main)
statusLbl.Size = UDim2.new(1, -20, 0, 22)
statusLbl.Position = UDim2.new(0, 10, 0, 45)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Status: IDLE"
statusLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 12
statusLbl.TextXAlignment = Enum.TextXAlignment.Left

local startInfo = Instance.new("TextLabel", main)
startInfo.Size = UDim2.new(1, -20, 0, 18)
startInfo.Position = UDim2.new(0, 10, 0, 72)
startInfo.BackgroundTransparency = 1
startInfo.Text = "📍 Start: BELUM DI-SET"
startInfo.TextColor3 = Color3.fromRGB(255, 150, 100)
startInfo.Font = Enum.Font.GothamBold
startInfo.TextSize = 12
startInfo.TextXAlignment = Enum.TextXAlignment.Left

local setStartBtn = Instance.new("TextButton", main)
setStartBtn.Size = UDim2.new(1, -20, 0, 34)
setStartBtn.Position = UDim2.new(0, 10, 0, 92)
setStartBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
setStartBtn.Text = "📍 SET START DI POSISI INI"
setStartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
setStartBtn.Font = Enum.Font.GothamBold
setStartBtn.TextSize = 13
setStartBtn.BorderSizePixel = 0
Instance.new("UICorner", setStartBtn).CornerRadius = UDim.new(0, 6)

setStartBtn.MouseButton1Click:Connect(function()
    updateChar()
    if hrp then
        CONFIG.StartPosition = hrp.Position
        startInfo.Text = string.format("📍 Start: (%.0f, %.0f, %.0f)", 
            hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
        startInfo.TextColor3 = Color3.fromRGB(100, 255, 100)
        setStartBtn.Text = "✅ TERSIMPAN!"
        setStartBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        task.wait(1)
        setStartBtn.Text = "📍 SET START DI POSISI INI"
        setStartBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    end
end)

local rarityLabel = Instance.new("TextLabel", main)
rarityLabel.Size = UDim2.new(1, -20, 0, 20)
rarityLabel.Position = UDim2.new(0, 10, 0, 132)
rarityLabel.BackgroundTransparency = 1
rarityLabel.Text = "🎯 Pilih Rarity:"
rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
rarityLabel.Font = Enum.Font.GothamBold
rarityLabel.TextSize = 13
rarityLabel.TextXAlignment = Enum.TextXAlignment.Left

local rarityFrame = Instance.new("ScrollingFrame", main)
rarityFrame.Size = UDim2.new(1, -20, 0, 200)
rarityFrame.Position = UDim2.new(0, 10, 0, 155)
rarityFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
rarityFrame.BorderSizePixel = 0
rarityFrame.ScrollBarThickness = 4
rarityFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", rarityFrame).CornerRadius = UDim.new(0, 8)

local layout = Instance.new("UIListLayout", rarityFrame)
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local rarities = {
    {name="Common",    color=Color3.fromRGB(180, 180, 180)},
    {name="Uncommon",  color=Color3.fromRGB(80, 220, 100)},
    {name="Rare",      color=Color3.fromRGB(80, 150, 255)},
    {name="Epic",      color=Color3.fromRGB(180, 80, 255)},
    {name="Legendary", color=Color3.fromRGB(255, 200, 50)},
    {name="Mythic",    color=Color3.fromRGB(255, 100, 100)},
    {name="Secret",    color=Color3.fromRGB(255, 50, 200)},
    {name="Eternal",   color=Color3.fromRGB(100, 255, 255)},
    {name="Divine",    color=Color3.fromRGB(255, 240, 150)},
}

local rarityButtons = {}

for _, r in ipairs(rarities) do
    local btn = Instance.new("TextButton", rarityFrame)
    btn.Size = UDim2.new(1, -8, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    btn.Text = "  ☐ " .. r.name
    btn.TextColor3 = r.color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = r.color
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    rarityButtons[r.name] = {btn=btn, stroke=stroke, color=r.color}
    btn.MouseButton1Click:Connect(function()
        CONFIG.SelectedRarities[r.name] = not CONFIG.SelectedRarities[r.name]
        local d = rarityButtons[r.name]
        if CONFIG.SelectedRarities[r.name] then
            d.btn.Text = "  ☑ " .. r.name
            d.btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            d.stroke.Transparency = 0.3
        else
            d.btn.Text = "  ☐ " .. r.name
            d.btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            d.stroke.Transparency = 0.7
        end
    end)
end

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    rarityFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
end)

local btnRow = Instance.new("Frame", main)
btnRow.Size = UDim2.new(1, -20, 0, 30)
btnRow.Position = UDim2.new(0, 10, 0, 362)
btnRow.BackgroundTransparency = 1

local selectAll = Instance.new("TextButton", btnRow)
selectAll.Size = UDim2.new(0.48, 0, 1, 0)
selectAll.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
selectAll.Text = "Select All"
selectAll.TextColor3 = Color3.fromRGB(255, 255, 255)
selectAll.Font = Enum.Font.Gotham
selectAll.TextSize = 12
selectAll.BorderSizePixel = 0
Instance.new("UICorner", selectAll).CornerRadius = UDim.new(0, 6)

local clearAll = Instance.new("TextButton", btnRow)
clearAll.Size = UDim2.new(0.48, 0, 1, 0)
clearAll.Position = UDim2.new(0.52, 0, 0, 0)
clearAll.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
clearAll.Text = "Clear"
clearAll.TextColor3 = Color3.fromRGB(255, 255, 255)
clearAll.Font = Enum.Font.Gotham
clearAll.TextSize = 12
clearAll.BorderSizePixel = 0
Instance.new("UICorner", clearAll).CornerRadius = UDim.new(0, 6)

selectAll.MouseButton1Click:Connect(function()
    for k in pairs(CONFIG.SelectedRarities) do
        CONFIG.SelectedRarities[k] = true
        local d = rarityButtons[k]
        if d then
            d.btn.Text = "  ☑ " .. k
            d.btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            d.stroke.Transparency = 0.3
        end
    end
end)

clearAll.MouseButton1Click:Connect(function()
    for k in pairs(CONFIG.SelectedRarities) do
        CONFIG.SelectedRarities[k] = false
        local d = rarityButtons[k]
        if d then
            d.btn.Text = "  ☐ " .. k
            d.btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            d.stroke.Transparency = 0.7
        end
    end
end)

local speedLabel = Instance.new("TextLabel", main)
speedLabel.Size = UDim2.new(1, -20, 0, 18)
speedLabel.Position = UDim2.new(0, 10, 0, 400)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "⚡ Kecepatan Lari:"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 12
speedLabel.TextXAlignment = Enum.TextXAlignment.Left

local speedBox = Instance.new("TextBox", main)
speedBox.Size = UDim2.new(1, -20, 0, 32)
speedBox.Position = UDim2.new(0, 10, 0, 420)
speedBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Text = tostring(CONFIG.SpeedFast)
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 14
speedBox.BorderSizePixel = 0
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)

speedBox.FocusLost:Connect(function(enter)
    if enter then
        local v = tonumber(speedBox.Text)
        if v and v > 0 and v <= 500 then
            CONFIG.SpeedFast = v
        else
            speedBox.Text = tostring(CONFIG.SpeedFast)
        end
    end
end)

local startBtn = Instance.new("TextButton", main)
startBtn.Size = UDim2.new(1, -20, 0, 42)
startBtn.Position = UDim2.new(0, 10, 0, 460)
startBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
startBtn.Text = "▶  START FARM"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 15
startBtn.BorderSizePixel = 0
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)

startBtn.MouseButton1Click:Connect(function()
    if not CONFIG.StartPosition then
        startBtn.Text = "❌ SET START DULU!"
        startBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        task.wait(1.5)
        startBtn.Text = "▶  START FARM"
        startBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        return
    end
    local any = false
    for _, v in pairs(CONFIG.SelectedRarities) do
        if v then any = true break end
    end
    if not any then
        startBtn.Text = "❌ PILIH RARITY!"
        startBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        task.wait(1.5)
        startBtn.Text = "▶  START FARM"
        startBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        return
    end
    CONFIG.AutoFarm = not CONFIG.AutoFarm
    if CONFIG.AutoFarm then
        startBtn.Text = "⏸  STOP FARM"
        startBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        state = "IDLE"
    else
        startBtn.Text = "▶  START FARM"
        startBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        state = "IDLE"
        if hum then hum.WalkSpeed = CONFIG.SpeedNormal end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if not g.Parent then break end
        statusLbl.Text = "Status: " .. state .. "  |  Speed: " .. math.floor(hum and hum.WalkSpeed or 0)
    end
end)

updateChar()
p.CharacterAdded:Connect(function()
    task.wait(1)
    updateChar()
end)

task.spawn(autoFarmLoop)
print("✅ Auto Egg Race Farm Loaded!")
