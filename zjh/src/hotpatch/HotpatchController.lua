local _M = {
    _VERSION = "1.0.0.1",
    _DESCRIPTION = "hotpacth controller",
    nextId = 1
}

local mt = {__index = _M}
local setmetatable, getmetatable = setmetatable, getmetatable
local tostring = tostring

local AM_STATE = {
    UNCHECKED            = 0,
    PREDOWNLOAD_VERSION  = 1,
    DOWNLOADING_VERSION  = 2,
    VERSION_LOADED       = 3,
    PREDOWNLOAD_MANIFEST = 4,
    DOWNLOADING_MANIFEST = 5,
    MANIFEST_LOADED      = 6,
    NEED_UPDATE          = 7,
    UPDATING             = 8,
    UNZIPPING            = 9,
    UP_TO_DATE           = 10,
    FAIL_TO_UPDATE       = 11
}

--
function _M.new(self, projectManifest, savePath)
    --
    local nextId = _M.nextId
    _M.nextId = _M.nextId + 1
    return setmetatable(
        {
            --
            id = nextId,
            assetsManager = nil,
            localVersion = nil,
            remoteVersion = nil,
            totalSize = 0,
            tips = "",
            abort = false, -- client corrupted, can't go on
            --
            projectManifest = projectManifest or "patch/lobby/project.manifest",
            savePath = savePath and cc.FileUtils:getInstance():getWritablePath() .. savePath or
                cc.FileUtils:getInstance():getWritablePath() .. "update",
            callback = nil    
        },
        mt
    )
end

--
function _M:init(callback)
    print("write path is",cc.FileUtils:getInstance():getWritablePath())
    
    self.assetsManager = cc.AssetsManagerEx:create(self.projectManifest, self.savePath)
    self.assetsManager:retain()

    self.localVersion = self.assetsManager:getLocalManifest():getVersion()
    self.remoteVersion = nil
    self.tips = "检查更新中..."
    self.callback = callback
end

--
function _M:release()
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    if self.updateListener then
        eventDispatcher:removeEventListener(self.updateListener)
        self.updateListener = nil
    end
    self.assetsManager:release()
    self.assetsManager = nil
end

--
function _M:doUpdate()
    if not self.assetsManager:getLocalManifest():isLoaded() then
        print("[AM]: fail to update assets, step skipped.")
        self.tips = "加载本地更新配置失败, 跳过版本更新流程"
        self.abort = false
    else
        local updateListener =
            cc.EventListenerAssetsManagerEx:create(
            self.assetsManager,
            function(event)
                self:onUpdateEvent(event)
            end
        )
        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:addEventListenerWithFixedPriority(updateListener, 1)
        self.updateListener = updateListener
        self.assetsManager:update()
    end
end

--
function _M:onUpdateEvent(event)
    local eventCode = event:getEventCode()
    print("wq-[AM]:", eventCode)

    if cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST == eventCode then
        -- code 0
        print("[AM]: no local manifest file found, skip assets update.", eventCode)
        self.tips = "未找到本地更新配置文件, 跳过版本更新流程"
    elseif cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST == eventCode then
        -- code 1
        print("[AM]: fail to download manifest file, update skipped.", eventCode)
        self.tips = "获取版本信息出错"
    elseif cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST == eventCode then
        -- code 2
        print("[AM]: fail to parse manifest file, update skipped.", eventCode)
        self.tips = "解析版本信息出错"
    elseif cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND == eventCode then
        -- code 3
        local needUpdate = self.assetsManager:getState() == AM_STATE.NEED_UPDATE
        if not needUpdate then
            print("[AM]: new version found.", eventCode)
            self.tips = "开始解析版本信息"
        else
            -- need update
            print("[AM]: new version found and need update.", eventCode)
            self.remoteVersion = self.assetsManager:getRemoteManifest():getVersion()
            self.tips = "发现新版本" .. self.remoteVersion
        end
    elseif cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE == eventCode then
        -- code 4
        self:release()
        self.tips = "已经是最新版本"
    elseif cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION == eventCode then
        -- code 5
        print("[AM]: update progression...", eventCode)
        local assetId = event:getAssetId()
        local percent = event:getPercent()
        local strInfo = ""

        if assetId == cc.AssetsManagerExStatic.VERSION_ID then
            strInfo = string.format("Version file: %d%%", percent)
        elseif assetId == cc.AssetsManagerExStatic.MANIFEST_ID then
            strInfo = string.format("Manifest file: %d%%", percent)
        else
            strInfo = string.format("%d%%", percent)
        end
        self.tips = "正在进行版本更新: " .. strInfo                      
    elseif cc.EventAssetsManagerEx.EventCode.ASSET_UPDATED == eventCode then
        -- code 6
        local assetId = event:getAssetId()
        print("[AM]: asset updated.", eventCode, assetId)
        self.tips = "资源文件" .. tostring(assetId) .. "更新完毕"
    elseif cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING == eventCode then
        -- code 7
        local assetId = event:getAssetId()
        print("[AM]: error updating.", tostring(assetId), eventCode)
        self.tips = "游戏维护中, 请留意官网开服公告"
        self.abort = true
    elseif cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED == eventCode then
        -- code 8
        print("[AM]: update finished.", eventCode)
        self:release()
        self.tips = "版本更新完毕"
    elseif cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED == eventCode then
        -- code 9
        print("[AM]: update failed.", eventCode)
        self.tips = "版本更新失败"
        self.abort = true
    elseif cc.EventAssetsManagerEx.EventCode.ERROR_DECOMPRESS == eventCode then
        -- code 10
        print("[AM]: error decompress.", eventCode)
        self.tips = "解压失败"
        self.abort = true
    end    
    print("tip is", self.tips)        
    local tInfo = {
        tips    = self.tips,
        abort   = self.abort,
        code    = eventCode,
        percent = event:getPercentByFile(),
        gameid  = self:findGameidByManifest()        
    }
    self:onUpdateCallBack(tInfo)
end

-- 与游戏gameid对应
function _M:findGameidByManifest()
    if string.find(self.projectManifest, "zjh") then
        return 1
    elseif string.find(self.projectManifest, "jdnn") then
        return 2
    elseif string.find(self.projectManifest, "qznn") then
        return 3
    end
    return -1
end

function _M:onUpdateCallBack(tInfo)
    self.callback(tInfo)
end

return _M