--
-- Created by IntelliJ IDEA.
-- User: jh
-- Date: 13-12-5
-- Time: 下午5:16
-- To change this template use File | Settings | File Templates.
--

require "lua_util"


local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning

-------------------------------------------------------------------------------------------------------------------
local StopwordMgr = {}
StopwordMgr.__index = StopwordMgr
-------------------------------------------------------------------------------------------------------------------

--初始化配置数据
function StopwordMgr:initData()
    local addStopWord = mogo.addStopWord
    --1保留字符集
    addStopWord(1, " ~!@#$%^&*()_+-=[]{};'\\:\"|,./<>?")

    --2敏感词汇
    local fn = G_LUA_ROOTPATH .. "/data/notxml/stopword_sub.txt"
    local f = io.open(fn, 'r')
    local s = ''
    for s2 in f:lines() do
        --其实这里只会循环一次
        s = s .. s2
    end
    local words = lua_util.split_str(s, ',')
    for _, _word in ipairs(words) do
        addStopWord(2, _word)
    end

    --3正则表达式
    local fn3 = G_LUA_ROOTPATH .. "/data/notxml/stopword_re.txt"
    local f3 = io.open(fn3, 'r')
    for s3 in f3:lines() do
        addStopWord(3, s3)
    end
end

--判断是否屏蔽词
function StopwordMgr:isStopWord(word)
    return mogo.isStopWord(word)
end


-------------------------------------------------------------------------------------------------------------------
return StopwordMgr

