-- ----------------------------------------------
-- Module to handle Bag space and currency displays
-- Author: Ranckor90
-- ----------------------------------------------
-- Ingame script to enable console Mode on PC
-- /script SetCVar("ForceConsoleFlow.2", "1")
-- Image script to go back to PC Mode
-- /script SetCVar("ForceConsoleFlow.2", "0")

local RanckorsBaggage = {
    name       = "RanckorsBaggage",
    version    = "v2.0.4",
    devURL     = "https://illyriat.com/",
    namespace  = "RanckorsBaggage",
}
local LAM = LibAddonMenu2

-- Defaults & Constants
RanckorsBaggage.defaults = {
    position        = { x = 0, y = 100 },
    backgroundStyle = "clear",
    uiScale         = 100,
    size            = nil,
    displaySettings = {
        -- Player currencies
        [CURT_MONEY]              = true,
        [CURT_ALLIANCE_POINTS]    = true,
        [CURT_TELVAR_STONES]      = true,
        [CURT_EVENT_TICKETS]      = true,
        [CURT_UNDAUNTED_KEYS]     = true,
        [CURT_CHAOTIC_CREATIA]    = true,
        [CURT_CROWN_GEMS]         = true,
        [CURT_IMPERIAL_FRAGMENTS] = true,
        [CURT_ENDEAVOR_SEALS]     = true,
        [CURT_WRIT_VOUCHERS]      = true,
        [CURT_ARCHIVAL_FORTUNES]  = true,
        [CURT_CROWNS]             = true,
        -- Banked currencies
        BankedGold            = true,
        BankedAlliancePoints  = true,
        BankedTelVar          = true,
        BankedWritVouchers    = true,
        -- Bags
        BagSpace              = true,
        BankSpace             = true,
    },
}

RanckorsBaggage.fonts = {
    pc = {
        label   = "ZoFontGameSmall",
        heading = "ZoFontWinH1",
        button  = "ZoFontGameSmall",
        value   = "ZoFontGameLarge",
        title   = "ZoFontWinH1",
    },
    console = {
        label   = "ZoFontGamepad16",
        heading = "ZoFontGamepad18",
        button  = "ZoFontGamepad16",
        value   = "ZoFontGamepad18",
        title   = "ZoFontGamepadBold18",
    }
}

local ICONS = {
    GOLD               = "/esoui/art/currency/gold_mipmap.dds",
    AP                 = "/esoui/art/currency/alliancepoints.dds",
    TELVAR             = "/esoui/art/currency/telvar_mipmap.dds",
    EVENT_TICKET       = "/esoui/art/currency/icon_eventticket_loot.dds",
    UNDAUNTED_KEY      = "/esoui/art/currency/undauntedkey.dds",
    TRANSMUTE          = "/esoui/art/currency/currency_seedcrystal_32.dds",
    CROWN_GEMS         = "/esoui/art/currency/currency_crown_gems.dds",
    IMPERIAL_FRAGMENT  = "/esoui/art/currency/currency_imperial_trophy_key_32.dds",
    SEALS              = "/esoui/art/currency/currency_seals_of_endeavor_32.dds",
    WRIT_VOUCHER       = "/esoui/art/icons/icon_writvoucher.dds",
    ARCHIVAL           = "/esoui/art/currency/archivalfragments_32.dds",
    CROWNS             = "/esoui/art/icons/store_crowns.dds",
    BAG                = "/esoui/art/tooltips/icon_bag.dds",
    BANK               = "/esoui/art/icons/servicemappins/servicepin_bank.dds",
    LINK               = "/esoui/art/help/help_tabicon_cs_up.dds",
}

local COLORS = {
    GOLD        = "|cFFD700",
    AP          = "|c50C878",
    TELVAR      = "|cADD8E6",
    EVENT       = "|cFF69B4",
    UNDAUNTED   = "|cB5A642",
    TRANSMUTE   = "|c8A2BE2",
    CROWN_GEMS  = "|cE883E8",
    IMPERIAL    = "|c87CEEB",
    SEALS       = "|c87CEEB",
    WRIT        = "|cFFA500",
    ARCHIVAL    = "|c800080",
    CROWNS      = "|cFFFF00",
    NORMAL      = "|cFFFFFF",
    WARNING     = "|cFFA500",
    CRITICAL    = "|cFF0000",
    SECTION     = "|cCCCCCC",
    VERSION     = "|c888888",
}

local CURRENCY_NAMES = {
    [CURT_MONEY]              = "Gold",
    [CURT_ALLIANCE_POINTS]    = "Alliance Points",
    [CURT_TELVAR_STONES]      = "Tel Var Stones",
    [CURT_EVENT_TICKETS]      = "Event Tickets",
    [CURT_UNDAUNTED_KEYS]     = "Undaunted Keys",
    [CURT_CHAOTIC_CREATIA]    = "Transmute Crystals",
    [CURT_CROWN_GEMS]         = "Crown Gems",
    [CURT_IMPERIAL_FRAGMENTS] = "Imperial Fragments",
    [CURT_ENDEAVOR_SEALS]     = "Seals of Endeavor",
    [CURT_WRIT_VOUCHERS]      = "Writ Vouchers",
    [CURT_ARCHIVAL_FORTUNES]  = "Archival Fortunes",
    [CURT_CROWNS]             = "Crowns",
}

-- quick helpers
local function ucfirst(s) return (s or ""):gsub("^%l", string.upper) end
local function IsValidWindow() return RanckorsBaggageWindow and RanckorsBaggageWindow.SetHidden ~= nil end
local function ZOComma(n) return (ZO_CommaDelimitNumber and ZO_CommaDelimitNumber(n)) or tostring(n):reverse():gsub("(%d%d%d)","%1,"):gsub(",(%-?)$","%1"):reverse() end

function RanckorsBaggage:GetFont(kind)
    local platform = IsInGamepadPreferredMode() and "console" or "pc"
    return (self.fonts[platform] and self.fonts[platform][kind]) or "ZoFontGameSmall"
end

function RanckorsBaggage:GetWindowSize()
    if IsInGamepadPreferredMode() then
        return 150, 480 -- Console/GamePad
    else
        return 200, 520 -- PC default
    end
end

RanckorsBaggage.baseWidth  = nil
RanckorsBaggage.baseHeight = nil

function RanckorsBaggage:SaveSize()
    if not IsValidWindow() then return end
    local w, h = RanckorsBaggageWindow:GetDimensions()
    self.saved.size = { w = w, h = h }
end

function RanckorsBaggage:RestoreSize()
    if not IsValidWindow() then return end

    local size = self.saved.size
    if size and size.w and size.h then
        -- Manual size (from PC drag) wins
        RanckorsBaggageWindow:SetDimensions(size.w, size.h)
    else
        -- Use UI scale (percent), default 100
        local pct = tonumber(self.saved.uiScale) or 100
        pct = math.max(50, math.min(200, pct))
        local bw = self.baseWidth  or select(1, self:GetWindowSize())
        local bh = self.baseHeight or select(2, self:GetWindowSize())
        RanckorsBaggageWindow:SetDimensions(bw * pct/100, bh * pct/100)
    end

    self:ApplyContentScale()
end

function RanckorsBaggage:ResetToDefaultSize()
    -- Clear both manual size and the user scale
    self.saved.size = nil
    self.saved.uiScale = nil

    if IsValidWindow() then
        local w, h = self:GetWindowSize()
        RanckorsBaggageWindow:SetDimensions(w, h)
        self:ApplyContentScale()
    end
end

-- Scale the inner content proportionally so layout/fonts/icons stay tidy
function RanckorsBaggage:ApplyContentScale()
    if not (self.ui and self.ui.content and IsValidWindow()) then return end
    local winW, winH = RanckorsBaggageWindow:GetDimensions()
    local bw,  bh    = self.baseWidth, self.baseHeight
    if not (bw and bh and bw > 0 and bh > 0) then return end

    local scaleX = winW / bw
    local scaleY = winH / bh
    local scale  = math.max(0.5, math.min(3.0, math.min(scaleX, scaleY)))

    self.ui.content:SetScale(scale)
    self.ui.content:ClearAnchors()
    self.ui.content:SetAnchor(TOPLEFT, RanckorsBaggageWindow, TOPLEFT, 0, 0)
end

-- UI
function RanckorsBaggage:CreateUI()
    if IsValidWindow() then return end

    local width, height = self:GetWindowSize()
    self.baseWidth, self.baseHeight = width, height

    RanckorsBaggageWindow = WINDOW_MANAGER:CreateTopLevelWindow("RanckorsBaggageWindow")
    RanckorsBaggageWindow:SetDimensions(width, height)
    RanckorsBaggageWindow:SetMovable(true)
    RanckorsBaggageWindow:SetMouseEnabled(true)
    RanckorsBaggageWindow:SetClampedToScreen(true)
    RanckorsBaggageWindow:SetResizeHandleSize(12)

    local background = WINDOW_MANAGER:CreateControl("$(parent)BG", RanckorsBaggageWindow, CT_BACKDROP)
    background:SetAnchorFill(RanckorsBaggageWindow)
    self:ApplyBackgroundStyle(background)

    self.ui = {}
    self.ui.content = WINDOW_MANAGER:CreateControl("$(parent)Content", RanckorsBaggageWindow, CT_CONTROL)
    self.ui.content:SetDimensions(width, height)
    self.ui.content:SetAnchor(TOPLEFT, RanckorsBaggageWindow, TOPLEFT, 0, 0)

    self.ui.link = WINDOW_MANAGER:CreateControl("$(parent)Link", self.ui.content, CT_LABEL)
    self.ui.link:SetDimensions(width - 20, 24)
    self.ui.link:SetAnchor(TOPLEFT, self.ui.content, TOPLEFT, 10, 10)
    self.ui.link:SetFont(self:GetFont("value"))
    self.ui.link:SetColor(0, 0.7, 1, 1)
    self.ui.link:SetText(zo_strformat("|t20:20:<<1>>|t |u1:0::RanckorsBaggage|u", ICONS.LINK))
    self.ui.link:SetMouseEnabled(true)
    self.ui.link:SetHandler("OnMouseUp", function() RequestOpenUnsafeURL(self.devURL) end)

    self.ui.version = WINDOW_MANAGER:CreateControl("$(parent)Version", self.ui.content, CT_LABEL)
    self.ui.version:SetDimensions(width - 20, 20)
    self.ui.version:SetAnchor(TOPLEFT, self.ui.content, TOPLEFT, 25, 28)
    self.ui.version:SetFont(self:GetFont("button"))
    self.ui.version:SetColor(0.8, 0.8, 0.8, 1)
    self.ui.version:SetText(self.version)

    self.ui.label = WINDOW_MANAGER:CreateControl("$(parent)Label", self.ui.content, CT_LABEL)
    self.ui.label:SetDimensions(width - 20, height - 40)
    self.ui.label:SetAnchor(TOPLEFT, self.ui.content, TOPLEFT, 10, 35)
    self.ui.label:SetFont(self:GetFont("value"))
    self.ui.label:SetColor(1, 1, 1, 1)
    self.ui.label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    self.ui.label:SetVerticalAlignment(TEXT_ALIGN_TOP)

    RanckorsBaggageWindow:SetHandler("OnMoveStop", function() self:SavePosition() end)
    RanckorsBaggageWindow:SetHandler("OnSizeChanged", function() self:ApplyContentScale() end)
    RanckorsBaggageWindow:SetHandler("OnResizeStop", function()
        self:SaveSize()
        self:ApplyContentScale()
    end)
    self:ApplyContentScale()
end

function RanckorsBaggage:ApplyBackgroundStyle(background)
    if not background then return end
    if (self.saved.backgroundStyle or "clear") == "clear" then
        background:SetCenterColor(0, 0, 0, 0)
        background:SetEdgeColor(0, 0, 0, 0)
    else
        background:SetCenterColor(0.1, 0.1, 0.1, 0.7)
        background:SetEdgeColor(0.1, 0.1, 0.1, 1)
    end
end

function RanckorsBaggage:SetBackgroundStyle(style)
    self.saved.backgroundStyle = (style == "dark") and "dark" or "clear"
    if IsValidWindow() then
        local bg = RanckorsBaggageWindow:GetNamedChild("BG")
        if bg then self:ApplyBackgroundStyle(bg) end
        d(self.name .. ": Background style set to " .. self.saved.backgroundStyle)
    end
end

-- Position
function RanckorsBaggage:RestorePosition()
    if not IsValidWindow() then return end
    local pos = self.saved.position or self.defaults.position
    RanckorsBaggageWindow:ClearAnchors()
    RanckorsBaggageWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, pos.x, pos.y)
end

function RanckorsBaggage:SavePosition()
    if not IsValidWindow() then return end
    self.saved.position = self.saved.position or { x = 0, y = 100 }
    self.saved.position.x = RanckorsBaggageWindow:GetLeft()
    self.saved.position.y = RanckorsBaggageWindow:GetTop()
end


function RanckorsBaggage:ToggleWindow()
    if not IsValidWindow() then return end
    RanckorsBaggageWindow:SetHidden(not RanckorsBaggageWindow:IsHidden())
end

-- Data & Formatting
RanckorsBaggage.hasShownCurrencyWarning = false

function RanckorsBaggage:GetCurrencySafely(currencyType, location)
    local name = CURRENCY_NAMES[currencyType] or ("Unknown("..tostring(currencyType)..")")
    if not CURRENCY_NAMES[currencyType] and not self.hasShownCurrencyWarning then
        d(self.name .. " - Warning: Invalid currency type " .. name)
        self.hasShownCurrencyWarning = true
        return nil
    end
    local amt = GetCurrencyAmount(currencyType, location)
    if amt == 0 and not self.hasShownCurrencyWarning then
        d(self.name .. " - Warning: " .. name .. " returned 0. Verify if this is correct.")
        self.hasShownCurrencyWarning = true
    end
    return amt
end

function RanckorsBaggage:UpdateCurrencyData()
    -- Player-held
    self.gold              = self:GetCurrencySafely(CURT_MONEY,              CURRENCY_LOCATION_CHARACTER)
    self.alliancePoints    = self:GetCurrencySafely(CURT_ALLIANCE_POINTS,    CURRENCY_LOCATION_CHARACTER)
    self.telVar            = self:GetCurrencySafely(CURT_TELVAR_STONES,      CURRENCY_LOCATION_CHARACTER)
    self.eventTickets      = self:GetCurrencySafely(CURT_EVENT_TICKETS,      CURRENCY_LOCATION_ACCOUNT)
    self.undauntedKeys     = self:GetCurrencySafely(CURT_UNDAUNTED_KEYS,     CURRENCY_LOCATION_ACCOUNT)
    self.transmuteCrystals = self:GetCurrencySafely(CURT_CHAOTIC_CREATIA,    CURRENCY_LOCATION_ACCOUNT)
    self.crownGems         = self:GetCurrencySafely(CURT_CROWN_GEMS,         CURRENCY_LOCATION_ACCOUNT)
    self.imperialFragments = self:GetCurrencySafely(CURT_IMPERIAL_FRAGMENTS, CURRENCY_LOCATION_ACCOUNT)
    self.sealsOfEndeavour  = self:GetCurrencySafely(CURT_ENDEAVOR_SEALS,     CURRENCY_LOCATION_ACCOUNT)
    self.writVouchers      = self:GetCurrencySafely(CURT_WRIT_VOUCHERS,      CURRENCY_LOCATION_CHARACTER)
    self.archivalFortunes  = self:GetCurrencySafely(CURT_ARCHIVAL_FORTUNES,  CURRENCY_LOCATION_ACCOUNT)
    self.crowns            = self:GetCurrencySafely(CURT_CROWNS,             CURRENCY_LOCATION_ACCOUNT)
    -- Bags
    self.currentBagSpace   = GetNumBagUsedSlots(BAG_BACKPACK)
    self.maxBagSpace       = GetBagSize(BAG_BACKPACK)
    -- Banked currencies
    self.bankedGold            = self:GetCurrencySafely(CURT_MONEY,           CURRENCY_LOCATION_BANK)
    self.bankedAlliancePoints  = self:GetCurrencySafely(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_BANK)
    self.bankedTelVar          = self:GetCurrencySafely(CURT_TELVAR_STONES,   CURRENCY_LOCATION_BANK)
    self.bankedWritVouchers    = self:GetCurrencySafely(CURT_WRIT_VOUCHERS,   CURRENCY_LOCATION_BANK)
    -- Bank space
    local bankUsed      = GetNumBagUsedSlots(BAG_BANK)
    local bankMax       = GetBagSize(BAG_BANK)
    local subBankUsed   = GetNumBagUsedSlots(BAG_SUBSCRIBER_BANK)
    local subBankMax    = GetBagSize(BAG_SUBSCRIBER_BANK)

    if IsESOPlusSubscriber() then
        self.combinedBankUsedSpace = bankUsed + subBankUsed
        self.combinedMaxBankSpace  = bankMax + subBankMax
        self.maxTransmuteCrystals  = 1000
    else
        self.combinedBankUsedSpace = bankUsed + subBankUsed
        self.combinedMaxBankSpace  = bankMax
        self.maxTransmuteCrystals  = 500
    end
end

local function usageColor(pct)
    if pct >= 95 then return COLORS.CRITICAL
    elseif pct >= 90 then return COLORS.WARNING
    else return COLORS.NORMAL end
end

function RanckorsBaggage:BuildInfoText()
    local s = {}
    local show = self.saved.displaySettings or {}
    local function addLine(color, icon, text)
        s[#s+1] = string.format("%s|t24:24:%s|t %s|r\n", color, icon, text)
    end

    s[#s+1] = string.format("%s--------Player--------|r\n", COLORS.SECTION)

    if show[CURT_MONEY] ~= false              then addLine(COLORS.GOLD,       ICONS.GOLD,              ZOComma(self.gold)) end
    if show[CURT_ALLIANCE_POINTS] ~= false    then addLine(COLORS.AP,         ICONS.AP,                ZOComma(self.alliancePoints)) end
    if show[CURT_TELVAR_STONES] ~= false      then addLine(COLORS.TELVAR,     ICONS.TELVAR,            ZOComma(self.telVar)) end
    if show[CURT_EVENT_TICKETS] ~= false      then addLine(COLORS.EVENT,      ICONS.EVENT_TICKET,      string.format("%s/12", ZOComma(self.eventTickets or 0))) end
    if show[CURT_UNDAUNTED_KEYS] ~= false     then addLine(COLORS.UNDAUNTED,  ICONS.UNDAUNTED_KEY,     ZOComma(self.undauntedKeys)) end
    if show[CURT_CHAOTIC_CREATIA] ~= false    then addLine(COLORS.TRANSMUTE,  ICONS.TRANSMUTE,         string.format("%s/%s", ZOComma(self.transmuteCrystals), ZOComma(self.maxTransmuteCrystals))) end
    if show[CURT_CROWN_GEMS] ~= false         then addLine(COLORS.CROWN_GEMS, ICONS.CROWN_GEMS,        ZOComma(self.crownGems)) end
    if show[CURT_IMPERIAL_FRAGMENTS] ~= false then addLine(COLORS.IMPERIAL,   ICONS.IMPERIAL_FRAGMENT, ZOComma(self.imperialFragments)) end
    if show[CURT_ENDEAVOR_SEALS] ~= false     then addLine(COLORS.SEALS,      ICONS.SEALS,             ZOComma(self.sealsOfEndeavour)) end
    if show[CURT_WRIT_VOUCHERS] ~= false      then addLine(COLORS.WRIT,       ICONS.WRIT_VOUCHER,      ZOComma(self.writVouchers)) end
    if show[CURT_ARCHIVAL_FORTUNES] ~= false  then addLine(COLORS.ARCHIVAL,   ICONS.ARCHIVAL,          ZOComma(self.archivalFortunes)) end
    if show[CURT_CROWNS] ~= false             then addLine(COLORS.CROWNS,     ICONS.CROWNS,            ZOComma(self.crowns)) end
    if show.BagSpace ~= false then
        local pct = (self.currentBagSpace / math.max(1, self.maxBagSpace)) * 100
        addLine(usageColor(pct), ICONS.BAG, string.format("%d/%d", self.currentBagSpace, self.maxBagSpace))
    end

    s[#s+1] = string.format("%s--------Banked--------|r\n", COLORS.SECTION)

    if show.BankedGold ~= false            then addLine(COLORS.GOLD,  ICONS.GOLD,   ZOComma(self.bankedGold)) end
    if show.BankedAlliancePoints ~= false  then addLine(COLORS.AP,    ICONS.AP,     ZOComma(self.bankedAlliancePoints)) end
    if show.BankedTelVar ~= false          then addLine(COLORS.TELVAR,ICONS.TELVAR, ZOComma(self.bankedTelVar)) end
    if show.BankedWritVouchers ~= false    then addLine(COLORS.WRIT,  ICONS.WRIT_VOUCHER, ZOComma(self.bankedWritVouchers)) end
    if show.BankSpace ~= false then
        local pct = (self.combinedBankUsedSpace / math.max(1, self.combinedMaxBankSpace)) * 100
        addLine(usageColor(pct), ICONS.BANK, string.format("%d/%d", self.combinedBankUsedSpace, self.combinedMaxBankSpace))
    end
    return table.concat(s)
end

-- Debounced UI updates to avoid thrash when many events fire
RanckorsBaggage._pendingUpdate = false
function RanckorsBaggage:RequestUpdate()
    if self._pendingUpdate then return end
    self._pendingUpdate = true
    zo_callLater(function()
        self._pendingUpdate = false
        self:UpdateCurrencyData()
        if self.ui and self.ui.label then
            self.ui.label:SetText(self:BuildInfoText())
        end
    end, 50)
end

-- Events
function RanckorsBaggage:OnPlayerActivated()
    EVENT_MANAGER:UnregisterForEvent(self.namespace, EVENT_PLAYER_ACTIVATED)
    self:UpdateCurrencyData()
    if self.ui and self.ui.label then
        self.ui.label:SetText(self:BuildInfoText())
    end
    self:RestorePosition()
    self:RestoreSize()
end

function RanckorsBaggage:OnActionLayerPushed(_, layerIndex)
    if layerIndex == 2 or layerIndex == 3 or layerIndex == 4 or layerIndex == 6 then
        if IsValidWindow() then RanckorsBaggageWindow:SetHidden(true) end
    end
end

function RanckorsBaggage:OnActionLayerPopped(_, layerIndex)
    if layerIndex == 2 or layerIndex == 3 or layerIndex == 4 or layerIndex == 6 then
        if IsValidWindow() then RanckorsBaggageWindow:SetHidden(false) end
    end
end

function RanckorsBaggage:OnCurrencyUpdate()
    self:RequestUpdate()
end

function RanckorsBaggage:OnInventoryUpdate()
    self:RequestUpdate()
end

function RanckorsBaggage:OnSubscriptionStatusChanged()
    self:RequestUpdate()
end

-- Settings
function RanckorsBaggage:CreateSettings()
    local panel = {
        type = "panel",
        name = "Ranckor's Baggage",
        displayName = "|cFFD700Ranckor's Baggage|r",
        author = "Ranckor90",
        version = self.version,
        registerForRefresh = true,
        registerForDefaults = true,
        resetFunc = function()
            self.saved.position        = { x = self.defaults.position.x, y = self.defaults.position.y }
            self.saved.uiScale         = 100
            self.saved.size            = nil
            self.saved.backgroundStyle = self.defaults.backgroundStyle or "clear"
            self.saved.displaySettings = ZO_DeepTableCopy(self.defaults.displaySettings)
            self:RestorePosition()
            self:RestoreSize()
            if IsValidWindow() then
                local bg = RanckorsBaggageWindow:GetNamedChild("BG")
                if bg then self:ApplyBackgroundStyle(bg) end
            end
            self:RequestUpdate()
        end
    }
    self.settingsPanel = LAM:RegisterAddonPanel(self.name .. "Settings", panel)


    local playerCurrencies = {
        { key = CURT_MONEY,              label = "Gold" },
        { key = CURT_ALLIANCE_POINTS,    label = "Alliance Points" },
        { key = CURT_TELVAR_STONES,      label = "Tel Var Stones" },
        { key = CURT_EVENT_TICKETS,      label = "Event Tickets" },
        { key = CURT_UNDAUNTED_KEYS,     label = "Undaunted Keys" },
        { key = CURT_CHAOTIC_CREATIA,    label = "Transmute Crystals" },
        { key = CURT_CROWN_GEMS,         label = "Crown Gems" },
        { key = CURT_IMPERIAL_FRAGMENTS, label = "Imperial Fragments" },
        { key = CURT_ENDEAVOR_SEALS,     label = "Seals of Endeavor" },
        { key = CURT_WRIT_VOUCHERS,      label = "Writ Vouchers" },
        { key = CURT_ARCHIVAL_FORTUNES,  label = "Archival Fortunes" },
        { key = CURT_CROWNS,             label = "Crowns" },
    }

    local bankedCurrencies = {
        { key = "BankedGold",           label = "Banked Gold" },
        { key = "BankedAlliancePoints", label = "Banked Alliance Points" },
        { key = "BankedTelVar",         label = "Banked Tel Var Stones" },
        { key = "BankedWritVouchers",   label = "Banked Writ Vouchers" },
    }

    local encumbrance = {
        { key = "BagSpace",  label = "Bag Space" },
        { key = "BankSpace", label = "Bank Space" },
    }

    local opts = {}

    local function currentWindowSize()
    if IsValidWindow() then
        return RanckorsBaggageWindow:GetWidth(), RanckorsBaggageWindow:GetHeight()
    else
        return self:GetWindowSize()
    end
    end
    local wndW, wndH = currentWindowSize()
    local maxX = math.max(0, GuiRoot:GetWidth()  - wndW)
    local maxY = math.max(0, GuiRoot:GetHeight() - wndH)

    -- Position sliders
    table.insert(opts, { type = "header", name = "UI Position" })
    table.insert(opts, {
        type = "slider",
        name = "Position X",
        tooltip = "Horizontal position of the UI",
        min = 0,
        max = maxX,
        step = 1,
        getFunc = function() return self.saved.position.x end,
        setFunc = function(v) self.saved.position.x = v; self:RestorePosition() end,
        default = self.defaults.position.x,
    })

    table.insert(opts, {
        type = "slider",
        name = "Position Y",
        tooltip = "Vertical position of the UI",
        min = 0,
        max = maxY,
        step = 1,
        getFunc = function() return self.saved.position.y end,
        setFunc = function(v) self.saved.position.y = v; self:RestorePosition() end,
        default = self.defaults.position.y,
    })

        -- Scale slider
    table.insert(opts, { type = "header", name = "Scale (Resize)" })
    table.insert(opts, {
        type = "slider",
        name = "UI Scale",
        tooltip = "Resize the window and its contents together. 100% is default.",
        min = 50,
        max = 200,
        step = 5,
        getFunc = function()
            return self.saved.uiScale or 100
        end,
        setFunc = function(val)
            -- Using the slider overrides manual drag-resize
            self.saved.uiScale = math.floor(val + 0.5)
            self.saved.size = nil

            if IsValidWindow() then
                local bw = self.baseWidth  or select(1, self:GetWindowSize())
                local bh = self.baseHeight or select(2, self:GetWindowSize())
                local s  = (self.saved.uiScale or 100) / 100
                RanckorsBaggageWindow:SetDimensions(bw * s, bh * s)
                self:ApplyContentScale()
            end
        end,
        default = 100,
    })

    -- Player currencies
    table.insert(opts, { type = "header", name = "Player Currencies" })
    for _, item in ipairs(playerCurrencies) do
        table.insert(opts, {
            type = "checkbox",
            name = item.label,
            getFunc = function() return self.saved.displaySettings[item.key] end,
            setFunc = function(val) self.saved.displaySettings[item.key] = val; self:RequestUpdate() end,
            default = true,
        })
    end

    -- Banked
    table.insert(opts, { type = "header", name = "Banked Currencies" })
    for _, item in ipairs(bankedCurrencies) do
        table.insert(opts, {
            type = "checkbox",
            name = item.label,
            getFunc = function() return self.saved.displaySettings[item.key] end,
            setFunc = function(val) self.saved.displaySettings[item.key] = val; self:RequestUpdate() end,
            default = true,
        })
    end

    -- Encumbrance
    table.insert(opts, { type = "header", name = "Encumbrance" })
    for _, item in ipairs(encumbrance) do
        table.insert(opts, {
            type = "checkbox",
            name = item.label,
            getFunc = function() return self.saved.displaySettings[item.key] end,
            setFunc = function(val) self.saved.displaySettings[item.key] = val; self:RequestUpdate() end,
            default = true,
        })
    end

    -- Utilities
    table.insert(opts, { type = "header", name = "Utilities" })
    table.insert(opts, {
        type = "dropdown",
        name = "Theme Style",
        tooltip = "Choose the background style for the display window.",
        choices = { "Clear", "Dark" },
        getFunc = function() return ucfirst(self.saved.backgroundStyle or "clear") end,
        setFunc = function(choice)
            local style = string.lower(choice)
            self:SetBackgroundStyle(style)
            if IsValidWindow() then
                local bg = RanckorsBaggageWindow:GetNamedChild("BG")
                if bg then self:ApplyBackgroundStyle(bg) end
            end
        end,
        default = "Clear",
        width = "full",
    })

    table.insert(opts, {
        type = "button",
        name = "Reset All",
        func = function()
            self.saved.position = self.saved.position or { x = 0, y = 100 }
            self.saved.position.x = self.defaults.position.x or 0
            self.saved.position.y = self.defaults.position.y or 100
            self.saved.uiScale    = self.defaults.uiScale or 100
            self.saved.size       = nil 
            self.saved.backgroundStyle = self.defaults.backgroundStyle or "clear"
            for k in pairs(self.saved.displaySettings) do
                self.saved.displaySettings[k] = nil
            end
            for k, v in pairs(self.defaults.displaySettings) do
                self.saved.displaySettings[k] = v
            end
            self:RestorePosition()
            self:RestoreSize()
            local bg = IsValidWindow() and RanckorsBaggageWindow:GetNamedChild("BG")
            if bg then self:ApplyBackgroundStyle(bg) end
            self:RequestUpdate()
            if CALLBACK_MANAGER and self.settingsPanel then
                CALLBACK_MANAGER:FireCallbacks("LAM-RefreshPanel", self.settingsPanel)
            end
        end,
        width = "full",
        warning = "Resets position, scale, theme, and all toggles to defaults.",
    })

    LAM:RegisterOptionControls(self.name .. "Settings", opts)
end

-- Register Events
function RanckorsBaggage:Initialize()
    self:CreateUI()

    -- Events
    local NS = self.namespace
    EVENT_MANAGER:RegisterForEvent(NS, EVENT_PLAYER_ACTIVATED,         function() self:OnPlayerActivated() end)
    EVENT_MANAGER:RegisterForEvent(NS, EVENT_CURRENCY_UPDATE,          function(...) self:OnCurrencyUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent(NS, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(...) self:OnInventoryUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent(NS, EVENT_ACTION_LAYER_PUSHED,      function(_, layerIndex) self:OnActionLayerPushed(_, layerIndex) end)
    EVENT_MANAGER:RegisterForEvent(NS, EVENT_ACTION_LAYER_POPPED,      function(_, layerIndex) self:OnActionLayerPopped(_, layerIndex) end)
    EVENT_MANAGER:RegisterForEvent(NS, EVENT_ESO_PLUS_FREE_TRIAL_STATUS_CHANGED, function(...) self:OnSubscriptionStatusChanged(...) end)

    -- Slash commands
    SLASH_COMMANDS["/rb"]      = function() self:ToggleWindow() end
    SLASH_COMMANDS["/rbclear"] = function() self:SetBackgroundStyle("clear") end
    SLASH_COMMANDS["/rbdark"]  = function() self:SetBackgroundStyle("dark") end

    self:CreateSettings()
end

function RanckorsBaggage:OnRanckorsBaggageLoaded(_, RanckorsBaggageName)
    if RanckorsBaggageName ~= self.name then return end
    EVENT_MANAGER:UnregisterForEvent(self.namespace, EVENT_ADD_ON_LOADED)

    self.saved = ZO_SavedVars:NewAccountWide(self.name .. "SavedVars", 1, nil, self.defaults)
    self.hasShownCurrencyWarning = false

    local pos = self.saved.position or self.defaults.position or {x=0, y=100}
    self.saved.position = ZO_DeepTableCopy(pos)

    local ds = self.saved.displaySettings or self.defaults.displaySettings or {}
    self.saved.displaySettings = ZO_DeepTableCopy(ds)

    if self.saved.uiScale == nil then self.saved.uiScale = self.defaults.uiScale or 100 end
    if self.saved.size and (not self.saved.size.w or not self.saved.size.h) then
        self.saved.size = nil
    end
    self.saved.backgroundStyle = self.saved.backgroundStyle or (self.defaults.backgroundStyle or "clear")

    self:Initialize()
end


-- Register Event Manager
EVENT_MANAGER:RegisterForEvent(RanckorsBaggage.namespace, EVENT_ADD_ON_LOADED, function(...) RanckorsBaggage:OnRanckorsBaggageLoaded(...) end)