package controllers

import (
	_ "github.com/joinhack/peony/session/memsession"
		"github.com/go-xorm/xorm"
	_ "github.com/go-sql-driver/mysql"
	"github.com/joinhack/radiusadmin/app/model"

)

var engine *xorm.Engine

func init() {
	var err error
	engine, err = xorm.NewEngine("mysql", "root:imroot!@tcp(coreos.net.cn:3306)/xradius?charset=utf8")
	if err != nil {
		panic(err)
	}
	engine.ShowSQL = true
}

func InitDB() {
	root := &model.Operator{
		LoginId:  "root",
		Password: "rootadmin",
		Name:     "超级管理员",
		IsMaster: true,
	}
	engine.DropTables(&model.Menu{})
	engine.Sync(root)
	engine.Insert(root)
	rootmenu := &model.Menu{
		Name: "系统管理",
		Url:  "",
	}
	engine.Sync(rootmenu)
	engine.Insert(rootmenu)
	engine.Insert(&model.Menu{
		Name:     "操作员",
		Url:      "/admin/operators",
		ParentId: rootmenu.Id,
	})

	rootmenu = &model.Menu{
		Name: "用户管理",
		Url:  "",
	}
	engine.Insert(rootmenu)
	engine.Insert(&model.Menu{
		Name:     "用户维护",
		Url:      "/admin/users",
		ParentId: rootmenu.Id,
	})
	engine.Insert(&model.Menu{
		Name:     "在线用户",
		Url:      "/admin/online",
		ParentId: rootmenu.Id,
	})
	engine.Insert(&model.Menu{
		Name:     "用户话单",
		Url:      "/admin/bill/bills",
		ParentId: rootmenu.Id,
	})
	rootmenu = &model.Menu{
		Name: "Radius管理",
		Url:  "",
	}
	engine.Insert(rootmenu)
	engine.Insert(&model.Menu{
		Name:     "设备维护",
		Url:      "/admin/vendors",
		ParentId: rootmenu.Id,
	})
	engine.Insert(&model.Menu{
		Name:     "属性维护",
		Url:      "/admin/attrs",
		ParentId: rootmenu.Id,
	})
	engine.Insert(rootmenu)
	engine.Insert(&model.Menu{
		Name:     "NAS维护",
		Url:      "/admin/nass",
		ParentId: rootmenu.Id,
	})
	
	engine.Sync(&model.User{})
	engine.Insert(&model.User{
		Name:     "测试用户",
		LoginId:  "user1",
		Password: "123456",
		Status:   0,
	})

	engine.Sync(&model.Vendor{})
	engine.Sync(&model.Attr{})
	engine.Sync(&model.Nas{})
	engine.Sync(&model.Online{})
	engine.Sync(&model.Billmsg{})
	engine.Sync(new(model.AttrTemplate))
	engine.Sync(new(model.AttrTemplateRel))
	template := &model.AttrTemplate{BizName:"时长配置", OperatorId:root.Id}
	engine.Insert(template)
	engine.Insert(&model.AttrTemplateRel{TemplateId:template.Id, AttrId:1})	
}
