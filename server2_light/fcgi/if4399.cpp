#include <stdio.h>
#include <ostream>

#include <sys/types.h>
#include <unistd.h>

#include "if4399.h"
#include <fcgi_stdio.h>
#include "pluto.h"
#include "net_util.h"
#include "rpc_mogo.h"

#include <openssl/md5.h>

//#include "other_def.h"
#include <curl/curl.h> 
//#include "http.h"
#include "cjson.h"
#include "URLDecode.h"
#include "cgicfg.h"
#include "login_base.h"
#include "iffactory.h"
#include "charge_appstore.h"



CIf4399::CIf4399() : m_fd(0)
{

}

CIf4399::~CIf4399()
{
    if(m_fd>0)
    {
        ::close(m_fd);
    }
}



//尝试连接loginapp
bool CIf4399::connect_loginapp(const char* pszAddr, uint16_t unPort)
{
	if(m_fd > 0)
	{
		return true;
	}

	int fd = MogoSocket();
	if(fd == -1)
	{
		return false;
	}

	int nRet = MogoConnect(fd, pszAddr, unPort);
	if(nRet != 0)
	{
		::close(fd);
		return false;
	}

	m_fd = fd;
	return true;
}

//重定向客户端页面
void CIf4399::redirect(const char* pszUrl)
{
	FCGI_printf("Location: %s\n\n", pszUrl);	
}

//返回错误码
void CIf4399::send_err_resp(int nRet)
{
    FCGI_printf("Content-type: text/html\r\n\r\n%d", nRet);
}

//从配置文件读取配置项的值
string CIf4399::get_cfg_value(const char* pszName, const char* pszDefault)
{
    string strValue = g_cgi_cfg->GetValue(m_strServName.c_str(), pszName);
    if(strValue.empty())
    {
        return string(pszDefault);
    }

    return strValue;
}

int CIf4399::get_cfg_value(const char* pszName, int nDefault)
{
    string strValue = g_cgi_cfg->GetValue(m_strServName.c_str(), pszName);
    if(strValue.empty())
    {
        return nDefault;
    }

    return atoi(strValue.c_str());
}

////////////////////////////////////////////////////////////////// 登录认证 //////////////////////////////////////////////////////////////////




//和内部的loginapp交互
bool CIf4399::loginapp_req(const string& strAccount)
{
	//发消息给loginapp
	CPluto u;
	u.Encode(MSGID_LOGINAPP_WEBLOGIN) << strAccount << "" << EndPluto;
	if(::send(m_fd, u.GetBuff(), u.GetLen(), 0) != u.GetLen())
	{
		::close(m_fd);
		m_fd = 0;
		LogError("loginapp_send_err", "");
		return false;
	}

	{
		//阻塞等待loginapp的返回消息
		char szRecv[256];
		//先收包长
		if(::recv(m_fd, szRecv, PLUTO_MSGLEN_HEAD, 0) != PLUTO_MSGLEN_HEAD)
		{
			::close(m_fd);
			m_fd = 0;
			LogError("loginapp_recv_err1", "");
			return false;
		}
		//收剩余内容
		int nPlutoSize = sz_to_uint32((unsigned char*)szRecv);
		if(::recv(m_fd, szRecv+PLUTO_MSGLEN_HEAD, nPlutoSize-PLUTO_MSGLEN_HEAD, 0) != nPlutoSize-PLUTO_MSGLEN_HEAD)
		{
			::close(m_fd);
			m_fd = 0;
			LogError("loginapp_recv_err2", "");
			return false;
		}

		CPluto u2(szRecv, nPlutoSize);
		u2.Decode();		

		//解析loginapp的返回消息
		pluto_msgid_t nMsgId = u2.GetMsgId();
		if(nMsgId == MSGID_CLIENT_NOTIFY_ATTACH_BASEAPP)
		{
			//通知登录baseapp
			string strBaseIp;
			uint16_t unPort;
			string strBaseKey;
			u2 >> strBaseIp >> unPort >> strBaseKey;

            //返回客户端成功信息,引导登陆baseapp
            FCGI_printf("Content-type: text/html\r\n\r\n%d,%s,%d,%s,%s", 0, strBaseIp.c_str(), unPort, strBaseKey.c_str(), strAccount.c_str());
            return true;
		}	
        else if(nMsgId == MSGID_CLIENT_NOTIFY_MULTILOGIN)
        {
            this->send_err_resp(ENUM_LOGIN_MULTILOGIN);
            return true;
        }
		else
		{
			//错误情况
            LogError("loginapp_msgid_err3", "msg=%d", nMsgId);
			return false;
		}
	}

	return false;
}

//登录命令
void CIf4399::login(const char* pszPathInfo, const char* pszReq)
{
	//设置日志路径
	g_logger.SetLogPath(this->get_cfg_value("login_log", sg_szCgiLogPath));

	 string plat_name = get_func_name(pszPathInfo);

	 CLoginBase* pLogin = CIfFactory::getLoginObj(plat_name.c_str());

	 if(pLogin == NULL)
	 {
		 LogError("login", "plat %s factory not found!!", plat_name.c_str());
		 this->send_err_resp(ENUM_LOGIN_INNER_ERR);
		 return;
	 }

	 //检查请求是否合法
	 string strAccount;	//登录玩家帐号
	 int nRet = pLogin->check_login(plat_name.c_str(), pszReq, strAccount);
	 if(nRet != ENUM_LOGIN_SUCCESS)
	 {
		 this->send_err_resp(nRet);
		 return;
	 }
	 strAccount = (plat_name + "_" + strAccount);

	 uint16_t uLoginappPort = this->get_cfg_value("loginapp_port",sg_unLoginappPort);     //目标loginapp端口
	 //尝试连接loginapp
	 if(!this->connect_loginapp(sg_szLoginappAddr, uLoginappPort))
	 {
		 LogError("connect_loginapp_err","");
		 this->send_err_resp(ENUM_LOGIN_NO_SERVICE);
		 return;
	 }
	 LogError("login"," connect to[%s:%d]  ok!", sg_szLoginappAddr, uLoginappPort);

	 if(!this->loginapp_req(strAccount))
	 {
		 LogError("loginapp_req", "send data to[%s:%d] failed", sg_szLoginappAddr, uLoginappPort);
		 this->send_err_resp(ENUM_LOGIN_INNER_ERR);
		 return;
	 }

	 LogError("login"," finish!");
	 return;
	 

}


void CIf4399::data_center_api(const char* pszFunc, const char* pszParams)
{
	g_logger.SetLogPath(this->get_cfg_value("center_log", sg_szCgiLogPath));
	string key = this->get_cfg_value("center_key", "aiyou123456");
	run_api(key.c_str(), pszFunc, pszParams, (CApiBase * )&m_data_center);
}

void CIf4399::plat_api(const char* pszFunc, const char* pszParams)
{
	g_logger.SetLogPath(this->get_cfg_value("plat_log", sg_szCgiLogPath));
	string key = this->get_cfg_value("plat_key", sg_szLoginKey);
	m_plat_api.init();
	run_api(key.c_str(), pszFunc, pszParams, (CApiBase * )&m_plat_api);
}

void CIf4399::add_gift(const char* remote_addr, const char* pszFunc, const char* pszParams)
{	
	g_logger.SetLogPath(this->get_cfg_value("gift_log", sg_szCgiLogPath));

	LogError("add_gift","remote_addr:[%s] -> server_name [%s]",remote_addr, my_getenv("SERVER_NAME"));

	string trust_ip = this->get_cfg_value("trust_ip", "127.0.0.1");
	
	if (string::npos == trust_ip.find(remote_addr))
	{
		this->send_err_resp(ENUM_ADDR_NOT_TRUST);
		LogError("add_gift","remote_addr:[%s] not in [%s]",remote_addr, trust_ip.c_str());
		return;
	}

	string key = this->get_cfg_value("card_center_key", "aiyou123456"); 
	run_api(key.c_str(), pszFunc, pszParams, (CApiBase * )&m_data_center);
}


void CIf4399::charge(const char* remote_addr, const char* pszPathInfo, const char* pszReq)
{	
	g_logger.SetLogPath(this->get_cfg_value("charge_log", sg_szCgiLogPath_CHARGE));

	string str_func = get_func_name(pszPathInfo);

	LogDebug("CIf4399::run_api", " server:[%s] m_server[%s], path_info: %s, func:%s , params:%s", my_getenv("SERVER_NAME"),m_strServName.c_str(), pszPathInfo, str_func.c_str(), pszReq );


	string new_params = "" ;

	if (str_func == "")
	{
		this->send_err_resp(ENUM_LOGIN_SIGN_ILLEGAL);
		return;
	}
	else if (str_func == "appstore")
	{
		CChargeAppStore cca;		
		string got_params;
		int nRet = cca.check_login(str_func.c_str(), pszReq, got_params);	

		LogDebug("charge","url  %s",got_params.c_str());	


		if (ENUM_LOGIN_SUCCESS != nRet)
		{
			this->send_err_resp(nRet);
			return;
		}		
		new_params = got_params;//这里重置下
	}
	else //非ios 统一交给充值中心
	{

		LogDebug("charge","remote_addr:[%s] -> server_name [%s]",remote_addr, my_getenv("SERVER_NAME"));	


		string trust_ip = this->get_cfg_value("charge_trust_ip", "127.0.0.1");

		if (string::npos == trust_ip.find(remote_addr))
		{
			this->send_err_resp(ENUM_ADDR_NOT_TRUST);
			LogError("charge","remote_addr:[%s] not in [%s]",remote_addr, trust_ip.c_str());
			return;
		}

		string key = this->get_cfg_value("charge_key", ""); 

		string decode_params_str =  HttpUtility::URLDecode(pszReq);
		map<string, string> dictParams;
		SplitStringToMap(decode_params_str, '&', '=', dictParams);	

		string order_id		= get_dict_field(dictParams, "order_id");
		string game_id		= get_dict_field(dictParams, "game_id");
		string server_id	= get_dict_field(dictParams, "server_id");
		string uid			= get_dict_field(dictParams, "uid");
		string pay_way		= get_dict_field(dictParams, "pay_way");
		string amount		= get_dict_field(dictParams, "amount");
		string callback_info = get_dict_field(dictParams, "callback_info");
		string order_status = get_dict_field(dictParams, "order_status");
		string failed_desc	= get_dict_field(dictParams, "failed_desc");
		string sign			= get_dict_field(dictParams, "sign");

		//加密采用md5算法：	MD5(order_id+game_id+server_id+uid+pay_way+amount+callback_info+order_status+failed_desc+key)
		ostringstream pre_md5;

		pre_md5 <<order_id.c_str() << game_id.c_str() << server_id.c_str() << uid.c_str() << pay_way.c_str() << amount.c_str() << callback_info.c_str() << order_status.c_str() << failed_desc.c_str() << key.c_str();

		string _md5 = getmd5(pre_md5.str().c_str());

		if (_md5 != sign)
		{
			this->send_err_resp(ENUM_CHARGE_SIGN_FAILED);
			LogDebug("md5_check failed","sign(%s) != mymd5(%s)",sign.c_str(), _md5.c_str());
			return;
		}


		new_params = decode_params_str;//这里重置下
	}


	LogDebug("run_api","md5 ok, begein to connect logapp");
	//LogDebug("CIf4399::run_api", ".2..");
	//尝试连接logapp //
	LogDebug("run_api","connect to [%s, %d]", sg_szLogappAddr,  this->get_cfg_value("logapp_port", sg_nLogappApiPort));
	if(!this->connect_logapp(sg_szLogappAddr, this->get_cfg_value("logapp_port", sg_nLogappApiPort)))
	{
		LogError("connect_loginapp_err","");
		this->send_err_resp(ENUM_CHARGE_FAILED);
		return;
	}
	LogDebug("run_api","connect ok");
	if(!this->logpp_req("charge", new_params + "&plat=" + str_func)) //这里请求charge
	{
		this->send_err_resp(ENUM_CHARGE_FAILED);
		return;
	}
	LogError("charge"," finish!");
}


//尝试连接loginapp
bool CIf4399::connect_logapp(const char* pszAddr, uint16_t unPort)
{
	return connect_loginapp(pszAddr, unPort);	
}

//和内部的loginapp交互
bool CIf4399::logpp_req(const string& func_str, const string& params_str)
{
	//发消息给loginapp
	//string send_str = string(getenv("QUERY_STRING"))
	CPluto u;
	u.Encode(MSGID_OTHER_YUNYING_API) << func_str << params_str << EndPluto;
	if(::send(m_fd, u.GetBuff(), u.GetLen(), 0) != u.GetLen())
	{
		::close(m_fd);
		m_fd = 0;
		LogError("loginapp_send_err", "");
		return false;
	}
	LogDebug("CIf4399::logpp_req", "func[%s], param[%s]", func_str.c_str(), params_str.c_str());
	{
		//阻塞等待loginapp的返回消息
		char szRecvHead[4];
		//先收包长
		if(::recv(m_fd, szRecvHead, PLUTO_MSGLEN_HEAD, 0) != PLUTO_MSGLEN_HEAD)
		{
			::close(m_fd);
			m_fd = 0;
			LogError("logapp_recv_err1", "");
			return false;
		}
		//收剩余内容
		int nPlutoSize = sz_to_uint32((unsigned char*)szRecvHead);
		char* pszRecv = new char[nPlutoSize];
		//memset(pszRecvText, 0, sizeof(pszRecvText));
		memcpy(pszRecv, szRecvHead, PLUTO_MSGLEN_HEAD);
		if(::recv(m_fd, pszRecv+PLUTO_MSGLEN_HEAD, nPlutoSize-PLUTO_MSGLEN_HEAD, 0) != nPlutoSize-PLUTO_MSGLEN_HEAD)
		{
			::close(m_fd);
			m_fd = 0;
			LogError("logapp_recv_err2", "");
			return false;
		}

		CPluto u2(pszRecv, nPlutoSize);
		delete[] pszRecv;
		/*
		//阻塞等待loginapp的返回消息
		char szRecv[256];
		//先收包长
		if(::recv(m_fd, szRecv, PLUTO_MSGLEN_HEAD, 0) != PLUTO_MSGLEN_HEAD)
		{
			::close(m_fd);
			m_fd = 0;
			LogError("loginapp_recv_err1", "");
			return false;
		}
		//收剩余内容
		int nPlutoSize = sz_to_uint32((unsigned char*)szRecv);
		if(::recv(m_fd, szRecv+PLUTO_MSGLEN_HEAD, nPlutoSize-PLUTO_MSGLEN_HEAD, 0) != nPlutoSize-PLUTO_MSGLEN_HEAD)
		{
			::close(m_fd);
			m_fd = 0;
			LogError("loginapp_recv_err2", "");
			return false;
		}

		CPluto u2(szRecv, nPlutoSize);
		*/
		u2.Decode();		

		//解析loginapp的返回消息
		pluto_msgid_t nMsgId = u2.GetMsgId();
		if(nMsgId == MSGID_LOG_INSERT)
		{
			//通知登录baseapp
			string result;
			u2 >> result;

			//返回客户端成功信息,引导登陆baseapp
			FCGI_printf("Content-type: text/html\r\n\r\n%s", result.c_str());
			return true;
		}	
		else
		{
			//错误情况
			LogError("loginapp_msgid_err3", "msg=%d", nMsgId);
			return false;
		}
	}

	return false;
}



void CIf4399::run_api(const char* key, const char* pszPathInfo, const char* pszReq, CApiBase * pMd5Checker)
{
	string str_func = get_func_name(pszPathInfo);

	LogDebug("CIf4399::run_api", " server:[%s] m_server[%s], path_info: %s, func:%s , params:%s", my_getenv("SERVER_NAME"),m_strServName.c_str(), pszPathInfo, str_func.c_str(), pszReq );

	if (str_func == "")
	{
		this->send_err_resp(ENUM_LOGIN_SIGN_ILLEGAL);
		return;
	}
	//LogDebug("CIf4399::run_api", ".1..");
	if (!pMd5Checker->check_md5(key, pszReq, str_func.c_str()))
	{
		this->send_err_resp(ENUM_LOGIN_SIGN_ILLEGAL);
		return;

	}
	LogDebug("run_api","md5 ok, begein to connect logapp");
	//LogDebug("CIf4399::run_api", ".2..");
	//尝试连接logapp //
	LogDebug("run_api","connect to [%s, %d]", sg_szLogappAddr,  this->get_cfg_value("logapp_port", sg_nLogappApiPort));
	if(!this->connect_logapp(sg_szLogappAddr, this->get_cfg_value("logapp_port", sg_nLogappApiPort)))
	{
		LogError("connect_loginapp_err","");
		this->send_err_resp(ENUM_LOGIN_NO_SERVICE);
		return;
	}
	LogDebug("run_api","connect ok");
	string decode_params_str =  HttpUtility::URLDecode(pszReq);
	if(!this->logpp_req(str_func, decode_params_str))
	{
		this->send_err_resp(ENUM_LOGIN_NO_SERVICE);
		return;
	}

	return;

}



string CIf4399::get_func_name(const char* pszPathInfo) 
{
	const char* pszFunc = pszPathInfo;
	if (NULL == pszFunc)
	{		
		return "";
	}

	string func_str = pszFunc;

	int find_pos = func_str.rfind('/');

	if (-1 == find_pos || 1 >= func_str.size())
	{
		return "";
	}

	return func_str.substr( find_pos + 1);
}

