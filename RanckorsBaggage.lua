-- ----------------------------------------------
-- Module to handle Bag space and currency displays
-- ----------------------------------------------

-- Define addon namespace
local RanckorsBaggage = {}

-- Define the default saved variables
RanckorsBaggage.defaults = {
    position = { x = 0, y = 100 },  -- Default position if no saved variables exist
    backgroundStyle = "clear"       -- Default background style
}

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
    SLASH_COMMANDS["/rbsettings"] = function() self:ToggleSettingsWindow() end

end

-- Function to create UI
function RanckorsBaggage:CreateUI()
    d("Creating UI...")

    if not RanckorsBaggageWindow then
        -- Create the main window with a larger height
        RanckorsBaggageWindow = WINDOW_MANAGER:CreateTopLevelWindow("RanckorsBaggageWindow")
        RanckorsBaggageWindow:SetDimensions(300, 520) -- Adjusted height to fit all info
        RanckorsBaggageWindow:SetMovable(true)
        RanckorsBaggageWindow:SetMouseEnabled(true)
        RanckorsBaggageWindow:SetClampedToScreen(true)

        -- Create the background and set it to fill the window dynamically
        local background = WINDOW_MANAGER:CreateControl("$(parent)BG", RanckorsBaggageWindow, CT_BACKDROP)
        background:SetAnchorFill(RanckorsBaggageWindow)
        self:ApplyBackgroundStyle(background) -- Apply the current background style

        -- Create a label for the clickable link at the top
        RanckorsBaggage.RanckorsBaggageWindowLink = WINDOW_MANAGER:CreateControl("$(parent)Link", RanckorsBaggageWindow, CT_LABEL)
        RanckorsBaggage.RanckorsBaggageWindowLink:SetDimensions(280, 24) -- Adjust dimensions as needed
        RanckorsBaggage.RanckorsBaggageWindowLink:SetAnchor(TOPLEFT, RanckorsBaggageWindow, TOPLEFT, 10, 5) -- Positioned at the very top
        RanckorsBaggage.RanckorsBaggageWindowLink:SetFont("ZoFontGameSmall")
        RanckorsBaggage.RanckorsBaggageWindowLink:SetColor(0, 0.7, 1, 1) -- Link color (light blue)
        RanckorsBaggage.RanckorsBaggageWindowLink:SetText("|t24:24:/esoui/art/help/help_tabicon_cs_up.dds|t |u1:0::RanckorsBaggage|u") -- Text with an icon
        RanckorsBaggage.RanckorsBaggageWindowLink:SetMouseEnabled(true)

        -- Click handler to open website
        RanckorsBaggage.RanckorsBaggageWindowLink:SetHandler("OnMouseUp", function()
            RequestOpenUnsafeURL("https://illyriat.com/") -- Replace with the actual URL
        end)

        -- Create the label to display the information, positioned below the link
        RanckorsBaggage.RanckorsBaggageWindowLabel = WINDOW_MANAGER:CreateControl("$(parent)Label", RanckorsBaggageWindow, CT_LABEL)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetDimensions(280, 480) -- Adjusted to match new window height
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetAnchor(TOPLEFT, RanckorsBaggageWindow, TOPLEFT, 10, 35) -- Positioned lower to avoid overlap
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetFont("ZoFontGameLarge")
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetColor(1, 1, 1, 1)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetVerticalAlignment(TEXT_ALIGN_TOP)

        -- Hook into the move event to save the new position
        RanckorsBaggageWindow:SetHandler("OnMoveStop", function()
            self:SavePosition()
        end)
    end
end

-- Table to map currency types to human-readable names. This then passes into the CreateSettingsWindow
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
function RanckorsBaggage:CreateSettingsWindow()
    if not RanckorsBaggageSettingsWindow then
        -- Create the settings window
        RanckorsBaggageSettingsWindow = WINDOW_MANAGER:CreateTopLevelWindow("RanckorsBaggageSettingsWindow")
        RanckorsBaggageSettingsWindow:SetDimensions(400, 800)
        RanckorsBaggageSettingsWindow:SetMovable(true)
        RanckorsBaggageSettingsWindow:SetMouseEnabled(true)
        RanckorsBaggageSettingsWindow:SetClampedToScreen(true)
        RanckorsBaggageSettingsWindow:SetHidden(true)

        -- Center the settings window
        RanckorsBaggageSettingsWindow:ClearAnchors()
        RanckorsBaggageSettingsWindow:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)

        -- Add a background
        local background = WINDOW_MANAGER:CreateControl("$(parent)BG", RanckorsBaggageSettingsWindow, CT_BACKDROP)
        background:SetAnchorFill(RanckorsBaggageSettingsWindow)
        background:SetCenterColor(0.1, 0.1, 0.1, 0.8)
        background:SetEdgeColor(0.5, 0.5, 0.5, 1)

        -- Add a title label
        local title = WINDOW_MANAGER:CreateControl("$(parent)Title", RanckorsBaggageSettingsWindow, CT_LABEL)
        title:SetDimensions(380, 24)
        title:SetAnchor(TOP, RanckorsBaggageSettingsWindow, TOP, 0, 10)
        title:SetFont("ZoFontWinH1")
        title:SetText("|cFFD700Ranckors Baggage Settings|r")

        -- Add an Exit button in the top-right corner
        local exitButton = WINDOW_MANAGER:CreateControl("$(parent)ExitButton", RanckorsBaggageSettingsWindow, CT_BUTTON)
        exitButton:SetDimensions(20, 20)
        exitButton:SetAnchor(TOPRIGHT, RanckorsBaggageSettingsWindow, TOPRIGHT, -10, 10)
        exitButton:SetText("X")
        exitButton:SetFont("ZoFontGameSmall")
        exitButton:SetHandler("OnClicked", function()
            RanckorsBaggageSettingsWindow:SetHidden(true)
        end)

        -- Helper function to create a toggle button
        local toggleControls = {} -- Store references to toggle buttons for reset functionality
        local function CreateToggle(parent, x, y, label, key)
            -- Container for consistent alignment
            local container = WINDOW_MANAGER:CreateControl(nil, parent, CT_CONTROL)
            container:SetDimensions(360, 30)
            container:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)

            -- Label
            local toggleLabel = WINDOW_MANAGER:CreateControl(nil, container, CT_LABEL)
            toggleLabel:SetAnchor(LEFT, container, LEFT, 10, 0)
            toggleLabel:SetFont("ZoFontGameSmall")
            toggleLabel:SetText(label)

            -- Toggle button
            local toggleButton = WINDOW_MANAGER:CreateControl(nil, container, CT_BUTTON)
            toggleButton:SetDimensions(60, 20)
            toggleButton:SetAnchor(RIGHT, container, RIGHT, -10, 0)
            toggleButton:SetFont("ZoFontGameSmall")
            toggleButton:SetText(self.savedVariables.displaySettings[key] and "|c00FF00ON|r" or "|cFF0000OFF|r")
            toggleButton.key = key -- Save the key for reset functionality
            toggleButton:SetHandler("OnClicked", function()
                -- Toggle the setting and update UI
                self.savedVariables.displaySettings[key] = not self.savedVariables.displaySettings[key]
                toggleButton:SetText(self.savedVariables.displaySettings[key] and "|c00FF00ON|r" or "|cFF0000OFF|r")
                self:UpdateUI()
            end)

            -- Store toggle button reference
            toggleControls[key] = toggleButton
        end

        -- Define sections and toggles
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

        -- Add toggles for each section with headings
        local startY = 50
        local offsetY = 30

        -- Player Currency Heading
        local playerHeading = WINDOW_MANAGER:CreateControl(nil, RanckorsBaggageSettingsWindow, CT_LABEL)
        playerHeading:SetAnchor(TOPLEFT, RanckorsBaggageSettingsWindow, TOPLEFT, 20, startY)
        playerHeading:SetFont("ZoFontGameBold")
        playerHeading:SetText("|cCCCCCCPlayer Currencies|r")
        startY = startY + offsetY

        for _, item in ipairs(playerCurrencies) do
            CreateToggle(RanckorsBaggageSettingsWindow, 20, startY, item.label, item.key)
            startY = startY + offsetY
        end

        -- Banked Currency Heading
        local bankedHeading = WINDOW_MANAGER:CreateControl(nil, RanckorsBaggageSettingsWindow, CT_LABEL)
        bankedHeading:SetAnchor(TOPLEFT, RanckorsBaggageSettingsWindow, TOPLEFT, 20, startY)
        bankedHeading:SetFont("ZoFontGameBold")
        bankedHeading:SetText("|cCCCCCCBanked Currencies|r")
        startY = startY + offsetY

        for _, item in ipairs(bankedCurrencies) do
            CreateToggle(RanckorsBaggageSettingsWindow, 20, startY, item.label, item.key)
            startY = startY + offsetY
        end

        -- Utilities Heading
        local utilitiesHeading = WINDOW_MANAGER:CreateControl(nil, RanckorsBaggageSettingsWindow, CT_LABEL)
        utilitiesHeading:SetAnchor(TOPLEFT, RanckorsBaggageSettingsWindow, TOPLEFT, 20, startY)
        utilitiesHeading:SetFont("ZoFontGameBold")
        utilitiesHeading:SetText("|cCCCCCCUtilities|r")
        startY = startY + offsetY

        for _, item in ipairs(utilities) do
            CreateToggle(RanckorsBaggageSettingsWindow, 20, startY, item.label, item.key)
            startY = startY + offsetY
        end

        -- Add Reset Button
        local resetButton = WINDOW_MANAGER:CreateControl("$(parent)ResetButton", RanckorsBaggageSettingsWindow, CT_BUTTON)
        resetButton:SetAnchor(BOTTOMRIGHT, RanckorsBaggageSettingsWindow, BOTTOMRIGHT, -20, -20)
        resetButton:SetDimensions(120, 40)
        resetButton:SetFont("ZoFontWinH3")
        resetButton:SetText("|cFFD700Reset|r")
        resetButton:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
        resetButton:SetVerticalAlignment(TEXT_ALIGN_CENTER)
        resetButton:SetHandler("OnClicked", function()
            -- Reset all settings to default
            for _, item in ipairs(playerCurrencies) do
                self.savedVariables.displaySettings[item.key] = true
            end
            for _, item in ipairs(bankedCurrencies) do
                self.savedVariables.displaySettings[item.key] = true
            end
            for _, item in ipairs(utilities) do
                self.savedVariables.displaySettings[item.key] = true
            end
            -- Update toggle button text
            for key, toggle in pairs(toggleControls) do
                toggle:SetText("|c00FF00ON|r")
            end
            self:UpdateUI()
        end)

        -- Add a Theme toggle button
    local themeButton = WINDOW_MANAGER:CreateControl("$(parent)ThemeButton", RanckorsBaggageSettingsWindow, CT_BUTTON)
    themeButton:SetAnchor(BOTTOMLEFT, RanckorsBaggageSettingsWindow, BOTTOMLEFT, 20, -20) -- Position it in line with the Reset button
    themeButton:SetDimensions(120, 40)
    themeButton:SetFont("ZoFontWinH3")
    themeButton:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    themeButton:SetVerticalAlignment(TEXT_ALIGN_CENTER)
        
    -- Update the button text based on the current theme
    local function UpdateThemeButtonText()
        themeButton:SetText("|cFFD700Theme: " .. string.upper(self.savedVariables.backgroundStyle) .. "|r")
    end
    
    -- Set the button's click handler to toggle the theme
    themeButton:SetHandler("OnClicked", function()
        -- Toggle between "clear" and "dark" themes
        local newStyle = (self.savedVariables.backgroundStyle == "clear") and "dark" or "clear"
        self:SetBackgroundStyle(newStyle)
        UpdateThemeButtonText()
    end)
    
    -- Initialize the button's text
    UpdateThemeButtonText()

    end
end











-- Settings toggle
function RanckorsBaggage:ToggleSettingsWindow()
    if not RanckorsBaggageSettingsWindow then
        self:CreateSettingsWindow()
    end
    RanckorsBaggageSettingsWindow:SetHidden(not RanckorsBaggageSettingsWindow:IsHidden())
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

-- Removes the addon from view when opening a menu such as Map, B
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

    -- Bank-held currency
    self.bankedGold = self:GetCurrencySafely(CURT_MONEY, CURRENCY_LOCATION_BANK)
    self.bankedAlliancePoints = self:GetCurrencySafely(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_BANK)
    self.bankedTelVar = self:GetCurrencySafely(CURT_TELVAR_STONES, CURRENCY_LOCATION_BANK)
    self.bankedWritVouchers = self:GetCurrencySafely(CURT_WRIT_VOUCHERS, CURRENCY_LOCATION_BANK)
    
    -- Bank information
    local currentBankSpace = GetNumBagUsedSlots(BAG_BANK)
    local maxBankSpace = GetBagUseableSize(BAG_BANK)
    
    -- Subscribers Bank Information 
    local currentSubBankSpace = GetNumBagUsedSlots(BAG_SUBSCRIBER_BANK)
    local maxSubBankSpace = GetBagSize(BAG_SUBSCRIBER_BANK)
    
    -- Combine Both 
    self.combinedBankUsedSpace = currentBankSpace + currentSubBankSpace
    self.combinedMaxBankSpace = maxBankSpace + maxSubBankSpace

    -- Determine the max transmute crystals based on subscription status
    if IsESOPlusSubscriber() then
        self.maxTransmuteCrystals = 1000
    else
        self.maxTransmuteCrystals = 500
    end
end


-- Function to format numbers with commas
function RanckorsBaggage:FormatNumberWithCommas(number)
    return tostring(number):reverse():gsub("(%d%d%d)", "%1,"):gsub(",(%-?)$", "%1"):reverse()
end





-- Function to update UI
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
    d("RanckorsBaggage: Player activated.")
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

-- Register the addon's event handlers
EVENT_MANAGER:RegisterForEvent("RanckorsBaggage", EVENT_ADD_ON_LOADED, function(event, ...) RanckorsBaggage.hasShownCurrencyWarning = false, RanckorsBaggage:OnAddOnLoaded(event, ...) end)
