#ifndef __WORLD__BASE__HEAD__
#define __WORLD__BASE__HEAD__


#include <lua.hpp>
#include "util.h"
#include "entity.h"
#include "rpc_mogo.h"
#include "lua_mogo.h"
#include "win_adaptor.h"
#include "timer.h"
#include "defparser.h"
#include "path_founder.h"
#include "exception.h"
#include "event.h"
#include "stopword.h"


class CEpollServer;


namespace mogo
{


    class CMailBoxManager
    {
        public:
            CMailBoxManager();
            ~CMailBoxManager();

        public:
            bool init(CCfgReader& cfg);

        public:
            inline list<CMailBox*>& GetMailboxs()
            {
                return m_mbs;
            }

        private:
            list<CMailBox*> m_mbs;

    };

    extern string GetServerTypeNameById(uint16_t nServerType);

    class world
    {
        public:
            world();
            virtual ~world();

        public:
            virtual int init(const char* pszEtcFile);

        public:
            virtual void Clear();
            virtual int OpenMogoLib(lua_State* L) = 0;

        public:
            virtual int OnScriptReady();
            virtual int OnServerReady();
            virtual int OnFdClosed(int fd);

        public:
            virtual CEntityParent* GetEntity(TENTITYID id) = 0;

        public:
            uint16_t GetMailboxId();

        public:
            bool RpcCallFromLua(const char* pszFunc, CEntityMailbox& em, lua_State* L);
            bool RpcCall2CellFromLua(const char* pszFunc, CEntityMailbox& em, lua_State* L);
            bool RpcCall2ClientFromLua(const char* pszFunc, CClientMailbox& em, lua_State* L);
            bool RpcCallToClientViaBase(const char* pszFunc, const CEntityMailbox& em, lua_State* L);
            //通过base转发的client rpc调用,nServerId=0是广播包
            CPluto* RpcCallToClientViaBase(const char* pszFunc, lua_State* L, TENTITYTYPE etype, TENTITYID eid, uint16_t nServerId);

        public:
            template<typename T1>
            void RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1);

            template<typename T1, typename T2>
            void RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2);

            template<typename T1, typename T2, typename T3>
            void RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3);

            template<typename T1, typename T2, typename T3, typename T4>
            void RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4);

            template<typename T1, typename T2, typename T3, typename T4, typename T5>
            void RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5);

            template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
            void RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6);

        public:
            //使用于dbmgr/logapp多线程的rpcall            
            inline bool SyncRpcCall(CPlutoList& pl, uint16_t nServerId, CPluto* u)
            {
#ifndef _WIN32
                CEpollServer* s = this->GetServer();
                CMailBox* mb = s->GetServerMailbox(nServerId);
                if(mb)
                {
                    u->SetMailbox(mb);
                    pl.PushPluto(u);

                    return true;
                }
#endif

                return false;
            }

            template<typename T1>
            void SyncRpcCall(CPlutoList& pl, uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1);

            template<typename T1, typename T2>
            void SyncRpcCall(CPlutoList& pl, uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2);

            template<typename T1, typename T2, typename T3>
            void SyncRpcCall(CPlutoList& pl, uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3);

            template<typename T1, typename T2, typename T3, typename T4>
            void SyncRpcCall(CPlutoList& pl, uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4);

            template<typename T1, typename T2, typename T3, typename T4, typename T5>
            void SyncRpcCall(CPlutoList& pl, uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5);

            template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
            void SyncRpcCall(CPlutoList& pl, uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6);

        public:
            bool PushPlutoToMailbox(uint16_t nServerId, CPluto* u);

        public:
            virtual int FromRpcCall(CPluto& u) = 0;

        public:
            inline CLuaCallback& GetCallback()
            {
                return m_cb;
            }

            inline CLuaCallback& GetLuaTables()
            {
                return m_luatables;
            }

            inline CRpcUtil& GetRpcUtil()
            {
                return m_rpc;
            }

        public:
            void SetServer(CEpollServer* s);
            CEpollServer* GetServer();
            CMailBox* GetServerMailbox(uint16_t nServerId);

#ifdef __TEST
            inline int GetLapsedTime()
            {
                return time1.GetLapsedTime();
            }

            inline void SetNowTime()
            {
                time1.SetNowTime();
            }
#endif

        protected:
            int OnTimerdTick(T_VECTOR_OBJECT* p);
            virtual int ShutdownServer(T_VECTOR_OBJECT* p);

        public:
            inline lua_State* GetLuaState()
            {
                return m_L;
            }

            inline CTimerHeap& GetTimer()
            {
                return m_timer;
            }

            inline CTimerActionQueue& GetLocalTimer()
            {
                return m_LocalTimer;
            }

            inline CDefParser& GetDefParser()
            {
                return m_defParser;
            }

            inline CCfgReader* GetCfgReader()
            {
                return m_cfg;
            }

            inline CMailBoxManager& GetMbMgr()
            {
                return m_mbMgr;
            }

            inline CEventDispatcher *GetEventDispatcher()
            {
                return pstEventDispatcher;
            }

        private:
            std::string ReadConsoleCmd();

        public:
            //根据server_id获取服务器绑定端口
            uint16_t GetServerPort(uint16_t sid);

            //控制台Lua输入
            void DoConsoleLua();

            //执行定时器
            void DoTimerAction();

        protected:
            void InitMailboxMgr();
            void InitTrustedClient();
            //检查一个rpc调用是否合法
            virtual bool CheckClientRpc(CPluto& u);
            //将客户端的socket fd附加到pluto解包出来的数据结构上
            void AddClientFdToVObjectList(int fd, T_VECTOR_OBJECT* p);
            virtual void InitEntityCall();

#ifdef __OPTIMIZE_PROP_SYN
            //每帧调用，同步客户端属性
            void EntitiesPropSyn();
#endif

        public:
            //判断一个客户端连接的地址是否来自于可信任地址列表
            bool IsTrustedClient(const string& strClientAddr);
            //将一个entity id加入定时存盘列表
            void RegisterTimeSave(TENTITYID tid);

            //判断一个IP的连接是否可以连进来该进程
            virtual bool IsCanAcceptedClient(const string& strClientAddr)
            {
                return true;
            }

#ifdef __OPTIMIZE_PROP_SYN
            inline void AddPropSyn(TENTITYID eid)
            {
                this->m_needPropSynEid.insert(eid);
            }
#endif

        public:
            //初始化entity id
            void InitNextEntityId();
            //获得next entity id
            inline TENTITYID GetNextEntityId()
            {
                return ++m_nNextEntityId;
            }

        public:
            inline bool IsValidEntityCall(const string& s)
            {
                return m_entityCalls.find(s) != m_entityCalls.end();
            }

            inline map<string, ENTITY_MEMBER_METHOD>& GetEntityCalls()
            {
                return m_entityCalls;
            }

#ifndef _WIN32
            inline CBlockMapMgr& GetBlockMapMgr()
            {
                return m_bmm;
            }
#endif

            inline CStopWord& GetStopWord()
            {
                return m_stopWord;
            }

        protected:
            lua_State* m_L;
            CCfgReader* m_cfg;
            set<string> m_trustedClients;
            set<string> m_canAcceptedClients;
            CLuaCallback m_cb;
            CLuaCallback m_luatables;
            CRpcUtil m_rpc;
            CEpollServer* the_server;
            CTimerHeap m_timer;
            CTimerActionQueue m_LocalTimer;
            CDefParser m_defParser;
            CMailBoxManager m_mbMgr;
            TENTITYID m_nNextEntityId;
            list<TENTITYID> m_lsTimeSave;
            map<string, ENTITY_MEMBER_METHOD> m_entityCalls;
#ifndef _WIN32
            CBlockMapMgr m_bmm;
#endif
            CEventDispatcher *pstEventDispatcher;
            CStopWord m_stopWord;

#ifdef __OPTIMIZE_PROP_SYN
            set<TENTITYID> m_needPropSynEid;    //记录每一帧里面需要同步客户端属性的entity的id
#endif

#ifdef __TEST
            CGetTimeOfDay time1;
#endif

    };


    //从VOBJECT*中读取字段
#define VOBJECT_GET_SSTR(p) *(p->vv.s)
#define VOBJECT_GET_STR(p) p->vv.s->c_str()
#define VOBJECT_GET_U8(p) p->vv.u8
#define VOBJECT_GET_U16(p) p->vv.u16
#define VOBJECT_GET_U32(p) p->vv.u32
#define VOBJECT_GET_U64(p) p->vv.u64
#define VOBJECT_GET_I8(p) p->vv.i8
#define VOBJECT_GET_I16(p) p->vv.i16
#define VOBJECT_GET_I32(p) p->vv.i32
#define VOBJECT_GET_I64(p) p->vv.i64
#define VOBJECT_GET_F32(p) p->vv.f32
//#define VOBJECT_GET_F64(p) p->vv.f64
#define VOBJECT_GET_EMB(p) p->vv.emb
#define VOBJECT_GET_BLOB(x) (x->vv.p)   //p->vv.p


    template<typename T1>
    void world::RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1)
    {
        if(nServerId == GetMailboxId())
        {
            //本进程
            CPluto* u = new CPluto;
            m_rpc.Encode(*u, msg_id, p1);
            GetServer()->AddLocalRpcPluto(u);
        }
        else
        {
            CMailBox* mb = GetServerMailbox(nServerId);
            if(mb)
            {
                mb->RpcCall(m_rpc, msg_id, p1);
            }
            else
            {
                LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
            }
        }
    }

    template<typename T1, typename T2>
    void world::RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2)
    {
        if(nServerId == GetMailboxId())
        {
            //本进程
            CPluto* u = new CPluto;
            m_rpc.Encode(*u, msg_id, p1, p2);
            GetServer()->AddLocalRpcPluto(u);
        }
        else
        {
            CMailBox* mb = GetServerMailbox(nServerId);
            if(mb)
            {
                mb->RpcCall(m_rpc, msg_id, p1, p2);
            }
            else
            {
                LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
            }
        }
    }

    template<typename T1, typename T2, typename T3>
    void world::RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3)
    {
        if(nServerId == GetMailboxId())
        {
            //本进程
            CPluto* u = new CPluto;
            m_rpc.Encode(*u, msg_id, p1, p2, p3);
            GetServer()->AddLocalRpcPluto(u);
        }
        else
        {
            CMailBox* mb = GetServerMailbox(nServerId);
            if(mb)
            {
                mb->RpcCall(m_rpc, msg_id, p1, p2, p3);
            }
            else
            {
                LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
            }
        }
    }

    template<typename T1, typename T2, typename T3, typename T4>
    void world::RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4)
    {
        if(nServerId == GetMailboxId())
        {
            //本进程
            CPluto* u = new CPluto;
            m_rpc.Encode(*u, msg_id, p1, p2, p3, p4);
            GetServer()->AddLocalRpcPluto(u);
        }
        else
        {
            CMailBox* mb = GetServerMailbox(nServerId);
            if(mb)
            {
                mb->RpcCall(m_rpc, msg_id, p1, p2, p3, p4);
            }
            else
            {
                LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
            }
        }
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5>
    void world::RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5)
    {
        if(nServerId == GetMailboxId())
        {
            //本进程
            CPluto* u = new CPluto;
            m_rpc.Encode(*u, msg_id, p1, p2, p3, p4, p5);
            GetServer()->AddLocalRpcPluto(u);
        }
        else
        {
            CMailBox* mb = GetServerMailbox(nServerId);
            if(mb)
            {
                mb->RpcCall(m_rpc, msg_id, p1, p2, p3, p4, p5);
            }
            else
            {
                LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
            }
        }
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
    void world::RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6)
    {
        if(nServerId == GetMailboxId())
        {
            //本进程
            CPluto* u = new CPluto;
            m_rpc.Encode(*u, msg_id, p1, p2, p3, p4, p5, p6);
            GetServer()->AddLocalRpcPluto(u);
        }
        else
        {
            CMailBox* mb = GetServerMailbox(nServerId);
            if(mb)
            {
                mb->RpcCall(m_rpc, msg_id, p1, p2, p3, p4, p5, p6);
            }
            else
            {
                LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
            }
        }
    }

    //使用于dbmgr/logapp多线程的rpcall
    template<typename T1>
    void world::SyncRpcCall(CPlutoList& pl, uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1)
    {
#ifndef _WIN32
        CEpollServer* s = this->GetServer();
        CMailBox* mb = s->GetServerMailbox(nServerId);
        if(mb)
        {
            CPluto* u = new CPluto;
            m_rpc.Encode(*u, msg_id, p1);
            u->SetMailbox(mb);
            pl.PushPluto(u);
        }
#endif
    }

    template<typename T1, typename T2>
    void world::SyncRpcCall(CPlutoList& pl, uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2)
    {
#ifndef _WIN32
        CEpollServer* s = this->GetServer();
        CMailBox* mb = s->GetServerMailbox(nServerId);
        if(mb)
        {
            CPluto* u = new CPluto;
            m_rpc.Encode(*u, msg_id, p1, p2);
            u->SetMailbox(mb);
            pl.PushPluto(u);
        }
#endif
    }

    template<typename T1, typename T2, typename T3>
    void world::SyncRpcCall(CPlutoList& pl, uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3)
    {
#ifndef _WIN32
        CEpollServer* s = this->GetServer();
        CMailBox* mb = s->GetServerMailbox(nServerId);
        if(mb)
        {
            CPluto* u = new CPluto;
            m_rpc.Encode(*u, msg_id, p1, p2, p3);
            u->SetMailbox(mb);
            pl.PushPluto(u);
        }
#endif
    }

    template<typename T1, typename T2, typename T3, typename T4>
    void world::SyncRpcCall(CPlutoList& pl, uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4)
    {
#ifndef _WIN32
        CEpollServer* s = this->GetServer();
        CMailBox* mb = s->GetServerMailbox(nServerId);
        if(mb)
        {
            CPluto* u = new CPluto;
            m_rpc.Encode(*u, msg_id, p1, p2, p3, p4);
            u->SetMailbox(mb);
            pl.PushPluto(u);
        }
#endif
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5>
    void world::SyncRpcCall(CPlutoList& pl, uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5)
    {
#ifndef _WIN32
        CEpollServer* s = this->GetServer();
        CMailBox* mb = s->GetServerMailbox(nServerId);
        if(mb)
        {
            CPluto* u = new CPluto;
            m_rpc.Encode(*u, msg_id, p1, p2, p3, p4, p5);
            u->SetMailbox(mb);
            pl.PushPluto(u);
        }
#endif
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
    void world::SyncRpcCall(CPlutoList& pl, uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6)
    {
#ifndef _WIN32
        CEpollServer* s = this->GetServer();
        CMailBox* mb = s->GetServerMailbox(nServerId);
        if(mb)
        {
            CPluto* u = new CPluto;
            m_rpc.Encode(*u, msg_id, p1, p2, p3, p4, p6);
            u->SetMailbox(mb);
            pl.PushPluto(u);
        }
#endif
    }


}




#endif

