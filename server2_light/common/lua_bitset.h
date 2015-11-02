/* 
 * File:   lua_bitset.h
 * Author: Arcol
 *
 * Created on 2013年7月16日, 下午2:00
 */

#ifndef LUA_BITSET_H
#define	LUA_BITSET_H


extern "C" {
#include "lua.h"     
#include "lauxlib.h"     
#include "lualib.h"     
};  


class lua_bitset
{
public:
    lua_bitset();
    virtual ~lua_bitset();
    
    void    Init(lua_State* L);
    
    
private:
    lua_bitset(const lua_bitset& rOther);
    
    
public:
    static int Set(lua_State* L);
    static int Reset(lua_State* L);
    static int Test(lua_State* L);
};

extern lua_bitset g_lua_bitset;


#endif	/* LUA_BITSET_H */

