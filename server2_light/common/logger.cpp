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
#include "global_config.h"
#include "mutex.h"

namespace mogo
{

    CLogger g_logger;  //全局变量

#ifndef _WIN32
    pthread_mutex_t* g_logger_mutex = NULL;
#endif


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
            pszFormat = "%Y%m%d.err";           //错误日志
        }
        else
        {
            pszFormat = "%Y%m%d.log";           //一般日志
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
        if(gettimeofday(&tv, NULL)==0)
        {
            time_t& t = tv.tv_sec;
            struct tm* tm2 = localtime(&t);

            snprintf(s, n, "%02d:%02d:%02d.%06d", tm2->tm_hour, tm2->tm_min, tm2->tm_sec, tv.tv_usec);
        }
        else
        {
            snprintf(s, n, "??:??:??.??????");
        }
#endif

    }

/*
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
*/

    template <size_t size>
    void _Log(char (&strDest)[size], const char* section, const char* key, const char* msg, va_list& ap)
    {
        static const char _hmsu_head[] = "17:04:10.762177";
        enum {_hmsu_head_size = sizeof(_hmsu_head)+1,};

        char szHmsu[32];
        memset(szHmsu, 0, 32);

        _get_time_hmsu_head(szHmsu, sizeof(szHmsu));

        int n1 = snprintf(strDest, (int)size, "%s  [%s][%s]", szHmsu, section, key);
        if(n1 > 0 && n1 < (int)size)
        {
            int n2 = vsnprintf(strDest+n1, (int)size-n1, msg, ap);
            if(n2 > 0 && (n1+n2)<(int)size)
            {
                strDest[n1+n2] = '\0';
            }

        }
    }

    void Log2File(const char* section, const char* key, const char* msg, va_list& ap, int nFileType = 0)
    {
        char szTmp[MAX_LOG_BUFF_SIZE];
        memset(szTmp, 0, MAX_LOG_BUFF_SIZE * sizeof(char));

        _Log(szTmp, section, key, msg, ap);

        if(g_logger.IsSetPath())
        {
#ifdef _WIN32
            g_logger.NewLine(nFileType) << szTmp << EndLine;
#else
            if(g_logger_mutex == NULL)
            {
                g_logger.NewLine(nFileType) << szTmp << EndLine;
            }
            else
            {
                //dbmgr的多线程日志要加锁
                CMutexGuard gm(*g_logger_mutex);
                g_logger.NewLine(nFileType) << szTmp << EndLine;
            }
#endif

        }
        else
        {
            printf("%s\n", szTmp);
        }
    }

    void Log2Console(const char* section, const char* key, const char* msg, va_list& ap, int nFileType = 0)
    {
        char szTmp[MAX_LOG_BUFF_SIZE];
        _Log(szTmp, section, key, msg, ap);

#ifdef _DEBUG_VERSION_
        printf("%s\n", szTmp);
#else
        if(g_logger.IsSetPath())
        {
            g_logger.NewLine(nFileType) << szTmp << EndLine;
            printf("%s\n", szTmp);
        }
        else
        {
            printf("%s\n", szTmp);
        }
#endif
    }

    void LogDebug(const char* key, const char* msg, ...)
    {
        va_list ap;
        memset(&ap, 0, sizeof ap);

        va_start(ap, msg);
        Log2File("DEBUG   ", key, msg, ap);
        va_end(ap);
    }

    void LogInfo(const char* key, const char* msg, ...)
    {
        va_list ap;
        memset(&ap, 0, sizeof ap);

        va_start(ap, msg);
        Log2File("INFO    ", key, msg, ap);
        va_end(ap);
    }

    void LogWarning(const char* key, const char* msg, ...)
    {
        va_list ap;
        memset(&ap, 0, sizeof ap);

        va_start(ap, msg);
        Log2File("WARNING ", key, msg, ap);
        va_end(ap);
    }

    void LogError(const char* key, const char* msg, ...)
    {
        va_list ap;
        memset(&ap, 0, sizeof ap);

        va_start(ap, msg);
        Log2File("ERROR   ", key, msg, ap);
        va_end(ap);
    }

    void LogCritical(const char* key, const char* msg, ...)
    {
        va_list ap;
        memset(&ap, 0, sizeof ap);

        va_start(ap, msg);
        Log2File("CRITICAL", key, msg, ap);
        va_end(ap);
    }

    void LogScript(const char* level, const char* msg, ...)
    {
        va_list ap;
        memset(&ap, 0, sizeof ap);

        va_start(ap, msg);
        Log2File("SCRIPT  ", level, msg, ap);
        va_end(ap);
    }

    void LogConsole(const char* key, const char* msg, ...)
    {
        va_list ap;
        memset(&ap, 0, sizeof ap);

        va_start(ap, msg);
        Log2Console("CONSOLE ", key, msg, ap);
        va_end(ap);
    }

    void Error(const char* level, const char* msg, ...)
    {
        va_list ap;
        memset(&ap, 0, sizeof ap);

        va_start(ap, msg);
        Log2File("ERROR  ", level, msg, ap, 1);
        va_end(ap);
    }

};
