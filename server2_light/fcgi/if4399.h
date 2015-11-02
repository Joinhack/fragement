#ifndef __IF4399_HEAD__
#define __IF4399_HEAD__

#include "type_mogo.h"
#include "ifbase.h"
#include "api_data_center.h"
#include "api_plat.h"



//平台接口
class CIf4399 : public CIfBase
{
public:
	CIf4399();
	~CIf4399();

public:
	void login(const char* pszPathInfo, const char* pszReq);
	//数据中心api
	void data_center_api(const char* pszFunc, const char* pszParams);
	//平台api
	void plat_api(const char* pszFunc, const char* pszParams);
	//激活码中心发来的发送礼包
	void add_gift(const char* remote_addr, const char* pszFunc, const char* pszParams);

	void charge(const char* remote_addr, const char* pszPathInfo, const char* pszReq);


protected:
    //重定向客户端页面
    void redirect(const char* pszUrl);
    //返回错误码
    void send_err_resp(int nRet);
    //从配置文件读取配置项的值
    string get_cfg_value(const char* pszName, const char* pszDefault);
    int get_cfg_value(const char* pszName, int nDefault);

protected:
	//尝试连接loginapp
	bool connect_loginapp(const char* pszAddr, uint16_t unPort);
	//校验请求是否正确
	int check_login(const char* pszReq, string& strAccount, uint16_t& uLoginappPort);
	//和内部的loginapp交互
	bool loginapp_req(const string& strAccount);


	//尝试连接logapp
	bool connect_logapp(const char* pszAddr, uint16_t unPort);
	//和内部的logapp交互
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

