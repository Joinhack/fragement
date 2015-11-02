#ifndef __WORLD_TIMERD_HEAD__
#define __WORLD_TIMERD_HEAD__

#include "world.h"



namespace mogo
{


    class CTimerdWorld : public world
    {
        public:
            CTimerdWorld();
            ~CTimerdWorld();

        public:
            int FromRpcCall(CPluto& u);
            bool IsCanAcceptedClient(const string& strClientAddr);

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
            CTimerdWorld(const CTimerdWorld&);
            CTimerdWorld& operator=(const CTimerdWorld&);
    };




}




#endif

