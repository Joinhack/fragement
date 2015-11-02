#include "mutex.h"

CMutex::CMutex(pthread_mutex_t& m) : m_m(m)
{
}


CMutex::~CMutex()
{
}

void CMutex::Lock()
{
#ifndef _WIN32
    pthread_mutex_lock(&m_m);
#endif
}


void CMutex::UnLock()
{
#ifndef _WIN32
    pthread_mutex_unlock(&m_m);
#endif
}

CMutexGuard::CMutexGuard(pthread_mutex_t& m):mm(m)
{
    mm.Lock();
}

CMutexGuard::~CMutexGuard()
{
    mm.UnLock();
}
