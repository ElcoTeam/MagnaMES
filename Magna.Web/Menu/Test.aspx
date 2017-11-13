<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Test.aspx.cs" Inherits="Magna.Web.Menu.Test" %>

<!DOCTYPE html>

<html>
<head>
    <meta charset="UTF-8" name="viewport" content="width=device-width" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>用户管理</title>
    <!--框架必需start-->
    <script src="../Content/scripts/jquery-1.11.1.min.js"></script>
    <link href="../Content/styles/font-awesome.min.css" rel="stylesheet" />
    <link href="../Content/scripts/plugins/jquery-ui/jquery-ui.min.css" rel="stylesheet" />
    <script src="../Content/scripts/plugins/jquery-ui/jquery-ui.min.js"></script>
    
    <link href="../Content/scripts/bootstrap/bootstrap.min.css" rel="stylesheet" />
    <script src="../Content/scripts/bootstrap/bootstrap.min.js"></script>
   
    <link href="../Content/scripts/plugins/jqgrid/jqgrid.css" rel="stylesheet" />
    <link href="../Content/styles/learun-ui.css" rel="stylesheet" />
    <script src="../Content/scripts/plugins/jqgrid/grid.locale-cn.js"></script>
    <script src="../Content/scripts/plugins/jqgrid/jqgrid.min.js"></script>
    <script src="../Content/scripts/plugins/tree/tree.js"></script>
    <script src="../Content/scripts/plugins/validator/validator.js"></script>
    <script src="../Content/scripts/utils/learun-ui.js"></script>
    <script src="../Content/scripts/utils/learun-form.js"></script>
    
    <style type="text/css">
        body {
            margin: 10px;
            margin-bottom: 0px;
        }
    </style>
</head>
<body>
    <div class="titlePanel">
            <div class="title-search">
                <table>
                    <tr>
                        <td>
                           <span class="formTitle">用户号：</span>
                        </td>
                        <td style="padding-left: 5px;">
                            <input id="UserNo" type="text" class="form-control" placeholder="请输入要查询关键字" style="width: 200px;" />
                        </td>
                        <td style="padding-left: 5px;">
                            <a id="btn_Search" class="btn btn-primary"><i class="fa fa-search"></i>&nbsp;查询</a>
                        </td>
                    </tr>
                </table>
            </div>
            <div class="toolbar">
                <div class="btn-group">
                    <a id="btn_Add" class="btn btn-default" onclick="btn_Add(event)"><i class="fa fa-plus"></i>&nbsp;新建</a>
                </div>
               
            </div>
        </div>

        <div class="gridPanel">
            <table id="gridTable"></table>
            <div id="gridPager"></div>
        </div>

   <script type="text/javascript">
       $(function () {
           InitialPage();
           GetGrid();

       });

       //初始化页面
       function InitialPage() {
           //resize重设(表格、树形)宽高
           $(window).resize(function (e) {
               window.setTimeout(function () {
                   $('#gridTable').setGridWidth(($('.gridPanel').width()));
                   $("#gridTable").setGridHeight($(window).height() - 136.5);
               }, 200);
               e.stopPropagation();
           });
           
       }

       //加载表格
       function GetGrid() {
           var selectedRowIndex = 0;
           var $gridTable = $('#gridTable');
           $gridTable.jqGrid({
               url: "GetMenuList.ashx",
               datatype: "json",
               height: $(window).height() - 136.5,
               autowidth: true,
               postData: {
                    Action: "TEST",
                    UserNo: $("#UserNo").val()
               },
               colModel: [
                   { label: '主键', name: 'user_id', hidden: true },
                   { label: '用户号', name: 'user_name', index: 'user_name', width: 200, align: 'left' },
                   { label: '登录名', name: 'user_no', index: 'user_no', width: 200, align: 'left' },
                   { label: '用户名', name: 'user_email', index: 'user_email', width: 200, align: 'left' },
                   { label: '邮箱', name: 'user_depid', index: 'user_depid', width: 150, align: 'left' },
                   { label: '部门名称', name: 'user_posiid', index: 'user_posiid', width: 200, align: 'left' },
                   { label: '用户组', name: 'user_menuids', index: 'user_menuids', width: 200, align: 'left' },
                   {
                       label: '角色名', name: '_user_sex', index: '_user_sex', width: 200, align: 'left'
                   }
               ],
               jsonReader: {
                   root: "dataList",
                   page: "currPage",
                   total: "totalpages",          //   很重要 定义了 后台分页参数的名字。
                   records: "totalCount",
                   repeatitems: false,
                   id: "id"
               },
               viewrecords: true,
               rowNum: 30,
               rowList: [30, 50, 100],
               pager: "#gridPager",
               sortname: '_user_id asc',
               rownumbers: true,
               rownumWidth: 50,
               shrinkToFit: false,
               gridview: true,
               onSelectRow: function () {
                   selectedRowIndex = $("#" + this.id).getGridParam('selrow');
               },
               gridComplete: function () {
                   $("#" + this.id).setSelection(selectedRowIndex, false);
               }
           });
          
       }

     </script>     
</body>
</html>
