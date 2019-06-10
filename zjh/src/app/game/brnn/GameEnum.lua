--[[
@brief  游戏枚举
]]

local GameEnum = {}

GameEnum.HERO_LOCAL_SEAT           = 1

GameEnum.CARDBACK                  = 0
GameEnum.CARDGRAY                  = 888

GameEnum.HISTORY_NUM               = 20
GameEnum.MAX_NUM                   = 48

-- 牌型信息
GameEnum.cardsType = {
   
}

GameEnum.hintType = {
    LHD_WAIT       = 1,   -- 等待
    LHD_LESS       = 2,   -- 低于5000   
    LHD_BOTH       = 3,   -- 均展示
}

GameEnum.soundType = {
    bet            = "bet.mp3",
    countdown      = "countdown.mp3",
    winall         = "banker_win_all.mp3",
    fly            = "se_chips.mp3",    
    game           = "bgm_game.mp3",    
    w_niu_0        = "niu_0_w.mp3",
    w_niu_1        = "niu_1_w.mp3",
    w_niu_2        = "niu_2_w.mp3",
    w_niu_3        = "niu_3_w.mp3",
    w_niu_4        = "niu_4_w.mp3",
    w_niu_5        = "niu_5_w.mp3",
    w_niu_6        = "niu_6_w.mp3",
    w_niu_7        = "niu_7_w.mp3",
    w_niu_8        = "niu_8_w.mp3",
    w_niu_9        = "niu_9_w.mp3",
    w_niu_10       = "niu_10_w.mp3",
    w_niu_11       = "niu_sizha_w.mp3",
    w_niu_12       = "niu_wuhua_w.mp3",
    w_niu_13       = "niu_5_s_w.mp3",
    start          = "start.mp3",
    stop           = "stop.mp3",
    win            = "niu_win.mp3",
    lose           = "niu_lose.mp3"               
}

return GameEnum