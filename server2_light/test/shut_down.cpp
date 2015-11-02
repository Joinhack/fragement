#include <iostream>

#include "pluto.h"
#include "net_util.h"
#include "rpc_mogo.h"
#include "world_base.h"

void send_shutdown(int fd)
{
    CPluto c1;
    c1.Encode(MSGID_BASEAPPMGR_SHUTDOWN_SERVERS);
    c1 << (uint8_t)1 << EndPluto;
    //PrintHexPluto(c1);
    send(fd, c1.GetBuff(), c1.GetLen(), 0);
}

world* g_pTheWorld = new CWorldBase;

int main(int argc, char* argv[])
{

    if(argc < 2)
    {
        printf("Usage:%s etc_fn server_id log_fn\n", argv[0]);
        return -1;
    }

    const char* address = argv[1];
    unsigned int port = (unsigned int)atoi(argv[2]);


    cout << "shut down server" << endl;

    int fd = MogoSocket();
    int nRet = MogoConnect(fd, address, port);

    send_shutdown(fd);
    sleep(2);


    return 0;
}
