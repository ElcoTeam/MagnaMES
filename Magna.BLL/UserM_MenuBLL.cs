using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Magna.Model;
using Magna.DAL;
using Magna.Utility;
namespace Magna.BLL
{
    public class UserM_MenuBLL
    {
        public static string GetMenuList()
        {
            string jsonStr = "[]";
            List<UserM_Menu> menuList = UserM_MenuDAL.GetUserMenuList();
            jsonStr = JSONTools.ScriptSerialize<List<UserM_Menu>>(menuList);
            return jsonStr;
        } 
    }
}
