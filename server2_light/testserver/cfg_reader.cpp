/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：cfg_reader
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：读配置类
//----------------------------------------------------------------*/
#include "cfg_reader.h"
#include "util.h"
#include "logger.h"
namespace mogo
{

CCfgReader::CCfgReader(const string& strFile)
            :m_strFile(strFile), m_bScan(false)
{
}

CCfgReader::~CCfgReader()
{
    map<string, map<string, string>*>::iterator iter = m_CfgDict.begin();
    for(; iter != m_CfgDict.end(); ++iter)
    {
        delete iter->second;
        iter->second = NULL;
    }
}

string CCfgReader::GetValue(const char* szSection, const char* szName)
{
    if(!m_bScan)
    {
        ScanCfgFile();
    }

    map<string, map<string, string>*>::const_iterator iter = m_CfgDict.find(szSection);
    if(iter != m_CfgDict.end())
    {
        map<string, string>& tmp = *(iter->second);
        map<string, string>::const_iterator iter2 = tmp.find(szName);
        if(iter2 != tmp.end())
        {
            printf("get_value, section=[%s], %s=%s\n", szSection, szName, iter2->second.c_str());
            return iter2->second;
        }
    }

    ThrowException(-1, "Empty item value: [%s] %s!", szSection, szName);
    
    static string strEmpty("");
    return strEmpty;
}

string CCfgReader::GetOptValue(const char* szSection, const char* szName, 
                               const string& strDefault)
{
    try
    {
        return GetValue(szSection, szName);
    }
    catch (const CException& ex)
    {
        return strDefault;
    }
}


void CCfgReader::ScanCfgFile()
{
    ifstream file(m_strFile.c_str(), ios::in);
    if(!file.is_open())
    {
        ThrowException(-1,  "open config file failed: %s", m_strFile.c_str());
    }

    string strSection;
    while(!file.eof())
    {
        char szLine[128];
        file.getline(szLine, sizeof(szLine), 0x0A);
        //window文件格式换行是0x0D0A,UNIX/LINUX是0x0A

        string sLine = Trim(szLine);
        if(sLine.empty() || sLine[0] == '#')
        {
            continue;
        }

        if(sLine[0] == '[' && sLine[sLine.size() - 1] == ']')
        {
            strSection = sLine.substr(1, sLine.size()-2);
            continue;
        }

        string::size_type pos = sLine.find("=");
        if(pos==string::npos)
        {
            continue;
        }

        if(strSection.empty())
        {
            ThrowException(-1, "item '%s' has not section", sLine.c_str());
        }

        string strTemp = sLine.substr(0, pos);
        string s1 = Trim(strTemp);
        strTemp = sLine.substr(pos+1, sLine.size() - pos - 1);
        string s2 = Trim(strTemp);

        map<string, map<string, string>*>::iterator iter = m_CfgDict.lower_bound(strSection);
        if(iter != m_CfgDict.end() && strSection == iter->first)
        {
            iter->second->insert(make_pair(s1, s2));
            //LogDebug("insert one item:", "%s %s %s", strSection, s1, s2);
        }
        else
        {
            map<string, string>* tmp = new map<string, string>;
            tmp->insert(make_pair(s1, s2));
            m_CfgDict.insert(iter, make_pair(strSection, tmp) );
           
        }
    }
    m_bScan = true;
     
}

};
