
cc.FileUtils:getInstance():setPopupNotify(false)

-- default
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

-- cclog
local cclog = function(...)
    print(string.format(...))
end

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
   
    return msg
end

print = release_print

local function main()
    collectgarbage("collect")
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
    
    require "config"
    require "cocos.init"

    if CC_HOTPATCH then
        -- 大厅搜索路径
        cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_lobby/src/", true)
        cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_lobby/res/", true)
        
        require("startup"):start()    
    else
        local start = require "app.start"
        start.init()
        start.start()
    end    
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
