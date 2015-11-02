#include "other_def.h"
#include "dboper.h"
#include "world_other.h"
#include "cjson.h"
#include "base64.h"

extern CWorldOther& g_worldOther;

tg_API_LIB g_api_lib = tg_API_LIB() ;


string dest2json( st_dest dest[])
{
	string ret;
	for (int i = 0; !dest[i].IsNull(); ++i)
	{
		ret += "\"";
		ret += dest[i].key;
		ret += "\":\"";		
		ret += dest[i].desc;
		ret += "\",\r\n";
	}

	ret =("{\r\n" + ret + "}\r\n") ;	
	return ret;
}

int data2json( vector<string>&  cols, vector<string>&  data, string & result)
{
	string ret;
	string a_row;	
	int num = 0;
	size_t len = cols.size();
	if (len == 0) return num;
	for (size_t i =0; i<data.size(); ++i)
	{		
		a_row += "\"";
		a_row += cols[i%len];
		a_row += "\":\"";		
		a_row += data[i];
		a_row += "\",\r\n";

		if ((i+1) %len == 0)
		{			
			ret +=("{\r\n" + a_row + "},\r\n") ;
			a_row = "";
			++num;
		}

	}

	result =  ret;
        if (num>1) {result = "[" + ret + "]";}
	return num;
}

cJSON *RenderJsonArray(vector<int>& format, vector<string>&  data)
{
	cJSON *n = 0, *p = 0, *json = cJSON_CreateArray();
	size_t i = 0;
	size_t len = format.size();
	while (i < data.size())
	{
		size_t ii = i%len;
		if(ii == 0)
			n = cJSON_CreateArray();
		p = 0;
		switch (format[ii])
		{
		case cJSON_String:
			{
				p = cJSON_CreateString(data[i].c_str());
				break;
			}
		case cJSON_Number:
			{
				p = cJSON_CreateNumber(atoi(data[i].c_str()));
				break;
			}
		default:
			break;
		}
		if (!p || 0 == p)
		{
			LogWarning("RenderJsonArray", "%s", data[i].c_str());
			break;
		}
		cJSON_AddItemToArray(n, p);
		if(ii == len - 1)
			cJSON_AddItemToArray(json, n);
		++i;
	}
}

string get_value(map<string,string>& params, const char* key)
{
	map<string,string>::iterator itor = params.find(key);
	if(itor != params.end())
	{
		return itor->second;
	}
	return "";	
}




int count_user(int fd, Method_Params & mp, void* p)
{
     static st_dest dest[] = 
    {
        {"sm_name", "角色名字"},
        {"sm_level", "角色名字"},
        {"sm_exp", "角色名字"},
	    {0,0}
    };
    
	string col_names;


	for (int i = 0; !dest[i].IsNull(); ++i)
	{
		col_names += dest[i].key;
		col_names += ",";
	}
	Trim(col_names);

	string strTop;
	
	string ret = get_value(mp.params, "page_size");
	if(!ret.empty())
	{
		strTop += (string(" top ") +  ret + " ");
	}

	string strWhere;


	ret = get_value(mp.params, "user_name");
	if(!ret.empty())
	{
		string tmp = ("where sm_name like '%" + ret +"%'"); //username 模糊查询
		strWhere += tmp;
	}

	ret = get_value(mp.params, "user_id");
	if(!ret.empty())
	{
		string tmp = (" and id =  " + ret ); //
		strWhere += tmp;
	}


	ret = get_value(mp.params, "account");
	if(!ret.empty())
	{
		string tmp = ("and sm_accountName =  '" + ret +"'"); //
		strWhere += tmp;
	}





// user_name	String	�?高富帅有人爱	玩家角色�? 支持模糊查询
// user_id	Number	�?2	玩家ID
// account	String	�?test	平台帐号
// is_online	Number	�?0	1=在线�?=全部
// last_login_ip	String	�?23.432.123.123	玩家�?��登陆IP
// order_field	String	�?use_name	排序：返回记录排序字�?
// order_type	String	�?1	排序�?=升序, 1=降序。当且仅当order_field存在时使�?
	// page_num	Number	�?1	分页处理：当前页数�?如果此�?为空，则接口实现方记得验证，将其设置�?。�?不是返回参数错误的提示�?
	// page_size	Number	�?15	分页处理：返回记录数。如果此值为空，则接口实现方记得验证，将其设置为�?��理想值，如：5�?0�?5。亲，由你决定�?
	// is_forbid	Number	�?0	是否封号�?=是，0=�?

	string sql;
	sql = "select "+ strTop + col_names + " from mogo_qurong.tbl_Avatar "+strWhere;


	vector<string>  cols; 
	vector<string>  data;
	CDbOper* db = (CDbOper*)p;
	if (0 != db->SqlQuery("select sm_name, sm_level, sm_exp from mogo_qurong.tbl_Avatar", cols, data))
	{
		return 0;
	}
        
	for (size_t i=0; i<cols.size(); ++i)
	{
            cout<<cols[i].c_str()<<endl;
		//printf(""cols[i].c_str());
	}
	size_t len = cols.size();
	for (size_t i =0; i<data.size(); ++i)
	{
            cout<<data[i].c_str()<<", ";
            if (i %len == 0)
                cout<<endl;
		//printf(data[i].c_str());
	}
	
}

int user_info_list(int fd, Method_Params & mp, void* p)
{
	static st_dest dest[] = 
	{
		{"sm_name", "角色名字"},
		{"sm_level", "等级"},
		{"sm_exp", "经验"},
		{"sm_gold", "金钱"},
		{"sm_diamond", "钻石"},
		{0,0}
	};

	string col_names;
	for (int i = 0; !dest[i].IsNull(); ++i)
	{
		col_names += dest[i].key;
		col_names += ",";
	}
	size_t index = col_names.rfind(',');
	if(string::npos != index)
	{
		col_names.erase(index);
	}
	
	
	string strTop;

	string ret = get_value(mp.params, "page_size");
	if(!ret.empty())
	{
		strTop += (string(" top ") +  ret + " ");
	}

	string strWhere;

	ret = get_value(mp.params, "user_name");
	if(!ret.empty())
	{
		string tmp = ("where sm_name like '%" + ret +"%'"); //username 模糊查询
		strWhere += tmp;
	}

	ret = get_value(mp.params, "user_id");
	if(!ret.empty())
	{
		string tmp = (" and id =  " + ret ); //
		strWhere += tmp;
	}

	ret = get_value(mp.params, "account");
	if(!ret.empty())
	{
		string tmp = ("and sm_accountName =  '" + ret +"'"); //
		strWhere += tmp;
	}

	string sql;
	sql = "select "+ strTop + col_names + " from mogo_qurong.tbl_Avatar "+strWhere;

	vector<string>  cols; 
	vector<string>  data;
	CDbOper* db = (CDbOper*)p;
	if (0 != db->SqlQuery(sql, cols, data))
	{
		g_worldOther.Response2Browser(fd, "\"state\":\"failed\"");	 //查询异常
		return 0;
	}
	string result_data;
	int num = data2json(cols, data, result_data);

	char s[64];
	memset(s, 0, sizeof(s));
	snprintf(s, sizeof(s), "\"total_number\":%d\r\n", num);

	string response = string("{\r\n") + string(s) + string("\"state\":\"success\",\r\n\"dest\":") + dest2json(dest) + string("\r\n\"data\":") +  result_data + string("}");
	g_worldOther.Response2Browser(fd, response);	
}

/*
4399平台 游戏在线统计接口
*/
int online_info(int fd, Method_Params & mp, void* p)
{
	static string selectCurrentCount = "SELECT people, FROM_UNIXTIME(happend_time) FROM tbllog_online ORDER BY happend_time DESC LIMIT 1;";
	vector<string>  cols; 
	vector<string>  data;
	CDbOper* db = (CDbOper*)p;
	if (0 != db->SqlQuery(selectCurrentCount, cols, data))
	{
		g_worldOther.Response2Browser(fd, "0");	 //找不到对应服务器信息
		return 0;
	}
	if (data.size() < 2)
	{
		g_worldOther.Response2Browser(fd, "0");	 //找不到对应服务器信息
		return 0;
	}
	string online_now = data[0];
	static string selectOtherCount = "SELECT MIN(people), MAX(people) FROM tbllog_online WHERE happend_time > UNIX_TIMESTAMP(CURRENT_DATE);";
	cols.clear();
	data.clear();
	if (0 != db->SqlQuery(selectOtherCount, cols, data))
	{
		g_worldOther.Response2Browser(fd, "0");	 //找不到对应服务器信息
		return 0;
	}
	if (data.size() < 1)
	{
		g_worldOther.Response2Browser(fd, "0");	 //找不到对应服务器信息
		return 0;
	}
	string online_min = data[0];
	string online_max = data[1];
	//当前服务器在线人数，当日最高在线人数，当天最低在线人数
	string resp = online_now + ",";
	resp += online_max;
	resp += ",";
	resp += online_min;
	g_worldOther.Response2Browser(fd, resp);
	return 0;
}

/*
4399平台 玩家创建角色信息接口
返回array(
array(‘ddd’,’aaaa’,1231),
array(‘ddd’,’aaaa’,1231),
)的json格式
*/
int avatar_create_info(int fd, Method_Params & mp, void* p)
{
	static st_dest dest[] = 
	{
		{"account_name", "帐号名字"},
		{"role_name", "角色名字"},
		{"happend_time", "时间"},
		{0,0}
	};
	static string select = "SELECT account_name, role_name, happend_time FROM tbllog_role WHERE happend_time >= %d and happend_time <= %d LIMIT 0,100;";
	string ret = get_value(mp.params, "start_time");
	if(ret.empty())
	{
		g_worldOther.Response2Browser(fd, "-1");	 //提交参数不全
		return 0;
	}
	uint32_t startTime = atoi(ret.c_str());
	ret = get_value(mp.params, "end_time");
	if (ret.empty())
	{
		g_worldOther.Response2Browser(fd, "-1");	 //提交参数不全
		return 0;
	}
	uint32_t endTime = atoi(ret.c_str());
	char pszSql[1024] = {0};
	if ( 0 > snprintf(pszSql,1023, select.c_str(), startTime, endTime))
	{
		g_worldOther.Response2Browser(fd, "-1");	 //提交参数不全
		return 0;
	}

	vector<string>  cols; 
	vector<string>  data;
	CDbOper* db = (CDbOper*)p;
	if (0 != db->SqlQuery(pszSql, cols, data))
	{
		g_worldOther.Response2Browser(fd, "0");	 //找不到对应服务器信息
		return 0;
	}
	if (data.size() < 1)
	{
		g_worldOther.Response2Browser(fd, "[]");	 //找不到对应服务器信息
		return 0;
	}
	string result_data = "[";
	/*[["123","\u6218\u58eb",123456],["246","\u6cd5\u5e08",456789]]*/
	for (size_t i =0; i < data.size(); )
	{		
		result_data += "[\"";
		result_data += data[i];
		result_data += "\",\"";
        string& strRoleName = data[i+1];
        result_data += base64_encode((unsigned char*)strRoleName.c_str(), (unsigned int)strRoleName.size());		
		result_data += "\",";
		result_data += data[i+2];
		i += 3;
		if(i < data.size())
			result_data += "],";
		else
			result_data += "]";
	}

	result_data += "]";
	g_worldOther.Response2Browser(fd, result_data);
	/*
	int num = data2json(cols, data, result_data);

	char s[64];
	memset(s, 0, sizeof(s));
	snprintf(s, sizeof(s), "\"total_number\":%d\r\n", num);

	string response = string("{\r\n") + string(s) + string("\"state\":\"success\",\r\n\"dest\":") + dest2json(dest) + string("\r\n\"data\":") +  result_data + string("}");
	g_worldOther.Response2Browser(fd, response);
	*/
	
	/*
	‘ddd’,’aaaa’,1231
	*/
	/*
	vector<int> format;
	format.push_back(cJSON_String);
	format.push_back(cJSON_String);
	format.push_back(cJSON_Number);
	cJSON *cj = RenderJsonArray(format, data);
	//当前服务器在线人数，当日最高在线人数，当天最低在线人数
	char* resp =cJSON_Print(cj);
	g_worldOther.Response2Browser(fd, resp);
	*/
	return 0;
}

/*
4399平台 玩家升级日志接口 
返回array(
array(‘ddd’,’aaaa’,5,1231),
array(‘ddd’,’aaaa’,5,1231),
)的json格式

*/
int avatar_levelUp_info(int fd, Method_Params & mp, void* p)
{
	static string select = "SELECT account_name, role_name, current_level, happend_time FROM tbllog_level_up WHERE happend_time >= %d and happend_time <= %d LIMIT 0,100;;";
	string ret = get_value(mp.params, "start_time");
	if(ret.empty())
	{
		g_worldOther.Response2Browser(fd, "-1");	 //提交参数不全
		return 0;
	}
	uint32_t startTime = atoi(ret.c_str());
	ret = get_value(mp.params, "end_time");
	if (ret.empty())
	{
		g_worldOther.Response2Browser(fd, "-1");	 //提交参数不全
		return 0;
	}
	uint32_t endTime = atoi(ret.c_str());
	char pszSql[1024] = {0};
	if (0 > snprintf(pszSql,1023, select.c_str(), startTime, endTime))
	{
		g_worldOther.Response2Browser(fd, "-1");	 //提交参数不全
		return 0;
	}

	vector<string>  cols; 
	vector<string>  data;
	CDbOper* db = (CDbOper*)p;
	if (0 != db->SqlQuery(pszSql, cols, data))
	{
		g_worldOther.Response2Browser(fd, "0");	 //找不到对应服务器信息
		return 0;
	}
	if (data.size() < 1)
	{
		g_worldOther.Response2Browser(fd, "[]");	 //找不到对应服务器信息
		return 0;
	}
	string result_data = "[";
	/*[["123","\u6218\u58eb",12,123456],["246","\u6cd5\u5e08",15,456789]]*/
	for (size_t i =0; i < data.size(); )
	{		
		result_data += "[\"";
		result_data += data[i];
		result_data += "\",\"";
        string& strRoleName = data[i+1];
		result_data += base64_encode((unsigned char*)strRoleName.c_str(), (unsigned int)strRoleName.size());
		result_data += "\",";
		result_data += data[i+2];
		result_data += ",";
		result_data += data[i+3];
		i += 4;
		if(i < data.size())
			result_data += "],";
		else
			result_data += "]";
	}
	result_data += "]";
	g_worldOther.Response2Browser(fd, result_data);
	/*
	‘ddd’,’aaaa’,1231
	*/
	/*
	vector<int> format;
	format.push_back(cJSON_String);
	format.push_back(cJSON_String);
	format.push_back(cJSON_Number);
	format.push_back(cJSON_Number);
	cJSON *cj = RenderJsonArray(format, data);
	//当前服务器在线人数，当日最高在线人数，当天最低在线人数
	char* resp =cJSON_Print(cj);
	g_worldOther.Response2Browser(fd, resp);
	*/
	return 0;
}

int InitLib()
{

    g_api_lib["count_user"] = count_user;
	g_api_lib["user_info_list"] = user_info_list;
	
	//4399手游平台接口
	g_api_lib["user_online"] = online_info;
	g_api_lib["user_role_info"] = avatar_create_info;
	g_api_lib["user_upgrade"] = avatar_levelUp_info;

    return 0;
}

