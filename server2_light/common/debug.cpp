/* 
 * File:   Debug.cpp
 * Author: Arcol
 * 
 * Created on 2013年8月9日, 上午11:07
 */

#include "debug.h"
#include "logger.h"
#include <stdarg.h>
#include <locale.h>
#include <iostream>


MOGO_USING


bool CDebug::s_bSignalOnce	= false;
bool CDebug::s_bAutoDump	= false;


void CDebug::Init(bool bAutoDump)
{
	setlocale(LC_ALL,"chs");
	if (signal(SIGUSR1, CDebug::SignalHandle) == SIG_ERR)
	{
		std::cerr << "Can't init signal[10]!" << std::endl;
		abort();
	}
	if (signal(SIGUSR2, CDebug::SignalHandle) == SIG_ERR)
	{
		std::cerr << "Can't init signal[12]!" << std::endl;
		abort();
	}
	s_bAutoDump = bAutoDump;
}

bool CDebug::IsSignalOnce()
{
	return s_bSignalOnce;
}

std::string CDebug::BreakMsg(const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    char* pBuffer;
    vasprintf(&pBuffer, fmt, args);
	va_end(args);
	std::string strMsg	= "Reason:" + std::string(pBuffer) + "\n";
	free(pBuffer);
	return strMsg;
}

std::string CDebug::BreakMsg()
{
	return "\n";
}

const std::string CDebug::BreakMsg(std::ostream& os)
{
	return std::string(std::istreambuf_iterator<char>(os.rdbuf()), std::istreambuf_iterator<char>());
}


const std::string CDebug::BreakMsg(std::ostream& os, const char* fmt, ...)
{
	if (fmt && fmt[0] != 0)
	{
		va_list args;
		va_start(args, fmt);
		char* pBuffer;
		vasprintf(&pBuffer, fmt, args);
		va_end(args);
		os << "Reason:" << pBuffer << endl;
		free(pBuffer);
	}
	return std::string(std::istreambuf_iterator<char>(os.rdbuf()), std::istreambuf_iterator<char>());
}


void CDebug::DebugBreakMsgHandle(const std::string& strMsg)
{
	sigset_t set;
	sigemptyset(&set);
	sigaddset(&set, SIGALRM);
	sigprocmask(SIG_BLOCK, &set, NULL);
	std::cerr << strMsg.c_str();
	LogCritical("Assert Error", strMsg.c_str());
	if (s_bAutoDump)
	{
		char pBuffer[256];
		sprintf(pBuffer, "gcore %d > /dev/null", getpid());
		system(pBuffer);
	}
}

void CDebug::SignalHandle(int nSignal)
{
	std::cerr << "Receive a signal[" << nSignal << "]..." << endl;
	s_bSignalOnce = (nSignal == SIGUSR2);
}

void CDebug::UnBlock()
{
	sigset_t set;
	sigemptyset(&set);
	sigaddset(&set, SIGALRM);
	sigprocmask(SIG_UNBLOCK, &set, NULL);
}














