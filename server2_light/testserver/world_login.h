#ifndef __WORLD_LOGIN_HEAD__
#define __WORLD_LOGIN_HEAD__

#include "world.h"
#include "pluto.h"


namespace mogo
{

class CWorldLogin : public world
{
public:
    CWorldLogin();
    ~CWorldLogin();

public:
    int FromRpcCall(CPluto& u);
    int OpenMogoLib(lua_State* L){

        return NULL;
    }
private:
    int AccountLogin(T_VECTOR_OBJECT* p);
    int SelectAccountCallback(T_VECTOR_OBJECT* p);
    int NotifyClientToAttach(T_VECTOR_OBJECT* p);
	int ModifyLoginFlag(T_VECTOR_OBJECT* p);
    
public:

    //此方法无用
    inline CEntityParent* GetEntity(TENTITYID id)
    {
        return NULL;
    }

    inline int OnServerReady()
    {
        return 0;
    }

public:
	int OnFdClosed(int fd);

private:
    map<int, string> m_fd2accounts;    //socket fd和account的关联关系
    map<string, int> m_accounts2fd;
    map<string, TDBID> m_accounts;     //读取过account表的账户缓存,//todo,独立出loginapp
    set<string> m_accountInCreating;   //正在创建角色的账户
	bool m_bCanLogin;				   //服务器是否开放登陆标记

};




}



#endif

