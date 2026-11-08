-- ForeverBuffReminder (WoW Forever, Druid)
-- Minimal missing-buff reminder: Mark of the Wild / Thorns. Click icon to cast.
-- Secure/taint-safe: no OnClick/PreClick/PostClick handlers on secure buttons.

local ADDON = "ForeverBuffReminder"
local VERSION = "1.0.0"
local DB

local DEFAULTS = {
    locked = true,
    showMotW = true,
    showThorns = true,
    cancelForm = false,   -- /cancelform + /cast macro mode (rarely needed)
    scale = 1.0,
    alpha = 1.0,
    pulse = true,
    sound = true,
    showInCombat = true,
    firstRun = true,
    point = "CENTER",
    relPoint = "CENTER",
    x = 0,
    y = -170,
}

local TRACKED = {
    { key = "showMotW",   id = 1126, fallback = "Mark of the Wild", short = "Mark",   color = { 1.00, 0.82, 0.20 } },
    { key = "showThorns", id = 467,  fallback = "Thorns",          short = "Thorns", color = { 0.55, 0.90, 0.45 } },
}

local root = CreateFrame("Frame", ADDON .. "Frame", UIParent)
root:SetClampedToScreen(true)
root:SetMovable(true)
root:EnableMouse(false) -- children handle input
root:SetFrameStrata("MEDIUM")
root:SetFrameLevel(50)
root:Hide()

local buttons = {}
local pending = false
local pulseT = 0
local forceTest = false

local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66c6ffForever Buff Reminder:|r " .. tostring(msg))
    end
end

local function GetSpellData(id, fallback)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(id)
        if info and info.name and info.name ~= "" then
            return info.name, info.iconID
        end
    end
    if GetSpellInfo then
        local name, _, icon = GetSpellInfo(id)
        if name and name ~= "" then return name, icon end
        name, _, icon = GetSpellInfo(fallback)
        if name and name ~= "" then return name, icon end
    end
    return fallback, 134400
end

local function SpellKnown(id, name)
    if not id and not name then return nil end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, id)
        if ok and known then return true end
    end
    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, id)
        if ok and known then return true end
    end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, id)
        if ok and known then return true end
    end
    if name and GetSpellInfo then
        local n = GetSpellInfo(name)
        if n and n ~= "" then return true end
    end
    return nil
end

local function HasBuff(spellId, spellName)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local a = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
            if not a then break end
            if (spellId and a.spellId == spellId) or (spellName and a.name == spellName) then return true end
        end
        return false
    end
    if UnitAura then
        for i = 1, 40 do
            local name, _, _, _, _, _, _, _, _, sid = UnitAura("player", i, "HELPFUL")
            if not name then break end
            if (spellId and sid == spellId) or (spellName and name == spellName) then return true end
        end
        return false
    end
    if UnitBuff then
        for i = 1, 40 do
            local name, _, _, _, _, _, _, _, _, sid = UnitBuff("player", i)
            if not name then break end
            if (spellId and sid == spellId) or (spellName and name == spellName) then return true end
        end
        return false
    end
    return false
end

local function SavePosition()
    local point, _, relPoint, x, y = root:GetPoint(1)
    if point then
        DB.point, DB.relPoint, DB.x, DB.y = point, relPoint, x, y
    end
end

local function ApplyPosition()
    root:ClearAllPoints()
    root:SetPoint(DB.point or "CENTER", UIParent, DB.relPoint or "CENTER", DB.x or 0, DB.y or -170)
end

local function ApplyVisuals()
    root:SetScale(DB.scale or 1)
    root:SetAlpha(DB.alpha or 1)
end

local function UpdateSecure(btn, spellName)
    if InCombatLockdown() then pending = true; return end
    btn:SetAttribute("type1", nil); btn:SetAttribute("spell1", nil); btn:SetAttribute("macrotext1", nil)
    btn:SetAttribute("*type1", nil); btn:SetAttribute("*spell1", nil); btn:SetAttribute("*macrotext1", nil)
    btn:SetAttribute("useOnKeyDown", false)
    if DB.cancelForm then
        local macro = "/cancelform\n/cast " .. spellName
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", macro)
        btn:SetAttribute("spell", nil)
        btn._mode = "macro"
    else
        btn:SetAttribute("type", "spell")
        btn:SetAttribute("spell", spellName)
        btn:SetAttribute("macrotext", nil)
        btn._mode = "spell"
    end
    btn._spellName = spellName
end

local function SetTooltip(btn, t)
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    local name = btn._spellName or t.fallback
    if GameTooltip.SetSpellByID and t.id then
        local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, t.id)
        if not ok then GameTooltip:SetText(name, 1, 1, 1) end
    else
        GameTooltip:SetText(name, 1, 1, 1)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Click|r to cast", 0.9, 0.9, 0.9)
    if DB.cancelForm then
        GameTooltip:AddLine("Mode: auto cancel form, then cast", 0.7, 0.8, 1)
    end
    GameTooltip:AddLine("|cff888888Shift+Drag|r to move  |cff888888/fbr|r options", 0.55, 0.55, 0.55)
    GameTooltip:Show()
end

local function SkinIcon(btn, t)
    -- Clean native feel without fragile action-bar art (avoids "inner square" artifacts).
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", -3, 3)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetTexture(134400)
    btn.icon = icon

    local function Edge(point, rel, x, y, w, h)
        local e = btn:CreateTexture(nil, "BORDER")
        e:SetColorTexture(0, 0, 0, 0.9)
        e:SetPoint(point, btn, rel, x, y)
        e:SetSize(w, h)
        return e
    end
    btn._edges = {
        Edge("TOPLEFT", "TOPLEFT", 0, 0, 40, 1),
        Edge("BOTTOMLEFT", "BOTTOMLEFT", 0, 0, 40, 1),
        Edge("TOPLEFT", "TOPLEFT", 0, 0, 1, 40),
        Edge("TOPRIGHT", "TOPRIGHT", 0, 0, 1, 40),
    }

    local ring = btn:CreateTexture(nil, "OVERLAY")
    ring:SetPoint("TOPLEFT", 1, -1)
    ring:SetPoint("BOTTOMRIGHT", -1, 1)
    ring:SetColorTexture(t.color[1], t.color[2], t.color[3], 0)
    btn.ring = ring

    local inner = {}
    local function RingEdge(point, rel, x, y, w, h)
        local e = btn:CreateTexture(nil, "OVERLAY", nil, 1)
        e:SetColorTexture(t.color[1], t.color[2], t.color[3], 0.95)
        e:SetPoint(point, btn, rel, x, y)
        e:SetSize(w, h)
        table.insert(inner, e)
    end
    RingEdge("TOPLEFT", "TOPLEFT", 1, -1, 38, 2)
    RingEdge("BOTTOMLEFT", "BOTTOMLEFT", 1, 1, 38, 2)
    RingEdge("TOPLEFT", "TOPLEFT", 1, -1, 2, 38)
    RingEdge("TOPRIGHT", "TOPRIGHT", -1, -1, 2, 38)
    btn._ringEdges = inner

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 3, -3)
    hl:SetPoint("BOTTOMRIGHT", -3, 3)
    hl:SetColorTexture(1, 1, 1, 0.18)
end

local function CreateButton(t)
    -- SecureActionButtonTemplate: NEVER add OnClick/PreClick/PostClick (taints secure cast).
    local btn = CreateFrame("Button", ADDON .. "_Btn_" .. t.key, root, "SecureActionButtonTemplate")
    btn:SetSize(40, 40)
    btn:EnableMouse(true)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:RegisterForDrag("LeftButton")

    SkinIcon(btn, t)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", btn, "BOTTOM", 0, -1)
    label:SetText(t.short)
    label:SetTextColor(t.color[1], t.color[2], t.color[3])
    btn.label = label

    btn:SetScript("OnDragStart", function()
        if not InCombatLockdown() and (not DB.locked or IsShiftKeyDown()) then root:StartMoving() end
    end)
    btn:SetScript("OnDragStop", function()
        if not InCombatLockdown() then root:StopMovingOrSizing(); SavePosition() end
    end)
    btn:SetScript("OnEnter", function(self) SetTooltip(self, t) end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn.track = t
    return btn
end

local function Layout()
    local shown = {}
    for _, t in ipairs(TRACKED) do
        local b = buttons[t.key]
        if b and b:IsShown() then table.insert(shown, b) end
    end
    local gap, padX, padY = 8, 0, 0
    local w = 40
    local n = #shown
    if n == 0 then root:SetSize(1, 1); return end
    root:SetSize(padX * 2 + n * w + (n - 1) * gap, padY + w + 14)
    for i, b in ipairs(shown) do
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", root, "TOPLEFT", padX + (i - 1) * (w + gap), -padY)
    end
end

local Refresh -- forward

root:SetScript("OnUpdate", function(self, elapsed)
    if not DB or not DB.pulse or not self:IsShown() then return end
    pulseT = pulseT + elapsed
    local a = 0.45 + 0.5 * (0.5 + 0.5 * math.sin(pulseT * 4.0))
    for _, t in ipairs(TRACKED) do
        local b = buttons[t.key]
        if b and b:IsShown() and b._ringEdges then
            for _, e in ipairs(b._ringEdges) do e:SetAlpha(a) end
        end
    end
end)

local function PlayReadyHint()
    if DB and DB.sound and PlaySound then
        pcall(PlaySound, 569593)
    end
end

Refresh = function()
    if not DB then return end
    if InCombatLockdown() then pending = true; return end
    pending = false

    local _, class = UnitClass("player")
    if class ~= "DRUID" and not forceTest then root:Hide(); return end

    local any, changedVisible = false, false
    for _, t in ipairs(TRACKED) do
        local b = buttons[t.key]
        if not b then b = CreateButton(t); buttons[t.key] = b end
        local name, icon = GetSpellData(t.id, t.fallback)
        UpdateSecure(b, name)
        if icon and b.icon then b.icon:SetTexture(icon) end
        b._known = SpellKnown(t.id, name)

        local missing = forceTest or (DB[t.key] and not HasBuff(t.id, name))
        local wasShown = b:IsShown()
        if missing then
            b:Show(); any = true
            if b._known == false then
                b.icon:SetDesaturated(true); b.icon:SetAlpha(0.55)
            else
                b.icon:SetDesaturated(false); b.icon:SetAlpha(1)
            end
        else
            b:Hide()
        end
        if wasShown ~= b:IsShown() then changedVisible = true end
    end

    if any then
        Layout(); ApplyVisuals(); root:Show()
        if changedVisible and not forceTest then PlayReadyHint() end
        if DB.firstRun then
            DB.firstRun = false
            Print("Missing buffs shown. Click an icon to cast. Shift+drag to move. /fbr for options.")
        end
    else
        forceTest = false
        root:Hide()
    end
end

local function Init()
    if type(ForeverBuffReminderDB) ~= "table" then ForeverBuffReminderDB = {} end
    DB = ForeverBuffReminderDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
    ApplyPosition(); ApplyVisuals(); Refresh()
    Print("v" .. VERSION .. " ready. |cff66c6ff/fbr|r options, |cff66c6ff/fbr move|r to reposition.")
end

root:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        Init()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pending and DB then Refresh() end
    elseif event == "UNIT_AURA" then
        if arg1 == "player" and DB then Refresh() end
    elseif DB then
        Refresh()
    end
end)

root:RegisterEvent("PLAYER_LOGIN")
root:RegisterEvent("PLAYER_ENTERING_WORLD")
root:RegisterEvent("UNIT_AURA")
root:RegisterEvent("SPELLS_CHANGED")
root:RegisterEvent("PLAYER_REGEN_ENABLED")

local function Help()
    Print("options:")
    print("  /fbr lock | unlock        lock/unlock position")
    print("  /fbr move                 show & unlock to reposition")
    print("  /fbr motw | thorns        toggle reminders")
    print("  /fbr scale <0.6-2.0>      icon size")
    print("  /fbr pulse | sound        toggle pulse / hint sound")
    print("  /fbr reset                reset position")
    print("  /fbr test                 show icons for testing")
    print("  /fbr debug                status")
    print("  /fbr rl                   reload UI")
end

SLASH_FOREVERBUFFREMINDER1 = "/fbr"
SLASH_FOREVERBUFFREMINDER2 = "/foreverbuff"
SlashCmdList.FOREVERBUFFREMINDER = function(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    if not DB then Print("not ready yet."); return end

    if cmd == "" or cmd == "help" or cmd == "?" then
        Help()
    elseif cmd == "lock" then
        DB.locked = true; root:EnableMouse(false); Print("Locked."); Refresh()
    elseif cmd == "unlock" or cmd == "move" then
        DB.locked = false; root:EnableMouse(true); forceTest = true
        Print("Unlocked - drag icons with Shift (or while unlocked), then /fbr lock."); Refresh()
    elseif cmd == "motw" then
        DB.showMotW = not DB.showMotW; Print("Mark of the Wild: " .. (DB.showMotW and "|cff00ff00ON|r" or "|cffff4040OFF|r")); Refresh()
    elseif cmd == "thorns" then
        DB.showThorns = not DB.showThorns; Print("Thorns: " .. (DB.showThorns and "|cff00ff00ON|r" or "|cffff4040OFF|r")); Refresh()
    elseif cmd == "scale" then
        local n = tonumber(rest)
        if n then DB.scale = math.max(0.6, math.min(2.0, n)); ApplyVisuals(); Print("Scale: " .. string.format("%.2f", DB.scale))
        else Print("Usage: /fbr scale 1.0") end
    elseif cmd == "pulse" then
        DB.pulse = not DB.pulse; Print("Pulse: " .. (DB.pulse and "ON" or "OFF"))
    elseif cmd == "sound" then
        DB.sound = not DB.sound; Print("Sound: " .. (DB.sound and "ON" or "OFF"))
    elseif cmd == "form" or cmd == "cancelform" then
        DB.cancelForm = not DB.cancelForm; Print("Cancel-form macro: " .. (DB.cancelForm and "ON" or "OFF")); Refresh()
    elseif cmd == "test" then
        forceTest = not forceTest; Print("Test: " .. (forceTest and "ON" or "OFF")); Refresh()
    elseif cmd == "reset" then
        DB.point, DB.relPoint, DB.x, DB.y = "CENTER", "CENTER", 0, -170
        ApplyPosition(); Print("Position reset.")
    elseif cmd == "debug" then
        Print(string.format("v%s combat=%s locked=%s class=%s", VERSION, tostring(InCombatLockdown()), tostring(DB.locked), tostring(select(2, UnitClass("player")))))
        for _, t in ipairs(TRACKED) do
            local b = buttons[t.key]
            local name = b and b._spellName or GetSpellData(t.id, t.fallback)
            Print(string.format("%s: enabled=%s has=%s shown=%s mode=%s type=%s spell=%s",
                t.short, tostring(DB[t.key]), tostring(HasBuff(t.id, name)),
                tostring(b and b:IsShown()), tostring(b and b._mode),
                tostring(b and b:GetAttribute("type")), tostring(b and b:GetAttribute("spell"))))
        end
    elseif cmd == "rl" or cmd == "reload" then
        ReloadUI()
    elseif cmd == "cast" then
        local which = (rest or ""):lower()
        local t = which:find("thorn") and TRACKED[2] or TRACKED[1]
        local name = GetSpellData(t.id, t.fallback)
        if CastSpellByName then CastSpellByName(name); Print("Attempted: " .. name) else Print("CastSpellByName unavailable.") end
    else
        Print("Unknown command. Try /fbr help")
    end
end

SLASH_FBRRELOAD1 = "/rl"
SlashCmdList.FBRRELOAD = function() ReloadUI() end
