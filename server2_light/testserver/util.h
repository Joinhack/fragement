#ifndef __UTIL__HEAD__
#define __UTIL__HEAD__

#ifdef _WIN32
	#pragma warning (disable:4786)
	#pragma warning (disable:4503)
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
#else
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
//	using std::unordered_map;
//	using std::unordered_multimap;
//#endif
//#ifdef _AIX_XLC
//	//在makefile里面定义这个宏
//	//#define __IBMCPP_TR1__
//	using std::tr1::unordered_map;
//	using std::tr1::unordered_multimap;
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

#define	FORMATPATHNAME(x) { x = formatPathName(x);}


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
//	typename unordered_multimap<T1, T2>::iterator iter = c1.begin();
//	for(; iter!=c1.end(); ++iter)
//	{
//		delete iter->second;
//		iter->second = NULL;
//	}
//	c1.clear();
//}


extern const char g_cPathSplit[2];	//路径分隔符

extern void GetCurTime(string& strCurTime);
extern string GetNextTime(const string& strLastTime);
extern void GetYesterday(string& strYesterday);
extern bool DayDiff(const string& strDayTime, int nClock);
extern void GetDateTime(char* pszDT, size_t nLen);


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

private:
	struct timeval* m_v;

};


};

#endif

