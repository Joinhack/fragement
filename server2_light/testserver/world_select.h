#ifndef __WORLD_SELECT_HEAD__
#define __WORLD_SELECT_HEAD__

//#include "../cell/lua_cell.h"
//#include "../cell/world_cell.h"
//#include "../base/lua_base.h"
//#include "../base/world_base.h"
#include "world.h"

extern world* g_pTheWorld;

inline world* GetWorld()
{
    return g_pTheWorld;
}
/*
inline CWorldBase& GetWorldbase()
{
    return (CWorldBase&)*g_pTheWorld;
}

inline CWorldCell& GetWorldcell()
{
	return (CWorldCell&)*g_pTheWorld;
}
*/

#endif


