#ifndef __ENTITY_HEAD__
#define __ENTITY_HEAD__


#include "type_mogo.h"
#include "my_stl.h"
#include "lua.hpp"
#include "defparser.h"
#include "pluto.h"


namespace mogo
{

    class CEntityParent
    {
        public:
            CEntityParent(TENTITYTYPE etype, TENTITYID nid);
            virtual ~CEntityParent();

            //void * operator new(size_t size, CEntityParent& area);

            //void operator delete(void* p, CEntityParent& area);

        public:
            bool operator<(const CEntityParent& other) const
            {
                return this->GetId() < other.GetId();
            }

        protected:
            virtual uint16_t GetMailboxId() = 0;

        public:
            virtual int init(lua_State* L);


        public:
            inline TENTITYID GetId() const
            {
                return m_id;
            }
            int lGetId(lua_State* L);
            inline TENTITYTYPE GetEntityType() const
            {
                return m_etype;
            }
            int lGetEntityType(lua_State* L);
            int lAddTimer(lua_State* L);
            int lDelTimer(lua_State* L);

            /*
                设置定时器,Lua调用参数:回调的实体成员函数名(字符串),间隔时间,触发次数(0代表无限次),[可选参数1],[可选参数2],返回定时器ID
                回调时参数:定时器ID,当前触发次数,[可选参数1],[可选参数2]
                其中可选参数支持布尔值,数值,字符串,Lua_Table类型,其余类型当作Lua_Nil处理
            */
            int lAddLocalTimer(lua_State* L);

            //移除定时器,Lua调用参数:定时器ID,返回是否成功(布尔值,失败是因为指定定时器不存在)
            int lDelLocalTimer(lua_State* L);

            //检查定时器是否存在,Lua调用参数:定时器ID,返回是否存在
            int lHasLocalTimer(lua_State* L);

            int lWriteToDB(lua_State* L);
            int lRegisterTimeSave(lua_State* L);
            int lGetDbid(lua_State* L);

            int lAddEventListener(lua_State* L);
            int lDelEventListener(lua_State* L);
            int lTriggerEvent(lua_State* L);

        public:
            bool WriteToRedis();

        public:
            inline map<string, VOBJECT*>& GetData()
            {
                return m_data;
            }

            inline TDBID GetDbid() const
            {
                return m_dbid;
            }

            inline void SetDbid(TDBID dbid)
            {
                m_dbid = dbid;
            }

        public:
            bool PickleToPluto(CPluto& u) const;
            //刷新entity的属性,数据一般来自数据库
            void UpdateProps(TDBID dbid, SEntityPropFromPluto* p);
            //刷新entity的属性,数据由一个table给出
            void UpdateProps(map<string, VOBJECT*>& new_data);
            //根据L中指定位置的table刷新entity属性
            void UpdateProps(lua_State* L);
            //刷新一个属性
            VOBJECT* UpdateAProp(const string& strPropName, VOBJECT* v, bool& bUpdate);
            //从redis读取到数据的回调方法
            void OnLoadRedis(const string& strKey, const string& strValue);

        protected:
            const SEntityDef* GetEntityDef() const;
            bool UnpickleFromPluto(CPluto& u);

        public:
            //base独有的方法
            virtual int lRegisterGlobally(lua_State* L)
            {
                return 0;
            }
            virtual int lRegisterCrossServer(lua_State*)
            {
                return 0;
            }
            virtual int lGiveClientTo(lua_State* L)
            {
                return 0;
            }
            //account创建之后,通过loginapp告诉客户端,可以连接baseapp了
            virtual int lNotifyClientToAttach(lua_State* L)
            {
                return 0;
            }
            //account创建以后，被人顶号时，通过loginapp告诉新客户端，断开连接
            virtual int lNotifyClientMultiLogin(lua_State* L)
            {
                return 0;
            }
            virtual int lCreateInNewSpace(lua_State* L)
            {
                return 0;
            }
            virtual int lCreateCellEntity(lua_State* L)
            {
                return 0;
            }
            virtual int lHasCell(lua_State* L)
            {
                return 0;
            }
            virtual int lDestroyCellEntity(lua_State*)
            {
                return 0;
            }
            virtual int lSetCellVisiable(lua_State*)
            {
                return 0;
            }
            virtual int lNotifyDbDestroyAccountCache(lua_State*)
            {
                return 0;
            }
            virtual int lTableSelectSql(lua_State*)
            {
                return 0;
            }
            virtual int lTableInsertSql(lua_State*)
            {
                return 0;
            }
            virtual int lTableExcuteSql(lua_State*)
            {
                return 0;
            }
            //使用回调id的数据库操作接口
            virtual int lTable2Select(lua_State*){return 0;}
            virtual int lTable2Insert(lua_State*){return 0;}
            virtual int lTable2Excute(lua_State*){return 0;}
            virtual int lKickedOut(lua_State*)
            {
                return 0;
            }
            virtual int lHasClient(lua_State* L)
            {
                return 0;
            }

            //cell独有的方法
            virtual int lGetSpaceId(lua_State*)
            {
                return 0;
            }
            virtual int lTelePort(lua_State*)
            {
                return 0;
            }
            virtual int lSetVisiable(lua_State*)
            {
                return 0;
            }

            virtual int lSetSpeed(lua_State*)
            {
                return 0;
            }

            virtual int lProcessMove(lua_State*)
            {
                return 0;
            }

            virtual int lProcessPull(lua_State*)
            {
                return 0;
            }

            virtual int lStopMove(lua_State*)
            {
                return 0;
            }

            virtual int lBroadcastAOI(lua_State*)
            {
                return 0;
            }

            virtual int lGetAOI(lua_State*)
            {
                return 0;
            }

            virtual int lIsInAOI(lua_State*)
            {
                return 0;
            }
			
            virtual int lGetDistance(lua_State*)
            {
                return 0;
            }

            virtual int lGetXY(lua_State*)
            {
                return 0;
            }

            virtual int lSetXY(lua_State*)
            {
                return 0;
            }

            virtual int lGetFace(lua_State*)
            {
                return 0;
            }

            virtual int lGetPackFace(lua_State*)
            {
                return 0;
            }
			
            virtual int lSetFace(lua_State*)
            {
                return 0;
            }

            virtual int lGetMovePointStraight(lua_State*)
            {
                return 0;
            }

            virtual int lGetNextEntityId(lua_State*)
            {
                return 0;
            }

            virtual int lActive(lua_State*)
            {
                return 0;
            }

            virtual int lInActive(lua_State*)
            {
                return 0;
            }

            virtual int lGetIPAddr(lua_State*)
            {
                return 0;
            }

            //把entity放进一个指定的space
            virtual int lAddToSpace(lua_State*)
            {
                return 0;
            }

            //把entity从一个指定的space拿出来
            virtual int lDelFromSpace(lua_State*)
            {
                return 0;
            }
        
            virtual int lUpdateEntityMove(lua_State*)
            {
                return 0;
            }

            //当某个属性变更时,是否要同步给other_clients
            virtual void OnAttriModified(const string& strPropName, VOBJECT* v)
            {
            }
            //将其他entity的属性变化发给自己的客户端
            virtual CPluto* SyncOtherEntityAttri(CPluto* u, TENTITYID eid, uint16_t nPropId, VOBJECT* v)
            {
                return NULL;
            }
            virtual void SyncOwnEntityAttri(uint16_t nPropId, VOBJECT* v)
            {
            }

            //同步带client标记的属性给客户端
            void SyncClientProp(int32_t nPropId, const VOBJECT& v);


#ifdef __OPTIMIZE_PROP_SYN
            virtual void SyncClientPropIds(int32_t nPropId);
            virtual void DoSyncClientProp()
            {
            }
#endif

            inline const CEntityMailbox& GetMyMailbox() const
            {
                return m_mymb;
            }
            inline bool IsBase() const
            {
                return m_bIsBase;
            }
            //设置脏数据标记
            inline void SetDirty()
            {
                m_bIsDirty = true;
                m_bIsMysqlDirty = true;
            }
            inline bool HasClient() const
            {
                return m_bHasClient;
            }

			inline void ClearAllData()
			{
				ClearMap(m_data);
			}

            //从L栈顶获取一个table,以name为名在entity上生成一个mailbox字段
            bool AddAnyMailbox(const string& name, int32_t nRef);

        protected:
            TENTITYID m_id;
            TDBID m_dbid;
            TENTITYTYPE m_etype;
            map<string, VOBJECT*> m_data;
            CEntityMailbox m_mymb;
            bool m_bIsBase;     //true:base false:cell
            bool m_bIsDirty;    //脏数据标记
            bool m_bIsMysqlDirty;  //mysql专有的脏数据标记
            bool m_bTimeSaveMysql; //定时存盘是否写mysql,否则写redis
            time_t m_nTimestamp;   //上次写数据库的时间戳
            bool m_bHasClient;     //是否拥有客户端

#ifdef __OPTIMIZE_PROP_SYN
            set<int32_t> m_clientPropIds;    //记录在每一帧之间修改过的属性ID
#endif


    };



}



#endif
