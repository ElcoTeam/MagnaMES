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
    public class UserM_MenuDAL
    {
        public static readonly string SqlConnString = ConfigurationManager.ConnectionStrings["ELCO_ConnectionString"].ConnectionString;
        public static List<UserM_Menu> GetUserMenuList()
        {
            
            using (var conn = new SqlConnection(SqlConnString))
            {
                
                //SqlCommand cmd = new SqlCommand();
                //conn.Open();
                //cmd.Connection = conn;
                //list =  conn.Query<UserM_Menu>("select * from UserM_Menu").ToList();
                return conn.Query<UserM_Menu>("select * from UserM_Menu").ToList();
            }
        }
    }
}
