/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：logger
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：通用日志模块
//----------------------------------------------------------------*/

#include "logger.h"

namespace mogo
{

CLogger g_logger;  //全局变量


CLogger::CLogger() : m_strFile(), m_strPath()
{
}


CLogger::~CLogger()
{

}

void CLogger::SetLogPath(const string& strPath)
{
    m_strPath.assign(strPath);
}


CLogger& CLogger::NewLine(int nFileType/* = 0*/)
{
    //using std::ios;

    time_t tNow = time(NULL);
    tm * pTm = localtime(&tNow);

    char szTemp[64];
    memset(szTemp, 0, sizeof(szTemp));

    string pszFormat;
    if(nFileType==1)
    {
        pszFormat = "%Y%m%d.err";  //error log
    }
    else
    {
        pszFormat = "%Y%m%d.log";  //general log
    }
    strftime(szTemp, sizeof(szTemp), pszFormat.c_str(), pTm);

    bool bOpen = false;
    if(!this->is_open())
    {
        bOpen = true;
    }
    else if(m_strFile != szTemp)
    {
        this->close();
        bOpen = true;
    }
    else
    {
        //bOpen = false;
    }

    if(bOpen)
    {
        m_strFile.assign(szTemp);

        if(m_strPath.empty())
        {
            this->open(szTemp, ios::out|ios::app);    
        }
        else
        {
            char szLogFile[256];
            memset(szLogFile, 0, sizeof(szLogFile));
            snprintf(szLogFile, sizeof(szLogFile), "%s%s", m_strPath.c_str(), szTemp);
            this->open(szLogFile, ios::out|ios::app);
        }
    }

    return *this;
}


ostream& EndLine(ostream& logger)
{
    logger << endl;
    logger.flush();

    return logger;
}


ostream& EndFile(ostream& logger)
{
    logger << endl;
    ((ofstream&)logger).close();

    return logger;
}


//获得当前时间的格式化的时分秒毫秒 HH:MM:SS.UUUUUU
void _get_time_hmsu_head(char* s, size_t n)
{
#ifdef _WIN32
    time_t t = time(NULL);
    struct tm* tm2 = localtime(&t);
    snprintf(s, n, "%02d:%02d:%02d.000000", tm2->tm_hour, tm2->tm_min, tm2->tm_sec);
#else
    struct timeval tv;
    gettimeofday(&tv, NULL);

    time_t& t = tv.tv_sec;
    struct tm* tm2 = localtime(&t);

    snprintf(s, n, "%02d:%02d:%02d.%06d", tm2->tm_hour, tm2->tm_min, tm2->tm_sec, tv.tv_usec);
#endif

}

void Log(const char* section, const char* key, const char* msg, va_list& ap)
{
    static const char _hmsu_head[] = "17:04:10.762177";
    enum {_hmsu_head_size = sizeof(_hmsu_head)+1,};

    char szHmsu[32];
    _get_time_hmsu_head(szHmsu, sizeof(szHmsu));

    char szTmp[MAX_LOG_BUFF_SIZE];
    int n1 = snprintf(szTmp, sizeof(szTmp), "%s  [%s][%s]", szHmsu, section, key);
    if(n1 > 0 && n1 < (int)sizeof(szTmp))
    {
        int n2 = vsnprintf(szTmp+n1, sizeof(szTmp)-n1, msg, ap);
        if(n2 > 0 && (n1+n2)<(int)sizeof(szTmp))
        {
            szTmp[n1+n2] = '\0';
        }

    }

    //设置了文件路径才打印到日志文件,否则只打印到stdout/stderr
    if(g_logger.IsSetPath())
    {
        g_logger.NewLine() << szTmp << EndLine;
        //printf("%s\n", szTmp);
    }
    else
    {
        printf("%s\n", szTmp);
    }
}

void LogDebug(const char* key, const char* msg, ...)
{
    va_list ap;
    va_start(ap, msg);
    Log("DEBUG   ", key, msg, ap);
    va_end(ap);
}

void LogInfo(const char* key, const char* msg, ...)
{
    va_list ap;
    va_start(ap, msg);
    Log("INFO    ", key, msg, ap);
    va_end(ap);
}

void LogWarning(const char* key, const char* msg, ...)
{
    va_list ap;
    va_start(ap, msg);
    Log("WARNING ", key, msg, ap);
    va_end(ap);
}

void LogError(const char* key, const char* msg, ...)
{
    va_list ap;
    va_start(ap, msg);
    Log("ERROR   ", key, msg, ap);
    va_end(ap);
}

void LogCritical(const char* key, const char* msg, ...)
{
    va_list ap;
    va_start(ap, msg);
    Log("CRITICAL", key, msg, ap);
    va_end(ap);
}

void logScript(const char* level, const char* msg, ...)
{
    va_list ap;
    va_start(ap, msg);
    Log("SCRIPT  ", level, msg, ap);
    va_end(ap);
}


};
