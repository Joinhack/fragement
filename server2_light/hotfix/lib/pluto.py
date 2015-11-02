# -*- coding:utf-8 -*-

import cStringIO


MSGLEN_HEAD = 4             #包头长度
MSGLEN_RESERVED = 2         #保留位


def u32_to_sz(value):
    c1 = chr((value >> 24) & 0xff)
    c2 = chr((value >> 16) & 0xff)
    c3 = chr((value >> 8) & 0xff)
    c4 = chr(value & 0xff)
    #return ''.join([c1,c2,c3,c4])
    return ''.join([c4,c3,c2,c1])


__char_map = "0123456789abcdef"
def char_to_sz(c):
    c1 = (c >> 4) & 0xf
    c2 = c & 0xf
    return __char_map[c1] + __char_map[c2]
    
def isprint(c):    
    return ((ord(' ') <= c) and (c <= ord('~')) )    
    
def print_hex16(msg, len):
    ss = [' ' for x in xrange(68)]
    for i in xrange(len):
        sc = msg[i]
        c = ord(sc)
        ss[i*3] = __char_map[(c>>4)&0xf]
        ss[i*3+1] = __char_map[c&0xf]
        
        if isprint(c):
            ss[i+51] = sc
        else:
            ss[i+51] = '.'
    
    print ''.join(ss)

def print_hex(msg, len):
    sixteen = 16
    count = len / sixteen + 1
    
    for i in xrange(count):
        if i == count-1:
            print_hex16(msg[i*sixteen:], len%sixteen)
        else:
            print_hex16(msg[i*sixteen:], sixteen)


class Pluto(object):
    
    def __init__(self):
        self._m_len = 0
        self._m_buff = cStringIO.StringIO()
    
    def encode(self, msg_id):
        self._m_len = MSGLEN_HEAD + MSGLEN_RESERVED
        self.put_u16(msg_id)

    def endPluto(self):
        msg = u32_to_sz(self._m_len) + chr(0) + chr(0) + self._m_buff.getvalue()
        self._m_buff.close()
        print '22211'
        print_hex(msg, self._m_len)
        return msg
        
    def put_u32(self, value):
        #self._m_buff.write( chr((value >> 24)&0xff) ) 
        #self._m_buff.write( chr((value >> 16)&0xff) ) 
        #self._m_buff.write( chr((value >> 8)&0xff) ) 
        #self._m_buff.write( chr(value & 0xff) )
                
        self._m_buff.write( chr(value & 0xff) )        
        self._m_buff.write( chr((value >> 8)&0xff) ) 
        self._m_buff.write( chr((value >> 16)&0xff) ) 
        self._m_buff.write( chr((value >> 24)&0xff) ) 
        
        self._m_len += 4
    
    def put_u16(self, value):        
        #self._m_buff.write( chr((value >> 8)&0xff) ) 
        #self._m_buff.write( chr(value & 0xff) )
        self._m_buff.write( chr(value & 0xff) )
        self._m_buff.write( chr((value >> 8)&0xff) ) 
        self._m_len += 2
        
    def put_str(self, value):
        value_len = len(value)
        self.put_u16(value_len)
        self._m_buff.write(value)
        self._m_len += value_len



def f():
    pass


#test code
if __name__ == "__main__":
    print 111
    c=Pluto()
    c.encode(1234)
    c.put_str('abcdex22')
    c.endPluto()

