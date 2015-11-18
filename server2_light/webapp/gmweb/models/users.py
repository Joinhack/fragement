# -*- coding: utf-8 -*-
from gmweb import db

class User(db.Model):
	id = db.Column(db.Integer, primary_key=True)
	loginid = db.Column(db.String(128), unique=True)
	password = db.Column(db.String(128), nullable=False)
	def __repr__(self):
		return "loginid:%s, password:%s"(self.loginid, self.password)

