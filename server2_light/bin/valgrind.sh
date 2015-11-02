#!/bin/sh
#running the process cwmd and then starting loginapp
#timerd dbmgr base cell 
echo "[running process cwmd......]"
#./sync_db ./cfg.ini
valgrind --tool=memcheck --undef-value-errors=yes --leak-check=full --error-limit=no --show-reachable=yes --log-file=cwmd_memcheck_%p.log ./cwmd ./cfg.ini & 
valgrind --tool=memcheck --undef-value-errors=yes --leak-check=full --error-limit=no --show-reachable=yes --log-file=loginapp_memcheck_%p.log ./loginapp ./cfg.ini 1 ./log/loginapp_1 &
valgrind --tool=memcheck --undef-value-errors=yes --leak-check=full --error-limit=no --show-reachable=yes --log-file=dbmgr_memcheck_%p.log ./dbmgr ./cfg.ini 3 ./log/dbmgr_3 &
valgrind --tool=memcheck --undef-value-errors=yes --leak-check=full --error-limit=no --show-reachable=yes --log-file=timerd_memcheck_%p.log ./timerd ./cfg.ini 4 ./log/timerd_4 &
valgrind --tool=memcheck --undef-value-errors=yes --leak-check=full --error-limit=no --show-reachable=yes --log-file=logapp_memcheck_%p.log ./logapp ./cfg.ini 5 ./log/logapp_5 &
valgrind --tool=memcheck --undef-value-errors=yes --leak-check=full --error-limit=no --show-reachable=yes --log-file=baseapp6_memcheck_%p.log ./baseapp ./cfg.ini 6 ./log/baseapp_6 &
valgrind --tool=memcheck --undef-value-errors=yes --leak-check=full --error-limit=no --show-reachable=yes --log-file=cellapp7_memcheck_%p.log ./cellapp ./cfg.ini 7 ./log/cellapp_7 & 
valgrind --tool=memcheck --undef-value-errors=yes --leak-check=full --error-limit=no --show-reachable=yes --log-file=cellapp8_memcheck_%p.log ./cellapp ./cfg.ini 8 ./log/cellapp_8 &
valgrind --tool=memcheck --undef-value-errors=yes --leak-check=full --error-limit=no --show-reachable=yes --log-file=baseapp9_memcheck_%p.log ./baseapp ./cfg.ini 9 ./log/baseapp_9 &  	
