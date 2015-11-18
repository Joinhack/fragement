# -*- coding: utf-8 -*-
from users import *
from gmweb import db

def create_tables():
	db.create_all()

def drop_tables():
	None
	# db.drop_all()

def add_defaults():
	user = User();
	user.loginid = 'admin'
	user.password = 'admin'
	
	db.session.add(user)
	db.session.commit()
