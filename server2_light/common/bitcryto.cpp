/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：bitcryto
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：简单的移位加密算法
//----------------------------------------------------------------*/
#include <string>
#include <string.h>

#include "bitcryto.h"

using std::string;

namespace mogo
{

    CBitCryto::CBitCryto(const char* szKey, size_t nSize) : m_nKeySize(nSize), m_nIdx(0)
    {
        m_pszKey = new unsigned char[nSize];
        memcpy(m_pszKey, szKey, nSize);
    }

    CBitCryto::~CBitCryto()
    {
        delete[] m_pszKey;
    }

    unsigned char CBitCryto::Encode(unsigned char c)
    {
        if(m_nIdx >= m_nKeySize)
        {
            m_nIdx = 0;
        }

        unsigned short k = (unsigned short)m_pszKey[m_nIdx];
        ++m_nIdx;

        unsigned char c2 = (unsigned char)((k + (unsigned short)c) & 0xff);

        return c2;
    }

    unsigned char CBitCryto::Decode(unsigned char c)
    {
        if(m_nIdx >= m_nKeySize)
        {
            m_nIdx = 0;
        }
        short k = (short)m_pszKey[m_nIdx];
        ++m_nIdx;

        short c2 = (short)c - k;
        if(c2 < 0)
        {
            c2 += 256;
        }

        return (unsigned char)c2;
    }

};
