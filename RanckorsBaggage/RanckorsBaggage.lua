-- ----------------------------------------------
-- Module to handle Bag space and currency displays
-- ----------------------------------------------

-- Ingame script to enable console Mode on PC
-- /script SetCVar("ForceConsoleFlow.2", "1")
-- Image script to go back to PC Mode
-- /script SetCVar("ForceConsoleFlow.2", "0")


local LAM = LibAddonMenu2
local RanckorsBaggage = {}
RanckorsBaggage.version = "v2.0.2"

-- Define the default saved variables
RanckorsBaggage.defaults = {
    position = { x = 0, y = 100 },  -- Default position if no saved variables exist
    backgroundStyle = "clear"       -- Default background style
}


RanckorsBaggage.fonts = {
    pc = {
        label = "ZoFontGameSmall",
        heading = "ZoFontWinH1",
        button = "ZoFontGameSmall",
        value = "ZoFontGameLarge",
        title = "ZoFontWinH1",
    },
    console = {
        label  = "ZoFontGamepad16",
        heading = "ZoFontGamepad18",
        button = "ZoFontGamepad16",
        value  = "ZoFontGamepad18",
        title  = "ZoFontGamepadBold18",
    }
}


function RanckorsBaggage:GetFont(type)
    local platform = IsInGamepadPreferredMode() and "console" or "pc"
    return self.fonts[platform][type] or "ZoFontGameSmall"
end

-- Initialize function
function RanckorsBaggage:Initialize()
    d("Initializing RanckorsBaggage...")

    -- Create and initialize the UI
    self:CreateUI()

    -- Register for events
    EVENT_MANAGER:RegisterForEvent("RanckorsBaggage", EVENT_PLAYER_ACTIVATED, function(event) self:OnPlayerActivated(event) end)
    EVENT_MANAGER:RegisterForEvent("RanckorsBaggage", EVENT_CURRENCY_UPDATE, function(event, ...) self:OnCurrencyUpdate(event, ...) end)
    EVENT_MANAGER:RegisterForEvent("RanckorsBaggage", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(event, ...) self:OnInventoryUpdate(event, ...) end)
    EVENT_MANAGER:RegisterForEvent("RanckorsBaggage", EVENT_ACTION_LAYER_PUSHED, function(event, layerIndex, activeLayerIndex) self:OnActionLayerPushed(event, layerIndex, activeLayerIndex) end)
    EVENT_MANAGER:RegisterForEvent("RanckorsBaggage", EVENT_ACTION_LAYER_POPPED, function(event, layerIndex, activeLayerIndex) self:OnActionLayerPopped(event, layerIndex, activeLayerIndex) end)

    -- Register slash commands
    SLASH_COMMANDS["/rb"] = function() self:ToggleWindow() end
    SLASH_COMMANDS["/rbclear"] = function() self:SetBackgroundStyle("clear") end
    SLASH_COMMANDS["/rbdark"] = function() self:SetBackgroundStyle("dark") end

    self:CreateSettingsWindow()


end

-- Function to create UI
function RanckorsBaggage:GetWindowSize()
    if IsInGamepadPreferredMode() then
        return 150, 480 -- Reduced for console
    else
        return 200, 520 -- PC default
    end
end

function RanckorsBaggage:CreateUI()
    d("Creating UI...")

    if not RanckorsBaggageWindow then
        RanckorsBaggageWindow = WINDOW_MANAGER:CreateTopLevelWindow("RanckorsBaggageWindow")
        local width, height = self:GetWindowSize()
        RanckorsBaggageWindow:SetDimensions(width, height)
        RanckorsBaggageWindow:SetMovable(true)
        RanckorsBaggageWindow:SetMouseEnabled(true)
        RanckorsBaggageWindow:SetClampedToScreen(true)

        local background = WINDOW_MANAGER:CreateControl("$(parent)BG", RanckorsBaggageWindow, CT_BACKDROP)
        background:SetAnchorFill(RanckorsBaggageWindow)
        self:ApplyBackgroundStyle(background)

        RanckorsBaggage.RanckorsBaggageWindowLink = WINDOW_MANAGER:CreateControl("$(parent)Link", RanckorsBaggageWindow, CT_LABEL)
        RanckorsBaggage.RanckorsBaggageWindowLink:SetDimensions(width - 20, 24)
        RanckorsBaggage.RanckorsBaggageWindowLink:SetAnchor(TOPLEFT, RanckorsBaggageWindow, TOPLEFT, 10, 10)
        RanckorsBaggage.RanckorsBaggageWindowLink:SetFont(self:GetFont("value"))
        RanckorsBaggage.RanckorsBaggageWindowLink:SetColor(0, 0.7, 1, 1)
        RanckorsBaggage.RanckorsBaggageWindowLink:SetText("|t20:20:/esoui/art/help/help_tabicon_cs_up.dds|t |u1:0::RanckorsBaggage|u")
        RanckorsBaggage.RanckorsBaggageWindowLink:SetMouseEnabled(true)
        RanckorsBaggage.RanckorsBaggageWindowLink:SetHandler("OnMouseUp", function()
            RequestOpenUnsafeURL("https://illyriat.com/")
        end)

        RanckorsBaggage.RanckorsBaggageWindowVersion = WINDOW_MANAGER:CreateControl("$(parent)Version", RanckorsBaggageWindow, CT_LABEL)
        RanckorsBaggage.RanckorsBaggageWindowVersion:SetDimensions(width - 20, 20)
        RanckorsBaggage.RanckorsBaggageWindowVersion:SetAnchor(TOPLEFT, RanckorsBaggageWindow, TOPLEFT, 25, 28)
        RanckorsBaggage.RanckorsBaggageWindowVersion:SetFont(self:GetFont("button"))
        RanckorsBaggage.RanckorsBaggageWindowVersion:SetColor(0.8, 0.8, 0.8, 1)
        RanckorsBaggage.RanckorsBaggageWindowVersion:SetText(RanckorsBaggage.version)

        RanckorsBaggage.RanckorsBaggageWindowLabel = WINDOW_MANAGER:CreateControl("$(parent)Label", RanckorsBaggageWindow, CT_LABEL)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetDimensions(width - 20, height - 40)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetAnchor(TOPLEFT, RanckorsBaggageWindow, TOPLEFT, 10, 35)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetFont(self:GetFont("value"))
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetColor(1, 1, 1, 1)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetVerticalAlignment(TEXT_ALIGN_TOP)

        RanckorsBaggageWindow:SetHandler("OnMoveStop", function()
            self:SavePosition()
        end)
    end
end



-- Table to map currency types
local CURRENCY_NAMES = {
    [CURT_MONEY] = "Gold",
    [CURT_ALLIANCE_POINTS] = "Alliance Points",
    [CURT_TELVAR_STONES] = "Tel Var Stones",
    [CURT_EVENT_TICKETS] = "Event Tickets",
    [CURT_UNDAUNTED_KEYS] = "Undaunted Keys",
    [CURT_CHAOTIC_CREATIA] = "Transmute Crystals",
    [CURT_CROWN_GEMS] = "Crown Gems",
    [CURT_IMPERIAL_FRAGMENTS] = "Imperial Fragments",
    [CURT_ENDEAVOR_SEALS] = "Seals of Endeavor",
    [CURT_WRIT_VOUCHERS] = "Writ Vouchers",
    [CURT_ARCHIVAL_FORTUNES] = "Archival Fortunes",
    [CURT_CROWNS] = "Crowns"
}



-- Function to create settings window with ON/OFF toggles
function string.ucfirst(str)
    return str:gsub("^%l", string.upper)
end


function RanckorsBaggage:CreateSettingsWindow()
    local panelData = {
        type = "panel",
        name = "Ranckor's Baggage",
        displayName = "|cFFD700Ranckor's Baggage|r",
        author = "Ranckor90",
        version = RanckorsBaggage.version,
        registerForRefresh = true,
        registerForDefaults = true,
    }

    self.settingsPanel = LAM:RegisterAddonPanel("RanckorsBaggageSettings", panelData)

    local optionsData = {}

    local playerCurrencies = {
        { key = CURT_MONEY, label = "Gold" },
        { key = CURT_ALLIANCE_POINTS, label = "Alliance Points" },
        { key = CURT_TELVAR_STONES, label = "Tel Var Stones" },
        { key = CURT_EVENT_TICKETS, label = "Event Tickets" },
        { key = CURT_UNDAUNTED_KEYS, label = "Undaunted Keys" },
        { key = CURT_CHAOTIC_CREATIA, label = "Transmute Crystals" },
        { key = CURT_CROWN_GEMS, label = "Crown Gems" },
        { key = CURT_IMPERIAL_FRAGMENTS, label = "Imperial Fragments" },
        { key = CURT_ENDEAVOR_SEALS, label = "Seals of Endeavor" },
        { key = CURT_WRIT_VOUCHERS, label = "Writ Vouchers" },
        { key = CURT_ARCHIVAL_FORTUNES, label = "Archival Fortunes" },
        { key = CURT_CROWNS, label = "Crowns" },
    }

    local bankedCurrencies = {
        { key = "BankedGold", label = "Banked Gold" },
        { key = "BankedAlliancePoints", label = "Banked Alliance Points" },
        { key = "BankedTelVar", label = "Banked Tel Var Stones" },
        { key = "BankedWritVouchers", label = "Banked Writ Vouchers" },
    }

    local utilities = {
        { key = "BagSpace", label = "Bag Space" },
        { key = "BankSpace", label = "Bank Space" },
    }

    -- Player Currencies
    table.insert(optionsData, { type = "header", name = "Player Currencies" })
    for _, item in ipairs(playerCurrencies) do
        table.insert(optionsData, {
            type = "checkbox",
            name = item.label,
            getFunc = function() return self.savedVariables.displaySettings[item.key] end,
            setFunc = function(value)
                self.savedVariables.displaySettings[item.key] = value
                self:UpdateUI()
            end,
            default = true,
        })
    end

    -- Banked Currencies
    table.insert(optionsData, { type = "header", name = "Banked Currencies" })
    for _, item in ipairs(bankedCurrencies) do
        table.insert(optionsData, {
            type = "checkbox",
            name = item.label,
            getFunc = function() return self.savedVariables.displaySettings[item.key] end,
            setFunc = function(value)
                self.savedVariables.displaySettings[item.key] = value
                self:UpdateUI()
            end,
            default = true,
        })
    end

    -- Utilities
    table.insert(optionsData, { type = "header", name = "Utilities" })
    for _, item in ipairs(utilities) do
        table.insert(optionsData, {
            type = "checkbox",
            name = item.label,
            getFunc = function() return self.savedVariables.displaySettings[item.key] end,
            setFunc = function(value)
                self.savedVariables.displaySettings[item.key] = value
                self:UpdateUI()
            end,
            default = true,
        })
    end

    -- Reset Button
    table.insert(optionsData, {
        type = "button",
        name = "Reset All to ON",
        func = function()
            for _, item in ipairs(playerCurrencies) do
                self.savedVariables.displaySettings[item.key] = true
            end
            for _, item in ipairs(bankedCurrencies) do
                self.savedVariables.displaySettings[item.key] = true
            end
            for _, item in ipairs(utilities) do
                self.savedVariables.displaySettings[item.key] = true
            end
            self:UpdateUI()
        end,
        width = "half",
        warning = "Resets all toggles to ON state.",
    })

    -- Theme Button
    table.insert(optionsData, {
    type = "dropdown",
    name = "Theme Style",
    tooltip = "Choose the background style for the display window.",
    choices = { "Clear", "Dark" },
    getFunc = function()
        return string.ucfirst(self.savedVariables.backgroundStyle or "Dark")
    end,
    setFunc = function(choice)
        local style = string.lower(choice)
        self:SetBackgroundStyle(style)

        if IsValidRanckorsBaggageWindow() then
            local background = RanckorsBaggageWindow:GetNamedChild("BG")
            if background then
                self:ApplyBackgroundStyle(background)
            end
        end
    end,
    default = "Clear",
    width = "half",
    })

    LAM:RegisterOptionControls("RanckorsBaggageSettings", optionsData)
end


-- Function to apply the background style
function RanckorsBaggage:ApplyBackgroundStyle(background)
    if not background then
        d("RanckorsBaggage Error: Background control is nil.")
        return
    end

    if self.savedVariables.backgroundStyle == "clear" then
        background:SetCenterColor(0, 0, 0, 0) -- Fully transparent background
        background:SetEdgeColor(0, 0, 0, 0)   -- Fully transparent edges
    else
        background:SetCenterColor(0.1, 0.1, 0.1, 0.7) -- Darker background
        background:SetEdgeColor(0.1, 0.1, 0.1, 1)     -- Visible edges
    end
end

-- Function to set the background style
function RanckorsBaggage:SetBackgroundStyle(style)
    self.savedVariables.backgroundStyle = style
    if IsValidRanckorsBaggageWindow() then
        local background = RanckorsBaggageWindow:GetNamedChild("BG")
        if background then
            self:ApplyBackgroundStyle(background)
            d("RanckorsBaggage: Background style set to " .. style)
        else
            d("RanckorsBaggage Error: Background control not found.")
        end
    end
end

-- Removes the addon from view when opening a menu such as Map,
-- Event handler for action layer pushed (UI layer opened)
function RanckorsBaggage:OnActionLayerPushed(event, layerIndex, activeLayerIndex)
    if layerIndex == 2 or layerIndex == 3 or layerIndex == 4 or layerIndex == 6 then -- Add specific layers as needed
        if IsValidRanckorsBaggageWindow() then
            RanckorsBaggageWindow:SetHidden(true)
        end
    end
end

-- Event handler for action layer popped (UI layer closed)
function RanckorsBaggage:OnActionLayerPopped(event, layerIndex, activeLayerIndex)
    if layerIndex == 2 or layerIndex == 3 or layerIndex == 4 or layerIndex == 6 then -- Add specific layers as needed
        if IsValidRanckorsBaggageWindow() then
            RanckorsBaggageWindow:SetHidden(false)
        end
    end
end

-- Function to restore saved position
function RanckorsBaggage:RestorePosition()
    if self.savedVariables and self.savedVariables.position then
        RanckorsBaggageWindow:ClearAnchors()
        RanckorsBaggageWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.savedVariables.position.x, self.savedVariables.position.y)
        d("RanckorsBaggage Restored position to: " .. self.savedVariables.position.x .. ", " .. self.savedVariables.position.y)
    else
        -- Set to default position if no saved variables
        RanckorsBaggageWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, RanckorsBaggage.defaults.position.x, RanckorsBaggage.defaults.position.y)
        d("RanckorsBaggage Set to default position: " .. RanckorsBaggage.defaults.position.x .. ", " .. RanckorsBaggage.defaults.position.y)
    end
end

-- Function to save position
function RanckorsBaggage:SavePosition()
    if RanckorsBaggageWindow then
        self.savedVariables.position = { x = RanckorsBaggageWindow:GetLeft(), y = RanckorsBaggageWindow:GetTop() }
        d("RanckorsBaggage Saved position: " .. self.savedVariables.position.x .. ", " .. self.savedVariables.position.y)
    end
end

-- Helper function to safely get a currency amount or return nil if invalid
RanckorsBaggage.hasShownCurrencyWarning = false

function RanckorsBaggage:GetCurrencySafely(currencyType, currencyLocation)
    local currencyName = CURRENCY_NAMES[currencyType] or "Unknown Currency"

    -- Only show warning message on login or ReloadUI and only once
    if not self.hasShownCurrencyWarning then
        if not CURRENCY_NAMES[currencyType] then
            d("RanckorsBaggage - Warning: Invalid currency type " .. currencyName .. " (" .. tostring(currencyType) .. ")")
            self.hasShownCurrencyWarning = true -- Set flag to avoid repeating the warning
            return nil
        end
    end

    local amount = GetCurrencyAmount(currencyType, currencyLocation)
    if amount == 0 and not self.hasShownCurrencyWarning then
        d("RanckorsBaggage - Warning: " .. currencyName .. " returned 0. Verify if this is correct.")
        self.hasShownCurrencyWarning = true -- Set flag after first display
    end
    return amount
end

-- Function to format numbers with commas
function RanckorsBaggage:FormatNumberWithCommas(number)
    return tostring(number):reverse():gsub("(%d%d%d)", "%1,"):gsub(",(%-?)$", "%1"):reverse()
end


-- Function to update currency data
function RanckorsBaggage:UpdateCurrencyData()
    -- Player-held currency
    self.gold = self:GetCurrencySafely(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
    self.alliancePoints = self:GetCurrencySafely(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER)
    self.telVar = self:GetCurrencySafely(CURT_TELVAR_STONES, CURRENCY_LOCATION_CHARACTER)
    self.eventTickets = self:GetCurrencySafely(CURT_EVENT_TICKETS, CURRENCY_LOCATION_ACCOUNT)
    self.undauntedKeys = self:GetCurrencySafely(CURT_UNDAUNTED_KEYS, CURRENCY_LOCATION_ACCOUNT)
    self.transmuteCrystals = self:GetCurrencySafely(CURT_CHAOTIC_CREATIA, CURRENCY_LOCATION_ACCOUNT)
    self.crownGems = self:GetCurrencySafely(CURT_CROWN_GEMS, CURRENCY_LOCATION_ACCOUNT)
    self.imperialFragments = self:GetCurrencySafely(CURT_IMPERIAL_FRAGMENTS, CURRENCY_LOCATION_ACCOUNT)
    self.sealsOfEndeavour = self:GetCurrencySafely(CURT_ENDEAVOR_SEALS, CURRENCY_LOCATION_ACCOUNT)
    self.writVouchers = self:GetCurrencySafely(CURT_WRIT_VOUCHERS, CURRENCY_LOCATION_CHARACTER)
    self.archivalFortunes = self:GetCurrencySafely(CURT_ARCHIVAL_FORTUNES, CURRENCY_LOCATION_ACCOUNT)
    self.crowns = self:GetCurrencySafely(CURT_CROWNS, CURRENCY_LOCATION_ACCOUNT)
    -- Bag Information
    self.currentBagSpace = GetNumBagUsedSlots(BAG_BACKPACK)
    self.maxBagSpace = GetBagSize(BAG_BACKPACK)
    -- Bank-held currencies
    self.bankedGold = self:GetCurrencySafely(CURT_MONEY, CURRENCY_LOCATION_BANK)
    self.bankedAlliancePoints = self:GetCurrencySafely(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_BANK)
    self.bankedTelVar = self:GetCurrencySafely(CURT_TELVAR_STONES, CURRENCY_LOCATION_BANK)
    self.bankedWritVouchers = self:GetCurrencySafely(CURT_WRIT_VOUCHERS, CURRENCY_LOCATION_BANK)
    -- Bank information
    local currentBankUsed = GetNumBagUsedSlots(BAG_BANK)
    local maxBankSize = GetBagSize(BAG_BANK)
    local currentSubscriberBankUsed = GetNumBagUsedSlots(BAG_SUBSCRIBER_BANK)
    local maxSubscriberBankSize = GetBagSize(BAG_SUBSCRIBER_BANK)

    if IsESOPlusSubscriber() then
        -- Include subscriber bank slots for subscribers
        self.combinedBankUsedSpace = currentBankUsed + currentSubscriberBankUsed
        self.combinedMaxBankSpace = maxBankSize + maxSubscriberBankSize
        self.maxTransmuteCrystals = 1000
    else
        -- For non-subscribers, exclude max subscriber bank slots
        self.combinedBankUsedSpace = currentBankUsed + currentSubscriberBankUsed
        self.combinedMaxBankSpace = maxBankSize
        self.maxTransmuteCrystals = 500
    end

    -- Debug: Log subscription status and calculated values
    -- d(string.format("Subscription Status: %s", IsESOPlusSubscriber() and "Subscribed" or "Not Subscribed"))
    -- d(string.format("Bank Space: Used=%d, Max=%d", self.combinedBankUsedSpace, self.combinedMaxBankSpace))
    -- d(string.format("Transmute Crystals: %d/%d", self.transmuteCrystals, self.maxTransmuteCrystals))
end


-- Function to update the UI
function RanckorsBaggage:UpdateUI()
    if not IsValidRanckorsBaggageWindow() then
        return
    end

    local displaySettings = self.savedVariables.displaySettings or {}

    -- Set default colors
    local goldColour = "|cFFD700"
    local apColour = "|c50C878"
    local telVarColour = "|cADD8E6"
    local eventTicketColour = "|cFF69B4"
    local undauntedColour = "|cB5A642"
    local transmuteColour = "|c8A2BE2"
    local crownGemsColour = "|ce883e8"
    local imperialFragmentColor = "|c87CEEB"
    local sealsColour = "|c87CEEB"
    local writVoucherColour = "|cFFA500"
    local archivalFortunesColour = "|c800080"
    local crownsColour = "|cFFFF00"
    local bagColour = "|cFFFFFF"
    local bankColour = "|cFFFFFF"

    -- Calculate bag space usage percentage
    local bagUsagePercentage = (self.currentBagSpace / self.maxBagSpace) * 100
    local bankUsagePercentage = (self.combinedBankUsedSpace / self.combinedMaxBankSpace) * 100

    -- Adjust colors based on usage
    if bagUsagePercentage >= 95 then
        bagColour = "|cFF0000" -- Red
    elseif bagUsagePercentage >= 90 then
        bagColour = "|cFFA500" -- Amber
    end

    if bankUsagePercentage >= 95 then
        bankColour = "|cFF0000" -- Red
    elseif bankUsagePercentage >= 90 then
        bankColour = "|cFFA500" -- Amber
    end

    local infoText = string.format("|c888888 %s|r\n", self.version)
    infoText = infoText .. "|cCCCCCC--------Player--------|r\n"


    -- Build the information string
    local infoText = "|cCCCCCC--------Player--------|r\n"

    if displaySettings[CURT_MONEY] ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/gold_mipmap.dds|t %s|r\n", goldColour, self:FormatNumberWithCommas(self.gold))
    end
    if displaySettings[CURT_ALLIANCE_POINTS] ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/alliancepoints.dds|t %s|r\n", apColour, self:FormatNumberWithCommas(self.alliancePoints))
    end
    if displaySettings[CURT_TELVAR_STONES] ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/telvar_mipmap.dds|t %s|r\n", telVarColour, self:FormatNumberWithCommas(self.telVar))
    end
    if displaySettings[CURT_EVENT_TICKETS] ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/icon_eventticket_loot.dds|t %s/12|r\n", eventTicketColour, self:FormatNumberWithCommas(self.eventTickets))
    end
    if displaySettings[CURT_UNDAUNTED_KEYS] ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/undauntedkey.dds|t %s|r\n", undauntedColour, self:FormatNumberWithCommas(self.undauntedKeys))
    end
    if displaySettings[CURT_CHAOTIC_CREATIA] ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/currency_seedcrystal_32.dds|t %s/%s|r\n", transmuteColour, self:FormatNumberWithCommas(self.transmuteCrystals), self:FormatNumberWithCommas(self.maxTransmuteCrystals))
    end
    if displaySettings[CURT_CROWN_GEMS] ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/currency_crown_gems.dds|t %s|r\n", crownGemsColour, self:FormatNumberWithCommas(self.crownGems))
    end
    if displaySettings[CURT_IMPERIAL_FRAGMENTS] ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/currency_imperial_trophy_key_32.dds|t %s|r\n", imperialFragmentColor, self:FormatNumberWithCommas(self.imperialFragments))
    end
    if displaySettings[CURT_ENDEAVOR_SEALS] ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/currency_seals_of_endeavor_32.dds|t %s|r\n", sealsColour, self:FormatNumberWithCommas(self.sealsOfEndeavour))
    end
    if displaySettings[CURT_WRIT_VOUCHERS] ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/icons/icon_writvoucher.dds|t %s|r\n", writVoucherColour, self:FormatNumberWithCommas(self.writVouchers))
    end
    if displaySettings[CURT_ARCHIVAL_FORTUNES] ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/archivalfragments_32.dds|t %s|r\n", archivalFortunesColour, self:FormatNumberWithCommas(self.archivalFortunes))
    end
    if displaySettings[CURT_CROWNS] ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/icons/store_crowns.dds|t %s|r\n", crownsColour, self:FormatNumberWithCommas(self.crowns))
    end

    if displaySettings.BagSpace ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/tooltips/icon_bag.dds|t %d/%d|r\n", bagColour, self.currentBagSpace, self.maxBagSpace)
    end

    -- Add Banked information
    infoText = infoText .. "|cCCCCCC--------Banked--------|r\n"

    if displaySettings.BankedGold ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/gold_mipmap.dds|t %s|r\n", goldColour, self:FormatNumberWithCommas(self.bankedGold))
    end
    if displaySettings.BankedAlliancePoints ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/alliancepoints.dds|t %s|r\n", apColour, self:FormatNumberWithCommas(self.bankedAlliancePoints))
    end
    if displaySettings.BankedTelVar ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/currency/telvar_mipmap.dds|t %s|r\n", telVarColour, self:FormatNumberWithCommas(self.bankedTelVar))
    end
    if displaySettings.BankedWritVouchers ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/icons/icon_writvoucher.dds|t %s|r\n", writVoucherColour, self:FormatNumberWithCommas(self.bankedWritVouchers))
    end
    if displaySettings.BankSpace ~= false then
        infoText = infoText .. string.format("%s|t24:24:/esoui/art/icons/servicemappins/servicepin_bank.dds|t %d/%d|r\n", bankColour, self.combinedBankUsedSpace, self.combinedMaxBankSpace)
    end

    if RanckorsBaggage.RanckorsBaggageWindowLabel then
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetText(infoText)
    else
        d("Error: RanckorsBaggageWindowLabel is nil.")
    end
end

-- Function to check if the window is valid
function IsValidRanckorsBaggageWindow()
    return RanckorsBaggageWindow and RanckorsBaggage.RanckorsBaggageWindowLabel and RanckorsBaggageWindow.SetHidden
end

-- Function to toggle the window visibility
function RanckorsBaggage:ToggleWindow()
    if IsValidRanckorsBaggageWindow() then
        local isHidden = RanckorsBaggageWindow:IsHidden()
        RanckorsBaggageWindow:SetHidden(not isHidden)
        d("RanckorsBaggage window " .. (isHidden and "shown" or "hidden") .. ".")
    else
        d("Error: RanckorsBaggageWindow is not valid.")
    end
end

-- Event handler for player activated
function RanckorsBaggage:OnPlayerActivated(event)
    -- d("RanckorsBaggage: Player activated.")
    -- Unregister the event so it doesn't get called again
    EVENT_MANAGER:UnregisterForEvent("RanckorsBaggage", EVENT_PLAYER_ACTIVATED)

    -- Update the currency data and UI
    self:UpdateCurrencyData()
    self:UpdateUI()

    -- Restore the saved position
    self:RestorePosition()
end

-- Event handler for currency update
function RanckorsBaggage:OnCurrencyUpdate(event, currencyType, currencyLocation, newAmount, oldAmount)
    self:UpdateCurrencyData()
    self:UpdateUI()
end

-- Event handler for inventory update
function RanckorsBaggage:OnInventoryUpdate(event, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
    self:UpdateCurrencyData()
    self:UpdateUI()
end

-- OnAddOnLoaded event handler
function RanckorsBaggage:OnAddOnLoaded(event, addonName)
    if addonName == "RanckorsBaggage" then
        -- Initialize saved variables
        self.savedVariables = ZO_SavedVars:NewAccountWide("RanckorsBaggageSavedVars", 1, nil, {
            position = RanckorsBaggage.defaults.position,
            backgroundStyle = RanckorsBaggage.defaults.backgroundStyle,
            displaySettings = {
                -- Player currencies
                [CURT_MONEY] = true,
                [CURT_ALLIANCE_POINTS] = true,
                [CURT_TELVAR_STONES] = true,
                [CURT_EVENT_TICKETS] = true,
                [CURT_UNDAUNTED_KEYS] = true,
                [CURT_CHAOTIC_CREATIA] = true,
                [CURT_CROWN_GEMS] = true,
                [CURT_IMPERIAL_FRAGMENTS] = true,
                [CURT_ENDEAVOR_SEALS] = true,
                [CURT_WRIT_VOUCHERS] = true,
                [CURT_ARCHIVAL_FORTUNES] = true,
                [CURT_CROWNS] = true,
                -- Banked currencies
                BankedGold = true,
                BankedAlliancePoints = true,
                BankedTelVar = true,
                BankedWritVouchers = true,
                -- Bag and bank space
                BagSpace = true,
                BankSpace = true,
            },
        })

        -- Initialize the addon
        self:Initialize()
    end
end

-- Event handler for subscription status changes
function RanckorsBaggage:OnSubscriptionStatusChanged(event, isFreeTrialActive)
    d("ESO Plus subscription status changed.")
    self:UpdateCurrencyData()
    self:UpdateUI()
end

-- Register the subscription status event
EVENT_MANAGER:RegisterForEvent("RanckorsBaggage", EVENT_ESO_PLUS_FREE_TRIAL_STATUS_CHANGED, function(...) RanckorsBaggage:OnSubscriptionStatusChanged(...) end)

-- Register the addon's event handlers
EVENT_MANAGER:RegisterForEvent("RanckorsBaggage", EVENT_ADD_ON_LOADED, function(event, ...) RanckorsBaggage.hasShownCurrencyWarning = false, RanckorsBaggage:OnAddOnLoaded(event, ...) end)
