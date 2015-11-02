#ifndef __WIN_ADAPTOR_HEAD__
#define __WIN_ADAPTOR_HEAD__

//为了vc下编译通过,写一个兼容类

#ifdef _WIN32

#include "type_mogo.h"
#include "rpc_mogo.h"


class CWinTestWorld
{
    public:
        int FromRpcCall(CPluto& u);
};


class CMailBox
{
    public:
        CMailBox() {}
        CMailBox(uint16_t uid, EFDTYPE fdtype, const char* pszAddr, uint16_t unPort) {}

    public:
        bool RpcCall(CPluto& u);

        template<typename T1>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1);

        template<typename T1, typename T2>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2);

        template<typename T1, typename T2, typename T3>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3);

        template<typename T1, typename T2, typename T3, typename T4>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4);

        template<typename T1, typename T2, typename T3, typename T4, typename T5>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5);

        template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
        bool RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6);

        inline uint16_t GetServerMbType() const
        {
            return 0;
        }

        inline void PushPluto(CPluto* u)
        {
        }

        inline void SetAuthz(uint8_t n)
        {
        }

        inline uint8_t GetAuthz() const
        {
            return MAILBOX_CLIENT_TRUSTED;
        }

        inline int GetFd()
        {
            return 0;
        }

        inline void SetServerMbType(int)
        {
        }

        inline uint16_t GetMailboxId()
        {
            return 0;
        }

        inline string GetServerName()
        {
            return "";
        }

        inline uint16_t GetServerPort()
        {
            return 0;
        }

		inline bool IsDelete() const
		{
			return false;
		}

};

inline bool CMailBox::RpcCall(CPluto& u)
{
    //todo,加入发送队列

    //test code
    CPluto u2(u.GetBuff(), u.GetLen());
    CWinTestWorld world;
    world.FromRpcCall(u2);

    return true;
}

template<typename T1>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1)
{
	CPluto u;
	r.Encode(u, msg_id, p1);

	//todo,加入发送队列

	//test code
	CPluto u2(u.GetBuff(), u.GetLen());
	CWinTestWorld world;
	world.FromRpcCall(u2);

	return true;
}

template<typename T1, typename T2>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2)
{
    CPluto u;
    r.Encode(u, msg_id, p1, p2);

    //todo,加入发送队列

    //test code
    CPluto u2(u.GetBuff(), u.GetLen());
    CWinTestWorld world;
    world.FromRpcCall(u2);

    return true;
}

template<typename T1, typename T2, typename T3>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3)
{
	CPluto u;
	r.Encode(u, msg_id, p1, p2, p3);

	//todo,加入发送队列

	//test code
	CPluto u2(u.GetBuff(), u.GetLen());
	CWinTestWorld world;
	world.FromRpcCall(u2);

	return true;
}

template<typename T1, typename T2, typename T3, typename T4>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4)
{
	CPluto u;
	r.Encode(u, msg_id, p1, p2, p3, p4);

	//todo,加入发送队列

	//test code
	CPluto u2(u.GetBuff(), u.GetLen());
	CWinTestWorld world;
	world.FromRpcCall(u2);

	return true;
}

template<typename T1, typename T2, typename T3, typename T4, typename T5>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5)
{
	CPluto u;
	r.Encode(u, msg_id, p1, p2, p3, p4, p5);

	//todo,加入发送队列

	//test code
	CPluto u2(u.GetBuff(), u.GetLen());
	CWinTestWorld world;
	world.FromRpcCall(u2);

	return true;
}

template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6)
{
	CPluto u;
	r.Encode(u, msg_id, p1, p2, p3, p4, p5, p6);

	//todo,加入发送队列

	//test code
	CPluto u2(u.GetBuff(), u.GetLen());
	CWinTestWorld world;
	world.FromRpcCall(u2);

	return true;
}

extern CMailBox g_winTestMailbox;

class CEpollServer
{
    public:
        CEpollServer() : m_serverMbs()
        {
        }

    public:
        inline CMailBox* GetServerMailbox(uint16_t nServerId)
        {
            return &g_winTestMailbox;
        }

        inline CMailBox* GetClientMailbox(int32_t fd)
        {
            return &g_winTestMailbox;
        }

        inline vector<CMailBox*>& GetAllServerMbs()
        {
            return m_serverMbs;
        }

        inline uint16_t GetMailboxId()
        {
            return 1;
        }

        inline void AddLocalRpcPluto(CPluto* u)
        {
        }

        inline void CloseFdFromServer(int fd)
        {
        }

        inline void KickOffFd(int fd)
        {}

        inline void Shutdown()
        {}

    protected:
        vector<CMailBox*> m_serverMbs;

};

#else

#include "epoll_server.h"
#include "mailbox.h"

#endif

#endif

