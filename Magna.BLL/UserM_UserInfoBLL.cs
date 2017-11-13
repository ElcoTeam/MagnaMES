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
    public class UserM_UserInfoBLL
    {
        public static string GetUserInfoList(int page, int pagesize, string sidx, string sord,  UserM_UserInfo userInfo)
        {
            string jsonStr = "[]";
            DataListModel<UserM_UserInfo> userList = UserM_UserInfoDAL.GetUserInfoList(page, pagesize, sidx, sord, userInfo);

            //List<UserM_Menu> menuList = UserM_MenuDAL.GetUserMenuList();
            jsonStr = JSONTools.ScriptSerialize<DataListModel<UserM_UserInfo>>(userList);
            return jsonStr;
        } 
    }
}
