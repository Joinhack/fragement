#!/bin/sh
HOSTNAME="127.0.0.1"                   #数据库Server信息
DBNAME="card"                  #要创建的数据库的库名称
PORT="3306"
USERNAME="root"
PASSWORD="7338701"

mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD}   <<QUERY_SQL 
CREATE DATABASE ${DBNAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
use ${DBNAME};
source ./card.sql;
QUIT 
QUERY_SQL
