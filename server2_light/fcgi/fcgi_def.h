#ifndef __DEF_FCGI__
#define __DEF_FCGI__


const static char sg_szCgiLogPath[]     = "/data/server/4399_s999/cgi_log/cgi";	        	//cgi日志的路径和前缀
const static char sg_szCgiLogPath_DC[]     = "/data/server/4399_s999/cgi_log/data_center";	        	//cgi日志的路径和前缀
const static char sg_szCgiLogPath_PA[]     = "/data/server/4399_s999/cgi_log/plat_api";	        	//cgi日志的路径和前缀
const static char sg_szCgiLogPath_AG[]     = "/data/server/4399_s999/cgi_log/add_gift";	        	//cgi日志的路径和前缀
const static char sg_szCgiLogPath_CHARGE[]     = "/data/server/4399_s999/cgi_log/charge";	        	//cgi日志的路径和前缀
const static char sg_szLoginKey[]       = "5a9513158a0254f81951236449190bfb";	//登录命令md5算法中需要的key
const static char sg_szLoginappAddr[] = "127.0.0.1";				            //内部loginapp的地址
const static uint16_t sg_unLoginappPort = 10001;						        //内部loginapp的端口,由url传过来
enum { LOGINAPP_MIN_PORT = 1900, LOGINAPP_MAX_PORT = 30000 };                      //loginapp的端口范围
const static char sg_szVerifyUrl[] = "https://api.4399sy.com/service/verify?verifyToken=";   //平台验证url
const static char sg_szLogappAddr[] = "127.0.0.1";				            //内部logapp的地址
const static int sg_nLogappApiPort = 10005;// 内部logapp 处理api的端口


extern int GetUrl_new(const char* url, string& result);
extern int http_post(const char* url,const char*  params, string& result);


////////////////////////////////////////////////////////////////// 登录认证 //////////////////////////////////////////////////////////////////

enum
{
	ENUM_LOGIN_SUCCESS = 0,                      //认证成功
	ENUM_LOGIN_RET_ACCOUNT_PASSWD_NOMATCH = 1,   //帐号密码不匹配
	ENUM_LOGIN_NO_SERVICE = 2,                   //服务器未开放登陆
	ENUM_LOGIN_FORBIDDEN_LOGIN = 3,              //被禁止登陆
	ENUM_LOGIN_TOO_MUCH   = 4,                   //服务器人数超过最大数量，不可登录
	ENUM_LOGIN_TIME_ILLEGAL = 5,                 //本次登录超时 
	ENUM_LOGIN_SIGN_ILLEGAL = 6,                 //签名非法
	ENUM_LOGIN_SERVER_BUSY = 7,                  //sdk服务器验证超时
	ENUM_LOGIN_SDK_VERIFY_FAILED = 8,            //sdk服务器验证失败
	ENUM_LOGIN_ACCOUNT_ILLEGAL = 9,              //sdk验证成功但是帐号不一样    
	ENUM_LOGIN_MULTILOGIN      = 10,             //重复登陆
	ENUM_LOGIN_INNER_ERR       = 11,             //服务器内部错误
	ENUM_ADDR_NOT_TRUST       = 12,             //非信任ip请求
	ENUM_LOGIN_PLAT_NAME_ERROR = 13,                //平台错误
	ENUM_LOGIN_PLAT_RETURN_ERROR = 14,                //平台返回错误

	ENUM_CHARGE_SUCCESS			=  1,	//	1 成功
	ENUM_CHARGE_REPEAT			=  2,	//	2 订单重复
	ENUM_CHARGE_PARAMES_NOTALL	= -1,	//	-1 提交参数不全
	ENUM_CHARGE_SIGN_FAILED		= -2,	//	-2 签名验证失败
	ENUM_CHARGE_USER_NOT_FOUND	= -3,	//	-3 用户不存在
	ENUM_CHARGE_TIMEOUT			= -4,	//	-4 请求超时
	ENUM_CHARGE_FAILED			= -5,	//	-5 充值失败
};
#endif