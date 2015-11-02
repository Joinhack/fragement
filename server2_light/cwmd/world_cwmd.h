#ifndef __WORLD_CWMD_HEAD__
#define __WORLD_CWMD_HEAD__

#include "world.h"
#include "balance.h"


namespace mogo
{
    class CWorldMgrD : public world
    {
        public:
            CWorldMgrD();
            ~CWorldMgrD();

        public:
            //读取日志输出路径
            string GetLogPath(const char* pszEtcFile);
            int init(const char* pszEtcFile);

        public:
            int FromRpcCall(CPluto& u);
            bool IsCanAcceptedClient(const string& strClientAddr);

        private:
            int RegisterGlobally(T_VECTOR_OBJECT* p);
            int CreateBaseFromDbByName(T_VECTOR_OBJECT* p);
            int CreateCellInNewSpace(T_VECTOR_OBJECT* p);
            int CreateBaseAnywhere(T_VECTOR_OBJECT* p);
            int ShutdownAllServers(T_VECTOR_OBJECT* p, CPluto& u);
            int OnServerShutdown(T_VECTOR_OBJECT* p);

        private:
            //根据需要创建的entity类型权重和各个baseapp的负载选择一个合适的baseapp的mailbox id
            uint16_t ChooseABaseApp(const char* pszEntityType);
            //根据需要创建的entity类型权重和各个cellapp的负载选择一个合适的cellapp的mailbox id
            uint16_t ChooseACellApp(const char* pszEntityType);
            uint16_t ChooseACellApp(uint16_t etype);

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
            map<string, CEntityMailbox*> m_globalBases;
            CBalance m_baseBalance;
            CBalance m_cellBalance;
            bool m_bShutdown;               //是否停止服务器标记
            bitset<SERVER_MAILBOX_RESERVE_SIZE> m_setShutdown;      //已经停止的服务器模块

            CWorldMgrD(const CWorldMgrD&);
            CWorldMgrD& operator=(const CWorldMgrD&);
    };




}




#endif

