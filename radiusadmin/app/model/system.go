package model

import ()

type Operator struct {
	Id       int64 `xorm:"pk <-"`
	Name     string
	LoginId  string `xorm:"varchar(255) not null unique 'login_id'`
	Password string `xorm:"varchar(64) not null`
	IsMaster bool
}

type Menu struct {
	Id       int64
	Url      string
	Name     string
	ParentId int64
	SubMenus []*Menu `xorm:"-"`
}



