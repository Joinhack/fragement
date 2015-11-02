# -*- coding:utf-8 -*-

import time
import socket


class Client(object):
    
    def connect(self, address, port):
        self._m_sk = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._m_sk.connect((address, port))
        
    def send(self, msg):
        print 'send',self._m_sk.send(msg)
        
    def recv(self):
        ss = []
        while True:
            data = self._m_sk.recv(1024)
            if len(data) > 0:
                ss.append(data)
            else:
                break
        return ''.join(ss)
    
    def close(self):
        self._m_sk.close()


def test():
    c = Client()
    c.connect('192.168.1.104', 5000)
    i = 1
    while True:
        print 'xxxx', i
        i+=1
        c.send('<policy-file-request/>')
        try:
            print c.recv()
        except:
            import traceback
            traceback.print_exc()
        #time.sleep(2)


if __name__ == '__main__':
    test()

