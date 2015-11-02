#ifndef __UTIL__HEAD__
#define __UTIL__HEAD__

#ifdef _WIN32
	#pragma warning (disable:4786)
	#pragma warning (disable:4503)
	#pragma warning (disable:4819)	
	#pragma warning (disable:4996)
#endif

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <ctype.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include <list>
#include "exception.h"

#ifdef _WIN32
	#define snprintf _snprintf
	#define vsnprintf _vsnprintf
	#define strcasecmp(a,b) strcmp(a,b)
#else
	#include <stdint.h>
	#include <fcntl.h>
	#include <unistd.h>
	#include <dirent.h>
	#include <sys/time.h>
#endif

using std::cout;
using std::endl;
using std::string;
using std::vector;
using std::map;
using std::ios;
using std::list;

//#ifdef _WIN32
//  using std::unordered_map;
//  using std::unordered_multimap;
//#endif
//#ifdef _AIX_XLC
//  //在makefile里面定义这个宏
//  //#define __IBMCPP_TR1__
//  using std::tr1::unordered_map;
//  using std::tr1::unordered_multimap;
//#endif

namespace mogo
{


    extern string& Ltrim(string& s);
    extern string& Rtrim(string& s);

    inline string& Trim(string& s)
    {
        return Rtrim(Ltrim(s));
    }

    //删除字符串左边的空格
    extern char* Ltrim(char* p);

    //删除字符串右边的空格
    extern char* Rtrim(char* p);

    //删除字符串两边的空格
    inline char* Trim(char* s)
    {
        return Rtrim(Ltrim(s));
    }

    //比较一个字符串的大写是否匹配一个大写的字符串
    extern bool UpperStrCmp(const char* src, const char* desc);

    //按照分隔符nDelim拆分字符串
    extern list<string> SplitString(const string& s1, int nDelim);
    extern void SplitString(const string& s1, int nDelim, list<string>& ls);
    extern void SplitStringToVector(const string& s1, int nDelim, vector<string>& ls);
    extern void SplitStringToMap(const string& s1, int nDelim1, char nDelim2, map<string, string>& dict);

    //替换string中第一次出现的某个部分
    extern string& xReplace(string& s1, const char* pszSrc, const char* pszRep);

    //判断一个字符串是否全部由数字字符组成
    extern bool IsDigitStr(const char* pszStr);

    //测试文件strFileName是否存在
    extern bool IsFileExist(const char* pszFileName);
    extern bool IsFileExist(const string& strFileName);

    //检查一个目录是否存在，如果不存在则创建
    extern void CheckDir(const char* pszDirName, bool bLog = false);

    //判断一个配置文件读取的路径名最后是否带路径分隔符，如果没有则加上
    extern string FormatPathName(const string& strPath);

#define FORMATPATHNAME(x) { x = formatPathName(x);}


    //用于清理一个指针容器
    template <typename TP,
             template <typename ELEM,
             typename ALLOC = std::allocator<ELEM>
             > class TC
             >
    void ClearContainer(TC<TP, std::allocator<TP> >& c1)
    {
        while(!c1.empty())
        {
            typename TC<TP>::iterator iter = c1.begin();
            delete *iter;
            *iter = NULL;
            c1.erase(iter);
        }
    }

    //用于清理一个map,第二个类型为指针
    template<typename T1, typename T2,
             template <class _Kty,
             class _Ty,
             class _Pr = std::less<_Kty>,
             class _Alloc = std::allocator<std::pair<const _Kty, _Ty> >
             > class M
             >
    void ClearMap(M<T1, T2, std::less<T1>, std::allocator<std::pair<const T1, T2> > >& c1)
    {
        typename M<T1, T2>::iterator iter = c1.begin();
        for(; iter!=c1.end(); ++iter)
        {
            delete iter->second;
            iter->second = NULL;
        }
        c1.clear();
    }

    //template<typename T1, typename T2>
    //void clearMap(unordered_multimap<T1, T2>& c1)
    //{
    //  typename unordered_multimap<T1, T2>::iterator iter = c1.begin();
    //  for(; iter!=c1.end(); ++iter)
    //  {
    //      delete iter->second;
    //      iter->second = NULL;
    //  }
    //  c1.clear();
    //}


    extern const char g_cPathSplit[2];  //路径分隔符

    //传入指定的速度、时间段、移动距离，校验玩家移动是否被允许
#ifndef _WIN32
    bool CheckSpeed(uint16_t speed, uint32_t timeDiff, float dis);
#endif

    extern void GetCurTime(string& strCurTime);
    extern string GetNextTime(const string& strLastTime);
    extern void GetYesterday(string& strYesterday);
    extern bool DayDiff(const string& strDayTime, int nClock);
    extern void GetDateTime(char* pszDT, size_t nLen);
#ifndef _WIN32
    extern uint32_t _GetTickCount();
    extern uint64_t _GetTickCount64();
#else	
	inline long _GetTickCount64()
	{
		return 0;
	}
#endif

    //linux下用gettimeofday来计算时间
    class CGetTimeOfDay
    {
        public:
            CGetTimeOfDay();
            ~CGetTimeOfDay();

        private:
            void GetTime(struct timeval* tv);

        public:
            //获取当前时间和上次的流逝时间
            int GetLapsedTime();
            void SetNowTime();

        private:
            struct timeval* m_v;

    };

#ifdef _WIN32
    class MyLock
    {
        //CRITICAL_SECTION m_Lock ;
    public :
        MyLock( ){ /*InitializeCriticalSection(&m_Lock);*/ } ;
        ~MyLock( ){ /*DeleteCriticalSection(&m_Lock);*/ } ;
        void Lock( ){ /*EnterCriticalSection(&m_Lock);*/ } ;
        void Unlock( ){ /*LeaveCriticalSection(&m_Lock);*/ } ;
    };
#else
    class MyLock
    {
        pthread_mutex_t m_Mutex; 
    public :
        MyLock( ){ pthread_mutex_init( &m_Mutex , NULL );} ;
        ~MyLock( ){ pthread_mutex_destroy( &m_Mutex) ; } ;
        void Lock( ){ pthread_mutex_lock(&m_Mutex); } ;
        void Unlock( ){ pthread_mutex_unlock(&m_Mutex); } ;
    };
#endif

};

#endif
