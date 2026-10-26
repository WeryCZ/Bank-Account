-- SharedBankController
--
-- Controller for the Shared Bank page
--

SharedBankController = {}
local dir = g_currentModDirectory
SharedBankController._mt = Class(SharedBankController, FrameElement)

function SharedBankController.register()
    local bankAccountPage = SharedBankController.new()

    g_gui:loadProfiles(Utils.getFilename("gui/BankAccountProfiles.xml", dir))
    g_gui:loadGui(Utils.getFilename("gui/BankAccountPage.xml", dir), "BankAccountPage", bankAccountPage)
    SharedBankController.activeController = bankAccountPage

    return bankAccountPage
end

function SharedBankController:onFrameOpen()
    self:refresh()
end

function SharedBankController:refresh()
    self.sharedBankEntries = SharedBank:getLog()
    self.sharedBankBalance = SharedBank:getBalance()
    self.localBalanceAmount = SharedBank:getLocalBalance()

    self.depositBalance:setText(g_i18n:getText("bankAccount_sharedBalance") .. ": " .. SharedBank:formatMoney(self.sharedBankBalance))
    self.depositQuickAll:setText(SharedBank:formatMoney(self.localBalanceAmount))
    self.withdrawQuickAll:setText(SharedBank:formatMoney(self.sharedBankBalance))
    self.depositQuick10:setText(SharedBank:formatMoney(10))
    self.depositQuick100:setText(SharedBank:formatMoney(100))
    self.depositQuick1000:setText(SharedBank:formatMoney(1000))
    self.depositQuick10000:setText(SharedBank:formatMoney(10000))
    self.depositQuick1000000:setText(SharedBank:formatMoney(1000000))
    self.withdrawQuick10:setText(SharedBank:formatMoney(10))
    self.withdrawQuick100:setText(SharedBank:formatMoney(100))
    self.withdrawQuick1000:setText(SharedBank:formatMoney(1000))
    self.withdrawQuick10000:setText(SharedBank:formatMoney(10000))
    self.withdrawQuick1000000:setText(SharedBank:formatMoney(1000000))
    self.depositButton:setDisabled(self.localBalanceAmount <= 0)
    self.withdrawButton:setDisabled(self.sharedBankBalance <= 0)
    self.depositAmount:setDisabled(self.localBalanceAmount <= 0)
    self.withdrawAmount:setDisabled(self.sharedBankBalance <= 0)
    self:updateQuickButton(self.depositQuick10, 10, self.localBalanceAmount)
    self:updateQuickButton(self.depositQuick100, 100, self.localBalanceAmount)
    self:updateQuickButton(self.depositQuick1000, 1000, self.localBalanceAmount)
    self:updateQuickButton(self.depositQuick10000, 10000, self.localBalanceAmount)
    self:updateQuickButton(self.depositQuick1000000, 1000000, self.localBalanceAmount)
    self:updateQuickButton(self.depositQuickAll, self.localBalanceAmount, self.localBalanceAmount)
    self:updateQuickButton(self.withdrawQuick10, 10, self.sharedBankBalance)
    self:updateQuickButton(self.withdrawQuick100, 100, self.sharedBankBalance)
    self:updateQuickButton(self.withdrawQuick1000, 1000, self.sharedBankBalance)
    self:updateQuickButton(self.withdrawQuick10000, 10000, self.sharedBankBalance)
    self:updateQuickButton(self.withdrawQuick1000000, 1000000, self.sharedBankBalance)
    self:updateQuickButton(self.withdrawQuickAll, self.sharedBankBalance, self.sharedBankBalance)
    self.sharedBankLogLayout:reloadData()
end

function SharedBankController:updateQuickButton(button, amount, available)
    if button ~= nil then
        button:setDisabled(amount <= 0 or amount > available)
    end
end

function SharedBankController:onFrameClose()
    -- no op
end

function SharedBankController:onTabOpen()
    -- no op
end

function SharedBankController:getNumberOfSections(list)
    return 1
end

function SharedBankController:getNumberOfItemsInSection(list, section)
    if list == self.sharedBankLogLayout then
        return #self.sharedBankEntries
    end

    return 0
end

function SharedBankController:populateCellForItemInSection(list, section, index, cell)
    local entry = self.sharedBankEntries[index]
    if entry == nil then return end
    local dateTime = entry.date or ""
    if entry.time ~= nil and entry.time ~= "" then
        dateTime = dateTime .. " " .. entry.time
    end
    cell:getAttribute("dateSave"):setText(dateTime .. "\n" .. (entry.save or ""))
    local transfer
    if entry.sign ~= nil and entry.amount ~= nil then
        transfer = entry.sign .. " " .. SharedBank:formatMoney(entry.amount)
    else
        local legacyChange = tostring(entry.change or "")
        local sign = legacyChange:sub(1, 1) == "-" and "-" or "+"
        transfer = sign .. " " .. SharedBank:formatMoney(legacyChange:gsub("[^%d]", ""))
    end
    local sharedBalance = tostring(entry.sharedBalance or "")
    sharedBalance = SharedBank:formatMoney(sharedBalance)
    cell:getAttribute("amountBalance"):setText(transfer .. "\n" .. sharedBalance)
end


function SharedBankController.new(subclass_mt)
    local self = FrameElement.new(nil, subclass_mt or SharedBankController._mt)
    self.sharedBankEntries = {}
    return self
end

function SharedBankController:setAmount(amount)
    self.depositAmount:setText(tostring(amount))
    self.withdrawAmount:setText(tostring(amount))
end

function SharedBankController:onClickDeposit()
    local controller = SharedBankController.activeController
    controller:clampAmount(controller.depositAmount, SharedBank:getLocalBalance())
    SharedBank:deposit(controller:getAmount(controller.depositAmount))
    controller:refresh()
end

function SharedBankController:onClickWithdraw()
    local controller = SharedBankController.activeController
    controller:clampAmount(controller.withdrawAmount, SharedBank:getBalance())
    SharedBank:withdraw(controller:getAmount(controller.withdrawAmount))
    controller:refresh()
end

function SharedBankController:getAmount(input)
    local text = input:getText() or "0"
    text = tostring(text):gsub("[^%d]", "")
    return tonumber(text) or 0
end

function SharedBankController:sanitizeAmount(input)
    if self.sanitizingAmount then return end
    self.sanitizingAmount = true
    local text = tostring(input:getText() or ""):gsub("[^%d]", "")
    if input:getText() ~= text then
        input:setText(text)
    end
    self.sanitizingAmount = false
end

function SharedBankController:onDepositAmountChanged()
    SharedBankController.activeController:sanitizeAmount(SharedBankController.activeController.depositAmount)
end

function SharedBankController:onWithdrawAmountChanged()
    SharedBankController.activeController:sanitizeAmount(SharedBankController.activeController.withdrawAmount)
end

function SharedBankController:clampAmount(input, maximum)
    local controller = SharedBankController.activeController
    local amount = controller:getAmount(input)
    if amount > maximum then
        input:setText(tostring(maximum))
    end
end

function SharedBankController:clampFocusedAmount(input)
    if input == self.depositAmount then
        self:clampAmount(input, SharedBank:getLocalBalance())
    elseif input == self.withdrawAmount then
        self:clampAmount(input, SharedBank:getBalance())
    end
end

function SharedBankController:onDepositAmountFocusLost()
    local controller = SharedBankController.activeController
    controller:clampAmount(controller.depositAmount, SharedBank:getLocalBalance())
end

function SharedBankController:onWithdrawAmountFocusLost()
    local controller = SharedBankController.activeController
    controller:clampAmount(controller.withdrawAmount, SharedBank:getBalance())
end

function SharedBankController:setDepositAmount(amount)
    SharedBankController.activeController.depositAmount:setText(tostring(amount))
end

function SharedBankController:setWithdrawAmount(amount)
    SharedBankController.activeController.withdrawAmount:setText(tostring(amount))
end

function SharedBankController:depositQuick(amount)
    local controller = SharedBankController.activeController
    SharedBank:deposit(amount)
    controller:refresh()
end

function SharedBankController:withdrawQuick(amount)
    local controller = SharedBankController.activeController
    SharedBank:withdraw(amount)
    controller:refresh()
end

function SharedBankController:onClickDepositQuick10()
    SharedBankController:depositQuick(10)
end

function SharedBankController:onClickDepositQuick100()
    SharedBankController:depositQuick(100)
end

function SharedBankController:onClickDepositQuick1000()
    SharedBankController:depositQuick(1000)
end

function SharedBankController:onClickDepositQuick10000()
    SharedBankController:depositQuick(10000)
end

function SharedBankController:onClickDepositQuick1000000()
    SharedBankController:depositQuick(1000000)
end

function SharedBankController:onClickDepositQuickAll()
    SharedBankController:depositQuick(SharedBank:getLocalBalance())
end

function SharedBankController:onClickWithdrawQuick10()
    SharedBankController:withdrawQuick(10)
end

function SharedBankController:onClickWithdrawQuick100()
    SharedBankController:withdrawQuick(100)
end

function SharedBankController:onClickWithdrawQuick1000()
    SharedBankController:withdrawQuick(1000)
end

function SharedBankController:onClickWithdrawQuick10000()
    SharedBankController:withdrawQuick(10000)
end

function SharedBankController:onClickWithdrawQuick1000000()
    SharedBankController:withdrawQuick(1000000)
end

function SharedBankController:onClickWithdrawQuickAll()
    SharedBankController:withdrawQuick(SharedBank:getBalance())
end

function SharedBankController:onClickSharedBank()
    g_inGameMenu.pageStatistics.subCategoryPaging:setState(InGameMenuStatisticsFrame.SUB_CATEGORY.BANK_ACCOUNT, true)
end
