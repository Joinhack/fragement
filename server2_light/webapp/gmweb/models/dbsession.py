# -*- coding: utf-8 -*-
from gmweb import db
from flask.sessions import SessionInterface, SessionMixin
import uuid, pickle

class Session(db.Model):
	id = db.Column(db.String(128), primary_key=True)
	data = db.Column(db.Binary(2048), nullable=False)
	expired = db.Column(db.DateTime)
	def __init__(self, id=None):
		self.id = id;

class DBSession(dict, SessionMixin):
	def __init__(self, sid=None):
		self.sid = sid
		self.modified = False
	def __setitem__(self, k, v):
		self.modified = True;
		super(DBSession, self).__setitem__(k, v)
	def __delitem__(self, k):
		self.modified = True;
		super(DBSession, self).__delitem__(k)


class DBSessionInterface(SessionInterface):
	def open_session(self, app, request):
		sid = request.cookies.get(app.session_cookie_name)
		if request.path == '/init_all':
			return None
		if not sid:
			return DBSession(sid=self.new_sid())
		s = Session.query.filter_by(id=sid).first()
		if s == None:
			return DBSession(sid=self.new_sid())
		session = pickle.loads(s.data)
		return session

	def save_session(self, app, session, response):
		domain = self.get_cookie_domain(app)
		if not session:
			if session.modified:
				s = Session.query.filter_by(id=session.sid).first()
				if s:
					db.session.delete(s)
					db.session.commit();
				return
		expires = self.get_expiration_time(app, session)
		val = self.persist_session(session, expires)
		response.set_cookie(app.session_cookie_name, val,
					expires=expires, httponly=True,
					domain=domain)
	def persist_session(self, session, expires):
		if not session.modified:
			return session.sid
		s = Session.query.filter_by(id=session.sid).first()
		if not s:
			s = Session(id = session.sid)
		s.expires = expires
		s.data = pickle.dumps(session)
		db.session.add(s)
		db.session.commit();
		return session.sid

	def new_sid(self):
		return str(uuid.uuid1())