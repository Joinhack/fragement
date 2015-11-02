#include "charge_appstore.h"
#include <stdio.h>
#include <ostream>
#include <sys/types.h>
#include <unistd.h>
#include "logger.h"
#include <curl/curl.h> 
#include "cjson.h"
#include "fcgi_def.h"
#include "pluto.h"
#include "ifbase.h"
#include "json_helper.h"

CChargeAppStore::CChargeAppStore()
{
	m_str_plat_name = "appstore";

	m_mpProductId["com.4399sy.ahzs.Online.RMB6"]	= "6";
	m_mpProductId["com.4399sy.ahzs.Online.RMB30"]	= "32";
	m_mpProductId["com.4399sy.ahzs.Online.RMB68"]	= "75";
	m_mpProductId["com.4399sy.ahzs.Online.RMB128"]	= "150";	
	m_mpProductId["com.4399sy.ahzs.Online.RMB328"]	= "390";	
	m_mpProductId["com.4399sy.ahzs.Online.RMB648"]	= "840";
	m_mpProductId["com.4399sy.ahzs.Online.DYJX"]	= "1"; //这个是测试商品
	
}

CChargeAppStore::~CChargeAppStore()
{

}


//校验请求是否正确
int CChargeAppStore::check_login(const char* plat_name, const char* pszReq, string& strAccountGot)
{  	
	LogWarning("into CChargeAppStore::check_login", "111111111111111111111");
	if ( m_str_plat_name !=  (string)plat_name)
	{
		LogWarning("check_login", "plat :%s != %s", plat_name, m_str_plat_name.c_str());
		return ENUM_LOGIN_PLAT_NAME_ERROR;
	}

	map<string, string> dictParams;
	SplitStringToMap(pszReq, '&', '=', dictParams); 

    //到平台验证tocken是否正确
    const string& strTocken = get_dict_field(dictParams, "token");
    const string& strDbid = get_dict_field(dictParams, "dbid");
	const string& strSign = get_dict_field(dictParams, "sign");
	const string& strSuid = get_dict_field(dictParams, "suid"); //账号

	string cfg_url = this->get_cfg_value("appstore_url", ""); 
	string cfg_key = this->get_cfg_value("appstore_key", ""); 
	//1bde13d9cb1675c5ca8188c8c86066c9

    {
		string resp = "";
		stringstream ss_pre_md5;
		stringstream ss_url_params;

		string req_url  = cfg_url;

		//sign = MD5(token&dbid&suid&key)
		ss_pre_md5 << strTocken.c_str() << "&" <<strDbid.c_str()<< "&"<<strSuid.c_str()<< "&"<<cfg_key.c_str();

		string req_sign = getmd5(ss_pre_md5.str().c_str());

		if(req_sign != strSign)
		{
			LogWarning("sign verify failed", "server sign(%s) != client sign(%s)",req_sign.c_str(), strSign.c_str());

			return ENUM_LOGIN_SIGN_ILLEGAL;
		}

		
		ss_url_params << "{\r\n\"receipt-data\" : \""<< strTocken.c_str() <<"\"\r\n}"; //json格式		
		

#if 1
		LogDebug("charge appstore", "url: %s, post data  :%s ", req_url.c_str(), ss_url_params.str().c_str());
		int ret = http_post(req_url.c_str(), ss_url_params.str().c_str(), resp); //这里是post请求
		if (ret != CURLE_OK)
		{
			LogWarning("charge appstore", "ret=%d;req=%s, params=%s", ret, req_url.c_str(), ss_url_params.str().c_str());
			return ENUM_LOGIN_SERVER_BUSY;
		}
#endif

#if 0
		resp = "{\r\n\"receipt\":{\"original_purchase_date_pst\":\"2014-02-07 03:46:36 America/Los_Angeles\", \"unique_identifier\":\"0000b00929f8\", \"original_transaction_id\":\"1000000100877086\", \r\n\"bvrs\":\"1.0\", \"transaction_id\":\"1000000100877086\", \"quantity\":\"1\", \"product_id\":\"com.4399sy.ahzs.Online.DYJX\", \"item_id\":\"816165913\", \"purchase_date_ms\":\"1391773596197\", \r\n\"purchase_date\":\"2014-02-07 11:46:36 Etc/GMT\", \"original_purchase_date\":\"2014-02-07 11:46:36 Etc/GMT\", \"purchase_date_pst\":\"2014-02-07 03:46:36 America/Los_Angeles\", \r\n\"bid\":\"com.4399sy.ahzs.Online\", \"original_purchase_date_ms\":\"1391773596197\"}, \"status\":0}";

#endif

		LogDebug("check_login", "http_post ok ret = %s", resp.c_str());

        Trim(resp);

		JsonHelper jsonhp(resp);
		int rst = 0;
		string rst_product_id = "";
		string rst_bid = "";
		string rst_order_id = "";
		if (!jsonhp.GetJsonItem("status", rst))
		{
			LogWarning("GetJsonItem failed ", "status");
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}		
		if (rst != 0) 
		{
			//结果码为0表示验证成功,其他值都是失败
			LogWarning("login_verifyfailed", "rst=%d;req=%s", rst, pszReq);
			return ENUM_LOGIN_SDK_VERIFY_FAILED;            
		}

		if (!jsonhp.GetJsonItem2("receipt", "product_id", rst_product_id))
		{
			LogWarning("GetJsonItem failed ", "receipt.product_id" );
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}	
		if (!jsonhp.GetJsonItem2("receipt", "bid", rst_bid))
		{
			LogWarning("GetJsonItem failed ", "receipt.bid" );
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}	
		if (!jsonhp.GetJsonItem2("receipt", "transaction_id", rst_order_id))
		{
			LogWarning("GetJsonItem failed ", "receipt.transaction_id" );
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}	

		if (rst_bid != "com.4399sy.ahzs.Online") //这里是我们申请的唯一标示 防止别人伪造
		{
			LogWarning("bid not match!! ", "receive an attack bid = %s" , rst_bid.c_str());
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}

	
		map<string,string>::iterator itor = m_mpProductId.find(rst_product_id.c_str());

		if(itor == m_mpProductId.end())
		{
			LogWarning("product_id find failed ", "%s not in product list" , rst_product_id.c_str());
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}
		string strMoney = itor->second;

		stringstream ss_new_url_params;

		//填充几个空的
		ss_new_url_params << "game_id=&server_id=&pay_way=&order_status=&failed_desc=&order_id=" <<rst_order_id.c_str() 
			<< "&uid=" << strSuid.c_str() 
			<< "&amount="<< strMoney.c_str()
			<< "&callback_info=" << strDbid.c_str();


		strAccountGot.assign(ss_new_url_params.str());
		
    }
	return ENUM_LOGIN_SUCCESS;
}
