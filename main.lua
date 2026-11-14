local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== ระบบแสดง Error / Rules GUI (พร้อมปุ่ม Copy และปุ่มปิด) ====================
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

-- ==================== โครงสร้างหลักแบบแยก Scope (ป้องกันเกิน 200 Local Variables) ====================
local Hub = {
    Env = {
        connections = {},
        workers = {},
        destroyed = false,
        Remotes = {},
        Modules = {},
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
        lastRulesSnapshot = nil,
        currentZoneSeed = nil,
        brewStartedAt = 0,
        stokedThisRound = false,
        examStageActive = false
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

    for _, modName in ipairs({ "HerbModule", "PillModule", "BrewMinigame", "AlchemyExamRules", "AlchemyRankRules" }) do
        local modObj = ReplicatedStorage:FindFirstChild(modName)
        if modObj and modObj:IsA("ModuleScript") then
            local ok, res = pcall(require, modObj)
            if ok and type(res) == "table" then
                Env.Modules[modName] = res
            end
        end
    end

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
                showDebugErrorGui("⚠️ Event Callback Error", err)
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

        local ulMod = ReplicatedStorage:FindFirstChild("UpdateLog")
        if ulMod and ulMod:IsA("ModuleScript") then
            local ok, ul = pcall(require, ulMod)
            if ok and type(ul) == "table" then
                addRaw("=== LATEST GAME PATCH ===")
                addRaw("UpdateLog.LATEST = " .. tostring(ul.LATEST))
                if type(ul.ENTRIES) == "table" and ul.ENTRIES[1] then
                    addRaw("UpdateLog.Title = " .. tostring(ul.ENTRIES[1].title) .. " (" .. tostring(ul.ENTRIES[1].date) .. ")")
                end
            end
        end

        addRaw("\n=== 1. REPLICATED STORAGE RULES & CONFIG MODULES ===")
        local modules = {}
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("ModuleScript") then
                local lower = obj.Name:lower()
                if lower:find("rule") or lower:find("config") or lower:find("boss") or lower:find("guard") or lower:find("const") or lower:find("stat") or lower:find("soul") or lower:find("beast") or lower:find("dragon") or lower:find("alchemy") then
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
        local snapshotFile = "murim_rules_snapshot.txt"
        local oldText = Env.lastRulesSnapshot
        if not oldText and type(isfile) == "function" and type(readfile) == "function" then
            pcall(function()
                if isfile(snapshotFile) then
                    oldText = readfile(snapshotFile)
                end
            end)
        end

        local diffHeader = ""
        if oldText and oldText ~= "" then
            local oldSet, newSet = {}, {}
            for line in oldText:gmatch("[^\r\n]+") do
                if line ~= "" and not line:find("^===") then
                    oldSet[line] = true
                end
            end
            for line in currentText:gmatch("[^\r\n]+") do
                if line ~= "" and not line:find("^===") then
                    newSet[line] = true
                end
            end

            local added, removed = {}, {}
            for line in pairs(newSet) do
                if not oldSet[line] then
                    table.insert(added, "+ " .. line)
                end
            end
            for line in pairs(oldSet) do
                if not newSet[line] then
                    table.insert(removed, "- " .. line)
                end
            end
            table.sort(added)
            table.sort(removed)

            if #added > 0 or #removed > 0 then
                diffHeader = "🆕 === สิ่งที่เพิ่ม/เปลี่ยนแปลงจากครั้งก่อน (" .. (#added + #removed) .. " รายการ) ===\n"
                if #added > 0 then
                    diffHeader = diffHeader .. table.concat(added, "\n") .. "\n"
                end
                if #removed > 0 then
                    diffHeader = diffHeader .. table.concat(removed, "\n") .. "\n"
                end
                diffHeader = diffHeader .. "\n"
            else
                diffHeader = "✅ === ไม่พบค่า Rules หรือ Remotes ที่เปลี่ยนไปจากครั้งก่อน ===\n\n"
            end
        else
            Env.lastRulesSnapshot = currentText
            if type(writefile) == "function" then
                pcall(writefile, snapshotFile, currentText)
            end
            diffHeader = "💾 === บันทึก Snapshot ครั้งแรกเรียบร้อยแล้ว (กดเช็กครั้งหน้าจะเทียบให้อัตโนมัติ) ===\n\n"
        end

        return diffHeader .. currentText, currentText, snapshotFile
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
            "SoulCultivation",
            "SpiritWorld",
            "SpiritDoor",
            "TamedBeasts",
            "CultivateResumed",
            "ClaimReward",
            "UseSkill",
            "CombatHit",
            "CauldronStartBrew",
            "CauldronStartSpiritBrew",
            "CauldronStartRefine",
            "CauldronClaim",
            "CauldronStoke",
            "CauldronStateUpdate",
            "AlchemyExam",
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
            "1000Yr Sniper + All Herbs",
            "Only 1000-Year (เฉพาะ 1000 ปี)"
        },
        recipeList = {
            {
                name = "🐾 Spirit Pill (อาหารสัตว์อสูร - Spirit Herbs x3)",
                mode = "spirit",
                ingredients = nil
            },
            {
                name = "⚡ Qi Cultivation (Ginseng x2, Lotus x1)",
                mode = "normal",
                ingredients = {
                    { id = 1, count = 2 },
                    { id = 2, count = 1 }
                }
            },
            {
                name = "💪 Body Cultivation (Moss x2, Fern x1)",
                mode = "normal",
                ingredients = {
                    { id = 3, count = 2 },
                    { id = 4, count = 1 }
                }
            },
            {
                name = "❤️ Vitality Pill (Ginseng, Moss, Sage)",
                mode = "normal",
                ingredients = {
                    { id = 1, count = 1 },
                    { id = 3, count = 1 },
                    { id = 5, count = 1 }
                }
            },
            {
                name = "🔥 Bloodfury Pill (Lotus, Fern, Sage)",
                mode = "normal",
                ingredients = {
                    { id = 2, count = 1 },
                    { id = 4, count = 1 },
                    { id = 5, count = 1 }
                }
            },
            {
                name = "🌊 [Rank 2] Meridian Cleansing (Ginseng, Moss, Frostbloom)",
                mode = "normal",
                ingredients = {
                    { id = 1, count = 1 },
                    { id = 3, count = 1 },
                    { id = 16, count = 1 }
                }
            },
            {
                name = "🛡️ [Rank 3] Iron Skin (Moss, Sage, Sunscale)",
                mode = "normal",
                ingredients = {
                    { id = 3, count = 1 },
                    { id = 5, count = 1 },
                    { id = 17, count = 1 }
                }
            },
            {
                name = "👻 [Rank 4] Spirit Lure (Lotus, Thunderroot, Moonshadow)",
                mode = "normal",
                ingredients = {
                    { id = 2, count = 1 },
                    { id = 18, count = 1 },
                    { id = 19, count = 1 }
                }
            },
            {
                name = "🐾 [Rank 5] Beast Affinity (Fern, Sage, Dragonblood)",
                mode = "normal",
                ingredients = {
                    { id = 4, count = 1 },
                    { id = 5, count = 1 },
                    { id = 20, count = 1 }
                }
            },
            {
                name = "⚓ [Rank 6] Soul Anchor (Frostbloom, Thunderroot, Phoenix)",
                mode = "normal",
                ingredients = {
                    { id = 16, count = 1 },
                    { id = 18, count = 1 },
                    { id = 21, count = 1 }
                }
            },
            {
                name = "☯️ [Rank 7] Clone Harmony (Sunscale, Dragonblood, Phoenix)",
                mode = "normal",
                ingredients = {
                    { id = 17, count = 1 },
                    { id = 20, count = 1 },
                    { id = 21, count = 1 }
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
        fallbackZones = {
            Vector3.new(0, 120, 0),
            Vector3.new(-350, 140, 2200),
            Vector3.new(900, 130, 2100),
            Vector3.new(-2800, 150, -2100),
            Vector3.new(2500, 1500, 1000)
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
        isAutoPerfectStoke = true,
        isAutoAlchemyExam = false,
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

-- 2. ระบบ Events Listeners, Perfect Stoke, Auto Alchemy Exam Solver
do
    local Env = Hub.Env
    local State = Hub.State
    local Config = Hub.Config
    local UI = Hub.UI

    function Hub.Fn.solveAlchemyQuiz(qData)
        if type(qData) ~= "table" or type(qData.options) ~= "table" then
            return 1
        end
        if type(qData.answer) == "number" then
            return qData.answer
        end

        local options = qData.options
        local text = tostring(qData.text or "")
        local HerbMod = Env.Modules.HerbModule or {}
        local PillMod = Env.Modules.PillModule or {}
        local RankMod = Env.Modules.AlchemyRankRules or {}

        local herbs = HerbMod.Herbs or {}
        local pills = PillMod.Pills or {}
        local yearTiers = HerbMod.YearTiers or {}
        local whereMap = HerbMod.WHERE or {}

        local function cleanStr(s)
            return tostring(s or ""):lower():gsub("^%s*(.-)%s*$", "%1")
        end

        local function findOption(targetStr)
            if not targetStr then
                return nil
            end
            local ct = cleanStr(targetStr)
            for idx, opt in ipairs(options) do
                if cleanStr(opt) == ct then
                    return idx
                end
            end
            return nil
        end

        if qData.image and type(herbs) == "table" then
            local targetImg = tostring(qData.image)
            local imgNum = targetImg:match("(%d+)")

            local orderedIds = {}
            for id = 1, 5 do
                if herbs[id] then
                    table.insert(orderedIds, id)
                end
            end
            for id in pairs(herbs) do
                if type(id) ~= "number" or id < 1 or id > 5 then
                    table.insert(orderedIds, id)
                end
            end

            for _, id in ipairs(orderedIds) do
                local h = herbs[id]
                if type(h) == "table" and h.name and h.imageId then
                    local hImg = tostring(h.imageId)
                    if hImg == targetImg or (imgNum and hImg:find(imgNum, 1, true)) then
                        local idx = findOption(h.name)
                        if idx then
                            return idx
                        end
                    end
                end
            end
        end

        if text:find("brews which pill%?") and type(pills) == "table" and type(herbs) == "table" then
            local recipePart = text:match("^(.-)%s+brews which pill%?$")
            if recipePart then
                local counts = {}
                for hName in recipePart:gmatch("[^+]+") do
                    local clean = cleanStr(hName)
                    counts[clean] = (counts[clean] or 0) + 1
                end
                for _, p in pairs(pills) do
                    if type(p) == "table" and p.name and type(p.recipe) == "table" then
                        local pCounts = {}
                        for _, hId in ipairs(p.recipe) do
                            local hObj = herbs[hId]
                            if type(hObj) == "table" and hObj.name then
                                local clean = cleanStr(hObj.name)
                                pCounts[clean] = (pCounts[clean] or 0) + 1
                            end
                        end
                        local match = true
                        for k, v in pairs(counts) do
                            if pCounts[k] ~= v then
                                match = false
                                break
                            end
                        end
                        for k, v in pairs(pCounts) do
                            if counts[k] ~= v then
                                match = false
                                break
                            end
                        end
                        if match then
                            local idx = findOption(p.name)
                            if idx then
                                return idx
                            end
                        end
                    end
                end
            end
        end

        if text:find("Which herb goes into the ") and type(pills) == "table" and type(herbs) == "table" then
            local pillName = text:match("^Which herb goes into the (.-)%?$")
            if pillName then
                for _, p in pairs(pills) do
                    if type(p) == "table" and p.name and cleanStr(p.name) == cleanStr(pillName) and type(p.recipe) == "table" then
                        for _, hId in ipairs(p.recipe) do
                            local hObj = herbs[hId]
                            if type(hObj) == "table" and hObj.name then
                                local idx = findOption(hObj.name)
                                if idx then
                                    return idx
                                end
                            end
                        end
                    end
                end
            end
        end

        if text == "Which herbs brew the strongest pills?" then
            if type(yearTiers) == "table" and #yearTiers > 0 and type(yearTiers[#yearTiers]) == "table" and yearTiers[#yearTiers].label then
                local idx = findOption(yearTiers[#yearTiers].label)
                if idx then
                    return idx
                end
            end
            for idx, opt in ipairs(options) do
                if tostring(opt):find("1000") then
                    return idx
                end
            end
        end

        if text:find("always brew a pill of which tier%?") then
            local topTier = tonumber(RankMod.MAX_NORMAL_TIER) or 5
            local idx = findOption("Tier " .. tostring(topTier))
            if idx then
                return idx
            end
        end

        if text:find("Where does the ") and type(herbs) == "table" then
            local herbName = text:match("^Where does the (.-) grow%?$")
            if herbName then
                for _, h in pairs(herbs) do
                    if type(h) == "table" and h.name and cleanStr(h.name) == cleanStr(herbName) and h.grows then
                        local locStr = whereMap[h.grows] or tostring(h.grows)
                        local idx = findOption(locStr)
                        if idx then
                            return idx
                        end
                    end
                end
            end
        end

        if text == "Who can pick spirit herbs?" then
            local idx = findOption("Only a soul in the spirit world")
            if idx then
                return idx
            end
        end

        if text == "Which of these is a spirit herb?" and type(herbs) == "table" then
            for _, h in pairs(herbs) do
                if type(h) == "table" and h.spirit == true and h.name then
                    local idx = findOption(h.name)
                    if idx then
                        return idx
                    end
                end
            end
        end

        if text:find("Which alchemist can first brew the ") and type(pills) == "table" then
            local pillName = text:match("^Which alchemist can first brew the (.-)%?$")
            if pillName then
                for _, p in pairs(pills) do
                    if type(p) == "table" and p.name and cleanStr(p.name) == cleanStr(pillName) then
                        local reqRank = tonumber(p.rank) or 1
                        local titleStr
                        if type(RankMod.title) == "function" then
                            titleStr = RankMod.title(reqRank)
                        elseif type(RankMod.NAMES) == "table" and RankMod.NAMES[reqRank] then
                            titleStr = "Rank-" .. tostring(RankMod.NAMES[reqRank]) .. " Alchemist"
                        end
                        local idx = findOption(titleStr)
                        if idx then
                            return idx
                        end
                    end
                end
            end
        end

        return 1
    end

    function Hub.Fn.performPerfectStoke(zoneSeed, startTime)
        local BrewMinigame = Env.Modules.BrewMinigame
        if not Env.Remotes.CauldronStoke then
            return
        end
        if not BrewMinigame or type(BrewMinigame.zoneFor) ~= "function" then
            task.wait(0.35)
            Env.Remotes.CauldronStoke:FireServer(0.35)
            Env.stokedThisRound = true
            return
        end
        local targetPos = BrewMinigame.zoneFor(zoneSeed)
        local period = tonumber(BrewMinigame.PERIOD) or 1.2
        local idealPressTime = targetPos * period
        local elapsed = os.clock() - startTime
        local waitTime = idealPressTime - elapsed
        if waitTime > 0 then
            task.wait(waitTime)
        end
        Env.Remotes.CauldronStoke:FireServer(idealPressTime)
        Env.stokedThisRound = true
        Hub.Fn.logDebug(string.format("🔥 Perfect Stoke! Target=%.2f (%.2fs)", targetPos, idealPressTime))
    end

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
                    if data.status ~= "brewing" then
                        Env.stokedThisRound = false
                        Env.currentZoneSeed = nil
                    elseif State.cauldronStatus ~= "brewing" then
                        Env.brewStartedAt = os.clock()
                        Env.stokedThisRound = false
                    end
                    State.cauldronStatus = data.status
                end
                if type(data.zoneSeed) == "number" then
                    Env.currentZoneSeed = data.zoneSeed
                    if State.isAutoPerfectStoke and State.cauldronStatus == "brewing" and not Env.stokedThisRound then
                        Env.stokedThisRound = true
                        local startT = Env.brewStartedAt > 0 and Env.brewStartedAt or os.clock()
                        task.spawn(Hub.Fn.performPerfectStoke, data.zoneSeed, startT)
                    end
                end
            end
        end)
    end

    if Env.Remotes.AlchemyExam then
        Hub.Fn.connect(Env.Remotes.AlchemyExam.OnClientEvent, function(action, p1, p2, p3)
            if not State.isAutoAlchemyExam then
                return
            end

            if action == "open" and type(p1) == "table" then
                if p1.canStart then
                    if UI.ExamStatusLabel then
                        UI.ExamStatusLabel.Text = "🎓 Exam: กำลังเริ่มสอบ Rank " .. tostring(p1.rank)
                        UI.ExamStatusLabel.TextColor3 = Color3.fromRGB(130, 235, 160)
                    end
                    task.delay(0.35, function()
                        if State.isAutoAlchemyExam and Env.Remotes.AlchemyExam then
                            Env.Remotes.AlchemyExam:FireServer("begin")
                        end
                    end)
                else
                    if UI.ExamStatusLabel then
                        UI.ExamStatusLabel.Text = "🎓 Exam: " .. tostring(p1.why or "เงื่อนไขยังไม่ครบ")
                        UI.ExamStatusLabel.TextColor3 = Color3.fromRGB(255, 150, 120)
                    end
                end

            elseif action == "quiz" and type(p3) == "table" then
                local qIndex = p1
                local totalQ = p2
                local ansIdx = Hub.Fn.solveAlchemyQuiz(p3)
                local ansText = (type(p3.options) == "table" and p3.options[ansIdx]) or tostring(ansIdx)
                if UI.ExamStatusLabel then
                    UI.ExamStatusLabel.Text = string.format("🎓 Exam: ตอบข้อ %s/%s -> %s", tostring(qIndex), tostring(totalQ), tostring(ansText))
                    UI.ExamStatusLabel.TextColor3 = Color3.fromRGB(130, 235, 160)
                end
                Hub.Fn.logDebug(string.format("🎓 ข้อ %s: %s -> ตอบ [%s] %s", tostring(qIndex), tostring(p3.text), tostring(ansIdx), tostring(ansText)))
                task.delay(0.45, function()
                    if State.isAutoAlchemyExam and Env.Remotes.AlchemyExam then
                        Env.Remotes.AlchemyExam:FireServer("answer", qIndex, ansIdx)
                    end
                end)

            elseif action == "gather" and type(p1) == "table" then
                if p1.haveAll then
                    if UI.ExamStatusLabel then
                        UI.ExamStatusLabel.Text = "🎓 Exam: ส่งวัตถุดิบเริ่มต้มทดสอบ!"
                        UI.ExamStatusLabel.TextColor3 = Color3.fromRGB(130, 235, 160)
                    end
                    task.delay(0.4, function()
                        if State.isAutoAlchemyExam and Env.Remotes.AlchemyExam then
                            Env.Remotes.AlchemyExam:FireServer("handIn")
                        end
                    end)
                else
                    if UI.ExamStatusLabel then
                        UI.ExamStatusLabel.Text = "🎓 Exam: วัตถุดิบสอบยังไม่ครบ!"
                        UI.ExamStatusLabel.TextColor3 = Color3.fromRGB(255, 150, 120)
                    end
                end

            elseif action == "brew" and type(p3) == "table" then
                local stageNum = p1
                local totalStages = p2
                local brewData = p3
                local ExamRules = Env.Modules.AlchemyExamRules
                local startedAt = os.clock()
                Env.examStageActive = true

                if UI.ExamStatusLabel then
                    UI.ExamStatusLabel.Text = string.format("🎓 Exam: คุมไฟด่าน %s/%s...", tostring(stageNum), tostring(totalStages))
                    UI.ExamStatusLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
                end

                task.spawn(function()
                    local targetZone = tonumber(brewData.zone) or 0.5
                    local period = tonumber(brewData.period) or 1.2
                    local width = tonumber(brewData.width) or 0.15
                    local limit = tonumber(brewData.limit) or 6

                    while State.isAutoAlchemyExam and Env.examStageActive do
                        local elapsed = os.clock() - startedAt
                        if elapsed > limit then
                            break
                        end
                        local pos = (ExamRules and type(ExamRules.flamePos) == "function") and ExamRules.flamePos(elapsed, period) or ((elapsed / period) % 1)
                        local isHit = (ExamRules and type(ExamRules.brewOk) == "function")
                            and ExamRules.brewOk(targetZone, pos, width * 0.5)
                            or (math.abs(pos - targetZone) <= (width * 0.25))

                        if elapsed > 0.25 and isHit then
                            Env.examStageActive = false
                            if Env.Remotes.AlchemyExam then
                                Env.Remotes.AlchemyExam:FireServer("press", stageNum, elapsed)
                            end
                            Hub.Fn.logDebug(string.format("🎓 กดไฟสอบด่าน %s สำเร็จ! (%.2fs)", tostring(stageNum), elapsed))
                            break
                        end
                        task.wait(0.015)
                    end
                end)

            elseif action == "brewResult" then
                Env.examStageActive = false

            elseif action == "trib" and type(p1) == "table" then
                local planData = p1
                local startedAt = os.clock() + (tonumber(planData.delay) or 0)
                local planList = planData.plan or {}

                if UI.ExamStatusLabel then
                    UI.ExamStatusLabel.Text = "🎓 Exam: กำลังรับทัณฑ์สายฟ้า (" .. #planList .. " สาย)"
                    UI.ExamStatusLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
                end

                for boltIdx, bolt in ipairs(planList) do
                    task.spawn(function()
                        local hitTime = tonumber(bolt.at) or 3
                        local targetPressElapsed = hitTime - 0.15
                        local waitDur = (startedAt + targetPressElapsed) - os.clock()
                        if waitDur > 0 then
                            task.wait(waitDur)
                        end
                        if State.isAutoAlchemyExam and Env.Remotes.AlchemyExam then
                            local actualElapsed = os.clock() - startedAt
                            Env.Remotes.AlchemyExam:FireServer("guard", boltIdx, bolt.lane, actualElapsed)
                            Hub.Fn.logDebug(string.format("⚡ กันสายฟ้าสายที่ %d (เลน %s)", boltIdx, tostring(bolt.lane)))
                        end
                    end)
                end

            elseif action == "pass" and type(p1) == "table" then
                Env.examStageActive = false
                if UI.ExamStatusLabel then
                    UI.ExamStatusLabel.Text = "🎓 Exam: สอบผ่านแล้ว! (" .. tostring(p1.pillName) .. ")"
                    UI.ExamStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 140)
                end
                Hub.Fn.logDebug("🎉 สอบเลื่อนขั้นนักปรุงยาผ่านเรียบร้อย!")

            elseif action == "fail" then
                Env.examStageActive = false
                if UI.ExamStatusLabel then
                    UI.ExamStatusLabel.Text = "🎓 Exam: สอบไม่ผ่าน (" .. tostring(p1) .. ")"
                    UI.ExamStatusLabel.TextColor3 = Color3.fromRGB(255, 110, 110)
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

    if Env.Remotes.WorldBoss then
        Hub.Fn.connect(Env.Remotes.WorldBoss.OnClientEvent, function(action, subAction)
            if action == "announce" and (subAction == "warning" or subAction == "rise") then
                Hub.Fn.logDebug("🐉 แจ้งเตือน World Boss: " .. tostring(subAction))
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
        local wbFolder = Hub.Fn.getWorldBossFolder()
        if wbFolder then
            local centreAttr = wbFolder:GetAttribute("Centre")
            if typeof(centreAttr) == "Vector3" then
                Env.cachedWorldBossArenaPos = centreAttr
                return centreAttr
            end
        end
        if Env.cachedWorldBossArenaPos then
            return Env.cachedWorldBossArenaPos
        end
        return Vector3.new(-1150, 35, -1700)
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
            if flatDir.Magnitude < 0.1 then
                flatDir = Vector3.new(0, 0, 1)
            else
                flatDir = flatDir.Unit
            end
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
                    UI.WorldBossStatusLabel.Text = "🐉 World Boss: เกิดใน " .. left .. " วิ (กำลังไปรอ)"
                    UI.WorldBossStatusLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
                else
                    if spawnAt > nowSec then
                        local diff = spawnAt - nowSec
                        local mins = math.floor(diff / 60)
                        local secs = diff % 60
                        UI.WorldBossStatusLabel.Text = string.format("🐉 World Boss: รอบถัดไป %d:%02d", mins, secs)
                    else
                        UI.WorldBossStatusLabel.Text = "🐉 World Boss: Standby (" .. wbState .. ")"
                    end
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
                        if (hrp.Position - arenaPos).Magnitude > 35 then
                            Hub.Fn.safeTeleport(hrp, CFrame.new(arenaPos + Vector3.new(0, 4, 0)))
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
                    Hub.Fn.logDebug("🐉 จบรอบ World Boss! กลับสู่โหมดฟาร์มปกติ")
                    local fxFolder = workspace:FindFirstChild("WorldBossFX")
                    if fxFolder and fireproximityprompt then
                        for _, desc in ipairs(fxFolder:GetDescendants()) do
                            if desc:IsA("ProximityPrompt") and desc.ObjectText == "Sovereign's Coffer" then
                                pcall(fireproximityprompt, desc)
                            end
                        end
                    end
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

        for _, mapName in ipairs({ "Map_sacred-mountain", "Map_withered-valley" }) do
            local mapFolder = workspace:FindFirstChild(mapName)
            if mapFolder then
                local spawns = mapFolder:FindFirstChild("Spawns")
                if spawns then
                    for _, sp in ipairs(spawns:GetChildren()) do
                        if sp:IsA("BasePart") then
                            addPoint(sp.Position)
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
                        UI.EventStatusLabel.Text = "🚩 Event: Waiting (รอสงครามสำนัก)"
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
                            UI.TargetHPLabel.Text = "🎯 Target: N/A (ไม่มีมอนสเตอร์ที่เลือก)"
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
            UI.TargetHPLabel.Text = "🎯 Target: Standby (รอการทำงาน)"
            UI.TargetHPLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
        end
        if not State.isFarming and not Hub.Fn.isWorldBossActive() and not (State.isAutoMapEvent and Env.ActiveMapEvent) then
            Env.groundPlatform.CFrame = CFrame.new(0, 9999, 0)
        end
    end
end

-- 4. ระบบ Cultivation, Soul Cultivation, Herbs (ตรรกะ V26 + ไล่จับโบนัส x2) และ Alchemy
do
    local Env = Hub.Env
    local State = Hub.State
    local Config = Hub.Config
    local UI = Hub.UI

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

    function Hub.Fn.startSoulLoop()
        local caughtCache = {}
        local sessionStartTime = 0
        while State.isAutoSoul do
            local char, hrp, humanoid = Hub.Fn.getCharacter()
            local stars = tonumber(LocalPlayer:GetAttribute("SoulStars")) or 0
            local essence = math.floor(tonumber(LocalPlayer:GetAttribute("SoulEssence")) or 0)
            local need = math.floor(tonumber(LocalPlayer:GetAttribute("SoulNeed")) or 120)

            if UI.SoulStatusLabel then
                UI.SoulStatusLabel.Text = string.format("👻 Soul: ⭐%d/10 | Essence: %d/%d", stars, essence, need)
                UI.SoulStatusLabel.TextColor3 = Color3.fromRGB(130, 235, 255)
            end

            if char and hrp and humanoid and humanoid.Health > 0 then
                local isProjecting = LocalPlayer:GetAttribute("SoulProjecting") == true
                local isForming = LocalPlayer:GetAttribute("SoulForming") == true

                if isProjecting and humanoid.MaxHealth > 0 and (humanoid.Health / humanoid.MaxHealth) <= 0.22 then
                    local bodyPos = Hub.Fn.getBodyPosition()
                    if bodyPos then
                        hrp.CFrame = CFrame.new(bodyPos + Vector3.new(0, 1.5, 0))
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                    if Env.Remotes.SoulProjection then
                        Env.Remotes.SoulProjection:FireServer("return")
                        Hub.Fn.logDebug("👻 เลือดวิญญาณต่ำ! ดึงกลับร่างอัตโนมัติป้องกันวิญญาณแตก")
                        task.wait(1.5)
                    end
                elseif not isProjecting then
                    caughtCache = {}
                    sessionStartTime = 0
                    if LocalPlayer:GetAttribute("SoulProjectionLearned") == true then
                        local isMeditating = char:FindFirstChild("IsMeditating")
                        local isPushingUp = char:FindFirstChild("IsPushingUp")
                        local cultivating = (isMeditating and isMeditating.Value) or (isPushingUp and isPushingUp.Value)
                        local cooldown = (tonumber(LocalPlayer:GetAttribute("SoulCooldownUntil")) or 0) - workspace:GetServerTimeNow()
                        if cultivating and cooldown <= 0 and Env.Remotes.SoulProjection then
                            Env.Remotes.SoulProjection:FireServer("start")
                            task.wait(2.1)
                            sessionStartTime = os.clock()
                        end
                    end
                elseif not isForming then
                    if sessionStartTime == 0 then
                        sessionStartTime = os.clock()
                    end
                    local bodyPos = Hub.Fn.getBodyPosition() or hrp.Position
                    local maxTether = (stars >= 6) and 999999 or ((tonumber(LocalPlayer:GetAttribute("SoulTether")) or 480) - 15)
                    local spiritWorldFolder = workspace:FindFirstChild("SpiritWorld")
                    local foundTarget = false

                    if spiritWorldFolder and Env.Remotes.SpiritWorld then
                        local spiritsFolder = spiritWorldFolder:FindFirstChild("Spirits")
                        if spiritsFolder then
                            for _, spirit in ipairs(spiritsFolder:GetChildren()) do
                                if not State.isAutoSoul or LocalPlayer:GetAttribute("SoulProjecting") ~= true then
                                    break
                                end
                                if spirit:IsA("BasePart") and spirit.Parent and not caughtCache[spirit] and (spirit.Position - bodyPos).Magnitude <= maxTether then
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
                                    caughtCache[spirit] = true
                                    task.wait(0.1)
                                end
                            end
                        end

                        local herbsFolder = spiritWorldFolder:FindFirstChild("Herbs")
                        if herbsFolder then
                            for _, herb in ipairs(herbsFolder:GetChildren()) do
                                if not State.isAutoSoul or LocalPlayer:GetAttribute("SoulProjecting") ~= true then
                                    break
                                end
                                if herb:IsA("BasePart") and herb:GetAttribute("Picked") ~= true then
                                    local prompt = herb:FindFirstChildOfClass("ProximityPrompt")
                                    if prompt and (herb.Position - bodyPos).Magnitude <= maxTether then
                                        foundTarget = true
                                        hrp.CFrame = herb.CFrame * CFrame.new(0, 1.5, 0)
                                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                        if firetouchinterest then
                                            pcall(function()
                                                firetouchinterest(hrp, herb, 0)
                                                firetouchinterest(hrp, herb, 1)
                                            end)
                                        end
                                        task.wait(0.08)
                                        if fireproximityprompt then
                                            pcall(fireproximityprompt, prompt)
                                        end
                                        if Env.Remotes.CollectHerb then
                                            Env.Remotes.CollectHerb:FireServer(herb)
                                        end
                                        task.wait(0.1)
                                    end
                                end
                            end
                        end
                    end

                    if Env.Remotes.SoulCultivation then
                        pcall(function()
                            Env.Remotes.SoulCultivation:FireServer("start")
                            Env.Remotes.SoulCultivation:FireServer("meditate")
                        end)
                    end

                    if not foundTarget and bodyPos then
                        hrp.CFrame = CFrame.new(bodyPos + Vector3.new(0, 15, 0))
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end

                    if stars < 6 and (os.clock() - sessionStartTime) >= 18 then
                        if bodyPos then
                            hrp.CFrame = CFrame.new(bodyPos + Vector3.new(0, 1.5, 0))
                            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            task.wait(0.15)
                        end
                        if Env.Remotes.SoulProjection and LocalPlayer:GetAttribute("SoulProjecting") == true then
                            Env.Remotes.SoulProjection:FireServer("return")
                            task.wait(1.5)
                        end
                    end
                end
            end
            task.wait(0.35)
        end

        if UI.SoulStatusLabel then
            UI.SoulStatusLabel.Text = "👻 Soul: OFF"
            UI.SoulStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
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

    -- ยกฟังก์ชัน getBestHerbTarget ของ V26 กลับมาทั้งหมด (รวม workspace.HerbSpots)
    local function getBestHerbTarget(fromPos)
        initHerbCache()
        local spiritWorld = workspace:FindFirstChild("SpiritWorld")
        local herbSpots = workspace:FindFirstChild("HerbSpots")
        local now = os.clock()
        local only1000Yr = (State.herbModeIndex == 2)
        local candidates, seenParts = {}, {}

        local function evaluatePart(part, prompt)
            if seenParts[part] or not part or not part.Parent then
                return
            end
            if spiritWorld and part:IsDescendantOf(spiritWorld) then
                return
            end
            if prompt and not prompt.Enabled then
                return
            end
            seenParts[part] = true

            local herbYear = part:GetAttribute("HerbYear") or part:GetAttribute("Year")
            if type(herbYear) ~= "number" then
                herbYear = 1
            end

            if only1000Yr and herbYear < 1000 then
                return
            end

            local cdUntil = Env.collectedCooldowns[part]
            if cdUntil and now < cdUntil then
                return
            end

            local dist = (part.Position - fromPos).Magnitude
            table.insert(candidates, { part = part, prompt = prompt, dist = dist, year = herbYear })
        end

        if herbSpots then
            for _, spot in ipairs(herbSpots:GetChildren()) do
                if spot:IsA("BasePart") then
                    evaluatePart(spot, spot:FindFirstChildOfClass("ProximityPrompt"))
                end
            end
        end

        for prompt in pairs(Env.cachedHerbPrompts) do
            if prompt and prompt.Parent then
                if prompt.Enabled then
                    local part = prompt.Parent
                    if part:IsA("BasePart") then
                        evaluatePart(part, prompt)
                    end
                end
            else
                Env.cachedHerbPrompts[prompt] = nil
            end
        end

        if #candidates == 0 then
            return nil, nil, 999999, 0
        end

        table.sort(candidates, function(a, b)
            local a1000, b1000 = a.year >= 1000, b.year >= 1000
            if a1000 ~= b1000 then
                return a1000
            end
            local a100, b100 = a.year >= 100, b.year >= 100
            if a100 ~= b100 then
                return a100
            end
            return a.dist < b.dist
        end)

        local best = candidates[1]
        return best.part, best.prompt, best.dist, best.year
    end

    -- ยกลูป startFarmLoop ของ V26 กลับมา + คงระบบไล่จับสมุนไพรวิ่งหนี x2
    function Hub.Fn.startFarmLoop()
        initHerbCache()
        Hub.Fn.logDebug("เริ่มลูปเก็บสมุนไพร (V26 Logic + Chase x2)...")
        while State.isFarming do
            if Hub.Fn.isWorldBossActive() or (State.isAutoMapEvent and Env.ActiveMapEvent) then
                task.wait(0.5)
            else
                local char, hrp, humanoid = Hub.Fn.getCharacter()
                if char and hrp and humanoid and humanoid.Health > 0 then
                    local herbPart, prompt, _, herbYear = getBestHerbTarget(hrp.Position)

                    if herbPart and herbPart.Parent then
                        Hub.Fn.logDebug("พบเป้าหมาย: " .. herbPart.Name .. " (" .. tostring(herbYear) .. "Yr)")
                        local initialPos = herbPart.Position
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
                                Env.Remotes.CollectHerb:FireServer(herbPart)
                            end

                            local waitStart = os.clock()
                            while State.isFarming and herbPart.Parent and (not prompt or prompt.Enabled) and Env.lastHerbCollectedAt == beforeCollect and (os.clock() - waitStart) < 0.25 do
                                task.wait(0.03)
                            end

                            -- เช็กกรณีสมุนไพรวิ่งหนี (ถ้าตำแหน่งขยับจากจุดเดิม)
                            if herbPart.Parent and (herbPart.Position - initialPos).Magnitude > 1.5 and (not prompt or prompt.Enabled) then
                                Hub.Fn.logDebug("🏃 สมุนไพรวิ่งหนี! กำลังไล่จับโบนัส x2...")
                                local chaseDeadline = os.clock() + 10
                                while State.isFarming and herbPart.Parent and (not prompt or prompt.Enabled) and os.clock() < chaseDeadline do
                                    local chaseCF = herbPart.CFrame * CFrame.new(0, 1.5, 1.5)
                                    Hub.Fn.safeTeleport(hrp, chaseCF, herbPart)
                                    Env.groundPlatform.CFrame = chaseCF * CFrame.new(0, -3.2, 0)
                                    if prompt and fireproximityprompt then
                                        pcall(fireproximityprompt, prompt)
                                    end
                                    if Env.Remotes.CollectHerb then
                                        Env.Remotes.CollectHerb:FireServer(herbPart)
                                    end
                                    if Env.lastHerbCollectedAt > beforeCollect then
                                        break
                                    end
                                    task.wait(0.08)
                                end
                            end

                            local collected = (not herbPart.Parent) or (prompt and not prompt.Enabled) or (Env.lastHerbCollectedAt > beforeCollect)
                            if collected then
                                Env.collectedCooldowns[herbPart] = os.clock() + 30
                                Hub.Fn.logDebug("✅ เก็บสำเร็จ: " .. herbPart.Name)
                            end
                        end
                    else
                        if State.isDynamicStream and State.herbModeIndex == 2 then
                            task.wait(0.3)
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
                                if not State.isFarming or Hub.Fn.isWorldBossActive() or (State.isAutoMapEvent and Env.ActiveMapEvent) then
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
                    end
                else
                    task.wait(0.3)
                end
                task.wait(0.03)
            end
        end
        Hub.Fn.logDebug("หยุดเก็บสมุนไพรแล้ว")
        if not State.isFarmingMob and not Hub.Fn.isWorldBossActive() and not (State.isAutoMapEvent and Env.ActiveMapEvent) then
            Env.groundPlatform.CFrame = CFrame.new(0, 9999, 0)
        end
    end

    function Hub.Fn.startBrewLoop()
        if Env.Remotes.RequestHerbInventory then
            pcall(function()
                Env.Remotes.RequestHerbInventory:FireServer()
            end)
        end
        task.wait(0.3)

        while State.isAutoBrew do
            local rank = tonumber(LocalPlayer:GetAttribute("AlchemyRank")) or 0
            local xp = math.floor(tonumber(LocalPlayer:GetAttribute("AlchemyXp")) or 0)
            if UI.AlchemyStatusLabel then
                UI.AlchemyStatusLabel.Text = string.format("⚗️ Alchemy: Rank %d | XP: %d (%s)", rank, xp, tostring(State.cauldronStatus))
                UI.AlchemyStatusLabel.TextColor3 = Color3.fromRGB(220, 170, 255)
            end

            if Env.Remotes.CauldronClaim then
                Env.Remotes.CauldronClaim:FireServer()
            end
            task.wait(0.3)

            if State.cauldronStatus == "brewing" then
                if Env.Remotes.CauldronStoke and not Env.stokedThisRound then
                    if State.isAutoPerfectStoke and type(Env.currentZoneSeed) == "number" then
                        Env.stokedThisRound = true
                        local startT = Env.brewStartedAt > 0 and Env.brewStartedAt or os.clock()
                        Hub.Fn.performPerfectStoke(Env.currentZoneSeed, startT)
                    elseif not State.isAutoPerfectStoke then
                        Env.Remotes.CauldronStoke:FireServer(0.4)
                    end
                end
                task.wait(0.5)
            else
                local currentRecipe = Config.recipeList[State.recipeIndex]

                if currentRecipe.mode == "spirit" then
                    if Env.Remotes.CauldronStartSpiritBrew then
                        local spiritHerbs = {}
                        for key, count in pairs(Env.myHerbCounts) do
                            local rawId, yr = string.match(key, "^(%d+)_(%d+)$")
                            local hId = tonumber(rawId)
                            local yearNum = tonumber(yr)
                            if hId and hId >= 11 and hId <= 15 and count and count > 0 and (State.selectedMinYear == 0 or yearNum >= State.selectedMinYear) then
                                local take = math.min(count, 3 - #spiritHerbs)
                                for _ = 1, take do
                                    table.insert(spiritHerbs, { id = hId, year = yearNum })
                                end
                                if #spiritHerbs >= 3 then
                                    break
                                end
                            end
                        end
                        if #spiritHerbs == 3 then
                            Env.brewStartedAt = os.clock()
                            Env.stokedThisRound = false
                            Env.Remotes.CauldronStartSpiritBrew:FireServer(spiritHerbs)
                            Hub.Fn.logDebug("🐾 เริ่มปรุงยา Spirit Pill...")
                        end
                    end
                elseif Env.Remotes.CauldronStartBrew and currentRecipe.ingredients then
                    local herbsToBrew, canBrew = {}, true
                    for _, req in ipairs(currentRecipe.ingredients) do
                        local foundCount = 0
                        for key, count in pairs(Env.myHerbCounts) do
                            local rawId, yr = string.match(key, "^(%d+)_(%d+)$")
                            local hId = tonumber(rawId)
                            local yearNum = tonumber(yr)
                            if hId == req.id and yearNum and (State.selectedMinYear == 0 or yearNum >= State.selectedMinYear) then
                                local take = math.min(count, req.count - foundCount)
                                for _ = 1, take do
                                    table.insert(herbsToBrew, { id = hId, year = yearNum })
                                end
                                foundCount = foundCount + take
                                if foundCount >= req.count then
                                    break
                                end
                            end
                        end
                        if foundCount < req.count then
                            canBrew = false
                            break
                        end
                    end
                    if canBrew and #herbsToBrew == 3 then
                        Env.brewStartedAt = os.clock()
                        Env.stokedThisRound = false
                        Env.Remotes.CauldronStartBrew:FireServer(herbsToBrew)
                        Hub.Fn.logDebug("⚗️ เริ่มปรุงยาสูตร: " .. currentRecipe.name)
                    end
                end
                task.wait(1.5)
            end
        end

        if UI.AlchemyStatusLabel then
            UI.AlchemyStatusLabel.Text = "⚗️ Alchemy: OFF"
            UI.AlchemyStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
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
    MainFrame.Size = UDim2.new(0, 300, 0, 520)
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
    TitleLabel.Text = "Murim Hub V35 (V26 Herbs + Exam)"
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
    UI.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 2100)
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
        btn.TextSize = 12
        btn.LayoutOrder = layoutOrder
        btn.Parent = UI.ScrollFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        return btn
    end

    -- หมวด Debug, Rules Checker & Error Log
    createCategoryHeader("🛠️ DEBUG & GAME RULES CHECKER", 0)
    UI.DebugBox = Instance.new("TextBox")
    UI.DebugBox.Size = UDim2.new(1, 0, 0, 60)
    UI.DebugBox.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    UI.DebugBox.TextColor3 = Color3.fromRGB(120, 255, 140)
    UI.DebugBox.Text = "[Ready] โหลดสคริปต์ V35 สำเร็จ!"
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

    local CheckRulesBtn = createButton("🔍 Check Game Rules & Updates (เทียบแพตช์)", Color3.fromRGB(45, 125, 110), 2)
    Hub.Fn.connect(CheckRulesBtn.MouseButton1Click, function()
        local reportText, rawSnapshot, snapshotFile = Hub.Fn.inspectGameRules()
        showDebugErrorGui(
            "🔍 Game Rules, Remotes & Patch Diff",
            reportText,
            "💾 Save Snapshot",
            function(btn)
                Env.lastRulesSnapshot = rawSnapshot
                if type(writefile) == "function" then
                    pcall(writefile, snapshotFile, rawSnapshot)
                end
                btn.Text = "✅ Saved!"
                task.wait(1.5)
                btn.Text = "💾 Save Snapshot"
            end
        )
    end)

    local OpenErrGuiBtn = createButton("📋 เปิดหน้าต่าง Error / Copy Log", Color3.fromRGB(70, 95, 130), 3)
    Hub.Fn.connect(OpenErrGuiBtn.MouseButton1Click, function()
        showDebugErrorGui("⚠️ Murim Hub Log & Last Error", "Last Error:\n" .. tostring(Env.lastErrorText) .. "\n\nRecent Logs:\n" .. UI.DebugBox.Text)
    end)

    -- หมวด Combat, World Boss & Sect Clash Event
    createCategoryHeader("⚔️ COMBAT, WORLD BOSS & EVENTS", 4)
    local RefreshMobListBtn = createButton("🔄 สแกนรายชื่อมอนสเตอร์ในแมพ", Color3.fromRGB(40, 90, 140), 5)

    UI.MobListContainer = Instance.new("Frame")
    UI.MobListContainer.Size = UDim2.new(1, 0, 0, 0)
    UI.MobListContainer.BackgroundTransparency = 1
    UI.MobListContainer.LayoutOrder = 6
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
    UI.TargetHPLabel.Text = "🎯 Target: Standby (รอการทำงาน)"
    UI.TargetHPLabel.Font = Enum.Font.SourceSansBold
    UI.TargetHPLabel.TextSize = 11
    UI.TargetHPLabel.LayoutOrder = 7
    UI.TargetHPLabel.Parent = UI.ScrollFrame
    Instance.new("UICorner", UI.TargetHPLabel).CornerRadius = UDim.new(0, 5)

    local ToggleMobBtn = createButton("⚔️ Start Auto Farm Monsters", Color3.fromRGB(180, 50, 50), 8)
    local ToggleTurboBtn = createButton("⚡ Turbo Speed Attack (ตีโคตรเร็ว): ON", Color3.fromRGB(220, 120, 20), 9)
    local ToggleAoEBtn = createButton("💥 Multi-Hit AoE (ตีกลุ่มพร้อมกัน): ON", Color3.fromRGB(160, 60, 160), 10)
    local ToggleSkillsBtn = createButton("🔥 Auto Spam Skills (Z,X,C,V)", Color3.fromRGB(200, 80, 30), 11)
    local ToggleOffsetBtn = createButton("📍 Distance Offset: " .. Config.farmOffsets[State.farmOffsetIndex].text, Color3.fromRGB(80, 80, 120), 12)

    UI.WorldBossStatusLabel = Instance.new("TextLabel")
    UI.WorldBossStatusLabel.Size = UDim2.new(1, 0, 0, 22)
    UI.WorldBossStatusLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    UI.WorldBossStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    UI.WorldBossStatusLabel.Text = "🐉 World Boss: OFF"
    UI.WorldBossStatusLabel.Font = Enum.Font.SourceSansBold
    UI.WorldBossStatusLabel.TextSize = 11
    UI.WorldBossStatusLabel.LayoutOrder = 13
    UI.WorldBossStatusLabel.Parent = UI.ScrollFrame
    Instance.new("UICorner", UI.WorldBossStatusLabel).CornerRadius = UDim.new(0, 5)

    local ToggleWorldBossBtn = createButton("🐉 Auto World Boss (แทรกคิวอัตโนมัติ): OFF", Color3.fromRGB(100, 100, 100), 14)

    UI.EventStatusLabel = Instance.new("TextLabel")
    UI.EventStatusLabel.Size = UDim2.new(1, 0, 0, 22)
    UI.EventStatusLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    UI.EventStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    UI.EventStatusLabel.Text = "🚩 Event: OFF"
    UI.EventStatusLabel.Font = Enum.Font.SourceSansBold
    UI.EventStatusLabel.TextSize = 11
    UI.EventStatusLabel.LayoutOrder = 15
    UI.EventStatusLabel.Parent = UI.ScrollFrame
    Instance.new("UICorner", UI.EventStatusLabel).CornerRadius = UDim.new(0, 5)

    local ToggleMapEventBtn = createButton("🚩 Auto Sect Clash Event: OFF", Color3.fromRGB(100, 100, 100), 16)

    Hub.Fn.connect(RefreshMobListBtn.MouseButton1Click, Hub.Fn.rebuildMobListUI)
    Hub.Fn.connect(ToggleTurboBtn.MouseButton1Click, function()
        State.isTurboAttack = not State.isTurboAttack
        ToggleTurboBtn.Text = State.isTurboAttack and "⚡ Turbo Speed Attack (ตีโคตรเร็ว): ON" or "⚡ Turbo Speed Attack (ตีโคตรเร็ว): OFF"
        ToggleTurboBtn.BackgroundColor3 = State.isTurboAttack and Color3.fromRGB(220, 120, 20) or Color3.fromRGB(100, 100, 100)
    end)
    Hub.Fn.connect(ToggleAoEBtn.MouseButton1Click, function()
        State.isAoEHit = not State.isAoEHit
        ToggleAoEBtn.Text = State.isAoEHit and "💥 Multi-Hit AoE (ตีกลุ่มพร้อมกัน): ON" or "💥 Multi-Hit AoE (ตีกลุ่มพร้อมกัน): OFF"
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
        ToggleOffsetBtn.Text = "📍 Distance Offset: " .. Config.farmOffsets[State.farmOffsetIndex].text
    end)
    Hub.Fn.connect(ToggleWorldBossBtn.MouseButton1Click, function()
        State.isAutoWorldBoss = not State.isAutoWorldBoss
        ToggleWorldBossBtn.Text = State.isAutoWorldBoss and "🐉 Auto World Boss (แทรกคิวอัตโนมัติ): ON" or "🐉 Auto World Boss (แทรกคิวอัตโนมัติ): OFF"
        ToggleWorldBossBtn.BackgroundColor3 = State.isAutoWorldBoss and Color3.fromRGB(185, 55, 55) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startWorldBossLoop", State.isAutoWorldBoss, Hub.Fn.startWorldBossLoop)
    end)
    Hub.Fn.connect(ToggleMapEventBtn.MouseButton1Click, function()
        State.isAutoMapEvent = not State.isAutoMapEvent
        ToggleMapEventBtn.Text = State.isAutoMapEvent and "🚩 Auto Sect Clash Event: ON" or "🚩 Auto Sect Clash Event: OFF"
        ToggleMapEventBtn.BackgroundColor3 = State.isAutoMapEvent and Color3.fromRGB(190, 60, 70) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startMapEventLoop", State.isAutoMapEvent, Hub.Fn.startMapEventLoop)
    end)

    -- หมวด Cultivation, Soul Stars & Gathering
    createCategoryHeader("✨ CULTIVATION & SOUL STARS (1-10)", 17)
    local ToggleCultivateBtn = createButton("🧘 Start Auto Meditate (นั่งสมาธิ/บ่มเพาะ)", Color3.fromRGB(50, 140, 180), 18)
    local ToggleBreakthroughBtn = createButton("🌀 Auto Breakthrough (ทะลวงขั้น): OFF", Color3.fromRGB(100, 100, 100), 19)
    local ToggleBodyBreakthroughBtn = createButton("💪 Auto Body Breakthrough (ทะลวงขั้นร่างกาย): OFF", Color3.fromRGB(100, 100, 100), 20)
    local TogglePushupBtn = createButton("🏋️‍♂️ Start Auto Pushup (วิดพื้น/ฝึกร่างกาย): OFF", Color3.fromRGB(100, 100, 100), 21)
    local ToggleTribulationBtn = createButton("⚡ Auto Tribulation (ดูดซับทัณฑ์สวรรค์): OFF", Color3.fromRGB(100, 100, 100), 22)

    UI.SoulStatusLabel = Instance.new("TextLabel")
    UI.SoulStatusLabel.Size = UDim2.new(1, 0, 0, 22)
    UI.SoulStatusLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    UI.SoulStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    UI.SoulStatusLabel.Text = "👻 Soul: OFF"
    UI.SoulStatusLabel.Font = Enum.Font.SourceSansBold
    UI.SoulStatusLabel.TextSize = 11
    UI.SoulStatusLabel.LayoutOrder = 23
    UI.SoulStatusLabel.Parent = UI.ScrollFrame
    Instance.new("UICorner", UI.SoulStatusLabel).CornerRadius = UDim.new(0, 5)

    local ToggleSoulBtn = createButton("👻 Auto Soul Cultivate & Catch (ปั๊มดาววิญญาณ): OFF", Color3.fromRGB(100, 100, 100), 24)
    local ToggleOrbBtn = createButton("🔮 Start Auto Cultivation Orb", Color3.fromRGB(120, 80, 180), 25)
    local ZoneExpanseBtn = createButton("🌌 Zone: Celestial Expanse", Color3.fromRGB(80, 60, 160), 26)

    createCategoryHeader("🌿 GATHERING (V26 LOGIC + CHASE x2)", 27)
    local ToggleFarmBtn = createButton("🌿 Start Auto Herbs (Smart All-Map + Chase x2)", Color3.fromRGB(40, 160, 80), 28)
    local ToggleHerbModeBtn = createButton("🌟 Mode: " .. Config.herbModes[State.herbModeIndex], Color3.fromRGB(180, 130, 30), 29)
    local ToggleStreamBtn = createButton("🗺️ Dynamic Map Streamer: ON", Color3.fromRGB(45, 135, 175), 30)

    -- หมวด Alchemy + Perfect Stoke + Auto Exam + วาร์ปคนสอบ
    createCategoryHeader("⚗️ ALCHEMY (11 สูตร + PERFECT STOKE + EXAM)", 31)
    UI.AlchemyStatusLabel = Instance.new("TextLabel")
    UI.AlchemyStatusLabel.Size = UDim2.new(1, 0, 0, 22)
    UI.AlchemyStatusLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    UI.AlchemyStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    UI.AlchemyStatusLabel.Text = "⚗️ Alchemy: OFF"
    UI.AlchemyStatusLabel.Font = Enum.Font.SourceSansBold
    UI.AlchemyStatusLabel.TextSize = 11
    UI.AlchemyStatusLabel.LayoutOrder = 32
    UI.AlchemyStatusLabel.Parent = UI.ScrollFrame
    Instance.new("UICorner", UI.AlchemyStatusLabel).CornerRadius = UDim.new(0, 5)

    local ToggleRecipeBtn = createButton("💊 Recipe: " .. Config.recipeList[1].name, Color3.fromRGB(70, 120, 170), 33)
    local ToggleYearBtn = createButton("🎯 Min Herb Year: Any (All)", Color3.fromRGB(70, 70, 110), 34)
    local ToggleBrewBtn = createButton("⚗️ Start Auto Brew Pills", Color3.fromRGB(140, 50, 140), 35)
    local TogglePerfectStokeBtn = createButton("🔥 Perfect Stoke (คำนวณไฟอัตโนมัติ): ON", Color3.fromRGB(200, 110, 30), 36)
    local RefineTier6Btn = createButton("✨ Refine Tier 6 Pill (Rank 9 Alchemist)", Color3.fromRGB(165, 110, 40), 37)

    UI.ExamStatusLabel = Instance.new("TextLabel")
    UI.ExamStatusLabel.Size = UDim2.new(1, 0, 0, 22)
    UI.ExamStatusLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    UI.ExamStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    UI.ExamStatusLabel.Text = "🎓 Exam: OFF"
    UI.ExamStatusLabel.Font = Enum.Font.SourceSansBold
    UI.ExamStatusLabel.TextSize = 11
    UI.ExamStatusLabel.LayoutOrder = 38
    UI.ExamStatusLabel.Parent = UI.ScrollFrame
    Instance.new("UICorner", UI.ExamStatusLabel).CornerRadius = UDim.new(0, 5)

    local TpExaminerBtn = createButton("🚀 วาร์ปไปหาคนสอบ (Grandmaster Danxin)", Color3.fromRGB(50, 115, 175), 39)
    local ToggleExamBtn = createButton("🎓 Auto Alchemy Exam (สอบเลื่อนขั้นอัตโนมัติ): OFF", Color3.fromRGB(100, 100, 100), 40)

    createCategoryHeader("⚙️ SYSTEM & REWARDS", 41)
    local ClaimRewardBtn = createButton("🎁 Claim Daily & Cauldron", Color3.fromRGB(50, 150, 150), 42)
    local DestroyBtn = createButton("🛑 Destroy Script & Stop", Color3.fromRGB(180, 40, 40), 43)

    Hub.Fn.connect(ToggleCultivateBtn.MouseButton1Click, function()
        State.isAutoCultivate = not State.isAutoCultivate
        ToggleCultivateBtn.Text = State.isAutoCultivate and "⏸ Stop Auto Meditate" or "🧘 Start Auto Meditate (นั่งสมาธิ/บ่มเพาะ)"
        ToggleCultivateBtn.BackgroundColor3 = State.isAutoCultivate and Color3.fromRGB(200, 120, 30) or Color3.fromRGB(50, 140, 180)
        Hub.Fn.setWorker("startCultivateLoop", State.isAutoCultivate, Hub.Fn.startCultivateLoop)
    end)
    Hub.Fn.connect(ToggleBreakthroughBtn.MouseButton1Click, function()
        State.isAutoBreakthrough = not State.isAutoBreakthrough
        ToggleBreakthroughBtn.Text = State.isAutoBreakthrough and "🌀 Auto Breakthrough (ทะลวงขั้น): ON" or "🌀 Auto Breakthrough (ทะลวงขั้น): OFF"
        ToggleBreakthroughBtn.BackgroundColor3 = State.isAutoBreakthrough and Color3.fromRGB(140, 60, 180) or Color3.fromRGB(100, 100, 100)
    end)
    Hub.Fn.connect(ToggleBodyBreakthroughBtn.MouseButton1Click, function()
        State.isAutoBodyBreakthrough = not State.isAutoBodyBreakthrough
        ToggleBodyBreakthroughBtn.Text = State.isAutoBodyBreakthrough and "💪 Auto Body Breakthrough (ทะลวงขั้นร่างกาย): ON" or "💪 Auto Body Breakthrough (ทะลวงขั้นร่างกาย): OFF"
        ToggleBodyBreakthroughBtn.BackgroundColor3 = State.isAutoBodyBreakthrough and Color3.fromRGB(160, 80, 200) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startBodyBreakthroughLoop", State.isAutoBodyBreakthrough, Hub.Fn.startBodyBreakthroughLoop)
    end)
    Hub.Fn.connect(TogglePushupBtn.MouseButton1Click, function()
        State.isAutoPushup = not State.isAutoPushup
        TogglePushupBtn.Text = State.isAutoPushup and "🏋️‍♂️ Start Auto Pushup (วิดพื้น/ฝึกร่างกาย): ON" or "🏋️‍♂️ Start Auto Pushup (วิดพื้น/ฝึกร่างกาย): OFF"
        TogglePushupBtn.BackgroundColor3 = State.isAutoPushup and Color3.fromRGB(70, 180, 140) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startPushupLoop", State.isAutoPushup, Hub.Fn.startPushupLoop)
    end)
    Hub.Fn.connect(ToggleTribulationBtn.MouseButton1Click, function()
        State.isAutoTribulation = not State.isAutoTribulation
        ToggleTribulationBtn.Text = State.isAutoTribulation and "⚡ Auto Tribulation (ดูดซับทัณฑ์สวรรค์): ON" or "⚡ Auto Tribulation (ดูดซับทัณฑ์สวรรค์): OFF"
        ToggleTribulationBtn.BackgroundColor3 = State.isAutoTribulation and Color3.fromRGB(220, 160, 40) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startTribulationLoop", State.isAutoTribulation, Hub.Fn.startTribulationLoop)
    end)
    Hub.Fn.connect(ToggleSoulBtn.MouseButton1Click, function()
        State.isAutoSoul = not State.isAutoSoul
        ToggleSoulBtn.Text = State.isAutoSoul and "👻 Auto Soul Cultivate & Catch (ปั๊มดาววิญญาณ): ON" or "👻 Auto Soul Cultivate & Catch (ปั๊มดาววิญญาณ): OFF"
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
    Hub.Fn.connect(ToggleFarmBtn.MouseButton1Click, function()
        State.isFarming = not State.isFarming
        ToggleFarmBtn.Text = State.isFarming and "⏸ Stop Auto Herbs" or "🌿 Start Auto Herbs (Smart All-Map + Chase x2)"
        ToggleFarmBtn.BackgroundColor3 = State.isFarming and Color3.fromRGB(200, 120, 30) or Color3.fromRGB(40, 160, 80)
        Hub.Fn.setWorker("startFarmLoop", State.isFarming, Hub.Fn.startFarmLoop)
    end)
    Hub.Fn.connect(ToggleHerbModeBtn.MouseButton1Click, function()
        State.herbModeIndex = (State.herbModeIndex % #Config.herbModes) + 1
        ToggleHerbModeBtn.Text = "🌟 Mode: " .. Config.herbModes[State.herbModeIndex]
    end)
    Hub.Fn.connect(ToggleStreamBtn.MouseButton1Click, function()
        State.isDynamicStream = not State.isDynamicStream
        ToggleStreamBtn.Text = State.isDynamicStream and "🗺️ Dynamic Map Streamer: ON" or "🗺️ Dynamic Map Streamer: OFF"
        ToggleStreamBtn.BackgroundColor3 = State.isDynamicStream and Color3.fromRGB(45, 135, 175) or Color3.fromRGB(100, 100, 100)
        Hub.Fn.setWorker("startDynamicStreamLoop", State.isDynamicStream, Hub.Fn.startDynamicStreamLoop)
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
    Hub.Fn.connect(TogglePerfectStokeBtn.MouseButton1Click, function()
        State.isAutoPerfectStoke = not State.isAutoPerfectStoke
        TogglePerfectStokeBtn.Text = State.isAutoPerfectStoke and "🔥 Perfect Stoke (คำนวณไฟอัตโนมัติ): ON" or "🔥 Perfect Stoke (คำนวณไฟอัตโนมัติ): OFF"
        TogglePerfectStokeBtn.BackgroundColor3 = State.isAutoPerfectStoke and Color3.fromRGB(200, 110, 30) or Color3.fromRGB(100, 100, 100)
    end)
    Hub.Fn.connect(RefineTier6Btn.MouseButton1Click, function()
        if Env.Remotes.CauldronStartRefine then
            Env.Remotes.CauldronStartRefine:FireServer()
            Hub.Fn.logDebug("✨ ส่งคำสั่งกลั่นยา Tier 6 (CauldronStartRefine)")
        end
    end)
    Hub.Fn.connect(TpExaminerBtn.MouseButton1Click, function()
        local _, hrp = Hub.Fn.getCharacter()
        if hrp then
            local examiner = workspace:FindFirstChild("AlchemyExaminer")
            local targetPos = Vector3.new(-116.0, 12.0, 148.0)
            if examiner then
                local pp = examiner:IsA("BasePart") and examiner or examiner:FindFirstChildWhichIsA("BasePart")
                if pp then
                    targetPos = pp.Position + Vector3.new(0, 2, 3)
                end
            end
            Hub.Fn.safeTeleport(hrp, CFrame.new(targetPos))
            Hub.Fn.logDebug("🚀 วาร์ปไปหา Grandmaster Danxin เรียบร้อย")
        end
    end)
    Hub.Fn.connect(ToggleExamBtn.MouseButton1Click, function()
        State.isAutoAlchemyExam = not State.isAutoAlchemyExam
        ToggleExamBtn.Text = State.isAutoAlchemyExam and "🎓 Auto Alchemy Exam (สอบเลื่อนขั้นอัตโนมัติ): ON" or "🎓 Auto Alchemy Exam (สอบเลื่อนขั้นอัตโนมัติ): OFF"
        ToggleExamBtn.BackgroundColor3 = State.isAutoAlchemyExam and Color3.fromRGB(55, 145, 95) or Color3.fromRGB(100, 100, 100)
        if UI.ExamStatusLabel then
            UI.ExamStatusLabel.Text = State.isAutoAlchemyExam and "🎓 Exam: Standby (กำลังเปิดหน้าต่างสอบ...)" or "🎓 Exam: OFF"
            UI.ExamStatusLabel.TextColor3 = State.isAutoAlchemyExam and Color3.fromRGB(130, 235, 160) or Color3.fromRGB(170, 170, 170)
        end
        if State.isAutoAlchemyExam and Env.Remotes.AlchemyExam then
            Env.Remotes.AlchemyExam:FireServer("open")
        end
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
    Hub.Fn.logDebug("พร้อมใช้งาน V35! (คืนระบบเก็บสมุนไพร V26 เต็มรูปแบบ + Chase x2 + Exam)")
end