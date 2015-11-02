#!/bin/sh
who=`whoami`
echo $who
if [ "$who" = "root" ]
then
    echo "can't start server via root"
    exit
fi
echo "[shutdown sever processes...]"
path=`pwd`
echo $path
ps -ewf | grep $path | awk '{print $2}'| xargs kill -9
#ps -ewf | grep "loginapp" | grep $who | awk '{print $2}'| xargs kill -9
#echo "[shutdown loginapp..........]"
#ps -ewf | grep "dbmgr" | grep $who | awk '{print $2}'| xargs kill -9
#echo "[shutdown dbmgr.............]"
#ps -ewf | grep "cwmd" | grep $who | awk '{print $2}'| xargs kill -9
#echo "[shutdown cwmd..............]"
#ps -ewf | grep "timerd" | grep $who | awk '{print $2}'| xargs kill -9
#echo "[shutdown timerd............]"
#ps -ewf | grep "logapp" | grep $who | awk '{print $2}'| xargs kill -9
#echo "[shutdown logapp...........]"
#ps -ewf | grep "baseapp" | grep $who | awk '{print $2}'| xargs kill -9
#echo "[shutdown baseapp...........]"
#ps -ewf | grep "cellapp" | grep $who | awk '{print $2}'| xargs kill -9
#echo "[shutdown cellapp...........]"


