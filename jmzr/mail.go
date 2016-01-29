package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"net/smtp"
	"strings"
)

func sendMail(title, content string) {
	auth := smtp.PlainAuth("", "joingong@163.com", "join123", "smtp.163.com")
	to := []string{"joinhack@qq.com", "779249967@qq.com"}
	from := "joingong@163.com"
	subject := title
	message := content
	msg := fmt.Sprintf("To: %s\r\nFrom: %s\r\nSubject: %s\r\nContent-Type: text/HTML\r\n\r\n%s\r\n", strings.Join(to, ","), from, subject, message)
	err := smtp.SendMail(
		"smtp.163.com:25",
		auth,
		from,
		to,
		[]byte(msg),
	)
	if err != nil {
		fmt.Println(err)
	}
}

func sendMyIp() {
	resp, err := http.Get("http://1212.ip138.com/ic.asp")
	if err != nil {
		return
	}
	defer resp.Body.Close()
	if bs, err := ioutil.ReadAll(resp.Body); err == nil {
		sendMail("服务器启动", string(bs))	
	}
}
