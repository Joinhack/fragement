package model

import ()

type User struct {
	Id        int64 `xorm:"'_ID' pk <-"`
	Name      string `xorm:"'_DISP_NAME'"`
	LoginId   string `xorm:"'_NAME'"`
	Password  string `xorm:"'_PASSWORD'"`
	MaxOnline int    `xorm:"'_MAX_ONLINE'"`
	Authorize string `xorm:"'_AUTHORIZE'" -`
	Status    int    `xorm:"'_STATUS'"`
}

func (u *User) TableName() string {
	return "users"
}

func (u *User) StatusLabel() string {
	switch u.Status {
	case 1:
		return "正常"
	case 2:
		return "停用"
	default:
		return "未知"
	}
}


