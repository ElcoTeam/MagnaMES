﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Magna.Model
{
    public class UserM_Menu
    {
        public int? ID { get; set; }
        public string MenuNo { get; set; }
        public string MenuName { get; set; }
        public string MenuAddr { get; set; }
        public string ParentNo { get; set; }
        public string MenuTag { get; set; }
        public string Image { get; set; }
    }
}
