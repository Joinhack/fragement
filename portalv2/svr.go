package main

import (
	"bytes"
	"crypto/md5"
	"encoding/binary"
	"errors"
	"fmt"
	"log"
	"net"
	"sync"
	"time"
)

type processingHandle struct {
	channel chan *PkgV2
	pkg *PkgV2
}

type PortalSvr struct {
	laddr      *net.UDPAddr
	udp        *net.UDPConn
	addrs      map[string]*net.UDPAddr
	processing map[string]*processingHandle
	seqs       map[string]uint16
	basAddr    string
	basSecret  []byte
	mtx        *sync.Mutex
}

func NewPortalSvr() *PortalSvr {
	svr := &PortalSvr{}
	svr.seqs = make(map[string]uint16)
	svr.addrs = make(map[string]*net.UDPAddr)
	svr.processing = make(map[string]*processingHandle)
	svr.mtx = new(sync.Mutex)
	return svr
}

type Attr interface {
	Type() byte
	Bytes() []byte
}

type UserNameAttr struct {
	Value string
}

func (u *UserNameAttr) Type() byte {
	return 0x1
}

func (u *UserNameAttr) Bytes() []byte {
	b := make([]byte, 2+len(u.Value))
	b[0] = u.Type()
	b[1] = byte(len(b))
	copy(b[2:], []byte(u.Value))
	return b
}

type PasswordAttr struct {
	Value string
}

func (u *PasswordAttr) Type() byte {
	return 0x2
}

func (u *PasswordAttr) Bytes() []byte {
	b := make([]byte, 2+len(u.Value))
	b[0] = u.Type()
	b[1] = byte(len(b))
	copy(b[2:], []byte(u.Value))
	return b
}

type PkgV2 struct {
	Version  byte
	Type     byte
	AuthType byte
	Resv     byte
	SerialNO uint16
	ReqID    uint16
	Secret   []byte
	UserAddr *net.TCPAddr
	ErrCode  byte
	AuthCode []byte
	Attrs    []Attr
}

var authCode = make([]byte, 16)

func NewPkgV2() *PkgV2 {
	v2 := &PkgV2{}
	v2.Version = 0x2
	v2.Type = 0x2
	v2.AuthType = 0x1
	v2.Resv = 0
	return v2
}

func unmarshal(b []byte) *PkgV2 {
	var pkg = new(PkgV2)
	ptr := b
	pkg.Version = ptr[0]
	ptr = ptr[1:]
	pkg.Type = ptr[0]
	ptr = ptr[1:]
	pkg.AuthType = ptr[0]
	ptr = ptr[1:]
	pkg.Resv = ptr[0]
	ptr = ptr[1:]
	pkg.SerialNO = binary.BigEndian.Uint16(ptr)
	ptr = ptr[2:]
	pkg.ReqID = binary.BigEndian.Uint16(ptr)
	ptr = ptr[2:]
	ip := net.IPv4(ptr[0], ptr[1], ptr[2], ptr[3])
	ptr = ptr[4:]
	port := binary.BigEndian.Uint16(ptr)
	ptr = ptr[2:]
	pkg.UserAddr = new(net.TCPAddr)
	pkg.UserAddr.IP = ip
	pkg.UserAddr.Port = int(port)
	pkg.ErrCode = ptr[0]
	ptr = ptr[1:]
	pkg.Attrs = make([]Attr, ptr[0])
	ptr = ptr[1:]
	copy(pkg.AuthCode, ptr[:16])
	ptr = ptr[16:]
	return pkg
}

func (v2 *PkgV2) Bytes() []byte {
	buf := new(bytes.Buffer)
	binary.Write(buf, binary.BigEndian, v2.Version)
	binary.Write(buf, binary.BigEndian, v2.Type)
	binary.Write(buf, binary.BigEndian, v2.AuthType)
	binary.Write(buf, binary.BigEndian, v2.Resv)
	binary.Write(buf, binary.BigEndian, v2.SerialNO)
	binary.Write(buf, binary.BigEndian, v2.ReqID)
	binary.Write(buf, binary.BigEndian, v2.UserAddr.IP.To4())
	binary.Write(buf, binary.BigEndian, uint16(v2.UserAddr.Port))
	binary.Write(buf, binary.BigEndian, v2.ErrCode)
	binary.Write(buf, binary.BigEndian, byte(len(v2.Attrs)))
	binary.Write(buf, binary.BigEndian, authCode)
	for _, attr := range v2.Attrs {
		binary.Write(buf, binary.BigEndian, attr.Bytes())
	}
	binary.Write(buf, binary.BigEndian, v2.Secret)
	b := buf.Bytes()
	sum := md5.Sum(b)
	ptr := b[16:]
	v2.AuthCode = sum[:]
	copy(ptr, v2.AuthCode)
	return b[:len(b)-len(v2.Secret)]
}

func (svr *PortalSvr) Listen(addr string) (err error) {
	if svr.laddr, err = net.ResolveUDPAddr("udp4", addr); err != nil {
		return
	}
	svr.udp, err = net.ListenUDP("udp4", svr.laddr)
	return
}

func (svr *PortalSvr) Send(addr string, v2 *PkgV2) (err error) {
	return svr.send(addr, v2.Bytes())
}

func (svr *PortalSvr) recieveJob() {
	for {
		buf := make([]byte, 65535)
		n, addr, err := svr.udp.ReadFrom(buf)
		if err != nil {
			log.Println(err)
			continue
		}
		if n < 32 {
			continue
		}
		var pkg *PkgV2
		buf = buf[:n]
		if pkg = unmarshal(buf); pkg == nil {
			continue
		}
		var handle *processingHandle

		var udpAddr = addr.(*net.UDPAddr)
		key := fmt.Sprintf("%s:%d-%x", udpAddr.IP.String(), udpAddr.Port, pkg.SerialNO)
		svr.mtx.Lock()
		handle, _ = svr.processing[key]
		svr.mtx.Unlock()
		if handle != nil {
			copy(buf[16:], handle.pkg.AuthCode)
			sum := md5.Sum(buf)
			if bytes.Compare(sum[:], pkg.AuthCode) == 0 {
				handle.channel <- pkg
			} else {
				log.Println("auth code error, please check.")
			}
		}
	}
}

func (svr *PortalSvr) Run() {
	go svr.recieveJob()
}

func (svr *PortalSvr) seq() uint16 {
	svr.mtx.Lock()
	defer svr.mtx.Unlock()
	var ok bool
	var seq uint16
	if seq, ok = svr.seqs[svr.basAddr]; !ok {
		seq = 0
	}
	seq++
	svr.seqs[svr.basAddr] = seq
	return seq
}

func (svr *PortalSvr) Auth(userName, password, uaddr string) (err error) {
	seq := svr.seq()
	v2 := NewPkgV2()
	v2.SerialNO = seq
	v2.Secret = svr.basSecret
	var userAddr *net.TCPAddr
	if userAddr, err = net.ResolveTCPAddr("tcp4", uaddr); err != nil {
		return
	}
	v2.UserAddr = userAddr
	v2.Attrs = append(v2.Attrs, &UserNameAttr{userName})
	v2.Attrs = append(v2.Attrs, &PasswordAttr{password})
	if err = svr.Send(svr.basAddr, v2); err != nil {
		return
	}

	key := fmt.Sprintf("%s-%x", svr.basAddr, seq)
	handle := &processingHandle{make(chan *PkgV2), v2}
	svr.mtx.Lock()
	svr.processing[key] = handle
	svr.mtx.Unlock()

	defer func(key string) {
		svr.mtx.Lock()
		delete(svr.processing, key)
		svr.mtx.Unlock()
	}(key)
	select {
	case pkg := <-handle.channel:
		if pkg.ErrCode == 0 {
			return
		} else {
			err = errors.New(fmt.Sprintf("auth error, code:%d", pkg.ErrCode))
			return
		}
	case <-time.After(10 * time.Second):
		err = errors.New(fmt.Sprintf("auth error: timeout"))
		return
	}
}

func (svr *PortalSvr) send(addr string, b []byte) (err error) {
	svr.mtx.Lock()
	defer svr.mtx.Unlock()
	var udpaddr *net.UDPAddr = svr.addrs[addr]
	if udpaddr == nil {
		if udpaddr, err = net.ResolveUDPAddr("udp4", addr); err != nil {
			return
		}
	}
	_, err = svr.udp.WriteTo(b, udpaddr)
	return
}
