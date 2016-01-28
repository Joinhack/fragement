package main

import (
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	"log"
	"net/http"
	"os"
	"strings"
)

var port int
var dbstring string

var (
	DBConnError = "database connection error"
	AuthError   = "execute auth error"
)

func init() {
	flag.IntVar(&port, "port", 8081, "Listen port")
	flag.StringVar(&dbstring, "db", "dfds:dfds@tcp(127.0.0.1:3309)/dsnode", "db configure: user:password@tcp(127.0.0.1:3306)/dbname")
}

type Auth struct {
	Account string
	Passwd  string
}

func progressLogin(account, passwd string) (code int, msg string) {
	var db *sql.DB
	var err error
	auth := Auth{}
	if db, err = sql.Open("mysql", dbstring); err != nil {
		msg = DBConnError
		goto err
	}
	defer db.Close()
	if err = db.Ping(); err != nil {
		msg = DBConnError
		goto err
	}

	if err = db.Ping(); err != nil {
		msg = DBConnError
		goto err
	}

	err = db.QueryRow("SELECT Account,Passwd  FROM Auth WHERE Account=?", account).Scan(&auth.Account, &auth.Passwd)
	if err == sql.ErrNoRows {
		_, err = db.Exec("insert into Auth(Account,Passwd) values(?,?)", account, passwd)
		if err != nil {
			msg = AuthError
			goto err
		}
	} else if err != nil {
		msg = AuthError
		goto err
	} else {
		if passwd != auth.Passwd {
			msg = "user or password error"
			goto err
		}
	}
	code = 0
	msg = "success"
	return
err:
	code = -1
	log.Println(err.Error())
	return

}

type handler func(w http.ResponseWriter, r *http.Request)

func BasicAuth(pass handler) handler {

	return func(w http.ResponseWriter, r *http.Request) {
		if u, p, ok := r.BasicAuth(); ok {
			if u != "19676436" && p != "779249967" {
				http.Error(w, "authorization failed", http.StatusUnauthorized)
				return
			}
		} else {
			w.Header().Add("WWW-Authenticate", "Basic realm=\"Please Auth.\"")
			http.Error(w, "authorization failed", http.StatusUnauthorized)
			return
		}
		pass(w, r)
	}
}

func loginHandle(w http.ResponseWriter, req *http.Request) {
	account := strings.TrimSpace(req.PostFormValue("Account"))
	passwd := strings.TrimSpace(req.PostFormValue("Password"))
	rs := map[string]interface{}{}
	var code int
	var msg string
	if account == "" || passwd == "" {
		rs["code"] = -1
		rs["message"] = "Parameter error."
		goto write
	}
	code, msg = progressLogin(account, passwd)
	rs["code"] = code
	rs["message"] = msg
write:
	if v, e := json.Marshal(rs); e != nil {
		w.Write([]byte(e.Error()))
	} else {
		w.Write(v)
	}
}

func shutdown(w http.ResponseWriter, r *http.Request) {
	log.Println("System shutdown")
	os.Exit(-1)
}

func main() {
	flag.Parse()
	http.HandleFunc("/login", loginHandle)
	http.HandleFunc("/shutdown", BasicAuth(shutdown))
	err := http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
	if err != nil {
		log.Fatal(err)
	}
}
