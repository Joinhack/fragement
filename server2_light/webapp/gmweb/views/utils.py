# -*- coding: utf-8 -*-
from flask import jsonify,session,redirect,url_for
from functools import wraps

LOGINID="@#$!!0@"

def login_required(json=False):
	def outer(fn):
		@wraps(fn)
		def login_check(*args, **kwargs):
			loginId = session.get(LOGINID)
			if not loginId:
				if json:
					return jsonify({'code':-1, 'msg':'please login'})
				return redirect(url_for("login"))
			return fn(*args, **kwargs)
		return login_check
	return outer

def attr_set(n, **kwargs):
	for k in kwargs:
		if hasattr(n, k) and  kwargs[k]:
			setattr(n, k, kwargs[k])

def toselect(datas):
	rs = []
	def _cover(data):
		rs = {}
		rs["content"] = data.name
		rs["value"] = data.id
		return rs
	for data in datas:
		rs.append(_cover(data))
	return rs