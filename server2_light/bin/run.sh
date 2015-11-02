#!/bin/sh
#running the process cwmd and then starting loginapp
#timerd dbmgr base cell 
echo "[running process cwmd......]"
who=`whoami`
echo $who
if [ "$who" = "root" ]
then
    echo "can't start server via root"
#   exit
fi
path=`pwd`
${path}/sync_db ./cfg.ini
${path}/cwmd ./cfg.ini 2 ./log/cwmdlog_2 &
${path}/loginapp ./cfg.ini 1 ./log/loginlog_1 &
${path}/dbmgr ./cfg.ini 3 ./log/dblog_3 &
${path}/timerd ./cfg.ini 4 ./log/timerd_4 &
${path}/logapp ./cfg.ini 5 ./log/logapplog_5 &
${path}/baseapp ./cfg.ini 6 ./log/baselog_6 &
${path}/cellapp ./cfg.ini 7 ./log/celllog_7 &



