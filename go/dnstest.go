package main

import (
	"flag"
	"fmt"
	"net"
	"os"
	"strings"
	"time"
)

var (
	sleep int = 0
	loop  int = 1
)

func init() {
	flag.IntVar(&sleep, "s", 0, "in loop sleep second")
	flag.IntVar(&loop, "l", 1, "loop times")
}

func usage() {
	println("usage:" + os.Args[0] + " hosts")
}

func main() {
	flag.Parse()
	c := make(chan int)
	defer close(c)
	if len(os.Args) < 2 {
		usage()
		return
	}

	args := flag.Args()
	max := len(args)
	finised := 0
	for i := 0; i < len(args); i++ {
		go func(i int) {
			defer func() { c <- 1 }()
			for l := 0; l < loop; l++ {
				ips, err := net.LookupHost(args[i])
				if err != nil {
					fmt.Fprintln(os.Stderr, "resolv error:", err.Error())
					return
				}
				fmt.Println("resloved success, ips:", strings.Join(ips, ","))
				if sleep > 0 {
					time.Sleep(1 * time.Second)
				}
			}
		}(i)
	}
	for finised < max {
		select {
		case <-c:
			finised++
		}
	}
}
