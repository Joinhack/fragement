#ifndef __WORLD_CROSSSERVER_HEAD__
#define __WORLD_CROSSSERVER_HEAD__

#include "world.h"
#include "balance.h"


namespace mogo
{

class CWorldCrossserver : public world
{
public:
    CWorldCrossserver();
    ~CWorldCrossserver();

public:
    int FromRpcCall(CPluto& u);
	int init(const char* pszEtcFile);

protected:
	int OnCrossReq(CPluto& u);
    int OnCrossServerRpc(CPluto& u);
    int RegisterServer(CPluto& u);
    int OnCrossClientResp(CPluto& u);
    int OnCrossClientBroadcast(CPluto& u);
    int CheckMd5(CPluto& u);

protected:
	//检查一个rpc调用是否合法
	bool CSCheckClientRpc(CPluto& u);
	//bool CheckTrustedMailbox(CMailBox* pmb);
	//根据需要创建的entity类型权重和各个baseapp的负载选择一个合适的baseapp的mailbox id
	uint16_t ChooseABaseapp(const char* pszEntityType);
    
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
    //获取一个流水号
    uint32_t GetNextRpcSeq(CPluto& u, uint16_t sid, TENTITYTYPE etype, TENTITYID eid);

private:
    //原始服rpc调用信息
    struct _SCrossClientInfo
    {
        int fd;
        uint16_t sid;
        TENTITYTYPE etype;
        TENTITYID eid;

        _SCrossClientInfo(int fd, uint16_t sid, TENTITYTYPE etype, TENTITYID eid)
        {
            this->fd = fd;
            this->sid = sid;
            this->etype = etype;
            this->eid = eid;
        }
    };

private:
	CBalance m_baseBalance;
    uint32_t m_nCrossRpcSeq;                    //跨服服务器内部使用的调用流水号
    list<uint32_t> m_lsFreeRpcSeq;              //已经使用过(可以再次使用的)流水号
    map<uint32_t, _SCrossClientInfo*> m_InRpc;  //正在调用中的rpc信息
    map<string, CEntityMailbox*> m_globalBases; //提供跨服服务的globalbase
    string m_strDefMd5;

};




}



#endif

