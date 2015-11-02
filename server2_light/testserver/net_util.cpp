/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：net_util
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：对socket 的简单包装
//----------------------------------------------------------------*/

#include "net_util.h"

namespace mogo
{

bool MogoSetNonblocking(int sockfd)
{
    return fcntl(sockfd, F_SETFL, fcntl(sockfd, F_GETFD, 0)|O_NONBLOCK) != -1;
}

int MogoSocket()
{
    return socket(PF_INET, SOCK_STREAM, 0);
}

int MogoBind(int sockfd, const char* pszAddr, unsigned int unPort)
{
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = PF_INET;
    addr.sin_port = htons(unPort);

    if(pszAddr == NULL || strcmp(pszAddr, "") == 0)
    {
        addr.sin_addr.s_addr = INADDR_ANY;
    }
    else
    {
        addr.sin_addr.s_addr = inet_addr(pszAddr);
    }

    int flag = 1;
    int len = sizeof(int);
    setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &flag, len); 
    return bind(sockfd, (struct sockaddr*)&addr, sizeof(addr) );
}

int MogoListen(int sockfd, int backlog/* = 5*/)
{
    return listen(sockfd, backlog);
}

int MogoConnect(int fd, const char* pszAddr, unsigned int unPort)
{
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = PF_INET;
    addr.sin_port = htons(unPort);
    addr.sin_addr.s_addr = inet_addr(pszAddr);

    return connect(fd, (sockaddr*)&addr, sizeof(addr));
}

};
