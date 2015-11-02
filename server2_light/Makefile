CXX=g++

BIN_PATH = /usr/local/bin

INCLUDE_PATH = /usr/local/include
MYSQL_INCLUDE_PATH = /opt/local/mysql/include
MYSQL_PLUS_PLUS_INCLUDE_PATH = /usr/include/mysql++
TINYXML_INCLUDE_PATH = /usr/include

SSL_LIB_PATH = /usr/lib/x86_64-linux-gnu/
TINYXML_LIB_PATH = /usr/lib
LIB_PATH = /usr/lib
MYSQL_LIB_PATH = /opt/local/mysql/lib
LOCAL_LIB_PATH = /usr/local/lib

CFLAGS=-W -I$(INCLUDE_PATH) -I$(MYSQL_PLUS_PLUS_INCLUDE_PATH) -I$(MYSQL_INCLUDE_PATH) -I$(BIN_PATH) -I$(TINYXML_INCLUDE_PATH) \
		 -Icommon -Ibase -Icell -Itest -Icwmd -Ilogin -Idbmgr -Itimerd -c -g -std=c++0x -DSYNC_DB_TEST -D__LUA_5_2_1 -D_USE_REDIS -D__AOI_PRUNING \
		 -D__SPEED_CHECK  \
		 -D__PLUTO_ORDER \
		 -D__RELOGIN \
		 #-D__PLAT_PLUG_IN \
		 #-D__OPTIMIZE_PROP_SYN
		 #-D__TEST
		 #-D__USE_MSGPACK \
		 #-D_GC_DEBUG
#-Icommon -Ibase -Icell -Itest -Icwmd -Ilogin -Idbmgr -Itimerd -c -g -DSYNC_DB_TEST -D_MYPROF -D_USE_REDIS -D_DEBUG_PLUTO
#-Icommon -Ibase -Icell -Itest -Icwmd -Ilogin -Idbmgr -Itimerd -c -g -DSYNC_DB_TEST -D_USE_RECV_BUFF
#		 -Icommon -Ibase -Icell -Itest -Icwmd -Ilogin -Idbmgr -Itimerd -c -g -DSYNC_DB_TEST -D_GC_DEBUG
LIBS = $(TINYXML_LIB_PATH)/libtinyxml.a $(SSL_LIB_PATH)/libssl.a $(SSL_LIB_PATH)/libcrypto.a 
 
LFLAGS=-L$(LIB_PATH) -L$(MYSQL_LIB_PATH) -L$(LOCAL_LIB_PATH) -L$(TINYXML_LIB_PATH) -L/usr/lib/x86_64-linux-gnu\
		-llua -ltinyxml -ldl -lm  -g -lpthread -lmysqlclient -luuid -lhiredis -lcurl -lboost_regex -Wl,-E 

		#-llua -ltinyxml -ldl -lm  -g -pg -lpthread -lmysqlclient -luuid -lhiredis -lcurl -Wl,-E
LUALIB=$(LOCAL_LIB_PATH)/liblua.a 
       #$(LOCAL_LIB_PATH)/libmsgpack.a

COMMON_O = common/json_helper.o common/type_mogo.o common/entity_mgr.o common/mailbox.o common/world.o \
	common/defparser.o common/epoll_server.o common/net_util.o common/xmsg.o \
	common/entity.o common/lua_mogo.o common/pluto.o common/util.o common/xsem.o \
	common/rpc_mogo.o common/timer.o common/balance.o common/path_founder.o \
	common/logger.o common/cfg_reader.o common/exception.o common/bitcryto.o common/timer_action.o\
	common/md5.o common/memory_pool.o common/mutex.o common/lua_bitset.o common/debug.o common/cjson.o \
	common/stopword.o common/base64.o
BASE_O = base/entity_base.o  base/lua_base.o  base/world_base.o
CELL_O = cell/entity_cell.o  cell/aoi.o  cell/lua_cell.o  cell/space.o  cell/world_cell.o
TOOLS_O = tools/stop.o
OTHERS_O=$(COMMON_O) $(BASE_O) $(CELL_O)

TEST_SERVER_O = test/main.o dbmgr/dboper.o dbmgr/world_dbmgr.o  dbmgr/db_task.o dbmgr/myredis.o
TEST_CLIENT_O = test/test_client.o dbmgr/myredis.o
SHUT_DOWN_O   = test/shut_down.o
#POLICY_SERVER_O = test/policy.o
BASEAPP_O = base/main.o base/baseapp.o
CELLAPP_O = cell/main.o cell/cellapp.o
CWMD_O = cwmd/main.o cwmd/cwmd.o cwmd/world_cwmd.o
LOGIN_O = loginapp/main.o loginapp/loginapp.o loginapp/world_login.o
DBMGR_O = dbmgr/main.o dbmgr/dboper.o dbmgr/dbmgr.o dbmgr/world_dbmgr.o dbmgr/db_task.o dbmgr/myredis.o
TIMERD_O = timerd/main.o timerd/timerd.o timerd/world_timerd.o
CROSSCLIENT_O = crossclient/crossclient.o crossclient/world_crossclient.o crossclient/main.o
CROSSSERVER_O = crossserver/crossserver.o crossserver/world_crossserver.o crossserver/main.o
#TOOL_STOP_O = tools/stop.o
FCGI_O = fcgi/charge_appstore.o fcgi/ifbase.o  fcgi/if4399.o fcgi/api_data_center.o fcgi/api_plat.o fcgi/iffactory.o fcgi/cgicfg.o  \
 fcgi/login_base.o fcgi/login91.o fcgi/login4399.o fcgi/login_pptv.o fcgi/login_dangle.o fcgi/login360.o fcgi/login_duokoo.o fcgi/login_uc.o \
 fcgi/login_xiaomi.o fcgi/login_pps.o fcgi/login_anzhi.o

FCGI_MAIN_O =  fcgi/main_data_center.o fcgi/main_plat_api.o fcgi/main_gift.o fcgi/main_card.o fcgi/main_login.o fcgi/main_charge.o fcgi/main_360_verify.o
BOT_O = test/world_client.o

LOG_DIR = $(wildcard logapp/*.cpp)
#LOG_O = $(patsubst %.cpp,%.o,$(LOG_DIR))
LOG_O = logapp/main.o logapp/dboper.o logapp/other.o logapp/world_other.o logapp/db_task.o logapp/http.o logapp/threadpool.o logapp/api.o

ALL_O = $(OTHERS_O) $(TEST_SERVER_O) $(TEST_CLIENT_O) $(BASEAPP_O) $(CWMD_O) \
			$(DBMGR_O) $(TIMERD_O) $(LOGIN_O) $(CELLAPP_O) $(LOG_O) $(SHUT_DOWN_O) $(BOT_O) \
			$(CROSSCLIENT_O) $(CROSSSERVER_O) \
#			$(TOOL_STOP_O) $(POLICY_SERVER_O) $(LOG_O)

BIN_HOME = ./bin/
FCGI_BIN_HOME = ./fcgi_bin/
APP=$(BIN_HOME)/sync_db $(BIN_HOME)/client $(BIN_HOME)/baseapp $(BIN_HOME)/cwmd \
		$(BIN_HOME)/dbmgr $(BIN_HOME)/timerd $(BIN_HOME)/loginapp $(BIN_HOME)/cellapp $(BIN_HOME)/logapp $(BIN_HOME)/shutdown \
		$(BIN_HOME)/crossclient $(BIN_HOME)/crossserver \
#		$(BIN_HOME)/login.cgi

%.o:%.cpp
	$(CXX) $(CFLAGS) $< -o $@


all:$(ALL_O)
	$(CXX)  $(OTHERS_O) $(TEST_SERVER_O) -o $(BIN_HOME)/sync_db $(LUALIB) $(LFLAGS) $(LIBS)
	$(CXX)  $(OTHERS_O) $(TEST_CLIENT_O) -o $(BIN_HOME)/client  $(LUALIB) $(LFLAGS) $(LIBS)
	$(CXX)  $(OTHERS_O) $(SHUT_DOWN_O) -o $(BIN_HOME)/shutdown  $(LUALIB) $(LFLAGS) $(LIBS)
#	$(CXX) $(LFLAGS) $(OTHERS_O) $(POLICY_SERVER_O) -o $(BIN_HOME)/policy  $(LUALIB) $(LIBS)
	$(CXX)  $(OTHERS_O) $(BASEAPP_O)     -o $(BIN_HOME)/baseapp $(LUALIB) $(LFLAGS) $(LIBS)
	$(CXX)  $(OTHERS_O) $(CELLAPP_O)     -o $(BIN_HOME)/cellapp $(LUALIB) $(LFLAGS) $(LIBS)
	$(CXX)  $(OTHERS_O) $(CWMD_O)        -o $(BIN_HOME)/cwmd    $(LUALIB) $(LFLAGS) $(LIBS)
	$(CXX)  $(OTHERS_O) $(DBMGR_O)       -o $(BIN_HOME)/dbmgr   $(LUALIB) $(LFLAGS) $(LIBS)
	$(CXX)  $(OTHERS_O) $(TIMERD_O)      -o $(BIN_HOME)/timerd  $(LUALIB) $(LFLAGS) $(LIBS)
	$(CXX)  $(OTHERS_O) $(LOGIN_O)       -o $(BIN_HOME)/loginapp $(LUALIB) $(LFLAGS) $(LIBS)
	$(CXX)  $(OTHERS_O) $(LOG_O)       -o $(BIN_HOME)/logapp $(LUALIB) $(LFLAGS) $(LIBS)
#	$(CXX) $(LFLAGS) $(OTHERS_O) $(TOOL_STOP_O)   -o $(BIN_HOME)/tool_stop $(LUALIB) $(LIBS)
	$(CXX)  $(OTHERS_O) $(BOT_O)   -o $(BIN_HOME)/bottest $(LUALIB) $(LFLAGS) $(LIBS)
	$(CXX)  $(OTHERS_O) $(CROSSCLIENT_O) -o $(BIN_HOME)/crossclient $(LUALIB) $(LFLAGS) $(LIBS)
	$(CXX) $(OTHERS_O) $(CROSSSERVER_O) -o $(BIN_HOME)/crossserver $(LUALIB) $(LFLAGS) $(LIBS)

clean:
	-rm -f $(ALL_O) $(APP)

cgi:$(ALL_O) $(FCGI_O) $(FCGI_MAIN_O)  logapp/http.o
	#$(CXX) $(LFLAGS)  -L/usr/local/lib -lfcgi $(OTHERS_O) logapp/http.o $(FCGI_O) fcgi/main_data_center.o -o $(FCGI_BIN_HOME)/data_center $(LUALIB)
	#cp $(FCGI_BIN_HOME)/data_center /data/server/cgi-bin/bin/.
	$(CXX)  $(OTHERS_O) logapp/http.o $(FCGI_O) fcgi/main_plat_api.o -o $(FCGI_BIN_HOME)/plat_api  $(LFLAGS)  -lfcgi   $(LUALIB)  $(LIBS)
	#cp $(FCGI_BIN_HOME)/plat_api /data/server/cgi-bin/bin/.
	$(CXX) $(OTHERS_O) logapp/http.o $(FCGI_O) fcgi/main_gift.o -o $(FCGI_BIN_HOME)/gift_sender $(LFLAGS)   -L/usr/local/lib -lfcgi  $(LUALIB) $(LIBS)
	#cp $(FCGI_BIN_HOME)/gift_sender /data/server/cgi-bin/bin/.
	$(CXX) $(OTHERS_O) logapp/http.o $(FCGI_O)  logapp/dboper.o fcgi/main_card.o -o $(FCGI_BIN_HOME)/card $(LFLAGS)  -L/usr/local/lib -lfcgi  $(LUALIB) $(LIBS)
	#cp $(FCGI_BIN_HOME)/card /data/server/cgi-bin/bin/.
	$(CXX) $(OTHERS_O) logapp/http.o $(FCGI_O) fcgi/main_charge.o -o $(FCGI_BIN_HOME)/charge $(LFLAGS)  -L/usr/local/lib -lfcgi  $(LUALIB) $(LIBS)
	#cp $(FCGI_BIN_HOME)/charge /data/server/cgi-bin/bin/.
	$(CXX)  $(OTHERS_O) logapp/http.o $(FCGI_O) fcgi/main_login.o -o $(FCGI_BIN_HOME)/login  $(LFLAGS)  -L/usr/local/lib -lfcgi $(LUALIB) $(LIBS)
	#cp $(FCGI_BIN_HOME)/login /data/server/cgi-bin/bin/.
	$(CXX) $(OTHERS_O) logapp/http.o $(FCGI_O)  fcgi/main_360_verify.o -o $(FCGI_BIN_HOME)/verify360 $(LFLAGS)  -L/usr/local/lib -lfcgi  $(LUALIB) $(LIBS)
	#cp $(FCGI_BIN_HOME)/verify360 /data/server/cgi-bin/bin/.