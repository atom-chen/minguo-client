--[[
@brief  商城管理类
]]

local app = app

local SafePresenter = class("SafePresenter",app.base.BasePresenter)
SafePresenter._ui = requireLobby("app.lobby.safe.SafeLayer")

function SafePresenter:init()
    self:createDispatcher()

    self:initBankInfo()
end

function SafePresenter:createDispatcher()
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_BANK, handler(self, self.onBankUpdate))    
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_BALANCE, handler(self, self.onBalanceUpdate))
end

function SafePresenter:initBankInfo()
    self:onBankUpdate()
    self:onBalanceUpdate()	
end

function SafePresenter:onBankUpdate()
    if not self:isCurrentUI() then
        return
    end

    local bank = app.data.UserData.getSafeBalance()
    self._ui:getInstance():setBank(bank)
end

function SafePresenter:onBalanceUpdate()
    if not self:isCurrentUI() then
        return
    end

    local balance = app.data.UserData.getBalance()
    self._ui:getInstance():setBalance(balance)
end

function SafePresenter:getMaxGold(type)
	if type == "put" then
        return app.data.UserData.getBalance()
	elseif type == "out" then
        return app.data.UserData.getSafeBalance()	
	end
end

-- send
function SafePresenter:reqPut(num)
    local gameStream = app.connMgr.getGameStream()

    self:performWithDelayGlobal(
        function()
            local po = gameStream:get_packet_obj()
            if po ~= nil then
                po:writer_reset()
                po:write_int64(num)                  
                local sessionid = app.data.UserData.getSession() or 222
                gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_DEPOSIT_CASH_REQ)                       
                
                print("存入%d元",num)               
            end              
        end, 0.2)
        
end

function SafePresenter:reqOut(num)
    local gameStream = app.connMgr.getGameStream()

    self:performWithDelayGlobal(
        function()
            local po = gameStream:get_packet_obj()
            if po ~= nil then
                po:writer_reset()
                po:write_int64(-num)                  
                local sessionid = app.data.UserData.getSession() or 222
                gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_DEPOSIT_CASH_REQ)
                print("取出%d元",num)                        
            end              
        end, 0.2)
end
  
function SafePresenter:onSafeCallback(data)
    if data.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then        
        app.data.UserData.setBalance(data.balance)
        app.data.UserData.setSafeBalance(data.safebalance)

        self._ui:getInstance():resetEnterNum()
    else
        self:dealTxtHintStart("操作失败")
    end
end
  
return SafePresenter