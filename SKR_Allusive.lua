local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function getMobileScale()
    local viewport = workspace.CurrentCamera.ViewportSize
    local isMobile = UIS.TouchEnabled and viewport.X < 1024
    if isMobile then
        return 0.8
    end
    return 1
end

local scale = getMobileScale()

local SAKURA_DARK = Color3.fromRGB(199, 21, 133)
local SAKURA_LIGHT = Color3.fromRGB(255, 154, 200)
local SAKURA_BRIGHT = Color3.fromRGB(255, 90, 165)
local DARK_PLUM = Color3.fromRGB(20, 0, 15)
local DARK_PLUM_TOPBAR = Color3.fromRGB(20, 0, 15)
local DARK_PLUM_OVERLAP = Color3.fromRGB(20, 0, 15)

local BASE_W, BASE_H = 580, 360
local BASE_MINI_W, BASE_MINI_H = 135, 42

local FullSize = UDim2.new(0, BASE_W * scale, 0, BASE_H * scale)
local MiniSize = UDim2.new(0, BASE_MINI_W * scale, 0, BASE_MINI_H * scale)

local function s(n)
    return math.round(n * scale)
end

local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

local function Round(inst, radius)
    return New("UICorner", {CornerRadius = UDim.new(0, radius)}, inst)
end

local function Stroke(inst, thickness, transparency)
    return New("UIStroke", {
        Color = SAKURA_BRIGHT,
        Thickness = thickness or 1.6,
        Transparency = transparency or 0.05,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inst)
end

local function Tween(inst, props, dur, style)
    local tw = TweenService:Create(inst, TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quart), props)
    tw:Play()
    return tw
end

local CONFIG_FOLDER = "SKRUI/AllusiveCore"

local Config = setmetatable({
    save = function(self, file_name, data)
        local ok = pcall(function()
            if not isfolder(CONFIG_FOLDER) then
                makefolder(CONFIG_FOLDER)
            end
            writefile(CONFIG_FOLDER .. "/" .. file_name .. ".json", HttpService:JSONEncode(data))
        end)
        return ok
    end,
    load = function(self, file_name)
        local result
        pcall(function()
            if isfile(CONFIG_FOLDER .. "/" .. file_name .. ".json") then
                result = HttpService:JSONDecode(readfile(CONFIG_FOLDER .. "/" .. file_name .. ".json"))
            end
        end)
        if not result then
            result = {_flags = {}, _keybinds = {}}
        end
        if not result._flags then result._flags = {} end
        if not result._keybinds then result._keybinds = {} end
        return result
    end,
}, {})

local Library = {}
Library.__index = Library

local function addAllusiveAliases(tbl, fn)
    -- Tạo cả 2 dạng: CamelCase và snake_case
    local names = {
        ["CreateTab"] = "create_tab",
        ["CreateModule"] = "create_module",
        ["CreateToggle"] = "create_toggle",
        ["CreateButton"] = "create_button",
        ["CreateSlider"] = "create_slider",
        ["CreateDropdown"] = "create_dropdown",
        ["CreateTextbox"] = "create_textbox",
        ["CreateKeybind"] = "create_keybind",
        ["CreateLabel"] = "create_label",
        ["CreateParagraph"] = "create_paragraph",
        ["CreateDivider"] = "create_divider",
    }
    for camel, snake in pairs(names) do
        tbl[camel] = fn
        tbl[snake] = fn
    end
end

function Library.new(config)
    return Library:CreateWindow(config)
end

function Library:CreateWindow(config)
    config = config or {}
    local Window = setmetatable({}, Library)
    Window.Tabs = {}
    Window.FirstTab = nil
    Window._config = Config:load(tostring(config.ConfigId or game.GameId))
    Window._choosingKeybind = false

    local PrimaryColor = config.PrimaryColor or SAKURA_LIGHT
    local PrimaryDark = Color3.new(PrimaryColor.R * 0.4, PrimaryColor.G * 0.4, PrimaryColor.B * 0.4)
    local PrimaryBright = Color3.new(
        math.min(PrimaryColor.R * 1.3, 1),
        math.min(PrimaryColor.G * 1.3, 1),
        math.min(PrimaryColor.B * 1.3, 1)
    )

    local ParentUI
    local success, coregui = pcall(function() return game:GetService("CoreGui") end)
    if success and coregui then
        ParentUI = coregui
    else
        ParentUI = LocalPlayer:WaitForChild("PlayerGui")
    end

    local OldUI = ParentUI:FindFirstChild("SKR_UI")
    if OldUI then OldUI:Destroy() end

    local ScreenGui = New("ScreenGui", {
        Name = "SKR_UI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, ParentUI)

    local MainFrame = New("Frame", {
        Name = "MainFrame",
        BackgroundColor3 = DARK_PLUM,
        BackgroundTransparency = 0.15,
        Position = UDim2.new(0.5, -s(BASE_W / 2), 0.5, -s(BASE_H / 2)),
        Size = FullSize,
        BorderSizePixel = 0,
        Active = true,
        ClipsDescendants = false,
    }, ScreenGui)
    Round(MainFrame, s(14))
    Stroke(MainFrame, 1.8, 0.05)

    local Topbar = New("Frame", {
        Name = "Topbar",
        BackgroundColor3 = DARK_PLUM_TOPBAR,
        BackgroundTransparency = 0.15,
        Size = UDim2.new(1, 0, 0, s(42)),
        BorderSizePixel = 0,
    }, MainFrame)
    Round(Topbar, s(14))

    local Title = New("TextLabel", {
        Text = config.Title or config.title or "SKR Free",
        TextColor3 = Color3.fromRGB(255, 225, 235),
        Font = Enum.Font.GothamBold,
        TextSize = s(15),
        Size = UDim2.new(0, s(140), 1, 0),
        Position = UDim2.new(0, s(45), 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
    }, Topbar)

    local Shimmer = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 225, 235)),
            ColorSequenceKeypoint.new(0.5, PrimaryColor),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 225, 235)),
        }),
    }, Title)

    task.spawn(function()
        while ScreenGui.Parent do
            local tween = TweenService:Create(Shimmer, TweenInfo.new(2, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
            Shimmer.Offset = Vector2.new(-1, 0)
            tween:Play()
            tween.Completed:Wait()
        end
    end)

    local frames = {
        "rbxassetid://102369650294802",
        "rbxassetid://131279032025741"
    }

    local MinBtn = New("ImageButton", {
        Name = "MinBtn",
        BackgroundColor3 = DARK_PLUM,
        BackgroundTransparency = 0,
        Size = UDim2.new(0, s(26), 0, s(26)),
        Position = UDim2.new(0, s(9), 0.5, -s(13)),
        ZIndex = 3,
        Image = frames[1],
        ScaleType = Enum.ScaleType.Fit,
    }, Topbar)
    Round(MinBtn, s(8))

    task.spawn(function()
        local direction = 1
        local index = 1
        while MinBtn and MinBtn.Parent do
            MinBtn.Image = frames[index]
            if index >= #frames then
                direction = -1
            elseif index <= 1 then
                direction = 1
            end
            index = index + direction
            task.wait(0.1)
        end
    end)

    local TopOverlap = New("Frame", {
        Name = "TopOverlap",
        BackgroundColor3 = DARK_PLUM_OVERLAP,
        BackgroundTransparency = 0.15,
        Size = UDim2.new(1, 0, 0, s(6)),
        Position = UDim2.new(0, 0, 0, s(36)),
        BorderSizePixel = 0,
        ZIndex = 0,
    }, MainFrame)

    local dragging, dragStart, startPos, dragTouchObject
    Topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position; dragTouchObject = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input == dragTouchObject then
            local delta = input.Position - dragStart
            local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            Tween(MainFrame, {Position = targetPos}, 0.4, Enum.EasingStyle.Quart)
        end
    end)

    local SidebarWidth = s(120)
    local Container = New("Frame", {
        Size = UDim2.new(1, -2, 1, -s(44)),
        Position = UDim2.new(0, 1, 0, s(43)),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
    }, MainFrame)

    local Sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, SidebarWidth, 1, 0),
        BackgroundTransparency = 1,
    }, Container)
    New("UIListLayout", {
        Padding = UDim.new(0, s(5)),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, Sidebar)
    New("UIPadding", {PaddingTop = UDim.new(0, s(10))}, Sidebar)

    local Pages = New("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, -SidebarWidth, 1, -2),
        Position = UDim2.new(0, SidebarWidth, 0, 1),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
    }, Container)

    New("Frame", {
        BackgroundColor3 = PrimaryColor,
        BackgroundTransparency = 0.8,
        Position = UDim2.new(0, SidebarWidth, 0, s(10)),
        Size = UDim2.new(0, 1, 1, -s(20)),
        BorderSizePixel = 0,
    }, Container)

    local isMainOpen = true
    MinBtn.MouseButton1Click:Connect(function()
        isMainOpen = not isMainOpen
        Tween(MainFrame, {Size = isMainOpen and FullSize or MiniSize}, 0.5)
        Container.Visible = isMainOpen
        TopOverlap.Visible = isMainOpen
    end)

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    Window.ScreenGui = ScreenGui
    Window.MainFrame = MainFrame
    Window.Sidebar = Sidebar
    Window.Pages = Pages

    function Window:SaveConfig()
        return Config:save(tostring(config.ConfigId or game.GameId), self._config)
    end

    function Window:GetFlag(flag, default)
        local v = self._config._flags[flag]
        if v == nil then return default end
        return v
    end

    function Window:SetFlag(flag, value)
        if not flag then return end
        self._config._flags[flag] = value
        self:SaveConfig()
    end

    -- ===== ALLUSIVE-COMPAT: create_tab / CreateTab =====
    function Window:create_tab(title, icon)
        return self:Tab({Title = title, Icon = icon})
    end
    Window.CreateTab = Window.create_tab

    function Window:Tab(tconfig)
        tconfig = tconfig or {}
        local Tab = {}
        local tabName = tconfig.Title or "Tab"
        local imageId = tconfig.Icon or "rbxassetid://76499042599127"

        local TabBtn = New("TextButton", {
            Name = tabName .. "_Tab",
            Size = UDim2.new(0.9, 0, 0, s(35)),
            BackgroundColor3 = Color3.fromRGB(50, 10, 40),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = #Window.Tabs + 1,
        }, Sidebar)
        Round(TabBtn, s(6))

        local Indicator = New("Frame", {
            Name = "Indicator",
            Size = UDim2.new(0, s(2), 0, s(16)),
            Position = UDim2.new(0, s(6), 0.5, -s(8)),
            BackgroundColor3 = PrimaryColor,
            BorderSizePixel = 0,
            Visible = false,
        }, TabBtn)
        Round(Indicator, s(999))

        local TabIcon = New("ImageLabel", {
            Size = UDim2.new(0, s(18), 0, s(18)),
            Position = UDim2.new(0, s(16), 0.5, -s(9)),
            BackgroundTransparency = 1,
            Image = imageId,
            ImageColor3 = PrimaryColor,
        }, TabBtn)

        local TabText = New("TextLabel", {
            Text = tabName,
            Size = UDim2.new(1, -s(40), 1, 0),
            Position = UDim2.new(0, s(40), 0, 0),
            TextColor3 = PrimaryColor,
            Font = Enum.Font.GothamBold,
            TextSize = s(11),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, TabBtn)

        local function UpdateTabVisuals(selected)
            local accent = selected and PrimaryColor or Color3.fromRGB(180, 100, 150)
            local bg = selected and PrimaryDark or Color3.fromRGB(50, 10, 40)
            Tween(TabBtn, {BackgroundColor3 = bg}, 0.2)
            Tween(TabIcon, {ImageColor3 = accent}, 0.2)
            Tween(TabText, {TextColor3 = accent}, 0.2)
            Indicator.Visible = selected
        end

        local Page = New("Frame", {
            Name = tabName .. "_Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            ClipsDescendants = false,
        }, Pages)

        local LeftCol = New("ScrollingFrame", {
            Name = "Left",
            Size = UDim2.new(0.5, -s(12), 1, 0),
            Position = UDim2.new(0, s(6), 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ClipsDescendants = false,
        }, Page)

        local RightCol = New("ScrollingFrame", {
            Name = "Right",
            Size = UDim2.new(0.5, -s(12), 1, 0),
            Position = UDim2.new(0.5, s(6), 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ClipsDescendants = false,
        }, Page)

        for _, col in ipairs({LeftCol, RightCol}) do
            New("UIListLayout", {
                Padding = UDim.new(0, s(12)),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, col)
            New("UIPadding", {PaddingTop = UDim.new(0, s(15))}, col)
        end

        TabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(Window.Tabs) do
                v.Page.Visible = false
                v.Update(false)
            end
            Page.Visible = true
            UpdateTabVisuals(true)
        end)

        Window.Tabs[#Window.Tabs + 1] = {Btn = TabBtn, Page = Page, Update = UpdateTabVisuals, Name = tabName}

        if not Window.FirstTab then
            Window.FirstTab = tabName
            Page.Visible = true
            UpdateTabVisuals(true)
        end

        local function GetSide(section)
            if section and tostring(section):lower() == "right" then return RightCol end
            return LeftCol
        end

        -- ===== MODULE (container) helpers =====
        local function CreateModule(mConfig)
            mConfig = mConfig or {}
            local parent = GetSide(mConfig.Section)
            local HEADER_H, DIVIDER_H = s(50), s(9)
            local MODULE_W = 0.92
            local flag = mConfig.Flag

            local ModuleFrame = New("Frame", {
                BackgroundColor3 = Color3.fromRGB(60, 15, 45),
                BackgroundTransparency = 0.3,
                Size = UDim2.new(MODULE_W, 0, 0, HEADER_H),
                ClipsDescendants = false,
            }, parent)
            Round(ModuleFrame, s(16))
            Stroke(ModuleFrame, 1.4, 0.15)

            local Header = New("Frame", {
                Size = UDim2.new(MODULE_W, 0, 0, HEADER_H),
                BackgroundTransparency = 1,
                ClipsDescendants = false,
            }, ModuleFrame)

            local titleWidth = s(150)

            New("TextLabel", {
                Text = " " .. (mConfig.Title or "Module"),
                Size = UDim2.new(0, titleWidth, 0, s(20)),
                Position = UDim2.new(0, s(10), 0, s(6)),
                TextColor3 = Color3.fromRGB(255, 200, 220),
                Font = Enum.Font.GothamBold,
                TextSize = s(14),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Header)

            New("TextLabel", {
                Text = " " .. (mConfig.Description or ""),
                Size = UDim2.new(0, titleWidth, 0, s(15)),
                Position = UDim2.new(0, s(10), 0, s(26)),
                TextColor3 = PrimaryColor,
                Font = Enum.Font.Gotham,
                TextSize = s(10),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Header)

            local KeybindBtn = New("TextButton", {
                Size = UDim2.new(0, s(46), 0, s(20)),
                Position = UDim2.new(1, -s(84), 0, s(10)),
                BackgroundColor3 = Color3.fromRGB(100, 30, 75),
                AutoButtonColor = false,
                Text = "None",
                TextColor3 = PrimaryColor,
                Font = Enum.Font.Gotham,
                TextSize = s(10),
                ZIndex = 10,
            }, Header)
            Round(KeybindBtn, s(6))

            local ToggleBg = New("Frame", {
                Size = UDim2.new(0, s(34), 0, s(18)),
                Position = UDim2.new(1, -s(46), 0, s(11)),
                BackgroundColor3 = Color3.fromRGB(100, 30, 75),
                ZIndex = 5,
            }, Header)
            Round(ToggleBg, s(999))
            local ToggleDot = New("Frame", {
                Size = UDim2.new(0, s(14), 0, s(14)),
                Position = UDim2.new(0, s(2), 0.5, -s(7)),
                BackgroundColor3 = Color3.fromRGB(180, 100, 150),
            }, ToggleBg)
            Round(ToggleDot, s(999))

            New("Frame", {
                Size = UDim2.new(1, -s(20), 0, 1),
                Position = UDim2.new(0, s(10), 0, HEADER_H),
                BackgroundColor3 = PrimaryColor,
                BackgroundTransparency = 0.6,
                BorderSizePixel = 0,
            }, ModuleFrame)

            local Options = New("Frame", {
                Name = "Options",
                Size = UDim2.new(1, -s(20), 0, 0),
                Position = UDim2.new(0, s(10), 0, HEADER_H + DIVIDER_H),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = false,
                Visible = true,
            }, ModuleFrame)

            local Canvas = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
            }, Options)

            local OptLayout = New("UIListLayout", {
                Padding = UDim.new(0, s(8)),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, Canvas)

            local ModuleObj = {
                Options = Options,
                Canvas = Canvas,
                Enabled = false,
                Flag = flag,
                _callback = mConfig.Callback,
                Window = Window,
            }

            local function recalc(animate)
                local target
                if ModuleObj.Enabled then
                    target = HEADER_H + DIVIDER_H + OptLayout.AbsoluteContentSize.Y + s(6)
                else
                    target = HEADER_H
                end
                if animate then
                    Tween(ModuleFrame, {Size = UDim2.new(MODULE_W, 0, 0, target)}, 0.3, Enum.EasingStyle.Quart)
                else
                    ModuleFrame.Size = UDim2.new(MODULE_W, 0, 0, target)
                end
            end

            local function updateCanvas(show, animate)
                local targetHeight = show and OptLayout.AbsoluteContentSize.Y or 0
                if animate then
                    Tween(Canvas, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.25, Enum.EasingStyle.Quart)
                else
                    Canvas.Size = UDim2.new(1, 0, 0, targetHeight)
                end
            end

            OptLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if ModuleObj.Enabled then
                    updateCanvas(true, true)
                end
                recalc(ModuleObj.Enabled)
            end)

            local function setEnabled(state, fromUser)
                ModuleObj.Enabled = state

                Tween(ToggleDot, {
                    Position = state and UDim2.new(0, s(18), 0.5, -s(7)) or UDim2.new(0, s(2), 0.5, -s(7)),
                    BackgroundColor3 = state and PrimaryColor or Color3.fromRGB(180, 100, 150),
                }, 0.2)

                updateCanvas(state, true)
                recalc(true)

                if fromUser and flag then
                    Window:SetFlag(flag, state)
                end
                if ModuleObj._callback then task.spawn(ModuleObj._callback, state) end
            end
            ModuleObj._SetEnabled = setEnabled

            local ClickArea = New("TextButton", {
                Size = UDim2.new(1, -s(90), 0, HEADER_H),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 2,
            }, Header)
            ClickArea.MouseButton1Click:Connect(function()
                setEnabled(not ModuleObj.Enabled, true)
            end)
            ToggleBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    setEnabled(not ModuleObj.Enabled, true)
                end
            end)

            local function scaleKeybind(name)
                KeybindBtn.Text = name or "None"
            end

            KeybindBtn.MouseButton1Click:Connect(function()
                if Window._choosingKeybind then return end
                Window._choosingKeybind = true
                KeybindBtn.Text = "..."
                local conn
                conn = UIS.InputBegan:Connect(function(input, gpe)
                    if gpe then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Backspace then
                            if flag then Window._config._keybinds[flag] = nil; Window:SaveConfig() end
                            scaleKeybind("None")
                        else
                            if flag then Window._config._keybinds[flag] = input.KeyCode.Name; Window:SaveConfig() end
                            scaleKeybind(input.KeyCode.Name)
                        end
                        conn:Disconnect()
                        Window._choosingKeybind = false
                    end
                end)
            end)

            UIS.InputBegan:Connect(function(input, gpe)
                if gpe or Window._choosingKeybind then return end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if flag and Window._config._keybinds[flag] == input.KeyCode.Name then
                    setEnabled(not ModuleObj.Enabled, true)
                end
            end)

            if flag then
                local savedKey = Window._config._keybinds[flag]
                if savedKey then scaleKeybind(savedKey) end
                local savedState = Window._config._flags[flag]
                if savedState ~= nil then
                    setEnabled(savedState, false)
                else
                    setEnabled(false, false)
                end
            else
                setEnabled(false, false)
            end

            setmetatable(ModuleObj, {__index = Library.ModuleMeta})
            return ModuleObj
        end

        -- ===== WIDGET HELPERS: gọi trực tiếp trên Tab (Allusive style) =====
        -- Tự động tạo module ẩn + thêm component vào đó

        local function autoModule(section)
            return CreateModule({Section = section, Title = "", Description = ""})
        end

        function Tab:create_toggle(text, callback)
            local mod = autoModule(self._lastSection)
            return mod:CreateToggle({Text = text, Callback = callback})
        end

        function Tab:create_button(text, callback)
            local mod = autoModule(self._lastSection)
            return mod:CreateButton({Text = text, Callback = callback})
        end

        function Tab:create_slider(text, min, max, default, callback)
            local mod = autoModule(self._lastSection)
            return mod:CreateSlider({Text = text, Min = min, Max = max, Default = default, Callback = callback})
        end

        function Tab:create_dropdown(text, options, default, callback)
            local mod = autoModule(self._lastSection)
            return mod:CreateDropdown({Text = text, Options = options, Default = default, Callback = callback})
        end

        function Tab:create_textbox(text, placeholder, default, callback)
            local mod = autoModule(self._lastSection)
            return mod:CreateTextbox({Text = text, Placeholder = placeholder, Default = default, Callback = callback})
        end

        function Tab:create_keybind(text, default, callback)
            local mod = autoModule(self._lastSection)
            return mod:CreateKeybind({Text = text, Default = default, Callback = callback})
        end

        function Tab:create_label(text)
            local mod = autoModule(self._lastSection)
            return mod:CreateLabel({Text = text})
        end

        function Tab:create_paragraph(title, content)
            local mod = autoModule(self._lastSection)
            return mod:CreateParagraph({Title = title, Content = content})
        end

        function Tab:create_divider()
            local mod = autoModule(self._lastSection)
            return mod:CreateDivider()
        end

        -- Aliases CamelCase
        Tab.CreateToggle = Tab.create_toggle
        Tab.CreateButton = Tab.create_button
        Tab.CreateSlider = Tab.create_slider
        Tab.CreateDropdown = Tab.create_dropdown
        Tab.CreateTextbox = Tab.create_textbox
        Tab.CreateKeybind = Tab.create_keybind
        Tab.CreateLabel = Tab.create_label
        Tab.CreateParagraph = Tab.create_paragraph
        Tab.CreateDivider = Tab.create_divider

        -- Module method (nếu ai vẫn muốn dùng module truyền thống)
        Tab.CreateModule = CreateModule
        Tab.create_module = CreateModule

        -- Cho phép section: tab:section("Right") rồi tạo element
        function Tab:section(name)
            self._lastSection = name
            return self
        end

        return Tab
    end

    return Window
end

Library.ModuleMeta = {}
Library.ModuleMeta.__index = Library.ModuleMeta

function Library.ModuleMeta:CreateLabel(config)
    config = config or {}
    local lbl = New("TextLabel", {
        Text = config.Text or "Label",
        Size = UDim2.new(1, 0, 0, s(16)),
        TextColor3 = Color3.fromRGB(255, 200, 220),
        Font = Enum.Font.Gotham,
        TextSize = s(11),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    lbl.Parent = self.Canvas
    return lbl
end

function Library.ModuleMeta:CreateParagraph(config)
    config = config or {}
    local lbl = New("TextLabel", {
        Text = (config.Title and (config.Title .. "\n") or "") .. (config.Content or ""),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextColor3 = Color3.fromRGB(255, 154, 200),
        Font = Enum.Font.Gotham,
        TextSize = s(10),
        TextWrapped = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    lbl.Parent = self.Canvas
    return lbl
end

function Library.ModuleMeta:CreateDivider()
    local div = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.fromRGB(255, 154, 200),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
    })
    div.Parent = self.Canvas
    return div
end

function Library.ModuleMeta:CreateButton(config)
    config = config or {}
    local Btn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, s(26)),
        BackgroundColor3 = Color3.fromRGB(100, 30, 75),
        AutoButtonColor = false,
        Text = config.Text or "Button",
        TextColor3 = Color3.fromRGB(255, 200, 220),
        Font = Enum.Font.GothamBold,
        TextSize = s(11),
        ZIndex = 5,
    })
    Btn.Parent = self.Canvas
    Round(Btn, s(6))
    Stroke(Btn, 1, 0.6)
    Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = Color3.fromRGB(130, 50, 100)}, 0.15) end)
    Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = Color3.fromRGB(100, 30, 75)}, 0.15) end)
    Btn.MouseButton1Click:Connect(function()
        if config.Callback then task.spawn(config.Callback) end
    end)
    return Btn
end

function Library.ModuleMeta:CreateToggle(config)
    config = config or {}
    local flag = config.Flag
    local state = config.Default or false
    if flag and self.Window and self.Window._config and self.Window._config._flags[flag] ~= nil then
        state = self.Window._config._flags[flag]
    end

    local Row = New("Frame", {Size = UDim2.new(1, 0, 0, s(22)), BackgroundTransparency = 1, ClipsDescendants = false})
    Row.Parent = self.Canvas
    New("TextLabel", {
        Text = config.Text or "Toggle",
        Size = UDim2.new(1, -s(40), 1, 0),
        TextColor3 = Color3.fromRGB(255, 200, 220),
        Font = Enum.Font.Gotham,
        TextSize = s(11),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Row)
    local Bg = New("Frame", {
        Size = UDim2.new(0, s(30), 0, s(16)),
        Position = UDim2.new(1, -s(30), 0.5, -s(8)),
        BackgroundColor3 = state and Color3.fromRGB(255, 154, 200) or Color3.fromRGB(100, 30, 75),
    }, Row)
    Round(Bg, s(999))
    local Dot = New("Frame", {
        Size = UDim2.new(0, s(12), 0, s(12)),
        Position = state and UDim2.new(1, -s(14), 0.5, -s(6)) or UDim2.new(0, s(2), 0.5, -s(6)),
        BackgroundColor3 = Color3.fromRGB(255, 245, 248),
    }, Bg)
    Round(Dot, s(999))

    local function apply(v, fromUser)
        state = v
        Tween(Bg, {BackgroundColor3 = state and Color3.fromRGB(255, 154, 200) or Color3.fromRGB(100, 30, 75)}, 0.15)
        Tween(Dot, {Position = state and UDim2.new(1, -s(14), 0.5, -s(6)) or UDim2.new(0, s(2), 0.5, -s(6))}, 0.15)
        if fromUser then
            if flag and self.Window then self.Window:SetFlag(flag, state) end
            if config.Callback then task.spawn(config.Callback, state) end
        end
    end

    local Click = New("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""}, Row)
    Click.MouseButton1Click:Connect(function()
        apply(not state, true)
    end)

    if config.Callback then task.spawn(config.Callback, state) end

    return {
        Set = function(_, v) apply(v, false) end,
        Get = function() return state end,
    }
end

function Library.ModuleMeta:CreateSlider(config)
    config = config or {}
    local flag = config.Flag
    local min, max = config.Min or 0, config.Max or 100
    local value = math.clamp(config.Default or min, min, max)
    if flag and self.Window and self.Window._config and self.Window._config._flags[flag] ~= nil then
        value = math.clamp(self.Window._config._flags[flag], min, max)
    end
    local suffix = config.Suffix or ""

    local Row = New("Frame", {Size = UDim2.new(1, 0, 0, s(32)), BackgroundTransparency = 1, ClipsDescendants = false})
    Row.Parent = self.Canvas
    New("TextLabel", {
        Text = config.Text or "Slider",
        Size = UDim2.new(1, -s(45), 0, s(14)),
        TextColor3 = Color3.fromRGB(255, 200, 220),
        Font = Enum.Font.Gotham,
        TextSize = s(11),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Row)
    local ValLbl = New("TextLabel", {
        Text = tostring(value) .. suffix,
        Size = UDim2.new(0, s(45), 0, s(14)),
        Position = UDim2.new(1, -s(45), 0, 0),
        TextColor3 = Color3.fromRGB(255, 154, 200),
        Font = Enum.Font.GothamBold,
        TextSize = s(10),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, Row)
    local Track = New("Frame", {
        Size = UDim2.new(1, 0, 0, s(4)),
        Position = UDim2.new(0, 0, 0, s(22)),
        BackgroundColor3 = Color3.fromRGB(100, 30, 75),
        ClipsDescendants = false,
    }, Row)
    Round(Track, s(999))
    local Fill = New("Frame", {
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 154, 200),
    }, Track)
    Round(Fill, s(999))
    local Dot = New("Frame", {
        Size = UDim2.new(0, s(12), 0, s(12)),
        Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 154, 200),
        ZIndex = 11,
    }, Track)
    Round(Dot, s(999))

    local function apply(v, animate)
        value = math.clamp(v, min, max)
        local pct = (value - min) / (max - min)
        if animate then
            Tween(Fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.15)
            Tween(Dot, {Position = UDim2.new(pct, 0, 0.5, 0)}, 0.15)
        else
            Fill.Size = UDim2.new(pct, 0, 1, 0)
            Dot.Position = UDim2.new(pct, 0, 0.5, 0)
        end
        ValLbl.Text = tostring(value) .. suffix
    end

    local dragging = false
    local function update(input, fromUser)
        local pct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        apply(min + (max - min) * pct, true)
        if fromUser then
            if flag then self.Window:SetFlag(flag, value) end
            if config.Callback then task.spawn(config.Callback, value) end
        end
    end
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input, true)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input, true)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    if config.Callback then task.spawn(config.Callback, value) end

    return {
        Set = function(_, v) apply(v, true) end,
        Get = function() return value end,
    }
end

function Library.ModuleMeta:CreateDropdown(config)
    config = config or {}
    local flag = config.Flag
    local options = config.Options or {"Option 1"}
    local selected = config.Default or options[1]
    if flag and self.Window and self.Window._config and self.Window._config._flags[flag] ~= nil then
        selected = self.Window._config._flags[flag]
    end

    local Row = New("Frame", {
        Size = UDim2.new(1, 0, 0, s(38)),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = 5,
    })
    Row.Parent = self.Canvas

    New("TextLabel", {
        Text = config.Text or "Dropdown",
        Size = UDim2.new(1, 0, 0, s(14)),
        TextColor3 = Color3.fromRGB(255, 200, 220),
        Font = Enum.Font.Gotham,
        TextSize = s(11),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    }, Row)

    local Selected = New("Frame", {
        Size = UDim2.new(1, 0, 0, s(18)),
        Position = UDim2.new(0, 0, 0, s(16)),
        BackgroundColor3 = Color3.fromRGB(100, 30, 75),
        ZIndex = 6,
    }, Row)
    Round(Selected, s(6))

    local SelectedText = New("TextLabel", {
        Text = selected,
        Size = UDim2.new(1, -s(10), 1, 0),
        Position = UDim2.new(0, s(8), 0, 0),
        TextColor3 = Color3.fromRGB(255, 240, 245),
        Font = Enum.Font.GothamBold,
        TextSize = s(10),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
    }, Selected)

    local DropBtn = New("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 11}, Selected)

    local Holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, s(37)),
        BackgroundColor3 = Color3.fromRGB(50, 10, 40),
        Visible = false,
        ZIndex = 100,
        ClipsDescendants = false,
    }, Row)
    Round(Holder, s(8))
    Stroke(Holder, 1.2, 0)

    local Scroll = New("ScrollingFrame", {
        Size = UDim2.new(1, -s(10), 1, -s(10)),
        Position = UDim2.new(0, s(5), 0, s(5)),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        ZIndex = 101,
        CanvasSize = UDim2.new(0, 0, 0, #options * s(25)),
    }, Holder)
    New("UIListLayout", {Padding = UDim.new(0, s(3))}, Scroll)

    local isOpen = false

    local function choose(option, fromUser)
        selected = option
        SelectedText.Text = option
        isOpen = false
        Holder.Visible = false
        Tween(Holder, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
        if fromUser then
            if flag then self.Window:SetFlag(flag, option) end
            if config.Callback then task.spawn(config.Callback, option) end
        end
    end

    for _, option in ipairs(options) do
        local OptBtn = New("TextButton", {
            Size = UDim2.new(1, 0, 0, s(22)),
            BackgroundColor3 = Color3.fromRGB(50, 10, 40),
            Text = "  " .. option,
            TextColor3 = Color3.fromRGB(255, 154, 200),
            Font = Enum.Font.GothamBold,
            TextSize = s(10),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 102,
        }, Scroll)
        Round(OptBtn, s(4))
        OptBtn.MouseButton1Click:Connect(function()
            choose(option, true)
        end)
    end

    DropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        Holder.Visible = isOpen
        local holderHeight = #options * s(25) + s(10)
        Tween(Holder, {Size = isOpen and UDim2.new(1, 0, 0, holderHeight) or UDim2.new(1, 0, 0, 0)}, 0.2)
    end)

    if config.Callback then task.spawn(config.Callback, selected) end

    return {
        Set = function(_, v) choose(v, false) end,
        Get = function() return selected end,
    }
end

function Library.ModuleMeta:CreateTextbox(config)
    config = config or {}
    local flag = config.Flag
    local Row = New("Frame", {Size = UDim2.new(1, 0, 0, s(36)), BackgroundTransparency = 1})
    Row.Parent = self.Canvas
    if config.Text then
        New("TextLabel", {
            Text = config.Text,
            Size = UDim2.new(1, 0, 0, s(12)),
            TextColor3 = Color3.fromRGB(255, 200, 220),
            Font = Enum.Font.Gotham,
            TextSize = s(9),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, Row)
    end
    local Wrapper = New("Frame", {
        Size = UDim2.new(1, 0, 0, s(22)),
        Position = UDim2.new(0, 0, 0, config.Text and s(14) or 0),
        BackgroundColor3 = Color3.fromRGB(100, 30, 75),
    }, Row)
    Round(Wrapper, s(6))
    Stroke(Wrapper, 1, 0)

    local defaultText = config.Default or ""
    if flag and self.Window and self.Window._config and self.Window._config._flags[flag] ~= nil then
        defaultText = self.Window._config._flags[flag]
    end

    local Box = New("TextBox", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = defaultText,
        PlaceholderText = config.Placeholder or "Type here...",
        PlaceholderColor3 = Color3.fromRGB(255, 154, 200),
        TextColor3 = Color3.fromRGB(255, 200, 220),
        Font = Enum.Font.Gotham,
        TextSize = s(11),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }, Wrapper)
    New("UIPadding", {PaddingLeft = UDim.new(0, s(8))}, Box)

    Box.FocusLost:Connect(function(enterPressed)
        if flag then self.Window:SetFlag(flag, Box.Text) end
        if config.Callback then task.spawn(config.Callback, Box.Text, enterPressed) end
    end)

    return {
        Set = function(_, v) Box.Text = v end,
        Get = function() return Box.Text end,
    }
end

function Library.ModuleMeta:CreateKeybind(config)
    config = config or {}
    local flag = config.Flag
    local bound = config.Default
    if flag and self.Window and self.Window._config and self.Window._config._keybinds[flag] then
        local keyName = self.Window._config._keybinds[flag]
        bound = Enum.KeyCode[keyName]
    end
    local listening = false

    local Row = New("Frame", {Size = UDim2.new(1, 0, 0, s(22)), BackgroundTransparency = 1})
    Row.Parent = self.Canvas
    New("TextLabel", {
        Text = config.Text or "Keybind",
        Size = UDim2.new(1, -s(50), 1, 0),
        TextColor3 = Color3.fromRGB(255, 200, 220),
        Font = Enum.Font.Gotham,
        TextSize = s(11),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Row)
    local Btn = New("TextButton", {
        Size = UDim2.new(0, s(46), 0, s(18)),
        Position = UDim2.new(1, -s(46), 0.5, -s(9)),
        BackgroundColor3 = Color3.fromRGB(100, 30, 75),
        AutoButtonColor = false,
        Text = typeof(bound) == "EnumItem" and bound.Name or "None",
        TextColor3 = Color3.fromRGB(255, 154, 200),
        Font = Enum.Font.Gotham,
        TextSize = s(9),
        ZIndex = 5,
    }, Row)
    Round(Btn, s(6))

    Btn.MouseButton1Click:Connect(function()
        if self.Window and self.Window._choosingKeybind then return end
        if self.Window then self.Window._choosingKeybind = true end
        listening = true
        Btn.Text = "..."
    end)
    UIS.InputBegan:Connect(function(input, gpe)
        if listening and not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
            bound = input.KeyCode
            Btn.Text = input.KeyCode.Name
            listening = false
            if self.Window then self.Window._choosingKeybind = false end
            if flag and self.Window then self.Window._config._keybinds[flag] = input.KeyCode.Name; self.Window:SaveConfig() end
            if config.Callback then task.spawn(config.Callback, bound) end
        elseif not listening and bound and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bound then
            if config.Pressed then task.spawn(config.Pressed) end
        end
    end)

    return {
        Set = function(_, key) bound = key; Btn.Text = key and key.Name or "None" end,
        Get = function() return bound end,
    }
end

return Library
