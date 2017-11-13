using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Magna.Model
{
    public class DataListModel<T>
    {
        public string totalpages { get; set; }
        public string currPage { get; set; }
        public string totalCount { get; set; }
        public IEnumerable<T> dataList { get; set; }
    }
}
