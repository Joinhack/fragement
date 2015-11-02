#ifndef __BITCRYTO__HEAD__
#define __BITCRYTO__HEAD__
#include "my_stl.h"

#ifdef _WIN32
    #pragma warning (disable:4786)
    #pragma warning (disable:4503)
#endif

namespace mogo
{

//一个简单的移位加密算法
class CBitCryto
{
public:
    CBitCryto(const char* szKey);
    ~CBitCryto();

public:
    unsigned char Encode(unsigned char c);
    unsigned char Decode(unsigned char c);

public:
    inline void Reset()
    {
        m_nIdx = 0;
    }

private:
    string m_strKey;
    size_t m_nIdx;

};

};

#endif
