#ifndef __CFG_READER__HEAD__
#define __CFG_READER__HEAD__

#ifdef _WIN32
    #pragma warning (disable:4786)
    #pragma warning (disable:4503)
#endif


#include "exception.h"
#include "my_stl.h"
#include "util.h"
 

namespace mogo
{
//自定义读配置类
class CCfgReader
{
public:
    CCfgReader(const string& strFile);
    ~CCfgReader();

    string GetValue(const char* szSection, const char* szName);
    string GetOptValue(const char* szSection, const char* szName, const string& strDefault);

private:
    void ScanCfgFile();

private:
    string m_strFile;
    map<string, map<string, string>*> m_CfgDict;
    bool m_bScan;

};

};

#endif
