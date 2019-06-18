
--[[
    @brief  游戏出牌UI基类
    @by     斯雪峰
]]--
local GameCardNode = require("app.game.card.shuangkou.base.node.GameCardNode")

local GameOutCardNode    = class("GameOutCardNode", app.base.BaseNodeEx)

-- local HAND_CARD_TYPE         = 0
-- local HAND_CARD_TYPE_NO_SELF = 1
local OUT_CARD_TYPE     = 2
local BANKER_CARD_TYPE  = 3

local OUT_CARD_SCALE        = 0.7
local OUT_CARD_SCALE_SMALL  = 0.6
local BANKER_CARD_SCALE     = 0.8

function GameOutCardNode:initData(localSeat)
    self._localSeat         = localSeat

    self._gameCards         = {}
    self._outCardCount      = 0
end

function GameOutCardNode:createCards(cards)
    for i = 1, #cards do
        if cards[i] ~= app.game.CardRule.cards.CV_BACK then
            self._outCardCount = self._outCardCount + 1
        end
    end

    for i = 1, #cards do
        if cards[i] ~= app.game.CardRule.cards.CV_BACK then
            if #cards <= 10 then
                self:createCard(cards[i], OUT_CARD_SCALE, OUT_CARD_TYPE)
            else
                self:createCard(cards[i], OUT_CARD_SCALE_SMALL, OUT_CARD_TYPE)
            end
        end
    end
end

function GameOutCardNode:createBankerCard(card, count, callBack)
    if card == app.game.CardRule.cards.CV_BACK then
        return
    end

    self._outCardCount = count

    for i = 1, count do
        self:createCard(card, BANKER_CARD_SCALE, BANKER_CARD_TYPE)
    end

    local function fun()
        self:resetOutCards()
    end

    local action
    if callBack then
        action = cc.Sequence:create(
            cc.DelayTime:create(3),
            cc.CallFunc:create(callBack),
            cc.CallFunc:create(fun)
        )
    else
        action = cc.Sequence:create(
            cc.DelayTime:create(3),
            cc.CallFunc:create(fun)
        )
    end

    self._gameCards[1]:getRootNode():runAction(action)
end

function GameOutCardNode:resetOutCards()
    self._outCardCount = 0

    for i = 1, #self._gameCards do
        if self._gameCards[i]:isVisible() then
            self._gameCards[i]:resetCard()
        end
    end
end

function GameOutCardNode:createCard(id, scale, type)
    if id == nil then
        return
    end

    if id == app.game.CardRule.cards.CV_BACK then
        return
    end

    local index = 1
    for i = 1, #self._gameCards do
        if self._gameCards[i]:isVisible() then
            index = index + 1
        else
            break
        end
    end

    if self._gameCards[index] then
        self._gameCards[index]:resetCard()
    else
        local gameCard = GameCardNode:create(self._presenter, self._localSeat, type)
        table.insert(self._gameCards, gameCard)

        self._rootNode:addChild(gameCard:getRootNode())
    end
    
    self._gameCards[index]:setCardID(id)
    self._gameCards[index]:setCardScale(scale)
    self._gameCards[index]:setCardIndex(index)

    self._gameCards[index]:setVisible(true)
end

function GameOutCardNode:getOutCardCount()
    return self._outCardCount
end

function GameOutCardNode:movePartner()
    self._rootNode:setPositionX(self._rootNode:getPositionX() + 200)
end

return GameOutCardNode