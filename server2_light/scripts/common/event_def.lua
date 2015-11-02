local cfg ={
			--日常
			cur_num = 1, 		--当前进度
			is_finish = 2,  	--是否完成
			is_reward = 3,       --是否领奖
			gold = 4, 			--奖励金钱
			exp = 5, 			--奖励经验

		    --成就
		    --cur_num = 1, 		--当前进度  已经在上面定义
		    aid = 2,  --成就id
		   	level = 3, --成就当前等级
		    reward_level = 4, --领奖领到的等级


		    --活动(event_ing)字段定义
			id = 1, --任务id
			--is_finish = 2, --是否完成   、、已经在上面定义
			--is_reward= 3,--已经定义      、已经在上面定义
			accept_time=4 ,--接取时间
			task_end_time =5, --结束时间
			close_time =6,   --截止时间
			event_cur_num = 7, 		--当前进度  

			-- 已接任务 字段定义
			--id = 1, 	--任务id  --已经在上面定义
			count=2, 	--任务计数
			--accept_time =4   --已经在上面定义




			switch_off= 0, --开关关
			switch_on = 1, --开关开

			--"上线活动结束时:
			reward_type_yes = 1, 	--1:邮件补发 
			reward_type_no = 2,		--2:邮件不会补发
			

			not_in_task  = 0,-- 还没有接任务
			in_task = 1,-- 已经接了任务

			task_not_finish = 0, --任务未完成
			task_finish = 1, --任务完成

			not_reward  = 0,-- 没有领奖
			has_reward  = 1,-- 有领奖

			eventHeartBeatDelay = 10, --延迟这么多再加心跳
			eventHeartBeat = 1 ,--活动检测心跳为1秒一次
			TIMER_ID_EVENT = 111, --活动检测心跳ID


			no_update = 0,		--永远都不刷新
			daily_update = 1, 	--一日一次（凌晨12点刷新）
			week_update = 2, 	--一周一次（新周点刷新）
			year_update = 3, 	-- 一年一次（新年刷新）
			month_update = 4, 	-- 一月一次（新月刷新）



			--以下为活动类型定义
			forever_event	= 1,
			day_event		= 2,
			week_event		= 3,
			month_event		= 4,
			forever_event_in_time		= 5,	 --永久限时活动
			festivalEvent 		= 6,
			festivalDayEvent	=7,
			festivalWeekEvent	=8,
			serverEvent         =9,
			serverDayEvent		=10,
			serverWeekEvent		=11,


			condition_config = 1,  --任务接取条件读取id
			task_condition_config = 2,	--任务完成条件读取id	
			achievement_condition_config = 3,	--achievement读取id 
			day_task_config = 4,	--日常任务读取id 


			max_achievmt_level = -1, --成就已经达到最大等级


			error_code_successful = 0, 
			error_code_event_ing = 1, --正在做该任务
			error_code_event_not_in_time = 2, --还没到接任务的时间
			error_code_event_beyond_count = 3, --你已经做过该任务(超过次数)
			error_code_event_closed = 4, --活动已关闭
			error_code_event_done = 5, --已经做过该任务
			error_code_event_no_begin = 6, --没有做该任务
			error_code_event_not_finish = 7, -- 还没有完成该任务
			error_code_event_rewarded = 8, --已经领过奖了
			error_code_event_less_recharge = 9, --充值金额未达到奖励要求
			error_code_event_not_login = 10, --该天未登陆
			error_code_event_config_not_found = 11, --未找到对应的config
			error_code_event_max_level = 12, --达到最高等级
			error_code_event_cur_cant = 13, --当前等级不能领取
			error_code_event_cant_get_task = 14, --没有达到接取任务条件
			error_code_event_unknow = 15, --未知错误
			error_code_giftbag_already_received =16,--该角色已经领取过该礼包
			error_code_giftbag_mutex 			=17,--已经领取过互斥的包
			error_code_giftbag_cant_found 		=18,--找不到该礼包的配置 请检查


}



event_def = cfg
return event_def

