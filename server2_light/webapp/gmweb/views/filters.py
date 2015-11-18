# -*- coding: utf-8 -*-
import jinja2, types, json

safe = jinja2.filters.FILTERS["safe"]

def to_selectjson(datas, format):
	rs = []
	content = None
	value = None
	selected = None
	if type(format) == types.TupleType:
		l  = len(format)
		if l < 2:
			raise Exception("error format")
		content = format[0]
		value = format[1]
		if l > 2:
			selected = format[2]

	if type(format) == types.DictType:
		content = format.get("content")
		value = format.get("value")
		selected = format.get("selected")

	def _cover(data):
		rs = {}
		rs["content"] = data.__getattribute__(content)
		rs["value"] = data.__getattribute__(value)
		if selected == rs["value"]:
			rs["selected"] = True
		return rs
	for data in datas:
		rs.append(_cover(data))
	return safe(json.dumps(rs))

jinja2.filters.FILTERS['to_selectjson'] = to_selectjson