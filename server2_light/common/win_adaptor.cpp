#ifdef _WIN32

#include "win_adaptor.h"
//test code
//#include "world_cwmd.h"
//#include "world_cell.h"
#include "world_base.h"
//#include "world_dbmgr.h"
#include "lua_cell.h"
#include "lua_base.h"
//test code
#include "world_select.h"


CMailBox g_winTestMailbox;

int CWinTestWorld::FromRpcCall(CPluto& u)
{
    using namespace mogo;

    //test code
    pluto_msgid_t msgid = u.GetMsgId();
    switch(msgid)
    {
        case MSGID_BASEAPPMGR_REGISTERGLOBALLY:
        {
            //static CEpollServer s;
            //static CWorldMgrD w;
            //w.SetServer(&s);
            ////s.SetWorld(*w);
            //w.FromRpcCall(u);
            break;
        }
        case MSGID_DBMGR_INSERT_ENTITY:
        case MSGID_DBMGR_SELECT_ENTITY:
        case MSGID_DBMGR_UPDATE_ENTITY:
        case MSGID_DBMGR_RAW_MODIFY_NORESP:
        {
            //CWorldDbmgr w;
            //w.init("F:\\CW\\cw\\cw\\etc\\cw.etc.txt");
            //CDbOper db(0);
            //string strErr;
            //db.Connect(w.GetDefParser().GetDbCfg(), w.GetDefParser().GetRedisCfg(), strErr);
            //w.FromRpcCall(u, db);
            break;
        }
        default:
        {
            //baseapp
            //static CWorldBase w;
            CWorldBase& w = (CWorldBase&)*g_pTheWorld;
            w.FromRpcCall(u);
        }
    }

    return 0;
}

#endif

