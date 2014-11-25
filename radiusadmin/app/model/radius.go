package model

import (
	"time"
)

type Attr struct {
	Id       int64  `xorm:"'_ID' pk <-"`
	Name     string `xorm:"'_NAME'"`
	VendorId int    `xorm:"'_VENDOR'"`
	Unique   bool   `xorm:"'_UNIQUE'"`
	DataType string `xorm:"'_DATA_TYPE'"`
	Type     int    `xorm:"'_TYPE'"`
}

func (attr *Attr) TableName() string {
	return "attrs"
}

type Vendor struct {
	Id       int64  `xorm:"'_ID' pk <-"`
	Name     string `xorm:"'_NAME'"`
	VendorId int    `xorm:"'_VENDOR_ID'"`
}

type Nas struct {
	Id     int64  `xorm:"'_ID' pk <-"`
	Name   string `xorm:"'_NAME'"`
	Ip     string `xorm:"'_IP'"`
	Key    string `xorm:"'_KEY'"`
	Vendor int    `xorm:"'_VENDOR'"`
}

type Online struct {
	Id          int64     `xorm:"'_ID' pk <-"`
	StartTime   time.Time `xorm:"'_START_TIME'"`
	EndTime     time.Time `xorm:"'_END_TIME'"`
	UpdateTime  time.Time `xorm:"'_UPDATE_TIME'"`
	SessionId   string    `xorm:"'_SESSION_ID'"`
	SessionTime string    `xorm:"'_SESSION_TIME'"`
	Status      int       `xorm:"'_STATUS'"`
	In          int       `xorm:"'_IN'"`
	Out         int       `xorm:"'_OUT'"`
	User        string    `xorm:"'_USER_NAME'"`
}

type AttrTemplate struct {
	Id         int64 `xorm:"'_ID' pk <-"`
	OperatorId int64
	BizName    string
}

type AttrTemplateRel struct {
	Id         int64 `xorm:"'_ID' pk <-"`
	TemplateId int64
	AttrId     int64
}
