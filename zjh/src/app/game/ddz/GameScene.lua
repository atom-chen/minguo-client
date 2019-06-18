--[[
@brief  游戏主场景UI基类
]]
local GameScene   = class("GameScene", app.base.BaseScene)

-- csb路径
GameScene.csbPath = "game/qznn/csb/gamescene.csb"

local GE   = app.game.GameEnum

GameScene.touchs = {
    "btn_exit", 
}

GameScene.clicks = {
    "btn_menu",   
}

GameScene.events = {
    
}

function GameScene:onTouch(sender, eventType)
    GameScene.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then        
        if name == "btn_exit" then
            self._presenter:sendLeaveRoom()                             
        end
    end
end

function GameScene:exit()
    GameScene.super.exit(self)

    GameScene._instance = nil
end

function GameScene:initData()    
    math.randomseed(tostring(os.time()):reverse():sub(1, 7))
end 

function GameScene:initUI()
    self:showBase()  
end

function GameScene:showBase()
    local base = app.game.GameConfig.getBase()
    local fntbase = self:seekChildByName("txt_base_score")
    fntbase:setString("底分 " .. base)
end

function GameScene:showPnlHint(type)
    local nodeHint1 = self:seekChildByName("node_hint_1")
    local nodeHint2 = self:seekChildByName("node_hint_2")
    local nodeHint3 = self:seekChildByName("node_hint_3")
    if nodeHint1 then
        -- 开始倒计时
        if type == 1 then            
            nodeHint2:setVisible(false)
            nodeHint3:setVisible(false)
            self._presenter:closeSchedulerRunLoading()
            self._presenter:openSchedulerPrepareClock(3)   
            nodeHint1:setVisible(true)         
        -- 等待
        elseif type == 2 then
            nodeHint1:setVisible(false)            
            nodeHint3:setVisible(false)      
            self._presenter:closeSchedulerPrepareClock()     
            self._presenter:openSchedulerRunLoading("请耐心等待其他玩家") 
            nodeHint2:setVisible(true)           
        -- 换桌成功   
        elseif type == 3 then
            nodeHint1:setVisible(false)
            nodeHint2:setVisible(false)            
            local txt = nodeHint3:getChildByName("txt_wait")
            txt:setString("换桌成功!")
            nodeHint3:setVisible(true)
            self._presenter:closeSchedulerRunLoading()
            self._presenter:closeSchedulerPrepareClock()
        elseif type == 4 then
            nodeHint1:setVisible(false)            
            nodeHint3:setVisible(false)
            self._presenter:closeSchedulerPrepareClock()   
            self._presenter:openSchedulerRunLoading("您正在旁观，请等待下一局开始")  
            nodeHint2:setVisible(true) 
        elseif type == 5 then       
            nodeHint2:setVisible(false)
            self._presenter:closeSchedulerRunLoading()  
            nodeHint3:setVisible(false)         
        else
            nodeHint1:setVisible(false)
            nodeHint2:setVisible(false)
            nodeHint3:setVisible(false)
            self._presenter:closeSchedulerRunLoading()
            self._presenter:closeSchedulerPrepareClock()
        end
    end       
end

function GameScene:setTxtwait(txt)
    local txtNode = self:seekChildByName("txt_wait")
    if txtNode then
        txtNode:setString(txt)
    end    
end

function GameScene:showClockPrepare(time)
    local fntClock = self:seekChildByName("fnt_hint_clock")
    if fntClock then
        fntClock:setString(time)
    end    
end

-- 游戏开始
function GameScene:showStartEffect()
    local node = self:seekChildByName("node_start_effect")
    node:removeAllChildren()
    node:stopAllActions()
    
    local effect = app.util.UIUtils.runEffectOne("game/qznn/effect","jiubei_dh", 0, 85)
    node:addChild(effect)
end

-- 胜利
function GameScene:showWinEffect()
    local node = self:seekChildByName("node_win")
    node:removeAllChildren()
    node:stopAllActions()

    local effect = app.util.UIUtils.runEffectOne("game/qznn/effect","nnshengli_dh", 0, 0)
    node:addChild(effect)

    self._presenter:playEffectByName("win")
end

-- 失败
function GameScene:showLoseEffect()
    local node = self:seekChildByName("node_lose")
    node:removeAllChildren()
    node:stopAllActions()

    local effect = app.util.UIUtils.runEffectOne("game/qznn/effect","nnsbai_dh", 0, 0)
    node:addChild(effect)

    self._presenter:playEffectByName("lose")
end

return GameScene