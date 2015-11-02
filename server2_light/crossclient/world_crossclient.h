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
    //ת���������
    int OnCrossServerRpc(CPluto& u);
    //���Կ���Ļص�
    int OnCrossClientResp(CPluto& u);
    //���Կ���Ĺ㲥
    int OnCrossClientBroadcast(CPluto& u);
    
public:
    //�˷�������
    inline int OpenMogoLib(lua_State* L)
    {
        return 0;
    }

    //�˷�������
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
    uint16_t m_nBcBaseappId;     //�����������������㲥��baseapp_id
    string m_strDefMd5;

};




}



#endif

