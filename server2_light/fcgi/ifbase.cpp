#include "ifbase.h"
#include <openssl/md5.h>
#include "pluto.h"


CIfBase::CIfBase()
{

}

CIfBase::~CIfBase()
{

}

void CIfBase::SetServName(const char* pszServName)
{
    m_strServName.assign(pszServName);

    string::size_type pos1 = m_strServName.find('.');
    if(pos1 != string::npos)
    {
        m_strServName.erase(pos1);
    }
}

const string& get_dict_field(const map<string, string>& dict, const string& strKey)
{
	map<string, string>::const_iterator iter = dict.find(strKey);
	if(iter != dict.end())
	{
		return iter->second;
	}

	const static string strEmpty = "";
	return strEmpty;
}

//兼容getenv返回NULL和""两种情况
char* my_getenv(const char* s)
{
    char* p = ::getenv(s);
    if(p == NULL)
    {
        static const char* p2 = "";
        return (char*)p2;
    }

    return p;
}

string getmd5(const string& src)
{
	enum{ SIZE16 = 16,};
	unsigned char szMd5[SIZE16];
	MD5((unsigned char*)src.c_str(), src.size(), szMd5);

	char szKey[64];
	memset(szKey, 0, sizeof(szKey));
	for(int i=0; i<SIZE16; ++i)
	{
		char_to_sz(szMd5[i], szKey+2*i);			
	}
	return szKey;
}