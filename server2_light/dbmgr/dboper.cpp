#ifdef _WIN32
#include <winsock.h>
#endif

#include "dboper.h"
#include "rpc_mogo.h"
#include "world_select.h"
#include "world_dbmgr.h"

#ifdef __TEST
#include "util.h"
#endif



namespace mogo
{

    extern bool PushVObjectToOstream(MYSQL* mysql, ostringstream& oss, VOBJECT& v);


#ifdef _USE_REDIS
    CDbOper::CDbOper(int seq) : m_bConnectDb(false), m_redis(), m_bFirstThread(seq==0)
#else
    CDbOper::CDbOper(int seq) : m_bConnectDb(false), m_bFirstThread(seq==0)
#endif
    {
        InitTypeMap();
        m_mysql = mysql_init(NULL);
    }

    CDbOper::~CDbOper()
    {
    }

    void CDbOper::DisConnect()
    {
        mysql_close(m_mysql);

#ifdef _USE_REDIS
        if(m_bFirstThread)
        {
            m_redis.DisConnectAndBgSave();
        }
        else
        {
            m_redis.DisConnect();
        }
#endif
    }

    void CDbOper::InitTypeMap()
    {
        m_typeMap.Assign(V_MAX_VTYPE);
        m_typeMap.SetNewString((uint32_t)V_UINT8,   "tinyint(3) unsigned");
        m_typeMap.SetNewString((uint32_t)V_INT8,    "tinyint(4)");
        m_typeMap.SetNewString((uint32_t)V_UINT16,  "smallint(5) unsigned");
        m_typeMap.SetNewString((uint32_t)V_INT16,   "smallint(6)");
        m_typeMap.SetNewString((uint32_t)V_UINT32,  "int(10) unsigned");
        m_typeMap.SetNewString((uint32_t)V_INT32,   "int(11)");
        m_typeMap.SetNewString((uint32_t)V_UINT64,  "bigint(20) unsigned");
        m_typeMap.SetNewString((uint32_t)V_INT64,   "bigint(20)");
        m_typeMap.SetNewString((uint32_t)V_FLOAT32, "float");
        m_typeMap.SetNewString((uint32_t)V_FLOAT64, "double");
        m_typeMap.SetNewString((uint32_t)V_STR,     "varchar(255)");
        m_typeMap.SetNewString((uint32_t)V_BLOB,    "tinyblob");
        //m_typeMap.SetNewString((uint32_t)V_MBLOB,    "mediumblob");
        m_typeMap.SetNewString((uint32_t)V_LUATABLE, "longblob");
    }

    const string& CDbOper::GetPropDbType(VTYPE vt)
    {
        return m_typeMap.GetStrByInt(vt);
    }

    bool CDbOper::MakeCreateSql(const string& strEntity, string& strSql)
    {
        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(strEntity);
        if(pDef)
        {
            ostringstream oss;
            oss << "CREATE TABLE `tbl_" << strEntity << "` ( `id` bigint NOT NULL AUTO_INCREMENT,`timestamp` int(11),";

            list<_SEntityDefProperties*>::const_iterator iter = pDef->m_propertiesList.begin();
            for(; iter != pDef->m_propertiesList.end(); ++iter)
            {
                const _SEntityDefProperties* pProp = *iter;
                if(pProp->m_bSaveDb)
                {
                    oss << "`sm_" << pProp->m_name << "` " << GetPropDbType(pProp->m_nType) << " ,";
                }
            }

            oss << " PRIMARY KEY (`id`)";

            if(!pDef->m_strUniqueIndex.empty())
            {
                oss << ",UNIQUE KEY `sm_" << pDef->m_strUniqueIndex << "`(`sm_" << pDef->m_strUniqueIndex << "`)";
            }

            oss << ") ENGINE=InnoDB row_format=dynamic DEFAULT CHARSET=utf8 COLLATE utf8_bin";
            strSql.assign(oss.str());
        }

        return pDef != NULL;
    }

    //根据pluto解包出来的字段生成insert语句
    bool CDbOper::MakeInsertSql(const string& strEntity, const map<string, VOBJECT*>& props, string& strSql)
    {
        ostringstream oss;
        ostringstream oss2;
        oss << "INSERT INTO tbl_" << strEntity << " (timestamp";
        oss2 << " values (" << (int)time(NULL) ;

        int i = 0;
        map<string, VOBJECT*>::const_iterator iter = props.begin();
        for(; iter != props.end(); ++iter)
        {
            oss << ", ";
            oss2 << ", ";
            oss << "sm_" << iter->first;

            VOBJECT* p = iter->second;
            PushVObjectToOstream(m_mysql, oss2, *p);
        }
        oss << ")";
        oss2 << ")";

        oss << oss2.str();

        strSql.assign(oss.str());

        return true;
    }

    //根据pluto解包出来的字段生成insert语句
    bool CDbOper::MakeUpdateSql(const string& strEntity, const map<string, VOBJECT*>& props,
                                TDBID dbid, string& strSql)
    {
        ostringstream oss;
        oss << "UPDATE tbl_" << strEntity << " SET timestamp=" << (int)time(NULL);

        int i = 0;
        map<string, VOBJECT*>::const_iterator iter = props.begin();
        for(; iter != props.end(); ++iter)
        {
            oss << ", ";
            oss << "sm_" << iter->first << "=";

            VOBJECT* p = iter->second;
            PushVObjectToOstream(m_mysql, oss, *p);
        }
        oss << " where id=" << dbid;
        strSql.assign(oss.str());

        return true;
    }

    bool CDbOper::Connect(const SDBCfg& cfg, const SRedisCfg& redisCfg, string& strErr)
    {
        int ml_outtime = 10;
        mysql_options(m_mysql, MYSQL_OPT_CONNECT_TIMEOUT, &ml_outtime);

        if(0 != mysql_options(m_mysql,MYSQL_SET_CHARSET_NAME,"utf8"))//设置字符集utf8
        {
            m_bConnectDb = false;
            strErr.assign(mysql_error(m_mysql));
        }

        if( mysql_real_connect(m_mysql, cfg.m_strHost.c_str(), cfg.m_strUser.c_str(), cfg.m_strPasswd.c_str(),
                               cfg.m_strDbName.c_str(), cfg.m_unPort, NULL, 0) == NULL)
        {
            m_bConnectDb = false;
            strErr.assign(mysql_error(m_mysql));
        }
        else
        {
            string strSql = "set interactive_timeout=24*3600";
            int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
            if(nRet != 0)
            {
                m_bConnectDb = false;
                strErr.assign(mysql_error(m_mysql));
            }
        }
#ifdef _USE_REDIS
        {
            m_bConnectDb = m_redis.Connect("127.0.0.1", redisCfg.m_unPort, redisCfg.m_unDbId);
        }
#else
        {
            m_bConnectDb = true;
        }
#endif

        return m_bConnectDb;
    }

    //插入一个entity
    TDBID CDbOper::InsertEntity(const string& strEntity, const map<string, VOBJECT*>& props, string& strErr)
    {
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return 0;
        }

        string strSql;
        if(!MakeInsertSql(strEntity, props, strSql))
        {
            strErr.assign("MakeInsertSql error");
            return 0;
        }

        //LogDebug("CDbOper::InsertEntity", "strSql=%s", strSql.c_str());

        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return 0;
        }


        TDBID newid = (TDBID)mysql_insert_id(m_mysql);
        //printf("newid:%d\n", newid);

#ifdef _USE_REDIS
        //redis更新
        m_redis.UpdateEntity(strEntity, props, newid);
#endif

        return newid;
    }

    int CDbOper::UpdateEntity(const string& strEntity, const map<string, VOBJECT*>& props,
                              TDBID dbid, string& strErr)
    {
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return -1;
        }

        string strSql;
        if(!MakeUpdateSql(strEntity, props, dbid, strSql))
        {
            strErr.assign("MakeUpdateSql error");
            return -2;
        }

        //LogDebug("CDbOper::UpdateEntity", "strSql=%s", strSql.c_str());

        //g_logger.newLine() << strSql << endLine;

        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return -3;
        }

        //数据库存盘结果,如果一条记录没有更新,mysql_affected_rows返回0
        int nDbRet = mysql_affected_rows(m_mysql) ==  1 ? 0 : -4 ;

#ifdef _USE_REDIS
        //无轮数据库存盘结果如何,redis都更新
        m_redis.UpdateEntity(strEntity, props, dbid);
#endif

        return nDbRet;
    }

    int CDbOper::UpdateEntityToRedis(const string& strEntity, const map<string, VOBJECT*>& props,
                                     TDBID dbid, string& strErr)
    {
//#ifdef _USE_REDIS
//        //无轮数据库存盘结果如何,redis都更新
//        m_redis.UpdateEntity(strEntity, props, dbid);
//#else
        //定时存盘改为mysql和redis一起更新
        return UpdateEntity(strEntity, props, dbid, strErr);
//#endif

        return 0;
    }

    int CDbOper::LookupEntityByDbId(const string& strEntity, TDBID dbid, int32_t ref,
                                    CPluto& u, string& strErr)
    {
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return -1;
        }

        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(strEntity);
        if(pDef == NULL)
        {
            strErr.assign("entity not define");
            return -2;
        }

        //todo,preparestatement
        static const char* pszSql = "select * from tbl_";
        ostringstream oss;
        oss << pszSql << strEntity << " where id=" << dbid;
        const string& strSql = oss.str();
        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return -3;
        }

        MYSQL_RES *result = mysql_store_result(m_mysql);
        int num_fields = mysql_num_fields(result);
        vector<string> vtFields;
        vtFields.reserve(num_fields);

        MYSQL_FIELD * fd;
        for(int i=0; fd = mysql_fetch_field(result); ++i)
        {
            char* s = fd->name;
            //printf("field_name=%s\n", s);

            size_t ls = strlen(s);
            if(ls > 3 && strncmp(s, "sm_", 3) == 0)
            {
                vtFields.push_back(string(s+3, ls-3));
            }
            else
            {
                vtFields.push_back(s);
            }
        }

        //CPluto u;
        u.Encode(MSGID_BASEAPP_SELECT_ENTITY_CALLBACK);
        u << dbid << ref;
        u << GetWorld()->GetDefParser().GetTypeId(strEntity);

        const map<string, _SEntityDefProperties*>& props = pDef->m_properties;
        MYSQL_ROW row;
        TDBID dbid2 = 0;
        while ((row = mysql_fetch_row(result)))
        {
            unsigned long *lengths;
            lengths = mysql_fetch_lengths(result);

            for(int i = 0; i < num_fields; i++)
            {
                char* s = row[i];
                //printf("%i, %s ", (int)lengths[i], s ? s : "NULL");

                const string& strFieldName = vtFields[i];

                if(strFieldName.compare("id") == 0)
                {
                    dbid2 = (TDBID)atol(s);
                }
                else
                {
                    map<string, _SEntityDefProperties*>::const_iterator iter = \
                            props.find(strFieldName);
                    if(iter != props.end())
                    {
                        const _SEntityDefProperties* p = iter->second;
                        u << (uint16_t)pDef->m_propertiesMap.GetIntByStr(iter->first);
                        u.FillPlutoFromStr(p->m_nType, s, lengths[i]);
                    }
                }
            }
            //printf("\n");
        }

        u << EndPluto;
        //PrintHexPluto(u);

        mysql_free_result(result);

        return 0;
    }

    int CDbOper::LookupEntityByName(uint8_t nCreateFlag, const string& strEntity, const string& strKey,
                                    TENTITYID eid, CPluto& u, uint16_t& nBaseappId,string& strErr)
    {
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return -1;
        }

        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(strEntity);
        if(pDef == NULL)
        {
            strErr.assign("entity not define");
            return -2;
        }

        //todo,preparestatement
        static const char* pszSql = "select * from tbl_";
        ostringstream oss;
        oss << pszSql << strEntity << " where sm_" << pDef->m_strUniqueIndex << "='" << strKey << "'";
        const string& strSql = oss.str();
        LogWarning("sql:", "%s", strErr.c_str());
        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return -3;
        }

        MYSQL_RES *result = mysql_store_result(m_mysql);
        int num_fields = mysql_num_fields(result);
        vector<string> vtFields;
        vtFields.reserve(num_fields);

        MYSQL_FIELD * fd;
        for(int i=0; fd = mysql_fetch_field(result); ++i)
        {
            char* s = fd->name;
            //printf("field_name=%s\n", s);

            size_t ls = strlen(s);
            if(ls > 3 && strncmp(s, "sm_", 3) == 0)
            {
                vtFields.push_back(string(s+3, ls-3));
            }
            else
            {
                vtFields.push_back(s);
            }
        }

        //为了load完所有Avatar后,Account能关联到自己的Avatar特殊写的一段代码
        TENTITYID nOtherEntityId = 0;
        const static string strAccount = "Account";
        if(strEntity == strAccount)
        {
            SEntityLookup* _pAvatar = ((CWorldDbmgr*)GetWorld())->LookupAvatarByAccount(strKey);
            if(_pAvatar)
            {
                nOtherEntityId = _pAvatar->eid;
                nBaseappId = _pAvatar->sid;
            }
        }

        //CPluto u;
        u.Encode(MSGID_BASEAPP_LOOKUP_ENTITY_CALLBACK);
        u << (uint64_t)0 << eid << nCreateFlag << strKey.c_str() << nOtherEntityId;
        u << GetWorld()->GetDefParser().GetTypeId(strEntity);

        const map<string, _SEntityDefProperties*>& props = pDef->m_properties;
        MYSQL_ROW row;
        TDBID dbid2 = 0;
        while ((row = mysql_fetch_row(result)))
        {
            unsigned long *lengths;
            lengths = mysql_fetch_lengths(result);

            for(int i = 0; i < num_fields; i++)
            {
                char* s = row[i];
                //printf("%i, %s ", (int)lengths[i], s ? s : "NULL");

                const string& strFieldName = vtFields[i];

                if(strFieldName.compare("id") == 0)
                {
                    dbid2 = (TDBID)atol(s);
                }
                else
                {
                    map<string, _SEntityDefProperties*>::const_iterator iter = \
                            props.find(strFieldName);
                    if(iter != props.end())
                    {
                        const _SEntityDefProperties* p = iter->second;
                        u << (uint16_t)pDef->m_propertiesMap.GetIntByStr(iter->first);
                        u.FillPlutoFromStr(p->m_nType, s, lengths[i]);
                    }
                }
            }
            //printf("\n");

            break;
        }

        u.ReplaceField(PLUTO_FILED_BEGIN_POS, dbid2);
        u << EndPluto;
        //PrintHexPluto(u);

        mysql_free_result(result);

        return 0;
    }

    //读取所有Avatar
    int CDbOper::LoadAllAvatars(const string& strEntity, const string& strIndex, string& strErr)
    {
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return -1;
        }

        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(strEntity);
        if(pDef == NULL)
        {
            strErr.assign("entity not define");
            return -2;
        }

        //todo,preparestatement
        static const char* pszSql = "select * from tbl_";
        ostringstream oss;
        oss << pszSql << strEntity;
        const string& strSql = oss.str();
        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return -3;
        }

        MYSQL_RES *result = mysql_store_result(m_mysql);
        int num_fields = mysql_num_fields(result);
        vector<string> vtFields;
        vtFields.reserve(num_fields);

        MYSQL_FIELD * fd;
        for(int i=0; fd = mysql_fetch_field(result); ++i)
        {
            char* s = fd->name;
            //printf("field_name=%s\n", s);

            size_t ls = strlen(s);
            if(ls > 3 && strncmp(s, "sm_", 3) == 0)
            {
                vtFields.push_back(string(s+3, ls-3));
            }
            else
            {
                vtFields.push_back(s);
            }
        }

        const map<string, _SEntityDefProperties*>& props = pDef->m_properties;
        MYSQL_ROW row;
        TDBID dbid2 = 0;
        int j = 0;
        CWorldDbmgr& the_world = (CWorldDbmgr&)*GetWorld();
        CDefParser& defparser = the_world.GetDefParser();
        TENTITYTYPE entity_typeid = defparser.GetTypeId(strEntity);
        while ((row = mysql_fetch_row(result)))
        {
            TENTITYID eid = the_world.GetNextEntityId();
            uint16_t nBaseappId = the_world.ChooseABaseApp();
            string strAccountName;
            CPluto* u = new CPluto;
            u->Encode(MSGID_BASEAPP_LOAD_ALL_AVATAR);
            (*u) << (uint64_t)0 << eid << entity_typeid;

            unsigned long *lengths;
            lengths = mysql_fetch_lengths(result);

            for(int i = 0; i < num_fields; i++)
            {
                char* s = row[i];
                //printf("%i, %s ", (int)lengths[i], s ? s : "NULL");

                const string& strFieldName = vtFields[i];

                if(strFieldName.compare("id") == 0)
                {
                    dbid2 = (TDBID)atol(s);
                }
                else
                {
                    //保存为account做索引的字段值
                    if(strFieldName == strIndex)
                    {
                        strAccountName.assign(s);
                    }

                    map<string, _SEntityDefProperties*>::const_iterator iter = \
                            props.find(strFieldName);
                    if(iter != props.end())
                    {
                        const _SEntityDefProperties* p = iter->second;
                        (*u) << (uint16_t)pDef->m_propertiesMap.GetIntByStr(iter->first);
                        u->FillPlutoFromStr(p->m_nType, s, lengths[i]);
                    }
                }
            }
            //printf("\n");
            ++j;
            //break;

            u->ReplaceField(PLUTO_FILED_BEGIN_POS, dbid2);
            (*u) << EndPluto;

            //加入查找表
            the_world.CreateNewAvatarToLookup(strAccountName, eid, nBaseappId);
            //发给每个baseapp
            CMailBox* mb = the_world.GetServerMailbox(nBaseappId);
            if(mb)
            {
                u->SetMailbox(mb);

                //LogDebug("CDbOper::LoadAllAvatars", "u.GenLen()=%d", u->GetLen());

                g_pluto_sendlist.PushPluto(u);
            }
            else
            {
                LogWarning("CDbOper::LoadAllAvatars", "");
                delete u;
            }

        }

        //print_hex_pluto(u);

        //printf("loadAll:%d\n", j);
        //结束包
        {
            uint16_t nBaseappId = the_world.ChooseABaseApp();       //随便选一个baseapp
            CMailBox* mb = the_world.GetServerMailbox(nBaseappId);
            if(mb)
            {
                CPluto* uu = new CPluto;
                uu->Encode(MSGID_BASEAPP_LOAD_ENTITIES_END_MSG);
                (*uu) << strEntity.c_str() << j << EndPluto;

                uu->SetMailbox(mb);

                //LogDebug("CDbOper::LoadAllAvatars", "u.GenLen()=%d", uu->GetLen());

                g_pluto_sendlist.PushPluto(uu);
            }
        }

        mysql_free_result(result);

        return 0;
    }

    //读取某个表的所有entity
    int CDbOper::LoadAllEntitiesOfType(const string& strEntity, uint16_t nBaseappId, string& strErr)
    {
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return -1;
        }

        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(strEntity);
        if(pDef == NULL)
        {
            strErr.assign("entity not define");
            return -2;
        }

        //todo,preparestatement
        static const char* pszSql = "select * from tbl_";
        ostringstream oss;
        oss << pszSql << strEntity;
        const string& strSql = oss.str();
        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return -3;
        }

        MYSQL_RES *result = mysql_store_result(m_mysql);
        int num_fields = mysql_num_fields(result);
        vector<string> vtFields;
        vtFields.reserve(num_fields);

        MYSQL_FIELD * fd;
        for(int i=0; fd = mysql_fetch_field(result); ++i)
        {
            char* s = fd->name;
            //printf("field_name=%s\n", s);

            size_t ls = strlen(s);
            if(ls > 3 && strncmp(s, "sm_", 3) == 0)
            {
                vtFields.push_back(string(s+3, ls-3));
            }
            else
            {
                vtFields.push_back(s);
            }
        }

        const map<string, _SEntityDefProperties*>& props = pDef->m_properties;
        MYSQL_ROW row;
        TDBID dbid2 = 0;
        int j = 0;
        CWorldDbmgr& the_world = (CWorldDbmgr&)*GetWorld();
        CDefParser& defparser = the_world.GetDefParser();
        TENTITYTYPE entity_typeid = defparser.GetTypeId(strEntity);
        while ((row = mysql_fetch_row(result)))
        {
            TENTITYID eid = the_world.GetNextEntityId();
            CPluto* u = new CPluto;
            u->Encode(MSGID_BASEAPP_LOAD_ENTITIES_OF_TYPE);
            (*u) << (uint64_t)0 << eid << entity_typeid;

            unsigned long *lengths;
            lengths = mysql_fetch_lengths(result);

            for(int i = 0; i < num_fields; i++)
            {
                char* s = row[i];
                //printf("%i, %s ", (int)lengths[i], s ? s : "NULL");

                const string& strFieldName = vtFields[i];

                if(strFieldName.compare("id") == 0)
                {
                    dbid2 = (TDBID)atol(s);
                }
                else
                {
                    map<string, _SEntityDefProperties*>::const_iterator iter = \
                            props.find(strFieldName);
                    if(iter != props.end())
                    {
                        const _SEntityDefProperties* p = iter->second;
                        (*u) << (uint16_t)pDef->m_propertiesMap.GetIntByStr(iter->first);
                        u->FillPlutoFromStr(p->m_nType, s, lengths[i]);
                    }
                }
            }
            //printf("\n");
            ++j;
            //break;

            u->ReplaceField(PLUTO_FILED_BEGIN_POS, dbid2);
            (*u) << EndPluto;

            //发给每个baseapp
            CMailBox* mb = the_world.GetServerMailbox(nBaseappId);
            if(mb)
            {
                u->SetMailbox(mb);

                //LogDebug("CDbOper::LoadAllEntitiesOfType", "u.GenLen()=%d", u->GetLen());

                g_pluto_sendlist.PushPluto(u);
            }
            else
            {
                LogWarning("CDbOper::LoadAllEntitiesOfType", "");
                delete u;
            }

        }

        //printf("loadAll:%d\n", j);

        //结束包
        {
            CMailBox* mb = the_world.GetServerMailbox(nBaseappId);
            if(mb)
            {
                CPluto* uu = new CPluto;
                uu->Encode(MSGID_BASEAPP_LOAD_ENTITIES_END_MSG);
                (*uu) << strEntity.c_str() << j << EndPluto;

                uu->SetMailbox(mb);
                g_pluto_sendlist.PushPluto(uu);
            }
        }

        mysql_free_result(result);

        return 0;
    }

	int CDbOper::SelectAccount(int32_t fd,const char* pszAccount, CPluto& u, string& strErr)
	{
		if(!m_bConnectDb)
		{
			strErr.assign("db not connected");
			return 0;
		}

		//任意帐号都通过验证
		u.Encode(MSGID_LOGINAPP_SELECT_ACCOUNT_CALLBACK) << fd << pszAccount << (uint8_t)1 << EndPluto;
		return 0;
	}

int CDbOper::insertAccount(const std::string &account, const std::string &password) {
	std::ostringstream oss;
	char rs[65535];
	oss << "insert account(account, password) values('";
	oss << account;
	oss << "','";
	oss << password;
	oss << "')";
	const std::string &sql = oss.str();
	return mysql_real_query(m_mysql, sql.c_str(), (unsigned long)sql.size());
}	

    int CDbOper::SelectAccount(int32_t fd, const char* pszAccount, const char* pszPasswd, CPluto& u, string& strErr)
    {
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return 0;
        }

        //任意帐号都通过验证
        // u.Encode(MSGID_LOGINAPP_SELECT_ACCOUNT_CALLBACK) << fd << pszAccount << (uint8_t)1 << EndPluto;
        // return 0;

        //todo,preparestatement
        //这个只是测试用的,忽略密码,真正的登录是到平台认证的
        static const char* _pszSql = "select account, password from account where account='%s'";
        char szSql[256];
        memset(szSql, 0, sizeof(szSql));
        snprintf(szSql, sizeof(szSql), _pszSql, pszAccount);

        int nRet = mysql_real_query(m_mysql, szSql, (unsigned long)strlen(szSql));
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return 0;
        }

        //CPluto u;
        u.Encode(MSGID_LOGINAPP_SELECT_ACCOUNT_CALLBACK) << fd << pszAccount;

        MYSQL_RES *result = mysql_store_result(m_mysql);
        MYSQL_ROW row;
        std::string password = pszPasswd;
        std::string dbAccount, dbPasswd;
        if ((row = mysql_fetch_row(result))) {
        		dbAccount = row[0];
        		dbPasswd = row[1];
        		if(dbPasswd != password)
        			u << (uint8_t) 0;
        		else
            	u << (uint8_t) 1;
        } else {
        	int nRet = insertAccount(pszAccount, password);
	        if(nRet != 0) {
	        	strErr.assign(mysql_error(m_mysql));
	        	LogError("SelectAccount", strErr.c_str());
	        	u << (uint8_t) 0;
	        } else 
          	u << (uint8_t) 1;
        }

        u << EndPluto;
        mysql_free_result(result);

        return 0;
    }

    int CDbOper::QueryModifyNoResp(const char* pszSql)
    {
        string strErr;
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return -1;
        }

        int nRet = mysql_real_query(m_mysql, pszSql, (unsigned long)strlen(pszSql));
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return -3;
        }

        int n = (int)mysql_affected_rows(m_mysql);
        LogDebug("CDbOper::QueryModifyNoResp", "affected=%d;sql=%s\n", n, pszSql);
        return  0;
    }

    //根据def生成一个table的预期结构
    bool CDbOper::GetEntityData(const string& strEntity, map<string, string>& data)
    {
        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(strEntity);
        if(pDef)
        {
            list<_SEntityDefProperties*>::const_iterator iter = pDef->m_propertiesList.begin();
            for(; iter != pDef->m_propertiesList.end(); ++iter)
            {
                const _SEntityDefProperties* pProp = *iter;
                if(pProp->m_bSaveDb)
                {
                    data.insert(make_pair(string("sm_").append(pProp->m_name), GetPropDbType(pProp->m_nType)));
                }
            }
        }

        return pDef != NULL;
    }

    //读取desc table的当前结构
    bool CDbOper::GetDescResult(const string& strEntity, string& strErr, \
                                map<string, string>& data)
    {
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return false;
        }

        ostringstream oss;
        oss << "DESC tbl_" << strEntity;
        const string& strSql = oss.str();

        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return false;
        }

        MYSQL_RES *result = mysql_store_result(m_mysql);
        MYSQL_ROW row;
        while ((row = mysql_fetch_row(result)))
        {
            //unsigned long *lengths;
            //lengths = mysql_fetch_lengths(result);

            data.insert(make_pair(row[0], row[1]));  //0:Field,1:type
        }

        mysql_free_result(result);

        return true;
    }

    //根据def和数据库desc生成alert语句
    bool CDbOper::MakeAlterSql(const string& strEntity, string& strSql)
    {
        map<string, string> desc_data;
        string strErr;
        if(!GetDescResult(strEntity, strErr, desc_data))
        {
            cout << strErr << endl;
            return false;
        }

        map<string, string> def_data;
        if(!GetEntityData(strEntity, def_data))
        {
            return false;
        }

        list<string> change;

        map<string, string>::const_iterator iter = desc_data.begin();
        for( ; iter != desc_data.end(); ++iter)
        {
            const string& strField = iter->first;
            if(strncmp(strField.c_str(), "sm_", 3) != 0)
            {
                continue;
            }

            map<string, string>::const_iterator iter2 = def_data.find(strField);
            if(iter2 == def_data.end())
            {
                //数据库有,def中已经没有了
                string s("DROP ");
                s.append(strField);
                change.push_back(s);
            }
            else
            {
                if(iter->second != iter2->second)
                {
                    //字段还有,但是类型变化了
                    string s("MODIFY ");
                    s.append(iter2->first).append(" ").append(iter2->second);
                    change.push_back(s);
                }
            }
        }

        iter = def_data.begin();
        for(; iter != def_data.end(); ++iter)
        {
            map<string, string>::const_iterator iter2 = desc_data.find(iter->first);
            if(iter2 == desc_data.end())
            {
                //数据库没有,def中新增的字段
                string s("ADD ");
                s.append(iter->first).append(" ").append(iter->second);
                change.push_back(s);
            }
        }

        if(!change.empty())
        {
            ostringstream oss;
            oss << "ALTER TABLE tbl_" << strEntity << " ";

            int i = 0;
            list<string>::const_iterator iter3 = change.begin();
            for(; iter3 != change.end(); ++iter3)
            {
                if( i > 0)
                {
                    oss << " , ";
                }

                oss << *iter3;
                ++i;
            }

            strSql.assign(oss.str());
        }

        return true;
    }

    void CDbOper::RedisHashLoad(const string& strKey, string& strValue)
    {
#ifdef _USE_REDIS
        m_redis.RedisHashLoad(strKey, strValue);
        //printf("CDbOper::redis_hash_load, key=%s;value=%s\n", strKey.c_str(), strValue.c_str());
#else
        //printf("CDbOper::redis_hash_load, key=%s\n", strKey.c_str());

        string strErr;
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return;
        }

        //todo,preparestatement
        static const char szSql[] = "select hash_key,hash_value from redis_hash where `key`='";
        ostringstream oss;
        oss << szSql << strKey << "'";
        const string& strSql = oss.str();

        //printf("sql:%s\n", strSql.c_str());

        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return;
        }

        MYSQL_RES *result = mysql_store_result(m_mysql);
        MYSQL_ROW row;
        int i = 0;

        ostringstream oss2;
        oss2 << "{";

        while ((row = mysql_fetch_row(result)))
        {
            if(i>0)
            {
                oss2 << ',';
            }

            char* sk = row[0];
            char* sv = row[1];
            //printf("k=%s;v=%s\n", sk, sv);
            size_t sv_len = strlen(sv);

            if(sv[0]=='{' && sv[sv_len-1]=='}')
            {
                oss2 << sk << '=' << sv;
            }
            else
            {
                //string
                char szLen[4];
                snprintf(szLen, sizeof(szLen), "%03d", sv_len);
                szLen[sizeof(szLen)-1] = '\0';

                oss2 << sk << "=s" << szLen << sv;
            }

            ++i;
        }

        oss2 << '}';

        mysql_free_result(result);

        strValue.assign(oss2.str());
        //printf("redis_load:%s\n", strValue.c_str());
#endif
    }

    void CDbOper::RedisHashSet(const string& strKey, int32_t nSeq, const string& strValue)
    {
#ifdef _USE_REDIS
        m_redis.RedisHashSet(strKey, nSeq, strValue);
#else
        //printf("CDbOper::redis_hash_set, key=%s;hkey=%d;hvalue=%s\n", strKey.c_str(), nSeq, strValue.c_str());

        string strErr;
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return;
        }

        //todo,preparestatement
        static const char szSql[] = "insert into redis_hash (`key`,`hash_key`,`hash_value`) values('";

        //输入参数
        char _s[65535*2];
        mysql_real_escape_string(m_mysql, _s, strValue.c_str(), (unsigned long)strValue.size());

        ostringstream oss;
        oss << szSql << strKey << "'," << nSeq << ",'" << _s << "')";
        const string& strSql = oss.str();

        //printf("sql:%s\n", strSql.c_str());

        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return;
        }

        return;
#endif
    }

    void CDbOper::RedisHashDel(const string& strKey, int32_t nSeq)
    {
#ifdef _USE_REDIS
        m_redis.RedisHashDel(strKey, nSeq);
#else
        //printf("CDbOper::redis_hash_del, key=%s;hkey=%d\n", strKey.c_str(), nSeq);

        string strErr;
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return;
        }

        //todo,preparestatement
        static const char szSql[] = "delete from redis_hash where `key`='";

        //输入参数
        ostringstream oss;
        oss << szSql << strKey << "' and `hash_key`=" << nSeq;
        const string& strSql = oss.str();

        //printf("sql:%s\n", strSql.c_str());

        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return;
        }

        return;
#endif
    }

    int CDbOper::UpdateArrayToDb(const string& itemName, const TDBID dbid, CPluto& u, const uint16_t nBaseappId, int32_t ref, string& strErr)
    {

#ifdef __TEST

        time1.SetNowTime();
#endif

        //cout<<"udpate"<<endl;
        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(itemName);
        if(pDef == NULL)
        {
            strErr.assign("item not define");
            return -1;
        }
        int32_t avatarId;
        ostringstream strInsert;
        strInsert << "INSERT INTO tbl_" << itemName << " (timestamp";
        u.SetLen(0);
        
        map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();

        for(; iter != pDef->m_properties.end(); ++iter)
        {
            const _SEntityDefProperties* pProp = iter->second;
            if ( pProp->m_bSaveDb )
            {
                strInsert << ", "<< "sm_" << pProp->m_name;
            }
        }
        strInsert << ") values ";

        list<string> ll;
        while(u.GetLen() < u.GetMaxLen())
        {

            ostringstream   ossValues;
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
            
            ossValues << " (" << (int)time(NULL);
           
            for(; iter != pDef->m_properties.end(); ++iter)
            {
                const _SEntityDefProperties* pProp = iter->second;
                //LogDebug("Parse Pluto Start", "name = %s, type =%d", pProp->m_name.c_str(), pProp->m_nType);
                VOBJECT *v = new VOBJECT();
                if( IsBaseFlag(pProp->m_nFlags) && pProp->m_bSaveDb )
                {
                    
                    ossValues << ", ";

                    u.FillVObject(pProp->m_nType, *v);

                    if(u.GetDecodeErrIdx() > 0)
                    {
                        delete v;
                        LogError("pluto parse error", "[type = %d][name = %s], [status = %d]", pProp->m_nType, pProp->m_name.c_str(), -1);
                        return -1;
                    }
                    bool ret = PushVObjectToOstream(m_mysql, ossValues, *v);
                    if( !ret )
                    {
                        LogError("Parse items data error", "[%s]", pProp->m_name.c_str());
                        delete v;
                        return -1;
                    }
                }
                delete v;
            }
            
            ossValues << ")";
            ll.push_back(ossValues.str());
        } 
        int nRet;
        
        if( ll.size() <= 0 )
        {
            return 0;
        }
        list<string>::iterator it = ll.begin();
        for( unsigned int i =0; i != ll.size() - 1; it++, i++ )
        {
            string& str = *it;
            strInsert << *it <<", ";
        }
        strInsert << *it <<";";
                      
        
        //插入新的背包数据
        const string& strSql = strInsert.str();         
        nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            //插入失败，做回滚处理
            LogError("insert items data failure", "[status = %d", -1);
            strErr.assign(mysql_error(m_mysql));
            
            return -1;
        }
         
        //cout<<"do over"<<endl;
        CPluto *u1 = new CPluto();
        u1->Encode(MSGID_BASEAPP_UPDATE_ITEMS_CALLBACK);
        *u1 << ref << (uint16_t)0 << "success" <<EndPluto;
        CMailBox* mb = GetWorld()->GetServerMailbox(nBaseappId);
        if(mb)
        {
            //PrintHexPluto(*u1);
            //cout<<"send pluto"<<endl;
            u1->SetMailbox(mb);

            //LogDebug("CDbOper::UpdateArrayToDb", "u.GenLen()=%d", u1->GetLen());
            //cout<<"send update callback"<<endl;
            g_pluto_sendlist.PushPluto(u1);
        }
        else
        {
            LogWarning("CDbOper::UpdateArrayToDb", "base mailbox lose");
            delete u1;
            return -1;
        }

#ifdef __TEST

        int cost = time1.GetLapsedTime();

        LogInfo("CDbOper::UpdateArrayToDb Cost", "cost=%d", cost);
#endif

        return 1;
    }

	//批量更新,uniqName字段对应是数字类型,uniqName字段对应是字符串类型的暂不支持
	int CDbOper::UpdateBatch(const string& itemName, const string& uniqName, CPluto& u, 
							const uint16_t nBaseappId, int32_t ref, string& strErr)
	{

#ifdef __TEST

        time1.SetNowTime();
#endif


        //cout<<"udpate"<<endl;
		const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(itemName);
		if(pDef == NULL)
		{
			strErr.assign("item not define");
			return -1;
		}
		std::map<TDBID, bool> uniqIds;
		ostringstream strInsert;
		strInsert << "INSERT INTO tbl_" << itemName << " (timestamp";
		u.SetLen(0);

		map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();

		for(; iter != pDef->m_properties.end(); ++iter)
		{
			const _SEntityDefProperties* pProp = iter->second;
			if( pProp->m_bSaveDb)
			{
				strInsert << ", "<< "sm_" << pProp->m_name;;
			}
		}
		strInsert << ") values ";

		list<string> ll;
		while(u.GetLen() < u.GetMaxLen())
		{

			ostringstream   ossValues;
			map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();

			ossValues << " (" << (int)time(NULL);

			for(; iter != pDef->m_properties.end(); ++iter)
			{
				const _SEntityDefProperties* pProp = iter->second;
				//LogDebug("Parse Pluto Start", "name = %s, type =%d", pProp->m_name.c_str(), pProp->m_nType);
				VOBJECT *v = new VOBJECT();
				if( pProp->m_bSaveDb /*IsBaseFlag(pProp->m_nFlags)*/ )
				{

					ossValues << ", ";

					u.FillVObject(pProp->m_nType, *v);

					if(u.GetDecodeErrIdx() > 0)
					{
						LogError("pluto parse error", "[type = %d][name = %s], [status = %d]", pProp->m_nType, pProp->m_name.c_str(), -1);
						delete v;
                        return -2;
					}
					bool ret = PushVObjectToOstream(m_mysql, ossValues, *v);
					if( !ret )
					{
						LogError("Parse items data error", "[%s]", pProp->m_name.c_str());
					}
					if( pProp->m_name == uniqName && uniqIds.find(v->vv.u64) == uniqIds.end())
					{
						//avatarId = v->vv.i32;
						uniqIds.insert(make_pair(v->vv.u64, true));
					}             
				}
				delete v;
			}

			ossValues << ")";         
			ll.push_back(ossValues.str());
		} 

		if (0 == uniqIds.size())
		{
			LogError("CDbOper::UpdateBatch", "[uniqName = %s, itemName = %s]0 == uniqIds.size()",uniqName.c_str(), itemName.c_str());
			return -3;
		}
		

		list<string>::iterator it = ll.begin();

		for( unsigned int i =0; i != ll.size() - 1; it++, i++ )
		{
			string& str = *it;
			strInsert << *it <<", ";
		}
		strInsert << *it <<";";

		ostringstream ossDel;
		ossDel << "DELETE FROM tbl_"<< itemName <<" where sm_" << uniqName << " = ";
		std::map<TDBID, bool>::iterator itUniq = uniqIds.begin();
		TDBID UniqId = 0;
		for ( unsigned int i =0; i != uniqIds.size() - 1; itUniq++, i++ )
		{
			UniqId = itUniq->first;
			ossDel << UniqId <<" or sm_" << uniqName << " = ";
		}
		UniqId = itUniq->first;
		ossDel << UniqId << " ; ";

		const string& delSql = ossDel.str();
		static string beginTran = "BEGIN";
		static string rollbackTran = "ROOLBACK";
		static string commitTran = "COMMIT";
		if( mysql_real_query(m_mysql, beginTran.c_str(),(unsigned long)beginTran.size())/*mysql_autocommit(m_mysql, 0)*/ )
		{
			LogError("start transaction failure", "[status = %d]", -1);
			strErr.assign("start transaction failure");
			return -4;
		}
		//cout<<delSql.c_str()<<endl;

		int nRet;
		nRet = mysql_real_query(m_mysql, delSql.c_str(), (unsigned long)delSql.size());
		if(nRet != 0)
		{
			LogError("delete items data failure", "[status = %d", -1);
			strErr.assign(mysql_error(m_mysql));
			if( mysql_real_query(m_mysql, rollbackTran.c_str(),(unsigned long)rollbackTran.size())/*mysql_rollback(m_mysql)*/ )
			{
				LogError("database rollback failure", "[status = %d", -1);
				mysql_close(m_mysql);
				m_mysql = mysql_init(NULL);
				return -5;
			}
			return -6;
		}
		const string& strSql = strInsert.str();
		nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
		if(nRet != 0)
		{
			LogError("insert items data failure", "[status = %d", -1);
			strErr.assign(mysql_error(m_mysql));
			if( mysql_real_query(m_mysql, rollbackTran.c_str(),(unsigned long)rollbackTran.size())/*mysql_rollback(m_mysql)*/ )
			{
				LogError("database rollback failure", "[status = %d", -1);
				mysql_close(m_mysql);
				m_mysql = mysql_init(NULL);
				return -7;
			}
			return -8;
		}
		if( mysql_real_query(m_mysql, commitTran.c_str(),(unsigned long)commitTran.size())/*mysql_commit(m_mysql)*/ )
		{
			LogError("commit items data failure", "[status = %d", -1);
			//
			strErr.assign(mysql_error(m_mysql));
			if( mysql_real_query(m_mysql, rollbackTran.c_str(),(unsigned long)rollbackTran.size())/*mysql_rollback(m_mysql)*/ )
			{
				LogError("database rollback failure", "[status = %d", -1);
				mysql_close(m_mysql);
				m_mysql = mysql_init(NULL);
				return -9;
			}
			return -10;
		}
		/*
		if( mysql_autocommit(m_mysql, 1) )
		{
			LogError("end transaction failure", "[status = %d]", -1);
			strErr.assign("end transaction failure");
			mysql_close(m_mysql);
			m_mysql = mysql_init(NULL);
			return 0;
		}
		*/
		//cout<<"do over"<<endl;
		if(ref == LUA_REFNIL)
		{
			//如果回调参数为LUA_REFNIL，则不返回
			return 0;
		}
		CPluto *u1 = new CPluto();
		u1->Encode(MSGID_BASEAPP_TABLE_UPDATE_BATCH_CB);
		*u1 << ref << (uint16_t)0 <<EndPluto;
		CMailBox* mb = GetWorld()->GetServerMailbox(nBaseappId);
		if(mb)
		{
			//PrintHexPluto(*u1);
            //cout<<"send pluto"<<endl;
			u1->SetMailbox(mb);

			//LogDebug("CDbOper::UpdateArrayToDb", "u.GenLen()=%d", u1->GetLen());
			//cout<<"send update callback"<<endl;
			g_pluto_sendlist.PushPluto(u1);
		}
        else
        {
            delete u1;
            LogWarning("CDbOper::UpdateArrayToDb", "");
        }

#ifdef __TEST

        int cost = time1.GetLapsedTime();

        LogInfo("CDbOper::UpdateBatch Cost", "cost=%d", cost);
#endif

		return 0;



	}
    //读取avatarId指定的items
    int CDbOper::LoadingItemsToInventory(const string& itemName, const TDBID dbid, uint16_t nBaseappId, int32_t ref, string& strErr)
    {

#ifdef __TEST

        time1.SetNowTime();
#endif

        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return -1;
        }

        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(itemName);
        if(pDef == NULL)
        {
            strErr.assign("item not define");
            return -2;
        }
        ostringstream ossSql, oss;
        ossSql << "select id";
        map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
        for(; iter != pDef->m_properties.end(); ++iter)
        {
            // if( oss.str().size() != 0 )
            // {
            //     oss << ", ";
            // }
            const _SEntityDefProperties* pProp = iter->second;
            if( IsBaseFlag(pProp->m_nFlags) && pProp->m_bSaveDb )
            {
                oss << ", sm_"<<pProp->m_name ;
            }
        }

        ossSql << oss.str() << " from tbl_"<<itemName <<" where sm_avatarId="<< dbid;
        const string& strSql = ossSql.str();
        //LogDebug("select sql: ", "[sql = %s]", strSql.c_str());
        //cout<<strSql.c_str()<<endl;
        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return -3;
        }
        //return 0;

        MYSQL_RES *result = mysql_store_result(m_mysql);
        int num_fields = mysql_num_fields(result);
        vector<string> vtFields;
        vtFields.reserve(num_fields);


        MYSQL_FIELD * fd;
        for(int i=0; fd = mysql_fetch_field(result); ++i)
        {
            char* s = fd->name;

            size_t ls = strlen(s);
            if(ls > 3 && strncmp(s, "sm_", 3) == 0)
            {
                vtFields.push_back(string(s+3, ls-3));
            }
            else
            {
                vtFields.push_back(s);
            }
        }

        CPluto* u = new CPluto;
        u->Encode(MSGID_BASEAPP_ITEMS_LOADING_CALLBACK);
        *u << ref << (uint16_t)0 << itemName << (uint16_t)0;
        MYSQL_ROW row;
       
        while ((row = mysql_fetch_row(result)))
        {
           
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
            unsigned long *lengths;
            lengths = mysql_fetch_lengths(result);

            for(int i = 0; i < num_fields; i++)
            {
                char* s = row[i];        
                if( iter != pDef->m_properties.end() )
                {
                    const _SEntityDefProperties* pProp = iter->second;
                    if( vtFields[i].compare("id") == 0  )
                    {
                        u->FillPlutoFromStr(V_INT64, s, lengths[i]);
                        continue;
                    }
                    if( pProp->m_name == vtFields[i] )
                    {
                        //cout<<"["<<pProp->m_name.c_str()<<"] ["<<vtFields[i].c_str()<<"]"<<endl;
                        u->FillPlutoFromStr(pProp->m_nType, s, lengths[i]);
                    }
                    else
                    {
                        LogError("Field Parse Error, not matched with Entitydef", \
                            "[field name = %s][entity props= %s][status = %d]",vtFields[i].c_str(), pProp->m_name.c_str(), -1);
                        delete u;
                        u = NULL;
                        return -1;
                    }
                }
                else
                {
                    LogError("field nums not matched with properties", "[status = %d", -1);
                    delete u;
                    u = NULL;
                    return -1;
                }//end if
                iter++;
                
            }//end for
        }//end while
        *u << EndPluto;
        //PrintHexPluto(*u);
        uint32_t pos = MSGLEN_TEXT_POS + sizeof(int32_t) + sizeof(uint16_t) + sizeof(uint16_t) + itemName.size();
        uint16_t value = (u->GetLen() - pos - sizeof(uint16_t));
        u->ReplaceField(pos, value);
        //PrintHexPluto(*u);
        CMailBox* mb = GetWorld()->GetServerMailbox(nBaseappId);
        if(mb)
        {
            //PrintHexPluto(*u);
            //cout<<"send pluto"<<endl;
            u->SetMailbox(mb);

            //LogDebug("CDbOper::LoaditemsOfAvatar", "u.GenLen()=%d", u->GetLen());
            //cout<<"send loading data"<<endl;
            g_pluto_sendlist.PushPluto(u);
        }
        else
        {
            delete u;
            LogWarning("CDbOper::LoaditemsOfAvatar", "base mailbox lose");
            return -1;
        }

        mysql_free_result(result);

#ifdef __TEST

        int cost = time1.GetLapsedTime();

        LogInfo("CDbOper::LoadingItemsToInventory Cost", "cost=%d", cost);
#endif

        return 1;
    }

    int CDbOper::TableSelect(uint16_t nBaseappId, uint32_t entityId, const string& strCallBackFunc, const string& strEntityType, const string& strSql)
    {

#ifdef __TEST

        time1.SetNowTime();
#endif

        string strErr;

        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            LogError("CDbOper::TableSelect", strErr.c_str());
            return -1;
        }

        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(strEntityType);

        if (!pDef)
        {
            strErr.assign("entity not define");
            LogError("CDbOper::TableSelect", strErr.c_str());
            return -1;
        }

        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            LogError("CDbOper::TableSelect", strErr.c_str());
            return -3;
        }

        MYSQL_RES *result = mysql_store_result(m_mysql);
        int num_fields = mysql_num_fields(result);//字段数

        //返回包
        CPluto* u = new CPluto;
        CPluto& uu = *u;
        uu.Encode(MSGID_BASEAPP_TABLE_SELECT_CALLBACK) << entityId << strCallBackFunc << strEntityType << (uint16_t)num_fields;

        //LogDebug("CDbOper::TableSelect", "entityId=%d;strCallBackFunc=%s;strEntityType=%s;num_fields=%d",
        //                                  entityId, strCallBackFunc.c_str(), strEntityType.c_str(), num_fields);

        MYSQL_FIELD * fd;
        for(int i=0; fd = mysql_fetch_field(result); ++i)
        {
            char* s = fd->name;
            //printf("field_name=%s\n", s);

            size_t ls = strlen(s);
            if(ls > 3 && strncmp(s, "sm_", 3) == 0)
            {
                uu << string(s+3, ls-3);
            }
            else
            {
                uu << s;
            }
        }

        const map<string, _SEntityDefProperties*>& props = pDef->m_properties;
        MYSQL_ROW row;

        while ((row = mysql_fetch_row(result)))
        { 
            unsigned long *lengths;
            lengths = mysql_fetch_lengths(result);

            for(int i = 0; i < num_fields; i++)
            {
                char* s = row[i];
                if(s)
                {
                    uint16_t len = (uint16_t)lengths[i];
                    uu.FillField(len).FillBuff(s, len);
                }
                else
                {
                    uu.FillField<uint16_t>(0);
                }
            }
        }

        uu << EndPluto;

        mysql_free_result(result);

        if(GetWorld()->SyncRpcCall(g_pluto_sendlist, nBaseappId, u))
        {
            LogDebug("CDbOper::TableSelect", "len=%d", u->GetLen());
        }
        else
        {
            delete u;
            LogWarning("CDbOper::TableSelect", "");
        }

#ifdef __TEST

        int cost = time1.GetLapsedTime();

        LogInfo("CDbOper::TableSelect Cost", "cost=%d", cost);
#endif

        return 0;
    }

    TDBID CDbOper::TableInsert(const string& strSql, string& strErr)
    {
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return 0;
        }

        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return 0;
        }


        TDBID newid = (TDBID)mysql_insert_id(m_mysql);
        //printf("newid:%d\n", newid);

#ifdef _USE_REDIS
        //redis更新
        //m_redis.UpdateEntity(strEntity, props, newid);
#endif

        return newid;
    }
	
	int CDbOper::TableExcute(const string& strSql, string& strErr)
	{
		if(!m_bConnectDb)
		{
			strErr.assign("db not connected");
			return -1;
		}

		int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
		if(nRet != 0)
		{
			strErr.assign(mysql_error(m_mysql));
		}

		return nRet;
	}

    int CDbOper::Table2Excute(const string& strSql, string& strErr)
    {
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return -1;
        }

        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return -2;
        }

        return mysql_affected_rows(m_mysql) ==  1 ? 0 : -3 ;
    }

    int CDbOper::Table2Select(uint16_t nBaseappId, TENTITYID eid, uint32_t nCbId, const string& strEntity, const string& strSql, string& strErr)
    {
        //string strErr;
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return -1;
        }

        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(strEntity);
        if(pDef == NULL)
        {
            strErr.assign("entity not define");
            return -2;
        }

        //todo,preparestatement
        int nRet = -3;
        if(strSql.empty())
        {
            char szSql2[128];            
            snprintf(szSql2, sizeof(szSql2), "select * from tbl_%s\0", strEntity.c_str());
            nRet = mysql_real_query(m_mysql, szSql2, (unsigned long)strlen(szSql2));
        }
        else
        {
            //用指定的sql语句
            nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        }
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return -3;
        }

        MYSQL_RES *result = mysql_store_result(m_mysql);
        int num_fields = mysql_num_fields(result);//字段数

        //返回包
        CPluto* u = new CPluto;
        CPluto& uu = *u;
        uu.Encode(MSGID_BASEAPP_TABLE2SELECT_RESP) << eid << nCbId << strEntity << (uint16_t)num_fields;

        MYSQL_FIELD * fd;
        for(int i=0; fd = mysql_fetch_field(result); ++i)
        {
            char* s = fd->name;
            //printf("field_name=%s\n", s);

            size_t ls = strlen(s);
            if(ls > 3 && strncmp(s, "sm_", 3) == 0)
            {
                uu << string(s+3, ls-3);			
            }
            else
            {
                uu << s;			
            }
        }

        const map<string, _SEntityDefProperties*>& props = pDef->m_properties;
        MYSQL_ROW row;
        //uint64_t dbid2 = 0;
        int j = 0;
        CWorldDbmgr& the_world = (CWorldDbmgr&)*GetWorld();
        CDefParser& defparser = the_world.GetDefParser();
        TENTITYTYPE entity_typeid = defparser.GetTypeId(strEntity);
        while ((row = mysql_fetch_row(result)))
        { 
            unsigned long *lengths;
            lengths = mysql_fetch_lengths(result);

            for(int i = 0; i < num_fields; i++)
            {
                char* s = row[i];
                if(s)
                {
                    uint16_t len = (uint16_t)lengths[i];
                    uu.FillField(len).FillBuff(s, len);
                }
                else
                {
                    uu.FillField<uint16_t>(0);
                }
            }
        }

        uu << EndPluto;
        //print_hex_pluto(uu);

        mysql_free_result(result);


        CMailBox* mb = GetWorld()->GetServerMailbox(nBaseappId);
        if(mb)
        {
            u->SetMailbox(mb);
            g_pluto_sendlist.PushPluto(u);
        }

        return 0;
    }

    int CDbOper::IncrementalUpdateItems(const string& tblName, const uint16_t nBaseappId, CPluto& u, int32_t ref, string& strErr)
    {

#ifdef __TEST

        time1.SetNowTime();
#endif

        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return -1;
        }

        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(tblName);
        if(pDef == NULL)
        {
            strErr.assign("item not define");
            return -1;
        }
        ostringstream ossUpdate;
        ossUpdate << "UPDATE tbl_" << tblName << " SET timestamp = " << (int)time(NULL);
        u.SetLen(0);

        list<string> ll;
        while(u.GetLen() < u.GetMaxLen())
        {
            ostringstream   ossValues;
            ostringstream   ossWhere;
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
            VOBJECT *vId = new VOBJECT();
            
            ossWhere << " WHERE id = ";
            u.FillVObject(V_INT64, *vId);
            if(u.GetDecodeErrIdx() > 0)
            {
                delete vId;
                LogError("pluto parse error", "[type = %d][name = %s], [status = %d]", V_INT64, "id", -1);
                return -1;
            }
            bool vRet = PushVObjectToOstream(m_mysql, ossWhere, *vId); 
            if( !vRet )
            {
                LogError("Parse items error", "[%s]", "id");
                delete vId;
                return -1;
            }   
            delete vId;
            
            for(; iter != pDef->m_properties.end(); ++iter)
            {
                const _SEntityDefProperties* pProp = iter->second;
                
                VOBJECT *v = new VOBJECT();
                
                if( IsBaseFlag(pProp->m_nFlags) && pProp->m_bSaveDb )
                {
                    ossValues << ", ";
                    ossValues << "sm_" << iter->first << "=";
                    u.FillVObject(pProp->m_nType, *v);

                    if( u.GetDecodeErrIdx() > 0 )
                    {
                        delete v;
                        LogError("pluto parse error", "[type = %d][name = %s], [status = %d]", pProp->m_nType, pProp->m_name.c_str(), -1);
                        return -1;
                    }
                    bool ret = PushVObjectToOstream(m_mysql, ossValues, *v);
                    if( !ret )
                    {
                        LogError("Parse items error", "[%s]", pProp->m_name.c_str());
                        delete v;
                        return -1;
                    }
                }         
                delete v;
            }
            ossValues << ossWhere.str();
            ll.push_back(ossValues.str());
        }

        for( list<string>::iterator iter = ll.begin(); iter != ll.end(); iter++ )
        {
            //更新的背包数据
            ostringstream oss;
            oss <<  ossUpdate.str() << *iter; 
            const string& strSql = oss.str();  
            LogDebug("CDbOper::IncrementalUpdateItems:", "%s", strSql.c_str());
            int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
            if(nRet != 0)
            {
                LogError("update items data failure", "[status = %d]", -1);
                strErr.assign(mysql_error(m_mysql));
                return -1;
            }
        }
        
        CPluto *u1 = new CPluto();
        u1->Encode(MSGID_BASEAPP_UPDATE_ITEMS_CALLBACK);
        *u1 << ref << (uint16_t)0 << "success" <<EndPluto;
        CMailBox* mb = GetWorld()->GetServerMailbox(nBaseappId);
        if(mb)
        {
            u1->SetMailbox(mb);
            g_pluto_sendlist.PushPluto(u1);
        }
        else
        {
            LogWarning("CDbOper::IncrementalUpdateItems", "base mailbox lose");
            delete u1;
            return -1;
        }

#ifdef __TEST

        int cost = time1.GetLapsedTime();

        LogInfo("CDbOper::IncrementalUpdateItems Cost", "cost=%d", cost);
#endif

        return 0;
    }

    int CDbOper::IncremantalInsertItems(const string& tblName, const uint16_t nBaseappId, CPluto& u, int32_t ref, string& strErr)
    {
#ifdef __TEST

        time1.SetNowTime();
#endif
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return -1;
        }

        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(tblName);
        if(pDef == NULL)
        {
            strErr.assign("item not define");
            return -2;
        }
         
        ostringstream strInsert;
        strInsert << "INSERT INTO tbl_" << tblName << " (timestamp";
        u.SetLen(0);

        //ostringstream ossSelect;
        //ossSelect << "SELECT id, sm_avatarId, sm_gridIndex, sm_bagGridType FROM tbl_"<< tblName <<" WHERE ";
        //const string& selSql = ossSelect.str();

        map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();

        for(; iter != pDef->m_properties.end(); ++iter)
        {
            const _SEntityDefProperties* pProp = iter->second;
            if( pProp->m_bSaveDb )
            {
                strInsert << ", "<< "sm_" << pProp->m_name;
            }
        }
        strInsert << ")  values";
        
        vector<string> vec;
        //vector<int64_t> vec;
        vector<vector<VOBJECT*>*> vecList;
        //int64_t i = 1;
        while(u.GetLen() < u.GetMaxLen())
        {

            ostringstream   ossValues;
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();

            ossValues << " (" << (int)time(NULL);
            //处理无用id字段内容
            VOBJECT *vId = new VOBJECT();
            u.FillVObject(V_INT64, *vId);
            if( u.GetDecodeErrIdx() > 0 )
            {
                LogError("pluto parse error", "[type = %d][name = %s], [status = %d]", V_INT64, "id", -1);
                delete vId;
                vector<vector<VOBJECT*>*>::iterator it1 = vecList.begin();
                for ( ; it1 != vecList.end(); it1++ )
                {
                    vector<VOBJECT*>* vit = *it1;
                    vector<VOBJECT*>::iterator v1 = vit->begin();
                    for(; v1 != vit->end(); v1++ )
                    {
                        delete *v1;
                    }
                    delete vit;
                }
                return -3;
            }
        
            vector<VOBJECT*>* tpList = new vector<VOBJECT*>();
            VOBJECT *voId = new VOBJECT();
            voId->vt = V_INT64;
            voId->vv = vId->vv;
            tpList->push_back(vId);
            tpList->push_back(voId);

            for(; iter != pDef->m_properties.end(); ++iter)
            {
                const _SEntityDefProperties* pProp = iter->second;
                
                VOBJECT *v = new VOBJECT();
                if( pProp->m_bSaveDb && IsBaseFlag(pProp->m_nFlags) )
                {
                    ossValues << ", ";

                    u.FillVObject(pProp->m_nType, *v);

                    if(u.GetDecodeErrIdx() > 0)
                    {
                        LogError("pluto parse error", "[type = %d][name = %s], [status = %d]", pProp->m_nType, pProp->m_name.c_str(), -1);
                        vector<VOBJECT*>::iterator iter1 = tpList->begin();
                        for(; iter1 != tpList->end(); iter1++ )
                        {
                            delete *iter1;
                        }
                        delete tpList;
                        vector<vector<VOBJECT*>*>::iterator it1 = vecList.begin();
                        for ( ; it1 != vecList.end(); it1++ )
                        {
                            vector<VOBJECT*>* vit = *it1;
                            vector<VOBJECT*>::iterator v1 = vit->begin();
                            for(; v1 != vit->end(); v1++ )
                            {
                                delete *v1;
                            }
                            delete vit;
                        }
                        
                        delete v;
                        return -4;
                    }

                    bool ret = PushVObjectToOstream(m_mysql, ossValues, *v);
                    if( !ret )
                    {
                        LogError("Parse  data error", "[%s]", pProp->m_name.c_str());
                        vector<VOBJECT*>::iterator iter1 = tpList->begin();
                        for(; iter1 != tpList->end(); iter1++ )
                        {
                            delete *iter1;
                        }
                        delete tpList;
                        vector<vector<VOBJECT*>*>::iterator it1 = vecList.begin();
                        for ( ; it1 != vecList.end(); it1++ )
                        {
                            vector<VOBJECT*>* vit = *it1;
                            vector<VOBJECT*>::iterator v1 = vit->begin();
                            for(; v1 != vit->end(); v1++ )
                            {
                                delete *v1;
                            }
                            delete vit;
                        }
                        
                        delete v;
                        return -4;
                    } 
                    if( pProp->m_name.compare("bagGridType") == 0 || pProp->m_name.compare("gridIndex") == 0 )
                    {
                        tpList->push_back(v);
                        continue;
                    }
                }
                delete v;
            }
            
            vecList.push_back(tpList);
            ossValues << ")";         
            vec.push_back(ossValues.str());
        } 
        vector<string>::iterator sIter = vec.begin();
        vector<vector<VOBJECT*>*>::iterator vvIt = vecList.begin(); 
        for( ; sIter != vec.end() && vvIt != vecList.end(); sIter++, vvIt++ )
        {
            //插入新的背包数据
            ostringstream oss;
            oss <<  strInsert.str() << *sIter; 
            const string& strSql = oss.str();  
            LogDebug("insert sql: ", "%s \n", strSql.c_str());
            int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
            if(nRet != 0)
            {
                LogError("insert data failure", "[status = %d]", -1);
                strErr.assign(mysql_error(m_mysql));
                vector<vector<VOBJECT*>*>::iterator it1 = vecList.begin();
                for ( ; it1 != vecList.end(); it1++ )
                {
                    vector<VOBJECT*>* vit = *it1;
                    vector<VOBJECT*>::iterator v1 = vit->begin();
                    for(; v1 != vit->end(); v1++ )
                    {
                        delete *v1;
                    }
                    delete vit;
                }
                return -1;
            }
            int64_t newId = (int64_t)mysql_insert_id(m_mysql);
            vector<VOBJECT*>* vv = *vvIt;
            VOBJECT* vtp = vv->front();
            vtp->vv.i64 = newId;
        }
     
        CPluto* u1 = new CPluto;
        u1->Encode(MSGID_BASEAPP_INSERT_ITEMS_CALLBACK);
        *u1 << ref << (uint16_t)0 << tblName.c_str() << (uint16_t)0;

        vector<vector<VOBJECT*>*>::iterator vIt = vecList.begin();
        for( ; vIt != vecList.end(); vIt++ )
        {
            vector<VOBJECT*>* v = *vIt;
            vector<VOBJECT*>::iterator it = v->begin();
            for( ; it != v->end(); it++ )
            {

                VOBJECT* tp = *it;
                LogDebug("new data:", "%d", tp->vv);
                u1->FillPluto(*tp);
                delete tp;
            }
            delete v;
        }

        *u1 << EndPluto;
        //PrintHexPluto(*u);
        uint32_t pos = MSGLEN_TEXT_POS + sizeof(int32_t) + sizeof(uint16_t)*2 + tblName.size();
        uint16_t value = (u1->GetLen() - pos - sizeof(uint16_t));
        u1->ReplaceField(pos, value);
        //PrintHexPluto(*u);
        CMailBox* mb = GetWorld()->GetServerMailbox(nBaseappId);
        if(mb)
        {    
            u1->SetMailbox(mb);
            g_pluto_sendlist.PushPluto(u1);
        }
        else
        {
            delete u1;
            LogWarning("CDbOper::IncremantalInsertItems", "base mailbox lose");
            return -1;
        }

        

#ifdef __TEST

        int cost = time1.GetLapsedTime();

        LogInfo("CDbOper::IncremantalInsertItems Cost", "cost=%d", cost);
#endif

        return 0;
    }
}//end of namespace
//------------------------------------------------------------------------------------------------



       
                      
        

       
         
        

        
        
        
         
        
        
