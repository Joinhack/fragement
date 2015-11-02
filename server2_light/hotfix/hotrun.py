# -*- coding:utf-8 -*-

import sys;
sys.path.append("./lib/")

import pluto
import client
import time
import cfg


lstClient = []

def pack_lua(msg_id, code):
    m = pluto.Pluto()
    m.encode(msg_id)
    m.put_str(code)
    return m.endPluto()
	
def send_cmd(msg_id, s, api_txt, cmd_txt):
	cli = client.Client()
	cli.connect(s[0], s[1])
	cli.send(pack_lua(msg_id, api_txt))
	cli.send(pack_lua(msg_id, cmd_txt))
	lstClient.append(cli)

def show_help():
	print('需要输入以下参数：\n')
	print('参数1：操作的服务器，1为Base，2为Cell\n')
	print('参数2：加载的Lua脚本文件名\n')

def main():
	args = len(sys.argv)
	if args < 3:
		show_help()
		return
	mode	 = sys.argv[1]
	fileName = sys.argv[2]
	if mode != '1' and mode != '2':
		show_help()
		return

	api_file	= open('mogo_api.lua')
	cmd_file	= open(fileName)
	api_txt		= api_file.read()
	cmd_txt		= cmd_file.read()

	if mode == '1':
		for s in cfg.BaseServers:
			send_cmd(cfg.MSGID_BASEAPP_LUA_DEBUG, s, api_txt, cmd_txt)
	if mode == '2':
		for s in cfg.CellServers:
			send_cmd(cfg.MSGID_CELLAPP_LUA_DEBUG, s, api_txt, cmd_txt)

    #延迟1秒退出,不然服务端处理会认为该pluto包非法
	time.sleep(1)
	
	for s in lstClient:
		s.close()


if __name__ == "__main__":
    main()
    
