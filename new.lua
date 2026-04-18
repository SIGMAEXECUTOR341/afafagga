local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local pGui = player:WaitForChild("PlayerGui")

if pGui:FindFirstChild("KikiaHookV2") then pGui.KikiaHookV2:Destroy() end

-- --- ESP CONFIGURATION (DEIN CODE) ---
local ESP_SETTINGS = {
    Enabled = false,
    Teamcheck = false,
    WallCheck = false,
    ShowBox = false,
    BoxColor = Color3.new(0, 1, 0),
    BoxOutlineColor = Color3.new(0, 0, 0),
    ShowName = false,
    NameColor = Color3.new(1, 1, 1),
    ShowHealth = false,
    HealthHighColor = Color3.new(0, 1, 0),
    HealthLowColor = Color3.new(1, 0, 0),
    ShowSkeletons = false,
    SkeletonsColor = Color3.new(1, 1, 1),
    ShowTracer = false,
    TracerColor = Color3.new(1, 1, 1),
    TracerPosition = "Bottom",
    TracerThickness = 1,
    ShowDistance = false,
}

local aimbotEnabled = false
local aimPart = "Head"
local smoothPercent = 15
local fovRadius = 110
local aimKey = Enum.UserInputType.MouseButton2
local isBinding = false
local fovVisible = true

local cache = {}
local bones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "LowerTorso"}, {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

-- --- UTILITY ---
local function create(class, properties)
    local drawing = Drawing.new(class)
    for property, value in pairs(properties) do drawing[property] = value end
    return drawing
end

local function getChar(p)
    return p.Character or workspace:FindFirstChild(p.Name) or (workspace:FindFirstChild("Live") and workspace.Live:FindFirstChild(p.Name))
end

local function createEsp(p)
    if p == player then return end
    local esp = {
        boxOutline = create("Square", {Thickness = 3, Color = ESP_SETTINGS.BoxOutlineColor, Filled = false, Visible = false}),
        box = create("Square", {Thickness = 1, Color = ESP_SETTINGS.BoxColor, Filled = false, Visible = false}),
        name = create("Text", {Color = ESP_SETTINGS.NameColor, Center = true, Size = 13, Outline = true, Visible = false}),
        healthOutline = create("Line", {Thickness = 3, Color = Color3.new(0, 0, 0), Visible = false}),
        health = create("Line", {Thickness = 1, Visible = false}),
        distance = create("Text", {Color = Color3.new(1, 1, 1), Size = 12, Outline = true, Center = true, Visible = false}),
        tracer = create("Line", {Thickness = ESP_SETTINGS.TracerThickness, Color = ESP_SETTINGS.TracerColor, Visible = false}),
        skeletonLines = {}
    }
    cache[p] = esp
end

-- --- UI SETUP (KIKIAHOOK V2) ---
local screenGui = Instance.new("ScreenGui", pGui); screenGui.Name = "KikiaHookV2"; screenGui.ResetOnSpawn = false
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 520, 0, 450); mainFrame.Position = UDim2.new(0.5, -260, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12); mainFrame.BorderSizePixel = 0
Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(0, 255, 0)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then mainFrame.Visible = not mainFrame.Visible end
end)

local sidebar = Instance.new("Frame", mainFrame)
sidebar.Size = UDim2.new(0, 120, 1, 0); sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 10); sidebar.BorderSizePixel = 0
local container = Instance.new("Frame", mainFrame)
container.Size = UDim2.new(1, -140, 1, -20); container.Position = UDim2.new(0, 130, 0, 10); container.BackgroundTransparency = 1

local vFrame = Instance.new("ScrollingFrame", container); vFrame.Size = UDim2.new(1,0,1,0); vFrame.BackgroundTransparency = 1; vFrame.Visible = true; vFrame.CanvasSize = UDim2.new(0,0,1.5,0); vFrame.ScrollBarThickness = 2
local aFrame = Instance.new("Frame", container); aFrame.Size = UDim2.new(1,0,1,0); aFrame.BackgroundTransparency = 1; aFrame.Visible = false
Instance.new("UIListLayout", vFrame).Padding = UDim.new(0, 5)
Instance.new("UIListLayout", aFrame).Padding = UDim.new(0, 8)

local function makeTab(txt, y, target)
    local b = Instance.new("TextButton", sidebar); b.Size = UDim2.new(1, 0, 0, 40); b.Position = UDim2.new(0, 0, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(10, 10, 10); b.Text = txt; b.TextColor3 = Color3.fromRGB(150, 150, 150); b.Font = Enum.Font.Code; b.BorderSizePixel = 0
    b.MouseButton1Click:Connect(function() 
        vFrame.Visible = false; aFrame.Visible = false; target.Visible = true 
        for _,v in pairs(sidebar:GetChildren()) do if v:IsA("TextButton") then v.TextColor3 = Color3.fromRGB(150, 150, 150) end end
        b.TextColor3 = Color3.fromRGB(0, 255, 0)
    end)
end
makeTab("Visuals", 10, vFrame); makeTab("Aimbot", 55, aFrame)

local function createToggle(txt, parent, cb)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.9, 0, 0, 25); f.BackgroundTransparency = 1
    local b = Instance.new("TextButton", f); b.Size = UDim2.new(0, 16, 0, 16); b.Position = UDim2.new(0, 0, 0.5, -8); b.BackgroundColor3 = Color3.fromRGB(30, 30, 30); b.Text = ""; b.BorderSizePixel = 0
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(1, -25, 1, 0); t.Position = UDim2.new(0, 25, 0, 0); t.Text = txt; t.TextColor3 = Color3.fromRGB(200, 200, 200); t.Font = Enum.Font.Code; t.TextSize = 13; t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left
    local on = false
    b.MouseButton1Click:Connect(function() on = not on; b.BackgroundColor3 = on and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(30, 30, 30); cb(on) end)
end

-- --- UI CONTENT ---
createToggle("ESP Master", vFrame, function(v) ESP_SETTINGS.Enabled = v end)
createToggle("Show Boxes", vFrame, function(v) ESP_SETTINGS.ShowBox = v end)
createToggle("Show Names", vFrame, function(v) ESP_SETTINGS.ShowName = v end)
createToggle("Show Health", vFrame, function(v) ESP_SETTINGS.ShowHealth = v end)
createToggle("Show Skeletons", vFrame, function(v) ESP_SETTINGS.ShowSkeletons = v end)
createToggle("Show Tracers", vFrame, function(v) ESP_SETTINGS.ShowTracer = v end)
createToggle("Show Distance", vFrame, function(v) ESP_SETTINGS.ShowDistance = v end)

createToggle("Aimbot Master", aFrame, function(v) aimbotEnabled = v end)
createToggle("Wall Check", aFrame, function(v) ESP_SETTINGS.WallCheck = v end)

-- --- MAIN LOOP (MERGED) ---
RunService.RenderStepped:Connect(function()
    for p, esp in pairs(cache) do
        local char = getChar(p)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if ESP_SETTINGS.Enabled and char and hum and hrp and hum.Health > 0 then
            local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local head = char:FindFirstChild("Head") or hrp
                local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height * 0.6
                local boxPos = Vector2.new(pos.X - width / 2, pos.Y - height / 2)

                -- Box
                esp.box.Visible = ESP_SETTINGS.ShowBox; esp.box.Size = Vector2.new(width, height); esp.box.Position = boxPos; esp.box.Color = ESP_SETTINGS.BoxColor
                esp.boxOutline.Visible = ESP_SETTINGS.ShowBox; esp.boxOutline.Size = esp.box.Size; esp.boxOutline.Position = esp.box.Position
                
                -- Name & Dist
                esp.name.Visible = ESP_SETTINGS.ShowName; esp.name.Text = p.Name; esp.name.Position = Vector2.new(pos.X, boxPos.Y - 15)
                local dist = (camera.CFrame.Position - hrp.Position).Magnitude
                esp.distance.Visible = ESP_SETTINGS.ShowDistance; esp.distance.Text = math.floor(dist) .. "m"; esp.distance.Position = Vector2.new(pos.X, boxPos.Y + height + 5)

                -- Health
                if ESP_SETTINGS.ShowHealth then
                    local healthPct = hum.Health / hum.MaxHealth
                    esp.healthOutline.Visible = true; esp.healthOutline.From = Vector2.new(boxPos.X - 5, boxPos.Y + height); esp.healthOutline.To = Vector2.new(boxPos.X - 5, boxPos.Y)
                    esp.health.Visible = true; esp.health.From = esp.healthOutline.From; esp.health.To = Vector2.new(boxPos.X - 5, boxPos.Y + (height * (1 - healthPct))); esp.health.Color = ESP_SETTINGS.HealthLowColor:Lerp(ESP_SETTINGS.HealthHighColor, healthPct)
                else esp.health.Visible = false; esp.healthOutline.Visible = false end

                -- Tracer
                if ESP_SETTINGS.ShowTracer then
                    esp.tracer.Visible = true; esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y); esp.tracer.To = Vector2.new(pos.X, pos.Y)
                else esp.tracer.Visible = false end

                -- Skeleton
                if ESP_SETTINGS.ShowSkeletons then
                    for i, bonePair in ipairs(bones) do
                        local b1, b2 = char:FindFirstChild(bonePair[1]), char:FindFirstChild(bonePair[2])
                        if b1 and b2 then
                            if not esp.skeletonLines[i] then esp.skeletonLines[i] = create("Line", {Thickness = 1, Color = ESP_SETTINGS.SkeletonsColor}) end
                            local p1 = camera:WorldToViewportPoint(b1.Position); local p2 = camera:WorldToViewportPoint(b2.Position)
                            esp.skeletonLines[i].From = Vector2.new(p1.X, p1.Y); esp.skeletonLines[i].To = Vector2.new(p2.X, p2.Y); esp.skeletonLines[i].Visible = true
                        end
                    end
                else for _, line in pairs(esp.skeletonLines) do line.Visible = false end end
            else -- Offscreen
                for _, obj in pairs(esp) do if type(obj) ~= "table" then obj.Visible = false else for _,l in pairs(obj) do l.Visible = false end end end
            end
        else -- Dead/Hidden
            for _, obj in pairs(esp) do if type(obj) ~= "table" then obj.Visible = false else for _,l in pairs(obj) do l.Visible = false end end end
        end
    end
    
    -- AIMBOT LOGIC
    if aimbotEnabled and UserInputService:IsMouseButtonPressed(aimKey) then
        local target = nil; local dist = fovRadius
        for _, p in pairs(Players:GetPlayers()) do
            local c = getChar(p)
            if p ~= player and c and c:FindFirstChild(aimPart) then
                local sPos, on = camera:WorldToViewportPoint(c[aimPart].Position)
                local mDist = (Vector2.new(sPos.X, sPos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if on and mDist < dist then target = c[aimPart]; dist = mDist end
            end
        end
        if target then
            local tPos = camera:WorldToViewportPoint(target.Position); local mPos = UserInputService:GetMouseLocation()
            mousemoverel((tPos.X - mPos.X) / (smoothPercent/5), (tPos.Y - mPos.Y) / (smoothPercent/5))
        end
    end
end)

-- SETUP
for _, p in ipairs(Players:GetPlayers()) do createEsp(p) end
Players.PlayerAdded:Connect(createEsp)
Players.PlayerRemoving:Connect(function(p) if cache[p] then for _,v in pairs(cache[p]) do if type(v) ~= "table" then v:Remove() else for _,l in pairs(v) do l:Remove() end end end cache[p] = nil end end)

-- DRAG
local d, s, sp; mainFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d=true s=i.Position sp=mainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position-s mainFrame.Position=UDim2.new(sp.X.Scale, sp.X.Offset+delta.X, sp.Y.Scale, sp.Y.Offset+delta.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d=false end end)
