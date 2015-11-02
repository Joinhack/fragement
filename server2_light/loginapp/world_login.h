#ifndef __WORLD_LOGIN_HEAD__
#define __WORLD_LOGIN_HEAD__

#include "world.h"
#include "pluto.h"

#if __PLAT_PLUG_IN || __PLAT_PLUG_IN_NEW
	#include "md5.h"
#endif

namespace mogo
{

    class CWorldLogin : public world
    {
        public:
            CWorldLogin();
            ~CWorldLogin();

        public:
            int FromRpcCall(CPluto& u);
            int OpenMogoLib(lua_State* L)
            {
                return 0;
            }
        private:
            //内网开发模式下的登陆
            int AccountLogin(T_VECTOR_OBJECT* p);
            //到平台认证后的登陆
            int AccountWebLogin(T_VECTOR_OBJECT* p);
            //真正实现登陆流程的方法
            int _AccountLoginImpl(T_VECTOR_OBJECT* p, bool bLoginFirst);
            int SelectAccountCallback(T_VECTOR_OBJECT* p);
            int NotifyClientToAttach(T_VECTOR_OBJECT* p);
            int NotifyClientMultiLogin(T_VECTOR_OBJECT* p);
            int ModifyLoginFlag(T_VECTOR_OBJECT* p);
            bool CheckClientRpc(CPluto& u);
            int VersionCheck(T_VECTOR_OBJECT* p);
            int ForbidLogin(T_VECTOR_OBJECT* p);		//禁用户登录 注：这里的time是 禁止的时间，不是截止时间

			int	ForbidLoginByAccount(T_VECTOR_OBJECT* p); //禁IP 到指定的时间 和ForbidLogin 有一点区别 这里是截止时间
			int ForbidLoginByIp(T_VECTOR_OBJECT* p); //禁IP 到指定的时间
			int ForbidLogin(map<string, uint32_t>& records, const string & key, uint32_t endTime);
            int ModifyOnlineCount(T_VECTOR_OBJECT* p);
            //帐号验证
#if __PLAT_PLUG_IN || __PLAT_PLUG_IN_NEW
            int AccountVerify(string& strSuid, string& strSign, string& timestamp);
			int AccountRealLogin(const char* pszAccount, const int32_t nFd);

			string GetGameAccount(const string& strSuid, const string& strPlatId);
#else
			int AccountRealLogin(const char* pszAccount, const char* pszPasswd, const int32_t nFd);
#endif

#if __PLAT_PLUG_IN_NEW
			int SdkServerCheckReq(const string& strToken, const int32_t nFd, const string& strSuid, const string& strPlatId);
			int SdkServerCheckResp(T_VECTOR_OBJECT* p);
#endif
        public:

            //此方法无用
            inline CEntityParent* GetEntity(TENTITYID id)
            {
                return NULL;
            }

            inline int OnServerReady()
            {
                return 0;
            }

        public:
            int OnFdClosed(int fd);

        private:
            map<int, string> m_fd2accounts;    //socket fd和account的关联关系
            map<string, int> m_accounts2fd;
            map<string, TDBID> m_accounts;     //读取过account表的账户缓存,//todo,独立出loginapp
            set<string> m_accountInCreating;   //正在创建角色的账户
            bool m_bCanLogin;                  //服务器是否开放登陆标记
            map<string, uint32_t> m_forbiddenLogin;   //禁止被登陆的人名，禁止登录的到期时间
			map<string, uint32_t> m_forbiddenIP;   //禁止被登陆的ip，禁止登录的到期时间
            map<string, time_t> m_accountsInVerify;   //出现过一次冲突后的,正在认证中的帐号对应的上次认证时间
            uint16_t m_onlineCount;           //当前服务器的在线人数

            CWorldLogin(const CWorldLogin&);
            CWorldLogin& operator=(const CWorldLogin&);

#if __PLAT_PLUG_IN || __PLAT_PLUG_IN_NEW
            CMd5 m_md5;
#endif
    };



}



#endif

