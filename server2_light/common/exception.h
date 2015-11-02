#ifndef __EXCEPTION__HEAD__
#define __EXCEPTION__HEAD__

#ifdef _WIN32
#pragma warning (disable:4786)
#pragma warning (disable:4503)
#endif

#include "my_stl.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include "util.h"



namespace mogo
{

    //自定义异常类
    class CException
    {
        public:
            CException(int nCode, const string& strMsg);
            CException(int nCode, const char* pszMsg);
            //CException(int nCode, const char* pszMsg, ...);
            ~CException();

        public:
            inline int GetCode() const
            {
                return m_nCode;
            }

            inline string GetMsg() const
            {
                return m_strMsg;
            }

        private:
            int m_nCode;
            string m_strMsg;

    };


    inline void ThrowException(int n, const string& s)
    {
        throw CException(n, s);
    }


    //inline void throwException(int n, const char* s)
    //{
    //  throw CException(n, s);
    //}


    extern void ThrowException(int n, const char* s, ...);

};

#endif
