#ifndef __MAILBOX_HEAD__
#define __MAILBOX_HEAD__

#include <string>
#include <map>
#include <list>
#include <time.h>

#include "pluto.h"
#include "rpc_mogo.h"
#include "memory_pool.h"


using std::string;
using std::list;
using mogo::CRpcUtil;

#ifdef _USE_RECV_BUFF
enum
{
    MAILBOX_RECV_BUFF_SIZE = 65000,
};
#endif

#ifdef __OPTIMIZE_PLUTO
enum
{
    SEND_BUFF = 8 * 1024,
};
#endif


struct MailBoxConfig
{
    uint8_t m_serverType;           //服务器类型:cell/base/login...
    string m_strRemoteIp;           //原程ip
    uint16_t m_unRemotePort;        //原程port
    //string m_strLocalMsgPath;       //本地消息队列路径
};

class CMailBox
{
    public:
        CMailBox(uint16_t uid, EFDTYPE fdtype, const char* pszAddr, uint16_t unPort);
        ~CMailBox();

        void * operator new(size_t size);

        void operator delete(void* p, size_t size);

    private:
        static MemoryPool *memPool;
        static void expandMemoryPool();
        static MyLock m_lock;

    public:
        //根据配置初始化
        bool init(const MailBoxConfig& cfg);
        //
        int ConnectServer(int epfd);

        int SendAll();

    public:
        inline bool IsConnected() const
        {
            return m_bConnected;
        }

        inline void SetConnected(bool c = true)
        {
            m_bConnected = c;
        }

        inline uint8_t GetAuthz() const
        {
            return m_uAuthz;
        }

        inline void SetAuthz(uint8_t n)
        {
            m_uAuthz = n;
        }

        inline void SetFd(int fd)
        {
            m_fd = fd;
        }

        inline int GetFd() const
        {
            return m_fd;
        }

        inline EFDTYPE GetFdType() const
        {
            return m_fdType;
        }

        inline const string& GetServerName() const
        {
            return m_serverName;
        }

        inline uint16_t GetServerPort() const
        {
            return m_serverPort;
        }

#ifdef _USE_RECV_BUFF
        inline char* GetRecvBuff()
        {
            return m_szRecvBuff;
        }

        inline uint16_t GetRecvBuffLen() const
        {
            return m_unRecvBuffLen;
        }

        inline void SetRecvBuffLen(uint16_t n)
        {
            m_unRecvBuffLen = n;
        }
#else
        inline CPluto* GetRecvPluto()
        {
            return m_pluto;
        }

        inline void SetRecvPluto(CPluto* u)
        {
            m_pluto = u;
        }
#endif

#ifdef __OPTIMIZE_PLUTO
        inline uint32_t CopySendBuff(const char* buff, uint32_t len)
        {
            uint16_t leftLen = (SEND_BUFF - sendBuffPos);
            if (len > leftLen)
            {
                memcpy(sendBuff + sendBuffPos, buff, leftLen);
                sendBuffPos += leftLen;
                return leftLen;
            }
            else
            {
                memcpy(sendBuff + sendBuffPos, buff, len);
                sendBuffPos += len;
                return len;
            }
        }

        inline char* GetSendBuff()
        {
            return this->sendBuff;
        }

        inline uint32_t GetSendBuffPos()
        {
            return this->sendBuffPos;
        }

        inline void ClearSendBuff()
        {
            this->sendBuffPos = 0;
        }

        inline void ResizeSendBuff(uint32_t SendPos)
        {
            if (SendPos >= this->sendBuffPos)
            {
                this->sendBuffPos = 0;
                return;
            }

            memmove(this->sendBuff, this->sendBuff + SendPos, this->sendBuffPos - SendPos);

            this->sendBuffPos -= SendPos;

        }
#endif

        inline uint16_t GetMailboxId() const
        {
            return m_id;
        }

        inline void SetServerMbType(uint16_t t)
        {
            m_unServerMbType = t;
        }

        inline uint16_t GetServerMbType() const
        {
            return m_unServerMbType;
        }

        inline void PushPluto(CPluto* u)
        {
            m_tobeSend.push_back(u);
        }

        //发送队列是否为空
        inline bool IsSendEmpty() const
        {
            return m_tobeSend.empty();
        }

		inline void SetDeleteFlag()
		{
			m_bDeleteFlag = true;
		}

		inline bool IsDelete() const
		{
			return m_bDeleteFlag;
		}

    public:
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

    public:
        bool RpcCallFromLua(CRpcUtil& r, pluto_msgid_t msg_id, CEntityMailbox& em);

    public:
        uint16_t m_id;
        bool m_bConnected;
        
        int m_fd;
        EFDTYPE m_fdType;
        string m_serverName;
        uint16_t m_serverPort;
        time_t m_connectdTime;
        time_t m_lastTickTime;
        time_t m_timeout;
		bool m_bDeleteFlag;        //标记之后,pluto包不再处理
#ifdef _USE_RECV_BUFF
        char m_szRecvBuff[MAILBOX_RECV_BUFF_SIZE];
        uint16_t m_unRecvBuffLen;
#else
        CPluto* m_pluto;        //析构函数不要处理这个指针
#endif
        list<CPluto*> m_tobeSend;
        uint16_t m_unServerMbType;
        int m_nSendPos;         //当send阻塞的时候,记录下次接着发送的位置


#ifdef __OPTIMIZE_PLUTO
        char sendBuff[SEND_BUFF];
        uint32_t sendBuffPos;
#endif

    private:
        uint8_t m_uAuthz;          //是否已经通过认证

        CMailBox(const CMailBox&);
        CMailBox& operator=(const CMailBox&);
};

template<typename T1>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1);

    m_tobeSend.push_back(u);

    return true;
}

template<typename T1, typename T2>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1, p2);

    m_tobeSend.push_back(u);

    return true;
}

template<typename T1, typename T2, typename T3>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1, p2, p3);

    m_tobeSend.push_back(u);

    //PrintHex16(u->GetRecvBuff(), u->GetLen());

    return true;
}

template<typename T1, typename T2, typename T3, typename T4>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1, p2, p3, p4);

    m_tobeSend.push_back(u);

    return true;
}

template<typename T1, typename T2, typename T3, typename T4, typename T5>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1, p2, p3, p4, p5);

    m_tobeSend.push_back(u);

    return true;
}

template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
bool CMailBox::RpcCall(CRpcUtil& r, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6)
{
    CPluto* u = new CPluto;
    r.Encode(*u, msg_id, p1, p2, p3, p4, p5, p6);

    m_tobeSend.push_back(u);

    return true;
}


#endif

