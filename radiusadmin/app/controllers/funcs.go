package controllers

import (
	"github.com/joinhack/peony"
	"github.com/joinhack/radiusadmin/app/model"
)


func getMenusByParant(menus []*model.Menu, parent *model.Menu) []*model.Menu {
	var subs []*model.Menu
	for _, m := range menus {
		if m.ParentId == parent.Id {
			subs = append(subs, m)
			m.SubMenus = getMenusByParant(menus, m)
		}
	}
	return subs
}

func orderMenus(menus []*model.Menu) []*model.Menu {
	var top []*model.Menu
	for _, m := range menus {
		if m.ParentId == 0 {
			top = append(top, m)
			m.SubMenus = getMenusByParant(menus, m)
		}
	}

	return top
}

func loadAllMenus() []*model.Menu {
	var menus []*model.Menu
	engine.Find(&menus)
	return orderMenus(menus)
}

//@Mapper("/")
func Index() peony.Renderer {
	return peony.Redirect(Admin)
}

//@Mapper("/admin")
func Admin(flash *peony.Flash) peony.Renderer {
	rp := map[interface{}]interface{}{}
	if e, ok := flash.In["error"]; ok && e != "" {
		rp["info"] = e
	}
	return peony.Render(rp)
}

//@Mapper("/admin/init")
func Init(info string) peony.Renderer {
	InitDB()
	return peony.RenderJson(true)
}

func getOperatorById(id string) *model.Operator {
	o := model.Operator{LoginId: id}
	has, _ := engine.Get(&o)

	if !has {
		return nil
	}
	return &o
}

//@Mapper("/login", method="POST")
func Login(name, password string, c *peony.Controller) peony.Renderer {
	if len(name) == 0 || len(password) == 0 {
		c.Flash.Error("用户名或密码错误~!")
		return peony.Redirect(Admin)
	}
	oper := getOperatorById(name)
	if oper == nil ||
		oper.LoginId != name ||
		oper.Password != password {
		c.Flash.Error("用户名或密码错误~!")
		return peony.Redirect(Admin)
	}
	session := c.Session
	session.Set("operatorId", session.GetId())
	session.Set("operator", oper)
	if oper.IsMaster {
		session.Set("menus", loadAllMenus())
	}
	return peony.Redirect("/admin/home")

}
