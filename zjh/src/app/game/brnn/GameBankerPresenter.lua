
--[[
    @brief  庄家列表
]]--

local app = app

local GameBankerPresenter    = class("GameBankerPresenter", app.base.BasePresenter)

GameBankerPresenter._ui  = requireBRNN("app.game.brnn.GameBankerLayer")

-- 初始化
function GameBankerPresenter:init(players,flag)
    self._ui:getInstance():showPlayerList(players)    
    self._ui:getInstance():showBtnBanker(players, flag)    
end

function GameBankerPresenter:sendGobanker(type)
    local gameStream = app.connMgr.getGameStream()

    if type == 1 then
        local flag = self:checkCanGoBanker()
        if flag then
            print("send go banker")
            local po = gameStream:get_packet_obj()
            if po ~= nil then
                local sessionid = app.data.UserData.getSession() or 222
                po:writer_reset()
                po:write_int32(type)  
                gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU100_BANKER_BID_REQ)  
            end
        end
    else
        print("send down banker")
        local po = gameStream:get_packet_obj()
        if po ~= nil then
            local sessionid = app.data.UserData.getSession() or 222
            po:writer_reset()
            po:write_int32(type)  
            gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU100_BANKER_BID_REQ)  
        end
    end    
end

function GameBankerPresenter:showHint(type)
    self._ui:getInstance():showHint(type) 	
end

function GameBankerPresenter:showBtnCdTime(time)
    self._ui:getInstance():showBtnCdTime(time)  
end

function GameBankerPresenter:showBtnBankerEx()
    self._ui:getInstance():showBtnBankerEx()    
end

function GameBankerPresenter:checkCanGoBanker()
    local balance = app.data.UserData.getBalance()
    if balance < 1000000 then
        self:dealHintStart("申请上庄需要100万金币！" .."\n".."是否现在充值？",
            function(bFlag)
                if bFlag then
                    print("charge")
                end
            end
            , 2, true)
        return false    
    end
    
    return true    
end

return GameBankerPresenter