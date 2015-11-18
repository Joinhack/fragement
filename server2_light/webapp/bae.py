# -*- coding: utf-8 -*-
from gmweb import init
init("bae")
from agent import app

from bae.core.wsgi import WSGIApplication


application = WSGIApplication(app)
