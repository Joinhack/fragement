#ifndef __IF4399_HEAD__
#define __IF4399_HEAD__

#include "type_mogo.h"
#include "ifbase.h"
#include "api_data_center.h"
#include "api_plat.h"



//ƽ̨�ӿ�
class CIf4399 : public CIfBase
{
public:
	CIf4399();
	~CIf4399();

public:
	void login(const char* pszPathInfo, const char* pszReq);
	//��������api
	void data_center_api(const char* pszFunc, const char* pszParams);
	//ƽ̨api
	void plat_api(const char* pszFunc, const char* pszParams);
	//���������ķ����ķ������
	void add_gift(const char* remote_addr, const char* pszFunc, const char* pszParams);

	void charge(const char* remote_addr, const char* pszPathInfo, const char* pszReq);


protected:
    //�ض���ͻ���ҳ��
    void redirect(const char* pszUrl);
    //���ش�����
    void send_err_resp(int nRet);
    //�������ļ���ȡ�������ֵ
    string get_cfg_value(const char* pszName, const char* pszDefault);
    int get_cfg_value(const char* pszName, int nDefault);

protected:
	//��������loginapp
	bool connect_loginapp(const char* pszAddr, uint16_t unPort);
	//У�������Ƿ���ȷ
	int check_login(const char* pszReq, string& strAccount, uint16_t& uLoginappPort);
	//���ڲ���loginapp����
	bool loginapp_req(const string& strAccount);


	//��������logapp
	bool connect_logapp(const char* pszAddr, uint16_t unPort);
	//���ڲ���logapp����
	bool logpp_req(const string& func_str, const string& params_str );
private:

	void run_api(const char* key,const char* pszFunc, const char* pszParams, CApiBase * pMd5Checker);	
	string get_func_name(const char* pszPathInfo);


private:
	int m_fd;
	CDataCenterApi  m_data_center;
	CPlatApi m_plat_api;

};


#endif

