#include "cgicfg.h"


using namespace mogo;

CCgiCfg* g_cgi_cfg = NULL;


CCgiCfg::CCgiCfg(const string& fn) : m_bInit(false), m_cfg(fn)
{

}
    
CCgiCfg::~CCgiCfg()
{

}

void CCgiCfg::init()
{
    try
    {
        //do nothing but for init
        m_cfg.GetValue("a", "b");
        m_bInit = true;
    }
    catch(const CException& ex)
    {
    }
}

string CCgiCfg::GetValue(const char* szSection, const char* szName)
{
    static const char szDefaultSection[] = "default";

    //先从输入参数指定的块里找,找不到再从缺省块里找
    try
    {
        string strValue = m_cfg.GetValue(szSection, szName);
        if(!strValue.empty())
        {
            return strValue;
        }
    }
    catch (const CException& ex1)
    {
        try
        {
            string strValue = m_cfg.GetValue(szDefaultSection, szName);
            if(!strValue.empty())
            {
                return strValue;
            }
        }
        catch (const CException& ex2)
        {
        }        	
    }

    static const string strEmpty = "";
    return strEmpty;    
}

