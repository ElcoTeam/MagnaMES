using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Magna.Model;
using System.Data.SqlClient;
using System.Configuration;
using System.Data;
using Dapper;

namespace Magna.DAL
{
    public class UserM_UserInfoDAL
    {
        public static readonly string SqlConnString = ConfigurationManager.ConnectionStrings["ELCO_ConnectionString"].ConnectionString;
        public static DataListModel<UserM_UserInfo> GetUserInfoList(int page, int pagesize, int startIndex, int endIndex, UserM_UserInfo userInfo)
        {
            List<UserM_UserInfo> userList = new List<UserM_UserInfo>();
            DataListModel<UserM_UserInfo> userdata = new DataListModel<UserM_UserInfo>();
            using (var conn = new SqlConnection(SqlConnString))
            {

                var param = new DynamicParameters();
                param.Add("@UserNo", userInfo.user_no);
                param.Add("@StartIndex", startIndex);
                param.Add("@EndIndex", endIndex);
                userList = conn.Query<UserM_UserInfo>("usp_UserM_GetUserInfoList", param, null, true, null, CommandType.StoredProcedure).ToList();
                userdata.dataList = userList;
                userdata.totalCount = userList.Count().ToString();
                userdata.currPage = page.ToString();
                userdata.totalpages = (userList.Count() % Convert.ToInt16(pagesize) == 0 ? userList.Count()
                / Convert.ToInt16(pagesize) : userList.Count() / Convert.ToInt16(pagesize)
                + 1).ToString(); // 计算总页数 
                return userdata;
                //return conn.Query<DataListModel<UserM_UserInfo>>("select * from UserM_Menu").ToList();
            }
        }
    }
}
