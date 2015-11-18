# -*- coding: utf-8 -*-

from gmweb import app
from flask import jsonify,session
from gmweb.models import *
from flask import request, render_template, session, redirect, url_for, send_from_directory
from utils import *
import logging, sys, types


@app.route('/')
@login_required()
def index():
	loginid = session.get(LOGINID)
	user = User.query.filter_by(loginid=loginid).first()
	return render_template('index.html', user=user)

@app.route('/about')
def about():
	return render_template('about.html')


@app.route("/login/do", methods=["post"])
def do_login():
	loginid = request.form["loginid"]
	password = request.form["password"]
	user  = User.query.filter_by(loginid=loginid).first()
	if user == None or \
		(user.loginid != loginid or user.password != password):
		return jsonify(code=-1, msg='用户或密码错误!')
	session[LOGINID] = loginid
	return jsonify({'code':0, 'redirect':url_for('index')})

@app.route("/logout")
def logout():
	session.clear()
	return redirect(url_for("index"))

@app.route('/login')
def login():
	return render_template('login.html')

@app.route('/init_all')
def init_all():
	drop_tables()
	create_tables()
	add_defaults()
	return jsonify({'code':0});