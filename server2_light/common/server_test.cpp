#include <stdio.h>
#include "xmsg.h"
#include "xsem.h"
#include "net_util.h"
#include "epoll_server.h"

/*
struct mybuf
{
    long mtype;
    char mtext[1024];
};

int msg_test()
{
    CMsg msg;
    if(!msg.init("/home/jh/ddev/sv/ipc/1", 1))
    {
        ERROR_RETURN();
    }
    printf("init\n");

    if(!msg.send<mybuf>("i'm msgaaaaa", 7))
    {
        ERROR_RETURN();
    }
    printf("sended\n");

    char msg2[] = "msg_22222222";
    mybuf sendbuf;
    sendbuf.mtype = 1;
    strcpy(sendbuf.mtext, msg2);
    if(!msg.send(sendbuf, sizeof(msg2)))
    {
        ERROR_RETURN();
    }
    printf("sended msg2\n");

    mybuf recvbuf;
    if(!msg.recv<mybuf>(recvbuf))
    {
        ERROR_RETURN();
    }
    printf("recved:%s\n", recvbuf.mtext);

    if(!msg.recv<mybuf>(recvbuf))
    {
        ERROR_RETURN();
    }
    printf("recved2:%s\n", recvbuf.mtext);

    if(!msg.del())
    {
        ERROR_RETURN();
    }
    printf("del\n");

}

int sem_test()
{
    CSemMutex sem;
    if(!sem.init("/home/jh/ddev/sv/ipc/5", 1))
    {
        ERROR_RETURN();
    }
    printf("init\n");

    CSemMutex sem2;
    if(!sem2.get("/home/jh/ddev/sv/ipc/5", 1))
    {
        ERROR_RETURN();
    }
    printf("get2\n");

    CSemMutexGuard g(sem2);

    sem2.del();
}


int nt_test()
{
    CProxyServer s;
    s.Service("", 11111);
}

int main(int argc, char* argv[])
{
    printf("begin...\n");

    //msg_test();
    //sem_test();
    nt_test();

    return 0;
}

*/
