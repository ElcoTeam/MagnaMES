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


        /// <summary>
        /// 获取用户列表
        /// </summary>
        /// <param name="page">当前页</param>
        /// <param name="pagesize">每页记录数</param>
        /// <param name="sidx">排序名称</param>
        /// <param name="sord">排序方式</param>
        /// <param name="userInfo">用户类</param>
        /// <returns></returns>
        public static DataListModel<UserM_UserInfo> GetUserInfoList(int page, int pagesize, string sidx, string sord, UserM_UserInfo userInfo)
        {
            List<UserM_UserInfo> userList = new List<UserM_UserInfo>();
            DataListModel<UserM_UserInfo> userdata = new DataListModel<UserM_UserInfo>();
            int totalcount = 0;
            using (var conn = new SqlConnection(SqlConnString))
            {

                var param = new DynamicParameters();
                param.Add("@UserNo", userInfo.user_no);
                param.Add("@StartIndex", (page - 1) * pagesize + 1);
                param.Add("@EndIndex", page * pagesize);
                param.Add("@sidx", sidx);
                param.Add("@sord", sord);
                param.Add("@totalcount", 0, DbType.Int32, ParameterDirection.Output);

                userList = conn.Query<UserM_UserInfo>("usp_UserM_GetUserInfoList", param, null, true, null, CommandType.StoredProcedure).ToList();
                totalcount = param.Get<int>("@totalcount");
                userdata.dataList = userList;
                userdata.totalCount = totalcount.ToString();
                userdata.currPage = page.ToString();
                userdata.totalpages = (totalcount % Convert.ToInt16(pagesize) == 0 ? totalcount
                / Convert.ToInt16(pagesize) : totalcount / Convert.ToInt16(pagesize)
                + 1).ToString(); // 计算总页数 
                return userdata;
                //return conn.Query<DataListModel<UserM_UserInfo>>("select * from UserM_Menu").ToList();
            }
        }
    }
}
