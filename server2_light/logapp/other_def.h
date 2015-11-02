#ifndef __OTHER_DEF_H__
#define	__OTHER_DEF_H__

#include <string>
#include <map>
#include<vector>
using namespace std;

//#define MYSQL_THREAD_NUM 4
enum { MYSQL_THREAD_NUM = 4, };

#define OUT 
#define POOL_THREAD_NUM  10
#define POOL_QUEUE_NUM   40

typedef struct 
{
	string method;				//方法名
	string flag_md5;			//flag 值（md5）
	string params_str;         //所有params组成的str   x=1&id=2&...
	string values_str;         //所有参数值组成的str   1+2...   
	map<string, string> params; //里面包含 flag=md5 这个字段
}Method_Params;


typedef struct 
{
	string param_name; //参数名字 名字
	int param_type;   //参数类型
	bool is_ness;
}A_Param;


typedef struct 
{
	string Api_name;		//api名
	int flag;				//走向标志
	vector<A_Param> params; //参数
}A_Api;

typedef map<string,A_Api> APIS;

typedef int (*api_func)(int fd, Method_Params & mp, void* p);
typedef map<string, api_func> tg_API_LIB;

typedef struct{
	const char *key;
	const char *desc;
	bool IsNull() 
	{
		return  key == 0 && desc == 0;
	}
} st_dest;


#endif // OTHER_DEF_H
