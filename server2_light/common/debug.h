/* 
 * File:   Debug.h
 * Author: Arcol
 *
 * Created on 2013年8月9日, 上午11:07
 */

#ifndef DEBUG_H
#define	DEBUG_H


#include "global_config.h"
#include <stdlib.h>
#ifndef _WIN32
	#include <unistd.h>
#endif
#include <sstream>
#include <string>
#include <signal.h>


#ifndef MG_MAKE_STR
#	define MG_MAKE_STR_I(x)	#x
#	define MG_MAKE_STR(x)		MG_MAKE_STR_I(x)
#endif	/* MG_MAKE_STR */

//注意:若使用"编辑并继续"编译,此MG_LINE_STR将无效,字符串变为类似于"(__LINE__Var+4)",此为VC2003版本的已知BUG,参见微软文档:KB199057
#ifndef MG_LINE_STR
#	define MG_LINE_STR		MG_MAKE_STR(__LINE__)
#endif	/* MG_LINE_STR */

#define MG_DEBUG_ERROR_MSG	"\n" << "\nProcessID = " << getpid() << "\nCompile:[" __TIMESTAMP__ "]\nFile:<" MG_LINE_STR ">[" __FILE__ "]\nFunction:[" << __PRETTY_FUNCTION__ << "]\nWarning:Program Freeze! Waiting for signal...\n"

/*
//绝对断言，不兼容低版本的g++
#define MG_CONFIRM(expr, ...)	\
((void)((expr) || ([](std::ostream& os){\
			static bool once_flag = false;\
			if (once_flag) return;\
			mogo::CDebug::DebugBreakMsgHandle(std::string(std::istreambuf_iterator<char>(os.rdbuf()), std::istreambuf_iterator<char>()) + mogo::CDebug::BreakMsg(__VA_ARGS__));\
			system(mogo::CDebug::GetDumpCmd()); pause();\
			once_flag = mogo::CDebug::IsSignalOnce();\
		}(std::stringstream() << MG_DEBUG_ERROR_MSG), 0)))
*/

/*
//绝对断言（使用仿函数对象代替，效率差一点，但可兼容g++ v4.5以下较低的版本）
#define MG_CONFIRM(expr, ...)	{struct{void operator()(std::ostream& os){static bool once_flag=false;if (once_flag) return;\
	mogo::CDebug::DebugBreakMsgHandle(std::string(std::istreambuf_iterator<char>(os.rdbuf()),std::istreambuf_iterator<char>())+mogo::CDebug::BreakMsg(__VA_ARGS__));\
	pause();once_flag=mogo::CDebug::IsSignalOnce();mogo::CDebug::UnBlock();};}op;((expr)||(op(std::stringstream()<<MG_DEBUG_ERROR_MSG),0));}
*/


//绝对断言（使用仿函数对象代替，效率差一点，但可兼容g++ v4.5以下较低的版本）
#define MG_CONFIRM(expr, ...)	{struct{void operator()(const std::string& str){static bool once_flag=false;if (!once_flag){mogo::CDebug::DebugBreakMsgHandle(str);\
	pause();once_flag=mogo::CDebug::IsSignalOnce();mogo::CDebug::UnBlock();}};}op;((expr)||(op(mogo::CDebug::BreakMsg(std::stringstream()<<MG_DEBUG_ERROR_MSG, ##__VA_ARGS__)),0));}

//标准断言，提供ASSERT和VERIFY两种标准机制
#if MOGO_DEBUG
#	define MG_ASSERT(expr, ...) MG_CONFIRM(expr, __VA_ARGS__)
#	define MG_VERIFY(expr, ...) MG_CONFIRM(expr, __VA_ARGS__)
#else
#	define MG_ASSERT(...)
#	define MG_VERIFY(expr, ...) ((void)(expr))
#endif


MOGO_BEGIN


class CDebug
{
private:
	static bool s_bSignalOnce;
	static bool s_bAutoDump;

public:
	static void Init(bool bAutoDump = true);
	static bool	IsSignalOnce();
	static std::string BreakMsg();
	static std::string BreakMsg(const char* fmt, ...);

	static const std::string BreakMsg(std::ostream& os);
	static const std::string BreakMsg(std::ostream& os, const char* fmt, ...);

	static void DebugBreakMsgHandle(const std::string& strMsg);
	static void UnBlock();

private:
	static void SignalHandle(int nSignal);
};
	
	
MOGO_END


#endif	/* DEBUG_H */






