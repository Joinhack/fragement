package controllers

import (
	"fmt"
	"github.com/joinhack/peony"
	"github.com/joinhack/radiusadmin/app/model"
)

type Vendor struct {
}

//@Intercept("BEFORE", priority=1)
func (v *Vendor) LoginRequired(c *peony.Controller) peony.Renderer {
	return loginCheck(c)
}

//@Mapper("/admin/vendors")
func (v *Vendor) Vendors() peony.Renderer {
	var vendors []*model.Vendor
	engine.Find(&vendors)
	return peony.Render(map[string]interface{}{
		"vendors": vendors,
	})
}

//@Mapper("/admin/vendor/add")
func (v *Vendor) Add() peony.Renderer {
	return peony.Render()
}

//@Mapper("/admin/vendor/exists")
func (v *Vendor) Exists(vendor *model.Vendor) peony.Renderer {
	has, _ := engine.Get(vendor)
	return peony.RenderJson(!has)
}

//@Mapper("/admin/vendor/<id>/edit")
func (v *Vendor) Edit(id int64) peony.Renderer {
	var vendor = &model.Vendor{Id: id}
	engine.Get(vendor)
	return peony.Render(map[string]interface{}{
		"vendor": vendor,
	})
}

//@Mapper("/admin/vendor/save")
func (v *Vendor) Save(vendor *model.Vendor, opType string, flash *peony.Flash) peony.Renderer {
	var back interface{} = (*Vendor).Add
	if opType == "edit" {
		back = (*Vendor).Edit
	}
	if len(vendor.Name) == 0 {
		flash.Error("名字不能为空")
		return peony.Redirect(back, map[string]interface{}{"id": vendor.Id})
	}
	if vendor.VendorId == 0 {
		flash.Error("VendorId不能为空")
		return peony.Redirect(back, map[string]interface{}{"id": vendor.Id})
	}

	if opType == "edit" {
		flash.Success(vendor.Name + "修改成功")
		engine.Id(vendor.Id).AllCols().Update(vendor)
	} else {
		flash.Success(vendor.Name + "添加成功")
		engine.Insert(vendor)
	}
	return peony.Redirect((*Vendor).Vendors)
}

//@Mapper("/admin/vendor/<id>/del")
func (u *Vendor) Del(id int64, flash *peony.Flash) peony.Renderer {
	var vendor = &model.Vendor{}
	engine.Id(id).Delete(vendor)
	flash.Success(fmt.Sprintf("厂商：%s 删除成功~！", vendor.Name))
	return peony.Redirect((*Vendor).Vendors)
}

type Attr struct {
}

//@Intercept("BEFORE", priority=1)
func (v *Attr) LoginRequired(c *peony.Controller) peony.Renderer {
	return loginCheck(c)
}

type VendorsMap map[int]string

func (v VendorsMap) Value(i int) string {
	return v[i]
}

func (v VendorsMap) NasVerbose(i int) string {
	if i == 0 {
		return "无"
	}
	return v[i]
}


//@Mapper("/admin/attrs")
func (v *Attr) Attrs() peony.Renderer {
	var attrs []*model.Attr
	engine.Find(&attrs)
	return peony.Render(map[string]interface{}{
		"attrs": attrs,
		"vendors": getVendorsMap(),
	})
}

type AttrDataType struct {
	Value, Desc string
}

var (
	attrDataTypes = []*AttrDataType{
		&AttrDataType{
			Value: "text",
			Desc:  "字符串",
		},
		&AttrDataType{
			Value: "string",
			Desc:  "二进制",
		},
		&AttrDataType{
			Value: "integer",
			Desc:  "整行",
		},
		&AttrDataType{
			Value: "time",
			Desc:  "时间",
		},
		&AttrDataType{
			Value: "address",
			Desc:  "地址",
		},
	}
)

//@Mapper("/admin/attr/exists")
func (v *Attr) Exists(attr *model.Attr) peony.Renderer {
	has, _ := engine.Get(attr)
	return peony.RenderJson(!has)
}

//@Mapper("/admin/attr/add")
func (v *Attr) Add() peony.Renderer {
	var vendors []*model.Vendor
	engine.Find(&vendors)
	return peony.Render(map[string]interface{}{
		"vendors":   vendors,
		"dataTypes": attrDataTypes,
	})
}


//@Mapper("/admin/attr/<id>/edit")
func (v *Attr) Edit(id int64) peony.Renderer {
	var attr = &model.Attr{Id: id}
	engine.Get(attr)
	var vendors []*model.Vendor
	engine.Find(&vendors)
	return peony.Render(map[string]interface{}{
		"attr": attr,
		"vendors":   vendors,
		"dataTypes": attrDataTypes,
	})
}


//@Mapper("/admin/attr/save")
func (v *Attr) Save(attr *model.Attr, opType string, flash *peony.Flash) peony.Renderer {
	var back interface{} = (*Attr).Add
	if opType == "edit" {
		back = (*Attr).Edit
	}
	if len(attr.Name) == 0 {
		flash.Error("名字不能为空")
		return peony.Redirect(back, map[string]interface{}{"id": attr.Id})
	}
	if attr.Type == 0 {
		flash.Error("类型不能为空")
		return peony.Redirect(back, map[string]interface{}{"id": attr.Id})
	}

	if opType == "edit" {
		flash.Success(attr.Name + "修改成功")
		engine.Id(attr.Id).AllCols().Update(attr)
	} else {
		flash.Success(attr.Name + "添加成功")
		engine.Insert(attr)
	}
	return peony.Redirect((*Attr).Attrs)
}

//@Mapper("/admin/attr/<id>/del")
func (u *Attr) Del(id int64, flash *peony.Flash) peony.Renderer {
	var attr = &model.Attr{}
	engine.Id(id).Delete(attr)
	flash.Success(fmt.Sprintf("属性：%s 删除成功~！", attr.Name))
	return peony.Redirect((*Attr).Attrs)
}





type Nas struct {

}


//@Intercept("BEFORE", priority=1)
func (v *Nas) LoginRequired(c *peony.Controller) peony.Renderer {
	return loginCheck(c)
}



//@Mapper("/admin/nas/exists")
func (v *Nas) Exists(nas *model.Nas) peony.Renderer {
	has, _ := engine.Get(nas)
	return peony.RenderJson(!has)
}

//@Mapper("/admin/nas/add")
func (v *Nas) Add() peony.Renderer {
	var vendors []*model.Vendor
	engine.Find(&vendors)
	return peony.Render(map[string]interface{}{
		"vendors":   vendors,
	})
}


//@Mapper("/admin/nas/<id>/edit")
func (v *Nas) Edit(id int64) peony.Renderer {
	var nas = &model.Nas{Id: id}
	engine.Get(nas)
	var vendors []*model.Vendor
	engine.Find(&vendors)
	return peony.Render(map[string]interface{}{
		"nas": nas,
		"vendors":   vendors,
	})
}


func getVendorsMap() VendorsMap {
	var vendors []*model.Vendor
	engine.Find(&vendors)
	var vendorsMap = make(VendorsMap, 0)
	for _, vendor := range vendors {
		vendorsMap[vendor.VendorId] = vendor.Name
	}
	return vendorsMap
}

//@Mapper("/admin/nass")
func (v *Nas) Nass() peony.Renderer {
	var nass []*model.Nas
	engine.Find(&nass)
	return peony.Render(map[string]interface{}{
		"nass": nass,
		"vendors": getVendorsMap(),
	})
}


//@Mapper("/admin/nas/save")
func (v *Nas) Save(nas *model.Nas, opType string, flash *peony.Flash) peony.Renderer {
	var back interface{} = (*Nas).Add
	if opType == "edit" {
		back = (*Nas).Edit
	}
	if len(nas.Name) == 0 {
		flash.Error("名字不能为空")
		return peony.Redirect(back, map[string]interface{}{"id": nas.Id})
	}
	if len(nas.Ip) == 0 {
		flash.Error("IP不能为空")
		return peony.Redirect(back, map[string]interface{}{"id": nas.Id})
	}

	if opType == "edit" {
		flash.Success(nas.Ip + "修改成功")
		engine.Id(nas.Id).AllCols().Update(nas)
	} else {
		flash.Success(nas.Ip + "添加成功")
		engine.Insert(nas)
	}
	return peony.Redirect((*Nas).Nass)
}

//@Mapper("/admin/nas/<id>/del")
func (u *Nas) Del(id int64, flash *peony.Flash) peony.Renderer {
	var nas = &model.Nas{}
	engine.Id(id).Delete(nas)
	flash.Success(fmt.Sprintf("Nas：%s 删除成功~！", nas.Name))
	return peony.Redirect((*Nas).Nass)
}

type Online struct {
}

//@Intercept("BEFORE", priority=1)
func (v *Online) LoginRequired(c *peony.Controller) peony.Renderer {
	return loginCheck(c)
}

//@Mapper("/admin/online")
func (b *Online) Online() peony.Renderer {
	return peony.Render(map[string]interface{}{
	})
}

var onlineSortedCols = []string{
	"_ID", 
	"_USER_NAME", 
	"_SESSION_ID", 
	"_START_TIME", 
	"_UPDATE_TIME", 
	"_STATUS",
	"_IN", 
	"_OUT", 
}

//@Mapper("/admin/online/json")
func (b *Online) OnlineJson(offset, limit int, orderCol int, order string) peony.Renderer {
	var onlines []*model.Online
	if orderCol < 0 || orderCol > len(onlineSortedCols) - 1 {
		orderCol = 0
	}
	s := engine.Limit(limit, offset)
	if order == "desc" {
		s.Desc(onlineSortedCols[orderCol])
	} else {
		s.Asc(onlineSortedCols[orderCol])
	}
	s.Find(&onlines)
	var rsData [][]interface{}
	for _, item := range onlines {
		rsData = append(rsData, []interface{}{
			item.Id,
			item.User,
			item.SessionId,
			item.SessionTime,
			item.StartTime.Format("2006-01-02 15:04:05"),
			item.UpdateTime.Format("2006-01-02 15:04:05"),
			item.Status,
			item.In,
			item.Out,
		})
	}
	count, _ := engine.Count(new(model.Online))
	return peony.Render(map[string]interface{}{
		"iTotalRecords": count,
		"iTotalDisplayRecords": count,
		"data": rsData,
	})
}
