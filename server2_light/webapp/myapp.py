# -*- coding: utf-8 -*-
import logging, sys
from gmweb import init,MysqlConf

if __name__ == "__main__":
	MysqlConf.update({"MYSQL_USER":"T", "MYSQL_PASS":"123456", "MYSQL_HOST":"54.248.147.73", "MYSQL_PORT":"3306", "MYSQL_DB":""})
	init("local")
	from gmweb import app
	app.run()
	