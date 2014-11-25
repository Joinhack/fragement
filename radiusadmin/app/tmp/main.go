
package main
import (
	"reflect"
	"time"
	"fmt"
	"flag"
	peony "github.com/joinhack/peony"
	controllers0 "github.com/joinhack/radiusadmin/app/controllers"
	model0 "github.com/joinhack/radiusadmin/app/model"
)

var (
	_ = reflect.Ptr
	bindAddr   *string = flag.String("bindAddr", "", "By default, read from app.conf")
	importPath *string = flag.String("importPath", ".", "Go ImportPath for the app.")
	srcPath    *string = flag.String("srcPath", ".", "Path to the source root.")
	devMode    *bool   = flag.Bool("devMode", false, "Run mode")
)

func main() {
	flag.Parse()
	app := peony.NewApp(*srcPath, *importPath)
	if devMode != nil {
		app.DevMode = *devMode
	}
	app.LoadConfig()
	if *bindAddr != "" {
		app.BindAddr = *bindAddr
	}
	svr := app.NewServer()
	svr.Init()
	svr.InterceptMethod((*controllers0.Vendor).LoginRequired, 0, 1)

	svr.MethodMapper(`/admin/vendors`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Vendor).Vendors, &peony.Action{
			Name: "Vendor.Vendors",
			},
	)

	svr.MethodMapper(`/admin/vendor/add`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Vendor).Add, &peony.Action{
			Name: "Vendor.Add",
			},
	)

	svr.MethodMapper(`/admin/vendor/exists`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Vendor).Exists, &peony.Action{
			Name: "Vendor.Exists",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "vendor", 
					Type: reflect.TypeOf((*model0.Vendor)(nil)),
				},
			}},
	)

	svr.MethodMapper(`/admin/vendor/<id>/edit`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Vendor).Edit, &peony.Action{
			Name: "Vendor.Edit",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "id", 
					Type: reflect.TypeOf((*int64)(nil)).Elem(),
				},
			}},
	)

	svr.MethodMapper(`/admin/vendor/save`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Vendor).Save, &peony.Action{
			Name: "Vendor.Save",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "vendor", 
					Type: reflect.TypeOf((*model0.Vendor)(nil)),
				},
			
				&peony.ArgType{
					Name: "opType", 
					Type: reflect.TypeOf((*string)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "flash", 
					Type: reflect.TypeOf((*peony.Flash)(nil)),
				},
			}},
	)

	svr.MethodMapper(`/admin/vendor/<id>/del`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Vendor).Del, &peony.Action{
			Name: "Vendor.Del",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "id", 
					Type: reflect.TypeOf((*int64)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "flash", 
					Type: reflect.TypeOf((*peony.Flash)(nil)),
				},
			}},
	)
	svr.InterceptMethod((*controllers0.Attr).LoginRequired, 0, 1)

	svr.MethodMapper(`/admin/attrs`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Attr).Attrs, &peony.Action{
			Name: "Attr.Attrs",
			},
	)

	svr.MethodMapper(`/admin/attr/exists`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Attr).Exists, &peony.Action{
			Name: "Attr.Exists",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "attr", 
					Type: reflect.TypeOf((*model0.Attr)(nil)),
				},
			}},
	)

	svr.MethodMapper(`/admin/attr/add`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Attr).Add, &peony.Action{
			Name: "Attr.Add",
			},
	)

	svr.MethodMapper(`/admin/attr/<id>/edit`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Attr).Edit, &peony.Action{
			Name: "Attr.Edit",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "id", 
					Type: reflect.TypeOf((*int64)(nil)).Elem(),
				},
			}},
	)

	svr.MethodMapper(`/admin/attr/save`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Attr).Save, &peony.Action{
			Name: "Attr.Save",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "attr", 
					Type: reflect.TypeOf((*model0.Attr)(nil)),
				},
			
				&peony.ArgType{
					Name: "opType", 
					Type: reflect.TypeOf((*string)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "flash", 
					Type: reflect.TypeOf((*peony.Flash)(nil)),
				},
			}},
	)

	svr.MethodMapper(`/admin/attr/<id>/del`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Attr).Del, &peony.Action{
			Name: "Attr.Del",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "id", 
					Type: reflect.TypeOf((*int64)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "flash", 
					Type: reflect.TypeOf((*peony.Flash)(nil)),
				},
			}},
	)
	svr.InterceptMethod((*controllers0.Nas).LoginRequired, 0, 1)

	svr.MethodMapper(`/admin/nas/exists`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Nas).Exists, &peony.Action{
			Name: "Nas.Exists",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "nas", 
					Type: reflect.TypeOf((*model0.Nas)(nil)),
				},
			}},
	)

	svr.MethodMapper(`/admin/nas/add`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Nas).Add, &peony.Action{
			Name: "Nas.Add",
			},
	)

	svr.MethodMapper(`/admin/nas/<id>/edit`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Nas).Edit, &peony.Action{
			Name: "Nas.Edit",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "id", 
					Type: reflect.TypeOf((*int64)(nil)).Elem(),
				},
			}},
	)

	svr.MethodMapper(`/admin/nass`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Nas).Nass, &peony.Action{
			Name: "Nas.Nass",
			},
	)

	svr.MethodMapper(`/admin/nas/save`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Nas).Save, &peony.Action{
			Name: "Nas.Save",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "nas", 
					Type: reflect.TypeOf((*model0.Nas)(nil)),
				},
			
				&peony.ArgType{
					Name: "opType", 
					Type: reflect.TypeOf((*string)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "flash", 
					Type: reflect.TypeOf((*peony.Flash)(nil)),
				},
			}},
	)

	svr.MethodMapper(`/admin/nas/<id>/del`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Nas).Del, &peony.Action{
			Name: "Nas.Del",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "id", 
					Type: reflect.TypeOf((*int64)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "flash", 
					Type: reflect.TypeOf((*peony.Flash)(nil)),
				},
			}},
	)
	svr.InterceptMethod((*controllers0.Online).LoginRequired, 0, 1)

	svr.MethodMapper(`/admin/online`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Online).Online, &peony.Action{
			Name: "Online.Online",
			},
	)

	svr.MethodMapper(`/admin/online/json`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Online).OnlineJson, &peony.Action{
			Name: "Online.OnlineJson",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "offset", 
					Type: reflect.TypeOf((*int)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "limit", 
					Type: reflect.TypeOf((*int)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "orderCol", 
					Type: reflect.TypeOf((*int)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "order", 
					Type: reflect.TypeOf((*string)(nil)).Elem(),
				},
			}},
	)
	svr.InterceptMethod((*controllers0.User).LoginRequired, 0, 1)

	svr.MethodMapper(`/admin/users`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.User).Users, &peony.Action{
			Name: "User.Users",
			},
	)

	svr.MethodMapper(`/admin/users/json`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.User).UsersJson, &peony.Action{
			Name: "User.UsersJson",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "offset", 
					Type: reflect.TypeOf((*int)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "limit", 
					Type: reflect.TypeOf((*int)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "orderCol", 
					Type: reflect.TypeOf((*int)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "order", 
					Type: reflect.TypeOf((*string)(nil)).Elem(),
				},
			}},
	)

	svr.MethodMapper(`/admin/user/save`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.User).Save, &peony.Action{
			Name: "User.Save",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "user", 
					Type: reflect.TypeOf((*model0.User)(nil)),
				},
			
				&peony.ArgType{
					Name: "opType", 
					Type: reflect.TypeOf((*string)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "flash", 
					Type: reflect.TypeOf((*peony.Flash)(nil)),
				},
			}},
	)

	svr.MethodMapper(`/admin/user/add`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.User).Add, &peony.Action{
			Name: "User.Add",
			},
	)

	svr.MethodMapper(`/admin/user/exists`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.User).Exists, &peony.Action{
			Name: "User.Exists",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "user", 
					Type: reflect.TypeOf((*model0.User)(nil)),
				},
			}},
	)

	svr.MethodMapper(`/admin/user/<id>/edit`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.User).Edit, &peony.Action{
			Name: "User.Edit",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "id", 
					Type: reflect.TypeOf((*int64)(nil)).Elem(),
				},
			}},
	)

	svr.MethodMapper(`/admin/user/<id>/del`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.User).Del, &peony.Action{
			Name: "User.Del",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "id", 
					Type: reflect.TypeOf((*int64)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "flash", 
					Type: reflect.TypeOf((*peony.Flash)(nil)),
				},
			}},
	)
	svr.InterceptMethod((*controllers0.Bill).LoginRequired, 0, 1)

	svr.MethodMapper(`/admin/bill/bills`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Bill).Bills, &peony.Action{
			Name: "Bill.Bills",
			},
	)

	svr.MethodMapper(`/admin/bill/bills/json`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Bill).BillsJson, &peony.Action{
			Name: "Bill.BillsJson",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "offset", 
					Type: reflect.TypeOf((*int)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "limit", 
					Type: reflect.TypeOf((*int)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "orderCol", 
					Type: reflect.TypeOf((*int)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "order", 
					Type: reflect.TypeOf((*string)(nil)).Elem(),
				},
			}},
	)

	svr.FuncMapper(`/`, []string{"GET", "POST", "PUT", "DELETE"}, 
		controllers0.Index, &peony.Action{
			Name: "Index",
			},
	)

	svr.FuncMapper(`/admin`, []string{"GET", "POST", "PUT", "DELETE"}, 
		controllers0.Admin, &peony.Action{
			Name: "Admin",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "flash", 
					Type: reflect.TypeOf((*peony.Flash)(nil)),
				},
			}},
	)

	svr.FuncMapper(`/admin/init`, []string{"GET", "POST", "PUT", "DELETE"}, 
		controllers0.Init, &peony.Action{
			Name: "Init",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "info", 
					Type: reflect.TypeOf((*string)(nil)).Elem(),
				},
			}},
	)

	svr.FuncMapper(`/login`, []string{"POST"}, 
		controllers0.Login, &peony.Action{
			Name: "Login",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "name", 
					Type: reflect.TypeOf((*string)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "password", 
					Type: reflect.TypeOf((*string)(nil)).Elem(),
				},
			
				&peony.ArgType{
					Name: "c", 
					Type: reflect.TypeOf((*peony.Controller)(nil)),
				},
			}},
	)
	svr.InterceptMethod((*controllers0.Operator).LoginRequired, 0, 1)

	svr.MethodMapper(`/admin/home`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Operator).Home, &peony.Action{
			Name: "Operator.Home",
			},
	)

	svr.MethodMapper(`/admin/logout`, []string{"GET", "POST", "PUT", "DELETE"}, 
		(*controllers0.Operator).Logout, &peony.Action{
			Name: "Operator.Logout",
			
			Args: []*peony.ArgType{ 
				
				&peony.ArgType{
					Name: "session", 
					Type: reflect.TypeOf((*peony.Session)(nil)),
				},
			}},
	)


	svr.Router.Refresh()

	go func(){
		time.Sleep(1 * time.Second)
		fmt.Println("Server is running, listening on", app.BindAddr)
	}()
	if err := <- svr.Run(); err != nil {
		panic(err)
	}
}
