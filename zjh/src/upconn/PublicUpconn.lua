local _M = {}

local function _readRoomInfo(po)
    local info = {}
    info.roomid    = po:read_int32()
    info.lower     = po:read_int32()
    info.upper     = po:read_int32()
    info.base      = po:read_int32()
    info.allin     = po:read_int32()
    info.usercount = po:read_int32()
    return info
end

local function _readUserInfo(po)
    local info = {}
    info.ticketid = po:read_int32()
    info.username = po:read_string()
    info.nickname = po:read_string()
    info.avatar   = po:read_string()
    info.gender   = po:read_byte()
    info.balance  = po:read_int64()
    return info
end

local function _readTableInfo(po)
    local info = {}
    info.tableid     = po:read_int32()
    info.status      = po:read_byte()
    info.round       = po:read_byte()
    info.basebet     = po:read_int32()
    info.jackpot     = po:read_int32()
    info.banker      = po:read_byte()
    info.currseat    = po:read_byte()
    info.playercount = po:read_int32()
    info.playerseat  = {}
    for i = 1, info.playercount do
        table.insert(info.playerseat, po:read_byte())
    end
    return info
end

local function _readSeatPlayerInfo(po)
    local info = {}
    info.ticketid   = po:read_int32()
    info.nickname   = po:read_string()
    info.avatar     = po:read_string()
    info.gender     = po:read_byte()
    info.balance    = po:read_int64()
    info.status     = po:read_byte()
    info.seat       = po:read_byte()
    info.bet        = po:read_int32()
    info.bankermult = po:read_int32()
    info.mult       = po:read_int32()  
    info.isshow     = po:read_int32()
    
    return info
end

local function _readCards(stringCards)
    local cards = {}
    for i=1, string.len(stringCards) do
        local card = string.byte(stringCards, i, i)
        table.insert(cards, card)
    end
    return cards
end

-- 心跳
function _M.onHeartBeat(conn, sessionid, msgid)
    local resp = {}   
    local po = upconn.upconn:get_packet_obj()
    
    if app.Connect then
        app.Connect:getInstance():respHeartbeat()
    end    
end

-- 注册
function _M.onRegister(conn, sessionid, msgid)       
    local resp = {}   
    local po = upconn.upconn:get_packet_obj()
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()

    print("onRegister",resp.errorCode)
    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        app.lobby.login.RegisterPresenter:getInstance():RegisterSuccess()
    else
        app.lobby.login.RegisterPresenter:getInstance():RegisterFail()
    end    
end

-- 登录
function _M.onLogin(conn, sessionid, msgid)   
    local resp = {}   
    local po = upconn.upconn:get_packet_obj()
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()
    resp.version   = po:read_string()
    resp.host      = po:read_string()
    resp.onlineCnt = po:read_int32()

    resp.gameCount = po:read_byte()   
    for i = 1, resp.gameCount do
        local gametype = po:read_int32()  
        resp.roomCount = po:read_byte()
        -- room info
        for j = 1, resp.roomCount do
            local info = _readRoomInfo(po)
            app.data.PlazaData.setPlazaList(info, gametype, j)
        end
    end

    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        -- user info
        local userInfo = {}
        userInfo = _readUserInfo(po)
        userInfo.session = sessionid
        -- recover flag
        local gaming = po:read_byte()  
        print("onenter is gaming",gaming)     
        -- 保存个人数据
        app.data.UserData.setUserData(userInfo)
        -- 分发登录成功消息
        app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_LOGIN_SUCCESS)

        app.data.UserData.setLoginState(1)      

        if gaming ~= 0 then
            local gametype = po:read_int32()
            local roomid =  po:read_int32()
            local base = app.data.PlazaData.getBaseByRoomid(gametype, roomid)
            local limit = app.data.PlazaData.getLimitByBase(gametype, base)
            app.game.GameEngine:getInstance():start(gametype, base, limit)            
            app.game.GameEngine:getInstance():onStartGame()   

            local tabInfo = _readTableInfo(po)
            tabInfo.basecoin = 0                        
            app.game.GameData.setTableInfo(tabInfo)

            local playerCount = po:read_int32()
            local ids = {}
            for i = 1, playerCount do
                -- seat player info
                local info = _readSeatPlayerInfo(po)
                dump(info)
                table.insert(ids,info.ticketid)
                app.game.PlayerData.onPlayerInfo(info)
            end            
            for k, id in ipairs(ids) do
                local player = app.game.PlayerData.getPlayerByNumID(id)
                if not player then                    
                    return
                end          
                app.game.GamePresenter:getInstance():onPlayerEnter(player)       
            end
            
            local player = {}            
            local stringCards = po:read_string()            
            player.cards      = _readCards(stringCards)  
            player.cardtype   = po:read_byte()

            app.game.GamePresenter:getInstance():onRelinkEnter(player)
        end             
    else
        -- error
        app.data.UserData.setLoginState(-1)
        app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_LOGIN_FAIL)
        print("login failed -- !!!!, errcode=" .. tostring(resp.errorCode) .. ", " .. resp.errorMsg)
    end    
end

-- 修改用户信息(avatar, gender)
function _M.onUserInfo(conn, sessionid, msgid)
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()

    app.lobby.usercenter.ChangeHeadPresenter:onReqChangeUserinfo(resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS)
end

-- 玩家状态
function _M.onPlayerStatus(conn, sessionid, msgid)
    local resp = {}
    local po = upconn.upconn:get_packet_obj()     
    resp.ticketid = po:read_int32()
    resp.status = po:read_byte()

    -- 7 离开
    -- 8 踢出房间
    print("playerstatus",resp.status)

    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onPlayerStatus(resp)    
    end
end

-- 玩家坐下
function _M.onPlayerSitDown(conn, sessionid, msgid)    
    print("onPlayerSitDown")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()

    local info = _readSeatPlayerInfo(po)

    if info.ticketid == app.data.UserData.getTicketID() then
        return
    end

    if app.game.PlayerData then
        app.game.PlayerData.onPlayerInfo(info)
    end
    local player = app.game.PlayerData.getPlayerByNumID(info.ticketid)
    if not player then
        return
    end  

    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onPlayerEnter(player)    
    end            
end

function _M.onEnterRoom(conn, sessionid, msgid)
    print("onEnterRoom")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()

    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        app.lobby.MainPresenter:getInstance():loadingHintExit()
        -- enter gamescene
        app.game.GameEngine:getInstance():onStartGame()
        
        local gameid = po:read_int32()
        local roomid = po:read_int32()
        
        -- table info
        local tabInfo = _readTableInfo(po)       
        tabInfo.basecoin = 0
        app.game.GameData.setTableInfo(tabInfo)

        -- seat in-gaming player info     
        local playerCount = po:read_int32()
        local ids = {}
        for i = 1, playerCount do
            -- seat player info
            local info = _readSeatPlayerInfo(po)

            table.insert(ids,info.ticketid)
            app.game.PlayerData.onPlayerInfo(info)
        end

        -- enter room
        for k, id in ipairs(ids) do
            local player = app.game.PlayerData.getPlayerByNumID(id)
            if not player then                
                return
            end            
            app.game.GamePresenter:getInstance():onPlayerEnter(player) 
            if app.data.UserData.getTicketID() == id then               
                _M.sendPlayerReady(gameid)
            end                    
        end
    else
        app.game.GameEngine:getInstance():exit()
        app.lobby.MainPresenter:getInstance():showErrorMsg(resp.errorCode)
    end
end

-- 离开房间
function _M.onLeaveRoom(conn, sessionid, msgid)
    local resp = {}
    local po   = upconn.upconn:get_packet_obj()
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()
    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        if app.game.GamePresenter then
            app.game.GamePresenter:getInstance():onLeaveRoom()
        end            
    end
end

-- 换桌
function _M.onChangeTable(conn, sessionid, msgid)
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()

    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        -- enter gamescene       
        local gameid = po:read_int32()
        local roomid =  po:read_int32()
        local base = app.data.PlazaData.getBaseByRoomid(gameid, roomid)
        local limit = app.data.PlazaData.getLimitByBase(gameid, base)
        app.game.GameEngine:getInstance():start(gameid, base, limit)            
        app.game.GameEngine:getInstance():onStartGame()

        app.game.GamePresenter:getInstance():onChangeTable()        

        -- table info
        local tabInfo = _readTableInfo(po)
        tabInfo.basecoin = 0
        app.game.GameData.setTableInfo(tabInfo)

        -- seat in-gaming player info     
        local playerCount = po:read_int32()
        local ids = {}
        for i = 1, playerCount do
            -- seat player info
            local info = _readSeatPlayerInfo(po)

            table.insert(ids,info.ticketid)
            app.game.PlayerData.onPlayerInfo(info)
        end
        -- enter room
        for k, id in ipairs(ids) do
            local player = app.game.PlayerData.getPlayerByNumID(id)
            if not player then

                return
            end                  
            app.game.GamePresenter:getInstance():onPlayerEnter(player)
            if app.data.UserData.getTicketID() == id then                
                _M.sendPlayerReady(gameid)
            end         
        end
    else
        app.game.GameEngine:getInstance():exit()  
    end
end

function _M.sendPlayerReady(gameid)
    print("sendPlayerReady")
    local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   

    po:writer_reset()
    po:write_int64(sessionid) -- test token
    if gameid == app.Game.GameID.ZJH then
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_READY_REQ)
    elseif gameid == app.Game.GameID.JDNN then
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_READY_REQ)
    end    
end

return _M