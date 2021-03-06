--[[
@brief  管理基类
]]

local app = app

local BasePresenter = class("BasePresenter")
local scheduler = cc.Director:getInstance():getScheduler()
---------------- 子类需配置项目 ---------------
-- UI单例
BasePresenter._ui   = nil
----------------------------------------------

-- 单例
BasePresenter._instance      = nil

-- 声明静态单例 
-- @param self
-- @return _instance
function BasePresenter:getInstance()
    if self._instance == nil then
        self._instance = self:create()
    end

    return self._instance
end

-- 初始化 
function BasePresenter:ctor()
end

-- 启动UI
function BasePresenter:start( ... )
    self:startUI( ... )
    self:init( ... )
end

-- 打开界面
function BasePresenter:startUI( ... )
    self._ui:getInstance():start( self, ... )
end

-- 初始化(由子类单独实现)
function BasePresenter:init( ... )
end

-- 退出界面
function BasePresenter:exit()
    self._ui:getInstance():exit()
end

-- 判断是否当前界面
function BasePresenter:isCurrentUI()
    return self._ui:getInstance():isCurrentUI()
end

-- 打开提示框
function BasePresenter:dealHintStart(...)
    app.lobby.public.HintPresenter:getInstance():start(...)
end

-- 关闭提示框
function BasePresenter:dealHintExit()
    app.lobby.public.HintPresenter:getInstance():exit()
end

-- 打开loading提示框
function BasePresenter:dealLoadingHintStart(...)
   app.lobby.public.LoadingHintPresenter:getInstance():start(...)
end

-- 关闭loading提示框
function BasePresenter:dealLoadingHintExit()
    app.lobby.public.LoadingHintPresenter:getInstance():exit()
end

function BasePresenter:dealTxtHintStart(...)
    app.lobby.public.TextHintPresenter:getInstance():start(...)
end

function BasePresenter:performWithDelayGlobal(listener, time)
    local handle
    handle = scheduler:scheduleScriptFunc(
        function()
            scheduler:unscheduleScriptEntry(handle)
            listener()
        end, time, false)
    return handle
end

function BasePresenter:sendAutoReady(gameid)        
    local sessionid = app.data.UserData.getSession() or 222
    local gameStream = app.connMgr.getGameStream()
    local po = gameStream:get_packet_obj()
    if po == nil then return end   

    po:writer_reset()
    po:write_int64(sessionid) -- test token

    if gameid == app.Game.GameID.ZJH then
        gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_READY_REQ)
    elseif gameid == app.Game.GameID.JDNN then
        gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_READY_REQ)
    elseif gameid == app.Game.GameID.QZNN then
        gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_C41_READY_REQ) 
    elseif gameid == app.Game.GameID.LHD then        
        gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_DRAGON_VS_TIGER_READY_REQ) 
    elseif gameid == app.Game.GameID.BRNN then        
        gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU100_READY_REQ) 
    elseif gameid == app.Game.GameID.DDZ then
        gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_DDZ_READY_REQ)                             
    end        
end

return BasePresenter
