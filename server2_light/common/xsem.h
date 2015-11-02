#ifndef __XSEM_HEAD__
#define __XSEM_HEAD__

#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/sem.h>


class CSem
{
    public:
        CSem();
        virtual ~CSem();

    public:
        //由单独的一个初始化进程来调用init，其他进程只能调用get
        bool init(const char* fn, int proj_id);
        bool get(const char* fn, int proj_id);
        bool del();

    protected:
        virtual bool init_value() = 0;

    protected:
        int m_semid;
        bool m_bInit;

};


class CSemMutex : public CSem
{
    public:
        CSemMutex();
        ~CSemMutex();

    protected:
        bool init_value();

    public:
        bool lock();
        bool unlock();

};


class CSemMutexGuard
{
    public:
        CSemMutexGuard(CSemMutex& s);
        ~CSemMutexGuard();

    private:
        CSemMutex& m_s;

};



#endif
