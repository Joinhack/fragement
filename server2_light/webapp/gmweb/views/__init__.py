# -*- coding: utf-8 -*-
import sys
from flask import send_from_directory
from gmweb import app
import user, filters


@app.route('/media/<path:filename>')
def send_pic(filename):
	return send_from_directory(sys.path[0] + '/media/', filename)
