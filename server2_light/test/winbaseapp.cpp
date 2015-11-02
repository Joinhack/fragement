#ifdef _WIN32

#include <iostream>
#include <algorithm>
#include <iomanip>
#include <lua.hpp>


#include "lua_mogo.h"
#include "space.h"
#include "world_cell.h"
#include "lua_cell.h"
#include "world_base.h"
#include "lua_base.h"
#include "pluto.h"
#include "world_select.h"


world* g_pTheWorld = new CWorldBase;

int main(int argc, char* argv[])
{
	using namespace std;
	using namespace mogo;

	char* fn = "E:\\proj\\lua\\cfg.ini.example";
	if(argc > 1)
	{
		fn = argv[1];
	}

	int nRet = GetWorld()->init(fn);
	cout << nRet << endl;
	
	return 0;
}

#endif


