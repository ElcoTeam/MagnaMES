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

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/plain";

            context.Response.Write(GetUserMenu());
        }

        public string  GetUserMenu()
        {
            string json = UserM_MenuBLL.GetMenuList();
            return json;
        }

        public bool IsReusable
        {
            get
            {
                return false;
            }
        }
    }
}