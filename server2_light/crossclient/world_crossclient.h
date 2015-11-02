#ifndef __WORLD_CROSSCLIENT_HEAD__
#define __WORLD_CROSSCLIENT_HEAD__

#include "world.h"


namespace mogo
{

class CWorldCrossclient : public world
{
public:
    CWorldCrossclient();
    ~CWorldCrossclient();

public:
    int FromRpcCall(CPluto& u);
    int init(const char* pszEtcFile);

protected:
	//int CrossReq(CPluto& u);
    //转发跨服调用
    int OnCrossServerRpc(CPluto& u);
    //来自跨服的回调
    int OnCrossClientResp(CPluto& u);
    //来自跨服的广播
    int OnCrossClientBroadcast(CPluto& u);
    
public:
    //此方法无用
    inline int OpenMogoLib(lua_State* L)
    {
        return 0;
    }

    //此方法无用
    inline CEntityParent* GetEntity(TENTITYID id)
    {
        return NULL;
    }

    inline int OnServerReady()
    {
        return 0;
    }

private:
    bool CcCheckClientRpc(CPluto& u);

public:
    inline const string& GetDefMd5() const
    {
        return m_strDefMd5;
    }

private:
    uint16_t m_nBcBaseappId;     //用来处理跨服服务器广播的baseapp_id
    string m_strDefMd5;

};




}



#endif

