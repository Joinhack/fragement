/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：defparse
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：def 文件解析器
//----------------------------------------------------------------*/

#include "defparser.h"
#include "pluto.h"

const string EMPTY_STRING = "";

namespace mogo
{


CStr2IntMap::CStr2IntMap() : m_nNextId(0)
{
}

CStr2IntMap::~CStr2IntMap()
{
}

void CStr2IntMap::AddNewString(const string& s)
{
    m_str2Int.insert(make_pair(s, m_nNextId));
    m_int2Str.push_back(s);
    ++m_nNextId;
}

//预先分配n个缺省值
void CStr2IntMap::Assign(uint32_t n)
{
    for(uint32_t i = 0; i < n; ++i)
    {
        AddNewString("");
    }
}


//直接指定一个id和string的映射
void CStr2IntMap::SetNewString(uint32_t uid, const string& s)
{
    m_str2Int.insert(make_pair(s, uid));
    m_int2Str[uid] = s;
}


const string& CStr2IntMap::GetStrByInt(uint32_t n) const 
{
    if(n < m_nNextId)
    {
        return m_int2Str[n];
    }
    return EMPTY_STRING;
}

int32_t CStr2IntMap::GetIntByStr(const string& s) const
{
    map<string, uint32_t>::const_iterator iter = m_str2Int.find(s);
    if(iter == m_str2Int.end())
    {
        return -1;
    }
    return iter->second;
}


//////////////////////////////////////////////////////////////////////////////////////////

_SEntityDefProperties::_SEntityDefProperties()
{

}

_SEntityDefProperties::_SEntityDefProperties(const _SEntityDefProperties& other)
{
    this->m_name = other.m_name;
    this->m_nType = other.m_nType;
    this->m_nFlags = other.m_nFlags;
    this->m_bSaveDb = other.m_bSaveDb;
    this->m_defaultValue = other.m_defaultValue;
}

_SEntityDefMethods::_SEntityDefMethods()
{

}

_SEntityDefMethods::_SEntityDefMethods(const _SEntityDefMethods& other)
{
    this->m_nServerId = other.m_nServerId;
    this->m_bExposed = other.m_bExposed;
    this->m_funcName = other.m_funcName;

    list<VTYPE>::const_iterator iter = other.m_argsType.begin();
    for(; iter != other.m_argsType.end(); ++iter)
    {
        this->m_argsType.push_back(*iter);
    }
}

SEntityDef::~SEntityDef()
{
    ClearMap(m_properties);
    ClearMap(m_clientMethods);
    ClearMap(m_baseMethods);
}


CDefParser::CDefParser():m_maxtype(0),m_typeInt2Str(NULL)
{
    InitData();
}

CDefParser::~CDefParser()
{
    delete[] m_typeInt2Str;
    ClearMap(m_entityDefs);
}

void CDefParser::InitData()
{
    m_propTypeStr2Int.insert(make_pair("LUA_TABLE", V_LUATABLE));
    m_propTypeStr2Int.insert(make_pair("INT8",    V_INT8));
    m_propTypeStr2Int.insert(make_pair("UINT8",   V_UINT8));
    m_propTypeStr2Int.insert(make_pair("INT16",   V_INT16));
    m_propTypeStr2Int.insert(make_pair("UINT16",  V_UINT16));
    m_propTypeStr2Int.insert(make_pair("INT32",   V_INT32));
    m_propTypeStr2Int.insert(make_pair("UINT32",  V_UINT32));
    //m_propTypeStr2Int.insert(make_pair("INT64",   V_INT64));
    //m_propTypeStr2Int.insert(make_pair("UINT64",  V_UINT64));
    m_propTypeStr2Int.insert(make_pair("FLOAT32", V_FLOAT32));
    //m_propTypeStr2Int.insert(make_pair("FLOAT64", V_FLOAT64));
    m_propTypeStr2Int.insert(make_pair("STRING",  V_STR));
    m_propTypeStr2Int.insert(make_pair("BLOB",    V_BLOB));
	m_propTypeStr2Int.insert(make_pair("LUA_OBJECT", V_LUA_OBJECT));
	m_propTypeStr2Int.insert(make_pair("REDIS_HASH", V_REDIS_HASH));
    //m_propTypeStr2Int.insert(make_pair("MAILBOX", V_ENTITYMB));

}

//根据配置文件中的字符串查找相应的类型定义
VTYPE CDefParser::GetVTypeByStr(const string& s)
{
    map<string, VTYPE>::const_iterator iter = m_propTypeStr2Int.find(s);
    if(iter != m_propTypeStr2Int.end())
    {
        return iter->second;
    }
    else
    {
        return V_TYPE_ERR;
    }
}

void CDefParser::init(const char* pszDefFilePath)
{
    {
        ostringstream oss;
        oss << pszDefFilePath << g_cPathSplit << "entities.xml";
        ParseEntitiesXml(oss.str().c_str());
    }

    map<string, TENTITYTYPE>::const_iterator iter = m_typeStr2Int.begin();
    for(; iter != m_typeStr2Int.end(); ++iter)
    {
        ostringstream oss;
        oss << pszDefFilePath << g_cPathSplit << iter->first << ".def";
        SEntityDef* p = ParseDef(oss.str().c_str());
        m_entityDefs.insert(make_pair(iter->first, p));
    }

    ParseParent();
}

TENTITYTYPE CDefParser::GetTypeId(const string& tname)
{
    map<string, TENTITYTYPE>::const_iterator iter = m_typeStr2Int.find(tname);
    if(iter != m_typeStr2Int.end())
    {
        return iter->second;
    }
    else
    {
        return ENTITY_TYPE_NONE;
    }
}


const string& CDefParser::GetTypeName(TENTITYTYPE tid)
{
    if(tid <= m_maxtype )
    {
        return m_typeInt2Str[tid];
    }
    else
    {
        return EMPTY_STRING;
    }
}


//解析entities.xml
void CDefParser::ParseEntitiesXml(const char* pszFileName)
{
    TiXmlDocument doc;
    if(!doc.LoadFile(pszFileName))
    {
        ThrowException(-1, "Failed to parse file: %s .", pszFileName);
    }

    TiXmlElement* root = doc.RootElement();
    TiXmlElement* ety = root->FirstChildElement();
    //生成entity类型名称和编号的对应关系
    TENTITYTYPE nEntityTypeNo = 0;
    for(; ety != NULL; ety = ety->NextSiblingElement())
    {
        m_typeStr2Int.insert(make_pair(ety->Value(), ++nEntityTypeNo));
    }

    m_maxtype = (uint16_t)(1+m_typeStr2Int.size());
    m_typeInt2Str = new string[m_maxtype];
    m_typeInt2Str[0] = EMPTY_STRING;

    //entity类型编号和名称的对应关系
    map<string, TENTITYTYPE>::const_iterator iter = m_typeStr2Int.begin();
    for(; iter != m_typeStr2Int.end(); ++iter)
    {
        m_typeInt2Str[iter->second] = iter->first;
    }
}

SEntityDef* CDefParser::ParseDef(const char* pszDefFn)
{
    TiXmlDocument doc;
    if(!doc.LoadFile(pszDefFn))
    {
        ThrowException(-1, "Failed to parse def file: %s.", pszDefFn);
    }

    TiXmlElement* root = doc.RootElement();
    SEntityDef* pDef = new SEntityDef;
	pDef->m_bHasCellClient = false;

    //parent
    TiXmlElement* parent = root->FirstChildElement("parent");
    if(parent)
    {
        pDef->m_parent.assign(parent->GetText());
    }
    else
    {
        pDef->m_parent = "";
    }

    //Properties
    TiXmlElement* props = root->FirstChildElement("Properties");
    if(props)
    {
        TiXmlElement* field = props->FirstChildElement();
        for(; field != NULL; field = field->NextSiblingElement())
        {
            _SEntityDefProperties* pProp = ReadProperty(pDef, field);
			//todo,检查有无重复的字段名
            pDef->m_properties.insert(make_pair(pProp->m_name, pProp));
            pDef->m_propertiesList.push_back(pProp);
            pDef->m_propertiesMap.AddNewString(field->Value());
        }
    }

    //ClientMethods
    TiXmlElement* methods = root->FirstChildElement("ClientMethods");
    if(methods)
    {
        TiXmlElement* m = methods->FirstChildElement();
        for(; m != NULL; m = m->NextSiblingElement())
        {
            _SEntityDefMethods* p = ReadMethod(m);
            p->m_nServerId = SERVER_CLIENT;
            pDef->m_clientMethods.insert(make_pair(p->m_funcName, p));
            pDef->m_clientMethodsMap.AddNewString(p->m_funcName);
        }
    }

    //BaseMethods
    methods = root->FirstChildElement("BaseMethods");
    if(methods)
    {
        TiXmlElement* m = methods->FirstChildElement();
        for(; m != NULL; m = m->NextSiblingElement())
        {
            _SEntityDefMethods* p = ReadMethod(m);
            p->m_nServerId = SERVER_BASEAPP;
            pDef->m_baseMethods.insert(make_pair(p->m_funcName, p));
            pDef->m_baseMethodsMap.AddNewString(p->m_funcName);
        }
    }

    //CellMethods
	methods = root->FirstChildElement("CellMethods");
	if(methods)
	{
		TiXmlElement* m = methods->FirstChildElement();
		for(; m != NULL; m = m->NextSiblingElement())
		{
			_SEntityDefMethods* p = ReadMethod(m);
			p->m_nServerId = SERVER_CELLAPP;
			pDef->m_cellMethods.insert(make_pair(p->m_funcName, p));
			pDef->m_cellMethodsMap.AddNewString(p->m_funcName);
		}
	}

    return pDef;
}


//处理parent关系
void CDefParser::ParseParent()
{
    map<string, SEntityDef*>::iterator iter = m_entityDefs.begin();
    for(; iter != m_entityDefs.end(); ++iter)
    {
        const string& strEntity = iter->first;
        SEntityDef* pDef = iter->second;

        //如果有基类
        if(!pDef->m_parent.empty())
        {
            ParseEntityParent(strEntity, pDef);
        }
    }
}

//处理一个entity的所有parent关系
void CDefParser::ParseEntityParent(const string& strEntity, SEntityDef* pDef)
{
    set<string> parents;

    string strChild = strEntity;
    const SEntityDef* pChild = pDef;
    for(;!pChild->m_parent.empty();)
    {
        //是否有循环的父类存在
        set<string>::const_iterator iter = parents.find(pChild->m_parent);
        if(iter != parents.end())
        {
            ThrowException(-1, "%s has circle parent '%s' ", strChild.c_str(), pChild->m_parent.c_str());
        }

        //父类未定义
        const SEntityDef* pParent = GetEntityDefByName(pChild->m_parent);
        if(pParent == NULL)
        {
            ThrowException(-1, "%s' parent '%s' not define!", strChild.c_str(), pChild->m_parent.c_str());
        }     

        //复制父类(或更高层次的父类)的属性到entity
        CopyParentToEntity(pDef, pParent);

        //继续处理父类的父类 
        parents.insert(pChild->m_parent);
        strChild = pChild->m_parent;
        pChild = pParent;
    }

}

//复制一个父类的配置数据到一个entity
void CDefParser::CopyParentToEntity(SEntityDef* pChild, const SEntityDef* pParent)
{
    //properties
    {
        map<string, _SEntityDefProperties*>::const_iterator iter = pParent->m_properties.begin();
        for(; iter != pParent->m_properties.end(); ++iter)
        {
            const string& strPropName = iter->first;
            if(pChild->m_properties.find(strPropName) == pChild->m_properties.end())
            {
                //子类已经有这个定义了,以子类的为准;子类未定义,使用父类的定义
                _SEntityDefProperties* pCopy = new _SEntityDefProperties(*(iter->second));
                pChild->m_properties.insert(make_pair(strPropName, pCopy));
                pChild->m_propertiesList.push_back(pCopy);
                pChild->m_propertiesMap.AddNewString(strPropName);
            }
        }
    }
    //client methods不用继承
    //base methods
    {
        map<string, _SEntityDefMethods*>::const_iterator iter = pParent->m_baseMethods.begin();
        for(; iter != pParent->m_baseMethods.end(); ++iter)
        {
            const string& strMethodName = iter->first;
            if(pChild->m_baseMethods.find(strMethodName) == pChild->m_baseMethods.end())
            {
                _SEntityDefMethods* pCopy = new _SEntityDefMethods(*(iter->second));
                pChild->m_baseMethods.insert(make_pair(strMethodName, pCopy));
                pChild->m_baseMethodsMap.AddNewString(strMethodName);
            }
        }
    }
	//cell methods
	{
		map<string, _SEntityDefMethods*>::const_iterator iter = pParent->m_cellMethods.begin();
		for(; iter != pParent->m_cellMethods.end(); ++iter)
		{
			const string& strMethodName = iter->first;
			if(pChild->m_cellMethods.find(strMethodName) == pChild->m_cellMethods.end())
			{
				_SEntityDefMethods* pCopy = new _SEntityDefMethods(*(iter->second));
				pChild->m_cellMethods.insert(make_pair(strMethodName, pCopy));
				pChild->m_cellMethodsMap.AddNewString(strMethodName);
			}
		}
	}
}

_SEntityDefProperties* CDefParser::ReadProperty(SEntityDef* pDef, TiXmlElement* node)
{
    _SEntityDefProperties* pProp = new _SEntityDefProperties;
    pProp->m_name.assign(node->Value());

    TiXmlElement* field_attri = node->FirstChildElement("Type");
    if(field_attri)
    {
        const char* szTypeName = field_attri->GetText();
        VTYPE vt = GetVTypeByStr(szTypeName);
        if(vt != V_TYPE_ERR)
        {
            pProp->m_nType = vt;
        }
        //else if(strcmp(szTypeName, "ARRAY") == 0)
        //{
        //    //array of ***特殊处理
        //}
        else
        {
            //未定义的类型
            ThrowException(-1, "Property '%s' has unsupported type: '%s'.", 
                pProp->m_name.c_str(), szTypeName);
        }
    }

    //Flags
    pProp->m_nFlags = 0;
	field_attri = node->FirstChildElement("Flags");
	if(field_attri)
	{
		const char* _szFlag = field_attri->GetText();
		if(UpperStrCmp(_szFlag, "BASE"))
		{
			SetBaseFlag(pProp->m_nFlags);
		}
		else if(UpperStrCmp(_szFlag, "BASE_AND_CLIENT"))
		{
			SetBaseFlag(pProp->m_nFlags);
			SetClientFlag(pProp->m_nFlags);
		}
		else if(UpperStrCmp(_szFlag, "CELL"))
		{
			SetCellFlag(pProp->m_nFlags);
		}
		else if(UpperStrCmp(_szFlag, "CELL_AND_CLIENT"))
		{
			SetCellFlag(pProp->m_nFlags);
			SetClientFlag(pProp->m_nFlags);
			pDef->m_bHasCellClient = true;
		}
        else if(UpperStrCmp(_szFlag, "ALL_CLIENTS"))
        {
            SetCellFlag(pProp->m_nFlags);
            SetClientFlag(pProp->m_nFlags);
            SetOtherClientsFlag(pProp->m_nFlags);
            pDef->m_bHasCellClient = true;
        }
        else if(UpperStrCmp(_szFlag, "OTHER_CLIENTS"))
        {
            //注意和all_clients的区别
            SetCellFlag(pProp->m_nFlags);
            //setClientFlag(pProp->m_nFlags);
            SetOtherClientsFlag(pProp->m_nFlags);
            //pDef->m_bHasCellClient = false;
        }
		else
		{
			ThrowException(-1, "unknown properties flag:%s", _szFlag);
		}
	}

	//该字段是否base和cell共有的字段
	field_attri = node->FirstChildElement("BaseAndCell");
	if(field_attri)
	{
		if(UpperStrCmp(field_attri->GetText(), "TRUE"))
		{
			SetCellFlag(pProp->m_nFlags);
			SetBaseFlag(pProp->m_nFlags);
		}
	}

    //该字段是否保存到数据库
    field_attri = node->FirstChildElement("Persistent");
    if(field_attri)
    {
		if(UpperStrCmp(field_attri->GetText(), "TRUE"))
        {
            pProp->m_bSaveDb = true;

			//cell属性不能有存盘标记(除非是cell和base共有的属性)
			if(IsCellFlag(pProp->m_nFlags) && !IsBaseFlag(pProp->m_nFlags))
			{
				ThrowException(-1, "CELL(but Base) properties cant set Persistent to TRUE");
			}
        }
        else
        {
            pProp->m_bSaveDb = false;
        }
    }
    else
    {
        pProp->m_bSaveDb = false;
    }

    //该字段是否有缺省值
    field_attri = node->FirstChildElement("Default");
    if(field_attri)
    {
        pProp->m_defaultValue.assign(field_attri->GetText());
    }
    else
    {
        pProp->m_defaultValue.assign("");
    }

    //该字段是否创建唯一索引
    field_attri = node->FirstChildElement("UniqueIndex");
    if(field_attri)
    {
        if(pDef->m_strUniqueIndex.empty())
        {
            pDef->m_strUniqueIndex.assign(node->Value());
        }
        else
        {
            //多个字段申明了唯一索引
            ThrowException(-1, "At least two properties set unique_index, '%s' vs '%s'", \
                pDef->m_strUniqueIndex.c_str(), node->Value());
        }
    }

    return pProp;
}

_SEntityDefMethods* CDefParser::ReadMethod(TiXmlElement* node)
{
    _SEntityDefMethods* p = new _SEntityDefMethods;
    p->m_funcName.assign(node->Value());

    TiXmlElement* e = node->FirstChildElement("Exposed");
    if(e)
    {
        p->m_bExposed = true;
    }
    else
    {
        p->m_bExposed = false;
    }

    e = node->FirstChildElement("Arg");
    for(; e != NULL; e = e->NextSiblingElement("Arg"))
    {
        const char* s = e->GetText();
        VTYPE vt = GetVTypeByStr(s);
        if(vt != V_TYPE_ERR)
        {
            p->m_argsType.push_back(vt);
        }
        else
        {
            ThrowException(-1, "Method '%s' has a error Arg type '%s'.", 
                p->m_funcName.c_str(), s);
        }
    }

    return p;
}

//根据entity类型获取其定义
const SEntityDef* CDefParser::GetEntityDefByName(const string& strEntityName)
{
    map<string, SEntityDef*>::const_iterator iter = m_entityDefs.find(strEntityName);
    if(iter == m_entityDefs.end())
    {
        return NULL;
    }
    else
    {
        return iter->second;
    }
}

const SEntityDef* CDefParser::GetEntityDefByType(TENTITYTYPE t)
{
    const string& strEntityName = this->GetTypeName(t);
    const SEntityDef* pDef = this->GetEntityDefByName(strEntityName);
    return pDef;
}

//根据entity类型和属性名获取属性的定义
const _SEntityDefProperties* CDefParser::GetEntityPropDef(const SEntityDef* p,
                                                          const string& strPropName)
{
    map<string, _SEntityDefProperties*>::const_iterator iter = p->m_properties.find(strPropName);
    if(iter == p->m_properties.end())
    {
        return NULL;
    }
    else
    {
        return iter->second;
    }
}

const _SEntityDefProperties* CDefParser::GetEntityPropDef(const string& strEntityName,
                                                          const string& strPropName)
{
    const SEntityDef* p = GetEntityDefByName(strEntityName);
    if(p)
    {
        return GetEntityPropDef(p, strPropName);
    }

    return NULL;
}

void CDefParser::ReadDbCfg(CCfgReader* r)
{
    m_dbCfg.m_strHost = r->GetValue("db", "host");
    m_dbCfg.m_strUser = r->GetValue("db", "user");
    m_dbCfg.m_strPasswd = r->GetValue("db", "passwd");
    m_dbCfg.m_unPort = atoi(r->GetValue("db", "port").c_str());
    m_dbCfg.m_strDbName = r->GetValue("db", "db");
}

//查询一个entity的某个方法的名称
const string& CDefParser::GetMethodNameById(TENTITYTYPE t, int32_t nFuncId)
{
    const SEntityDef* p = GetEntityDefByType(t);
    if(p)
    {
        return p->m_baseMethodsMap.GetStrByInt(nFuncId);
    }

    return EMPTY_STRING;
}

//查询一个entity的某个cell方法的名称
const string& CDefParser::GetCellMethodNameById(TENTITYTYPE t, int32_t nFuncId)
{
	const SEntityDef* p = GetEntityDefByType(t);
	if(p)
	{
		return p->m_cellMethodsMap.GetStrByInt(nFuncId);
	}

	return EMPTY_STRING;
}

}
