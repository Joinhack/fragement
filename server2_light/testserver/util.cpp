/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：util
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：常用函数集合
//----------------------------------------------------------------*/

#include <stdarg.h>
#ifndef _WIN32
    #include <sys/time.h>
#endif

#include "util.h"
using namespace std;


namespace mogo
{

string& Ltrim(string& s)
{
	int (*func)(int) = isspace;

	string::iterator iter;
	iter = find_if(s.begin(), s.end(), not1(ptr_fun(func)));
	s.erase(s.begin(), iter);

	return s;
}


string& Rtrim(string& s)
{
	int (*func)(int) = isspace;

	string::reverse_iterator iter;
	iter = find_if(s.rbegin(), s.rend(), not1(ptr_fun(func)));
	s.erase(iter.base(), s.end());

	return s;
}


bool IsDigitStr(const char* pszStr)
{
	if(pszStr == NULL)
	{
		return false;
	}

	size_t nLen = strlen(pszStr);
	for(size_t i = 0; i < nLen; ++i)
	{
		if(!isdigit(pszStr[i]))
		{
			return false;
		}
	}

	return true;
}


bool IsFileExist(const string& strFileName)
{
	return IsFileExist(strFileName.c_str());
}

bool IsFileExist(const char* pszFileName)
{
	bool bExist = false;

	ifstream iFile(pszFileName, ios::in);
	if(iFile.is_open())
	{
		bExist = true;
		iFile.close();
	}

	return bExist;
}


//替换string中第一次出现的某个部分
string& xReplace(string& s1, const char* pszSrc, const char* pszRep)
{
	string::size_type nPos1 = s1.find(pszSrc);
	if(nPos1 == string::npos)
	{
		return s1;
	}

	s1.replace(nPos1, strlen(pszSrc), pszRep);
	return s1;
}


//判断一个配置文件读取的路径名最后是否带路径分隔符，如果没有则加上
string FormatPathName(const string& strPath)
{
	if(strPath[strPath.size()-1]==g_cPathSplit[0])
	{
		return strPath;
	}

	string strPath1;
	strPath1.assign(strPath).append(g_cPathSplit);

	return strPath1;
}

//删除字符串右边的空格
char* Rtrim(char* p)
{
	if(p==NULL)
	{
		return p;
	}

    size_t n = strlen(p);
    if(n==0)
    {
        return p;
    }

	char* q = p + n - 1;

	while(isspace(*q))
	{
		--q;
	}

	*(q+1) = '\0';

	return p;
}

//删除字符串左边的空格
char* Ltrim(char* p)
{
	if(p==NULL)
	{
		return p;
	}

	char* q = p;

	while(isspace(*q))
	{
		++q;
	}

	if(p!=q)
	{
		while(*p++ = *q++){}
	}

	return p;
}

//比较一个字符创的大写是否匹配一个大写的字符串
//也可以用strcasecmp
bool UpperStrCmp(const char* src, const char* dest)
{
	if( strlen(src) != strlen(dest) )
	{
		return false;
	}
	if(src && dest)
	{
		for(;;)
		{
			char c1 = *src;
			char c2 = *dest;
			if( toupper(c1) == toupper(c2) )
			{
				++src;
				++dest;
			}
			else
			{
				return false;
			}
		}
		return true;
	}

	//src和dest任一个为NULL,都认为false
	return false;
}

//按照分隔符nDelim拆分字符串
list<string> SplitString(const string& s1, int nDelim)
{
	list<string> l;

	size_t nSize = s1.size()+1;
	char* pszTemp = new char[nSize];
	memset(pszTemp, 0, nSize);

	istringstream iss(s1);
	while(iss.getline(pszTemp, (std::streamsize)nSize, nDelim))
	{
		if(strlen(Rtrim(pszTemp))>0)
		{
			l.push_back(pszTemp);
		}
		memset(pszTemp, 0, nSize);
	}

	delete pszTemp;
	pszTemp = NULL;

	return l;
}


void SplitString(const string& s1, int nDelim, list<string>& ls)
{
	ls.clear();

	size_t nSize = s1.size()+1;
	char* pszTemp = new char[nSize];
	memset(pszTemp, 0, nSize);

	istringstream iss(s1);
	while(iss.getline(pszTemp, (std::streamsize)nSize, nDelim))
	{
		if(strlen(Rtrim(pszTemp))>0)
		{
			ls.push_back(pszTemp);
		}
		memset(pszTemp, 0, nSize);
	}

	delete pszTemp;
	pszTemp = NULL;

	return;
}

void CheckDir(const char* pszDirName, bool bLog /*= false*/)
{
	if(pszDirName==NULL || strlen(pszDirName)==0)
	{
		cout << "输入目录名称为空!"<< endl;
	}

#ifdef _WIN32
	if(_mkdir(pszDirName)==-1)
	{
		if(bLog)
		{
			cout << "检测到存在目录:" << pszDirName << endl;
		}
	}
	else
	{
		cout << "成功创建了目录:" << pszDirName << endl;
	}
#else


	DIR* pDir = opendir(pszDirName);
	if(pDir==NULL)
	{
		cout << "没有这个目录:" << pszDirName << endl;
		if(mkdir(pszDirName, 0777)==0)
		{
			if(bLog)
			{
				cout << "成功创建了目录:" << pszDirName << endl;
			}
		}
		else
		{
			ThrowException(-1, "创建目录失败");
		}
	}
	else
	{
		closedir(pDir);
		if(bLog)
		{
			cout << "检测到存在目录:" << pszDirName << endl;
		}
	}
#endif
}


#ifdef _WIN32
	const char g_cPathSplit[2] = "\\";		//路径分隔符
#else
	const char g_cPathSplit[2] = "/";		//路径分隔符
#endif


bool DayDiff(const string& strDayTime, int nClock)
{
	time_t t2;	
	{
		int nYear = atoi(strDayTime.substr(0,4).c_str());
		int nMonth = atoi(strDayTime.substr(4,2).c_str());
		int nDay = atoi(strDayTime.substr(6,2).c_str());

		tm dtm;
		dtm.tm_year = nYear-1900;
		dtm.tm_mon = nMonth-1;
		dtm.tm_mday = nDay;
		dtm.tm_hour = nClock;
		dtm.tm_isdst = 0;
		dtm.tm_min = 0;
		dtm.tm_sec = 0;
		dtm.tm_wday = 0;
		dtm.tm_yday = 0;

		t2 = mktime(&dtm);
	}

	time_t t1 = time(NULL);

	//int nDayDiff = (int)difftime(t1, t2);
	int nDayDiff = (int)(t1 - t2 - 60*60*24);

	return nDayDiff>=0;
}


string GetNextTime(const string& strLastTime)
{
	string strNextTime;

	if(strLastTime.size()!=8)
	{
		return strNextTime;
	}

	int nYear = atoi(strLastTime.substr(0,4).c_str());
	int nMonth = atoi(strLastTime.substr(4,2).c_str());
	int nDay = atoi(strLastTime.substr(6,2).c_str());

	tm dtm;
	dtm.tm_year = nYear-1900;
	dtm.tm_mon = nMonth-1;
	dtm.tm_mday = nDay;
	dtm.tm_hour = 0;
	dtm.tm_isdst = 0;
	dtm.tm_min = 0;
	dtm.tm_sec = 0;
	dtm.tm_wday = 0;
	dtm.tm_yday = 0;

	time_t t2 = mktime(&dtm);
	if(t2<0)
	{
		return strNextTime;
	}

	t2 += 24*60*60;
	tm* dtm2 = localtime(&t2);

	char szTemp[9];
	snprintf(szTemp, sizeof(szTemp), "%04d%02d%02d", dtm2->tm_year+1900, dtm2->tm_mon+1, dtm2->tm_mday);
	szTemp[8] = '\0';
	strNextTime.assign(szTemp);

	return strNextTime;
}


void GetCurTime(string& strCurTime)
{
	time_t t2 = time(NULL);
	if(t2<0)
	{
		strCurTime.clear();
		return;
	}

	tm* dtm2 = localtime(&t2);
	char szTemp[9];
	snprintf(szTemp, sizeof(szTemp), "%04d%02d%02d", dtm2->tm_year+1900, dtm2->tm_mon+1, dtm2->tm_mday);
	szTemp[8] = '\0';
	strCurTime.assign(szTemp);

	return;
}


void GetDateTime(char* pszDT, size_t nLen)
{
	time_t t2 = time(NULL);
	if(t2<0)
	{
		pszDT[0] = '\0';
		return;
	}

	tm* dtm2 = localtime(&t2);
	memset(pszDT, 0, nLen);
	snprintf(pszDT, nLen, "%04d%02d%02d%02d%02d%02d", 
		dtm2->tm_year+1900, dtm2->tm_mon+1, dtm2->tm_mday,
		dtm2->tm_hour, dtm2->tm_min, dtm2->tm_sec);
	
	return;
}


void GetYesterday(string& strYesterday)
{
	time_t t2 = time(NULL);
	if(t2<0)
	{
		strYesterday.clear();
		return;
	}

	enum{e_oneday = 24*60*60};
	t2 -= e_oneday;
	tm* dtm2 = localtime(&t2);
	char szTemp[9];
	snprintf(szTemp, sizeof(szTemp), "%04d%02d%02d", dtm2->tm_year+1900, dtm2->tm_mon+1, dtm2->tm_mday);
	szTemp[8] = '\0';
	strYesterday.assign(szTemp);

	return;
}

//linux下用gettimeofday来计算时间

CGetTimeOfDay::CGetTimeOfDay()
{
	m_v = new struct timeval;
	this->GetTime(m_v);
}

CGetTimeOfDay::~CGetTimeOfDay()
{
	delete m_v;
}

void CGetTimeOfDay::GetTime(struct timeval* tv)
{
#ifndef _WIN32
	gettimeofday(tv, NULL);
#endif
}

//获取当前时间和上次的流逝时间
int CGetTimeOfDay::GetLapsedTime()
{
	struct timeval* v2 = new struct timeval;
	this->GetTime(v2);
	enum{ e_micro_sec = 1000000, };
	int n = (int)((v2->tv_sec - m_v->tv_sec)*e_micro_sec + v2->tv_usec - m_v->tv_usec);
	m_v = v2;
	return n;
}



};
