#include "cwmd.h"

CMgrServer::CMgrServer() : CEpollServer()
{

}

CMgrServer::~CMgrServer()
{

}

int CMgrServer::HandlePluto()
{
    //printf("CMgrServer::handle_pluto\n");
    CEpollServer::HandlePluto();

    return 0;
}
