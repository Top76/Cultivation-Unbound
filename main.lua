local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== ระบบแสดง Error / Rules GUI ====================
local function showDebugErrorGui(titleText, errMsg, extraActionText, extraActionCallback)
    pcall(function()
        local old = PlayerGui:FindFirstChild("MurimDebugErrorGui")
        if old then
            old:Destroy()
        end

        local sg = Instance.new("ScreenGui")
        sg.Name = "MurimDebugErrorGui"
        sg.DisplayOrder = 999999
        sg.ResetOnSpawn = false
        sg.Parent = PlayerGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 420, 0, 320)
        frame.Position = UDim2.new(0.5, -210, 0.22, 0)
        frame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        frame.BorderSizePixel = 0
        frame.Parent = sg
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

        local topBar = Instance.new("Frame")
        topBar.Size = UDim2.new(1, 0, 0, 35)
        topBar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        topBar.BorderSizePixel = 0
        topBar.Parent = frame
        Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -40, 1, 0)
        title.Position = UDim2.new(0, 12, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = tostring(titleText)
        title.TextColor3 = Color3.fromRGB(255, 215, 110)
        title.Font = Enum.Font.SourceSansBold
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = topBar

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 26, 0, 26)
        closeBtn.Position = UDim2.new(1, -31, 0, 4)
        closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        closeBtn.Text = "X"
        closeBtn.TextColor3 = Color3.new(1, 1, 1)
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.TextSize = 13
        closeBtn.Parent = topBar
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
        closeBtn.MouseButton1Click:Connect(function()
            sg:Destroy()
        end)

        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(1, -20, 1, -95)
        textBox.Position = UDim2.new(0, 10, 0, 43)
        textBox.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
        textBox.TextColor3 = Color3.fromRGB(225, 245, 230)
        textBox.Text = tostring(errMsg)
        textBox.TextWrapped = true
        textBox.MultiLine = true
        textBox.ClearTextOnFocus = false
        textBox.TextXAlignment = Enum.TextXAlignment.Left
        textBox.TextYAlignment = Enum.TextYAlignment.Top
        textBox.Font = Enum.Font.Code
        textBox.TextSize = 11
        textBox.Parent = frame
        Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)

        local hasExtra = (type(extraActionText) == "string" and type(extraActionCallback) == "function")
        local btnWidth = hasExtra and 0.31 or 0.47

        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.new(btnWidth, 0, 0, 32)
        copyBtn.Position = UDim2.new(0, 10, 1, -42)
        copyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 180)
        copyBtn.Text = "📋 Copy All"
        copyBtn.TextColor3 = Color3.new(1, 1, 1)
        copyBtn.Font = Enum.Font.SourceSansBold
        copyBtn.TextSize = 12
        copyBtn.Parent = frame
        Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

        copyBtn.MouseButton1Click:Connect(function()
            if type(setclipboard) == "function" then
                setclipboard(textBox.Text)
                copyBtn.Text = "✅ Copied!"
                task.wait(1.5)
                copyBtn.Text = "📋 Copy All"
            else
                copyBtn.Text = "❌ Not Supported"
            end
        end)

        if hasExtra then
            local extraBtn = Instance.new("TextButton")
            extraBtn.Size = UDim2.new(btnWidth, 0, 0, 32)
            extraBtn.Position = UDim2.new(0.345, 0, 1, -42)
            extraBtn.BackgroundColor3 = Color3.fromRGB(45, 145, 95)
            extraBtn.Text = extraActionText
            extraBtn.TextColor3 = Color3.new(1, 1, 1)
            extraBtn.Font = Enum.Font.SourceSansBold
            extraBtn.TextSize = 12
            extraBtn.Parent = frame
            Instance.new("UICorner", extraBtn).CornerRadius = UDim.new(0, 6)

            extraBtn.MouseButton1Click:Connect(function()
                extraActionCallback(extraBtn, textBox)
            end)
        end

        local bottomCloseBtn = Instance.new("TextButton")
        bottomCloseBtn.Size = UDim2.new(btnWidth, 0, 0, 32)
        bottomCloseBtn.Position = UDim2.new(hasExtra and 0.67 or 0.505, 0, 1, -42)
        bottomCloseBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
        bottomCloseBtn.Text = "❌ ปิด"
        bottomCloseBtn.TextColor3 = Color3.new(1, 1, 1)
        bottomCloseBtn.Font = Enum.Font.SourceSansBold
        bottomCloseBtn.TextSize = 12
        bottomCloseBtn.Parent = frame
        Instance.new("UICorner", bottomCloseBtn).CornerRadius = UDim.new(0, 6)

        bottomCloseBtn.MouseButton1Click:Connect(function()
            sg:Destroy()
        end)
    end)
end

-- ==================== โครงสร้างหลักแบบแยก Scope ====================
local Hub = {
    Env = {
        connections = {},
        workers = {},
        destroyed = false,
        Remotes = {},
        ActiveMapEvent = nil,
        availableMobNames = {},
        selectedMobsMap = {},
        mobUIElements = {},
        myHerbCounts = {},
        lastHerbCollectedAt = 0,
        lastStreamedTarget = nil,
        mobInfoCache = {},
        mobInfoCacheAt = -999999,
        orbParts = nil,
        cachedHerbPrompts = {},
        herbCacheInitialized = false,
        collectedCooldowns = {},
        zoneIndex = 1,
        patrolAngle = 0,
        lastErrorText = "ไม่มี Error",
        cachedWorldBossArenaPos = nil,
        lastRulesSnapshot = nil
    },
    UI = {},
    Config = {},
    State = {},
    Fn = {}
}

-- 1. ระบบพื้นฐาน Remotes, Helpers & Game Rules Inspector
do
    local Env = Hub.Env
    local UI = Hub.UI

    function Hub.Fn.logDebug(msg)
        local line = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(msg)
        if UI.DebugBox then
            UI.DebugBox.Text = line .. "\n" .. string.sub(UI.DebugBox.Text, 1, 600)
        end
    end

    function Hub.Fn.connect(signal, callback)
        if not signal then
            return nil
        end
        local connection = signal:Connect(function(...)
            local ok, err = xpcall(callback, debug.traceback, ...)
            if not ok and not Env.destroyed then
                Env.lastErrorText = tostring(err)
                Hub.Fn.logDebug("ERR(Event): " .. tostring(err))
            end
        end)
        Env.connections[connection] = true
        return connection
    end

    function Hub.Fn.stopWorker(name)
        local thread = Env.workers[name]
        Env.workers[name] = nil
        if thread and coroutine.status(thread) ~= "dead" and thread ~= coroutine.running() then
            pcall(task.cancel, thread)
        end
    end

    function Hub.Fn.setWorker(name, enabled, callback)
        Hub.Fn.stopWorker(name)
        if not enabled or Env.destroyed then
            return nil
        end
        local thread = task.spawn(function()
            local ok, err = xpcall(callback, debug.traceback)
            if not ok and not Env.destroyed then
                Env.lastErrorText = tostring(err)
                Hub.Fn.logDebug("ERR(" .. name .. "): " .. tostring(err))
                showDebugErrorGui("⚠️ Worker Error: " .. name, err)
            end
        end)
        Env.workers[name] = thread
        return thread
    end

    function Hub.Fn.inspectGameRules()
        local rawLines = {}
        local function addRaw(str)
            table.insert(rawLines, tostring(str))
        end

        local function dumpTable(tbl, prefix, depth)
            if depth > 2 then
                return
            end
            local keys = {}
            for k in pairs(tbl) do
                table.insert(keys, k)
            end
            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b)
            end)
            for _, k in ipairs(keys) do
                local v = tbl[k]
                local fullKey = prefix .. "." .. tostring(k)
                if type(v) == "table" then
                    dumpTable(v, fullKey, depth + 1)
                elseif type(v) ~= "function" and type(v) ~= "userdata" then
                    addRaw(fullKey .. " = " .. tostring(v))
                end
            end
        end

        addRaw("=== 1. REPLICATED STORAGE RULES & CONFIG MODULES ===")
        local modules = {}
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("ModuleScript") then
                local lower = obj.Name:lower()
                if lower:find("rule") or lower:find("config") or lower:find("boss") or lower:find("guard") or lower:find("const") or lower:find("stat") or lower:find("data") or lower:find("pill") or lower:find("herb") then
                    table.insert(modules, obj)
                end
            end
        end
        table.sort(modules, function(a, b)
            return a:GetFullName() < b:GetFullName()
        end)

        for _, modObj in ipairs(modules) do
            local ok, res = pcall(require, modObj)
            if ok and type(res) == "table" then
                dumpTable(res, modObj.Name, 1)
            end
        end

        addRaw("\n=== 2. CULTIVATION REMOTES ===")
        local cultEvents = ReplicatedStorage:FindFirstChild("CultivationEvents")
        if cultEvents then
            local rList = {}
            for _, child in ipairs(cultEvents:GetChildren()) do
                table.insert(rList, "Remote: " .. child.Name .. " [" .. child.ClassName .. "]")
            end
            table.sort(rList)
            for _, line in ipairs(rList) do
                addRaw(line)
            end
        end

        local currentText = table.concat(rawLines, "\n")
        return currentText, currentText, "murim_rules_snapshot.txt"
    end

    local CultivationEvents = ReplicatedStorage:FindFirstChild("CultivationEvents")
    if CultivationEvents then
        local remoteNames = {
            "CollectHerb",
            "HerbInventoryUpdate",
            "RequestHerbInventory",
            "Breakthrough",
            "BreakthroughMinigameResult",
            "StartBreakthroughMinigame",
            "BodyBreakthrough",
            "BodyBreakthroughCutsceneDone",
            "StartPushup",
            "Tribulation",
            "StartMeditate",
            "ZoneChanged",
            "SoulProjection",
            "SpiritWorld",
            "CultivateResumed",
            "ClaimReward",
            "UseSkill",
            "CombatHit",
            "CauldronStartBrew",
            "CauldronClaim",
            "CauldronStoke",
            "CauldronStateUpdate",
            "CultivationOrbClicked",
            "MapEvent",
            "WorldBoss"
        }
        for _, rName in ipairs(remoteNames) do
            Env.Remotes[rName] = CultivationEvents:FindFirstChild(rName)
        end
    end

    Hub.Fn.connect(LocalPlayer.Idled, function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)

    Hub.Config = {
        herbModes = {
            "1. Normal Body Only (ร่างปกติ - 1000Yr + All)",
            "2. Spirit Soul Only (ร่างวิญญาณ - ส่งจิตเก็บเฉพาะโลกวิญญาณ)",
            "3. Hybrid: Normal + Spirit Soul (สลับ 2 ร่างอัตโนมัติ)",
            "4. Normal Rare Only (ร่างปกติ - เฉพาะ 1000 ปี & สมุนไพรปรุงยา)"
        },
        recipeList = {
            {
                name = "⚡ Auto Any (ปรุงมั่ว - สมุนไพรชนิดเดียวกัน 3 ชิ้น)",
                ingredients = nil
            },
            {
                name = "❤️ Vitality Pill (Ginseng, Moss, Sage)",
                ingredients = {
                    { id = 1, count = 1 },
                    { id = 3, count = 1 },
                    { id = 5, count = 1 }
                }
            },
            {
                name = "⚡ Qi Cultivation (Ginseng x2, Lotus x1)",
                ingredients = {
                    { id = 1, count = 2 },
                    { id = 2, count = 1 }
                }
            },
            {
                name = "💪 Body Cultivation (Moss x2, Fern x1)",
                ingredients = {
                    { id = 3, count = 2 },
                    { id = 4, count = 1 }
                }
            },
            {
                name = "🔥 Bloodfury Pill (Lotus, Fern, Sage)",
                ingredients = {
                    { id = 2, count = 1 },
                    { id = 4, count = 1 },
                    { id = 5, count = 1 }
                }
            }
        },
        yearOptions = { 0, 10, 100, 1000 },
        farmOffsets = {
            { text = "ใต้ดิน ลึกมาก (-12 Studs)", offset = Vector3.new(0, -12, 0) },
            { text = "ใต้ดิน ลึก (-8 Studs)", offset = Vector3.new(0, -8, 0) },
            { text = "ใต้ดิน ปานกลาง (-5 Studs)", offset = Vector3.new(0, -5, 0) },
            { text = "ใต้ดิน ตื้น (-3 Studs)", offset = Vector3.new(0, -3, 0) },
            { text = "บนหัว ต่ำ (+4 Studs)", offset = Vector3.new(0, 4, 0) },
            { text = "บนหัว ปานกลาง (+6 Studs)", offset = Vector3.new(0, 6, 0) },
            { text = "บนหัว สูง (+10 Studs)", offset = Vector3.new(0, 10, 0) },
            { text = "ด้านหลัง ใกล้ (-3 Studs)", offset = Vector3.new(0, 0, 3) },
            { text = "ด้านหลัง ไกล (-5 Studs)", offset = Vector3.new(0, 0, 5) },
            { text = "ตรงกลางตัวมอน (0 Studs)", offset = Vector3.new(0, 0, 0) }
        },
        -- เพิ่มพิกัดครอบคลุมโซนใหม่ (เกาะลอยฟ้า, ภูเขาไฟ, แดนหิมะ, ทะเลทราย, รังบอส)
        fallbackZones = {
            Vector3.new(0, 120, 0),
            Vector3.new(-350, 140, 2200),
            Vector3.new(900, 130, 2100),
            Vector3.new(-2800, 150, -2100),
            Vector3.new(2500, 1500, 1000),
            Vector3.new(-1800, 180, 1600),
            Vector3.new(1900, 160, -1700),
            Vector3.new(0, 1400, -1200)
        }
    }

    Hub.State = {
        isFarmingMob = false,
        isAoEHit = true,
        isTurboAttack = true,
        isAutoSkills = false,
        isAutoMapEvent = false,
        isAutoWorldBoss = false,
        isFarming = false,
        isDynamicStream = true,
        herbModeIndex = 1,
        isAutoBrew = false,
        isAutoCultivate = false,
        isAutoBreakthrough = false,
        isAutoBodyBreakthrough = false,
        isAutoPushup = false,
        isAutoTribulation = false,
        isAutoOrb = false,
        isAutoSoul = false,
        recipeIndex = 1,
        yearIndex = 1,
        selectedMinYear = 0,
        farmOffsetIndex = 3,
        currentOffset = Vector3.new(0, -5, 0),
        cauldronStatus = "idle"
    }

    local groundPlatform = Instance.new("Part")
    groundPlatform.Size = Vector3.new(8, 1, 8)
    groundPlatform.Anchored = true
    groundPlatform.Transparency = 1
    groundPlatform.CanCollide = true
    groundPlatform.Name = "TempUndergroundGround"
    groundPlatform.Parent = workspace
    Env.groundPlatform = groundPlatform

    function Hub.Fn.getCharacter()
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                return char, hrp, hum
            end
        end
        return nil, nil, nil
    end

    function Hub.Fn.getBodyPosition()
        local soulBodies = workspace:FindFirstChild("SoulBodies")
        if soulBodies then
            local myBody = soulBodies:FindFirstChild(LocalPlayer.Name) or soulBodies:FindFirstChild(tostring(LocalPlayer.UserId))
            if myBody then
                if myBody:IsA("Model") then
                    local pp = myBody.PrimaryPart or myBody:FindFirstChildWhichIsA("BasePart")
                    if pp then
                        return pp.Position
                    end
                elseif myBody:IsA("BasePart") then
                    return myBody.Position
                end
            end
        end
        return nil
    end

    function Hub.Fn.safeTeleport(hrp, targetCFrame, targetHrp)
        if not hrp or not targetCFrame then
            return false
        end
        local targetPos = targetCFrame.Position
        if targetPos.Magnitude < 5 then
            return false
        end

        if targetHrp and Env.lastStreamedTarget ~= targetHrp then
            Env.lastStreamedTarget = targetHrp
            if (hrp.Position - targetPos).Magnitude > 300 then
                pcall(function()
                    workspace:RequestStreamAroundAsync(targetPos)
                end)
            end
        end

        local startPos = hrp.Position
        local flatDist = Vector2.new(targetPos.X - startPos.X, targetPos.Z - startPos.Z).Magnitude

        local function applyCFrame(cframe)
            groundPlatform.CFrame = cframe * CFrame.new(0, -1, 0)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            if targetHrp and targetHrp.Parent then
                local safeLookTarget = targetHrp.Position + Vector3.new(0.01, 0, 0.01)
                pcall(function()
                    hrp.CFrame = CFrame.new(cframe.Position, safeLookTarget)
                end)
            else
                pcall(function()
                    hrp.CFrame = cframe
                end)
            end
        end

        if flatDist <= 38 then
            applyCFrame(targetCFrame)
            return true
        end

        local stepDist = 36
        local steps = math.ceil(flatDist / stepDist)
        local rotOnly = targetCFrame - targetCFrame.Position

        for i = 1, steps do
            if not hrp or not hrp.Parent then
                return false
            end
            local nextPos = startPos:Lerp(targetPos, i / steps)
            applyCFrame(CFrame.new(nextPos) * rotOnly)
            task.wait(0.10)
        end
        return true
    end
end

-- 2. ระบบ Events Listeners, Dynamic Streamer, Sect Clash และ World Boss
do
    local Env = Hub.Env
    local State = Hub.State
    local Config = Hub.Config
    local UI = Hub.UI

    if Env.Remotes.HerbInventoryUpdate then
        Hub.Fn.connect(Env.Remotes.HerbInventoryUpdate.OnClientEvent, function(data, pickedInfo)
            if type(data) == "table" then
                Env.myHerbCounts = data
            end
            if pickedInfo then
                Env.lastHerbCollectedAt = os.clock()
            end
        end)
    end

    if Env.Remotes.CauldronStateUpdate then
        Hub.Fn.connect(Env.Remotes.CauldronStateUpdate.OnClientEvent, function(data)
            if type(data) == "table" then
                if data.herbCounts then
                    Env.myHerbCounts = data.herbCounts
                end
                if data.status then
                    State.cauldronStatus = data.status
                end
            end
        end)
    end

    if Env.Remotes.StartBreakthroughMinigame then
        Hub.Fn.connect(Env.Remotes.StartBreakthroughMinigame.OnClientEvent, function()
            if State.isAutoBreakthrough and Env.Remotes.BreakthroughMinigameResult then
                task.wait(0.2)
                Env.Remotes.BreakthroughMinigameResult:FireServer(true)
            end
        end)
    end

    if Env.Remotes.MapEvent then
        Hub.Fn.connect(Env.Remotes.MapEvent.OnClientEvent, function(action, payload)
            if action == "start" and type(payload) == "table" and typeof(payload.centre) == "Vector3" then
                Env.ActiveMapEvent = {
                    name = tostring(payload.name or "Sect Clash"),
                    centre = payload.centre,
                    endsAt = tonumber(payload.endsAt) or (workspace:GetServerTimeNow() + 300),
                    teams = payload.teams or {},
                    order = payload.order or { "Alliance", "Cult" },
                    side = type(payload.side) == "string" and payload.side or nil
                }
                Hub.Fn.logDebug("พบอีเวนต์: " .. Env.ActiveMapEvent.name)
            elseif action == "side" and type(payload) == "string" and Env.ActiveMapEvent then
                Env.ActiveMapEvent.side = payload
                Hub.Fn.logDebug("เข้าร่วมฝ่าย: " .. payload)
            elseif action == "end" or action == "cancel" then
                Env.ActiveMapEvent = nil
                Hub.Fn.logDebug("อีเวนต์จบลงแล้ว")
            end
        end)
    end

    function Hub.Fn.getWorldBossFolder()
        return workspace:FindFirstChild("WorldBoss")
    end

    function Hub.Fn.getWorldBossState()
        local wbFolder = Hub.Fn.getWorldBossFolder()
        if not wbFolder then
            return "idle", 0
        end
        local state = tostring(wbFolder:GetAttribute("State") or "idle")
        local spawnAt = tonumber(wbFolder:GetAttribute("SpawnAt")) or 0
        return state, spawnAt
    end

    function Hub.Fn.isWorldBossActive()
        if not State.isAutoWorldBoss then
            return false
        end
        local state = Hub.Fn.getWorldBossState()
        return (state == "warning" or state == "rising" or state == "fight")
    end

    function Hub.Fn.findWorldBossModel()
        local wbFolder = Hub.Fn.getWorldBossFolder()
        if not wbFolder then
            return nil, nil, nil
        end
        for _, child in ipairs(wbFolder:GetChildren()) do
            if child:IsA("Model") and (child:GetAttribute("IsWorldBoss") == true or child:FindFirstChildOfClass("Humanoid")) then
                local hum = child:FindFirstChildOfClass("Humanoid")
                local hrp = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
                if hum and hum.Health > 0 and hrp then
                    return child, hrp, hum
                end
            end
        end
        return nil, nil, nil
    end

    function Hub.Fn.getWorldBossArenaPos()
        if Env.cachedWorldBossArenaPos then
            return Env.cachedWorldBossArenaPos
        end
        local mapFolder = workspace:FindFirstChild("Map_sacred-mountain")
        if mapFolder then
            local landmarks = mapFolder:FindFirstChild("Landmarks")
            local ashPlain = landmarks and landmarks:FindFirstChild("World Boss Ash Plain")
            if ashPlain then
                local sumPos, count = Vector3.new(0, 0, 0), 0
                for _, desc in ipairs(ashPlain:GetDescendants()) do
                    if desc:IsA("BasePart") then
                        sumPos = sumPos + desc.Position
                        count = count + 1
                    end
                end
                if count > 0 then
                    Env.cachedWorldBossArenaPos = sumPos / count
                    return Env.cachedWorldBossArenaPos
                end
            end
        end
        return Vector3.new(900, 130, 2100)
    end

    function Hub.Fn.getWorldBossStandCFrame(bossModel, bossHrp)
        local _, playerHrp = Hub.Fn.getCharacter()
        local refPos = playerHrp and playerHrp.Position or bossHrp.Position
        local closestSurface, bestDist = nil, math.huge

        for _, part in ipairs(bossModel:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 1 then
                local localPt = part.CFrame:PointToObjectSpace(refPos)
                local half = part.Size * 0.5
                local clamped = Vector3.new(
                    math.clamp(localPt.X, -half.X, half.X),
                    math.clamp(localPt.Y, -half.Y, half.Y),
                    math.clamp(localPt.Z, -half.Z, half.Z)
                )
                local worldPt = part.CFrame:PointToWorldSpace(clamped)
                local d = (worldPt - refPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    closestSurface = worldPt
                end
            end
        end

        if closestSurface then
            local dir = (refPos - closestSurface)
            local flatDir = Vector3.new(dir.X, 0, dir.Z)
            flatDir = (flatDir.Magnitude < 0.1) and Vector3.new(0, 0, 1) or flatDir.Unit
            return CFrame.new(closestSurface + flatDir * 4 + Vector3.new(0, 1, 0))
        end
        return bossHrp.CFrame * CFrame.new(0, 0, 8)
    end

    function Hub.Fn.startWorldBossLoop()
        local nextToolAction = 0
        local wasFightingBoss = false

        while State.isAutoWorldBoss do
            local wbState, spawnAt = Hub.Fn.getWorldBossState()
            local nowSec = os.time()

            if UI.WorldBossStatusLabel then
                if wbState == "fight" or wbState == "rising" then
                    local _, _, bossHum = Hub.Fn.findWorldBossModel()
                    if bossHum then
                        local pct = bossHum.MaxHealth > 0 and math.floor((bossHum.Health / bossHum.MaxHealth) * 100) or 0
                        UI.WorldBossStatusLabel.Text = "🐉 World Boss: FIGHT! (" .. pct .. "%)"
                        UI.WorldBossStatusLabel.TextColor3 = Color3.fromRGB(255, 95, 95)
                    else
                        UI.WorldBossStatusLabel.Text = "🐉 World Boss: " .. wbState:upper() .. " (กำลังเดินทาง)"
                        UI.WorldBossStatusLabel.TextColor3 = Color3.fromRGB(255, 190, 80)
                    end
                elseif wbState == "warning" then
                    local left = math.max(0, spawnAt - nowSec)
                    UI.WorldBossStatusLabel.Text = "🐉 World Boss: เกิดใน " .. left .. " วิ"
                    UI.WorldBossStatusLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
                else
                    UI.WorldBossStatusLabel.Text = "🐉 World Boss: Standby (" .. wbState .. ")"
                    UI.WorldBossStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
                end
            end

            if wbState == "warning" or wbState == "rising" or wbState == "fight" then
                wasFightingBoss = true
                local char, hrp, hum = Hub.Fn.getCharacter()
                if char and hrp and hum and hum.Health > 0 then
                    local bossModel, bossHrp, bossHum = Hub.Fn.findWorldBossModel()
                    if not bossModel or not bossHrp then
                        local arenaPos = Hub.Fn.getWorldBossArenaPos()
                        pcall(function()
                            workspace:RequestStreamAroundAsync(arenaPos)
                        end)
                        if (hrp.Position - arenaPos).Magnitude > 60 then
                            Hub.Fn.safeTeleport(hrp, CFrame.new(arenaPos + Vector3.new(0, 5, 0)))
                        end
                        task.wait(0.25)
                    else
                        local standCFrame = Hub.Fn.getWorldBossStandCFrame(bossModel, bossHrp)
                        Hub.Fn.safeTeleport(hrp, standCFrame, bossHrp)

                        if wbState == "fight" and bossHum and bossHum.Health > 0 then
                            if Env.Remotes.CombatHit then
                                Env.Remotes.CombatHit:FireServer(bossModel, 1)
                                if State.isTurboAttack then
                                    Env.Remotes.CombatHit:FireServer(bossModel, 1)
                                end
                            end

                            local now = os.clock()
                            if now >= nextToolAction then
                                nextToolAction = now + (State.isTurboAttack and 0.10 or 0.20)
                                local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                                local tool = char:FindFirstChildOfClass("Tool") or (backpack and backpack:FindFirstChildOfClass("Tool"))
                                if tool and tool.Parent ~= char then
                                    hum:EquipTool(tool)
                                end
                                if tool then
                                    tool:Activate()
                                end
                                pcall(function()
                                    VirtualUser:CaptureController()
                                    VirtualUser:ClickButton1(Vector2.new(0, 0))
                                end)
                            end
                        end
                        task.wait(State.isTurboAttack and 0.06 or 0.12)
                    end
                else
                    task.wait(0.3)
                end
            else
                if wasFightingBoss then
                    wasFightingBoss = false
                    Hub.Fn.logDebug("🐉 จบรอบ World Boss!")
                end
                task.wait(0.8)
            end
        end

        if UI.WorldBossStatusLabel then
            UI.WorldBossStatusLabel.Text = "🐉 World Boss: OFF"
            UI.WorldBossStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
        end
    end

    function Hub.Fn.getDynamicStreamPoints()
        local points = {}
        local seen = {}

        local function addPoint(pos)
            if typeof(pos) ~= "Vector3" then
                return
            end
            local key = math.floor(pos.X / 150) .. "_" .. math.floor(pos.Z / 150)
            if not seen[key] then
                seen[key] = true
                table.insert(points, pos)
            end
        end

        local anchors = workspace:FindFirstChild("MapAnchors")
        if anchors then
            for _, child in ipairs(anchors:GetDescendants()) do
                if child:IsA("BasePart") then
                    addPoint(child.Position)
                end
            end
        end

        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Folder") and obj.Name:find("^Map_") then
                for _, sub in ipairs(obj:GetChildren()) do
                    if sub:IsA("Folder") then
                        for _, sp in ipairs(sub:GetDescendants()) do
                            if sp:IsA("BasePart") then
                                addPoint(sp.Position)
                            end
                        end
                    end
                end
            end
        end

        for _, pos in ipairs(Config.fallbackZones) do
            addPoint(pos)
        end

        return points
    end

    function Hub.Fn.startDynamicStreamLoop()
        local streamIdx = 1
        while State.isDynamicStream do
            local points = Hub.Fn.getDynamicStreamPoints()
            if #points > 0 then
                if streamIdx > #points then
                    streamIdx = 1
                end
                local targetPos = points[streamIdx]
                streamIdx = streamIdx + 1
                pcall(function()
                    workspace:RequestStreamAroundAsync(targetPos)
                end)
            end
            task.wait(0.8)
        end
    end

    local function getEventEnemyTarget(centrePos, enemyFighterName)
        local bestTarget, bestDist = nil, 999999
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local hrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                if hum and hum.Health > 0 and hrp then
                    local distFromCentre = (hrp.Position - centrePos).Magnitude
                    if distFromCentre <= 150 then
                        local isEnemy = (enemyFighterName and obj.Name == enemyFighterName)
                        if isEnemy and distFromCentre < bestDist then
                            bestDist = distFromCentre
                            bestTarget = { model = obj, hrp = hrp, hum = hum }
                        end
                    end
                end
            end
        end
        return bestTarget
    end

    function Hub.Fn.startMapEventLoop()
        while State.isAutoMapEvent do
            if Hub.Fn.isWorldBossActive() then
                task.wait(0.5)
            else
                if Env.ActiveMapEvent and workspace:GetServerTimeNow() > (Env.ActiveMapEvent.endsAt + 10) then
                    Env.ActiveMapEvent = nil
                end

                if Env.ActiveMapEvent then
                    local char, hrp, hum = Hub.Fn.getCharacter()
                    if char and hrp and hum and hum.Health > 0 then
                        local distToCentre = (hrp.Position - Env.ActiveMapEvent.centre).Magnitude
                        local joinRange = 145

                        if not Env.ActiveMapEvent.side or distToCentre > joinRange then
                            if UI.EventStatusLabel then
                                UI.EventStatusLabel.Text = "🚩 กำลังเข้าร่วม: " .. Env.ActiveMapEvent.name
                                UI.EventStatusLabel.TextColor3 = Color3.fromRGB(255, 210, 90)
                            end
                            Hub.Fn.safeTeleport(hrp, CFrame.new(Env.ActiveMapEvent.centre + Vector3.new(0, 3, 0)))
                            task.wait(0.3)
                        else
                            local teamInfo = Env.ActiveMapEvent.teams[Env.ActiveMapEvent.side]
                            local enemySide = (Env.ActiveMapEvent.side == Env.ActiveMapEvent.order[1]) and Env.ActiveMapEvent.order[2] or Env.ActiveMapEvent.order[1]
                            local enemyTeamInfo = Env.ActiveMapEvent.teams[enemySide]
                            local enemyFighterName = enemyTeamInfo and enemyTeamInfo.fighter or nil

                            if UI.EventStatusLabel then
                                UI.EventStatusLabel.Text = "⚔️ ฝ่าย: " .. (teamInfo and teamInfo.name or Env.ActiveMapEvent.side)
                                UI.EventStatusLabel.TextColor3 = Color3.fromRGB(100, 230, 140)
                            end

                            local enemy = getEventEnemyTarget(Env.ActiveMapEvent.centre, enemyFighterName)
                            if enemy then
                                Hub.Fn.safeTeleport(hrp, enemy.hrp.CFrame * CFrame.new(State.currentOffset), enemy.hrp)
                                if Env.Remotes.CombatHit then
                                    Env.Remotes.CombatHit:FireServer(enemy.model, 1)
                                    if State.isTurboAttack then
                                        Env.Remotes.CombatHit:FireServer(enemy.model, 1)
                                    end
                                end
                            else
                                Hub.Fn.safeTeleport(hrp, CFrame.new(Env.ActiveMapEvent.centre + Vector3.new(0, 5, 0)))
                            end
                        end
                    end
                    task.wait(0.12)
                else
                    if UI.EventStatusLabel then
                        UI.EventStatusLabel.Text = "🚩 Event: Waiting"
                        UI.EventStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
                    end
                    task.wait(1.0)
                end
            end
        end
        if UI.EventStatusLabel then
            UI.EventStatusLabel.Text = "🚩 Event: OFF"
            UI.EventStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
        end
    end
end

-- 3. ระบบสแกนและฟาร์มมอนสเตอร์
do
    local Env = Hub.Env
    local State = Hub.State
    local UI = Hub.UI

    local function getTargetContainers()
        local result = {}
        for _, name in ipairs({ "BanditCamp", "CultivatorCamps", "BlockingDummy", "TrainingDummy" }) do
            local container = workspace:FindFirstChild(name)
            if container then
                result[#result + 1] = container
            end
        end
        return result
    end

    local function checkAndAddMob(model, list, nameSet)
        if model:IsA("Model") and model ~= LocalPlayer.Character then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Head")
            if hum and hum.Health > 0 and hrp then
                if nameSet then
                    if not nameSet[model.Name] then
                        nameSet[model.Name] = true
                        table.insert(list, model.Name)
                    end
                else
                    if Env.selectedMobsMap[model.Name] == true then
                        table.insert(list, { model = model, hrp = hrp, hum = hum })
                    end
                end
            end
        end
    end

    local function scanAvailableMobNames()
        local foundNames, nameSet = {}, {}
        for _, container in ipairs(getTargetContainers()) do
            checkAndAddMob(container, foundNames, nameSet)
            for _, child in ipairs(container:GetChildren()) do
                checkAndAddMob(child, foundNames, nameSet)
            end
        end
        Env.availableMobNames = foundNames
        for _, name in ipairs(Env.availableMobNames) do
            if Env.selectedMobsMap[name] == nil then
                Env.selectedMobsMap[name] = true
            end
        end
    end

    local function getTargetMonsters()
        local mobs = {}
        for _, container in ipairs(getTargetContainers()) do
            checkAndAddMob(container, mobs, nil)
            for _, child in ipairs(container:GetChildren()) do
                checkAndAddMob(child, mobs, nil)
            end
        end
        return mobs
    end

    local function getMobDataByName(mobName)
        local now = os.clock()
        if now - Env.mobInfoCacheAt >= 0.2 then
            local nextCache = {}
            local _, playerRoot = Hub.Fn.getCharacter()
            for _, container in ipairs(getTargetContainers()) do
                local list = container:IsA("Model") and { container } or container:GetDescendants()
                for _, obj in ipairs(list) do
                    if obj:IsA("Model") and obj ~= LocalPlayer.Character then
                        local hum = obj:FindFirstChildOfClass("Humanoid")
                        local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChild("Head")
                        if hum and hum.Health > 0 and root and root:IsA("BasePart") then
                            local info = nextCache[obj.Name]
                            if not info then
                                info = { hp = 0, max = 0, distance = 999999 }
                                nextCache[obj.Name] = info
                            end
                            info.hp, info.max = math.floor(hum.Health), math.floor(hum.MaxHealth)
                            if playerRoot then
                                local distance = (playerRoot.Position - root.Position).Magnitude
                                if distance < info.distance then
                                    info.distance, info.root = distance, root
                                end
                            end
                        end
                    end
                end
            end
            Env.mobInfoCache, Env.mobInfoCacheAt = nextCache, now
        end
        local info = Env.mobInfoCache[mobName]
        if info then
            return info.hp, info.max, info.root, true
        end
        return 0, 0, nil, false
    end

    function Hub.Fn.rebuildMobListUI()
        if not UI.MobListContainer then
            return
        end
        for _, child in ipairs(UI.MobListContainer:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
                child:Destroy()
            end
        end
        Env.mobUIElements = {}
        scanAvailableMobNames()

        if #Env.availableMobNames == 0 then
            local noMobLabel = Instance.new("TextLabel")
            noMobLabel.Size = UDim2.new(1, 0, 0, 24)
            noMobLabel.BackgroundTransparency = 1
            noMobLabel.Text = "⚠️ ไม่พบมอนสเตอร์ในบริเวณใกล้เคียง"
            noMobLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            noMobLabel.Font = Enum.Font.SourceSansItalic
            noMobLabel.TextSize = 11
            noMobLabel.Parent = UI.MobListContainer
            return
        end

        local allBtn = Instance.new("TextButton")
        allBtn.Size = UDim2.new(1, 0, 0, 24)
        allBtn.BackgroundColor3 = Color3.fromRGB(50, 110, 80)
        allBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        allBtn.Text = "🎯 [เลือกทุกตัว / Toggle All]"
        allBtn.Font = Enum.Font.SourceSansBold
        allBtn.TextSize = 11
        allBtn.Parent = UI.MobListContainer
        Instance.new("UICorner", allBtn).CornerRadius = UDim.new(0, 4)

        allBtn.MouseButton1Click:Connect(function()
            local allSelected = true
            for _, name in ipairs(Env.availableMobNames) do
                if not Env.selectedMobsMap[name] then
                    allSelected = false
                    break
                end
            end
            local allState = not allSelected
            for _, name in ipairs(Env.availableMobNames) do
                Env.selectedMobsMap[name] = allState
            end
            Hub.Fn.rebuildMobListUI()
        end)

        for _, mobName in ipairs(Env.availableMobNames) do
            local rowFrame = Instance.new("Frame")
            rowFrame.Size = UDim2.new(1, 0, 0, 24)
            rowFrame.BackgroundTransparency = 1
            rowFrame.Parent = UI.MobListContainer

            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(1, -52, 1, 0)
            local isOn = Env.selectedMobsMap[mobName] == true
            toggleBtn.BackgroundColor3 = isOn and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(65, 65, 75)
            toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            local curHP, maxHP, _, found = getMobDataByName(mobName)
            toggleBtn.Text = (isOn and "✅ " or "❌ ") .. mobName .. (found and (" [" .. curHP .. "/" .. maxHP .. "]") or " [N/A]")
            toggleBtn.Font = Enum.Font.SourceSansBold
            toggleBtn.TextSize = 11
            toggleBtn.TextXAlignment = Enum.TextXAlignment.Left
            toggleBtn.Parent = rowFrame
            Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0, 48, 1, 0)
            tpBtn.Position = UDim2.new(1, -48, 0, 0)
            tpBtn.BackgroundColor3 = Color3.fromRGB(60, 110, 170)
            tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tpBtn.Text = "🚀 TP"
            tpBtn.Font = Enum.Font.SourceSansBold
            tpBtn.TextSize = 11
            tpBtn.Parent = rowFrame
            Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)

            toggleBtn.MouseButton1Click:Connect(function()
                Env.selectedMobsMap[mobName] = not Env.selectedMobsMap[mobName]
                local newState = Env.selectedMobsMap[mobName]
                toggleBtn.BackgroundColor3 = newState and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(65, 65, 75)
                local cHP, mHP, _, f = getMobDataByName(mobName)
                toggleBtn.Text = (newState and "✅ " or "❌ ") .. mobName .. (f and (" [" .. cHP .. "/" .. mHP .. "]") or " [N/A]")
            end)

            tpBtn.MouseButton1Click:Connect(function()
                local _, _, targetHrp, foundTarget = getMobDataByName(mobName)
                local _, hrp = Hub.Fn.getCharacter()
                if foundTarget and targetHrp and hrp then
                    Hub.Fn.safeTeleport(hrp, targetHrp.CFrame * CFrame.new(State.currentOffset), targetHrp)
                end
            end)

            Env.mobUIElements[mobName] = toggleBtn
        end
    end

    Hub.Fn.setWorker("hpUpdate", true, function()
        while task.wait(0.5) do
            for mobName, toggleBtn in pairs(Env.mobUIElements) do
                if toggleBtn and toggleBtn.Parent then
                    local isOn = Env.selectedMobsMap[mobName] == true
                    local curHP, maxHP, _, found = getMobDataByName(mobName)
                    local text = (isOn and "✅ " or "❌ ") .. mobName .. (found and (" [" .. curHP .. "/" .. maxHP .. "]") or " [N/A]")
                    if toggleBtn.Text ~= text then
                        toggleBtn.Text = text
                    end
                end
            end
        end
    end)

    local function isValidFarmTarget(target)
        return target and target.model and target.model.Parent
            and Env.selectedMobsMap[target.model.Name] == true
            and target.hum and target.hum.Parent and target.hum.Health > 0
            and target.hrp and target.hrp.Parent
    end

    function Hub.Fn.startMobFarmLoop()
        local nextTargetUI, nextToolAction = 0, 0
        local clusterMobs, clusterCursor, nextClusterRefresh = {}, 1, 0
        local expandedParts = {}

        local function resetHitboxes()
            for part, origSize in pairs(expandedParts) do
                if part and part.Parent then
                    pcall(function()
                        part.Size = origSize
                        part.Transparency = 1
                    end)
                end
            end
            expandedParts = {}
        end

        local function getGroupAround(centerPos, allMobs)
            local group = {}
            for _, m in ipairs(allMobs) do
                if isValidFarmTarget(m) and (m.hrp.Position - centerPos).Magnitude <= 38 then
                    table.insert(group, m)
                    if State.isAoEHit then
                        if not expandedParts[m.hrp] then
                            expandedParts[m.hrp] = m.hrp.Size
                        end
                        pcall(function()
                            m.hrp.Size = Vector3.new(25, 25, 25)
                            m.hrp.CanCollide = false
                        end)
                    end
                end
            end
            return group
        end

        while State.isFarmingMob do
            if Hub.Fn.isWorldBossActive() then
                resetHitboxes()
                if UI.TargetHPLabel then
                    UI.TargetHPLabel.Text = "🎯 พักฟาร์มชั่วคราว -> สลับไปตี World Boss!"
                    UI.TargetHPLabel.TextColor3 = Color3.fromRGB(255, 130, 100)
                end
                task.wait(0.5)
            elseif State.isAutoMapEvent and Env.ActiveMapEvent then
                resetHitboxes()
                task.wait(0.5)
            else
                local _, playerRoot, playerHumanoid = Hub.Fn.getCharacter()
                if not playerRoot or not playerHumanoid or playerHumanoid.Health <= 0 then
                    if UI.TargetHPLabel then
                        UI.TargetHPLabel.Text = "🎯 รอตัวละครเกิดใหม่..."
                        UI.TargetHPLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
                    end
                    task.wait(0.3)
                else
                    local allMobs = getTargetMonsters()
                    if #allMobs > 0 then
                        table.sort(allMobs, function(a, b)
                            return (a.hrp.Position - playerRoot.Position).Magnitude < (b.hrp.Position - playerRoot.Position).Magnitude
                        end)
                        local anchorMob = allMobs[1]

                        while State.isFarmingMob and isValidFarmTarget(anchorMob) and not Hub.Fn.isWorldBossActive() and not (State.isAutoMapEvent and Env.ActiveMapEvent) do
                            local char, hrp, humanoid = Hub.Fn.getCharacter()
                            if not char or not humanoid or humanoid.Health <= 0 then
                                break
                            end

                            local now = os.clock()
                            if now >= nextClusterRefresh then
                                clusterMobs = getGroupAround(anchorMob.hrp.Position, getTargetMonsters())
                                nextClusterRefresh = now + 0.4
                            end

                            local activeTarget = anchorMob
                            if State.isAoEHit and #clusterMobs > 1 then
                                if clusterCursor > #clusterMobs then
                                    clusterCursor = 1
                                end
                                activeTarget = clusterMobs[clusterCursor]
                                clusterCursor = clusterCursor + 1
                                if not isValidFarmTarget(activeTarget) then
                                    activeTarget = anchorMob
                                end
                            elseif not State.isAoEHit then
                                resetHitboxes()
                            end

                            if UI.TargetHPLabel and now >= nextTargetUI then
                                nextTargetUI = now + 0.1
                                local curHP = math.floor(activeTarget.hum.Health)
                                local maxHP = math.floor(activeTarget.hum.MaxHealth)
                                local countText = State.isAoEHit and (" [กลุ่ม " .. #clusterMobs .. " ตัว]") or ""
                                UI.TargetHPLabel.Text = "🎯 " .. activeTarget.model.Name .. ": " .. curHP .. "/" .. maxHP .. countText
                                UI.TargetHPLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
                            end

                            Hub.Fn.safeTeleport(hrp, activeTarget.hrp.CFrame * CFrame.new(State.currentOffset), activeTarget.hrp)
                            if not State.isFarmingMob or not isValidFarmTarget(activeTarget) or Hub.Fn.isWorldBossActive() then
                                break
                            end

                            if Env.Remotes.CombatHit then
                                Env.Remotes.CombatHit:FireServer(activeTarget.model, 1)
                                if State.isTurboAttack then
                                    Env.Remotes.CombatHit:FireServer(activeTarget.model, 1)
                                end
                                if State.isAoEHit then
                                    for _, otherMob in ipairs(clusterMobs) do
                                        if otherMob.model ~= activeTarget.model and isValidFarmTarget(otherMob) then
                                            Env.Remotes.CombatHit:FireServer(otherMob.model, 1)
                                        end
                                    end
                                end
                            end

                            now = os.clock()
                            if now >= nextToolAction then
                                nextToolAction = now + (State.isTurboAttack and 0.10 or 0.20)
                                local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                                local tool = char:FindFirstChildOfClass("Tool") or (backpack and backpack:FindFirstChildOfClass("Tool"))
                                if tool and tool.Parent ~= char then
                                    humanoid:EquipTool(tool)
                                end
                                if tool then
                                    tool:Activate()
                                end
                                pcall(function()
                                    VirtualUser:CaptureController()
                                    VirtualUser:ClickButton1(Vector2.new(0, 0))
                                end)
                            end

                            task.wait(State.isTurboAttack and 0.06 or 0.12)
                        end
                    else
                        resetHitboxes()
                        if UI.TargetHPLabel then
                            UI.TargetHPLabel.Text = "🎯 Target: N/A"
                            UI.TargetHPLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
                        end
                        if not State.isFarming and not Hub.Fn.isWorldBossActive() and not (State.isAutoMapEvent and Env.ActiveMapEvent) then
                            Env.groundPlatform.CFrame = CFrame.new(0, 9999, 0)
                        end
                        task.wait(0.5)
                    end
                end
            end
        end

        resetHitboxes()
        if UI.TargetHPLabel then
            UI.TargetHPLabel.Text = "🎯 Target: Standby"
            UI.TargetHPLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
        end
        if not State.isFarming and not Hub.Fn.isWorldBossActive() and not (State.isAutoMapEvent and Env.ActiveMapEvent) then
            Env.groundPlatform.CFrame = CFrame.new(0, 9999, 0)
        end
    end
end

-- 4. ระบบ Cultivation, Soul (ร่างวิญญาณ), Herbs (ร่างปกติ) และ Alchemy
do
    local Env = Hub.Env
    local State = Hub.State
    local Config = Hub.Config

    function Hub.Fn.startSkillsLoop()
        local skillKeys = { "Z", "X", "C", "V" }
        while State.isAutoSkills do
            local char, hrp, humanoid = Hub.Fn.getCharacter()
            if char and humanoid.Health > 0 and hrp and Env.Remotes.UseSkill then
                local lookDir = hrp.CFrame.LookVector
                local targetPos = hrp.Position + (lookDir * 15)
                for _, key in ipairs(skillKeys) do
                    if not State.isAutoSkills then
                        break
                    end
                    Env.Remotes.UseSkill:FireServer(key, lookDir, targetPos)
                    task.wait(0.15)
                end
            end
            task.wait(0.5)
        end
    end

    function Hub.Fn.startCultivateLoop()
        while State.isAutoCultivate do
            local char, _, humanoid = Hub.Fn.getCharacter()
            if char and humanoid and humanoid.Health > (humanoid.MaxHealth * 0.3) then
                if Env.Remotes.StartMeditate then
                    Env.Remotes.StartMeditate:FireServer()
                end
                if Env.Remotes.CultivateResumed then
                    Env.Remotes.CultivateResumed:FireServer()
                end
                if State.isAutoBreakthrough then
                    if Env.Remotes.Breakthrough then
                        Env.Remotes.Breakthrough:FireServer()
                    end
                    if Env.Remotes.BreakthroughMinigameResult then
                        Env.Remotes.BreakthroughMinigameResult:FireServer(true)
                    end
                end
            end
            task.wait(2)
        end
    end

    function Hub.Fn.startBodyBreakthroughLoop()
        while State.isAutoBodyBreakthrough do
            local char, _, humanoid = Hub.Fn.getCharacter()
            if char and humanoid and humanoid.Health > (humanoid.MaxHealth * 0.3) then
                if Env.Remotes.BodyBreakthrough then
                    Env.Remotes.BodyBreakthrough:FireServer()
                end
                if Env.Remotes.BodyBreakthroughCutsceneDone then
                    Env.Remotes.BodyBreakthroughCutsceneDone:FireServer(true)
                end
            end
            task.wait(3)
        end
    end

    function Hub.Fn.startPushupLoop()
        while State.isAutoPushup do
            local char, _, humanoid = Hub.Fn.getCharacter()
            if char and humanoid and humanoid.Health > (humanoid.MaxHealth * 0.2) then
                if Env.Remotes.StartPushup then
                    Env.Remotes.StartPushup:FireServer()
                end
            end
            task.wait(1.5)
        end
    end

    function Hub.Fn.startTribulationLoop()
        while State.isAutoTribulation do
            local char, _, humanoid = Hub.Fn.getCharacter()
            if char and humanoid and humanoid.Health > (humanoid.MaxHealth * 0.3) then
                if Env.Remotes.Tribulation then
                    Env.Remotes.Tribulation:FireServer("absorb", 14, -0.014265060424804688)
                end
            end
            task.wait(1)
        end
    end

    -- ฟังก์ชันผู้ช่วยสำหรับเก็บสมุนไพรวิญญาณและจับวิญญาณ (ใช้ได้ทั้งปุ่ม Auto Soul และโหมดฟาร์มสมุนไพรวิญญาณ)
    function Hub.Fn.runSpiritSoulSession(autoMeditateToEnter)
        local char, hrp, humanoid = Hub.Fn.getCharacter()
        if not char or not hrp or not humanoid or humanoid.Health <= 0 then
            return false
        end

        local isProjecting = LocalPlayer:GetAttribute("SoulProjecting") == true
        local isForming = LocalPlayer:GetAttribute("SoulForming") == true

        if not isProjecting then
            if LocalPlayer:GetAttribute("SoulProjectionLearned") ~= true then
                return false
            end
            local cooldown = (tonumber(LocalPlayer:GetAttribute("SoulCooldownUntil")) or 0) - workspace:GetServerTimeNow()
            if cooldown > 0 then
                return false
            end

            local isMeditating = char:FindFirstChild("IsMeditating")
            local isPushingUp = char:FindFirstChild("IsPushingUp")
            local cultivating = (isMeditating and isMeditating.Value) or (isPushingUp and isPushingUp.Value)

            -- ถ้าตั้งใจจะเข้าโหมดวิญญาณแต่ยังไม่นั่งสมาธิ ให้กดนั่งสมาธิให้อัตโนมัติ
            if not cultivating and autoMeditateToEnter and Env.Remotes.StartMeditate then
                Env.Remotes.StartMeditate:FireServer()
                task.wait(0.4)
                cultivating = true
            end

            if cultivating and Env.Remotes.SoulProjection then
                Hub.Fn.logDebug("👻 กำลังส่งจิตออกจากร่าง...")
                Env.Remotes.SoulProjection:FireServer("start")
                task.wait(2.1)
                return true
            end
            return false
        end

        if isForming then
            return true
        end

        local caughtSpirits = {}
        local pickedSpiritHerbs = {}
        local sessionStartTime = os.clock()
        local maxTether = 465

        while LocalPlayer:GetAttribute("SoulProjecting") == true and (State.isAutoSoul or (State.isFarming and (State.herbModeIndex == 2 or State.herbModeIndex == 3))) do
            char, hrp = Hub.Fn.getCharacter()
            if not char or not hrp then
                break
            end

            local bodyPos = Hub.Fn.getBodyPosition() or hrp.Position
            local spiritWorldFolder = workspace:FindFirstChild("SpiritWorld")
            local foundTarget = false

            if spiritWorldFolder then
                -- 1. เก็บสมุนไพรวิญญาณใน SpiritWorld.Herbs (รองรับทั้ง BasePart และ Model)
                local herbsFolder = spiritWorldFolder:FindFirstChild("Herbs")
                if herbsFolder then
                    for _, herb in ipairs(herbsFolder:GetChildren()) do
                        if LocalPlayer:GetAttribute("SoulProjecting") ~= true then
                            break
                        end
                        if not pickedSpiritHerbs[herb] and herb:GetAttribute("Picked") ~= true then
                            local targetPart = herb:IsA("BasePart") and herb or (herb:IsA("Model") and (herb.PrimaryPart or herb:FindFirstChildWhichIsA("BasePart", true)))
                            local prompt = herb:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if targetPart and (not prompt or prompt.Enabled) and (targetPart.Position - bodyPos).Magnitude <= maxTether then
                                foundTarget = true
                                Hub.Fn.logDebug("👻🌿 พบสมุนไพรวิญญาณ: " .. herb.Name)
                                hrp.CFrame = targetPart.CFrame * CFrame.new(0, 1.5, 0)
                                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

                                if firetouchinterest then
                                    pcall(function()
                                        firetouchinterest(hrp, targetPart, 0)
                                        firetouchinterest(hrp, targetPart, 1)
                                    end)
                                end
                                task.wait(0.08)
                                if prompt and fireproximityprompt then
                                    pcall(fireproximityprompt, prompt)
                                end
                                if Env.Remotes.CollectHerb then
                                    Env.Remotes.CollectHerb:FireServer(herb)
                                    if targetPart ~= herb then
                                        Env.Remotes.CollectHerb:FireServer(targetPart)
                                    end
                                end
                                pickedSpiritHerbs[herb] = true
                                task.wait(0.12)
                            end
                        end
                    end
                end

                -- 2. จับดวงวิญญาณใน SpiritWorld.Spirits
                local spiritsFolder = spiritWorldFolder:FindFirstChild("Spirits")
                if spiritsFolder and Env.Remotes.SpiritWorld then
                    for _, spirit in ipairs(spiritsFolder:GetChildren()) do
                        if LocalPlayer:GetAttribute("SoulProjecting") ~= true then
                            break
                        end
                        if spirit:IsA("BasePart") and spirit.Parent and not caughtSpirits[spirit] and (spirit.Position - bodyPos).Magnitude <= maxTether then
                            foundTarget = true
                            hrp.CFrame = spirit.CFrame
                            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            if firetouchinterest then
                                pcall(function()
                                    firetouchinterest(hrp, spirit, 0)
                                    firetouchinterest(hrp, spirit, 1)
                                end)
                            end
                            task.wait(0.08)
                            if spirit.Parent then
                                hrp.CFrame = spirit.CFrame
                                Env.Remotes.SpiritWorld:FireServer("catch", spirit)
                            end
                            caughtSpirits[spirit] = true
                            task.wait(0.1)
                        end
                    end
                end
            end

            -- ถ้าเก็บในระยะหมดแล้วให้ลอยเหนือร่างรอหรือเตรียมกลับร่าง
            if not foundTarget and bodyPos then
                hrp.CFrame = CFrame.new(bodyPos + Vector3.new(0, 15, 0))
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                if (os.clock() - sessionStartTime) >= 4 then
                    break
                end
            end

            if (os.clock() - sessionStartTime) >= 18 then
                break
            end
            task.wait(0.25)
        end

        -- กลับเข้าร่างเมื่อเก็บเสร็จหรือครบเวลา
        if LocalPlayer:GetAttribute("SoulProjecting") == true and Env.Remotes.SoulProjection then
            local _, curHrp = Hub.Fn.getCharacter()
            local bodyPos = Hub.Fn.getBodyPosition()
            if curHrp and bodyPos then
                curHrp.CFrame = CFrame.new(bodyPos + Vector3.new(0, 1.5, 0))
                curHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                task.wait(0.15)
            end
            Env.Remotes.SoulProjection:FireServer("return")
            Hub.Fn.logDebug("👻 กลับเข้าร่างปกติเรียบร้อย")
            task.wait(1.5)
        end
        return true
    end

    function Hub.Fn.startSoulLoop()
        while State.isAutoSoul do
            Hub.Fn.runSpiritSoulSession(false)
            task.wait(0.4)
        end
    end

    function Hub.Fn.startOrbLoop()
        if not Env.orbParts then
            Env.orbParts = {}
            Hub.Fn.connect(workspace.DescendantAdded, function(obj)
                if obj:IsA("BasePart") then
                    Env.orbParts[obj] = true
                end
            end)
            Hub.Fn.connect(workspace.DescendantRemoving, function(obj)
                Env.orbParts[obj] = nil
            end)
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    Env.orbParts[obj] = true
                end
            end
        end
        while State.isAutoOrb do
            pcall(function()
                if Env.Remotes.CultivationOrbClicked then
                    Env.Remotes.CultivationOrbClicked:FireServer()
                end
                local _, hrp = Hub.Fn.getCharacter()
                if hrp and firetouchinterest then
                    for obj in pairs(Env.orbParts) do
                        if obj.Parent and obj.Name:lower():find("orb", 1, true) and (hrp.Position - obj.Position).Magnitude < 40 then
                            firetouchinterest(hrp, obj, 0)
                            firetouchinterest(hrp, obj, 1)
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
    end

    local function initHerbCache()
        if Env.herbCacheInitialized then
            return
        end
        Env.herbCacheInitialized = true
        local function registerObj(obj)
            if obj:IsA("ProximityPrompt") and (obj.Name == "CollectHerbPrompt" or obj.Name:lower():find("herb")) then
                Env.cachedHerbPrompts[obj] = true
            end
        end
        Hub.Fn.connect(workspace.DescendantAdded, registerObj)
        Hub.Fn.connect(workspace.DescendantRemoving, function(obj)
            Env.cachedHerbPrompts[obj] = nil
        end)
        for _, obj in ipairs(workspace:GetDescendants()) do
            registerObj(obj)
        end
    end

    -- ค้นหาสมุนไพรร่างปกติ (รองรับ BasePart/MeshPart/Model และสมุนไพรปรุงยา ID 16-21)
    local function getBestHerbTarget(fromPos)
        initHerbCache()
        local spiritWorld = workspace:FindFirstChild("SpiritWorld")
        local herbSpots = workspace:FindFirstChild("HerbSpots")
        local now = os.clock()
        local onlyRareNormal = (State.herbModeIndex == 4)
        local candidates, seenParts = {}, {}

        local function evaluateSpot(obj, prompt)
            if not obj or not obj.Parent then
                return
            end
            if spiritWorld and obj:IsDescendantOf(spiritWorld) then
                return
            end
            local part = obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)))
            if not part or seenParts[part] then
                return
            end
            if not prompt then
                prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            end
            if prompt and not prompt.Enabled then
                return
            end
            if part.Transparency >= 0.95 then
                return
            end
            seenParts[part] = true

            local herbYear = obj:GetAttribute("HerbYear") or part:GetAttribute("HerbYear") or obj:GetAttribute("Year") or 1
            if type(herbYear) ~= "number" then
                herbYear = 1
            end
            local herbType = obj:GetAttribute("HerbType") or part:GetAttribute("HerbType") or 1
            local isAlchemyHerb = (type(herbType) == "number" and herbType >= 16)

            if onlyRareNormal and (herbYear < 1000 and not isAlchemyHerb) then
                return
            end

            local cdUntil = Env.collectedCooldowns[part]
            if cdUntil and now < cdUntil then
                return
            end

            local dist = (part.Position - fromPos).Magnitude
            table.insert(candidates, {
                part = part,
                targetObj = obj,
                prompt = prompt,
                dist = dist,
                year = herbYear,
                isAlchemy = isAlchemyHerb
            })
        end

        if herbSpots then
            for _, spot in ipairs(herbSpots:GetChildren()) do
                evaluateSpot(spot, nil)
            end
        end

        for prompt in pairs(Env.cachedHerbPrompts) do
            if prompt and prompt.Parent then
                if prompt.Enabled and prompt.Parent then
                    evaluateSpot(prompt.Parent, prompt)
                end
            else
                Env.cachedHerbPrompts[prompt] = nil
            end
        end

        if #candidates == 0 then
            return nil, nil, nil, 999999, 0
        end

        table.sort(candidates, function(a, b)
            local a1000, b1000 = a.year >= 1000, b.year >= 1000
            if a1000 ~= b1000 then
                return a1000
            end
            if a.isAlchemy ~= b.isAlchemy then
                return a.isAlchemy
            end
            local a100, b100 = a.year >= 100, b.year >= 100
            if a100 ~= b100 then
                return a100
            end
            return a.dist < b.dist
        end)

        local best = candidates[1]
        return best.part, best.targetObj, best.prompt, best.dist, best.year
    end

    function Hub.Fn.startFarmLoop()
        initHerbCache()
        Hub.Fn.logDebug("เริ่มลูปเก็บสมุนไพร (" .. Config.herbModes[State.herbModeIndex] .. ")")

        while State.isFarming do
            if Hub.Fn.isWorldBossActive() or (State.isAutoMapEvent and Env.ActiveMapEvent) then
                task.wait(0.5)
            else
                local mode = State.herbModeIndex

                -- โหมด 2: ร่างวิญญาณเท่านั้น (Spirit Soul Only)
                if mode == 2 then
                    local didSoul = Hub.Fn.runSpiritSoulSession(true)
                    if not didSoul then
                        Hub.Fn.logDebug("👻 รอคูลดาวน์ส่งจิต / ตรวจสอบสกิล SoulProjection...")
                        task.wait(1.5)
                    end
                    task.wait(0.2)

                -- โหมด 3: สลับ 2 ร่างอัตโนมัติ (เช็กคูลดาวน์ส่งจิตก่อน ถ้าพร้อมให้ไปเก็บโลกวิญญาณก่อน แล้วค่อยกลับมาฟาร์มร่างปกติ)
                elseif mode == 3 and LocalPlayer:GetAttribute("SoulProjectionLearned") == true then
                    local cooldown = (tonumber(LocalPlayer:GetAttribute("SoulCooldownUntil")) or 0) - workspace:GetServerTimeNow()
                    if cooldown <= 0 or LocalPlayer:GetAttribute("SoulProjecting") == true then
                        Hub.Fn.runSpiritSoulSession(true)
                    end
                end

                -- ส่วนเก็บสมุนไพรในร่างปกติ (ทำงานในโหมด 1, 3, 4)
                if mode ~= 2 and State.isFarming then
                    -- ถ้ายังอยู่ในร่างวิญญาณ (กรณีผู้ใช้เปิด Auto Soul ค้างไว้) ให้รอจนกว่าจะกลับร่างปกติ
                    if LocalPlayer:GetAttribute("SoulProjecting") == true then
                        task.wait(0.5)
                    else
                        local char, hrp, humanoid = Hub.Fn.getCharacter()
                        if char and hrp and humanoid and humanoid.Health > 0 then
                            local herbPart, targetObj, prompt, _, herbYear = getBestHerbTarget(hrp.Position)

                            if herbPart and herbPart.Parent then
                                Hub.Fn.logDebug("🌿 พบสมุนไพร: " .. herbPart.Name .. " (" .. tostring(herbYear) .. "Yr)")
                                local standCFrame = herbPart.CFrame * CFrame.new(0, 1.5, 1.8)
                                Hub.Fn.safeTeleport(hrp, standCFrame, herbPart)
                                Env.groundPlatform.CFrame = standCFrame * CFrame.new(0, -3.2, 0)

                                if not prompt then
                                    prompt = herbPart:FindFirstChildOfClass("ProximityPrompt")
                                end

                                if State.isFarming and herbPart.Parent and (not prompt or prompt.Enabled) then
                                    local beforeCollect = Env.lastHerbCollectedAt
                                    if prompt and fireproximityprompt then
                                        pcall(fireproximityprompt, prompt)
                                    end
                                    if Env.Remotes.CollectHerb then
                                        Env.Remotes.CollectHerb:FireServer(targetObj or herbPart)
                                    end

                                    local waitStart = os.clock()
                                    while State.isFarming and herbPart.Parent and (not prompt or prompt.Enabled) and Env.lastHerbCollectedAt == beforeCollect and (os.clock() - waitStart) < 0.35 do
                                        task.wait(0.03)
                                    end

                                    local collected = (not herbPart.Parent) or (prompt and not prompt.Enabled) or (Env.lastHerbCollectedAt > beforeCollect) or (herbPart.Transparency >= 0.9)
                                    if collected then
                                        Env.collectedCooldowns[herbPart] = os.clock() + 30
                                        Hub.Fn.logDebug("✅ เก็บสำเร็จ: " .. herbPart.Name)
                                    else
                                        -- ป้องกันยืนค้างถ้าติดเงื่อนไขเวลา (เช่น Moonshadow Orchid ตอนกลางวัน)
                                        Env.collectedCooldowns[herbPart] = os.clock() + 8
                                    end
                                end
                            else
                                local streamPoints = Hub.Fn.getDynamicStreamPoints()
                                if Env.zoneIndex > #streamPoints then
                                    Env.zoneIndex = 1
                                end
                                local center = streamPoints[Env.zoneIndex] or Vector3.new(0, 120, 0)
                                Env.patrolAngle = Env.patrolAngle + (math.pi / 3)
                                if Env.patrolAngle >= math.pi * 2 then
                                    Env.patrolAngle = 0
                                    Env.zoneIndex = (Env.zoneIndex % math.max(1, #streamPoints)) + 1
                                end

                                local nextPos = Vector3.new(center.X + math.cos(Env.patrolAngle) * 450, center.Y + 25, center.Z + math.sin(Env.patrolAngle) * 450)
                                pcall(function()
                                    workspace:RequestStreamAroundAsync(nextPos)
                                end)

                                local startPos = hrp.Position
                                local steps = math.max(1, math.ceil((nextPos - startPos).Magnitude / 36))

                                for i = 1, steps do
                                    if not State.isFarming or Hub.Fn.isWorldBossActive() or (State.isAutoMapEvent and Env.ActiveMapEvent) or State.herbModeIndex == 2 then
                                        break
                                    end
                                    if getBestHerbTarget(hrp.Position) then
                                        break
                                    end
                                    local stepCFrame = CFrame.new(startPos:Lerp(nextPos, i / steps))
                                    Env.groundPlatform.CFrame = stepCFrame * CFrame.new(0, -3.2, 0)
                                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                    hrp.CFrame = stepCFrame
                                    task.wait(0.10)
                                end
                            end
                        else
                            task.wait(0.3)
                        end
                    end
                end
                task.wait(0.05)
            end
        end

        Hub.Fn.logDebug("หยุดเก็บสมุนไพรแล้ว")
        if not State.isFarmingMob and not Hub.Fn.isWorldBossActive() and not (State.isAutoMapEvent and Env.ActiveMapEvent) then
            Env.groundPlatform.CFrame = CFrame.new(0, 9999, 0)
        end
    end

    function Hub.Fn.startBrewLoop()
        while State.isAutoBrew do
            if Env.Remotes.CauldronClaim then
                Env.Remotes.CauldronClaim:FireServer()
            end
            task.wait(0.3)
            if State.cauldronStatus == "brewing" then
                if Env.Remotes.CauldronStoke then
                    Env.Remotes.CauldronStoke:FireServer(0.4)
                end
                task.wait(0.8)
            else
                if Env.Remotes.CauldronStartBrew then
                    local currentRecipe = Config.recipeList[State.recipeIndex]
                    if not currentRecipe.ingredients then
                        for key, count in pairs(Env.myHerbCounts) do
                            if count and count >= 3 then
                                local rawType, yr = string.match(key, "^(.+)_(%d+)$")
                                if rawType and yr then
                                    local hType = tonumber(rawType) or rawType
                                    local yearNum = tonumber(yr) or 0
                                    if State.selectedMinYear == 0 or yearNum >= State.selectedMinYear then
                                        Env.Remotes.CauldronStartBrew:FireServer({
                                            { herbType = hType, year = yearNum },
                                            { herbType = hType, year = yearNum },
                                            { herbType = hType, year = yearNum }
                                        })
                                        break
                                    end
                                end
                            end
                        end
                    else
                        local herbsToBrew, canBrew = {}, true
                        for _, req in ipairs(currentRecipe.ingredients) do
                            local foundCount = 0
                            for key, count in pairs(Env.myHerbCounts) do
                                local rawType, yr = string.match(key, "^(.+)_(%d+)$")
                                if rawType and yr then
                                    local hType = tonumber(rawType) or rawType
                                    local yearNum = tonumber(yr) or 0
                                    if (hType == req.id or tostring(hType) == tostring(req.id)) and (State.selectedMinYear == 0 or yearNum >= State.selectedMinYear) then
                                        local take = math.min(count, req.count - foundCount)
                                        for _ = 1, take do
                                            table.insert(herbsToBrew, { herbType = hType, year = yearNum })
                                        end
                                        foundCount = foundCount + take
                                        if foundCount >= req.count then
                                            break
                                        end
                                    end
                                end
                            end
                            if foundCount < req.count then
                                canBrew = false
                                break
                            end
                        end
                        if canBrew and #herbsToBrew == 3 then
                            Env.Remotes.CauldronStartBrew:FireServer(herbsToBrew)
                        end
                    end
                end
                task.wait(1.5)
            end
        end
    end
end

-- 5. สร้าง GUI หลัก
do
    local Env = Hub.Env
    local State = Hub.State
    local Config = Hub.Config
    local UI = Hub.UI

    if PlayerGui:FindFirstChild("MurimHerbFarmGui") then
        PlayerGui.MurimHerbFarmGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MurimHerbFarmGui"
    ScreenGui.DisplayOrder = 999999
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    local OpenToggleBtn = Instance.new("TextButton")
    OpenToggleBtn.Size = UDim2.new(0, 95, 0, 35)
    OpenToggleBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
    OpenToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    OpenToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    OpenToggleBtn.Text = "⚡ Hub [Hide]"
    OpenToggleBtn.Font = Enum.Font.SourceSansBold
    OpenToggleBtn.TextSize = 14
    OpenToggleBtn.Parent = ScreenGui
    Instance.new("UICorner", OpenToggleBtn).CornerRadius = UDim.new(0, 8)

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 310, 0, 520)
    MainFrame.Position = UDim2.new(0.38, 0, 0.1, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -40, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Murim Hub V27 (Normal + Spirit Mode)"
    TitleLabel.TextColor3 = Color3.fromRGB(230, 230, 250)
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextSize = 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Position = UDim2.new(1, -30, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Text = "X"
    CloseBtn.Font = Enum.Font.SourceSansBold
    CloseBtn.TextSize = 14
    CloseBtn.Parent = TitleBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    UI.ScrollFrame = Instance.new("ScrollingFrame")
    UI.ScrollFrame.Size = UDim2.new(1, 0, 1, -35)
    UI.ScrollFrame.Position = UDim2.new(0, 0, 0, 35)
    UI.ScrollFrame.BackgroundTransparency = 1
    UI.ScrollFrame.BorderSizePixel = 0
    UI.ScrollFrame.ScrollBarThickness = 5
    UI.ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
    UI.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 1850)
    UI.ScrollFrame.Parent = MainFrame

    local scrollLayout = Instance.new("UIListLayout")
    scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scrollLayout.Padding = UDim.new(0, 6)
    scrollLayout.Parent = UI.ScrollFrame
    Hub.Fn.connect(scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        UI.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 30)
    end)

    local scrollPadding = Instance.new("UIPadding")
    scrollPadding.PaddingLeft = UDim.new(0, 10)
    scrollPadding.PaddingRight = UDim.new(0, 10)
    scrollPadding.PaddingTop = UDim.new(0, 8)
    scrollPadding.PaddingBottom = UDim.new(0, 15)
    scrollPadding.Parent = UI.ScrollFrame

    local dragging, dragInput, dragStart, startPos
    Hub.Fn.connect(TitleBar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    Hub.Fn.connect(TitleBar.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    Hub.Fn.connect(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    Hub.Fn.connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local isGuiVisible = true
    Hub.Fn.connect(OpenToggleBtn.MouseButton1Click, function()
        isGuiVisible = not isGuiVisible
        MainFrame.Visible = isGuiVisible
        OpenToggleBtn.Text = isGuiVisible and "⚡ Hub [Hide]" or "⚡ Hub [Open]"
    end)
    Hub.Fn.connect(CloseBtn.MouseButton1Click, function()
        isGuiVisible = false
        MainFrame.Visible = false
        OpenToggleBtn.Text = "⚡ Hub [Open]"
    end)

    local function createCategoryHeader(text, layoutOrder)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 180, 60)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.LayoutOrder = layoutOrder
        label.Parent = UI.ScrollFrame
        return label
    end

    local function createButton(text, bgCol, layoutOrder)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 26)
        btn.BackgroundColor3 = bgCol
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = text
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 11
        btn.LayoutOrder = layoutOrder
        btn.Parent = UI.ScrollFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        return btn
    end

    -- หมวด Debug & Log
    createCategoryHeader("🛠️ DEBUG & LOG", 0)
    UI.DebugBox = Instance.new("TextBox")
    UI.DebugBox.Size = UDim2.new(1, 0, 0, 60)
    UI.DebugBox.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    UI.DebugBox.TextColor3 = Color3.fromRGB(120, 255, 140)
    UI.DebugBox.Text = "[Ready] โหลดสคริปต์ V27 สำเร็จ!"
    UI.DebugBox.TextWrapped = true
    UI.DebugBox.MultiLine = true
    UI.DebugBox.ClearTextOnFocus = false
    UI.DebugBox.TextXAlignment = Enum.TextXAlignment.Left
    UI.DebugBox.TextYAlignment = Enum.TextYAlignment.Top
    UI.DebugBox.Font = Enum.Font.Code
    UI.DebugBox.TextSize = 10
    UI.DebugBox.LayoutOrder = 1
    UI.DebugBox.Parent = UI.ScrollFrame
    Instance.new("UICorner", UI.DebugBox).CornerRadius = UDim.new(0, 5)

    local CheckRulesBtn = createButton("🔍 Check Game Rules & Remotes", Color3.fromRGB(45, 125, 110), 2)
    Hub.Fn.connect(CheckRulesBtn.MouseButton1Click, function()
        local reportText = Hub.Fn.inspectGameRules()
        showDebugErrorGui("🔍 Game Rules & Remotes", reportText)
    end)

    -- หมวด Gathering & Mode (แยกโหมดร่างปกติ / ร่างวิญญาณ)
    createCategoryHeader("🌿 HERB GATHERING (NORMAL & SPIRIT MODE)", 3)
    local ToggleFarmBtn = createButton("🌿 Start Auto Herbs (เริ่มเก็บสมุนไพร)", Color3.fromRGB(40, 160, 80), 4)
    local ToggleHerbModeBtn = createButton("🌟 Mode: " .. Config.herbModes[State.herbModeIndex], Color3.fromRGB(180, 130, 30), 5)
    local ToggleStreamBtn = createButton("🗺️ Dynamic Map Streamer: ON", Color3.fromRGB(45, 135, 175), 6)

    Hub.Fn.connect(ToggleFarmBtn.MouseButton1Click, function()
        State.isFarming = not State.isFarming
        ToggleFarmBtn.Text = State.isFarming and "⏸ Stop Auto Herbs (หยุดเก็บสมุนไพร)" or "🌿 Start Auto Herbs (เริ่มเก็บสมุนไพร)"
        ToggleFarmBtn.BackgroundColor3 = State.isFarming and Color3.fromRGB(200, 120, 30) or Color3.fromRGB(40, 160, 80)
        Hub.Fn.setWorker("startFarmLoop", State.isFarming, Hub.Fn.startFarmLoop)
    end)
    Hub.Fn.connect(ToggleHerbModeBtn.MouseButton1Click, function()
        State.herbModeIndex = (State.herbModeIndex % #Config.herbModes) + 1
        ToggleHerbModeBtn.Text = "🌟 Mode: " .. Config.herbModes[State.herbModeIndex]
        if State.herbModeIndex == 2 then
            ToggleHerbModeBtn.BackgroundColor3 = Color3.fromRGB(75, 115, 195)
        elseif State.herbModeIndex == 3 then
            ToggleHerbModeBtn.BackgroundColor3 = Color3.fromRGB(135, 85, 185)
        else
            ToggleHerbModeBtn.BackgroundColor3 = Color3.fromRGB(180, 130, 30)
        end
    end)
    Hub.Fn.connect(ToggleStreamBtn.MouseButton1Click, function()
        State.isDynamicStream = not State.isDynamicStream
        ToggleStreamBtn.Text = State.isDynamicStream and "🗺️ Dynamic Map Streamer: ON" or "🗺️ Dynamic Map Streamer: OFF"
        ToggleStreamBtn.BackgroundColor3 = State.isDynamicStream and Color3.fromRGB(45, 135, 175) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startDynamicStreamLoop", State.isDynamicStream, Hub.Fn.startDynamicStreamLoop)
    end)

    -- หมวด Combat, World Boss & Sect Clash Event
    createCategoryHeader("⚔️ COMBAT, WORLD BOSS & EVENTS", 7)
    local RefreshMobListBtn = createButton("🔄 สแกนรายชื่อมอนสเตอร์ในแมพ", Color3.fromRGB(40, 90, 140), 8)

    UI.MobListContainer = Instance.new("Frame")
    UI.MobListContainer.Size = UDim2.new(1, 0, 0, 0)
    UI.MobListContainer.BackgroundTransparency = 1
    UI.MobListContainer.LayoutOrder = 9
    UI.MobListContainer.Parent = UI.ScrollFrame

    local mobListLayout = Instance.new("UIListLayout")
    mobListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mobListLayout.Padding = UDim.new(0, 4)
    mobListLayout.Parent = UI.MobListContainer
    Hub.Fn.connect(mobListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        UI.MobListContainer.Size = UDim2.new(1, 0, 0, mobListLayout.AbsoluteContentSize.Y)
    end)

    UI.TargetHPLabel = Instance.new("TextLabel")
    UI.TargetHPLabel.Size = UDim2.new(1, 0, 0, 22)
    UI.TargetHPLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    UI.TargetHPLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    UI.TargetHPLabel.Text = "🎯 Target: Standby"
    UI.TargetHPLabel.Font = Enum.Font.SourceSansBold
    UI.TargetHPLabel.TextSize = 11
    UI.TargetHPLabel.LayoutOrder = 10
    UI.TargetHPLabel.Parent = UI.ScrollFrame
    Instance.new("UICorner", UI.TargetHPLabel).CornerRadius = UDim.new(0, 5)

    local ToggleMobBtn = createButton("⚔️ Start Auto Farm Monsters", Color3.fromRGB(180, 50, 50), 11)
    local ToggleTurboBtn = createButton("⚡ Turbo Speed Attack: ON", Color3.fromRGB(220, 120, 20), 12)
    local ToggleAoEBtn = createButton("💥 Multi-Hit AoE: ON", Color3.fromRGB(160, 60, 160), 13)
    local ToggleSkillsBtn = createButton("🔥 Auto Spam Skills (Z,X,C,V)", Color3.fromRGB(200, 80, 30), 14)
    local ToggleOffsetBtn = createButton("📍 Offset: " .. Config.farmOffsets[State.farmOffsetIndex].text, Color3.fromRGB(80, 80, 120), 15)

    UI.WorldBossStatusLabel = Instance.new("TextLabel")
    UI.WorldBossStatusLabel.Size = UDim2.new(1, 0, 0, 22)
    UI.WorldBossStatusLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    UI.WorldBossStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    UI.WorldBossStatusLabel.Text = "🐉 World Boss: OFF"
    UI.WorldBossStatusLabel.Font = Enum.Font.SourceSansBold
    UI.WorldBossStatusLabel.TextSize = 11
    UI.WorldBossStatusLabel.LayoutOrder = 16
    UI.WorldBossStatusLabel.Parent = UI.ScrollFrame
    Instance.new("UICorner", UI.WorldBossStatusLabel).CornerRadius = UDim.new(0, 5)

    local ToggleWorldBossBtn = createButton("🐉 Auto World Boss: OFF", Color3.fromRGB(100, 100, 100), 17)

    UI.EventStatusLabel = Instance.new("TextLabel")
    UI.EventStatusLabel.Size = UDim2.new(1, 0, 0, 22)
    UI.EventStatusLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    UI.EventStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    UI.EventStatusLabel.Text = "🚩 Event: OFF"
    UI.EventStatusLabel.Font = Enum.Font.SourceSansBold
    UI.EventStatusLabel.TextSize = 11
    UI.EventStatusLabel.LayoutOrder = 18
    UI.EventStatusLabel.Parent = UI.ScrollFrame
    Instance.new("UICorner", UI.EventStatusLabel).CornerRadius = UDim.new(0, 5)

    local ToggleMapEventBtn = createButton("🚩 Auto Sect Clash Event: OFF", Color3.fromRGB(100, 100, 100), 19)

    Hub.Fn.connect(RefreshMobListBtn.MouseButton1Click, Hub.Fn.rebuildMobListUI)
    Hub.Fn.connect(ToggleTurboBtn.MouseButton1Click, function()
        State.isTurboAttack = not State.isTurboAttack
        ToggleTurboBtn.Text = State.isTurboAttack and "⚡ Turbo Speed Attack: ON" or "⚡ Turbo Speed Attack: OFF"
        ToggleTurboBtn.BackgroundColor3 = State.isTurboAttack and Color3.fromRGB(220, 120, 20) or Color3.fromRGB(100, 100, 100)
    end)
    Hub.Fn.connect(ToggleAoEBtn.MouseButton1Click, function()
        State.isAoEHit = not State.isAoEHit
        ToggleAoEBtn.Text = State.isAoEHit and "💥 Multi-Hit AoE: ON" or "💥 Multi-Hit AoE: OFF"
        ToggleAoEBtn.BackgroundColor3 = State.isAoEHit and Color3.fromRGB(160, 60, 160) or Color3.fromRGB(100, 100, 100)
    end)
    Hub.Fn.connect(ToggleMobBtn.MouseButton1Click, function()
        State.isFarmingMob = not State.isFarmingMob
        ToggleMobBtn.Text = State.isFarmingMob and "⏸ Stop Farm Monsters" or "⚔️ Start Auto Farm Monsters"
        ToggleMobBtn.BackgroundColor3 = State.isFarmingMob and Color3.fromRGB(200, 120, 30) or Color3.fromRGB(180, 50, 50)
        Hub.Fn.setWorker("startMobFarmLoop", State.isFarmingMob, Hub.Fn.startMobFarmLoop)
    end)
    Hub.Fn.connect(ToggleSkillsBtn.MouseButton1Click, function()
        State.isAutoSkills = not State.isAutoSkills
        ToggleSkillsBtn.Text = State.isAutoSkills and "⏸ Stop Auto Skills" or "🔥 Auto Spam Skills (Z,X,C,V)"
        ToggleSkillsBtn.BackgroundColor3 = State.isAutoSkills and Color3.fromRGB(200, 120, 30) or Color3.fromRGB(200, 80, 30)
        Hub.Fn.setWorker("startSkillsLoop", State.isAutoSkills, Hub.Fn.startSkillsLoop)
    end)
    Hub.Fn.connect(ToggleOffsetBtn.MouseButton1Click, function()
        State.farmOffsetIndex = (State.farmOffsetIndex % #Config.farmOffsets) + 1
        State.currentOffset = Config.farmOffsets[State.farmOffsetIndex].offset
        ToggleOffsetBtn.Text = "📍 Offset: " .. Config.farmOffsets[State.farmOffsetIndex].text
    end)
    Hub.Fn.connect(ToggleWorldBossBtn.MouseButton1Click, function()
        State.isAutoWorldBoss = not State.isAutoWorldBoss
        ToggleWorldBossBtn.Text = State.isAutoWorldBoss and "🐉 Auto World Boss: ON" or "🐉 Auto World Boss: OFF"
        ToggleWorldBossBtn.BackgroundColor3 = State.isAutoWorldBoss and Color3.fromRGB(185, 55, 55) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startWorldBossLoop", State.isAutoWorldBoss, Hub.Fn.startWorldBossLoop)
    end)
    Hub.Fn.connect(ToggleMapEventBtn.MouseButton1Click, function()
        State.isAutoMapEvent = not State.isAutoMapEvent
        ToggleMapEventBtn.Text = State.isAutoMapEvent and "🚩 Auto Sect Clash Event: ON" or "🚩 Auto Sect Clash Event: OFF"
        ToggleMapEventBtn.BackgroundColor3 = State.isAutoMapEvent and Color3.fromRGB(190, 60, 70) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startMapEventLoop", State.isAutoMapEvent, Hub.Fn.startMapEventLoop)
    end)

    -- หมวด Cultivation & Alchemy
    createCategoryHeader("✨ CULTIVATION & SPIRIT SOUL", 20)
    local ToggleCultivateBtn = createButton("🧘 Start Auto Meditate (นั่งสมาธิ)", Color3.fromRGB(50, 140, 180), 21)
    local ToggleBreakthroughBtn = createButton("🌀 Auto Breakthrough: OFF", Color3.fromRGB(100, 100, 100), 22)
    local ToggleBodyBreakthroughBtn = createButton("💪 Auto Body Breakthrough: OFF", Color3.fromRGB(100, 100, 100), 23)
    local TogglePushupBtn = createButton("🏋️‍♂️ Start Auto Pushup: OFF", Color3.fromRGB(100, 100, 100), 24)
    local ToggleTribulationBtn = createButton("⚡ Auto Tribulation: OFF", Color3.fromRGB(100, 100, 100), 25)
    local ToggleSoulBtn = createButton("👻 Auto Soul & Catch (จับวิญญาณเมื่อนั่งสมาธิ): OFF", Color3.fromRGB(100, 100, 100), 26)
    local ToggleOrbBtn = createButton("🔮 Start Auto Cultivation Orb", Color3.fromRGB(120, 80, 180), 27)
    local ZoneExpanseBtn = createButton("🌌 Zone: Celestial Expanse", Color3.fromRGB(80, 60, 160), 28)

    createCategoryHeader("⚗️ ALCHEMY & BUFF PILLS", 29)
    local ToggleRecipeBtn = createButton("💊 Recipe: " .. Config.recipeList[1].name, Color3.fromRGB(70, 120, 170), 30)
    local ToggleYearBtn = createButton("🎯 Min Herb Year: Any (All)", Color3.fromRGB(70, 70, 110), 31)
    local ToggleBrewBtn = createButton("⚗️ Start Auto Brew Pills", Color3.fromRGB(140, 50, 140), 32)

    createCategoryHeader("⚙️ SYSTEM & REWARDS", 33)
    local ClaimRewardBtn = createButton("🎁 Claim Daily & Cauldron", Color3.fromRGB(50, 150, 150), 34)
    local DestroyBtn = createButton("🛑 Destroy Script & Stop", Color3.fromRGB(180, 40, 40), 35)

    Hub.Fn.connect(ToggleCultivateBtn.MouseButton1Click, function()
        State.isAutoCultivate = not State.isAutoCultivate
        ToggleCultivateBtn.Text = State.isAutoCultivate and "⏸ Stop Auto Meditate" or "🧘 Start Auto Meditate (นั่งสมาธิ)"
        ToggleCultivateBtn.BackgroundColor3 = State.isAutoCultivate and Color3.fromRGB(200, 120, 30) or Color3.fromRGB(50, 140, 180)
        Hub.Fn.setWorker("startCultivateLoop", State.isAutoCultivate, Hub.Fn.startCultivateLoop)
    end)
    Hub.Fn.connect(ToggleBreakthroughBtn.MouseButton1Click, function()
        State.isAutoBreakthrough = not State.isAutoBreakthrough
        ToggleBreakthroughBtn.Text = State.isAutoBreakthrough and "🌀 Auto Breakthrough: ON" or "🌀 Auto Breakthrough: OFF"
        ToggleBreakthroughBtn.BackgroundColor3 = State.isAutoBreakthrough and Color3.fromRGB(140, 60, 180) or Color3.fromRGB(100, 100, 100)
    end)
    Hub.Fn.connect(ToggleBodyBreakthroughBtn.MouseButton1Click, function()
        State.isAutoBodyBreakthrough = not State.isAutoBodyBreakthrough
        ToggleBodyBreakthroughBtn.Text = State.isAutoBodyBreakthrough and "💪 Auto Body Breakthrough: ON" or "💪 Auto Body Breakthrough: OFF"
        ToggleBodyBreakthroughBtn.BackgroundColor3 = State.isAutoBodyBreakthrough and Color3.fromRGB(160, 80, 200) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startBodyBreakthroughLoop", State.isAutoBodyBreakthrough, Hub.Fn.startBodyBreakthroughLoop)
    end)
    Hub.Fn.connect(TogglePushupBtn.MouseButton1Click, function()
        State.isAutoPushup = not State.isAutoPushup
        TogglePushupBtn.Text = State.isAutoPushup and "🏋️‍♂️ Start Auto Pushup: ON" or "🏋️‍♂️ Start Auto Pushup: OFF"
        TogglePushupBtn.BackgroundColor3 = State.isAutoPushup and Color3.fromRGB(70, 180, 140) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startPushupLoop", State.isAutoPushup, Hub.Fn.startPushupLoop)
    end)
    Hub.Fn.connect(ToggleTribulationBtn.MouseButton1Click, function()
        State.isAutoTribulation = not State.isAutoTribulation
        ToggleTribulationBtn.Text = State.isAutoTribulation and "⚡ Auto Tribulation: ON" or "⚡ Auto Tribulation: OFF"
        ToggleTribulationBtn.BackgroundColor3 = State.isAutoTribulation and Color3.fromRGB(220, 160, 40) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startTribulationLoop", State.isAutoTribulation, Hub.Fn.startTribulationLoop)
    end)
    Hub.Fn.connect(ToggleSoulBtn.MouseButton1Click, function()
        State.isAutoSoul = not State.isAutoSoul
        ToggleSoulBtn.Text = State.isAutoSoul and "👻 Auto Soul & Catch: ON" or "👻 Auto Soul & Catch (จับวิญญาณเมื่อนั่งสมาธิ): OFF"
        ToggleSoulBtn.BackgroundColor3 = State.isAutoSoul and Color3.fromRGB(46, 139, 87) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startSoulLoop", State.isAutoSoul, Hub.Fn.startSoulLoop)
    end)
    Hub.Fn.connect(ToggleOrbBtn.MouseButton1Click, function()
        State.isAutoOrb = not State.isAutoOrb
        ToggleOrbBtn.Text = State.isAutoOrb and "⏸ Stop Auto Cultivation Orb" or "🔮 Start Auto Cultivation Orb"
        ToggleOrbBtn.BackgroundColor3 = State.isAutoOrb and Color3.fromRGB(200, 120, 30) or Color3.fromRGB(120, 80, 180)
        Hub.Fn.setWorker("startOrbLoop", State.isAutoOrb, Hub.Fn.startOrbLoop)
    end)
    Hub.Fn.connect(ZoneExpanseBtn.MouseButton1Click, function()
        if Env.Remotes.ZoneChanged then
            Env.Remotes.ZoneChanged:FireServer("Celestial Expanse")
        end
    end)
    Hub.Fn.connect(ToggleRecipeBtn.MouseButton1Click, function()
        State.recipeIndex = (State.recipeIndex % #Config.recipeList) + 1
        ToggleRecipeBtn.Text = "💊 Recipe: " .. Config.recipeList[State.recipeIndex].name
    end)
    Hub.Fn.connect(ToggleYearBtn.MouseButton1Click, function()
        State.yearIndex = (State.yearIndex % #Config.yearOptions) + 1
        State.selectedMinYear = Config.yearOptions[State.yearIndex]
        ToggleYearBtn.Text = State.selectedMinYear == 0 and "🎯 Min Herb Year: Any (All)" or ("🎯 Min Herb Year: " .. State.selectedMinYear .. "+ Years")
    end)
    Hub.Fn.connect(ToggleBrewBtn.MouseButton1Click, function()
        State.isAutoBrew = not State.isAutoBrew
        ToggleBrewBtn.Text = State.isAutoBrew and "⏸ Stop Auto Brew" or "⚗️ Start Auto Brew Pills"
        ToggleBrewBtn.BackgroundColor3 = State.isAutoBrew and Color3.fromRGB(200, 120, 30) or Color3.fromRGB(140, 50, 140)
        Hub.Fn.setWorker("startBrewLoop", State.isAutoBrew, Hub.Fn.startBrewLoop)
    end)
    Hub.Fn.connect(ClaimRewardBtn.MouseButton1Click, function()
        if Env.Remotes.ClaimReward then
            Env.Remotes.ClaimReward:FireServer("daily")
        end
        if Env.Remotes.CauldronClaim then
            Env.Remotes.CauldronClaim:FireServer()
        end
    end)

    local function cleanup()
        if Env.destroyed then
            return
        end
        Env.destroyed = true
        for k, v in pairs(State) do
            if type(v) == "boolean" then
                State[k] = false
            end
        end
        for name in pairs(Env.workers) do
            Hub.Fn.stopWorker(name)
        end
        for connection in pairs(Env.connections) do
            connection:Disconnect()
        end
        Env.connections = {}
        Env.cachedHerbPrompts = {}
        Env.collectedCooldowns = {}
        Env.orbParts = {}
        Env.mobInfoCache = {}
        if Env.groundPlatform then
            Env.groundPlatform:Destroy()
        end
    end

    Hub.Fn.connect(ScreenGui.Destroying, cleanup)
    Hub.Fn.connect(DestroyBtn.MouseButton1Click, function()
        cleanup()
        ScreenGui:Destroy()
    end)

    Hub.Fn.setWorker("startDynamicStreamLoop", State.isDynamicStream, Hub.Fn.startDynamicStreamLoop)
    Hub.Fn.rebuildMobListUI()
    Hub.Fn.logDebug("พร้อมใช้งาน V27! (จุดสตรีม: " .. #Hub.Fn.getDynamicStreamPoints() .. " จุด)")
end