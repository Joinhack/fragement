#ifndef __MUTEX__H__
#define __MUTEX__H__

#include <list>

#ifndef _WIN32
#include <pthread.h>
#else
typedef int pthread_mutex_t;
typedef int pthread_t;
#endif




class CMutex
{
    public:
        CMutex(pthread_mutex_t& m);
        ~CMutex();

        void Lock();
        void UnLock();

    private:
        pthread_mutex_t& m_m;

};

class CMutexGuard
{
    public:
        CMutexGuard(pthread_mutex_t& m);
        ~CMutexGuard();

    private:
        CMutex mm;

};


#endif

