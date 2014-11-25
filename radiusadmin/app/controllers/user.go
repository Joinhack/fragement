package controllers

import (
	"github.com/joinhack/peony"
	"fmt"
	"github.com/joinhack/radiusadmin/app/model"
)

var (
	
)

type User struct {
	
}

//@Intercept("BEFORE", priority=1)
func (u *User) LoginRequired(c *peony.Controller) peony.Renderer {
	return loginCheck(c)
}

//@Mapper("/admin/users")
func (u *User) Users() peony.Renderer {
	return peony.Render()
}

var userSortedCols = []string{
	"_ID", 
	"_NAME", 
	"_DISP_NAME", 
	"_MAX_ONLINE", 
	"_STATUS",
}

//@Mapper("/admin/users/json")
func (u *User) UsersJson(offset, limit int, orderCol int, order string) peony.Renderer {
	var users []*model.User
	if orderCol < 0 || orderCol > len(userSortedCols) - 1 {
		orderCol = 0
	}
	s := engine.Limit(limit, offset)
	if order == "desc" {
		s.Desc(userSortedCols[orderCol])
	} else {
		s.Asc(userSortedCols[orderCol])
	}
	s.Find(&users)
	var rsData [][]interface{}
	for _, item := range users {
		rsData = append(rsData, []interface{}{
			item.Id,
			item.LoginId,
			item.Name,
			item.MaxOnline,
			item.Status,
			item.Id,
		})
	}
	count, _ := engine.Count(new(model.Online))
	return peony.Render(map[string]interface{}{
		"iTotalRecords": count,
		"iTotalDisplayRecords": count,
		"data": rsData,
	})
}


//@Mapper("/admin/user/save")
func (u *User) Save(user *model.User, opType string, flash *peony.Flash) peony.Renderer {
	var back interface{} = (*User).Add
	if opType == "edit" {
		back = (*User).Edit
	}
	if len(user.LoginId) == 0 {
		flash.Error("登录ID不能为空")
		return peony.Redirect(back, map[string]interface{}{"id":user.Id})
	}
	if len(user.Name) == 0 {
		flash.Error("名字不能为空")
		return peony.Redirect(back, map[string]interface{}{"id":user.Id})
	}
	if len(user.Password) < 6 {
		flash.Error("密码长度不够")
		return peony.Redirect(back, map[string]interface{}{"id":user.Id})
	}
	if opType == "edit" {
		flash.Success(user.LoginId + "修改成功")
		engine.Id(user.Id).AllCols().Update(user)
	} else {
		flash.Success(user.LoginId + "添加成功")
		engine.Insert(user)
	}
	return peony.Redirect((*User).Users)
}


func getUser(id int64) (user *model.User, err error) {
	user = &model.User{Id: id}
	engine.Get(user)
	return
}

//@Mapper("/admin/user/add")
func (u *User) Add() peony.Renderer {
	return peony.Render()
}

//@Mapper("/admin/user/exists")
func (u *User) Exists(user *model.User) peony.Renderer {
	has, _ := engine.Get(user)
	return peony.RenderJson(!has)
}

//@Mapper("/admin/user/<id>/edit")
func (u *User) Edit(id int64) peony.Renderer {
	user, _ := getUser(id)
	return peony.Render(map[string]interface{}{
		"user": user,
	})
}

//@Mapper("/admin/user/<id>/del")
func (u *User) Del(id int64, flash *peony.Flash) peony.Renderer {
	var user = &model.User{}
	engine.Id(id).Delete(user)
	flash.Success(fmt.Sprintf("帐号：%s 删除成功~！", user.LoginId));
	return peony.Redirect((*User).Users)
}