package model

import (
	"time"
)

type Billmsg struct {
	Id          int64     `xorm:"'_ID' pk <-"`
	Time        time.Time `xorm:"'_TIMESTAMP'"`
	SessionId   string    `xorm:"'_ACCT_SESSION_ID'"`
	SessionTime string    `xorm:"'_ACCT_SESSION_TIME'"`
	Status      int       `xorm:"'_ACCT_STATUS_TYPE'"`
	In          int       `xorm:"'_IN'"`
	Out         int       `xorm:"'_OUT'"`
	User        string    `xorm:"'_USER_NAME'"`
}

