--[[
@brief  游戏主场景控制基类
]]

local GamePlayerNode = require("app.game.zjh.GamePlayerNode")
local GameBtnNode    = require("app.game.zjh.GameBtnNode")
local GameMenuNode   = require("app.game.zjh.GameMenuNode")

local GamePresenter  = class("GamePresenter", app.base.BasePresenter)

GamePresenter._ui    = require("app.game.zjh.GameScene")

local scheduler = cc.Director:getInstance():getScheduler()

local HERO_LOCAL_SEAT   = 1
local CARD_NUM          = 3
local CV_BACK           = 0

local TIME_START_EFFECT = 0
local TIME_MAKE_BANKER  = 0.5
local TIME_THROW_CHIP   = 1.5
local TIME_TAKE_FIRST   = 2

local TIME_PLAYER_BET   = 15

-- 初始化
function GamePresenter:init(...)
    self._maxPlayerCnt = app.game.PlayerData.getMaxPlayerCount()  
    self:initPlayerNode()
    self:initBtnNode()
    self:initMenuNode()
    self:initScheduler()
end

function GamePresenter:initPlayerNode()
    self._gamePlayerNodes = {}
    for i = 0, self._maxPlayerCnt - 1 do
        local pnlPlayer = self._ui:getInstance():seekChildByName("pnl_player_"..i) 
        self._gamePlayerNodes[i] = GamePlayerNode:create(self, pnlPlayer, i)
    end    
end

function GamePresenter:initBtnNode()
    local nodeBtn = self._ui:getInstance():seekChildByName("node_game_btn")
    self._gameBtnNode = GameBtnNode:create(self, nodeBtn)
end

function GamePresenter:initMenuNode()
    local nodeMenu = self._ui:getInstance():seekChildByName("node_menu")
    self._gameMenuNode = GameMenuNode:create(self, nodeMenu)
end

function GamePresenter:initScheduler()    
    self._schedulerClocks      = {}      -- 时钟    
    self._schedulerTakeFirst   = nil     -- 发牌    
end

-- 退出界面
function GamePresenter:exit()
    GamePresenter.super.exit(self)
    
    self:closeSchedulerTakeFirst()
    self:closeSchedulerClocks()
    
    GamePresenter._instance = nil
end

function GamePresenter:performWithDelayGlobal(listener, time)
    local handle
    handle = scheduler:scheduleScriptFunc(
        function()
            scheduler:unscheduleScriptEntry(handle)
            listener()
        end, time, false)
    return handle
end

function GamePresenter:onPlayerStatus(data)
    if data.status == 7 then    -- 退出
        local numID = data.ticketid
        local player = app.game.PlayerData.getPlayerByNumID(numID)        

        if not player then
            return
        end

        app.game.PlayerData.onPlayerLeave(numID)
        self:onPlayerLeave(player)
    end
end

-- 处理玩家进入
function GamePresenter:onPlayerEnter(player)
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(player:getSeat()) 
    if self._gamePlayerNodes then
        self._gamePlayerNodes[localSeat]:onPlayerEnter() 
    end 
    
    self._ui:getInstance():showBiPaiPanel(false)  
end

function GamePresenter:onLeaveRoom()
    app.game.GameEngine:getInstance():exit()
end

-- 处理玩家离开
function GamePresenter:onPlayerLeave(player)
    local numID = player:getTicketID()
    -- 自己离开重置桌子
    if app.game.PlayerData.isHero(numID) then 
        for i = 0, self._maxPlayerCnt - 1 do
            if self._gamePlayerNodes[i] then
                self._gamePlayerNodes[i]:onResetTable()
            end
        end
    -- 某个玩家离开将该节点隐藏
    else 
        local localSeat = app.game.PlayerData.serverSeatToLocalSeat(player:getSeat())
        if self._gamePlayerNodes[localSeat] then
            self._gamePlayerNodes[localSeat]:onPlayerLeave()
        end

        if app.game.PlayerData.getPlayerCount() <= 1 then
            if self._gamePlayerNodes[HERO_LOCAL_SEAT] then
                self._gamePlayerNodes[HERO_LOCAL_SEAT]:onPlayerLeave()
            end
        end
    end
end

-- 玩家准备
function GamePresenter:onPlayerReady(seat)
	
end

-- 开始
function GamePresenter:onGameStart()
    for i = 0, self._maxPlayerCnt - 1 do
        local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i)
        if self._gamePlayerNodes[localSeat] then
            app.game.PlayerData.updatePlayerStatus(i, 3)
        end
    end
    
    -- 隐藏比牌
    self._ui:getInstance():showBiPaiPanel(false)
    
    -- 玩家开始
    for i = 0, self._maxPlayerCnt - 1 do
        if self._gamePlayerNodes[i] then
            self._gamePlayerNodes[i]:onGameStart()
        end
    end
    
    -- 初始化场景
    self:refreshUI()
    
    -- 开局动画    
    self:performWithDelayGlobal(
        function()
            self._ui:getInstance():showStartEffect()
        end, TIME_START_EFFECT)
    
    -- 确定庄家    
    self:performWithDelayGlobal(
        function()
            self:playBankerAction()
        end, TIME_MAKE_BANKER)
    
    -- 扔筹码
    self:performWithDelayGlobal(
        function()
            self:playChipAction()
        end, TIME_THROW_CHIP)
   
    -- 发牌
    self:performWithDelayGlobal(
        function()
            self:onTakeFirst()
        end, TIME_TAKE_FIRST)  
end

-- 发牌
function GamePresenter:onTakeFirst()
    local function callback()
        self._gameBtnNode:showBetBtns(true)
        self:onBankerBet()
    end
    
    self:openSchedulerTakeFirst(callback)
end

-- 时钟
function GamePresenter:onClock(serverSeat)
    for i = 0, self._maxPlayerCnt - 1 do
        if serverSeat == i then
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(serverSeat)
            self._gamePlayerNodes[localSeat]:onClock(TIME_PLAYER_BET)    
        else
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i)
            self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)
        end
    end    
end

-- 开始押注(庄家)
function GamePresenter:onBankerBet()
    local banker = app.game.GameData.getBanker()
    if app.game.PlayerData.getHeroSeat() == banker then
        self._gameBtnNode:showBetBtnEnable(true)
    else
        self._gameBtnNode:showBetBtnEnable(false)    
    end
    
    self:onClock(banker)
end

-- 玩家押注
function GamePresenter:onPlayerBet(seat)
    print("onPlayerBet open schedule!!!")
    if seat == -1 then
    	return
    end
    if app.game.PlayerData.getHeroSeat() == seat then
        self._gameBtnNode:showBetBtnEnable(true)
    else
        self._gameBtnNode:showBetBtnEnable(false)    
    end

    self:onClock(seat)
    
--    local flag = self._gameBtnNode:getCbxSelected()
--    if flag then
--        self:performWithDelayGlobal(
--            function()
--                self:sendBetmult(1) 
--            end, 3) 
--    end
end

-- 弃牌
function GamePresenter:onPlayerGiveUp(now, next, round)
    app.game.PlayerData.updatePlayerStatus(now, 5)
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(now)
    
    self._gamePlayerNodes[localSeat]:showImgCheck(true, 1)
    self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)   
    self._gamePlayerNodes[localSeat]:playSpeakAction(3) 
    self:showGaryCard(localSeat)
    
    if app.game.PlayerData.getHeroSeat() == now then
        self._gameBtnNode:showBetBtnEnable(false)
    end

    self:onPlayerBet(next)
end

-- 比牌
function GamePresenter:onPlayerCompareCard(data) 
    print("onPlayerCompareCard")  
    dump(data)
    app.game.PlayerData.updatePlayerRiches(data.playerSeat, data.playerBet, data.playerBalance)
    
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(data.playerSeat)
    local otherSeat = app.game.PlayerData.serverSeatToLocalSeat(data.acceptorSeat)
    local loserSeat = app.game.PlayerData.serverSeatToLocalSeat(data.loserSeat)    
    local mult = self:getMult(data.playerBet)
      
    self:refreshUI()
    self._ui:getInstance():showChipAction(mult, localSeat)
    self:playCompareAction(localSeat, otherSeat, loserSeat)
    
    self._gamePlayerNodes[localSeat]:showTxtBalance(true, data.playerBalance)
    self._gamePlayerNodes[localSeat]:showImgBet(true, data.playerBet)
    self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)
    
    self:onPlayerBet(app.game.GameData.getCurrseat())    
end 

-- 看牌
function GamePresenter:onPlayerShowCard(seat, cards)
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)
    if localSeat ~= 1 then
        self._gamePlayerNodes[localSeat]:showImgCheck(true, 0)
    end
    
    local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
    gameHandCardNode:resetHandCards()
    gameHandCardNode:createCards(cards)
end

-- 押注
function GamePresenter:onPlayerAnteUp(data)
    app.game.PlayerData.updatePlayerRiches(data.playerSeat, data.playerBet, data.playerBalance)
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(data.playerSeat)
    local mult = self:getMult(data.playerBet)  
    
    self:refreshUI()
    self._ui:getInstance():showChipAction(mult, localSeat)
       
    self._gamePlayerNodes[localSeat]:showTxtBalance(true, data.playerBalance)
    self._gamePlayerNodes[localSeat]:showImgBet(true, data.playerBet)
    if mult == 1 then
        self._gamePlayerNodes[localSeat]:playSpeakAction(1)
    else
        self._gamePlayerNodes[localSeat]:playSpeakAction(2)
    end
    
    self:onPlayerBet(app.game.GameData.getCurrseat())    
end

function GamePresenter:onGameOver(data, players)
    dump(players)
    local winseat = data.winnerSeat
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(winseat)    
    self:playChipBackAction({winseat})

    for seat = 0, self._maxPlayerCnt - 1 do
        if players[seat] then          
            app.game.PlayerData.updatePlayerRiches(seat, 0, players[seat].balance) 
            
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)            
            self._gamePlayerNodes[localSeat]:showWinloseScore(players[seat].score)
        	
            local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()            
            gameHandCardNode:resetHandCards()
            gameHandCardNode:createCards(players[seat].cards)
            
            self._gamePlayerNodes[localSeat]:showImgCardType(true, players[seat].type)            
            self._gamePlayerNodes[localSeat]:showTxtBalance(true, players[seat].balance)            
            self._gamePlayerNodes[localSeat]:showImgCheck(false) 
            self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)          
        end
	end
	
    self._gameBtnNode:showBetBtns(false)
    
    
    self:performWithDelayGlobal(
        function()
            self:sendPlayerReady()
        end, 10) 
end

--------------------------------------------
function GamePresenter:refreshUI()
    -- 单注
    local basebet = app.game.GameData.getBasebet() or 0
    self._ui:getInstance():showDanZhu(basebet)
    
    -- 轮数
    local round = app.game.GameData.getRound() or 0
    self._ui:getInstance():showLunShu(round)
    
    -- 总注 
    local jackpot = app.game.GameData.getJackpot() or 0
    self._ui:getInstance():showZongzhu(jackpot)
end

function GamePresenter:playBankerAction()
    local banker = app.game.GameData.getBanker()
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(banker) 
    if self._gamePlayerNodes[localSeat] then
        self._gamePlayerNodes[localSeat]:playBankAction()                     
    end
end

function GamePresenter:playChipAction()
    local basecoin = app.game.GameData.getBasecoin()
    for i = 0, self._maxPlayerCnt - 1 do
        local player = app.game.PlayerData.getPlayerByServerSeat(i)
        if player then
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i) 
            self._ui:getInstance():showChipAction(0, localSeat) 
        end            
    end
end

function GamePresenter:playChipBackAction(localseats)
    self._ui:getInstance():showChipBackAction(localseats)
end

function GamePresenter:playBiPaiPanel(flag)
    if flag then
        self._ui:getInstance():showBiPaiPanel(true)
        local heroseat = app.game.PlayerData.getHeroSeat()
        for i = 0, self._maxPlayerCnt - 1 do
            if heroseat ~= i then
                local player = app.game.PlayerData.getPlayerByServerSeat(i)
                if player and not player:isPlaying() then
                    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i)
                    self._gamePlayerNodes[localSeat]:setLocalZOrder(-1)
                end
                if player and player:isPlaying() then
                    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i)
                    self._gamePlayerNodes[localSeat]:playBlinkAction()
                end
            end           
        end
    else
        self._ui:getInstance():showBiPaiPanel(false)
        for i = 0, self._maxPlayerCnt - 1 do
            if self._gamePlayerNodes[i] then
                self._gamePlayerNodes[i]:setLocalZOrder(1)
                self._gamePlayerNodes[i]:stopBlinkAction()
            end            
        end
    end
end

function GamePresenter:playCompareAction(localSeat, otherSeat, loserSeat)
    local flag = otherSeat == loserSeat
    local fx, fy = self._gamePlayerNodes[localSeat]:getPosition()
    local fm, fn = self._gamePlayerNodes[otherSeat]:getPosition() 
    local tl, tlm, trm, tr = self._ui:getInstance():getToPosition()
    
    local posl,posr
    if localSeat == 2 or localSeat == 3 then
        posl = tlm
    else
        posl = tl    
    end
    if otherSeat == 0 or otherSeat == 1 or otherSeat == 4 then
        posr = trm
    else
        posr = tr	
    end
    self._ui:getInstance():showBiPaiEffect()
    self._gamePlayerNodes[localSeat]:playPanleAction(0, cc.p(fx, fy), posl, flag)  
    self._gamePlayerNodes[otherSeat]:playPanleAction(1, cc.p(fm, fn), posr, not flag)                 
end

function GamePresenter:showGaryCard(localSeat)
    local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
    if gameHandCardNode:getCardID() == CV_BACK then
        gameHandCardNode:resetHandCards()
        gameHandCardNode:createCards({888,888,888})  
    end
end

function GamePresenter:setCardScale(scale, localSeat)
    local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
    if gameHandCardNode and localSeat == 1 then
        gameHandCardNode:setCardScale(scale)
    end
end

-------------------------------schedule------------------------------
function GamePresenter:openSchedulerTakeFirst(callback)
    local cardbacks = {}             
    for i = 0, self._maxPlayerCnt - 1 do
        cardbacks[i] = cardbacks[i] or {}  
        for j=1, CARD_NUM do
            cardbacks[i][j] = CV_BACK
        end
    end
         
    local cardNum = 1
    local function onInterval(dt)
        if cardNum <= CARD_NUM then
            for i = 0, self._maxPlayerCnt - 1 do                
                if self._gamePlayerNodes[i] then
                    self._gamePlayerNodes[i]:onTakeFirst(cardbacks[i][cardNum])                     
                end
            end

            cardNum = cardNum + 1
        else
            self:closeSchedulerTakeFirst()
                
            if callback then
                callback()
            end
        end
    end

    self:closeSchedulerTakeFirst()
    
    self._schedulerTakeFirst = scheduler:scheduleScriptFunc(onInterval, 1/CARD_NUM, false)
end

function GamePresenter:closeSchedulerTakeFirst()
    if self._schedulerTakeFirst then
        scheduler:unscheduleScriptEntry(self._schedulerTakeFirst)
        self._schedulerTakeFirst = nil
    end
end

function GamePresenter:openSchedulerClock(localSeat, time)
    local allTime = time
    
    local function flipIt(dt)
        time = time - dt

        if time <= 0 then
            self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)
        end
        self._gamePlayerNodes[localSeat]:showClockProgress(time / allTime * 100)
    end

    self:closeSchedulerClock(localSeat)
    
    self._schedulerClocks[localSeat] = scheduler:scheduleScriptFunc(flipIt, 0.05, false)
end

function GamePresenter:closeSchedulerClock(localSeat)
    if self._schedulerClocks[localSeat] then
        scheduler:unscheduleScriptEntry(self._schedulerClocks[localSeat])
        self._schedulerClocks[localSeat] = nil
    end
end

function GamePresenter:closeSchedulerClocks()
    for i = 0, self._maxPlayerCnt - 1 do
        if self._schedulerClocks[i] then
            self:closeSchedulerClock(i)
        end
    end
end

-------------------------------ontouch-------------------------------
function GamePresenter:onTouchBtnQipai()
	self:sendQipai()
end

function GamePresenter:onTouchBtnBipai()
    self:playBiPaiPanel(true)
end

function GamePresenter:onTouchPanelBiPai(localseat)
    if not self._ui:getInstance():isBiPaiPanelVisible() then
    	return
    end
    self:playBiPaiPanel(false)
    local seat = app.game.PlayerData.localSeatToServerSeat(localseat)
    self:sendBipai(seat)
end

function GamePresenter:onTouchBtnKanpai()
    self:sendKanpai()
end

function GamePresenter:onTouchBtnGenzhu()
    self:sendBetmult(1) 
end

function GamePresenter:onTouchBtnBetmult(index)
    local mult = 1
    if index < 6 then
        mult = index*2        
    end    
    self:sendBetmult(mult) 
end

function GamePresenter:onEventCbxGendaodi(flag)
	if flag then
        local curseat = app.game.GameData.getCurrseat()
        local heroseat = app.game.PlayerData.getHeroSeat()
        if curseat == heroseat then
            self:sendBetmult(1) 
        end
	end	
end

-------------------------------request-------------------------------
function GamePresenter:sendLeaveRoom()
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()
        po:write_int32(sessionid)  
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_LEAVE_ROOM_REQ)
    end 
end

-- 弃牌
function GamePresenter:sendQipai()
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()
        po:write_int32(sessionid)  
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_GIVE_UP_REQ)
    end 
end

-- 比牌
function GamePresenter:sendBipai(seat)
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()
        po:write_byte(seat) 
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_COMPARE_CARD_REQ)
    end 
end

-- 看牌
function GamePresenter:sendKanpai()
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()
        po:write_int32(sessionid)  
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_SHOW_CARD_REQ)
    end 
end

-- 加注
function GamePresenter:sendBetmult(mult)
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()        
        po:write_int32(mult)
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_ANTE_UP_REQ)
    end 
end

function GamePresenter:sendPlayerReady()
	print("auto ready!!!!!")
	local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_int64(sessionid)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_READY_REQ)
end

-------------------------------rule-------------------------------
function GamePresenter:getCardColor(id)
    if id ~= nil then
        return  bit._rshift(bit._and(id, 0xf0), 4) 
    end   
end

function GamePresenter:getCardNum(id)
    if id ~= nil then
        return bit._and(id, 0x0f)
    end    
end

function GamePresenter:getMult(bet)   
    local base = app.game.GameConfig.getBase()    
    local mult = bet / base       
    print("bet is",bet,mult)
    if mult < 5 then
        mult = 0 
    elseif mult < 10 then
        mult = 1 
    elseif mult <15 then
        mult = 2
    elseif mult <20 then
        mult = 3
    else
        mult = 4
    end
end

return GamePresenter