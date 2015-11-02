spawn-fcgi -a 127.0.0.1 -p 9001 -C 4 -f   /opt/server2/bin/card - F 4
spawn-fcgi -a 127.0.0.1 -p 9002 -C 4 -f   /opt/server2/bin/charge - F 4
spawn-fcgi -a 127.0.0.1 -p 9003 -C 4 -f   /opt/server2/bin/gift_sender - F 4
spawn-fcgi -a 127.0.0.1 -p 9004 -C 4 -f   /opt/server2/bin/plat_api - F 4