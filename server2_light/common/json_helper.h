#ifndef __JSON_HELPER__
#define __JSON_HELPER__


#include <string>
#include "cjson.h"
using namespace std;


//json������
class JsonHelper 
{
public:
	JsonHelper(string& strJson);
	~JsonHelper();

public:
	//��ȡ�ӽڵ��ֵ
	bool GetJsonItem(const char* node_name, string & result);
	bool GetJsonItem(const char* node_name, int & result);

	//��ȡ�����ӽڵ��ֵ
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

