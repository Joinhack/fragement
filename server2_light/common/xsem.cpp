#include "xsem.h"


CSem::CSem() : m_bInit(false), m_semid(-1)
{

}

CSem::~CSem()
{

}

bool CSem::init(const char *fn, int proj_id)
{
    key_t key = ::ftok(fn, proj_id);
    if(key == -1)
    {
        return false;
    }

    m_semid = ::semget(key, 1, IPC_CREAT|IPC_EXCL|0666);
    if(m_semid != -1)
    {
        if(init_value())
        {
            m_bInit = true;
            return true;
        }
    }

    return false;
}

bool CSem::get(const char *fn, int proj_id)
{
    key_t key = ::ftok(fn, proj_id);
    if(key == -1)
    {
        return false;
    }

    m_semid = ::semget(key, 1, IPC_EXCL);
    if(m_semid != -1)
    {
        m_bInit = true;
        return true;
    }

    return false;
}

bool CSem::del()
{
    int n = ::semctl(m_semid, 0, IPC_RMID, NULL);
    return n == 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////

union semun
{
    int val;
};

CSemMutex::CSemMutex()
{

}

CSemMutex::~CSemMutex()
{

}

bool CSemMutex::init_value()
{
    union semun u;
    u.val = 1;
    int n = ::semctl(m_semid, 0, SETVAL, u);
    return n != -1;
}

bool CSemMutex::lock()
{
    sembuf buf;
    buf.sem_num = 0;
    buf.sem_op = -1;
    buf.sem_flg = SEM_UNDO;
    int n = ::semop(m_semid, &buf, 1);
    return n == 0;
}

bool CSemMutex::unlock()
{
    sembuf buf;
    buf.sem_num = 0;
    buf.sem_op = 1;
    buf.sem_flg = SEM_UNDO;
    int n = ::semop(m_semid, &buf, 1);
    return n == 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////

CSemMutexGuard::CSemMutexGuard(CSemMutex& s) : m_s(s)
{
    m_s.lock();
}

CSemMutexGuard::~CSemMutexGuard()
{
    m_s.unlock();
}


