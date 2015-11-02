#ifndef __CGI_CFG_HEAD__
#define __CGI_CFG_HEAD__

#include "my_stl.h"
#include "cfg_reader.h"


//cgi�����ļ���ȡ��
class CCgiCfg
{
public:
	CCgiCfg(const string& fn);
	~CCgiCfg();

public:
	void init();
    string GetValue(const char* szSection, const char* szName);

private:
    bool m_bInit;   //�Ƿ��ʼ���ɹ�
    mogo::CCfgReader m_cfg;


};

extern CCgiCfg* g_cgi_cfg;


#endif
