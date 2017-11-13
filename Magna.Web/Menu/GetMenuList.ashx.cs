using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Magna.BLL;
using Magna.Model;

namespace Magna.Web.Menu
{
    /// <summary>
    /// GetMenuList 的摘要说明
    /// </summary>
    public class GetMenuList : IHttpHandler
    {
        string Action = "";
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/plain";
            Action = RequstString("Action");
            if (Action == "TEST")
            {
                context.Response.Write(TEST());
            }
            else
            {
                context.Response.Write(GetUserMenu());
            }
            
        }

        public string  GetUserMenu()
        {
            string json = UserM_MenuBLL.GetMenuList();
            return json;
        }

        public string TEST()
        {
            UserM_UserInfo userInfo = new UserM_UserInfo();
            userInfo.user_no = RequstString("UserNo");
            int page = int.Parse(RequstString("page"));
            int pagesize = int.Parse(RequstString("rows"));
            string sidx = RequstString("sidx");    //排序名称
            string sord = RequstString("sord");    //排序方式
            string json = UserM_UserInfoBLL.GetUserInfoList( page, pagesize, sidx, sord, userInfo);
            return json;
        }
        public bool IsReusable
        {
            get
            {
                return false;
            }
        }

        public static string RequstString(string sParam)
        {
            return (HttpContext.Current.Request[sParam] == null ? string.Empty
                  : HttpContext.Current.Request[sParam].ToString().Trim());
        }
    }
}