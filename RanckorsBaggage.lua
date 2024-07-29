-- ----------------------------------------------
-- Module to handle Bag space and currency displays
-- ----------------------------------------------

-- Define addon namespace
local RanckorsBaggage = {}

-- Define the default saved variables
RanckorsBaggage.defaults = {
    position = { x = 0, y = 100 }  -- Default position if no saved variables exist
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
    end
    

-- Function to create UI
function RanckorsBaggage:CreateUI()
    d("Creating UI...")

    if not RanckorsBaggageWindow then
        -- Create the main window
        RanckorsBaggageWindow = WINDOW_MANAGER:CreateTopLevelWindow("RanckorsBaggageWindow")
        RanckorsBaggageWindow:SetDimensions(300, 300)
        RanckorsBaggageWindow:SetMovable(true)
        RanckorsBaggageWindow:SetMouseEnabled(true)
        RanckorsBaggageWindow:SetClampedToScreen(true)

        -- Create the background
        local background = WINDOW_MANAGER:CreateControl("RanckorsBaggageWindowBG", RanckorsBaggageWindow, CT_BACKDROP)
        background:SetAnchorFill(RanckorsBaggageWindow)
        background:SetCenterColor(0, 0, 0, 0)
        background:SetEdgeColor(0, 0, 0, 0)
        background:SetEdgeTexture("", 0, 0, 0)

        -- Create the label to display the information
        RanckorsBaggage.RanckorsBaggageWindowLabel = WINDOW_MANAGER:CreateControl("RanckorsBaggageWindowLabel", RanckorsBaggageWindow, CT_LABEL)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetDimensions(300, 300)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetAnchor(TOPLEFT, RanckorsBaggageWindow, TOPLEFT, 10, 10)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetFont("ZoFontGameLarge")
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetColor(1, 1, 1, 1)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        RanckorsBaggage.RanckorsBaggageWindowLabel:SetVerticalAlignment(TEXT_ALIGN_TOP)

        -- Hook into the move event to save the new position
        RanckorsBaggageWindow:SetHandler("OnMoveStop", function()
            self:SavePosition()
        end)
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



-- Restore the saved position
self:RestorePosition()
    end

-- Function to restore saved position
function RanckorsBaggage:RestorePosition()
    if self.savedVariables and self.savedVariables.position then
        RanckorsBaggageWindow:ClearAnchors()
        RanckorsBaggageWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.savedVariables.position.x, self.savedVariables.position.y)
        d("Restored position to: " .. self.savedVariables.position.x .. ", " .. self.savedVariables.position.y)
    else
        -- Set to default position if no saved variables
        RanckorsBaggageWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, RanckorsBaggage.defaults.position.x, RanckorsBaggage.defaults.position.y)
        d("Set to default position: " .. RanckorsBaggage.defaults.position.x .. ", " .. RanckorsBaggage.defaults.position.y)
    end
end

-- Function to save position
function RanckorsBaggage:SavePosition()
    if RanckorsBaggageWindow then
        self.savedVariables.position = { x = RanckorsBaggageWindow:GetLeft(), y = RanckorsBaggageWindow:GetTop() }
        d("Saved position: " .. self.savedVariables.position.x .. ", " .. self.savedVariables.position.y)
    end
end

-- Function to update currency data
function RanckorsBaggage:UpdateCurrencyData()
    self.gold = GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
    self.alliancePoints = GetCurrencyAmount(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER)
    self.telVar = GetCurrencyAmount(CURT_TELVAR_STONES, CURRENCY_LOCATION_CHARACTER)
    self.eventTickets = GetCurrencyAmount(CURT_EVENT_TICKETS, CURRENCY_LOCATION_ACCOUNT)
    self.undauntedKeys = GetCurrencyAmount(CURT_UNDAUNTED_KEYS, CURRENCY_LOCATION_ACCOUNT)
    self.transmuteCrystals = GetCurrencyAmount(CURT_CHAOTIC_CREATIA, CURRENCY_LOCATION_ACCOUNT)
    self.crownGems = GetCurrencyAmount(CURT_CROWN_GEMS, CURRENCY_LOCATION_ACCOUNT)
    self.sealsOfEndeavour = GetCurrencyAmount(CURT_ENDEAVOR_SEALS, CURRENCY_LOCATION_ACCOUNT)
    self.writVouchers = GetCurrencyAmount(CURT_WRIT_VOUCHERS, CURRENCY_LOCATION_CHARACTER)
    self.archivalFortunes = GetCurrencyAmount(CURT_ARCHIVAL_FORTUNES, CURRENCY_LOCATION_ACCOUNT)
    self.crowns = GetCurrencyAmount(CURT_CROWNS, CURRENCY_LOCATION_ACCOUNT)
    self.currentBagSpace = GetNumBagUsedSlots(BAG_BACKPACK)
    self.maxBagSpace = GetBagSize(BAG_BACKPACK)
    -- Bank information
    local currentBankSpace = GetNumBagUsedSlots(BAG_BANK)
    local maxBankSpace = GetBagUseableSize(BAG_BANK)
    -- Subscribers Bank Information 
    local currentSubBankSpace = GetNumBagUsedSlots(BAG_SUBSCRIBER_BANK)
    local maxSubBankSpace = GetBagSize(BAG_SUBSCRIBER_BANK)
    -- Combine Both 
    self.combinedBankUsedSpace = currentBankSpace + currentSubBankSpace
    self.combinedMaxBankSpace =
     maxBankSpace + maxSubBankSpace
    

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

    local goldColour = "|cFFD700"
    local apColour = "|c50C878"
    local telVarColour = "|cADD8E6"
    local eventTicketColour = "|cFF69B4"
    local undauntedColour = "|cB5A642"
    local transmuteColour = "|c8A2BE2"
    local crownGemsColour = "|ce883e8"
    local sealsColour = "|c2424BB" 
    local writVoucherColour = "|cFFA500"
    local archivalFortunesColour = "|c800080"
    local crownsColour = "|cFFFF00"
    local bagColour = "|cFFFFFF"
    local bankColour = "|cFFFFFF"

    local infoText = string.format("%s|t24:24:/esoui/art/currency/gold_mipmap.dds|t %s|r\n%s|t24:24:/esoui/art/currency/alliancepoints.dds|t %s|r\n%s|t24:24:/esoui/art/currency/telvar_mipmap.dds|t %s|r\n%s|t24:24:/esoui/art/currency/icon_eventticket_loot.dds|t %s/12|r\n%s|t24:24:/esoui/art/currency/undauntedkey.dds|t %s|r\n%s|t24:24:/esoui/art/currency/currency_seedcrystal_32.dds|t %s/%s|r\n%s|t24:24:/esoui/art/currency/currency_crown_gems.dds|t %s|r\n%s|t24:24:/esoui/art/currency/currency_seals_of_endeavor_32.dds|t %s|r\n%s|t24:24:/esoui/art/icons/icon_writvoucher.dds|t %s|r\n%s|t24:24:/esoui/art/currency/archivalfragments_32.dds|t %s|r\n%s|t24:24:/esoui/art/icons/store_crowns.dds|t %s|r\n%s|t24:24:/esoui/art/tooltips/icon_bag.dds|t %d/%d|r\n%s|t24:24:/esoui/art/icons/servicemappins/servicepin_bank.dds|t %s/%s|r",
        goldColour, self:FormatNumberWithCommas(self.gold),
        apColour, self:FormatNumberWithCommas(self.alliancePoints),
        telVarColour, self:FormatNumberWithCommas(self.telVar),
        eventTicketColour, self:FormatNumberWithCommas(self.eventTickets),
        undauntedColour, self:FormatNumberWithCommas(self.undauntedKeys),
        transmuteColour, self:FormatNumberWithCommas(self.transmuteCrystals), self:FormatNumberWithCommas(self.maxTransmuteCrystals),
        crownGemsColour, self:FormatNumberWithCommas(self.crownGems),
        sealsColour, self:FormatNumberWithCommas(self.sealsOfEndeavour),
        writVoucherColour, self:FormatNumberWithCommas(self.writVouchers),
        archivalFortunesColour, self:FormatNumberWithCommas(self.archivalFortunes),
        crownsColour, self:FormatNumberWithCommas(self.crowns),
        bagColour, self.currentBagSpace, self.maxBagSpace,
        bankColour, self.combinedBankUsedSpace, self.combinedMaxBankSpace)

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
    d("Player activated.")
    -- Unregister the event so it doesn't get called again
    EVENT_MANAGER:UnregisterForEvent("RanckorsBaggage", EVENT_PLAYER_ACTIVATED)

    -- Update the currency data and UI
    self:UpdateCurrencyData()
    self:UpdateUI()
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
        self.savedVariables = ZO_SavedVars:NewAccountWide("RanckorsBaggageSavedVars", 1, nil, RanckorsBaggage.defaults)

        -- Initialize the addon
        self:Initialize()
    end
end

-- Register the addon's event handlers
EVENT_MANAGER:RegisterForEvent("RanckorsBaggage", EVENT_ADD_ON_LOADED, function(event, ...) RanckorsBaggage:OnAddOnLoaded(event, ...) end)