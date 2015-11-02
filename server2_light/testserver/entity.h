#ifndef __ENTITY_HEAD__
#define __ENTITY_HEAD__


#include "type_mogo.h"
#include "my_stl.h"
//#include "lua.hpp"
#include "defparser.h"
#include "pluto.h"


namespace mogo
{

class CEntityParent
{
public:
    CEntityParent(TENTITYTYPE etype, TENTITYID nid);
    virtual ~CEntityParent();

public:
    bool operator<(const CEntityParent& other) const
    {
        return this->GetId() < other.GetId();
    }

protected:
    virtual uint16_t GetMailboxId() = 0;

public:
    virtual int init();


public:
    inline TENTITYID GetId() const {return m_id;}
  /*  int lGetId(lua_State* L);
    inline TENTITYTYPE GetEntityType() const {return m_etype;}
    int lGetEntityType(lua_State* L);
    int lAddTimer(lua_State* L);
    int lWriteToDB(lua_State* L);	
	int lRegisterTimeSave(lua_State* L);
    int lGetDbid(lua_State* L);
	int lHasClient(lua_State* L);

public:
	bool WriteToRedis();
*/
public:
    inline map<string, VOBJECT*>& GetData()
    {
        return m_data;
    }

	inline uint32_t GetDbid() const
	{
		return m_dbid;
	}

    inline void SetDbid(uint32_t dbid)
    {
        m_dbid = dbid;
    }

public:
    bool PickleToPluto(CPluto& u) const;
    //刷新entity的属性,数据一般来自数据库
    void UpdateProps(uint32_t dbid, SEntityPropFromPluto* p);
    //刷新entity的属性,数据由一个table给出
    void UpdateProps(map<string, VOBJECT*>& new_data);
	//根据L中指定位置的table刷新entity属性
	//void UpdateProps(lua_State* L);
	//刷新一个属性
	VOBJECT* UpdateAProp(const string& strPropName, VOBJECT* v, bool& bUpdate);
	//从redis读取到数据的回调方法
	//void OnLoadRedis(const string& strKey, const string& strValue);

protected:
    const SEntityDef* GetEntityDef() const;
    bool UnpickleFromPluto(CPluto& u);

public:
/*    //base独有的方法
    virtual int lRegisterGlobally(lua_State* L){return 0;}
    virtual int lGiveClientTo(lua_State* L){return 0;}
    //account创建之后,通过loginapp告诉客户端,可以连接baseapp了
    virtual int lNotifyClientToAttach(lua_State* L){return 0;}
	virtual int lCreateInNewSpace(lua_State* L){return 0;}
	virtual int lCreateCellEntity(lua_State* L){return 0;}
	virtual int lHasCell(lua_State* L){return 0;}
	virtual int lDestroyCellEntity(lua_State*){return 0;}
	virtual int lSetCellVisiable(lua_State*){return 0;}

public:
    //cell独有的方法
	virtual int lGetSpaceId(lua_State*){return 0;}
	virtual int lTeleport(lua_State*){return 0;}
	virtual int lSetVisiable(lua_State*){return 0;}
*/
//public:
	//同步带client标记的属性给客户端
	//void SyncClientProp(int32_t nPropId, const VOBJECT& v);
	
public:
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

public:
	//从L栈顶获取一个table,以name为名在entity上生成一个mailbox字段
	bool AddAnyMailbox(const string& name, int32_t nRef);

protected:
    TENTITYID m_id;
    TDBID m_dbid;
    TENTITYTYPE m_etype;
    map<string, VOBJECT*> m_data;
    CEntityMailbox m_mymb;
	bool m_bIsBase;		//true:base false:cell
	bool m_bIsDirty;    //脏数据标记
	bool m_bIsMysqlDirty;  //mysql专有的脏数据标记
	bool m_bTimeSaveMysql; //定时存盘是否写mysql,否则写redis
	time_t m_nTimestamp;   //上次写数据库的时间戳 
	bool m_bHasClient;     //是否拥有客户端


};



}



#endif
