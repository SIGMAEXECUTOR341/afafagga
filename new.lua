local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local pGui = player:WaitForChild("PlayerGui")

if pGui:FindFirstChild("KikiaHookV2") then pGui.KikiaHookV2:Destroy() end

-- --- SETTINGS ---
local aimbotEnabled = false
local wallCheck = false
local aimPart = "Head"
local smoothPercent = 15
local fovRadius = 110
local aimKey = Enum.UserInputType.MouseButton2
local isBinding = false
local fovVisible = true

local espSettings = {
    Box = false, Skeleton = false, 
    BoxColor = Color3.fromRGB(0, 255, 0), 
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    FOVColor = Color3.fromRGB(0, 255, 0)
}

-- --- UI SETUP ---
local screenGui = Instance.new("ScreenGui", pGui); screenGui.Name = "KikiaHookV2"; screenGui.ResetOnSpawn = false
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 520, 0, 420); mainFrame.Position = UDim2.new(0.5, -260, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12); mainFrame.BorderSizePixel = 0
Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(0, 255, 0)

-- TOGGLE
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then mainFrame.Visible = not mainFrame.Visible end
end)

-- SIDEBAR
local sidebar = Instance.new("Frame", mainFrame)
sidebar.Size = UDim2.new(0, 120, 1, 0); sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 10); sidebar.BorderSizePixel = 0
local container = Instance.new("Frame", mainFrame)
container.Size = UDim2.new(1, -140, 1, -20); container.Position = UDim2.new(0, 130, 0, 10); container.BackgroundTransparency = 1

local vFrame = Instance.new("Frame", container); vFrame.Size = UDim2.new(1,0,1,0); vFrame.BackgroundTransparency = 1; vFrame.Visible = true
local aFrame = Instance.new("Frame", container); aFrame.Size = UDim2.new(1,0,1,0); aFrame.BackgroundTransparency = 1; aFrame.Visible = false
Instance.new("UIListLayout", vFrame).Padding = UDim.new(0, 8)
Instance.new("UIListLayout", aFrame).Padding = UDim.new(0, 8)

local function makeTab(txt, y, target)
    local b = Instance.new("TextButton", sidebar); b.Size = UDim2.new(1, 0, 0, 40); b.Position = UDim2.new(0, 0, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(10, 10, 10); b.Text = txt; b.TextColor3 = Color3.fromRGB(150, 150, 150); b.Font = Enum.Font.Code; b.BorderSizePixel = 0; b.TextSize = 15
    b.MouseButton1Click:Connect(function() 
        vFrame.Visible = false; aFrame.Visible = false; target.Visible = true 
        for _,v in pairs(sidebar:GetChildren()) do if v:IsA("TextButton") then v.TextColor3 = Color3.fromRGB(150, 150, 150) end end
        b.TextColor3 = Color3.fromRGB(0, 255, 0)
    end)
end
makeTab("Visuals", 10, vFrame); makeTab("Aimbot", 55, aFrame)

-- --- HELPER ---
local function createToggle(txt, parent, cb)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 25); f.BackgroundTransparency = 1
    local b = Instance.new("TextButton", f); b.Size = UDim2.new(0, 16, 0, 16); b.Position = UDim2.new(0, 0, 0.5, -8); b.BackgroundColor3 = Color3.fromRGB(30, 30, 30); b.Text = ""; b.BorderSizePixel = 0
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(1, -25, 1, 0); t.Position = UDim2.new(0, 25, 0, 0); t.Text = txt; t.TextColor3 = Color3.fromRGB(200, 200, 200); t.Font = Enum.Font.Code; t.TextSize = 14; t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left
    local on = false
    b.MouseButton1Click:Connect(function() on = not on; b.BackgroundColor3 = on and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(30, 30, 30); cb(on) end)
end

local function createSlider(txt, min, max, start, parent, cb)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 45); f.BackgroundTransparency = 1
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(1, 0, 0, 20); t.Text = txt .. ": " .. start; t.TextColor3 = Color3.fromRGB(200, 200, 200); t.Font = Enum.Font.Code; t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left
    local b = Instance.new("Frame", f); b.Size = UDim2.new(0.9, 0, 0, 4); b.Position = UDim2.new(0, 0, 0, 28); b.BackgroundColor3 = Color3.fromRGB(30, 30, 30); b.BorderSizePixel = 0
    local fi = Instance.new("Frame", b); fi.Size = UDim2.new((start-min)/(max-min), 0, 1, 0); fi.BackgroundColor3 = Color3.fromRGB(0, 255, 0); fi.BorderSizePixel = 0
    local dragging = false
    local function update()
        local rel = math.clamp((UserInputService:GetMouseLocation().X - b.AbsolutePosition.X) / b.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel)
        fi.Size = UDim2.new(rel, 0, 1, 0); t.Text = txt .. ": " .. val; cb(val)
    end
    b.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update() end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    RunService.RenderStepped:Connect(function() if dragging then update() end end)
end

-- --- VISUALS TAB ---
createToggle("Box ESP", vFrame, function(v) espSettings.Box = v end)
createToggle("Skeleton ESP", vFrame, function(v) espSettings.Skeleton = v end)

local function colorBtn(txt, parent, prop)
    local b = Instance.new("TextButton", parent); b.Size = UDim2.new(0.9, 0, 0, 30); b.BackgroundColor3 = Color3.fromRGB(25, 25, 25); b.Text = "Color: " .. txt; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.Code; b.BorderSizePixel = 0
    Instance.new("UIStroke", b).Color = Color3.fromRGB(50, 50, 50)
    b.MouseButton1Click:Connect(function()
        espSettings[prop] = Color3.fromHSV(math.random(), 1, 1)
        b.TextColor3 = espSettings[prop]
    end)
end
colorBtn("Box", vFrame, "BoxColor")
colorBtn("Skeleton", vFrame, "SkeletonColor")

-- --- AIMBOT TAB ---
createToggle("Aimbot Master", aFrame, function(v) aimbotEnabled = v end)
createToggle("Wall Check (Visible Only)", aFrame, function(v) wallCheck = v end)
createSlider("Smoothness", 1, 100, 15, aFrame, function(v) smoothPercent = v end)
createSlider("FOV Radius", 10, 500, 110, aFrame, function(v) fovRadius = v end)
colorBtn("FOV Circle", aFrame, "FOVColor")

local bindBtn = Instance.new("TextButton", aFrame); bindBtn.Size = UDim2.new(0.9, 0, 0, 35); bindBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); bindBtn.Text = "Bind: MB2"; bindBtn.TextColor3 = Color3.fromRGB(0, 255, 0); bindBtn.Font = Enum.Font.Code; bindBtn.BorderSizePixel = 0
Instance.new("UIStroke", bindBtn).Color = Color3.fromRGB(0, 255, 0)
bindBtn.MouseButton1Click:Connect(function() isBinding = true; bindBtn.Text = "Press any key..." end)

-- --- WALLCHECK LOGIC ---
local function isVisible(part, char)
    if not wallCheck then return true end
    local castPoints = {camera.CFrame.Position, part.Position}
    local ignoreList = {player.Character, char}
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList
    
    local ray = workspace:Raycast(camera.CFrame.Position, part.Position - camera.CFrame.Position, params)
    return ray == nil
end

-- --- ENGINE ---
local fovCircle = Drawing.new("Circle"); fovCircle.Thickness = 1; fovCircle.Visible = true
local drawings = {}

local function getChar(p)
    return p.Character or workspace:FindFirstChild(p.Name) or (workspace:FindFirstChild("Live") and workspace.Live:FindFirstChild(p.Name))
end

RunService.RenderStepped:Connect(function()
    fovCircle.Radius = fovRadius
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Color = espSettings.FOVColor
    
    for _, p in pairs(Players:GetPlayers()) do
        if p == player then continue end
        if not drawings[p] then 
            drawings[p] = {Box = Drawing.new("Square"), Skel = {H2T=Drawing.new("Line"), T2LA=Drawing.new("Line"), T2RA=Drawing.new("Line"), T2LL=Drawing.new("Line"), T2RL=Drawing.new("Line")}}
        end
        local d = drawings[p]; local char = getChar(p)
        
        if char and char:FindFirstChild("Head") then
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char.Head
            local pos, on = camera:WorldToViewportPoint(root.Position)
            local visible = isVisible(char.Head, char)

            if on and (not wallCheck or visible) then
                local h = math.abs(camera:WorldToViewportPoint(char.Head.Position + Vector3.new(0, 0.5, 0)).Y - camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0)).Y)
                local w = h * 0.6
                d.Box.Visible = espSettings.Box; d.Box.Size = Vector2.new(w, h); d.Box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2); d.Box.Color = espSettings.BoxColor
                
                for _, l in pairs(d.Skel) do l.Visible = espSettings.Skeleton; l.Color = espSettings.SkeletonColor end
                if espSettings.Skeleton then
                    local head = camera:WorldToViewportPoint(char.Head.Position)
                    d.Skel.H2T.From = Vector2.new(head.X, head.Y); d.Skel.H2T.To = Vector2.new(pos.X, pos.Y)
                    -- Simplified Skeleton for Performance
                end
            else d.Box.Visible = false; for _,l in pairs(d.Skel) do l.Visible = false end end
        else d.Box.Visible = false; for _,l in pairs(d.Skel) do l.Visible = false end end
    end

    if aimbotEnabled and (UserInputService:IsMouseButtonPressed(aimKey) or UserInputService:IsKeyDown(aimKey)) then
        local target = nil; local dist = fovRadius
        for _, p in pairs(Players:GetPlayers()) do
            local c = getChar(p)
            if p ~= player and c and c:FindFirstChild(aimPart) and isVisible(c[aimPart], c) then
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

-- BIND LOGIC
UserInputService.InputBegan:Connect(function(i)
    if isBinding then
        if i.UserInputType == Enum.UserInputType.Keyboard then
            aimKey = i.KeyCode; bindBtn.Text = "Bind: " .. i.KeyCode.Name
        elseif i.UserInputType.Name:find("MouseButton") then
            aimKey = i.UserInputType; bindBtn.Text = "Bind: " .. (i.UserInputType == Enum.UserInputType.MouseButton1 and "MB1" or "MB2")
        end
        isBinding = false
    end
end)

-- DRAG
local d, s, sp; mainFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d=true s=i.Position sp=mainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position-s mainFrame.Position=UDim2.new(sp.X.Scale, sp.X.Offset+delta.X, sp.Y.Scale, sp.Y.Offset+delta.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d=false end end)
