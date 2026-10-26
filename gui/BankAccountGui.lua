-- SharedBankGui
--
-- GUI integration for the Shared Bank page
--

SharedBankGui = {}
SharedBankGui._mt = Class(SharedBankGui)
local gEnv = getmetatable(_G).__index

function SharedBankGui.new(custom_mt)
    local self = setmetatable({}, custom_mt or SharedBankGui._mt)
    local statsFrame = g_inGameMenu.pageStatistics

    SharedBankGui.appendFunction(statsFrame, "onFrameOpen", self, "sharedBankOnFrameOpen")
    SharedBankGui.prependedFunction(statsFrame, "onFrameClose", self, "sharedBankOnFrameClose")
    SharedBankGui.overwriteFunction(statsFrame.subCategoryPaging, "onClickCallback", self, "sharedBankOnClickCallback")
    SharedBankGui.overwriteFunction(statsFrame, "inputEvent", self, "sharedBankInputEvent")

    self.statsFrame = statsFrame
    self.screenController = nil

    return self
end

function SharedBankGui:addPage(position)
    local screenController = SharedBankController.register()
    local bankAccountPage = screenController.bankAccountPage
    local bankAccountTab = screenController.bankAccountTab

    self:addElementAtPosition(bankAccountPage, self.statsFrame.subCategoryPages[1].parent, position)
    table.insert(self.statsFrame.subCategoryPaging.texts, position, tostring(position))
    self:addElementAtPosition(bankAccountTab, self.statsFrame.subCategoryBox, position)

    table.insert(self.statsFrame.subCategoryPages, position, screenController.bankAccountPage)
    table.insert(self.statsFrame.subCategoryTabs, position, screenController.bankAccountTab)


    for subCategory, id in pairs(InGameMenuStatisticsFrame.SUB_CATEGORY) do
        if id >= position then
           InGameMenuStatisticsFrame.SUB_CATEGORY[subCategory] = id + 1
        end
    end

    InGameMenuStatisticsFrame.SUB_CATEGORY.BANK_ACCOUNT = position
    gEnv.g_i18n:setText("bankAccount_tab", g_i18n:getText("global_bankAccount_tab"))
    table.insert(InGameMenuStatisticsFrame.HEADER_TITLES, position, "bankAccount_tab")

    table.insert(self.statsFrame.menuButtonInfo, position, self.statsFrame.menuButtonInfoDefault)
    self.statsFrame:updateAbsolutePosition()
    self.statsFrame:exposeControlsAsFields(self.statsFrame.name)
    self.statsFrame.getDescendants = function()
        return bankAccountPage:getDescendants()
    end

    local tabPosition = position
    local statsFrame = self.statsFrame
    bankAccountTab:getDescendantByName("background").getIsSelected = function()
        return tabPosition == statsFrame.subCategoryPaging:getState()
    end
    bankAccountTab.getIsSelected = function()
        return tabPosition == statsFrame.subCategoryPaging:getState()
    end

    bankAccountPage:setTarget(self.statsFrame, bankAccountPage.target)
    bankAccountTab:setTarget(self.statsFrame, bankAccountTab.target)

    FocusManager:setGui(self.statsFrame.name)
    FocusManager:removeElement(bankAccountPage)
    FocusManager:removeElement(bankAccountTab)
    FocusManager:loadElementFromCustomValues(bankAccountPage)
    FocusManager:loadElementFromCustomValues(bankAccountTab)
    FocusManager:setGui(FocusManager.currentGui)

    self.screenController = screenController

    screenController.sharedBankLogLayout:setDataSource(screenController)
    screenController.sharedBankLogLayout:setDelegate(screenController)

    return screenController
end

function SharedBankGui:sharedBankOnFrameOpen(frame)
    frame.isOpening = true

    if self.screenController ~= nil then
        -- DebugUtil.printTableRecursively(self.screenController)
        self.screenController:onFrameOpen()
    end

    frame.isOpening = false
end

function SharedBankGui:sharedBankOnFrameClose(frame)
    if self.screenController ~= nil then
        self.screenController:onFrameClose()
    end
end

function SharedBankGui:addElementAtPosition(element, target, position)
    if element.parent ~= nil then
        element.parent:removeElement(element)
    end

    table.insert(target.elements, position, element)

    element.parent = target
end

function SharedBankGui:sharedBankOnClickCallback(superFunc, paging, state)

    if state == InGameMenuStatisticsFrame.SUB_CATEGORY.BANK_ACCOUNT then
        if self.screenController ~= nil then
            self.screenController:onTabOpen()
        end

        local bankAccountLogLayout = self.statsFrame.sharedBankLogLayout

        FocusManager:linkElements(self.statsFrame, FocusManager.TOP, bankAccountLogLayout)
        FocusManager:linkElements(self.statsFrame, FocusManager.BOTTOM, bankAccountLogLayout)
    end

    superFunc(paging, state)
    return nil
end

function SharedBankGui:sharedBankInputEvent(superFunc, statsFrame, action, value, eventUsed)
    local retValue = superFunc(statsFrame, action, value, eventUsed)

    if self.screenController ~= nil then
        local focusElement = FocusManager.currentFocusData ~= nil and FocusManager.currentFocusData.focusElement or nil
        local previousFocus = self.screenController.lastAmountFocus
        if previousFocus ~= nil and previousFocus ~= focusElement then
            self.screenController:clampFocusedAmount(previousFocus)
        end
        self.screenController.lastAmountFocus = focusElement
    end

    local pressedAccept = false
    local focusData = FocusManager.currentFocusData
    local element = focusData ~= nil and focusData.focusElement or nil

    if element ~= nil and not element.needExternalClick then
        pressedAccept = action == InputAction.MENU_ACCEPT

        if pressedAccept and not FocusManager:isFocusInputLocked(action) and element:getIsFocused() and element:getIsVisible() then
            FocusManager.focusSystemMadeChanges = true
            element:onFocusActivate()
            FocusManager.focusSystemMadeChanges = false
        end
    end

    return retValue or pressedAccept
end

function SharedBankGui.overwriteFunction(oldTarget, oldFunc, newTarget, newFunc)
    local superFunc = oldTarget[oldFunc]

    oldTarget[oldFunc] = function(...)
        return newTarget[newFunc](newTarget, superFunc, ...)
    end
end

function SharedBankGui.appendFunction(oldTarget, oldFunc, newTarget, newFunc)
    local superFunc = oldTarget[oldFunc]

    oldTarget[oldFunc] = function(...)
        superFunc(...)
        newTarget[newFunc](newTarget, ...)
    end
end

function SharedBankGui.prependedFunction(oldTarget, oldFunc, newTarget, newFunc)
    local superFunc = oldTarget[oldFunc]

    oldTarget[oldFunc] = function(...)
        newTarget[newFunc](newTarget, ...)
        superFunc(...)
    end
end
