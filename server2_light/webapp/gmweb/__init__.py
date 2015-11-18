# -*- coding: utf-8 -*-
from flask import Flask
import logging, sys
try:
	from flask.ext.sqlalchemy import SQLAlchemy
except:
	from flask_sqlalchemy import SQLAlchemy

app = None
db = None

const = {}

MysqlConf = {}

def get_mysql_uri():
	return "mysql://%s:%s@%s:%s/%s?charset=utf8"%(MysqlConf["MYSQL_USER"], MysqlConf["MYSQL_PASS"], MysqlConf["MYSQL_HOST"], MysqlConf["MYSQL_PORT"], MysqlConf["MYSQL_DB"])

def _init_sae_db():
	import sae.const
	MysqlConf["MYSQL_USER"] = sae.const.MYSQL_USER
	MysqlConf["MYSQL_PASS"] = sae.const.MYSQL_PASS
	MysqlConf["MYSQL_HOST"] = sae.const.MYSQL_HOST
	MysqlConf["MYSQL_PORT"] = sae.const.MYSQL_PORT
	MysqlConf["MYSQL_DB"] = sae.const.MYSQL_DB
	app.config.setdefault("SQLALCHEMY_DATABASE_URI", get_mysql_uri())

def _init_bae_db():
	from bae.core import const
	MysqlConf["MYSQL_USER"] = const.MYSQL_USER
	MysqlConf["MYSQL_PASS"] = const.MYSQL_PASS
	MysqlConf["MYSQL_HOST"] = const.MYSQL_HOST
	MysqlConf["MYSQL_PORT"] = const.MYSQL_PORT
	MysqlConf["MYSQL_DB"] = "iVRwDyxGQdEyxjJTHIue"
	app.config.setdefault("SQLALCHEMY_DATABASE_URI", get_mysql_uri())

def _init_mysql_db():
	app.config.setdefault("SQLALCHEMY_DATABASE_URI", get_mysql_uri())

def _init_local_db():
	app.config.setdefault("SQLALCHEMY_DATABASE_URI", "sqlite://////Volumes/joinhack/Downloads/h.db")

inited = False

class nullpool_SQLAlchemy(SQLAlchemy):
	def apply_driver_hacks(self, app, info, options):
		super(nullpool_SQLAlchemy, self).apply_driver_hacks(app, info, options)
		from sqlalchemy.pool import NullPool
		options['poolclass'] = NullPool
		if options.has_key("pool_size"):
			del options['pool_size']

def init(type):
	global app
	global db
	global inited
	if not inited:
		app = Flask(__name__)
		app.debug = True
		app.secret_key = 'xkjhjw153k1x1jhl0h5xzyzi22kjh0xll1k52l5i'
		if type == 'sae':
			_init_sae_db()
		elif type == 'bae':
			_init_bae_db()
		elif type == 'mysql':
			_init_mysql_db()	
		else:
			_init_local_db()
		app.config.setdefault("SQLALCHEMY_POOL_RECYCLE", 15)
		db = SQLAlchemy(app)
		db.engine.echo = True
		import views
		import models
		#app.session_interface = models.DBSessionInterface()
	else:
		inited = True