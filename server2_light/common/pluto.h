#ifndef __PLUTO__HEAD__
#define __PLUTO__HEAD__


//pluto:冥王星,离太阳最远的行星,跑得最慢
//Mercury:水星,离太阳最近的行星,公转最快


#include "type_mogo.h"
#include "bitcryto.h"
#include "memory_pool.h"
#include <ctype.h>
#include "util.h"
#include "mutex.h"

enum
{
    MSGLEN_HEAD             = 4,                                              //消息包头长度
    MSGLEN_RESERVED         = 2,                                              //保留2位,可用作版本或其他
    MSGLEN_MSGID            = 2,                                              //消息id长度
    MSGLEN_TEXT_POS         = MSGLEN_HEAD + MSGLEN_RESERVED + MSGLEN_MSGID,   //正文开始的位置
    MSGLEN_MAX              = 65000,                                          //消息包最大长度

    PLUTO_CLIENT_MSGLEN_MAX = 65000,                                          //客户端包的最大长度
    PLUTO_MSGLEN_HEAD       = MSGLEN_HEAD,                                    //便于其他模块引用
    PLUTO_FILED_BEGIN_POS   = MSGLEN_HEAD + MSGLEN_RESERVED + MSGLEN_MSGID,   //字段开始的位置,此前的位置都是协议自己需要的
};


#define REVERSE_CONVERT     0           //针对数据类型是否做大小端转换(Big/Little Endian Convert)


/*
union FLOAT32_CONVERT
{
    float32_t f;
    unsigned char s[sizeof(float32_t)];
};

union FLOAT64_CONVERT
{
    float64_t f;
    unsigned char s[sizeof(float64_t)];
};

union UINT64_CONVERT
{
    uint64_t i;
    unsigned char s[sizeof(uint64_t)];
};
*/

//#ifdef _CROSS_SERVER_ID
enum
{
    SERVER_NONE          = 0,
    SERVER_LOGINAPP      = 1,
    SERVER_BASEAPPMGR    = 2,
    SERVER_DBMGR         = 3,
    SERVER_TIMERD        = 4,
    SERVER_LOG           = 5, //日志服务器
    SERVER_BASEAPP       = 6,
    SERVER_CELLAPP       = 7,
    SERVER_CLIENT        = 8,
    SERVER_CROSSCLIENT   = 9,
    SERVER_CROSSSERVER   = 10,
    //SERVER_PROXY         = 1,
    //SERVER_CELLAPPMGR    = 4,

    //可能启动多个进程的服务器最小id从这里开始 >=; 
    //baseapp和cellapp虽然server_type为6/7,但server_id是从这个值开始的
    SERVER_MULTI_MIN_ID  = 6,

    SERVER_MAILBOX_RESERVE_SIZE = 30,   //预设30个服务器进程
};
//#else
//enum
//{
//    SERVER_NONE          = 0,
//    SERVER_LOGINAPP      = 1,
//    SERVER_BASEAPPMGR    = 2,
//    SERVER_DBMGR         = 3,
//    SERVER_TIMERD        = 4,
//    SERVER_LOG           = 5, //日志服务器
//
//
//    //SERVER_PROXY         = 1,
//    //SERVER_CELLAPPMGR    = 4,
//
//    SERVER_BASEAPP       = 6,
//    SERVER_CELLAPP       = 7,
//
//    SERVER_MULTI_MIN_ID  = 5,       //可能启动多个进程的服务器最小id从这里开始
//
//    SERVER_CLIENT        = 8,
//
//    SERVER_CROSSCLIENT   = 14,
//    SERVER_CROSSSERVER   = 15,
//
//    SERVER_MAILBOX_RESERVE_SIZE = 30,   //预设30个服务器进程
//};
//#endif

enum
{
    MSGTYPE_LOGINAPP     = SERVER_LOGINAPP << 12,      //0x2000
    MSGTYPE_BASEAPPMGR   = SERVER_BASEAPPMGR << 12,    //0x3000
    //MSGTYPE_CELLAPPMGR   = SERVER_CELLAPPMGR << 12,    //0x4000
    MSGTYPE_BASEAPP      = SERVER_BASEAPP << 12,       //0x5000
    MSGTYPE_CELLAPP      = SERVER_CELLAPP << 12,       //0x6000
    MSGTYPE_DBMGR        = SERVER_DBMGR << 12,         //0x7000
    MSGTYPE_LOG          = SERVER_LOG << 12,
    MSGTYPE_CROSSCLIENT  = SERVER_CROSSCLIENT << 12,
    MSGTYPE_CROSSSERVER  = SERVER_CROSSSERVER << 12,

};


extern bool IsValidMsgid(uint16_t msgid);
extern void uint8_to_sz(uint8_t n, char* s);
extern void uint16_to_sz(uint16_t n, char* s);
extern void uint32_to_sz(uint32_t n, char* s);
extern void uint64_to_sz(uint64_t n, char* s);
extern void float32_to_sz(float32_t n, char* s);
extern void float64_to_sz(float64_t n, char* s);
extern uint8_t sz_to_uint8(unsigned char* s);
extern uint16_t sz_to_uint16(unsigned char* s);
extern uint32_t sz_to_uint32(unsigned char* s);
extern uint64_t sz_to_uint64(unsigned char* s);
extern float32_t sz_to_float32(unsigned char* s);
extern float64_t sz_to_float64(unsigned char* s);
//将值如0x12的char转换为字符串"12"
extern void char_to_sz(unsigned char c, char* s);
//将形如"12"的字符创转换为值为0x12的char
extern unsigned char sz_to_char(char* s);
extern void PrintHex16(const char* s, size_t n);
extern void PrintHex(const char* s, size_t n);

struct charArrayDummy
{
    charArrayDummy() ;
    ~charArrayDummy();

    uint16_t m_l;
    char* m_s;
};

class CMailBox;

template<typename T>
T sz_to_msgid(unsigned char* s);

template<>
inline uint16_t sz_to_msgid<uint16_t>(unsigned char* s)
{
    return sz_to_uint16(s);
}


using namespace mogo;


//从pluto中解析出来的entity prop数据集合
struct SEntityPropFromPluto
{
    TENTITYTYPE etype;
    map<string, VOBJECT*> data;

    ~SEntityPropFromPluto();
};

enum { DEFAULT_PLUTO_BUFF_SIZE = 256, };       //缺省的buff_size

class CPluto
{
    public:
        CPluto(uint32_t buff_size = DEFAULT_PLUTO_BUFF_SIZE);  //for encode
        CPluto(const char* s, uint32_t n);  //for decode
        ~CPluto();

#ifdef _PLUTO_POOL
        void * operator new(size_t size);

        void operator delete(void* p, size_t size);
#endif

    public:
        //输入
        CPluto& Encode(pluto_msgid_t msgid);
        CPluto& operator<< (uint8_t n);
        CPluto& operator<< (uint16_t n);
        CPluto& operator<< (uint32_t n);
        CPluto& operator<< (uint64_t n);
        CPluto& operator<< (int8_t n);
        CPluto& operator<< (int16_t n);
        CPluto& operator<< (int32_t n);
        CPluto& operator<< (int64_t n);
        CPluto& operator<< (float32_t f);
        CPluto& operator<< (float64_t f);
        CPluto& operator<< (const char* s);
        CPluto& operator<< (const string& s);
        CPluto& operator<< (const charArrayDummy& r);
        typedef CPluto& (*pluto_op) (CPluto&);
        CPluto& operator<< (pluto_op op);
        friend CPluto& endPluto(CPluto& p);
        CPluto& operator<< (const CEntityMailbox& m);
        CPluto& operator<< (const CEntityParent& e);
        CPluto& FillPluto(const VOBJECT& v);
        CPluto& FillPlutoFromStr(VTYPE vt, const char* s, unsigned long ll);
        CPluto& FillPlutoFromLua(VTYPE vt, lua_State* L, int idx);

    private:
        //encode时自动调整buff大小
        void Resize(uint32_t n);

    public:
        //这个方法类似于operator<<,可用于实现链式表达式
        template<typename T>
        CPluto& FillField(const T& value);
        //不输入buff的长度,只输入buff内容
        CPluto& FillBuff(const char* s, uint32_t n);
        //类似于EndPluto
        CPluto& endPluto();

    public:
        //替换掉某个位置开始的一个字段的值
        template<typename T>
        void ReplaceField(uint32_t nIdx, const T& value);

    public:
        //输出
        //包头里记录的包长度
        uint32_t GetMsgLen();
        //去掉包头的剩下长度
        uint32_t GetMsgLeftLen();
        //消息id
        pluto_msgid_t GetMsgId();
        CPluto& Decode();
        CPluto& operator>> (uint8_t& n);
        CPluto& operator>> (uint16_t& n);
        CPluto& operator>> (uint32_t& n);
        CPluto& operator>> (uint64_t& n);
        CPluto& operator>> (int8_t& n);
        CPluto& operator>> (int16_t& n);
        CPluto& operator>> (int32_t& n);
        CPluto& operator>> (int64_t& n);
        CPluto& operator>> (float32_t& f);
        CPluto& operator>> (float64_t& f);
        CPluto& operator>> (charArrayDummy& d);
        CPluto& operator>> (string& s);
        CPluto& operator>> (CEntityMailbox& m);
        void FillVObject(VTYPE vt, VOBJECT& v);
        bool UnpickleEntity(VOBJECT& v);


    public:
        inline const char* GetBuff() const
        {
            return m_szBuff;
        }

        inline char* GetRecvBuff()
        {
            return m_szBuff;
        }

        inline void SetLen(uint32_t n)
        {
            m_unLen = n;
        }
        inline void SetMaxLen(uint32_t n)
        {
            m_unMaxLen = n;
        }

        inline void EndRecv(uint32_t n)
        {
            m_unLen = n;
            m_unMaxLen = n;
        }

        inline uint32_t GetBuffSize() const
        {
            return m_unBuffSize;
        }

        inline uint32_t GetLen() const
        {
            return m_unLen;
        }

        inline uint32_t GetMaxLen() const
        {
            return m_unMaxLen;
        }

        inline CMailBox* GetMailbox()
        {
            return m_mb;
        }

        inline void SetMailbox(CMailBox* mb)
        {
            m_mb = mb;
        }

        inline bool IsEnd() const
        {
            return m_unLen >= m_unMaxLen;
        }

        inline uint32_t GetDecodeErrIdx() const
        {
            return m_nDecodeErrIdx;
        }

		inline bool IsEncodeErr() const
		{
			return m_bEncodeErr;
		}

		inline void SetEncodeErr()
		{
			m_bEncodeErr = true;
		}

#ifdef __OPTIMIZE_PLUTO
        inline uint32_t GetSendPos() const
        {
            return m_SendPos;
        }

        inline void SetSendPos(uint32_t Pos)
        {
            this->m_SendPos = Pos;
        }
#endif

    private:
        static MemoryPool *memPool;
        static void expandMemoryPool();
        static MyLock m_lock;

        char* m_szBuff;
        uint32_t m_unBuffSize;
        uint32_t m_unLen;
        uint32_t m_unMaxLen;
        uint32_t m_nDecodeErrIdx;
        CMailBox* m_mb;
		bool m_bEncodeErr;  //编码是否出错


        CPluto(const CPluto&);
        CPluto& operator=(const CPluto&);

#ifdef __OPTIMIZE_PLUTO
        uint32_t m_SendPos;    //记录已经拷贝到发送缓冲区的buff偏移
#endif
};

template<typename T>
CPluto& CPluto::FillField(const T& value)
{
    (*this) << value;
    return *this;
}

template<typename T>
void CPluto::ReplaceField(uint32_t nIdx, const T& value)
{
    uint32_t old_len = m_unLen;
    m_unLen = nIdx;
    (*this) << value;
    m_unLen = old_len;
}

CPluto& EndPluto(CPluto& p);

extern void PrintHexPluto(CPluto& c);



class CPlutoList
{
public:
	CPlutoList();
	~CPlutoList();

public:
	bool InitMutex();
	void PushPluto(CPluto* p);
	CPluto* PopPluto();
	bool Empty();

private:
	pthread_mutex_t m_mutex_t;
	bool m_init;
	std::list<CPluto*> m_list;
};

#endif

