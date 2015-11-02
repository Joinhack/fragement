/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：pluto
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：rpc 以及 entity 的二进制封装
//----------------------------------------------------------------*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <string>

#include "pluto.h"
#include "util.h"
#include "entity.h"
#include "defparser.h"
#include "world_select.h"


using namespace std;


CBitCryto sg_mycryto("\0\0\0\0\0");	//客户端服务器交互包加解密类


charArrayDummy::charArrayDummy() : m_l(0), m_s(NULL)
{
}

charArrayDummy::~charArrayDummy()
{
    if(m_l > 0)
    {
        delete[] m_s;
    }
}


bool IsValidMsgid(uint16_t msgid)
{
    return true;
}
void bool_to_sz(bool n, char *s)
{
     uint8_to_sz((uint8_t)n, s);

}
void uint8_to_sz(uint8_t n, char* s)
{
    s[0] = n;
}

void uint16_to_sz(uint16_t n, char* s)
{
    s[0] = (n >> 8) & 0xff ;
    s[1] = n & 0xff;
}

void uint32_to_sz(uint32_t n, char* s)
{
    s[0] = (n >> 24) & 0xff ;
    s[1] = (n >> 16) & 0xff ;
    s[2] = (n >> 8) & 0xff ;
    s[3] = n & 0xff;
}

//void uint64_to_sz(uint64_t n, char* s)
//{
//    s[0] = (n >> 56) & 0xff ;
//    s[1] = (n >> 48) & 0xff ;
//    s[2] = (n >> 40) & 0xff ;
//    s[3] = (n >> 32) & 0xff ;
//    s[4] = (n >> 24) & 0xff ;
//    s[5] = (n >> 16) & 0xff ;
//    s[6] = (n >> 8) & 0xff ;
//    s[7] = n & 0xff;
//}
bool sz_to_bool(unsigned char *s)
{

    return sz_to_uint8(s);
}
uint8_t sz_to_uint8(unsigned char* s)
{
    return s[0];
}

uint16_t sz_to_uint16(unsigned char* s)
{
    return (s[0] << 8) + s[1];
   
}

uint32_t sz_to_uint32(unsigned char* s)
{
    ////printf("s[0]:%c s[1]:%c s[2]:%c s[3]:%c\n", s[0], s[1], s[2], s[3]);
    return (s[0] << 24) + (s[1] << 16) + (s[2] << 8) + s[3];
 

}

//uint64_t sz_to_uint64(unsigned char* s)
//{
//    return (s[0] << 56) + (s[1] << 48) + (s[2] << 40) + (s[3] << 32) \
//        + (s[4] << 24) + (s[5] << 16) + (s[6] << 8) + s[7];
//}

//将值如0x12的char转换为字符串"12"
void char_to_sz(unsigned char c, char* s)
{
    //char tmp[3];
    //tmp[2] = '\0';
    //s//printf(tmp, "%02x", c);
    //s[0] = tmp[0];
    //s[1] = tmp[1];

    const static char char_map[] = "0123456789abcdef";

    unsigned char c1 = (c >> 4) & 0xf;
    unsigned char c2 = c & 0xf;
    s[0] = char_map[c1];
    s[1] = char_map[c2];

}

//将形如"12"的字符创转换为值为0x12的char
unsigned char sz_to_char(char* s)
{
	unsigned int i;
	sscanf(s, "%02x", &i);
	unsigned char c = (unsigned char)i;
	return c;
}

void PrintHex16(const char* s, size_t n)
{
    char buf[16*3 + 3 + 16 + 1 + 1];
    memset(buf, ' ', sizeof(buf) - 1);
    buf[sizeof(buf)-1] = '\0';

    for(size_t i=0; i<n; ++i)
    {
        unsigned char c = s[i];
        char_to_sz(c, buf+i*3);

        if(isprint(c))
        {
            buf[51+i] = c;
        }
        else
        {
            buf[51+i] = '.';
        }
    }
#ifdef _WIN32
	//printf("%s\n", buf);
#endif
    
	g_logger.NewLine() << buf << EndLine;
}

void PrintHex(const char* s, size_t n)
{
    size_t sixteen = 16;
    size_t count = n / sixteen + 1;

    for(size_t i=0; i<count; ++i)
    {
        if(i == count-1)
        {
            PrintHex16(s+i*sixteen, n % sixteen);
        }
        else
        {
            PrintHex16(s+i*sixteen, sixteen);
        }
    }

}
/*
void PrintHexPluto(CPluto& c)
{
	uint32_t n = max(c.GetLen(), c.GetMaxLen());
    PrintHex(c.GetBuff(), n);
}

*/
SEntityPropFromPluto::~SEntityPropFromPluto()
{
    ClearMap(data);
}

////////////////////////////////////////////////////////////////////////////////////////

CPluto::CPluto(uint32_t buff_size/* = DEFAULT_PLUTO_BUFF_SIZE*/) : m_unLen(0), m_unMaxLen(0), m_nDecodeErrIdx(0), m_mb(NULL)
{
	m_szBuff = new char[buff_size];
	m_unBuffSize = buff_size;
}

CPluto::CPluto(const char* s, uint32_t n) : m_unLen(n), m_unMaxLen(n), m_nDecodeErrIdx(0), m_mb(NULL), m_unBuffSize(n)
{
	m_szBuff = new char[n];
    memcpy(m_szBuff, s, n);
}

CPluto::~CPluto()
{
	delete[] m_szBuff;
}

//输入
CPluto& CPluto::Encode(pluto_msgid_t msgid)
{
    m_unLen = MSGLEN_HEAD + MSGLEN_RESERVED;
    //printf("encode MSGLEN_MSGID : %d\n", msgid);
    (*this) << msgid;
    return *this;
}

//encode时自动调整buff大小
void CPluto::Resize(uint32_t n)
{
	if(m_unLen + n <= m_unBuffSize)
	{
		return;
	}

	//buff大小不足,需要扩展
	LogWarning("CPluto::resize", "msg=%d;old=%u", GetMsgId(), m_unBuffSize);

	m_unBuffSize = (m_unLen+n)*2;
	char* new_buff = new char[m_unBuffSize];
	
	memcpy(new_buff, m_szBuff, m_unLen);

	delete[] m_szBuff;
	m_szBuff = new_buff;
}
CPluto& CPluto::operator<< (bool n)
{
    Resize(sizeof(n));
    bool_to_sz(n, m_szBuff + m_unLen);
    m_unLen += sizeof(n);
    return *this;
}

CPluto& CPluto::operator<< (uint8_t n)
{
	Resize(sizeof(n));

    uint8_to_sz(n, m_szBuff + m_unLen);
    m_unLen += sizeof(n);
    return *this;
}

CPluto& CPluto::operator<< (uint16_t n)
{
	Resize(sizeof(n));

    uint16_to_sz(n, m_szBuff + m_unLen);
    m_unLen += sizeof(n);
    return *this;
}

CPluto& CPluto::operator<< (uint32_t n)
{
	Resize(sizeof(n));

    uint32_to_sz(n, m_szBuff + m_unLen);
    m_unLen += sizeof(n);
    return *this;
}

CPluto& CPluto::operator<< (uint64_t n)
{
	Resize(sizeof(n));

    UINT64_CONVERT u;
    u.i = n;
    memcpy(m_szBuff+m_unLen, u.s, sizeof(n));
    m_unLen += sizeof(n);
    return *this;
}

CPluto& CPluto::operator<< (int8_t n)
{
    uint8_t n2 = (uint8_t)n;
    (*this) << n2;
    return *this;
}

CPluto& CPluto::operator<< (int16_t n)
{
    uint16_t n2 = (uint16_t)n;
    (*this) << n2;
    return *this;
}

CPluto& CPluto::operator<< (int32_t n)
{
    uint32_t n2 = (uint32_t)n;
    (*this) << n2;
    return *this;
}

CPluto& CPluto::operator<< (int64_t n)
{
    uint64_t n2 = (uint64_t)n;
    (*this) << n2;
    return *this;
}

CPluto& CPluto::operator<< (float32_t f)
{
	Resize(sizeof(f));

    FLOAT32_CONVERT u;
    u.f = f;
    memcpy(m_szBuff + m_unLen, u.s, sizeof(f));
    m_unLen += sizeof(f);
    return *this;
}

CPluto& CPluto::operator<< (float64_t f)
{
	Resize(sizeof(f));

    FLOAT64_CONVERT u;
    u.f = f;
    memcpy(m_szBuff + m_unLen, u.s, sizeof(f));
    m_unLen += sizeof(f);
    return *this;
}

CPluto& CPluto::operator<< (const char* s)
{
    uint16_t n = (uint16_t)strlen(s);

	Resize(sizeof(uint16_t)+n);

    (*this) << n;
    strcpy(m_szBuff + m_unLen, s);
    m_unLen += n;
    return *this;
}

CPluto& CPluto::operator<< (const string& s)
{
	uint16_t n = (uint16_t)s.size();

	Resize(sizeof(uint16_t) + n);

	(*this) << n;
	strcpy(m_szBuff + m_unLen, s.c_str());
	m_unLen += n;
	return *this;
}

CPluto& CPluto::operator<< (const charArrayDummy& r)
{
	Resize(sizeof(uint16_t) + r.m_l);

    (*this) << r.m_l;
    memcpy(m_szBuff + m_unLen, r.m_s, r.m_l);
    m_unLen += r.m_l;
    return *this;
}

CPluto& CPluto::operator<< (pluto_op op)
{
    return (*op)(*this);
}

CPluto& CPluto::operator<< (const CEntityMailbox& m)
{
    (*this) << m.m_nServerMailboxId << m.m_nEntityType << m.m_nEntityId;
    return (*this);
}

CPluto& CPluto::operator<< (const CEntityParent& e)
{
    CPluto& u = *this;
    e.PickleToPluto(u);
    return u;
}

//输出
//包头里记录的包长度
uint32_t CPluto::GetMsgLen()
{
    return sz_to_uint32((unsigned char*)m_szBuff);
}

//去掉包头的剩下长度
uint16_t CPluto::GetMsgLeftLen()
{
    return GetMsgLen() - MSGLEN_HEAD;
}

//消息id
pluto_msgid_t CPluto::GetMsgId()//16bits
{
    // unsigned char *p = (unsigned char *)(m_szBuff);
    // return sz_to_msgid<pluto_msgid_t>(*(p + 1) << 8 + *(p));
    return sz_to_msgid<pluto_msgid_t>((unsigned char*)(m_szBuff + MSGLEN_HEAD + MSGLEN_RESERVED));
}

CPluto& CPluto::Decode()
{
/*
	if(GetMsgId() < MAX_CLIENT_SERVER_MSGID)
	{
		//客户端包需要解密
		sg_mycryto.Reset();
        //MSGLEN_TEXT_POS  = 8 为第八个位置 
		for(uint32_t i=MSGLEN_TEXT_POS; i<m_unMaxLen; ++i)
		{
			m_szBuff[i] = sg_mycryto.Decode(m_szBuff[i]);
		}
	}
*/
	//print_hex_pluto(*this);
    m_unLen = MSGLEN_HEAD + MSGLEN_RESERVED + MSGLEN_MSGID;
    return *this;
}
/*
   according to the item type get the limited length content
*/

CPluto& CPluto::operator>> (bool& n)
{
    uint32_t nNewLen = m_unLen + sizeof(n);
    if(nNewLen > m_unMaxLen)
    {
       m_nDecodeErrIdx = m_unLen;

    }else
    {
       n = sz_to_bool((unsigned char*)m_szBuff + m_unLen);
       //printf("bool >> : value: %d\n", n);
       m_unLen = nNewLen;

    }
    return *this;
     
}
CPluto& CPluto::operator>>(uint8_t& n)
{
	uint32_t nNewLen = m_unLen + sizeof(n);
    
	if(nNewLen > m_unMaxLen)
	{
		//字符数不够解析
		m_nDecodeErrIdx = m_unLen;
	}
	else
	{
		n = sz_to_uint8((unsigned char*)m_szBuff + m_unLen);
        //printf("uint8_t >> : value : %d\n", n);
		m_unLen = nNewLen;
	}

    return *this;
}

CPluto& CPluto::operator>>(uint16_t& n)
{
    //printf("uint16_t >> start\n");
	uint32_t nNewLen = m_unLen + sizeof(n);
	if(nNewLen > m_unMaxLen)
	{
		//字符数不够解析
        //printf("error idx \n");
		m_nDecodeErrIdx = m_unLen;
	}
	else
	{
		n = sz_to_uint16((unsigned char*)m_szBuff + m_unLen);
        //printf("uint16_t >> : value : %d\n", n);
		m_unLen = nNewLen;
	}

	return *this;
}

CPluto& CPluto::operator>>(uint32_t& n)
{
	uint32_t nNewLen = m_unLen + sizeof(n);
	if(nNewLen > m_unMaxLen)
	{
		//字符数不够解析
		m_nDecodeErrIdx = m_unLen;
	}
	else
	{
		n = sz_to_uint32((unsigned char*)m_szBuff + m_unLen);
        //printf("uint32_t >> : value : %d\n", n);
		m_unLen = nNewLen;
	}

	return *this;
}

CPluto& CPluto::operator>>(uint64_t& n)
{
	uint32_t nNewLen = m_unLen + sizeof(n);
	if(nNewLen > m_unMaxLen)
	{
		//字符数不够解析
		m_nDecodeErrIdx = m_unLen;
	}
	else
	{
		UINT64_CONVERT u;
		memcpy(u.s, m_szBuff + m_unLen, sizeof(n));
		m_unLen = nNewLen;
		n = u.i;
        //printf("uint64_t >> : value : %d\n", n);
	}

	return *this;
}

CPluto& CPluto::operator>>(int8_t& n)
{
    uint8_t n2;
    (*this) >> n2;
    n = (int8_t) n2;
    return *this;
}

CPluto& CPluto::operator>>(int16_t& n)
{
    uint16_t n2;
    (*this) >> n2;
    n = (int16_t) n2;
    return *this;
}

CPluto& CPluto::operator>>(int32_t& n)
{
    uint32_t n2;
    (*this) >> n2;
    n = (int32_t) n2;
    return *this;
}

CPluto& CPluto::operator>>(int64_t& n)
{
    uint64_t n2;
    (*this) >> n2;
    n = (int64_t) n2;
    return *this;
}

CPluto& CPluto::operator>>(float32_t& f)
{
	uint32_t nNewLen = m_unLen + sizeof(f);
	if(nNewLen > m_unMaxLen)
	{
		//字符数不够解析
		m_nDecodeErrIdx = m_unLen;
	}
	else
	{
		FLOAT32_CONVERT u;
		memcpy(u.s, m_szBuff + m_unLen, sizeof(f));
		m_unLen = nNewLen;
		f = u.f;
        //printf("float32_t >> : value : %f\n", f);
	}

	return *this;
}

CPluto& CPluto::operator>>(float64_t& f)
{
	uint32_t nNewLen = m_unLen + sizeof(f);
	if(nNewLen > m_unMaxLen)
	{
		//字符数不够解析
		m_nDecodeErrIdx = m_unLen;
	}
	else
	{
		FLOAT64_CONVERT u;
		memcpy(u.s, m_szBuff + m_unLen, sizeof(f));
		m_unLen = nNewLen;
		f = u.f;
        //printf("float64_t >> : value : %f\n", f);
	}

	return *this;
}

CPluto& CPluto::operator>> (charArrayDummy& d)
{
	uint16_t buff_size = 0;
	(*this) >> buff_size;
	
	if(this->GetDecodeErrIdx() == 0)
	{
		if(buff_size > 0)
		{
			if(d.m_l > 0)
			{
				delete[] d.m_s;
			}

			uint32_t nNewLen = m_unLen + buff_size;
			if(nNewLen > m_unMaxLen)
			{
				m_nDecodeErrIdx = m_unLen;
			}
			else
			{
				d.m_l = buff_size;
				d.m_s = new char[buff_size];
				memcpy((void*)d.m_s, (unsigned char*)m_szBuff + m_unLen, buff_size);
				m_unLen = nNewLen;
                //printf("charArrayDummy >> : value : %d\n", buff_size);
			}
		}
	}

    return *this;
}

CPluto& CPluto::operator>> (string& s)
{
    uint16_t n = 0;
    (*this) >> n;
    //printf("string value: %d idx : %d \n", n, this->GetDecodeErrIdx());
	if(this->GetDecodeErrIdx() == 0)
	{
		uint32_t nNewLen = m_unLen + n;
		if(n > m_unMaxLen)
		{
			m_nDecodeErrIdx = m_unLen;
		}
		else
		{
			s.assign(m_szBuff+m_unLen, n);
			m_unLen += n;
		}
	}

    return *this;
}

CPluto& EndPluto(CPluto& u)
{   
    
    //printf("friend EndPluto!\n");
    uint32_to_sz(u.GetLen(), u.GetRecvBuff());
    //uint32_to_sz(u.m_unLen, u.m_szBuff);
    char *str = u.GetRecvBuff();
    str[MSGLEN_HEAD] = '\0';
    str[MSGLEN_HEAD + 1] = '\0';
    
    u.SetMaxLen(u.GetLen());


	if(u.GetMsgId() < MAX_CLIENT_SERVER_MSGID)
	{
		//客户端包需要加密
		sg_mycryto.Reset();
		for(uint32_t i = MSGLEN_TEXT_POS; i<u.GetLen(); ++i)
		{
			str[i] = sg_mycryto.Encode(str[i]);
		}
	}

    return u;
}

CPluto& CPluto::endPluto()
{   
    //printf("CPluto::endPluto!\n");
	return EndPluto(*this);
}

CPluto& CPluto::operator>> (CEntityMailbox& m)
{
	CPluto& u = (*this);
	
	u >> m.m_nServerMailboxId;
	if(GetDecodeErrIdx() == 0)
	{
		u >> m.m_nEntityType;
		if(GetDecodeErrIdx() == 0)
		{
			u >> m.m_nEntityId;
		}
	}

    return u;
}

CPluto& CPluto::FillPluto(const VOBJECT& v)
{
    switch(v.vt)
    {
    case V_INT8:
        (*this) << v.vv.i8;
        break;
    case V_INT16:
        (*this) << v.vv.i16;
        break;
    case V_INT32:
        (*this) << v.vv.i32;
        break;
    //case V_INT64:
    //    (*this) << v.vv.i64;
    //    break;
    case V_UINT8:
        (*this) << v.vv.u8;
        break;
    case V_UINT16:
        (*this) << v.vv.u16;
        break;
    case V_UINT32:
        (*this) << v.vv.u32;
        break;
    //case V_UINT64:
    //    (*this) << v.vv.u64;
    //    break;
    case V_FLOAT32:
        (*this) << v.vv.f32;
        break;
    //case V_FLOAT64:
    //    (*this) << v.vv.f64;
    //    break;
    case V_STR:
        {
            (*this) << v.vv.s->c_str();
            break;
        }
    case V_BLOB:
        {
            (*this) << (*(charArrayDummy*)(v.vv.p));
            break;
        }
    
    //case V_ENTITYMB:
    //    {
    //        (*this) << v.vv.emb;
    //        break;
    //    }
    default:
        break;
    }

    return *this;
}

CPluto& CPluto::FillPlutoFromStr(VTYPE vt, const char* s, unsigned long ll)
{
	const static char szEmpty[] = "";
	const static char szEmptyTable[] = "{}";
	if(s == NULL)
	{
		if(vt == V_LUATABLE)
		{
			s = szEmptyTable;
		}
		else
		{
			s = szEmpty;
		}
	}

    CPluto& u = *this;
    switch(vt)
    {
    case V_UINT8:
        {
            u << (uint8_t)atoi(s);
            break;
        }
    case V_INT8:
        {
            u << (int8_t)atoi(s);
            break;
        }
    case V_UINT16:
        {
            u << (uint16_t)atoi(s);
            break;
        }
    case V_INT16:
        {
            u << (int16_t)atoi(s);
            break;
        }
    case V_UINT32:
        {
            u << (uint32_t)atoll(s);
            break;
        }
    case V_INT32:
        {
            u << (int32_t)atoll(s);
            break;
        }
    //case V_UINT64:
    //    {
    //        u << (uint64_t)atoll(s);
    //        break;
    //    }
    //case V_INT64:
    //    {
    //        u << (int64_t)atoll(s);
    //        break;
    //    }
    case V_FLOAT32:
        {
            u << (float32_t)atof(s);
            break;
        }
    //case V_FLOAT64:
    //    {
    //        u << (float64_t)atof(s);
    //        break;
    //    }
    case V_STR:
        {
            u << s;
            break;
        }
    case V_BLOB:
        {
            charArrayDummy d;
            d.m_l = (uint16_t)ll;
            d.m_s = (char*)s;
            u << d;
			d.m_l = 0;  //not delete m_s
            break;
        }
    case V_LUATABLE:
        {
			u << s;
            break;
        }
    default:
        {
            //nothing to do
        }
    }

    return u;
}
/*
CPluto& CPluto::FillPlutoFromLua(VTYPE vt, lua_State* L, int idx)
{
    CPluto& u = *this;
    switch(vt)
    {
    case V_UINT8:
        {
            //todo, 检查整数系列的类型是否正确,不能直接就转换类型
            uint8_t n = (uint8_t)luaL_checkint(L, idx);
            u << n;
            ////printf("arg: idx = %d ; value = %d \n", idx, n);
            break;
        }
    case V_UINT16:
        {
            uint16_t n = (uint16_t)luaL_checkint(L, idx);
            u << n;
            ////printf("arg: idx = %d ; value = %d \n", idx, n);
            break;
        }
    case V_UINT32:
        {
            uint32_t n = (uint32_t)luaL_checkint(L, idx);
            u << n;
            ////printf("arg: idx = %d ; value = %d \n", idx, n);
            break;
        }
    //case V_UINT64:
    //    {
    //        uint64_t n = (uint64_t)luaL_checkint(L, idx);
    //        u << n;
    //        ////printf("arg: idx = %d ; value = %d \n", idx, n);
    //        break;
    //    }
    case V_INT8:
        {
            //todo, 检查整数系列的类型是否正确,不能直接就转换类型
            int8_t n = (int8_t)luaL_checkint(L, idx);
            u << n;
            ////printf("arg: idx = %d ; value = %d \n", idx, n);
            break;
        }
    case V_INT16:
        {
            int16_t n = (int16_t)luaL_checkint(L, idx);
            u << n;
            ////printf("arg: idx = %d ; value = %d \n", idx, n);
            break;
        }
    case V_INT32:
        {
            int32_t n = (int32_t)luaL_checkint(L, idx);
            u << n;
            ////printf("arg: idx = %d ; value = %d \n", idx, n);
            break;
        }
    //case V_INT64:
    //    {
    //        int64_t n = (int64_t)luaL_checkint(L, idx);
    //        u << n;
    //        ////printf("arg: idx = %d ; value = %d \n", idx, n);
    //        break;
    //    }
    case V_FLOAT32:
        {
            float32_t n = (float32_t)luaL_checknumber(L, idx);
            u << n;
            ////printf("arg: idx = %d ; value = %f \n", idx, n);
            break;
        }
    //case V_FLOAT64:
    //    {
    //        float64_t n = (float64_t)luaL_checknumber(L, idx);
    //        u << n;
    //        ////printf("arg: idx = %d ; value = %f \n", idx, n);
    //        break;
    //    }
    case V_STR:
        {
            const char* s = luaL_checkstring(L, idx);
            u << s;
            ////printf("arg: idx = %d ; value = %s \n", idx, s);
            break;
        }
    case V_BLOB:
        {
            size_t l = 0;
            charArrayDummy d;
            d.m_s = (char*)luaL_checklstring(L, idx, &l );
            d.m_l = (uint16_t)l;
            u << d;
			d.m_l = 0;
            break;
        }
    
    default:
        break;
    }

    return u;
}
*/
void CPluto::FillVObject(VTYPE vt, VOBJECT& v)
{
    v.vt = vt;
    switch(vt)
    {
    case V_INT8:
        (*this) >> v.vv.i8;
        break;
    case V_INT16:
        (*this) >> v.vv.i16;
        break;
    case V_INT32:

        (*this) >> v.vv.i32;
        break;
    //case V_INT64:
    //    (*this) >> v.vv.i64;
    //    break;
    case V_UINT8:
        (*this) >> v.vv.u8;
        break;
    case V_UINT16:
        (*this) >> v.vv.u16;
        break;
    case V_UINT32:
        (*this) >> v.vv.u32;
        break;
    //case V_UINT64:
    //    (*this) >> v.vv.u64;
    //    break;
    case V_FLOAT32:
        (*this) >> v.vv.f32;
        break;
    //case V_FLOAT64:
    //    (*this) >> v.vv.f64;
    //    break;
    case V_STR:
        {  
           // printf("decode start for string!\n");
            string* s = new string;
            (*this) >> (*s);
           // printf("string is: %s\n", (*s).c_str());
            v.vv.s = s;
            break;
        }
    case V_BLOB:
        {
            charArrayDummy* d = new charArrayDummy;
            (*this) >> (*d);
            v.vv.p = d;
            break;
        }
     
    case V_ENTITYMB:
        {
            (*this) >> v.vv.emb;
            break;
        }
    case V_ENTITY:
        {
            v.vv.p = (void*) new SEntityPropFromPluto;
            UnpickleEntity(v);
            break;
        }
    default:
        break;
    }
}

bool CPluto::UnpickleEntity(VOBJECT& v)
{
    CPluto& u = *this;
    SEntityPropFromPluto& ep = *((SEntityPropFromPluto*)v.vv.p);

    u >> ep.etype;
	if(GetDecodeErrIdx() > 0)
	{
		return false;
	}

    const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(ep.etype);
    if(pDef)
    {
        while(!u.IsEnd())
        {
            uint16_t nPropId;
            u >> nPropId;
			if(GetDecodeErrIdx() > 0)
			{
				return false;
			}

            const string& strPropName = pDef->m_propertiesMap.GetStrByInt(nPropId);
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.find(strPropName);
            if(iter == pDef->m_properties.end())
            {
                return false;
            }
            VOBJECT* v = new VOBJECT;
            u.FillVObject(iter->second->m_nType, *v);
			if(GetDecodeErrIdx() > 0)
			{
				delete v;
				return false;
			}
            ep.data.insert(make_pair(strPropName, v));
        }
    }

    return pDef != NULL;
}

CPluto& CPluto::FillBuff(const char* s, uint32_t n)
{
	Resize(sizeof(uint16_t)+n);

	memcpy(m_szBuff + m_unLen, s, n);
	m_unLen += n;
	return *this;
}

