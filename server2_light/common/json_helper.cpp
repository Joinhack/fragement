#include "json_helper.h"

JsonHelper::JsonHelper(string& strJson)
{
	m_json = NULL;
	b_parse = false;
	m_str_json = strJson;			
}

JsonHelper::~JsonHelper()
{
	if(m_json)
	{
		cJSON_Delete(m_json);
	}  

}

bool JsonHelper::_Parse()
{
	m_json = cJSON_Parse(m_str_json.c_str());
	b_parse = true;
	return true;
}


bool JsonHelper::GetJsonItem(const char* node_name, string & result)
{
	result = "";
	if (!b_parse)
	{
		_Parse();		//没分析 就分析一次
	}
	if(m_json == NULL)
	{
		return false;
	}
	cJSON* obj_find = cJSON_GetObjectItem(m_json, node_name);

	if(obj_find == NULL)
	{
		return false;
	}
	result = obj_find->valuestring;
	return true;
}

bool JsonHelper::GetJsonItem(const char* node_name, int & result)
{
	result = 0;
	if (!b_parse)
	{
		_Parse();		//没分析 就分析一次
	}
	if(m_json == NULL)
	{
		return false;
	}
	cJSON* obj_find = cJSON_GetObjectItem(m_json, node_name);

	if(obj_find == NULL)
	{
		return false;
	}
	result = obj_find->valueint;
	return true;

}

bool JsonHelper::GetJsonItem2(const char* node1, const char* node2, string & result)
{
	result = "";
	if (!b_parse)
	{
		_Parse();		//没分析 就分析一次
	}

	if(m_json == NULL)
	{
		return false;
	}
	cJSON* obj1 = cJSON_GetObjectItem(m_json, node1);

	if(obj1 == NULL)
	{
		return false;
	}
	cJSON* obj2 = cJSON_GetObjectItem(obj1, node2);
	if(obj2 == NULL)
	{
		return false;
	}

	result = obj2->valuestring;
	return true;
}

bool JsonHelper::GetJsonItem2(const char* node1, const char* node2, int & result)
{
	result = 0;

	if (!b_parse) 
	{
		_Parse();		//没分析 就分析一次
	}

	if(m_json == NULL)
	{
		return false;
	}
	cJSON* obj1 = cJSON_GetObjectItem(m_json, node1);

	if(obj1 == NULL)
	{
		return false;
	}
	cJSON* obj2 = cJSON_GetObjectItem(obj1, node2);
	if(obj2 == NULL)
	{
		return false;
	}

	result = obj2->valueint;
	return true;
}