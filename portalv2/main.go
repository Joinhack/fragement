package main

import (
	"net"
	"runtime"
)

func main() {

	go func() {
		var addr net.Addr
		var udp *net.UDPConn
		var err error
		if addr, err = net.ResolveUDPAddr("udp4", ":1234"); err != nil {
			panic(err)
		}
		if udp, err = net.ListenUDP("udp", addr.(*net.UDPAddr)); err != nil {
			panic(err)
		}
		var buf = make([]byte, 65535)
		n, addr, e := udp.ReadFrom(buf)
		if e != nil {
			panic(e)
		}
		udp.WriteTo(buf[:n], addr)
	}()
	runtime.Gosched()
	svr := NewPortalSvr()
	svr.basAddr = "127.0.0.1:1234"
	svr.basSecret = []byte("xxffe")
	if err := svr.Listen(":1288"); err != nil {
		panic(err)
	}
	svr.Run()
	err := svr.Auth("aas", "asas1", "255.255.255.255:1223")
	if err != nil {
		println(err.Error())
	}
}
