-- wow-forever-buff-reminder-addon (WoW Forever) - ByJTT Foundation Reference
-- Display name: "WoW Forever Buff Reminder Addon ByJTT" (AddonName ByJTT style)
-- Data-driven missing-buff reminders for all classes/races (curated catalog, extensible).
-- Secure click-to-cast (taint-safe): NO OnClick/PreClick/PostClick on secure buttons.
--   Protected attribute/visibility changes are deferred out of combat.
-- https://github.com/ByJTT/wow-forever-buff-reminder-addon

local ADDON_NAME = "ForeverBuffReminder" -- in-game folder/TOC name (must remain stable)
local REPO_NAME  = "wow-forever-buff-reminder-addon"
local DISPLAY_NAME = "WoW Forever Buff Reminder Addon ByJTT"
local ns = {}
local VERSION = "2.0.0"
local SCHEMA = 2
local DB

-- ByJTT foundation namespace (reference pattern for future ByJTT addons)
ByJTT = ByJTT or {}
ByJTT.Brand = ByJTT.Brand or {
    name = "ByJTT",
    web = "https://byjtt.com",
    github = "https://github.com/ByJTT",
    -- PLACEHOLDER: replace with your real Buy Me a Coffee URL when ready.
    support = "https://buymeacoffee.com/ByJTT",
    supportLabel = "Buy Me a Coffee",
}
ByJTT.Addons = ByJTT.Addons or {}
ByJTT.Addons[ADDON_NAME] = ns
ns._version = VERSION
ns._schema = SCHEMA
ns._repo = REPO_NAME
ns._displayName = DISPLAY_NAME
ns._brand = ByJTT.Brand

--------------------------------------------------------------------------------
-- Compat / providers (WoW Forever: Interface 16001/30300; feature-detect + pcall)
--------------------------------------------------------------------------------
local Compat = {}
ns.Compat = Compat

function Compat.SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e = pcall(fn, ...)
    if ok then return a, b, c, d, e end
    return nil
end

function Compat.GetSpellData(id, fallbackName)
    if id and C_Spell and C_Spell.GetSpellInfo then
        local info = Compat.SafeCall(C_Spell.GetSpellInfo, id)
        if type(info) == "table" and info.name and info.name ~= "" then
            return info.name, info.iconID, info.spellID or id
        end
        if type(info) == "string" and info ~= "" then
            return info, Compat.SafeCall(C_Spell.GetSpellTexture, id), id
        end
    end
    if id and GetSpellInfo then
        local name, _, icon = GetSpellInfo(id)
        if name and name ~= "" then return name, icon, id end
    end
    local fb = fallbackName
    if fb and GetSpellInfo then
        local name, _, icon = GetSpellInfo(fb)
        if name and name ~= "" then return name, icon, id end
    end
    return fb or (id and ("spell:" .. tostring(id))) or "?", 134400, id
end

function Compat.IsSpellKnown(rule)
    -- Check prioritized spell IDs/names; if nothing checkable, treat as "unknown" (don't show as castable-known).
    local ids = (rule.cast and rule.cast.spellIds) or (rule.known and rule.known.spellIds) or (rule.aura and rule.aura.spellIds) or {}
    local names = (rule.cast and rule.cast.names) or {}
    local foundAny = false
    for _, id in ipairs(ids) do
        if id then
            foundAny = true
            if C_SpellBook and C_SpellBook.IsSpellKnown and Compat.SafeCall(C_SpellBook.IsSpellKnown, id) then return true end
            if IsSpellKnown and Compat.SafeCall(IsSpellKnown, id) then return true end
            if IsPlayerSpell and Compat.SafeCall(IsPlayerSpell, id) then return true end
            -- fall through to name resolution
            local n = Compat.SafeCall(GetSpellInfo, id)
            if n and n ~= "" then return true end
        end
    end
    for _, name in ipairs(names) do
        if name and name ~= "" then
            foundAny = true
            local n = Compat.SafeCall(GetSpellInfo, name)
            if n and n ~= "" then return true end
        end
    end
    if not foundAny then return nil end -- indeterminate
    return false
end

function Compat.HasAura(spellIds, names, unit)
    unit = unit or "player"
    local idset
    if spellIds and #spellIds > 0 then
        idset = {}
        for _, id in ipairs(spellIds) do if id then idset[id] = true end end
    end
    local nameset
    if names and #names > 0 then
        nameset = {}
        for _, n in ipairs(names) do if n and n ~= "" then nameset[n] = true end end
    end
    if not idset and not nameset then return false end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local a = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
            if not a then break end
            if idset and a.spellId and idset[a.spellId] then return true end
            if nameset and a.name and nameset[a.name] then return true end
        end
        return false
    end
    if UnitAura then
        for i = 1, 40 do
            local name, _, _, _, _, _, _, _, _, sid = UnitAura(unit, i, "HELPFUL")
            if not name then break end
            if idset and sid and idset[sid] then return true end
            if nameset and name and nameset[name] then return true end
        end
        return false
    end
    if UnitBuff then
        for i = 1, 40 do
            local name, _, _, _, _, _, _, _, _, sid = UnitBuff(unit, i)
            if not name then break end
            if idset and sid and idset[sid] then return true end
            if nameset and name and nameset[name] then return true end
        end
        return false
    end
    return false
end

function Compat.PlayerInfo()
    local _, class = UnitClass("player")
    local _, race = UnitRace("player")
    local level = UnitLevel and UnitLevel("player") or 0
    return { class = class, race = race, level = level }
end

function Compat.InCombat()
    return InCombatLockdown and InCombatLockdown() or false
end

--------------------------------------------------------------------------------
-- SavedVariables: defaults, schema, migrations (preserve v1.0.1 keys/settings)
--------------------------------------------------------------------------------
local GLOBAL_DEFAULTS = {
    _schema = SCHEMA,
    _version = VERSION,
    locked = true,
    scale = 1.0,
    alpha = 1.0,
    pulse = true,
    sound = true,
    showInCombat = true, -- explicit (was present but unused in v1)
    grow = "RIGHT",      -- RIGHT or DOWN
    debug = false,
    firstRun = true,
    onboardingDone = false,
    onboardingDismissed = false,
    point = "CENTER",
    relPoint = "CENTER",
    x = 0,
    y = -170,
    rules = {}, -- [ruleId] = boolean
}

local function EnsureDB()
    if type(ForeverBuffReminderDB) ~= "table" then ForeverBuffReminderDB = {} end
    DB = ForeverBuffReminderDB
end

local function ApplyDefaults(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            if type(v) == "table" then
                local t = {}
                ApplyDefaults(t, v)
                dst[k] = t
            else
                dst[k] = v
            end
        end
    end
end

local function MigrateDB(catalog)
    -- v1.0.1 -> v2 schema migration. Preserve legacy keys; never delete unknown keys.
    local legacySchema = not DB._schema
    if legacySchema then
        -- map legacy per-buff toggles to rule ids
        DB.rules = DB.rules or {}
        if DB.showMotW ~= nil and DB.rules["druid_motw"] == nil then DB.rules["druid_motw"] = DB.showMotW end
        if DB.showThorns ~= nil and DB.rules["druid_thorns"] == nil then DB.rules["druid_thorns"] = DB.showThorns end
        -- legacy cancelForm stays as global compat flag (used by UpdateSecure)
        if DB.firstRun == true and DB.onboardingDone == nil then DB.onboardingDone = false end
        DB._schema = 1 -- mark migrated-from-legacy; will set to SCHEMA below
    end
    -- ensure defaults and schema version
    if type(DB.rules) ~= "table" then DB.rules = {} end
    ApplyDefaults(DB, GLOBAL_DEFAULTS)
    -- seed rule defaults from catalog (only if unset) so recommended class buffs work
    if catalog then
        for _, r in ipairs(catalog) do
            if DB.rules[r.id] == nil then DB.rules[r.id] = r.enabledDefault ~= false end
        end
    end
    DB._schema = SCHEMA
    DB._version = VERSION
end

--------------------------------------------------------------------------------
-- Buff catalog (curated v1, WoW Forever target) - data-driven, extensible
-- Spec: id, classes?, races?, category, label, short, color, enabledDefault,
--       aura={spellIds={}, names={}}, cast={spellIds={}, names={}},
--       priority, note?
-- Spell IDs/names are curated with conservative fallbacks; verify on WoW Forever.
--------------------------------------------------------------------------------
local Catalog = {}
ns.Catalog = Catalog

local function R(id, classes, label, short, color, auraIds, auraNames, castIds, castNames, opts)
    opts = opts or {}
    return {
        id = id, classes = classes, races = opts.races, category = opts.category or "self",
        label = label, short = short, color = color or {1, 1, 1},
        enabledDefault = (opts.enabledDefault ~= false),
        aura = { spellIds = auraIds or {}, names = auraNames or {}, unit = "player" },
        cast = { kind = "spell", spellIds = castIds or auraIds or {}, names = castNames or auraNames or {} },
        priority = opts.priority or 50,
        note = opts.note,
    }
end

local function BuildCatalog()
    local C = {}
    local function add(...) table.insert(C, R(...)) end
    -- DRUID (preserve v1 defaults/behavior; ids 1126 MotW, 467 Thorns)
    add("druid_motw", {"DRUID"}, "Mark of the Wild", "Mark", {1.00,0.82,0.20},
        {1126,5232,6756,5234,8907,9884,9885,26990}, {"Mark of the Wild"},
        {1126,5232,6756,5234,8907,9884,9885,26990}, {"Mark of the Wild"}, {priority=10})
    add("druid_thorns", {"DRUID"}, "Thorns", "Thorns", {0.55,0.90,0.45},
        {467,782,1075,8914,9756,9910,26992}, {"Thorns"},
        {467,782,1075,8914,9756,9910,26992}, {"Thorns"}, {priority=20})

    -- WARRIOR
    add("warrior_battle", {"WARRIOR"}, "Battle Shout", "Shout", {0.90,0.55,0.20},
        {6673,5242,6192,11549,11550,11551,25289,2048}, {"Battle Shout"},
        {6673,5242,6192,11549,11550,11551,25289}, {"Battle Shout"}, {priority=10})
    -- PRIEST
    add("priest_fort", {"PRIEST"}, "Power Word: Fortitude", "Fort", {0.95,0.95,0.85},
        {1243,1244,1245,2791,10937,10938,25389,21562}, {"Power Word: Fortitude"},
        {1243,1244,1245,2791,10937,10938,25389}, {"Power Word: Fortitude"}, {priority=10})
    add("priest_innerfire", {"PRIEST"}, "Inner Fire", "Inner", {0.95,0.85,0.55},
        {588,7128,602,1006,10951,10952,25431}, {"Inner Fire"},
        {588,7128,602,1006,10951,10952,25431}, {"Inner Fire"}, {priority=20})
    add("priest_shadowprot", {"PRIEST"}, "Shadow Protection", "Shadow", {0.70,0.55,0.95},
        {976,10957,10958,25433,27683}, {"Shadow Protection","Prayer of Shadow Protection"},
        {976,10957,10958,25433}, {"Shadow Protection"}, {priority=30, enabledDefault=false, note="Situational"})
    -- MAGE
    add("mage_ai", {"MAGE"}, "Arcane Intellect", "Int", {0.55,0.75,1.00},
        {1459,1460,1461,10156,10157,27126,23028}, {"Arcane Intellect","Arcane Brilliance"},
        {1459,1460,1461,10156,10157,27126}, {"Arcane Intellect"}, {priority=10})
    add("mage_armor_mage", {"MAGE"}, "Mage Armor", "M.Arm", {0.65,0.80,1.00},
        {6117,22782,22783,27125}, {"Mage Armor"},
        {6117,22782,22783,27125}, {"Mage Armor"}, {priority=20})
    add("mage_armor_frost", {"MAGE"}, "Frost Armor", "F.Arm", {0.55,0.85,1.00},
        {168,7300,7301,7302,7320,10219,10220,27124}, {"Frost Armor","Ice Armor"},
        {168,7300,7301,7302,7320,10219,10220,27124}, {"Frost Armor"}, {priority=21, enabledDefault=false, note="Alternative armor"})
    -- PALADIN (aura/blessing self-maintenance; blessing on self)
    add("paladin_devotion", {"PALADIN"}, "Devotion Aura", "Devot", {1.00,0.92,0.55},
        {465,10290,643,10291,1032,10292,10293,27149}, {"Devotion Aura"},
        {465,10290,643,10291,1032,10292,10293,27149}, {"Devotion Aura"}, {priority=10})
    add("paladin_might", {"PALADIN"}, "Blessing of Might", "Might", {1.00,0.75,0.35},
        {19740,19834,19835,19836,19837,19838,25291,27140}, {"Blessing of Might","Greater Blessing of Might"},
        {19740,19834,19835,19836,19837,19838,25291}, {"Blessing of Might"}, {priority=20})
    add("paladin_rf", {"PALADIN"}, "Righteous Fury", "RFury", {1.00,0.85,0.35},
        {25780}, {"Righteous Fury"},
        {25780}, {"Righteous Fury"}, {priority=30, enabledDefault=false, note="Tank/prot use"})
    -- HUNTER
    add("hunter_aspect_hawk", {"HUNTER"}, "Aspect of the Hawk", "Hawk", {0.85,0.95,0.55},
        {13165,14318,14319,14320,14321,14322,25296,27044}, {"Aspect of the Hawk"},
        {13165,14318,14319,14320,14321,14322,25296,27044}, {"Aspect of the Hawk"}, {priority=10})
    add("hunter_trueshot", {"HUNTER"}, "Trueshot Aura", "True", {0.95,0.80,0.45},
        {19506,20905,20906}, {"Trueshot Aura"},
        {19506,20905,20906}, {"Trueshot Aura"}, {priority=20, enabledDefault=false, note="If talented"})
    -- ROGUE (maintenance buffs; poisons/weapon enchants are out of scope for this foundation pass)
    add("rogue_blade_flurry", {"ROGUE"}, "Blade Flurry", "B.Flur", {0.95,0.85,0.45},
        {13877}, {"Blade Flurry"},
        {13877}, {"Blade Flurry"}, {priority=20, enabledDefault=false, note="Situational (talent, costs energy)"})
    add("rogue_sprint", {"ROGUE"}, "Sprint", "Sprint", {0.90,0.90,0.55},
        {2983,8696,11305}, {"Sprint"},
        {2983,8696,11305}, {"Sprint"}, {priority=30, enabledDefault=false, note="Short-duration; reminder may be noisy"})
    -- WARLOCK
    add("warlock_armor_demon", {"WARLOCK"}, "Demon Armor", "D.Arm", {0.75,0.55,0.95},
        {706,1086,11733,11734,11735,27260}, {"Demon Armor","Demon Skin"},
        {706,1086,11733,11734,11735,27260}, {"Demon Armor"}, {priority=10})
    add("warlock_detect", {"WARLOCK"}, "Detect Invisibility", "DetInv", {0.65,0.70,1.00},
        {132,2970,11743}, {"Detect Invisibility"},
        {132,2970,11743}, {"Detect Invisibility"}, {priority=30, enabledDefault=false, note="Situational"})
    -- SHAMAN (self weapon imbues are temporary weapon enchants - out of scope; Lightning Shield is a self buff)
    add("shaman_lightningshield", {"SHAMAN"}, "Lightning Shield", "L.Shld", {0.45,0.75,1.00},
        {324,325,905,945,8134,10431,10432,25469,25472}, {"Lightning Shield"},
        {324,325,905,945,8134,10431,10432,25469}, {"Lightning Shield"}, {priority=10})

    return C
end

Catalog.list = BuildCatalog()
Catalog.byId = {}
for _, r in ipairs(Catalog.list) do Catalog.byId[r.id] = r end

function ns:RegisterBuffPack(pack)
    if type(pack) ~= "table" then return end
    for _, r in ipairs(pack) do
        if type(r) == "table" and r.id and not Catalog.byId[r.id] then
            table.insert(Catalog.list, r)
            Catalog.byId[r.id] = r
            if DB and DB.rules and DB.rules[r.id] == nil then DB.rules[r.id] = r.enabledDefault ~= false end
        end
    end
end

--------------------------------------------------------------------------------
-- Evaluation engine (read/plan/apply separation)
--------------------------------------------------------------------------------
local function RuleEnabled(rule)
    if not DB or not DB.rules then return rule.enabledDefault ~= false end
    local v = DB.rules[rule.id]
    if v == nil then return rule.enabledDefault ~= false end
    return v and true or false
end

local function RuleAppliesToPlayer(rule, pinfo)
    if rule.classes then
        local ok = false
        for _, c in ipairs(rule.classes) do if c == pinfo.class then ok = true break end end
        if not ok then return false end
    end
    if rule.races then
        local ok = false
        for _, rc in ipairs(rule.races) do if rc == pinfo.race then ok = true break end end
        if not ok then return false end
    end
    return true
end

local function ResolveRule(rule)
    local auraIds = rule.aura and rule.aura.spellIds or {}
    local auraNames = rule.aura and rule.aura.names or {}
    local castIds = rule.cast and rule.cast.spellIds or auraIds
    local castNames = rule.cast and rule.cast.names or auraNames
    local primaryId = castIds[1] or auraIds[1]
    local fallback = castNames[1] or auraNames[1] or rule.label
    local name, icon, resolvedId = Compat.GetSpellData(primaryId, fallback)
    -- also accept any cast name for "known" resolution feel
    if (not name or name == "?") and castNames[1] then name = castNames[1] end
    local known = Compat.IsSpellKnown(rule)
    local has = Compat.HasAura(auraIds, auraNames, "player")
    return {
        rule = rule, id = rule.id, label = rule.label, short = rule.short or rule.label,
        color = rule.color or {1,1,1}, name = name, icon = icon, resolvedId = resolvedId or primaryId,
        known = known, has = has, enabled = RuleEnabled(rule),
        auraIds = auraIds, auraNames = auraNames,
    }
end

local function BuildPlan(forceTest)
    local pinfo = Compat.PlayerInfo()
    local plan = { pinfo = pinfo, items = {}, missing = 0 }
    for _, rule in ipairs(Catalog.list) do
        if RuleAppliesToPlayer(rule, pinfo) and (RuleEnabled(rule) or forceTest) then
            local st = ResolveRule(rule)
            if forceTest or not st.has then
                table.insert(plan.items, st)
                plan.missing = plan.missing + 1
            end
        end
    end
    table.sort(plan.items, function(a,b) return (a.rule.priority or 50) < (b.rule.priority or 50) end)
    return plan
end

--------------------------------------------------------------------------------
-- UI: root, secure button pool, skinning (WoW-authentic, minimal)
-- INVARIANTS: SecureActionButtonTemplate; NO OnClick/PreClick/PostClick.
--------------------------------------------------------------------------------
local root = CreateFrame("Frame", ADDON_NAME .. "Frame", UIParent)
root:SetClampedToScreen(true)
root:SetMovable(true)
root:EnableMouse(false) -- children handle input
root:SetFrameStrata("MEDIUM")
root:SetFrameLevel(50)
root:Hide()

local buttons = {} -- [ruleId] = secure button
local pool = {}    -- reusable buttons
local pendingSecure = false
local pulseT = 0
local forceTest = false
local suppressNextHint = false
ns.root = root

local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66c6ffWoW Forever Buff Reminder Addon ByJTT:|r " .. tostring(msg))
    end
end
local function Debug(msg)
    if DB and DB.debug then Print("|cffaaaaaa[debug]|r " .. tostring(msg)) end
end
ns.Print = Print
ns.Debug = Debug

local function SavePosition()
    if not DB then return end
    local point, _, relPoint, x, y = root:GetPoint(1)
    if point then DB.point, DB.relPoint, DB.x, DB.y = point, relPoint, x, y end
end

local function ApplyPosition()
    if not DB then return end
    root:ClearAllPoints()
    root:SetPoint(DB.point or "CENTER", UIParent, DB.relPoint or "CENTER", DB.x or 0, DB.y or -170)
end

local function ApplyVisuals()
    if not DB then return end
    root:SetScale(DB.scale or 1)
    root:SetAlpha(DB.alpha or 1)
end

-- Secure attribute apply - ONLY out of combat. Centralized for taint safety.
local function UpdateSecure(btn, st)
    if Compat.InCombat() then pendingSecure = true; return false end
    -- clear legacy/variant attributes
    btn:SetAttribute("type1", nil); btn:SetAttribute("spell1", nil); btn:SetAttribute("macrotext1", nil)
    btn:SetAttribute("*type1", nil); btn:SetAttribute("*spell1", nil); btn:SetAttribute("*macrotext1", nil)
    btn:SetAttribute("useOnKeyDown", false)
    local spellName = st.name
    if DB and DB.cancelForm then
        local macro = "/cancelform\n/cast " .. (spellName or st.label)
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
    btn._ruleId = st.id
    return true
end

local function SetTooltip(btn)
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    local st = btn._st
    local name = (st and st.name) or btn._spellName or "Buff"
    local shown = false
    if st and st.resolvedId and GameTooltip.SetSpellByID then
        shown = Compat.SafeCall(GameTooltip.SetSpellByID, GameTooltip, st.resolvedId) and true or false
    end
    if not shown then GameTooltip:SetText(name, 1, 1, 1) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Click|r to cast/apply", 0.9, 0.9, 0.9)
    if st and st.rule and st.rule.note then
        GameTooltip:AddLine(st.rule.note, 0.8, 0.8, 0.8, true)
    end
    if DB and DB.cancelForm then
        GameTooltip:AddLine("Mode: auto cancel form, then cast", 0.7, 0.8, 1)
    end
    if st and st.known == false then
        GameTooltip:AddLine("Spell not known/available on this character.", 1, 0.6, 0.2, true)
    end
    GameTooltip:AddLine("|cff888888Shift+Drag|r to move - |cff888888/fbr config|r settings", 0.55, 0.55, 0.55)
    GameTooltip:AddLine("|cff888888WoW Forever Buff Reminder Addon ByJTT|r", 0.45, 0.45, 0.45)
    GameTooltip:Show()
end

local function SkinIcon(btn, color)
    color = color or {1, 0.82, 0.2}
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
    Edge("TOPLEFT", "TOPLEFT", 0, 0, 40, 1)
    Edge("BOTTOMLEFT", "BOTTOMLEFT", 0, 0, 40, 1)
    Edge("TOPLEFT", "TOPLEFT", 0, 0, 1, 40)
    Edge("TOPRIGHT", "TOPRIGHT", 0, 0, 1, 40)

    local inner = {}
    local function RingEdge(point, rel, x, y, w, h)
        local e = btn:CreateTexture(nil, "OVERLAY", nil, 1)
        e:SetColorTexture(color[1], color[2], color[3], 0.95)
        e:SetPoint(point, btn, rel, x, y)
        e:SetSize(w, h)
        table.insert(inner, e)
    end
    RingEdge("TOPLEFT", "TOPLEFT", 1, -1, 38, 2)
    RingEdge("BOTTOMLEFT", "BOTTOMLEFT", 1, 1, 38, 2)
    RingEdge("TOPLEFT", "TOPLEFT", 1, -1, 2, 38)
    RingEdge("TOPRIGHT", "TOPRIGHT", -1, -1, 2, 38)
    btn._ringEdges = inner
    btn._ringColor = color

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 3, -3)
    hl:SetPoint("BOTTOMRIGHT", -3, 3)
    hl:SetColorTexture(1, 1, 1, 0.18)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", btn, "BOTTOM", 0, -1)
    label:SetTextColor(color[1], color[2], color[3])
    btn.label = label
end

local function RetintButton(btn, color)
    color = color or {1,1,1}
    btn._ringColor = color
    if btn._ringEdges then
        for _, e in ipairs(btn._ringEdges) do e:SetColorTexture(color[1], color[2], color[3], e:GetAlpha() or 0.95) end
    end
    if btn.label then btn.label:SetTextColor(color[1], color[2], color[3]) end
end

local function AcquireButton(ruleId)
    if buttons[ruleId] then return buttons[ruleId] end
    local btn = table.remove(pool)
    if not btn then
        local name = ADDON_NAME .. "_Btn_" .. tostring(#buttons + #pool + 1) .. "_" .. tostring(math.random(1000,9999))
        btn = CreateFrame("Button", name, root, "SecureActionButtonTemplate")
        btn:SetSize(40, 40)
        btn:EnableMouse(true)
        btn:RegisterForClicks("AnyUp", "AnyDown")
        btn:RegisterForDrag("LeftButton")
        SkinIcon(btn, {1,0.82,0.2})
        btn:SetScript("OnDragStart", function()
            if not Compat.InCombat() and DB and (not DB.locked or IsShiftKeyDown()) then root:StartMoving() end
        end)
        btn:SetScript("OnDragStop", function()
            if not Compat.InCombat() then root:StopMovingOrSizing(); SavePosition() end
        end)
        btn:SetScript("OnEnter", function(self) SetTooltip(self) end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    buttons[ruleId] = btn
    return btn
end

local function ReleaseUnused(activeSet)
    for id, btn in pairs(buttons) do
        if not activeSet[id] then
            if not Compat.InCombat() then
                btn:Hide()
                btn:ClearAllPoints()
                btn:SetAttribute("type", nil); btn:SetAttribute("spell", nil); btn:SetAttribute("macrotext", nil)
                btn._st = nil; btn._ruleId = nil
                buttons[id] = nil
                table.insert(pool, btn)
            else
                pendingSecure = true
            end
        end
    end
end

local function Layout(shown)
    local n = #shown
    if n == 0 then
        if not Compat.InCombat() then root:SetSize(1,1) end
        return
    end
    local w, h, gap = 40, 40, 8
    local grow = (DB and DB.grow) or "RIGHT"
    if grow == "DOWN" then
        root:SetSize(w, n * h + (n - 1) * gap + 14)
        for i, b in ipairs(shown) do
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -((i - 1) * (h + gap)))
        end
    else
        root:SetSize(n * w + (n - 1) * gap, h + 14)
        for i, b in ipairs(shown) do
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", root, "TOPLEFT", (i - 1) * (w + gap), 0)
        end
    end
end

root:SetScript("OnUpdate", function(self, elapsed)
    if not DB or not DB.pulse or not self:IsShown() then return end
    pulseT = pulseT + elapsed
    local a = 0.45 + 0.5 * (0.5 + 0.5 * math.sin(pulseT * 4.0))
    for _, b in pairs(buttons) do
        if b:IsShown() and b._ringEdges then
            local c = b._ringColor or {1,0.82,0.2}
            for _, e in ipairs(b._ringEdges) do e:SetColorTexture(c[1], c[2], c[3], a) end
        end
    end
end)

local function PlayReadyHint()
    if DB and DB.sound and PlaySound then pcall(PlaySound, 569593) end
end

--------------------------------------------------------------------------------
-- Onboarding (lightweight, WoW-authentic, re-openable)
--------------------------------------------------------------------------------
local onboard
local function DismissOnboarding(markDone)
    if not DB then return end
    DB.onboardingDismissed = true
    if markDone then DB.onboardingDone = true; DB.firstRun = false end
    if onboard and onboard.Hide then onboard:Hide() end
end

local function ShowOnboarding(force)
    if not DB then return end
    if not force and (DB.onboardingDone or DB.onboardingDismissed) then return end
    if Compat.InCombat() then pendingSecure = true; return end
    if not onboard then
        onboard = CreateFrame("Frame", ADDON_NAME .. "Onboard", UIParent, "BackdropTemplate")
        if not onboard.SetBackdrop and BackdropTemplateMixin then
            -- already applied by template on modern clients
        end
        onboard:SetSize(440, 255)
        onboard:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
        onboard:SetFrameStrata("DIALOG")
        onboard:SetClampedToScreen(true)
        onboard:EnableMouse(true)
        onboard:SetMovable(true)
        onboard:RegisterForDrag("LeftButton")
        onboard:SetScript("OnDragStart", function(self) if not Compat.InCombat() then self:StartMoving() end end)
        onboard:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        if onboard.SetBackdrop then
            onboard:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 }
            })
        else
            local bg = onboard:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(true)
            bg:SetColorTexture(0, 0, 0, 0.85)
        end
        local title = onboard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -18)
        title:SetText("|cff66c6ffWoW Forever Buff Reminder Addon ByJTT|r")
        onboard.title = title
        local body = onboard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        body:SetPoint("TOPLEFT", 22, -54)
        body:SetPoint("TOPRIGHT", -22, -54)
        body:SetJustifyH("LEFT")
        body:SetJustifyV("TOP")
        onboard.body = body
        local by = onboard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        by:SetPoint("TOP", title, "BOTTOM", 0, -2)
        by:SetText("|cffaaaaaaby ByJTT - " .. (ByJTT.Brand.web or "byjtt.com") .. "|r")
        onboard.by = by

        local function mkBtn(text, x, y, w, onClick)
            local b = CreateFrame("Button", nil, onboard, "UIPanelButtonTemplate")
            b:SetSize(w or 120, 22)
            b:SetPoint("BOTTOM", onboard, "BOTTOM", x, y)
            b:SetText(text)
            b:SetScript("OnClick", onClick)
            return b
        end
        mkBtn("Got it", 0, 16, 110, function() DismissOnboarding(true); Print("You're set. Missing buffs show as icons - click to cast. /fbr config for settings.") end)
        mkBtn("Open Settings", -125, 16, 110, function() DismissOnboarding(true); ns.OpenOptions() end)
        mkBtn("Later", 125, 16, 70, function() DismissOnboarding(false) end)
    end
    local p = Compat.PlayerInfo()
    local className = p.class or "your class"
    onboard.body:SetText(
        "Shows your missing class buffs as secure, click-to-cast icons (taint-safe). Only appears when something is missing.\n\n" ..
        "-  Recommended buffs for |cffffd200" .. className .. "|r are enabled by default.\n" ..
        "-  |cff00ff00Click|r an icon to cast. |cff888888Shift+Drag|r to move (or unlock via /fbr).\n" ..
        "-  Changes in combat are deferred for safety.\n\n" ..
        "Support: " .. (ByJTT.Brand.supportLabel or "Buy Me a Coffee") .. " (placeholder) - " .. (ByJTT.Brand.support or "") .. "\n" ..
        "Use |cff66c6ff/fbr config|r for settings."
    )
    onboard:Show()
end
ns.ShowOnboarding = ShowOnboarding

--------------------------------------------------------------------------------
-- Settings UI (Blizzard-native when available; feature-detected). Slash parity.
--------------------------------------------------------------------------------
local optionsPanel
local function EnsureOptionsPanel()
    if optionsPanel then return optionsPanel end
    local panel = CreateFrame("Frame", ADDON_NAME .. "OptionsPanel", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    panel.name = DISPLAY_NAME
    panel:Hide() -- shown on demand (Blizzard settings, or standalone fallback)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff66c6ffWoW Forever Buff Reminder Addon|r |cffaaaaaaby ByJTT|r")
    local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText("Data-driven missing-buff reminders (all classes/races). Secure click-to-cast. WoW Forever foundation reference. /fbr help")

    local y = -60
    local function mkCheck(label, get, set, tooltip)
        local cb = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, y)
        cb.Text:SetText(label)
        cb:SetScript("OnShow", function(self) self:SetChecked(get() and true or false) end)
        cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
        if tooltip then cb.tooltipText = label; cb.tooltipRequirement = tooltip end
        y = y - 26
        return cb
    end

    mkCheck("Lock position", function() return DB.locked end, function(v) DB.locked=v; Print("Locked: "..tostring(v)) end,
        "When locked, Shift+Drag moves the icons.")
    mkCheck("Pulse missing icons", function() return DB.pulse end, function(v) DB.pulse=v end)
    mkCheck("Play hint sound", function() return DB.sound end, function(v) DB.sound=v end)
    mkCheck("Show in combat (display only; actions defer)", function() return DB.showInCombat end, function(v) DB.showInCombat=v end)
    mkCheck("Auto cancel form before cast (macro mode)", function() return DB.cancelForm end, function(v) DB.cancelForm=v; ns.Refresh() end,
        "Uses /cancelform then /cast. Useful for shapeshifted Druids.")
    mkCheck("Debug logging", function() return DB.debug end, function(v) DB.debug=v end)

    local scaleLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    scaleLabel:SetPoint("TOPLEFT", 20, y - 4); scaleLabel:SetText("Scale")
    local slider = CreateFrame("Slider", ADDON_NAME.."ScaleSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 80, y)
    slider:SetMinMaxValues(0.6, 2.0); slider:SetValueStep(0.05); slider:SetObeyStepOnDrag(true)
    if slider.Low then slider.Low:SetText("0.6") end
    if slider.High then slider.High:SetText("2.0") end
    if slider.Text then slider.Text:SetText("") end
    slider:SetScript("OnShow", function(self) self:SetValue(DB.scale or 1.0) end)
    slider:SetScript("OnValueChanged", function(self, v) DB.scale = math.floor(v*100+0.5)/100; ApplyVisuals() end)
    y = y - 46

    local growBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    growBtn:SetSize(160, 22); growBtn:SetPoint("TOPLEFT", 16, y)
    local function updGrow() growBtn:SetText("Grow: "..((DB and DB.grow) or "RIGHT")) end
    growBtn:SetScript("OnShow", updGrow)
    growBtn:SetScript("OnClick", function() DB.grow = (DB.grow=="RIGHT") and "DOWN" or "RIGHT"; updGrow(); ns.Refresh() end)
    y = y - 30

    local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testBtn:SetSize(120, 22); testBtn:SetPoint("TOPLEFT", 16, y); testBtn:SetText("Toggle Test")
    testBtn:SetScript("OnClick", function() forceTest = not forceTest; Print("Test: "..(forceTest and "ON" or "OFF")); ns.Refresh() end)
    local onbBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    onbBtn:SetSize(140, 22); onbBtn:SetPoint("LEFT", testBtn, "RIGHT", 8, 0); onbBtn:SetText("Show Onboarding")
    onbBtn:SetScript("OnClick", function() DB.onboardingDone=false; DB.onboardingDismissed=false; ShowOnboarding(true) end)
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 22); resetBtn:SetPoint("LEFT", onbBtn, "RIGHT", 8, 0); resetBtn:SetText("Reset Position")
    resetBtn:SetScript("OnClick", function() DB.point,DB.relPoint,DB.x,DB.y="CENTER","CENTER",0,-170; ApplyPosition(); Print("Position reset.") end)
    y = y - 36

    local buffsHdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buffsHdr:SetPoint("TOPLEFT", 16, y)
    buffsHdr:SetText("Buffs (curated catalog) - toggle rules for your account/character")
    y = y - 8

    -- About / Support (ByJTT foundation branding)
    local about = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    about:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 16, 14)
    about:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 14)
    about:SetJustifyH("LEFT")
    about:SetText("|cff888888" .. DISPLAY_NAME .. " - v" .. VERSION .. " - by " .. (ByJTT.Brand.name or "ByJTT") ..
        " - " .. (ByJTT.Brand.web or "") .. " - " .. (ByJTT.Brand.github or "") ..
        "\nSupport (placeholder): " .. (ByJTT.Brand.support or "") .. "|r")
    panel._about = about

    local scroll = CreateFrame("ScrollFrame", ADDON_NAME.."BuffScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, y - 16)
    scroll:SetPoint("BOTTOMRIGHT", -34, 44) -- leave room for About/Support footer
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(520, 400)
    scroll:SetScrollChild(content)
    panel._buffContent = content

    panel.RefreshBuffs = function()
        if not DB then return end
        -- clear old children
        for _, child in ipairs({content:GetChildren()}) do child:Hide(); child:SetParent(nil) end
        local pinfo = Compat.PlayerInfo()
        local cy = -4
        local shownAny = false
        for _, r in ipairs(Catalog.list) do
            local applies = RuleAppliesToPlayer(r, pinfo)
            local cb = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 4, cy)
            local tag = applies and "" or " |cff888888(other class)|r"
            local def = (r.enabledDefault ~= false) and "" or " |cff888888(off by default)|r"
            cb.Text:SetText((r.label or r.id) .. tag .. def)
            cb:SetChecked(RuleEnabled(r))
            cb:SetScript("OnClick", function(self)
                DB.rules = DB.rules or {}
                DB.rules[r.id] = self:GetChecked() and true or false
                ns.Refresh()
            end)
            cy = cy - 24
            shownAny = true
        end
        if not shownAny then
            local t = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            t:SetPoint("TOPLEFT", 4, -4); t:SetText("No catalog entries.")
        end
        content:SetHeight(math.max(400, -cy + 20))
    end
    panel:SetScript("OnShow", function(self) if self.RefreshBuffs then self:RefreshBuffs() end end)

    optionsPanel = panel
    -- Register with Settings (Dragonflight+/modern) or InterfaceOptions (legacy) if available
    local registered = false
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, panel, panel.name)
        if ok and cat then
            cat.ID = panel.name
            pcall(Settings.RegisterAddOnCategory, cat)
            panel._settingsCategory = cat
            registered = true
        end
    end
    if not registered and InterfaceOptions_AddCategory then
        pcall(InterfaceOptions_AddCategory, panel)
        registered = true
    end
    panel._registered = registered
    return panel
end

function ns.OpenOptions()
    local p = EnsureOptionsPanel()
    if Settings and Settings.OpenToCategory and p and p._settingsCategory then
        pcall(Settings.OpenToCategory, p._settingsCategory.ID or p._settingsCategory)
        return
    end
    if InterfaceOptionsFrame_OpenToCategory and p then
        InterfaceOptionsFrame_OpenToCategory(p)
        InterfaceOptionsFrame_OpenToCategory(p) -- legacy quirk
        return
    end
    if not p then Print("Options UI not available; use /fbr commands."); return end

    -- Fallback: standalone movable dialog (Blizzard settings unavailable, e.g. Classic client).
    p:ClearAllPoints()
    p:SetSize(560, 480)
    p:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    p:SetFrameStrata("DIALOG")
    p:SetClampedToScreen(true)
    p:EnableMouse(true)
    p:SetMovable(true)
    p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", function(self) if not Compat.InCombat() then self:StartMoving() end end)
    p:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    if p.SetBackdrop and not p._backdropSet then
        p:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        p._backdropSet = true
    elseif not p.SetBackdrop and not p._fallbackBg then
        local bg = p:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(true)
        bg:SetColorTexture(0, 0, 0, 0.92)
        p._fallbackBg = bg
    end
    if not p._closeBtn then
        local close = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
        close:SetSize(80, 22)
        close:SetPoint("BOTTOM", p, "BOTTOM", 0, 16)
        close:SetText("Close")
        close:SetScript("OnClick", function() p:Hide() end)
        p._closeBtn = close
    end
    p:Show()
    Print("Options panel opened (standalone). Drag to move; Close to dismiss.")
end

--------------------------------------------------------------------------------
-- Refresh / apply (read plan -> secure apply). Defers in combat.
--------------------------------------------------------------------------------
local function ApplyPlan(plan)
    if not DB then return end
    if Compat.InCombat() then pendingSecure = true; return end
    pendingSecure = false

    local active = {}
    local shown = {}
    local changedVisible = false

    -- release rules no longer in plan
    local planSet = {}
    for _, st in ipairs(plan.items) do planSet[st.id] = true end
    ReleaseUnused(planSet)

    for _, st in ipairs(plan.items) do
        local b = AcquireButton(st.id)
        st.color = st.rule.color or st.color or {1,0.82,0.2}
        b._st = st
        if b.icon then b.icon:SetTexture(st.icon or 134400) end
        if b.label then b.label:SetText(st.short or st.label or "?") end
        RetintButton(b, st.color)
        UpdateSecure(b, st)
        local was = b:IsShown()
        b:Show()
        if st.known == false then
            if b.icon then b.icon:SetDesaturated(true); b.icon:SetAlpha(0.55) end
        else
            if b.icon then b.icon:SetDesaturated(false); b.icon:SetAlpha(1) end
        end
        active[st.id] = true
        table.insert(shown, b)
        if was ~= b:IsShown() then changedVisible = true end
    end

    ReleaseUnused(active)

    local shouldShow = #shown > 0 and (DB.showInCombat or not Compat.InCombat() or forceTest)
    if shouldShow then
        Layout(shown); ApplyVisuals(); root:Show()
        if changedVisible and not forceTest and not suppressNextHint then PlayReadyHint() end
        if DB.firstRun and not DB.onboardingDismissed and not DB.onboardingDone then
            -- trigger onboarding (deferred-safe); keep legacy safety: mark firstRun handled once shown
            DB.firstRun = false
            ShowOnboarding(false)
            Print("Missing buffs detected. Click an icon to cast. Shift+Drag to move. /fbr config for settings.")
        end
    else
        if #shown == 0 then forceTest = false end
        root:Hide()
    end
    suppressNextHint = false
end

function ns.Refresh()
    if not DB then return end
    if Compat.InCombat() then pendingSecure = true; return end
    local plan = BuildPlan(forceTest)
    ns._lastPlan = plan
    Debug("refresh: class="..tostring(plan.pinfo.class).." missing="..tostring(plan.missing)..(forceTest and " [test]" or ""))
    ApplyPlan(plan)
end
local Refresh = ns.Refresh

--------------------------------------------------------------------------------
-- Events / init
--------------------------------------------------------------------------------
local function Init()
    EnsureDB()
    MigrateDB(Catalog.list)
    ApplyPosition(); ApplyVisuals()
    EnsureOptionsPanel()
    Refresh()
    Print("v" .. VERSION .. " ready. " .. DISPLAY_NAME .. " - " .. (ByJTT.Brand.web or "byjtt.com") .. " - |cff66c6ff/fbr config|r")
    if not DB.onboardingDone and not DB.onboardingDismissed then
        -- show after a short moment so UI is settled; fallback if no timer
        if C_Timer and C_Timer.After then
            C_Timer.After(1.5, function() if DB and not DB.onboardingDone and not DB.onboardingDismissed then ShowOnboarding(false) end end)
        else
            ShowOnboarding(false)
        end
    end
end

root:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        Init()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if DB then
            if pendingSecure then Refresh() end
            if onboard and onboard:IsShown() == false and not DB.onboardingDone and not DB.onboardingDismissed and not Compat.InCombat() then
                -- no-op; onboarding shows via Init/timer or /fbr
            end
        end
    elseif event == "UNIT_AURA" then
        if arg1 == "player" and DB then Refresh() end
    elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "LEARNED_SPELL_IN_TAB" or event == "PLAYER_TALENT_UPDATE" then
        if DB then Refresh() end
    elseif DB then
        Refresh()
    end
end)

root:RegisterEvent("PLAYER_LOGIN")
root:RegisterEvent("PLAYER_ENTERING_WORLD")
root:RegisterEvent("UNIT_AURA")
root:RegisterEvent("SPELLS_CHANGED")
root:RegisterEvent("PLAYER_REGEN_ENABLED")
pcall(root.RegisterEvent, root, "UPDATE_SHAPESHIFT_FORM")
pcall(root.RegisterEvent, root, "LEARNED_SPELL_IN_TAB")
pcall(root.RegisterEvent, root, "PLAYER_TALENT_UPDATE")

--------------------------------------------------------------------------------
-- Slash commands (parity + debug). /fbr config opens WoW-authentic settings.
--------------------------------------------------------------------------------
local function Help()
    Print(DISPLAY_NAME .. " - commands:")
    print("  /fbr config               open settings (WoW UI)")
    print("  /fbr lock | unlock        lock/unlock position (Shift+Drag moves)")
    print("  /fbr move                 show & unlock to reposition")
    print("  /fbr scale <0.6-2.0>      icon scale")
    print("  /fbr grow right|down      layout direction")
    print("  /fbr pulse | sound        toggle pulse / hint sound")
    print("  /fbr form                 toggle cancel-form macro mode")
    print("  /fbr reset                reset position")
    print("  /fbr test                 show missing icons for testing")
    print("  /fbr debug                status / catalog state")
    print("  /fbr onboarding           show onboarding")
    print("  /fbr rl                   reload UI")
    print("  Legacy toggles: /fbr motw | thorns (Druid)")
end

local function ToggleRuleById(id, label)
    if not DB then return end
    DB.rules = DB.rules or {}
    DB.rules[id] = not RuleEnabled(Catalog.byId[id] or {id=id, enabledDefault=true})
    Print((label or id) .. ": " .. (DB.rules[id] and "|cff00ff00ON|r" or "|cffff4040OFF|r"))
    Refresh()
end

SLASH_FOREVERBUFFREMINDER1 = "/fbr"
SLASH_FOREVERBUFFREMINDER2 = "/foreverbuff"
SlashCmdList.FOREVERBUFFREMINDER = function(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    if not DB then Print("not ready yet (try after login). /reload if needed."); return end

    if cmd == "" or cmd == "help" or cmd == "?" then
        Help()
    elseif cmd == "config" or cmd == "options" or cmd == "settings" or cmd == "ui" then
        ns.OpenOptions()
    elseif cmd == "onboarding" or cmd == "welcome" then
        DB.onboardingDone=false; DB.onboardingDismissed=false; ShowOnboarding(true)
    elseif cmd == "lock" then
        DB.locked = true; forceTest = false; Print("Locked. (Shift+Drag still moves.)"); Refresh()
    elseif cmd == "unlock" or cmd == "move" then
        DB.locked = false; forceTest = true
        Print("Unlocked - drag icons (Shift+Drag) to move, then /fbr lock."); Refresh()
    elseif cmd == "motw" then -- legacy alias
        ToggleRuleById("druid_motw", "Mark of the Wild")
    elseif cmd == "thorns" then -- legacy alias
        ToggleRuleById("druid_thorns", "Thorns")
    elseif cmd == "scale" then
        local n = tonumber(rest)
        if n then DB.scale = math.max(0.6, math.min(2.0, n)); ApplyVisuals(); Print("Scale: " .. string.format("%.2f", DB.scale))
        else Print("Usage: /fbr scale 1.0") end
    elseif cmd == "grow" then
        local g = (rest or ""):upper()
        if g == "DOWN" or g == "RIGHT" then DB.grow = g; Print("Grow: "..g); Refresh() else Print("Usage: /fbr grow right|down") end
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
        local p = Compat.PlayerInfo()
        Print(string.format("v%s schema=%s combat=%s locked=%s class=%s race=%s test=%s", VERSION, tostring(DB._schema), tostring(Compat.InCombat()), tostring(DB.locked), tostring(p.class), tostring(p.race), tostring(forceTest)))
        local plan = ns._lastPlan or BuildPlan(forceTest)
        Print("catalog="..tostring(#Catalog.list).." eligibleMissing="..tostring(plan.missing))
        for _, st in ipairs(plan.items) do
            local b = buttons[st.id]
            Print(string.format("%s [%s]: has=%s known=%s shown=%s mode=%s spellAttr=%s",
                st.id, st.short or "?", tostring(st.has), tostring(st.known),
                tostring(b and b:IsShown()), tostring(b and b._mode),
                tostring(b and b:GetAttribute("spell") or b and b:GetAttribute("type"))))
        end
        if plan.missing == 0 then Print("No missing buffs for current class/settings (or all covered). Use /fbr test or /fbr config.") end
    elseif cmd == "rl" or cmd == "reload" then
        ReloadUI()
    elseif cmd == "cast" then
        -- debug convenience (non-secure). Usage: /fbr cast <ruleId>
        local rid = (rest ~= "" and rest) or "druid_motw"
        local r = Catalog.byId[rid]
        if r then
            local st = ResolveRule(r)
            if CastSpellByName and st.name then CastSpellByName(st.name); Print("Attempted: "..st.name) else Print("Cast unavailable or unknown spell.") end
        else
            Print("Unknown rule: "..tostring(rid)..". See /fbr debug.")
        end
    else
        Print("Unknown command. Try /fbr help")
    end
end

-- Binding display strings (Bindings.xml) - safe globals for WoW keybinding UI
BINDING_HEADER_WOW_FOREVER_BUFF_REMINDER_ADDON_BYJTT = "WoW Forever Buff Reminder Addon ByJTT"
BINDING_NAME_FBR_RELOADUI = "Reload UI"

-- Keep a lightweight reload alias (F7 via Bindings.xml also calls ReloadUI)
SLASH_FBRRELOAD1 = "/rl"
SlashCmdList.FBRRELOAD = function() ReloadUI() end
