-- Mirra's Simple Combo Points: settings

local ADDON, ns = ...

local FLAT = "Interface\\Buttons\\WHITE8X8"
local window
local controls = {}

local function Apply()
    if ns.Update then ns.Update() end
end

local function Label(parent, text, size, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetText(text)
    if size then
        local font, _, flags = fs:GetFont()
        fs:SetFont(font, size, flags)
    end
    if r then fs:SetTextColor(r, g, b) end
    return fs
end

local function Box(frame, r, g, b, a)
    local t = frame:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints()
    t:SetColorTexture(r, g, b, a)
    return t
end

local function Border(frame, r, g, b, a)
    local function line(p1, p2, w, h)
        local t = frame:CreateTexture(nil, "BORDER")
        t:SetColorTexture(r, g, b, a)
        t:SetPoint(p1); t:SetPoint(p2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    line("TOPLEFT", "TOPRIGHT", nil, 1)
    line("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    line("TOPLEFT", "BOTTOMLEFT", 1, nil)
    line("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
end

local function Slider(parent, label, key, minV, maxV, step, fmt)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(300, 40)

    local title = Label(f, label, 12, 1, 0.82, 0)
    title:SetPoint("TOPLEFT", 0, 0)

    local valueText = Label(f, "", 12, 1, 1, 1)
    valueText:SetPoint("TOPRIGHT", 0, 0)

    local s = CreateFrame("Slider", nil, f)
    s:SetOrientation("HORIZONTAL")
    s:SetPoint("TOPLEFT", 0, -18)
    s:SetPoint("TOPRIGHT", 0, -18)
    s:SetHeight(16)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s:EnableMouseWheel(true)

    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(0.15, 0.15, 0.15, 1)
    track:SetPoint("LEFT"); track:SetPoint("RIGHT")
    track:SetHeight(6)

    local thumb = s:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(1, 0.75, 0.1, 1)
    thumb:SetSize(10, 16)
    s:SetThumbTexture(thumb)

    local function show(v)
        valueText:SetText(string.format(fmt or "%d", v))
    end

    s:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        show(v)
        if self.updating then return end
        ns.db[key] = v
        Apply()
    end)
    s:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(self:GetValue() + delta * step)
    end)

    f.Refresh = function()
        s.updating = true
        s:SetValue(ns.db[key])
        show(ns.db[key])
        s.updating = false
    end
    return f
end

local function Check(parent, label, getter, setter)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(300, 20)

    local box = CreateFrame("Frame", nil, b)
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 0, 0)
    Box(box, 0.1, 0.1, 0.1, 1)
    Border(box, 0.5, 0.5, 0.5, 1)

    local tick = box:CreateTexture(nil, "OVERLAY")
    tick:SetPoint("TOPLEFT", 3, -3)
    tick:SetPoint("BOTTOMRIGHT", -3, 3)
    tick:SetColorTexture(1, 0.75, 0.1, 1)

    local text = Label(b, label, 12, 1, 1, 1)
    text:SetPoint("LEFT", box, "RIGHT", 8, 0)

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(box)
    hl:SetColorTexture(1, 1, 1, 0.15)

    b:SetScript("OnClick", function()
        setter(not getter())
        tick:SetShown(getter())
        Apply()
    end)
    b.Refresh = function() tick:SetShown(getter() and true or false) end
    return b
end

local function Button(parent, text, w, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w or 120, 22)
    Box(b, 0.2, 0.2, 0.2, 1)
    Border(b, 0.5, 0.5, 0.5, 1)
    local fs = Label(b, text, 12, 1, 1, 1)
    fs:SetPoint("CENTER")
    b.text = fs
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 0.75, 0.1, 0.2)
    b:SetScript("OnClick", onClick)
    return b
end

local function Cycle(parent, label, key, options)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(300, 22)
    local title = Label(f, label, 12, 1, 0.82, 0)
    title:SetPoint("LEFT", 0, 0)

    local btn
    local function textFor(v)
        for _, o in ipairs(options) do
            if o[1] == v then return o[2] end
        end
        return tostring(v)
    end
    btn = Button(f, "", 170, function()
        local idx = 1
        for i, o in ipairs(options) do
            if o[1] == ns.db[key] then idx = i end
        end
        idx = idx % #options + 1
        ns.db[key] = options[idx][1]
        btn.text:SetText(textFor(ns.db[key]))
        Apply()
    end)
    btn:SetPoint("RIGHT", 0, 0)
    f.Refresh = function() btn.text:SetText(textFor(ns.db[key])) end
    return f
end

local function OpenColorPicker(c, hasAlpha, onChange)
    local prev = { r = c.r, g = c.g, b = c.b, a = c.a }
    local function read()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        c.r, c.g, c.b = r, g, b
        if hasAlpha then
            local a
            if ColorPickerFrame.GetColorAlpha then
                a = ColorPickerFrame:GetColorAlpha()
            elseif OpacitySliderFrame then
                a = 1 - OpacitySliderFrame:GetValue()
            end
            c.a = a or c.a
        end
        onChange()
    end
    local function cancel()
        c.r, c.g, c.b, c.a = prev.r, prev.g, prev.b, prev.a
        onChange()
    end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = c.r, g = c.g, b = c.b,
            opacity = c.a or 1,
            hasOpacity = hasAlpha,
            swatchFunc = read,
            opacityFunc = read,
            cancelFunc = cancel,
        })
    else
        ColorPickerFrame.hasOpacity = hasAlpha
        ColorPickerFrame.opacity = 1 - (c.a or 1)
        ColorPickerFrame.func = read
        ColorPickerFrame.opacityFunc = read
        ColorPickerFrame.cancelFunc = cancel
        ColorPickerFrame:SetColorRGB(c.r, c.g, c.b)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end

local function Swatch(parent, label, key, hasAlpha)
    local f = CreateFrame("Button", nil, parent)
    f:SetSize(280, 20)

    local box = CreateFrame("Frame", nil, f)
    box:SetSize(28, 16)
    box:SetPoint("RIGHT", 0, 0)
    Box(box, 0.3, 0.3, 0.3, 1)
    local col = box:CreateTexture(nil, "ARTWORK")
    col:SetPoint("TOPLEFT", 1, -1)
    col:SetPoint("BOTTOMRIGHT", -1, 1)
    Border(box, 0.7, 0.7, 0.7, 1)

    local text = Label(f, label, 12, 1, 1, 1)
    text:SetPoint("LEFT", 0, 0)

    local hl = f:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(box)
    hl:SetColorTexture(1, 1, 1, 0.2)

    f.Refresh = function()
        local c = ns.db[key]
        col:SetColorTexture(c.r, c.g, c.b, hasAlpha and (c.a or 1) or 1)
    end
    f:SetScript("OnClick", function()
        OpenColorPicker(ns.db[key], hasAlpha, function()
            f.Refresh()
            Apply()
        end)
    end)
    return f
end

local COL_W = 280

local function Section(parent, text)
    local fs = Label(parent, text, 13, 1, 1, 1)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.75, 0.1, 0.5)
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 8, 0)
    line:SetWidth(COL_W - fs:GetStringWidth() - 8)
    return fs
end

local function BuildWindow()
    window = CreateFrame("Frame", "MirrasSimpleComboPointsOptions", UIParent)
    window:SetSize(20 + COL_W + 30 + COL_W + 20, 500)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()
    Box(window, 0.05, 0.05, 0.07, 0.95)
    Border(window, 0.35, 0.35, 0.35, 1)

    tinsert(UISpecialFrames, "MirrasSimpleComboPointsOptions")

    local header = CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT"); header:SetPoint("TOPRIGHT")
    header:SetHeight(30)
    Box(header, 0.12, 0.12, 0.14, 1)

    local title = Label(header, "Mirra's Simple Combo Points", 14, 1, 0.82, 0)
    title:SetPoint("LEFT", 12, 0)

    local close = Button(header, "X", 22, function() window:Hide() end)
    close:SetPoint("RIGHT", -4, 0)

    local x, y
    local function column(cx)
        x, y = cx, -80
    end
    local function place(w, gap)
        w:SetPoint("TOPLEFT", window, "TOPLEFT", x, y)
        if w.SetWidth and w:GetWidth() > COL_W then w:SetWidth(COL_W) end
        y = y - (w:GetHeight() + (gap or 10))
        if w.Refresh then controls[#controls + 1] = w end
        return w
    end
    local function section(text)
        local fs = Section(window, text)
        fs:SetPoint("TOPLEFT", window, "TOPLEFT", x, y)
        y = y - 24
    end

    local previewRow
    local prev = Check(window, "Show preview",
        function() return ns.preview end,
        function(v)
            ns.preview = v
            if previewRow then previewRow:SetShown(v) end
        end)
    prev:SetPoint("TOPLEFT", 20, -44)
    controls[#controls + 1] = prev

    previewRow = ns.CreatePreview(window, 22)
    previewRow:SetPoint("LEFT", prev, "LEFT", 150, 0)

    column(20)
    section("Appearance")
    place(Cycle(window, "Shape", "shape", {
        { "round", "Round" },
        { "square", "Square" },
    }))
    place(Slider(window, "Pip size", "size", 4, 40, 1))
    place(Slider(window, "Spacing", "spacing", 0, 20, 1))
    place(Slider(window, "Opacity", "alpha", 0.1, 1, 0.05, "%.2f"), 14)

    section("Position")
    place(Cycle(window, "Anchor", "anchor", {
        { "TOP", "Above health bar" },
        { "BOTTOM", "Below health bar" },
    }))
    place(Slider(window, "Horizontal offset", "offsetX", -100, 100, 1))
    place(Slider(window, "Vertical offset", "offsetY", -50, 50, 1))

    column(20 + COL_W + 30)
    section("Colors")
    place(Cycle(window, "Color mode", "colorMode", {
        { "gradient", "Gradient" },
        { "single", "Single color" },
    }))
    place(Swatch(window, "Color (or gradient start)", "colorStart"))
    place(Swatch(window, "Gradient end", "colorEnd"))
    place(Check(window, "Custom color when all points are full",
        function() return ns.db.useFullColor end,
        function(v) ns.db.useFullColor = v end))
    place(Swatch(window, "Full points color", "colorFull"))
    place(Swatch(window, "Empty slot color (with opacity)", "colorEmpty", true), 14)

    section("Behavior")
    place(Check(window, "Show empty slots",
        function() return ns.db.showEmpty end,
        function(v) ns.db.showEmpty = v end))
    place(Check(window, "Hide at 0 combo points",
        function() return ns.db.hideEmpty end,
        function(v) ns.db.hideEmpty = v end))
    place(Check(window, "Show login message in chat",
        function() return ns.db.loginMessage end,
        function(v) ns.db.loginMessage = v end))

    local reset = Button(window, "Reset", 120, function()
        for k, v in pairs(ns.defaults) do ns.db[k] = ns.Copy(v) end
        ns.RefreshOptions()
        Apply()
    end)
    reset:SetPoint("BOTTOMLEFT", 20, 16)

    local done = Button(window, "Close", 120, function() window:Hide() end)
    done:SetPoint("BOTTOMRIGHT", -20, 16)

    window:SetScript("OnShow", function()
        ns.RefreshOptions()
        previewRow:SetShown(ns.preview)
    end)
    window:SetScript("OnHide", function()
        ns.preview = false
        previewRow:Hide()
    end)
end

function ns.RefreshOptions()
    if not window then return end
    for _, c in ipairs(controls) do c.Refresh() end
end

local function OpenCustomWindow()
    if not window then BuildWindow() end
    if window:IsShown() then window:Hide() else window:Show() end
end

local ADDON_TITLE = "Mirra's Simple Combo Points"
local nativeCategory
local nativeSettings = {}

local function BuildNativePanel()
    local S = Settings
    local category, layout = S.RegisterVerticalLayoutCategory(ADDON_TITLE)
    local VT = S.VarType
    local db, defaults = ns.db, ns.defaults

    local function OnChanged() Apply() end

    local function Register(key, varType, name)
        local variable = "MSCP_" .. key
        local setting = S.RegisterAddOnSetting(category, variable, key, db, varType, name, defaults[key])
        S.SetOnValueChangedCallback(variable, OnChanged)
        nativeSettings[key] = setting
        return setting
    end

    local function Header(text)
        if CreateSettingsListSectionHeaderInitializer then
            layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
        end
    end

    local function Checkbox(key, name, tooltip)
        S.CreateCheckbox(category, Register(key, VT.Boolean, name), tooltip)
    end

    local function Slider(key, name, minV, maxV, step, fmt, tooltip)
        local setting = Register(key, VT.Number, name)
        local opts = S.CreateSliderOptions(minV, maxV, step)
        if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
            opts:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(v)
                return string.format(fmt or "%d", v)
            end)
        end
        S.CreateSlider(category, setting, opts, tooltip)
    end

    local CreateDropdown = S.CreateDropdown or S.CreateDropDown
    local function Dropdown(key, name, choices, tooltip)
        local setting = Register(key, VT.String, name)
        local function GetOptions()
            local c = S.CreateControlTextContainer()
            for _, o in ipairs(choices) do c:Add(o[1], o[2]) end
            return c:GetData()
        end
        CreateDropdown(category, setting, GetOptions, tooltip)
    end

    local function ActionButton(name, buttonText, onClick, tooltip)
        layout:AddInitializer(CreateSettingsButtonInitializer(name, buttonText, onClick, tooltip, true))
    end

    local function ColorButton(key, name, hasAlpha)
        ActionButton(name, "Choose color", function()
            OpenColorPicker(db[key], hasAlpha, Apply)
        end, "Opens the color picker.")
    end

    local previewGroup, previewInit
    if S.RegisterProxySetting then
        local preview = S.RegisterProxySetting(category, "MSCP_preview", VT.Boolean,
            "Show preview", false,
            function() return ns.preview end,
            function(v)
                ns.preview = v
                if previewGroup and previewGroup.owner then previewGroup:SetShown(v) end
            end)
        previewInit = S.CreateCheckbox(category, preview,
            "Shows the combo points right here, cycling through 1 to max, so you can see your changes.")
    end

    local function Attach(frame)
        if not previewGroup then previewGroup = ns.CreatePreview(frame, 22) end
        local g = previewGroup
        g:SetParent(frame)
        g:SetFrameLevel(frame:GetFrameLevel() + 5)
        g:ClearAllPoints()
        local cb = frame.Checkbox or frame.CheckBox
        if cb then
            g:SetPoint("LEFT", cb, "RIGHT", 24, 0)
        else
            g:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
        end
        g.owner = frame
        g:SetShown(ns.preview)

        if not frame.mscpHooked then
            frame.mscpHooked = true
            frame:HookScript("OnHide", function(f)
                if g.owner == f then g:Hide() end
            end)
            if frame.Init then
                hooksecurefunc(frame, "Init", function(f, init)
                    if init ~= previewInit and g.owner == f then
                        g.owner = nil
                        g:Hide()
                    end
                end)
            end
        end
    end

    if previewInit and previewInit.InitFrame then
        local origInit = previewInit.InitFrame
        previewInit.InitFrame = function(self, frame, ...)
            origInit(self, frame, ...)
            pcall(Attach, frame)
        end
    end

    Header("Appearance")
    Dropdown("shape", "Shape", { { "round", "Round" }, { "square", "Square" } })
    Slider("size", "Pip size", 4, 40, 1)
    Slider("spacing", "Spacing", 0, 20, 1)
    Slider("alpha", "Opacity", 0.1, 1, 0.05, "%.2f")

    Header("Position")
    Dropdown("anchor", "Anchor", { { "TOP", "Above health bar" }, { "BOTTOM", "Below health bar" } })
    Slider("offsetX", "Horizontal offset", -100, 100, 1)
    Slider("offsetY", "Vertical offset", -50, 50, 1)

    Header("Colors")
    Dropdown("colorMode", "Color mode", { { "gradient", "Gradient" }, { "single", "Single color" } })
    ColorButton("colorStart", "Color (or gradient start)")
    ColorButton("colorEnd", "Gradient end")
    Checkbox("useFullColor", "Custom color when full", "Use a separate color when all combo points are up.")
    ColorButton("colorFull", "Full points color")
    ColorButton("colorEmpty", "Empty slot color", true)

    Header("Behavior")
    Checkbox("showEmpty", "Show empty slots", "Show dark circles for missing combo points.")
    Checkbox("hideEmpty", "Hide at 0 combo points", "Hide everything while you have no combo points on the target.")
    Checkbox("loginMessage", "Show login message in chat")

    Header("Other")
    ActionButton("Reset", "Reset all", function()
        for k, v in pairs(defaults) do
            if nativeSettings[k] then
                nativeSettings[k]:SetValue(v)
            else
                db[k] = ns.Copy(v)
            end
        end
        Apply()
    end, "Restores all settings, including colors, to their defaults.")

    S.RegisterAddOnCategory(category)
    nativeCategory = category

    if SettingsPanel then
        SettingsPanel:HookScript("OnHide", function()
            ns.preview = false
            if previewGroup then previewGroup:Hide() end
        end)
    end
end

function ns.OpenOptions()
    if nativeCategory then
        if SettingsPanel and SettingsPanel:IsShown() then
            pcall(HideUIPanel, SettingsPanel)
            return
        end
        local id = nativeCategory.GetID and nativeCategory:GetID() or nativeCategory.ID
        local ok = pcall(Settings.OpenToCategory, id)
        if ok then return end
    end
    OpenCustomWindow()
end

local function RegisterFallbackPanel()
    local panel = CreateFrame("Frame")
    panel.name = ADDON_TITLE

    local t = Label(panel, ADDON_TITLE, 16, 1, 0.82, 0)
    t:SetPoint("TOPLEFT", 16, -16)
    local d = Label(panel, "The settings are in a separate window.\nYou can also type /mscp in chat.", 12, 1, 1, 1)
    d:SetJustifyH("LEFT")
    d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -10)

    local b = Button(panel, "Open settings", 180, function()
        if SettingsPanel and SettingsPanel:IsShown() then
            pcall(HideUIPanel, SettingsPanel)
        end
        if not window then BuildWindow() end
        window:Show()
    end)
    b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -14)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        pcall(function()
            local cat = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
            Settings.RegisterAddOnCategory(cat)
        end)
    elseif InterfaceOptions_AddCategory then
        pcall(InterfaceOptions_AddCategory, panel)
    end
end

function ns.BuildOptions()
    local ok, err = false, "Settings API not available"
    if Settings and Settings.RegisterVerticalLayoutCategory and CreateSettingsButtonInitializer then
        ok, err = pcall(BuildNativePanel)
    end
    if not ok then
        nativeCategory = nil
        ns.nativeError = err
        RegisterFallbackPanel()
    end
end

ns.OpenCustomWindow = OpenCustomWindow

function MirrasSimpleComboPoints_OnCompartmentClick()
    ns.OpenOptions()
end
