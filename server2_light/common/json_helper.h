#ifndef __JSON_HELPER__
#define __JSON_HELPER__


#include <string>
#include "cjson.h"
using namespace std;


//json解析类
class JsonHelper 
{
public:
	JsonHelper(string& strJson);
	~JsonHelper();

public:
	//获取子节点的值
	bool GetJsonItem(const char* node_name, string & result);
	bool GetJsonItem(const char* node_name, int & result);

	//获取二级子节点的值
	bool GetJsonItem2(const char* node1, const char* node2, string & result);
	bool GetJsonItem2(const char* node1, const char* node2, int & result);

private:
	bool _Parse();

private:
	cJSON* m_json;
	bool b_parse;	
	string m_str_json;
	

};


#endif

