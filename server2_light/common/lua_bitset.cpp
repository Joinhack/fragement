/* 
 * File:   lua_bitset.cpp
 * Author: Arcol
 * 
 * Created on 2013年7月16日, 下午2:00
 */

#include "lua_bitset.h"
#include <stdint.h>


lua_bitset g_lua_bitset;


/////////////////////////////////////////////////////////////////////

lua_bitset::lua_bitset()
{
}

lua_bitset::~lua_bitset()
{
}

void lua_bitset::Init(lua_State* L)
{
	static const luaL_Reg bitLib[] =
	{
		{"Set",		lua_bitset::Set},
        {"Reset",	lua_bitset::Reset},
        {"Test",	lua_bitset::Test},
		{NULL,		NULL},
	};
	
	luaL_newlib(L, bitLib);
	lua_setglobal(L, "Bit");
}

int lua_bitset::Set(lua_State* L)
{
	uint64_t data	= (uint64_t)luaL_checknumber(L, 1);
	int nBit		= luaL_checknumber(L, 2);
	if (nBit >= 0 && nBit < (int)sizeof(data) * 8)
	{
		data |= (1ull << nBit);
	}
	lua_pushnumber(L, data);

	return 1;
}

int lua_bitset::Reset(lua_State* L)
{
	uint64_t data	= (uint64_t)luaL_checknumber(L, 1);
	int nBit		= luaL_checknumber(L, 2);
	if (nBit >= 0 && nBit < (int)sizeof(data) * 8)
	{
		data &= ~(1ull << nBit);
	}
	lua_pushnumber(L, data);

	return 1;
}

int lua_bitset::Test(lua_State* L)
{
	int nRet		= 0;
	uint64_t data	= (uint64_t)luaL_checknumber(L, 1);
	int nBit		= luaL_checknumber(L, 2);
	if (nBit >= 0 && nBit < (int)sizeof(data) * 8)
	{
		data &= (1ull << nBit);
		if (data != 0) nRet = 1;
	}
	lua_pushboolean(L, nRet);

	return 1;
}










