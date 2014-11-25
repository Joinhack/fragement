package controllers

import (
	"github.com/joinhack/peony"
	"github.com/joinhack/radiusadmin/app/model"
)

type Bill struct {
}

//@Intercept("BEFORE", priority=1)
func (v *Bill) LoginRequired(c *peony.Controller) peony.Renderer {
	return loginCheck(c)
}

//@Mapper("/admin/bill/bills")
func (b *Bill) Bills() peony.Renderer {
	return peony.Render(map[string]interface{}{
	})
}

var billSortedCols = []string{
	"_ID", 
	"_USER_NAME", 
	"_ACCT_SESSION_ID", 
	"_ACCT_SESSION_TIME", 
	"_ACCT_STATUS_TYPE", 
	"_IN", 
	"_OUT", 
	"_TIMESTAMP",
}

//@Mapper("/admin/bill/bills/json")
func (b *Bill) BillsJson(offset, limit int, orderCol int, order string) (render peony.Renderer, err error) {

	var bills []*model.Billmsg
	if orderCol < 0 || orderCol > len(billSortedCols) - 1 {
		orderCol = 0
	}
	s := engine.Limit(limit, offset)
	if order == "desc" {
		s.Desc(billSortedCols[orderCol])
	} else {
		s.Asc(billSortedCols[orderCol])
	}
	if err = s.Find(&bills); err != nil {
		return
	}
	var rsData [][]interface{}
	for _, bill := range bills {
		rsData = append(rsData, []interface{}{
			bill.Id,
			bill.User,
			bill.SessionId,
			bill.SessionTime,
			bill.Status,
			bill.In,
			bill.Out,
			bill.Time.Format("2006-01-02 15:04:05"),
		})
	}
	count, _ := engine.Count(new(model.Billmsg))
	render = peony.Render(map[string]interface{}{
		"iTotalRecords": count,
		"iTotalDisplayRecords": count,
		"data":rsData,
	})
	return
}




