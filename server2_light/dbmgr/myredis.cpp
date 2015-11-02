#include "myredis.h"
#include "util.h"


namespace mogo
{


    CRedisUtil::CRedisUtil() : m_redis(NULL)
    {

    }

    CRedisUtil::~CRedisUtil()
    {

    }

    bool CRedisUtil::Connect(const char* pszAddr, int nPort, int nDbId)
    {
#ifndef _WIN32
        m_redis = redisConnect(pszAddr, nPort);
        if(m_redis->err != 0)
        {
            LogError("redis_connect", "failed to connect: %s:%d ,err=%s", pszAddr, nPort, m_redis->errstr);
            return false;
        }
		//选择库
		char szCommond[24];
		memset(szCommond, 0, sizeof(szCommond));
		snprintf(szCommond, sizeof(szCommond), "SELECT %d", nDbId);
		redisReply* reply = (redisReply*)redisCommand(m_redis, szCommond);
		if(!reply)
		{
			LogError("redis_connect", szCommond);
			return false;
		}
        else
        {
            LogInfo("redis_connect", szCommond);
            //LogDebug("freeReplyObject", "%s : %d", __FILE__, __LINE__);
            freeReplyObject(reply);
        }
#endif
        return true;
    }

    void CRedisUtil::DisConnect()
    {
#ifndef _WIN32
        if(m_redis == NULL)
        {
            return;
        }

        redisFree(m_redis);
#endif
    }

    void CRedisUtil::DisConnectAndBgSave()
    {
#ifndef _WIN32
        if(m_redis == NULL)
        {
            return;
        }

        redisReply* reply = (redisReply*)redisCommand(m_redis, "BGSAVE");
        if(reply)
        {
            LogInfo("redis_disconnect", "BGSAVE,ret=%s", reply->str);
            freeReplyObject(reply);
        }

        redisFree(m_redis);
#endif
    }

    void _CopyStringToRedisCmd2(int idx, const string& k, char** argv, size_t* argvlen)
    {
        char* s = new char[k.size()+1];
        strcpy(s, k.c_str());
        argv[idx] = s;
        argvlen[idx] = int(k.size());
    }

    int CRedisUtil::UpdateEntity(const string& strEntity, const map<string, VOBJECT*>& props, TDBID dbid)
    {
        int nPropsSize = 2*(int)props.size() + 4;

        char** argv = new char*[nPropsSize];
        size_t* argvlen = new size_t[nPropsSize];

        //设置命令头
        {
            string s1("hmset");
            _CopyStringToRedisCmd2(0, s1, argv, argvlen);

            enum { _cmd_size = 64 };
            char* s = new char[_cmd_size];
            memset(s, 0, _cmd_size);
            snprintf(s, _cmd_size, "%s:%lld", strEntity.c_str(), dbid);

            argv[1] = s;
            argvlen[1] = strlen(s);

            _CopyStringToRedisCmd2(2, "timestamp", argv, argvlen);

            char szTime[32];
            memset(szTime, 0, sizeof(szTime));
            snprintf(szTime, sizeof(szTime), "%d", (int)time(NULL));
            _CopyStringToRedisCmd2(3, szTime, argv, argvlen);
        }

        //设置其他参数
        int i = 4;
        map<string, VOBJECT*>::const_iterator iter = props.begin();
        for(; iter != props.end(); ++iter)
        {
            VOBJECT* p = iter->second;
            PushVObjectToRedisCmd(i, iter->first, *(iter->second), argv, argvlen);
            i += 2;
        }

        //for(int i=0;i<nPropsSize; ++i)
        //{
        //  printf("--- %s %d\n", argv[i], argvlen[i]);
        //}

#ifndef _WIN32
        redisReply* reply = (redisReply*)redisCommandArgv(m_redis, nPropsSize, (const char**)argv, (const size_t*)argvlen);
        if(reply && reply->str)
        {
            LogInfo("redis_UpdateEntity", "type=%s;dbid=%lld;ret=%s", strEntity.c_str(), dbid, reply->str);
        }
        else
        {
            LogError("redis_UpdateEntity_err", "dbid=%lld;err=%s", dbid, m_redis->errstr);
        }
        if(reply)
        {
            //LogDebug("freeReplyObject", "%s : %d", __FILE__, __LINE__);
            freeReplyObject(reply);
        }
#endif

        //释放argv, argvlen
        for(int i=0; i<nPropsSize; ++i)
        {
            delete[] argv[i];
        }
        delete[] argv;
        delete[] argvlen;

        return 0;
    }

    void CRedisUtil::RedisHashLoad(const string& strKey, string& strValue)
    {
#ifndef _WIN32
        redisReply* reply = (redisReply*)redisCommand(m_redis, "hgetall %s", strKey.c_str());
        if(reply)
        {
            if (reply->type == REDIS_REPLY_ARRAY)
            {
                ostringstream oss;
                oss << "{";
                struct redisReply ** ele = reply->element;
                for (int j = 0; j < (int)reply->elements; j+=2)
                {
                    if(j>0)
                    {
                        oss << ",";
                    }

                    struct redisReply* pele = ele[j+1];

                    if(pele->len > 1 && pele->str[0]=='{' && pele->str[pele->len-1]=='}')
                    {
                        //lua_table
                        oss << atoi(ele[j]->str) << "=" << pele->str;
                    }
                    else
                    {
                        //string
                        char szLen[4];
                        snprintf(szLen, sizeof(szLen), "%03d", pele->len);
                        szLen[sizeof(szLen)-1] = '\0';

                        oss << atoi(ele[j]->str) << "=s" << szLen << pele->str;
                    }
                }
                oss << "}";
                strValue.assign(oss.str());
                //LogDebug("freeReplyObject", "%s : %d", __FILE__, __LINE__);
                freeReplyObject(reply);
                return;
            }
            freeReplyObject(reply);
        }

        const static char szEmptyTable[] = "{}";
        strValue.assign(szEmptyTable);
#endif
    }

    void CRedisUtil::RedisHashSet(const string& strKey, int32_t nSeq, const string& strValue)
    {
#ifndef _WIN32
        redisReply* reply = (redisReply*)redisCommand(m_redis, "hset %s %d %s", strKey.c_str(), nSeq, strValue.c_str());
        if(reply)
        {
            freeReplyObject(reply);
        }
#endif
    }

    void CRedisUtil::RedisHashDel(const string& strKey, int32_t nSeq)
    {
#ifndef _WIN32
        redisReply* reply = (redisReply*)redisCommand(m_redis, "hdel %s %d", strKey.c_str(), nSeq);
        if(reply)
        {
            freeReplyObject(reply);
        }
#endif
    }


}
