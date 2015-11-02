#ifndef __DEFPARSER__HEAD__
#define __DEFPARSER__HEAD__

#include <list>
#include "util.h"
#include "type_mogo.h"
#include <tinyxml.h>
#include "cfg_reader.h"

using std::list;

enum{ ENTITY_TYPE_NONE = 0,};
extern const string EMPTY_STRING;
const char g_cPathSplit = '/';

namespace mogo
{

//string和int的映射类
class CStr2IntMap
{
public:
    CStr2IntMap();
    ~CStr2IntMap();

public:
    //按自增长的id和string作映射
    void AddNewString(const string& s);
    const string& GetStrByInt(uint32_t n) const;
    int32_t GetIntByStr(const string& s) const;
    //预先分配n个缺省值
    void Assign(uint32_t n);
    //直接指定一个id和string的映射
    void SetNewString(uint32_t uid, const string& s);

private:
    uint32_t m_nNextId;
    map<string, uint32_t> m_str2Int;
    vector<string> m_int2Str;
    
};

enum EEntityPropFlag
{
	//EEPF_BASE            = 0x0,
	//EEPF_BASE_AND_CLIENT = 0x1,
	//EEPF_CELL            = 0x10,		//CELL_PRIVATE
	//EEPE_CELL_AND_CLIENT = 0x11,		//OWN_CLIENT

	EEPF2_BASE   = 0x1,
	EEPF2_CELL   = 0x2,
	EEPF2_CLIENT = 0x4,
    EEPF2_OTHERCLIENTS = 0x8,
};

inline void SetBaseFlag(uint8_t& e)
{
	e |= EEPF2_BASE;
}

inline void SetCellFlag(uint8_t& e)
{
	e |= EEPF2_CELL;
}

inline void SetClientFlag(uint8_t& e)
{
	e |= EEPF2_CLIENT;
}

inline void SetOtherClientsFlag(uint8_t& e)
{
    e |= EEPF2_OTHERCLIENTS;
}

inline bool IsBaseFlag(uint8_t e)
{
	return (e & EEPF2_BASE) > 0;
}

inline bool IsCellFlag(uint8_t e)
{
	return (e & EEPF2_CELL) > 0;
}

inline bool IsClientFlag(uint8_t e)
{
	return (e & EEPF2_CLIENT) > 0;
}

inline bool IsOtherClientsFlag(uint8_t e)
{
    return (e & EEPF2_OTHERCLIENTS) > 0;
}

inline bool IsBaseAndClientFlag(uint8_t e)
{
	return IsClientFlag(e) && IsBaseFlag(e);
}

inline bool IsCellAndClientFlag(uint8_t e)
{
	return IsClientFlag(e) && IsCellFlag(e);
}

struct _SEntityDefProperties
{
    string m_name;
    VTYPE m_nType;          //int8,string,list of ...
    uint8_t m_nFlags;       //base,cell_private,all_clients
    bool m_bSaveDb;         //是否存盘
    string m_defaultValue;  //缺省值

    _SEntityDefProperties();
    _SEntityDefProperties(const _SEntityDefProperties& other);
};

struct _SEntityDefMethods
{
    uint8_t m_nServerId;   //base/cell/client
    bool m_bExposed;       //客户端是否可以调用
    string m_funcName;
    list<VTYPE> m_argsType;

    _SEntityDefMethods();
    _SEntityDefMethods(const _SEntityDefMethods& other);
};

struct SEntityDef
{
    string m_parent;
    string m_strUniqueIndex;
	bool m_bHasCellClient;  //是否拥有client可见的cell属性
    map<string, _SEntityDefProperties*> m_properties; //这个清理指针
    list<_SEntityDefProperties*> m_propertiesList;    //这个不清理指针
    map<string, _SEntityDefMethods*> m_baseMethods;
	map<string, _SEntityDefMethods*> m_cellMethods;
    map<string, _SEntityDefMethods*> m_clientMethods;

    CStr2IntMap m_propertiesMap;
    CStr2IntMap m_baseMethodsMap;
	CStr2IntMap m_cellMethodsMap;
    CStr2IntMap m_clientMethodsMap;

    ~SEntityDef();

};

//mysql db需要的配置数据
struct SDBCfg
{
    string m_strHost;
    string m_strUser;
    string m_strPasswd;
    string m_strDbName;
    uint16_t m_unPort;
};

class CDefParser
{
public:
    CDefParser();
    ~CDefParser();

public:
    void init(const char* pszDefFilePath);

    TENTITYTYPE GetTypeId(const string& tname);
    const string& GetTypeName(TENTITYTYPE tid);

private:
    //解析entities.xml
    void ParseEntitiesXml(const char* pszFileName);
    //解析一个def文件,失败会抛出异常
    SEntityDef* ParseDef(const char* pszDefFn);
    //处理parent关系
    void ParseParent();
    //处理一个entity的所有parent关系
    void ParseEntityParent(const string& strEntity, SEntityDef* pDef);
    //复制一个父类的配置数据到一个entity
    void CopyParentToEntity(SEntityDef* pChild, const SEntityDef* pParent);

private:
    void InitData();

private:
    _SEntityDefProperties* ReadProperty(SEntityDef* pDef, TiXmlElement* node);
    _SEntityDefMethods* ReadMethod(TiXmlElement* node);

public:
    //根据配置文件中的字符串查找相应的类型定义
    VTYPE GetVTypeByStr(const string& s);
    //根据entity类型获取其定义
    const SEntityDef* GetEntityDefByName(const string& );
    const SEntityDef* GetEntityDefByType(TENTITYTYPE t);
    //根据entity类型和属性名获取属性的定义
    const _SEntityDefProperties* GetEntityPropDef(const SEntityDef*, const string&);
    const _SEntityDefProperties* GetEntityPropDef(const string&, const string&);
    //查询一个entity的某个方法的名称
    const string& GetMethodNameById(TENTITYTYPE t, int32_t nFuncId);
	//查询一个entity的某个cell方法的名称
	const string& GetCellMethodNameById(TENTITYTYPE t, int32_t nFuncId);

public:
    void ReadDbCfg(CCfgReader* r);
    inline const SDBCfg& GetDbCfg() const
    {
        return m_dbCfg;
    }

public:
    inline const map<string, TENTITYTYPE>& GetDefTypes() const
    {
        return m_typeStr2Int;
    }

private:
    map<string, TENTITYTYPE> m_typeStr2Int;
    string* m_typeInt2Str;
    uint16_t m_maxtype;
    map<string, SEntityDef*> m_entityDefs;

    map<string, VTYPE> m_propTypeStr2Int;
    SDBCfg m_dbCfg;

};


}




#endif

