
--Lua调试设置

--是否在开始时即进入调试模式
local DEBUG_SW   = false

--调试器的IP地址
local DEBUGER_IP = "192.168.43.176"


if DEBUG_SW == true then
	require('mobdebug').start(DEBUGER_IP)
end


------------------------------------------------------

function mogo_debug()
	require('mobdebug').start(DEBUGER_IP)
  
  --延时，以便调试器中断
  for i = 0, 100000 do end
  
  print("Debuger Started!")
end





















