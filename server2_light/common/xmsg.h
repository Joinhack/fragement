#ifndef __XMSG_HEAD__
#define __XMSG_HEAD__


#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>


class CMsg
{
    public:
        CMsg();
        ~CMsg();

    public:
        bool init(const char* fn, int proj_id);
        bool del();

    public:
        template<typename TBuff> bool send(const char* s, size_t n);
        template<typename TBuff> bool send(TBuff& buf, size_t n);
        template<typename TBuff> bool recv(TBuff& buf);


    private:
        int m_msgid;
        bool m_bInit;


};


template<typename TBuff>
bool CMsg::send(const char* s, size_t n)
{
    if(!m_bInit)
    {
        return false;
    }

    TBuff buf;
    buf.mtype = 1;
    memcpy(buf.mtext, s, n);
    int ret = ::msgsnd(m_msgid, &buf, n, IPC_NOWAIT);
    return ret != -1;
}

template<typename TBuff>
bool CMsg::send(TBuff& buf, size_t n)
{
    if(!m_bInit)
    {
        return false;
    }

    int ret = ::msgsnd(m_msgid, &buf, n, IPC_NOWAIT);
    return ret != -1;
}


template<typename TBuff>
bool CMsg::recv(TBuff& buf)
{
    if(!m_bInit)
    {
        return false;
    }

    ssize_t n = ::msgrcv(m_msgid, &buf, sizeof(buf.mtext), 0, IPC_NOWAIT|MSG_NOERROR);
    if(n > 0)
    {
        buf.mtext[n] = '\0';
        return true;
    }
    else
    {
        return false;
    }
}


#endif

