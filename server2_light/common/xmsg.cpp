#include "xmsg.h"



CMsg::CMsg() : m_bInit(false), m_msgid(-1)
{

}

CMsg::~CMsg()
{

}


bool CMsg::init(const char* fn, int proj_id)
{
    key_t key = ::ftok(fn, proj_id);
    if(key == -1)
    {
        return false;
    }

    m_msgid = ::msgget(key, IPC_CREAT|IPC_EXCL|0666);
    if(m_msgid != -1)
    {
        m_bInit = true;
        return true;
    }
    else if(errno == EEXIST)
    {
        m_msgid = ::msgget(key, IPC_EXCL);
        if(m_msgid != -1)
        {
            m_bInit = true;
            return true;
        }
    }

    return false;
}


bool CMsg::del()
{
    int n = ::msgctl(m_msgid, IPC_RMID, NULL);
    return n == 0;
}


