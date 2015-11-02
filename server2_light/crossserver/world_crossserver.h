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
	//���һ��rpc�����Ƿ�Ϸ�
	bool CSCheckClientRpc(CPluto& u);
	//bool CheckTrustedMailbox(CMailBox* pmb);
	//������Ҫ������entity����Ȩ�غ͸���baseapp�ĸ���ѡ��һ�����ʵ�baseapp��mailbox id
	uint16_t ChooseABaseapp(const char* pszEntityType);
    
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
    //��ȡһ����ˮ��
    uint32_t GetNextRpcSeq(CPluto& u, uint16_t sid, TENTITYTYPE etype, TENTITYID eid);

private:
    //ԭʼ��rpc������Ϣ
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
    uint32_t m_nCrossRpcSeq;                    //����������ڲ�ʹ�õĵ�����ˮ��
    list<uint32_t> m_lsFreeRpcSeq;              //�Ѿ�ʹ�ù�(�����ٴ�ʹ�õ�)��ˮ��
    map<uint32_t, _SCrossClientInfo*> m_InRpc;  //���ڵ����е�rpc��Ϣ
    map<string, CEntityMailbox*> m_globalBases; //�ṩ��������globalbase
    string m_strDefMd5;

};




}



#endif

