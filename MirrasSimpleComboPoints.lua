-- Mirra's Simple Combo Points
-- Shows your combo points on your target's nameplate (WoW: Forever).

local ADDON, ns = ...
local POWER_COMBO = (Enum and Enum.PowerType and Enum.PowerType.ComboPoints) or 4
local MAX_PIPS = 10
local FLAT = "Interface\\Buttons\\WHITE8X8"

local defaults = {
    size      = 15,
    spacing   = 3,
    offsetX   = 0,
    offsetY   = 4,
    anchor    = "TOP",
    hideEmpty = true,
    showEmpty = true,
    alpha     = 1,
    loginMessage = true,
    shape     = "round",
    colorMode = "gradient",
    colorStart = { r = 1,   g = 0.9,  b = 0.1 },
    colorEnd   = { r = 1,   g = 0.15, b = 0.1 },
    useFullColor = true,
    colorFull  = { r = 1,   g = 0.1,  b = 0.1 },
    colorEmpty = { r = 0,   g = 0,    b = 0, a = 0.85 },
}
ns.defaults = defaults

local function Copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = x end
    return t
end
ns.Copy = Copy
ns.preview = false

local db
local container
local lastReason = "no update yet"

local function Print(msg)
    print("|cffffcc00Mirra's Simple Combo Points:|r " .. tostring(msg))
end

local function IsSecret(v)
    if issecretvalue then
        local ok, res = pcall(issecretvalue, v)
        return ok and res or false
    end
    return false
end

local function PipColor(i, max)
    local a, b = db.colorStart, db.colorEnd
    if db.colorMode == "single" then return a.r, a.g, a.b end
    local t = (max > 1) and (i - 1) / (max - 1) or 1
    return a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t
end

local TEX_ROUND  = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local function ShapeTexture()
    return db.shape == "square" and FLAT or TEX_ROUND
end

local function NewBar(parent, level)
    local b = CreateFrame("StatusBar", nil, parent)
    b:SetStatusBarTexture(FLAT)
    b:SetMinMaxValues(0, 1)
    b:SetValue(0)
    b:SetFrameLevel(parent:GetFrameLevel() + level)
    return b
end

local function CreatePip(parent)
    local f = CreateFrame("Frame", nil, parent)

    local bgBar = NewBar(f, 1)
    bgBar:SetAllPoints()

    local bar = NewBar(f, 2)
    bar:SetPoint("TOPLEFT", 2, -2)
    bar:SetPoint("BOTTOMRIGHT", -2, 2)

    local fullBar = NewBar(f, 3)
    fullBar:SetAllPoints(bar)

    f.bgBar, f.bar, f.fullBar = bgBar, bar, fullBar
    return f
end

local function CreateGroup(parent, name)
    local g = CreateFrame("Frame", name, parent)
    g:SetSize(1, 1)
    g.pips = {}
    for i = 1, MAX_PIPS do
        g.pips[i] = CreatePip(g)
    end
    return g
end

local function LayoutPips(g, max)
    local size, gap = db.size, db.spacing
    g:SetSize(max * size + (max - 1) * gap, size)
    local tex = ShapeTexture()
    local inset = math.max(1, math.floor(size / 7 + 0.5))
    local e = db.colorEmpty
    for i = 1, MAX_PIPS do
        local p = g.pips[i]
        p:ClearAllPoints()
        if i <= max then
            p:SetSize(size, size)
            p:SetPoint("LEFT", g, "LEFT", (i - 1) * (size + gap), 0)
            p.bar:SetPoint("TOPLEFT", inset, -inset)
            p.bar:SetPoint("BOTTOMRIGHT", -inset, inset)
            for _, b in ipairs({ p.bgBar, p.bar, p.fullBar }) do
                b:SetStatusBarTexture(tex)
            end
            p.bgBar:SetStatusBarColor(e.r, e.g, e.b, e.a or 0.85)
            p.bgBar:SetAlpha(db.showEmpty and 1 or 0)
            p:Show()
        else
            p:Hide()
        end
    end
end

local function PaintGroup(g, cur, max)
    LayoutPips(g, max)
    local fc = db.colorFull
    for i = 1, max do
        local p = g.pips[i]
        p.bgBar:SetValue(db.hideEmpty and cur or 1)

        p.bar:SetMinMaxValues(i - 1, i)
        p.bar:SetValue(cur)
        p.bar:SetStatusBarColor(PipColor(i, max))

        p.fullBar:SetMinMaxValues(max - 1, max)
        p.fullBar:SetValue(cur)
        p.fullBar:SetStatusBarColor(fc.r, fc.g, fc.b, 1)
        p.fullBar:SetShown(db.useFullColor)
    end
    g:SetAlpha(db.alpha or 1)
end

local function BuildFrames()
    container = CreateGroup(UIParent, "MirrasSimpleComboPointsFrame")
    container:SetFrameStrata("HIGH")
    container:Hide()
end

local function GetCombo()
    local cur
    if GetComboPoints then
        local ok, c = pcall(GetComboPoints, "player", "target")
        if ok then cur = c end
    end
    local max = UnitPowerMax and UnitPowerMax("player", POWER_COMBO)
    if max == nil or IsSecret(max) or max <= 0 then max = MAX_COMBO_POINTS or 5 end
    max = math.min(max, MAX_PIPS)
    return cur or 0, max, "GetComboPoints"
end

local function GetAnchorFrame(plate)
    local uf = plate.UnitFrame
    if uf then
        local hb = uf.healthBar or uf.HealthBar
            or (uf.HealthBarsContainer and (uf.HealthBarsContainer.healthBar or uf.HealthBarsContainer))
        if hb then return hb, "healthBar" end
        return uf, "UnitFrame"
    end
    return plate, "plate"
end

local function Hide(reason)
    lastReason = reason
    container:Hide()
end

local function Render(anchor, plate, cur, max)
    container:ClearAllPoints()
    local ok = pcall(function()
        if db.anchor == "BOTTOM" then
            container:SetPoint("TOP", anchor, "BOTTOM", db.offsetX, -db.offsetY)
        else
            container:SetPoint("BOTTOM", anchor, "TOP", db.offsetX, db.offsetY)
        end
    end)
    if not ok and plate then
        container:ClearAllPoints()
        container:SetPoint("BOTTOM", plate, "TOP", db.offsetX, db.offsetY)
    end
    PaintGroup(container, cur, max)
    container:Show()
end

local function Update()
    if not container then return end

    if not UnitExists("target") then return Hide("no target") end

    local canAttack = UnitCanAttack("player", "target")
    if not IsSecret(canAttack) and not canAttack then return Hide("target not attackable") end

    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit("target")
    if not plate then return Hide("target has no visible nameplate (press V?)") end

    local cur, max, src = GetCombo()
    local secret = IsSecret(cur)

    if db.hideEmpty and not secret and cur == 0 then
        return Hide("0 combo points (" .. src .. ")")
    end

    Render(GetAnchorFrame(plate), plate, cur, max)
    lastReason = "shown (" .. src .. (secret and ", protected value" or ", " .. tostring(cur) .. "/" .. max) .. ")"
end

function ns.CreatePreview(parent, maxHeight)
    local g = CreateGroup(parent)
    g:Hide()
    local t = 0
    g:SetScript("OnUpdate", function(self, dt)
        t = t + dt
        if t < 0.1 then return end
        t = 0
        if not (ns.preview and db) then self:Hide() return end
        local _, max = GetCombo()
        local n = math.floor(GetTime() / 0.8) % max + 1
        PaintGroup(self, n, max)
        local h = maxHeight or 24
        self:SetScale(db.size > h and h / db.size or 1)
    end)
    return g
end

ns.Update = Update

local ev = CreateFrame("Frame")
local function Reg(e) pcall(ev.RegisterEvent, ev, e) end
Reg("ADDON_LOADED")
Reg("PLAYER_ENTERING_WORLD")
Reg("PLAYER_TARGET_CHANGED")
Reg("NAME_PLATE_UNIT_ADDED")
Reg("NAME_PLATE_UNIT_REMOVED")
Reg("UNIT_POWER_UPDATE")
Reg("UNIT_POWER_FREQUENT")
Reg("UNIT_MAXPOWER")
Reg("UNIT_FLAGS")
Reg("UPDATE_SHAPESHIFT_FORM")
Reg("PLAYER_COMBO_POINTS")
Reg("UNIT_COMBO_POINTS")

ev:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON then return end
        MirrasSimpleComboPointsDB = MirrasSimpleComboPointsDB or {}
        db = MirrasSimpleComboPointsDB
        for k, v in pairs(defaults) do
            if db[k] == nil then db[k] = Copy(v) end
        end
        db.source = nil
        ns.db = db
        BuildFrames()
        if ns.BuildOptions then ns.BuildOptions() end
        if db.loginMessage then
            Print("loaded – type /mscp to open the settings.")
        end
        return
    end
    if not db then return end
    if event == "NAME_PLATE_UNIT_REMOVED" then
        C_Timer.After(0, Update)
        return
    end
    Update()
end)

local elapsed = 0
ev:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed >= 0.2 then
        elapsed = 0
        if db then Update() end
    end
end)

local function Debug()
    Print("--- Diagnostics ---")
    print("  Interface:", select(4, GetBuildInfo()), " Build:", (GetBuildInfo()))
    print("  Target exists:", UnitExists("target"), " attackable:", tostring(UnitCanAttack("player", "target")))
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit("target")
    print("  Nameplate:", plate and "yes" or "NO")
    if plate then
        local _, kind = GetAnchorFrame(plate)
        print("  Anchor:", kind)
    end
    if GetComboPoints then
        local ok, c = pcall(GetComboPoints, "player", "target")
        print("  GetComboPoints:", ok and (IsSecret(c) and "<protected>" or tostring(c)) or "error")
    else
        print("  GetComboPoints: not available")
    end

    print("  Status:", lastReason)
end

SLASH_MIRRASSIMPLECOMBOPOINTS1 = "/mscp"
SLASH_MIRRASSIMPLECOMBOPOINTS2 = "/mirrascombopoints"
SlashCmdList.MIRRASSIMPLECOMBOPOINTS = function(input)
    local cmd, val = strsplit(" ", (input or ""):lower(), 2)
    local n = tonumber(val)
    if cmd == "" or cmd == "config" or cmd == "options" then
        if ns.OpenOptions then ns.OpenOptions() end
        return
    elseif cmd == "window" then
        if ns.OpenCustomWindow then ns.OpenCustomWindow() end
        return
    elseif cmd == "debug" then
        Debug()
        if ns.nativeError then print("  Native settings panel failed:", tostring(ns.nativeError)) end
        return
    elseif cmd == "size" and n then
        db.size = math.max(4, math.min(40, n))
    elseif cmd == "spacing" and n then
        db.spacing = math.max(0, math.min(20, n))
    elseif cmd == "x" and n then
        db.offsetX = n
    elseif cmd == "y" and n then
        db.offsetY = n
    elseif cmd == "top" or cmd == "bottom" then
        db.anchor = cmd:upper()
    elseif cmd == "empty" then
        db.hideEmpty = not db.hideEmpty
        Print("Hide at 0 points: " .. (db.hideEmpty and "on" or "off"))
    elseif cmd == "login" then
        db.loginMessage = not db.loginMessage
        Print("Login message: " .. (db.loginMessage and "on" or "off"))
    elseif cmd == "slots" then
        db.showEmpty = not db.showEmpty
        Print("Show empty slots: " .. (db.showEmpty and "on" or "off"))
    elseif cmd == "reset" then
        for k, v in pairs(defaults) do db[k] = Copy(v) end
        Print("Settings reset.")
    elseif cmd ~= "help" then
        Print("Unknown command – /mscp help")
        return
    else
        Print("Commands:")
        print("  /mscp                  – open settings (Options -> AddOns)")
        print("  /mscp window           – open the compact settings window")
        print("  /mscp debug            – print diagnostics")
        print("  /mscp size <4-40>      – pip size (current " .. db.size .. ")")
        print("  /mscp spacing <0-20>   – spacing (current " .. db.spacing .. ")")
        print("  /mscp x <n> | y <n>    – offset (current " .. db.offsetX .. " / " .. db.offsetY .. ")")
        print("  /mscp top | bottom     – above/below the health bar")
        print("  /mscp empty            – toggle hide at 0 points")
        print("  /mscp slots            – toggle empty slots")
        print("  /mscp login            – toggle login chat message")
        print("  /mscp reset            – restore defaults")
        return
    end
    Update()
    if ns.RefreshOptions then ns.RefreshOptions() end
end
