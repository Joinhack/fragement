/*
 * 模拟客户端
 * todo: 1.没有实现接收到的多个pluto拆分
 *
 */

#ifdef _WIN32
#define _WIN32_WINNT 0x0501
#include <boost/asio.hpp>
#include <boost/bind.hpp>
#include <boost/array.hpp>
#else
    #include "net_util.h"
#endif


#include "util.h"
#include "world_base.h"
#include "world_select.h"


#ifdef _WIN32
using boost::asio::ip::tcp;
using namespace mogo;
#else
#define Sleep(x) 
#endif


world* g_pTheWorld = new CWorldBase;
bool g_bShutdown = false;


const char g_szHostIp[] = "172.16.10.151";     //服务器ip
enum
{
    g_nLoginAppPort = 28001,                    //loginapp端口
    MAX_BOT_COUNT = 20000,                      //已经做好的bot数据的最大值 bot_20000
    BOT_COUNT_PER_PROGRESS = 10,               //每个进程登陆的bot数
};

#ifdef _WIN32
const char g_szCfgFilename[] = "E:\\proj\\winbaseapp\\cfg.ini.example";
#else
const char g_szCfgFilename[] = "/home/liangbohao/server/bin/cfg.ini";    //配置文件路径
#endif


//基类
class CMyConnector
{
public:
	CMyConnector() : m_rpc()
#ifdef _WIN32
        ,m_sk(m_ios)
#else
        ,m_fd(0)
#endif
	{}

	virtual ~CMyConnector()
	{}

public:
	bool connect(const char* pszHost, int nPort)
	{
#ifdef _WIN32
		tcp::endpoint ep(boost::asio::ip::address_v4::from_string(pszHost), nPort);
		boost::system::error_code err;
		m_sk.connect(ep, err);
		return err.value() == 0;
#else
        m_fd = MogoSocket();
        int ret = MogoConnect(m_fd, pszHost, nPort);
        if(ret == 0)
        {
            MogoSetNonblocking(m_fd);
            return true;
        }

        return false;
#endif
	}

    void disconnect()
    {
#ifdef _WIN32
        m_sk.close();
#else
        ::close(m_fd);
#endif
    }

	template<int buff_size>
	bool read_some(char* buff, size_t& len2)
	{
#ifdef _WIN32
		for (;;)
		{
			boost::array<char, buff_size> buf;
			boost::system::error_code error;

			size_t len = m_sk.read_some(boost::asio::buffer(buf), error);			

			if (error == boost::asio::error::eof)
			{
				//break; // Connection closed cleanly by peer.
				return false;
			}
			else if (error)
			{
				//throw boost::system::system_error(error); // Some other error.
				return false;
			}

			len2 = len;
			memcpy(buff, buf.data(), len);
			return true;
		}
#else
        char buff2[1024];
        size_t buffsize2 = sizeof(buff2);
        bool bIsTimeout;
        int n = MogoAsyncRead(m_fd, buff2, buffsize2, 1);
        if(n > 0)
        {
            memcpy(buff, buff2, n);
            len2 = n;
            return true;
        }

        return false;
#endif
	}

	CPluto* read_pluto()
	{
		enum{ buff_size = 4096*16, };
		char buff[buff_size];
		size_t real_len;
		if(read_some<buff_size>(buff, real_len))
		{
			CPluto* u = new CPluto(buff, (uint32_t)real_len);			
            //PrintHexPluto(*u);
			return u;
		}	

		return NULL;
	}

#ifdef _WIN32
	void handle_read(const boost::system::error_code& error)
	{
		printf("handle_read, %d \n", error.value());
	}
#endif

	void async_read_some()
	{
		enum{ buff_size = 4096*16, };
		char buf[buff_size];
#ifdef _WIN32
		m_sk.async_read_some(boost::asio::buffer(buf, buff_size), boost::bind(&CMyConnector::handle_read, this, boost::asio::placeholders::error));
#else
        size_t n1;
        read_some<1>(buf, n1);
#endif
	}

	bool write_some(const char* msg, size_t len)
	{
#ifdef _WIN32
		return m_sk.write_some(boost::asio::buffer(msg, len)) == len;
#else
        return ::write(m_fd, msg, len) > 0;
#endif
	}

protected:
#ifdef _WIN32
	boost::asio::io_service m_ios;
	tcp::socket m_sk;
#else
    int m_fd;
#endif
	CRpcUtil m_rpc;

};

struct SBaseappLoginData
{
	string m_strBase;
	string m_strKey;
	uint16_t m_unPort;
};


//loginapp的相关操作
class CLoginappConnector : public CMyConnector
{
public:
	CLoginappConnector():CMyConnector()
	{}

	~CLoginappConnector()
	{

	}

public:
	SBaseappLoginData* login_account(const char* pszHost, int nPort, const char* pszAccount, const char* pszPasswd)
	{
		printf("try to login account: [ %s : %d ] [ %s ] \n", pszHost, nPort, pszAccount);
		if(this->connect(pszHost, nPort))
		{
			//发送登录包
			CPluto u;
			m_rpc.Encode(u, MSGID_LOGINAPP_LOGIN, pszAccount, pszPasswd);
			write_some(u.GetBuff(), u.GetLen());
		}
		else
		{
			return NULL;
		}

		bool bWait = true;
        int nWaitCount = 0;
		SBaseappLoginData* bd = NULL;
		while(bWait)
		{
			CPluto* u = read_pluto();
			if(u)
			{
				T_VECTOR_OBJECT* p = m_rpc.Decode(*u);
				if(p)
				{
					pluto_msgid_t msgid = u->GetMsgId();
					if(msgid == MSGID_CLIENT_LOGIN_RESP)
					{
						uint8_t nRet = VOBJECT_GET_U8((*p)[0]);
						printf("login ret=%d\n", nRet);
						if(nRet != 0)
						{
							bWait = false;
						}						
					}
					else if(msgid == MSGID_CLIENT_NOTIFY_ATTACH_BASEAPP)
					{
						const char* pszBaseappIp = VOBJECT_GET_STR((*p)[0]);
						uint16_t nBaseappPort = VOBJECT_GET_U16((*p)[1]);
						const char* pszKey = VOBJECT_GET_STR((*p)[2]);

						bd = new SBaseappLoginData;
						bd->m_strBase.assign(pszBaseappIp);
						bd->m_strKey.assign(pszKey);
						bd->m_unPort = nBaseappPort;
						bWait = false;

						printf("redirect to baseapp [ %s : %d ] [ %s ] \n", pszBaseappIp, nBaseappPort, pszKey);

                        //断开到loginapp的连接
                        this->disconnect();
					}
                    else if(msgid == MSGID_CLIENT_NOTIFY_MULTILOGIN)
                    {
                        int a = 0;
                        ++a;
                        printf("mutlilogin, [%s] \n", pszAccount);
                    }
                    else
                    {
                        int a = 0;
                        ++a;
                    }

					ClearTListObject(p);					
				}
				delete u;
			}
            else
            {
                if(++nWaitCount > 3)
                {
                    return NULL;
                }
            }
		}


		return bd;
	}


};


//baseapp的相关操作
class CBaseappConnector : public CMyConnector
{
public:
	CBaseappConnector() : CMyConnector()
	{
	}

	~CBaseappConnector()
	{
	}

public:
	bool login_baseapp(SBaseappLoginData* bd)
	{
		if(bd == NULL)
		{
			return false;
		}

		if(this->connect(bd->m_strBase.c_str(), bd->m_unPort))
		{
			//发送登录包
			CPluto u;
			m_rpc.Encode(u, MSGID_BASEAPP_CLIENT_LOGIN, bd->m_strKey);
			write_some(u.GetBuff(), u.GetLen());
		}
		else
		{
			return false;
		}

		//等待绑定entity(等Account转换为Avatar)
#ifdef _WIN32
		Sleep(100);
#else
        Sleep(1);
#endif

		bool bWait = true;
        int nWaitCount = 0;
		while(bWait)
		{
			CPluto* u = read_pluto();
			if(u)
			{
				//T_VECTOR_OBJECT* p = m_rpc.decode(*u);
				//if(p)
				//{
				//	pluto_msgid_t msgid = u->getMsgId();
				//	if(msgid == MSGID_CLIENT_ENTITY_ATTACHED)
				//	{
				//		bWait = false;
				//		printf("entity attached.\n");
				//	}

				//	clear_T_LIST_OBJECT(p);
				//}
				//delete u;

				bWait = false;
				printf("entity attached.\n");
			}

            if(++nWaitCount > 3)
            {
                bWait = false;
                printf("wait_timeout.\n");
            }
		}

		return true;
	}

	bool avatar_rpc(const char* cmd)
	{
		list<string> ls;
		SplitString(cmd, '|', ls);

		if(ls.empty())
		{
			printf("error rpc, empty string. \n");
			return false;
		}
		
		//远程方法名
		CDefParser& defp = GetWorld()->GetDefParser();
		const SEntityDef* pDef = defp.GetEntityDefByName("Avatar");
		string strFunc = ls.front();
		ls.pop_front();
		uint16_t nFunc = (uint16_t)pDef->m_baseMethodsMap.GetIntByStr(strFunc);		

		CPluto u;
		u.Encode(MSGID_BASEAPP_CLIENT_RPCALL) << nFunc;

		//其他参数
		map<string, _SEntityDefMethods*>::const_iterator iter11 = pDef->m_baseMethods.find(strFunc);		
		if(iter11 != pDef->m_baseMethods.end())
		{
			_SEntityDefMethods* pmethod = iter11->second;
			list<VTYPE>::const_iterator iter = pmethod->m_argsType.begin();
			for(; iter != pmethod->m_argsType.end(); ++iter)
			{
				if(ls.empty())
				{
					printf("error rpc, less params, %s \n", cmd);
					return false;
				}

				const string& sv = ls.front();
				u.FillPlutoFromStr(*iter, sv.c_str(), (unsigned long)sv.size());
				ls.pop_front();
			}
		}

		u << EndPluto;

		//发送
		printf("send cmd: %s \n", cmd);
		//print_hex_pluto(u);
		write_some(u.GetBuff(), u.GetLen());

		//收取回应包
		//async_read_some();
		//CPluto* u2 = read_pluto();
		//delete u2;

		return true;
	}

    //模拟错误的rpc包
    bool err_avatar_rpc()
    {
        //远程方法名
        CDefParser& defp = GetWorld()->GetDefParser();
        const SEntityDef* pDef = defp.GetEntityDefByName("Avatar");
        string strFunc("UseSkillReq");        
        uint16_t nFunc = (uint16_t)pDef->m_baseMethodsMap.GetIntByStr(strFunc);		

        CPluto u;
        u.Encode(MSGID_BASEAPP_CLIENT_RPCALL) << nFunc;

        //其他参数
        u << (uint64_t) 1 << (uint16_t) 2 << (uint16_t)3 << (uint8_t) 4 << (uint16_t) 5 ;
        u << (uint8_t) 6; //error
        u << EndPluto;

        //发送
        printf("send err_cmd: %s \n", strFunc.c_str());
        //print_hex_pluto(u);
        write_some(u.GetBuff(), u.GetLen());

        //收取回应包
        //async_read_some();
        //CPluto* u2 = read_pluto();
        //delete u2;

        return true;
    }

    bool random_base_rpc()
    {
        //远程方法名
        CDefParser& defp = GetWorld()->GetDefParser();
        const SEntityDef* pDef = defp.GetEntityDefByName("Avatar");

        int nMaxFuncId = (int)pDef->m_baseMethods.size();
        int nFunc = rand() % nMaxFuncId;
        const string& strFunc = pDef->m_baseMethodsMap.GetStrByInt(nFunc);

        ostringstream oss;
        oss << strFunc;
        CPluto u;
        u.Encode(MSGID_BASEAPP_CLIENT_RPCALL) << nFunc;

        //其他参数
        map<string, _SEntityDefMethods*>::const_iterator iter11 = pDef->m_baseMethods.find(strFunc);		
        if(iter11 != pDef->m_baseMethods.end())
        {
            _SEntityDefMethods* pmethod = iter11->second;
            list<VTYPE>::const_iterator iter = pmethod->m_argsType.begin();
            for(; iter != pmethod->m_argsType.end(); ++iter)
            {
                VTYPE vt = *iter;
                string sv;
                switch(vt)
                {
                case V_STR:
                    sv.assign("abcd");
                    break;
                case V_INT8:
                case V_UINT8:
                case V_INT16:
                case V_UINT16:
                case V_INT32:
                case V_UINT32:
                case V_INT64:
                case V_UINT64:
                case V_FLOAT32:
                case V_FLOAT64:
                    sv.assign("14");
                    break;
                case V_BLOB:
                    sv.assign("{}");
                    break;
                default:
                    sv.assign("");
                    break;
                }

                oss << "|" << sv;
                u.FillPlutoFromStr(*iter, sv.c_str(), (unsigned long)sv.size());
            }
        }

        u << EndPluto;

        //发送
        printf("send base_cmd: %d %s \n", nFunc,  oss.str().c_str());
        //print_hex_pluto(u);
        write_some(u.GetBuff(), u.GetLen());

        //收取回应包
        //async_read_some();
        //CPluto* u2 = read_pluto();
        //delete u2;

        return true;
    }

    bool random_cell_rpc()
    {
        //远程方法名
        CDefParser& defp = GetWorld()->GetDefParser();
        const SEntityDef* pDef = defp.GetEntityDefByName("Avatar");

        int nMaxFuncId = (int)pDef->m_cellMethods.size();
        int nFunc = rand() % nMaxFuncId;
        const string& strFunc = pDef->m_cellMethodsMap.GetStrByInt(nFunc);

        ostringstream oss;
        oss << strFunc;
        CPluto u;
        u.Encode(MSGID_BASEAPP_CLIENT_RPC2CELL_VIA_BASE) << nFunc;

        //其他参数
        map<string, _SEntityDefMethods*>::const_iterator iter11 = pDef->m_cellMethods.find(strFunc);		
        if(iter11 != pDef->m_cellMethods.end())
        {
            _SEntityDefMethods* pmethod = iter11->second;
            list<VTYPE>::const_iterator iter = pmethod->m_argsType.begin();
            for(; iter != pmethod->m_argsType.end(); ++iter)
            {
                VTYPE vt = *iter;
                string sv;
                switch(vt)
                {
                case V_STR:
                    sv.assign("abcd");
                    break;
                case V_INT8:
                case V_UINT8:
                case V_INT16:
                case V_UINT16:
                case V_INT32:
                case V_UINT32:
                case V_INT64:
                case V_UINT64:
                case V_FLOAT32:
                case V_FLOAT64:
                    sv.assign("14");
                    break;
                case V_BLOB:
                    sv.assign("{}");
                    break;
                default:
                    sv.assign("");
                    break;
                }

                oss << "|" << sv;
                u.FillPlutoFromStr(*iter, sv.c_str(), (unsigned long)sv.size());
            }
        }

        u << EndPluto;

        //发送
        printf("send cell_cmd: %d %s \n", nFunc,  oss.str().c_str());
        //print_hex_pluto(u);
        write_some(u.GetBuff(), u.GetLen());

        //收取回应包
        //async_read_some();
        //CPluto* u2 = read_pluto();
        //delete u2;

        return true;
    }
    
    bool avatar_cell_rpc(const char* cmd)
    {
        list<string> ls;
        SplitString(cmd, '|', ls);

        if(ls.empty())
        {
            printf("error rpc, empty string. \n");
            return false;
        }

        //远程方法名
        CDefParser& defp = GetWorld()->GetDefParser();
        const SEntityDef* pDef = defp.GetEntityDefByName("Avatar");
        string strFunc = ls.front();
        ls.pop_front();
        uint16_t nFunc = (uint16_t)pDef->m_cellMethodsMap.GetIntByStr(strFunc);		

        CPluto u;
        u.Encode(MSGID_BASEAPP_CLIENT_RPC2CELL_VIA_BASE) << nFunc;

        //其他参数
        map<string, _SEntityDefMethods*>::const_iterator iter11 = pDef->m_cellMethods.find(strFunc);		
        if(iter11 != pDef->m_cellMethods.end())
        {
            _SEntityDefMethods* pmethod = iter11->second;
            list<VTYPE>::const_iterator iter = pmethod->m_argsType.begin();
            for(; iter != pmethod->m_argsType.end(); ++iter)
            {
                if(ls.empty())
                {
                    printf("error rpc, less params, %s \n", cmd);
                    return false;
                }

                const string& sv = ls.front();
                u.FillPlutoFromStr(*iter, sv.c_str(), (unsigned long)sv.size());
                ls.pop_front();
            }
        }

        u << EndPluto;

        //发送
        printf("send cell cmd: %s \n", cmd);
        //print_hex_pluto(u);
        write_some(u.GetBuff(), u.GetLen());

        //收取回应包
        //async_read_some();
        //CPluto* u2 = read_pluto();
        //delete u2;

        return true;
    }



	//随机走动
	void random_move()
	{
		uint16_t x = 3016 + rand() % 300;
		uint16_t y = 2020 + rand() % 300;
		CPluto u;
		u.Encode(MSGID_BASEAPP_CLIENT_MOVE_REQ) << x << y << EndPluto;
		//u.Cryto();
		write_some(u.GetBuff(), u.GetLen());
	}

};

string make_random_account(int nn = 0)
{
	int n = (nn == 0) ? rand() : nn;
	int m = n % MAX_BOT_COUNT + 1;
	
	char s[16];
	memset(s, 0, sizeof(s));
	snprintf(s, sizeof(s), "bot_%d", m);

	return s;
}

struct SConnectorData
{
	CLoginappConnector* m_login;
	SBaseappLoginData* m_login_data;
	CBaseappConnector* m_baseapp;

public:
	~SConnectorData()
	{
		delete m_login;
		delete m_login_data;
		delete m_baseapp;
	}
};

int main(int argc, char* argv[])
{
	srand((unsigned int)time(NULL));
	printf("%d\n", rand());
	printf("%d\n", rand());
	printf("%d\n", rand());
	printf("%d\n", rand());
	printf("%d\n", rand());
	printf("%d\n", rand());

    int begin_pos = -1;
    if(argc > 1)
    {
        begin_pos = atoi(argv[1]) + 1;
    }

	//初始化,读取配置文件
    GetWorld()->init(g_szCfgFilename);    

	list<SConnectorData*> all_conn;

	for(int i=0; i<BOT_COUNT_PER_PROGRESS; ++i)
	{
		SConnectorData* p = new SConnectorData;
		p->m_login = new CLoginappConnector;
        int name_suffix = begin_pos == -1 ? 0 : begin_pos + i;
		p->m_login_data = p->m_login->login_account(g_szHostIp, g_nLoginAppPort, make_random_account(name_suffix).c_str(), "12345678asb");
		p->m_baseapp = new CBaseappConnector;
		if(p->m_baseapp->login_baseapp(p->m_login_data))
		{
			all_conn.push_back(p);
		}
		else
		{
			delete p;
		}
	}

	for(;;)	
	{
		//发送测试指令
		list<SConnectorData*>::iterator iter = all_conn.begin();
		for(; iter != all_conn.end(); ++iter)
		{
			CBaseappConnector& base_conn = *((*iter)->m_baseapp);

			try
			{
				//base_conn.random_move();
				//base_conn.avatar_rpc("MissionReq|1|10101|1|\"\"");
                //Sleep(10);
                base_conn.avatar_rpc("MissionReq|71|0|0|\"\"");
                base_conn.avatar_cell_rpc("TelportLocally|10|21");

                //base_conn.random_base_rpc();
                //base_conn.random_cell_rpc();
                base_conn.err_avatar_rpc();

                //{
                //    char szChat[128];
                //    memset(szChat, 0, sizeof(szChat));
                //    snprintf(szChat, sizeof(szChat), "Chat|2|0|hello_world,%x", &base_conn);
                //    //base_conn.avatar_rpc(szChat);
                //}
				//base_conn.avatar_rpc("gm_req|@add gold 100");
				//base_conn.avatar_rpc("gm_req|@add silver 100");
				//base_conn.avatar_rpc("item_buy_req|2001|1");
				//base_conn.avatar_rpc("item_buy_req|2002|1");
				//base_conn.avatar_rpc("item_buy_req|2003|1");
				//base_conn.avatar_rpc("item_buy_req|2004|1");
				//base_conn.avatar_rpc("gm_req|@vs 17 16");
				//base_conn.avatar_rpc("gm_req|@vs 17");

				Sleep(100);

				base_conn.async_read_some();
			}
			catch (...)
			{
				printf("exception\n");
			}

#ifdef _WIN32
            //20毫秒
            Sleep(20);
#else
            //2秒
            sleep(2);
#endif // _WIN32

			

			//CPluto* u = base_conn.read_pluto();
			//delete u;	
		}	
	}

	return 0;
}

