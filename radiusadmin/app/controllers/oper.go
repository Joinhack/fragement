package controllers

import (
	"github.com/joinhack/peony"
)

type Operator struct {

}

func loginCheck(c *peony.Controller) peony.Renderer {
	session := c.Session
	id,ok := session.Get("operatorId")
	if !ok || id == nil {
		return peony.Redirect(Admin)
	}
	return nil
}



//@Intercept("BEFORE", priority=1)
func (oc *Operator) LoginRequired(c *peony.Controller) peony.Renderer {
	return loginCheck(c)
}

//@Mapper("/admin/home")
func (oc *Operator) Home() peony.Renderer {
	return peony.Render()
}

//@Mapper("/admin/logout")
func (oc *Operator) Logout(session *peony.Session) peony.Renderer {
	session.Del("operatorId")
	session.Del("operator")
	return peony.Redirect("/admin")
}
