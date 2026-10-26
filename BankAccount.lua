SharedBank = {}
SharedBank.dir = g_currentModDirectory
SharedBank.settingsDir = getUserProfileAppPath() .. "modSettings/FS25_BankAccount/"
SharedBank.accountFile = SharedBank.settingsDir .. "BankAccount.xml"
SharedBank.logFile = SharedBank.settingsDir .. "BankAccountLog.xml"
source(SharedBank.dir .. "gui/BankAccountGui.lua")
source(SharedBank.dir .. "gui/BankAccountController.lua")

function SharedBank:loadData()
    createFolder(self.settingsDir)
    self.balance = 0
    self.log = {}

    local account = XMLFile.loadIfExists("SharedBank", self.accountFile)
    if account ~= nil then
        self.balance = account:getInt("sharedBank.balance") or 0
        account:delete()
    end

    local log = XMLFile.loadIfExists("SharedBankLog", self.logFile)
    if log ~= nil then
        local count = log:getInt("sharedBankLog.count") or 0
        for index = 1, count do
            local key = string.format("sharedBankLog.entry(%d)", index - 1)
            self.log[index] = {
                date = log:getString(key .. ".date") or "",
                time = log:getString(key .. ".time") or "",
                sign = log:getString(key .. ".sign") or "",
                amount = log:getString(key .. ".amount") or "",
                change = log:getString(key .. ".change") or "",
                save = log:getString(key .. ".save") or "",
                sharedBalance = log:getString(key .. ".sharedBalance") or log:getString(key .. ".account") or ""
            }
        end
        log:delete()
    end
end

function SharedBank:saveData()
    createFolder(self.settingsDir)
    local account = XMLFile.create("SharedBank", self.accountFile, "sharedBank")
    account:setInt("sharedBank.balance", self.balance)
    account:save()
    account:delete()

    local log = XMLFile.create("SharedBankLog", self.logFile, "sharedBankLog")
    log:setInt("sharedBankLog.count", #self.log)
    for index, entry in ipairs(self.log) do
        local key = string.format("sharedBankLog.entry(%d)", index - 1)
        log:setString(key .. ".date", entry.date)
        log:setString(key .. ".time", entry.time)
        log:setString(key .. ".sign", entry.sign)
        log:setString(key .. ".amount", entry.amount)
        log:setString(key .. ".change", entry.change)
        log:setString(key .. ".save", entry.save)
        log:setString(key .. ".sharedBalance", entry.sharedBalance)
    end
    log:save()
    log:delete()
end

function SharedBank:getBalance()
    return self.balance or 0
end

function SharedBank:formatAmount(amount)
    local numericAmount = tostring(amount or 0):gsub("[^%d%-]", "")
    local value = math.floor(tonumber(numericAmount) or 0)
    local sign = value < 0 and "-" or ""
    local digits = tostring(math.abs(value))
    while true do
        local formatted, count = digits:gsub("^(%d+)(%d%d%d)", "%1,%2")
        digits = formatted
        if count == 0 then break end
    end
    return sign .. digits
end

function SharedBank:formatDisplayAmount(amount)
    local numericAmount = tostring(amount or 0):gsub("[^%d%-]", "")
    local value = math.floor(tonumber(numericAmount) or 0)
    return self:formatAmount(value)
end

function SharedBank:getCurrencyUnit()
    if g_i18n ~= nil and g_i18n.formatMoney ~= nil then
        local sample = g_i18n:formatMoney(0, 0, true, true)
        local unit = tostring(sample):gsub("[%d%.,%s%-]", "")
        if unit ~= "" then
            return unit
        end
    end
    return "$"
end

function SharedBank:formatMoney(amount)
    local numericAmount = tostring(amount or 0):gsub("[^%d%-]", "")
    local value = math.floor(tonumber(numericAmount) or 0)

    if g_i18n ~= nil and g_i18n.formatMoney ~= nil then
        return g_i18n:formatMoney(value, 0, true, false)
    end

    return self:formatDisplayAmount(value) .. " " .. self:getCurrencyUnit()
end

function SharedBank:getLog()
    return self.log or {}
end

function SharedBank:getFarm()
    local farmId = g_currentMission:getFarmId()
    return g_farmManager:getFarmById(farmId), farmId
end

function SharedBank:getLocalBalance()
    local farm = self:getFarm()
    return farm ~= nil and farm.money or 0
end

function SharedBank:addLog(amount)
    local save = tostring(g_currentMission.missionInfo.savegameDirectory or "")
    save = save:match("([^/\\]+)$") or save
    local date = "unknown"
    local time = "unknown"
    if getDate ~= nil then
        date = getDate("%Y-%m-%d")
        time = getDate("%H:%M:%S")
    end
    table.insert(self.log, 1, {
        date = date,
        time = time,
        sign = amount >= 0 and "+" or "-",
        amount = self:formatAmount(math.abs(amount)),
        change = (amount >= 0 and "+" or "") .. self:formatAmount(math.abs(amount)),
        save = save,
        sharedBalance = self:formatAmount(self:getBalance())
    })
end

function SharedBank:deposit(amount)
    local farm, farmId = self:getFarm()
    amount = math.floor(amount or 0)
    if farm == nil or amount <= 0 or farm.money < amount then return false end
    g_currentMission:addMoney(-amount, farmId, MoneyType.OTHER)
    self.balance = self:getBalance() + amount
    self:addLog(amount)
    self:saveData()
    return true
end

function SharedBank:withdraw(amount)
    local _, farmId = self:getFarm()
    amount = math.floor(amount or 0)
    if amount <= 0 or amount > self:getBalance() then return false end
    g_currentMission:addMoney(amount, farmId, MoneyType.OTHER)
    self.balance = self:getBalance() - amount
    self:addLog(-amount)
    self:saveData()
    return true
end

function SharedBank:loadMap()
    self:loadData()
    local gui = SharedBankGui.new()
    local tabPosition = 6

    self.page = gui:addPage(tabPosition)
end

addModEventListener(SharedBank)
