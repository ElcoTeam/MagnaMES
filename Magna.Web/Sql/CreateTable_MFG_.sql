--PP(流程控制)和MFG(生产计划)两个模块的接口定义表, 
--其目的是MFG从PP获得生产线的某个工位上的产出, 从而可以从生产线的库存中核销产线物料
CREATE TABLE PP_2_MFG_Interface
(
    [ID]            INT IDENTITY (1, 1) NOT NULL,                    -- (系统自动生成)
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('1001'),       --工厂编号    天津厂编号
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('1001-01'),    --车间编号    传感器车间编号
    [WHCode]        VARCHAR  (15)   NOT NULL DEFAULT ('1001-01-01'), --库房编号    传感器产线01线库
    [LineCode]      VARCHAR  (15)   NOT NULL DEFAULT ('1001-01-01'), --生产线编号  生产线01线编号
    [LOT]           NVARCHAR (50)   NOT NULL,                        --批号
    [StationNo]     VARCHAR  (15)   NOT NULL,                        --工作站编号: PP侧PP_LotRT表的ProcessCode
    [GoodsCode]     NVARCHAR (50)   NOT NULL,                        --货号:       PP侧PPLot表的GoodsCode
    [Qty]           NUMERIC  (18,4) NOT NULL,                        --数量:       此工位上需要核减的数量
    [GenerateTime]  DATETIME        NOT NULL DEFAULT GETDATE(),      --本条记录的生成时间
    [OutputTime]    DATETIME        NOT NULL DEFAULT '2010-01-01',   --MFG端传送处理时间(导入到预处理表Usage)
    [OutloadTime]   DATETIME        NOT NULL DEFAULT '2010-01-01',   --MFG端导入时间
    [Flag]          CHAR (1)        NOT NULL DEFAULT ('?'),          --行记录状态标志: 引用MFG_ConstKeyLists表中的: KeyType=P2M_FLAG, KeyName=Flag
                   -- ?:PP侧  新增或需要MFG侧重新再处理; 
                   -- X:未知异常, 需要PP侧和MFG侧共同查找
                   -- R:出错重置, 等待处理(其效果和?标志相同, 目的是给用户提供诸如"产品耗料"操作的结果反馈)
                   -- 0:MFG侧 准备处理;
                   -- 2:MFG侧 处理中;
                   -- 4:MFG侧 处理完成;
                   -- A:MFG侧 GoodsCode数值未知,
                   --         需要MFG侧在"产品耗料"模块进行配置, 重置后需要等待MFG下一处理周期重新处理
                   -- B:MFG侧 StationNo(ProcessCode)未知, 
                   --         需要MFG侧在"产品耗料"模块进行配置, 重置后需要等待MFG下一处理周期重新处理
                   -- C:MFG侧 库房现有料有数量不足情况(某一种或几种料不足), 等待MFG下一处理周期重新处理, 时间关系, 目前不考虑处理此异常
                   -- D:MFG侧 处理过程发生异常, 等待MFG下一处理周期重新处理, 时间关系, 需要手工进行系统处理                                                                     
    [Attribute_0]   VARCHAR  (50)       NULL,                        --备用属性字段, 供PP & MFG 共用
    [Attribute_1]   VARCHAR  (50)       NULL,                        --备用属性字段, 供PP侧使用
    [Attribute_2]   VARCHAR  (50)       NULL,                        --备用属性字段, 供PP侧使用
    [Attribute_3]   VARCHAR  (50)       NULL,                        --备用属性字段, 供PP侧使用 
    [Attribute_4]   VARCHAR  (50)       NULL,                        --备用属性字段, 供MFG侧使用
    [Attribute_5]   VARCHAR  (50)       NULL,                        --备用属性字段, 供MFG侧使用
    [Attribute_6]   VARCHAR  (50)       NULL                         --备用属性字段, 供MFG侧使用                                           
)

-- 线边库发料到产线的计划单
CREATE TABLE [dbo].[MFG_Push_Plan_Head] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [LineCode]      VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --生产线名称
    [TransferOrder] NVARCHAR (50)   NOT NULL,                        --物料推送编号
    [PlanDate]      DATETIME        NOT NULL,                        --计划生产日期
    [PlanShift]     VARCHAR  (4)    NOT NULL,                        --计划生产班次(DS,NS,AS,MS,PS,...)
    [ModelCode]     NVARCHAR (50)   NOT NULL,                        --产品型号
    [ModelName]     NVARCHAR (50)   NOT NULL,                        --产品名称
    [Qty]           NUMERIC  (18,4) NOT NULL,                        --产品数量
    [SalesOrder]    NVARCHAR (50)   NOT NULL,                        --销货单号
    [LOT]           NVARCHAR (50)   NOT NULL,                        --批号
    [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --创建时间
    [CreateUser]    NVARCHAR (50)   NOT NULL,                        --创建用户
    [ModifyTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --更新时间
    [ModifyUser]    NVARCHAR (50)   NOT NULL,                        --更新用户
    [Status]        NVARCHAR (2)    NOT NULL,                        --单子状态标志, 引用MFG_ConstKeyLists表中的: KeyType=MTL_ORHD, KeyName=Status的KeyValue和KeyTip
    [Attribute_0]   VARCHAR  (50)       NULL,                        --备用0-6
    [Attribute_1]   VARCHAR  (50)       NULL,
    [Attribute_2]   VARCHAR  (50)       NULL,
    [Attribute_3]   VARCHAR  (50)       NULL,
    [Attribute_4]   VARCHAR  (50)       NULL,
    [Attribute_5]   VARCHAR  (50)       NULL,
    [Attribute_6]   VARCHAR  (50)       NULL
);

-- 线边库发料到产线的用料计划详单
CREATE TABLE [dbo].[MFG_Push_Plan_Detail] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [LineCode]      VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --生产线名称
    [TransferOrder] NVARCHAR (50)   NOT NULL,                        --物料推送编号
    [PONO]          NUMERIC  (6)    NOT NULL,                        --对应BaaN的PONO(Position Number)
    [ITEM]          NVARCHAR (50)   NOT NULL,                        --料号
    [PlanQty]       NUMERIC  (18,4) NOT NULL,                        --计划需求数量
    [OffsetQty]     NUMERIC  (18,4) NOT NULL,                        --计划数量偏差调整
    [PushedQty]     NUMERIC  (18,4) NOT NULL,                        --已经发送数量(实发汇总，目的为后期制作查询报告提高性能)
    [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --创建时间
    [CreateUser]    NVARCHAR (50)   NOT NULL,                        --创建用户
    [ModifyTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --更新时间
    [ModifyUser]    NVARCHAR (50)   NOT NULL,                        --更新用户
    [Status]        NVARCHAR (2)    NOT NULL,                        --行记录状态标志, 引用MFG_ConstKeyLists表中的: KeyType=MTL_ORLN, KeyName=Status的KeyValue和KeyTip
    [Attribute_0]   VARCHAR  (50)       NULL,                        --备用0-6
    [Attribute_1]   VARCHAR  (50)       NULL,
    [Attribute_2]   VARCHAR  (50)       NULL,
    [Attribute_3]   VARCHAR  (50)       NULL,
    [Attribute_4]   VARCHAR  (50)       NULL,
    [Attribute_5]   VARCHAR  (50)       NULL,
    [Attribute_6]   VARCHAR  (50)       NULL
);

-- 线边库发料到产线的实发详单
-- 此表目前仅仅被使用记录一下实际曾经发生的发料事件记录
CREATE TABLE [dbo].[MFG_Push_Actual] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [WHCode_From]   VARCHAR  (15)   NOT NULL,                        --出库房编号
    [WHCode_To]     VARCHAR  (15)   NOT NULL,                        --入库房编号
    [StationNo_To]  VARCHAR  (15)   NOT NULL,                        --工作站名称
    [TransferOrder] NVARCHAR (50)   NOT NULL,                        --物料推送编号
    [PONO]          NUMERIC  (6)    NOT NULL,                        --对应BaaN的PONO(Position Number)
    [ITEM]          NVARCHAR (50)   NOT NULL,                        --料号
    [IssueQty]      NUMERIC  (18,4) NOT NULL,                        --实发数量
    [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --创建时间
    [CreateUser]    NVARCHAR (50)   NOT NULL,                        --创建用户
    [Status]        NVARCHAR (2)    NOT NULL,                        --行记录状态标志(1: OK)
    [Attribute_0]   VARCHAR  (50)       NULL,                        --备用0-6
    [Attribute_1]   VARCHAR  (50)       NULL,
    [Attribute_2]   VARCHAR  (50)       NULL,
    [Attribute_3]   VARCHAR  (50)       NULL,
    [Attribute_4]   VARCHAR  (50)       NULL,
    [Attribute_5]   VARCHAR  (50)       NULL,
    [Attribute_6]   VARCHAR  (50)       NULL
);

-- 库存盘点头表
CREATE TABLE [dbo].[MFG_CC_Task_Head] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [WHCode]        VARCHAR  (15)   NOT NULL,                        --库房编号
    [LineCode]      VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --生产线编号
    [TransferOrder] NVARCHAR (50)   NOT NULL,                        --盘点单子编号
    [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --创建时间
    [CreateUser]    NVARCHAR (50)   NOT NULL,                        --创建用户
    [Status]        NVARCHAR (2)    NOT NULL,                        --单子状态标志(-2:REJECT; -1:MODIFY; 0:NEW/OPEN; 1:APPROVED; 2:CLOSE)
    [Attribute_0]   VARCHAR  (50)       NULL,                        --备用0-6
    [Attribute_1]   VARCHAR  (50)       NULL,
    [Attribute_2]   VARCHAR  (50)       NULL,
    [Attribute_3]   VARCHAR  (50)       NULL,
    [Attribute_4]   VARCHAR  (50)       NULL,
    [Attribute_5]   VARCHAR  (50)       NULL,
    [Attribute_6]   VARCHAR  (50)       NULL
);

-- 库存盘点物料明细表
CREATE TABLE [dbo].[MFG_CC_Task_Detail] (
    [TransferOrder] NVARCHAR (50)   NOT NULL,                        --盘点单子编号
    [PONO]          NUMERIC  (6)    NOT NULL,                        --PONO
    [ITEM]          NVARCHAR (50)   NOT NULL,                        --料号
    [AdvanceQty]    NUMERIC  (18,4) NOT NULL,                        --调整后的在线数量
    [OnhandQty]     NUMERIC  (18,4) NOT NULL,                        --在线数量（包含锁定数量）
    [BlockQty]      NUMERIC  (18,4) NOT NULL,                        --锁定数量
    [OrderQty]      NUMERIC  (18,4) NOT NULL,                        --待入数量
    [AllocateQty]   NUMERIC  (18,4) NOT NULL,                        --待发数量
    [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --创建时间
    [CreateUser]    NVARCHAR (50)   NOT NULL,                        --创建用户
    [ModifyTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --更新时间
    [ModifyUser]    NVARCHAR (50)   NOT NULL,                        --更新用户
    [Status]        NVARCHAR (2)    NOT NULL,                        --状态标志(-2:DISABLED; -1:MODIFY; 0:NEW; 1:ACTIVE; 2:CLOSE)
    [Attribute_0]   VARCHAR  (50)       NULL,                        --备用0-6
    [Attribute_1]   VARCHAR  (50)       NULL,
    [Attribute_2]   VARCHAR  (50)       NULL,
    [Attribute_3]   VARCHAR  (50)       NULL,
    [Attribute_4]   VARCHAR  (50)       NULL,
    [Attribute_5]   VARCHAR  (50)       NULL,
    [Attribute_6]   VARCHAR  (50)       NULL
);

-- 授权路径模板表
CREATE TABLE [dbo].[MFG_Appr_Template] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [OrderType]     NVARCHAR (50)   NOT NULL,                        --授权类型
    [Approver]      NVARCHAR (50)   NOT NULL,                        --审批人
    [ApproveOrder]  INT             NOT NULL DEFAULT (1),            --审批人排列顺序(1，2，3...)
    [EMailAddress]  NVARCHAR (50)   NOT NULL,                        --审批人E-Mail Address
    [EMailTitle]    NVARCHAR (50)   NOT NULL,                        --审批人E-Mail Title
    [EMailContent]  NVARCHAR (150)  NOT NULL,                        --审批人E-Mail Content
    [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --创建时间
    [CreateUser]    NVARCHAR (50)   NOT NULL,                        --创建用户
    [ModifyTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --更新时间
    [ModifyUser]    NVARCHAR (50)   NOT NULL,                        --更新用户
    [Status]        NVARCHAR (2)    NOT NULL                         --模板有效标志(-2:DISABLED; -1:MODIFY; 0:NEW; 1:ACTIVE; 2:CLOSE)
);

-- 授权路径实际操作表（记录表）
CREATE TABLE [dbo].[MFG_Appr_Actual] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [TransferOrder] NVARCHAR (50)   NOT NULL,                        --盘点单子编号
    [Approver]      NVARCHAR (50)   NOT NULL,                        --审批人
    [ApproveOrder]  INT             NOT NULL DEFAULT (1),            --审批人排列顺序(1，2，3...)
    [EMailAddress]  NVARCHAR (50)   NOT NULL,                        --审批人E-Mail Address
    [EMailTitle]    NVARCHAR (50)   NOT NULL,                        --审批人E-Mail Title
    [EMailContent]  NVARCHAR (150)  NOT NULL,                        --审批人E-Mail Content
    [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --创建时间
    [CreateUser]    NVARCHAR (50)   NOT NULL,                        --创建用户
    [ModifyTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --更新时间
    [ModifyUser]    NVARCHAR (50)   NOT NULL,                        --更新用户
    [Status]        NVARCHAR (2)    NOT NULL                         --审批状态标志(-2:REJECT; -1:MODIFY; 0:NEW/OPEN; 1:APPROVED)
);

-- 库存数据表
CREATE TABLE [dbo].[MFG_Inv_Data] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [WHCode]        VARCHAR  (15)   NOT NULL,                        --库房编号
    [ITEM]          NVARCHAR (50)   NOT NULL,                        --料号
    [OnhandQty]     NUMERIC  (18,4) NOT NULL,                        --在线数量（包含锁定数量）
    [BlockQty]      NUMERIC  (18,4) NOT NULL,                        --锁定数量
    [OrderQty]      NUMERIC  (18,4) NOT NULL,                        --待入数量
    [AllocateQty]   NUMERIC  (18,4) NOT NULL,                        --待发数量
    [ModifyTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --更新时间
    [ModifyUser]    NVARCHAR (50)   NOT NULL,                        --更新用户
    [Status]        NVARCHAR (2)    NOT NULL,                        --行记录状态标志(0: NEW; 1: ACTIVE; -1: BLOCKED; -2: DELETED;)
    [Attribute_0]   VARCHAR  (50)       NULL,                        --备用0-6
    [Attribute_1]   VARCHAR  (50)       NULL,
    [Attribute_2]   VARCHAR  (50)       NULL,
    [Attribute_3]   VARCHAR  (50)       NULL,
    [Attribute_4]   VARCHAR  (50)       NULL,
    [Attribute_5]   VARCHAR  (50)       NULL,
    [Attribute_6]   VARCHAR  (50)       NULL
);

-- 库存数据快照表
CREATE TABLE [dbo].[MFG_Inv_Data_Snapshot] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [WHCode]        VARCHAR  (15)   NOT NULL,                        --库房编号
    [ITEM]          NVARCHAR (50)   NOT NULL,                        --料号
    [OnhandQty]     NUMERIC  (18,4) NOT NULL,                        --在线数量（包含锁定数量）
    [BlockQty]      NUMERIC  (18,4) NOT NULL,                        --锁定数量
    [OrderQty]      NUMERIC  (18,4) NOT NULL,                        --待入数量
    [AllocateQty]   NUMERIC  (18,4) NOT NULL,                        --待发数量
    [SnapTime]      DATETIME        NOT NULL DEFAULT GETDATE(),      --快照时间
    [Status]        NVARCHAR (2)    NOT NULL                         --行记录状态标志(0: NEW; 1: ACTIVE; -1: BLOCKED; -2: DELETED;)
);

-- 库存转移操作表：出库
CREATE TABLE [dbo].[MFG_Inv_Trans_From] (
    [ID]            NUMERIC(18, 0)  NOT NULL IDENTITY(1,1),
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [WHCode]        VARCHAR  (15)   NOT NULL,                        --出库库房
    [ORIDCK]        VARCHAR  (50)   NOT NULL,                        --物料包装编号
    [TransferOrder] NVARCHAR (50)   NOT NULL,                        --转移单编号
    [PONO]          NUMERIC  (6)    NOT NULL,                        --PONO
    [ITEM]          NVARCHAR (50)   NOT NULL,                        --料号
    [Qty]           NUMERIC  (18,4) NOT NULL,                        --转移数量
    [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --创建时间
    [CreateUser]    NVARCHAR (50)   NOT NULL,                        --创建用户
    [Status]        NVARCHAR (2)    NOT NULL,                        --行记录状态标志, 引用MFG_ConstKeyLists表中的: KeyType=MTL_SEND, KeyName=Status的KeyValue和KeyTip
    [Operate]       NVARCHAR (90)       NULL,                        --操作描述(可以用来记录盘点减账，具体操作描述)
    [Attribute_0]   VARCHAR  (50)       NULL,                        --备用0-6
    [Attribute_1]   VARCHAR  (50)       NULL,
    [Attribute_2]   VARCHAR  (50)       NULL,
    [Attribute_3]   VARCHAR  (50)       NULL,
    [Attribute_4]   VARCHAR  (50)       NULL,
    [Attribute_5]   VARCHAR  (50)       NULL,
    [Attribute_6]   VARCHAR  (50)       NULL
);

-- 库存转移操作表：入库
CREATE TABLE [dbo].[MFG_Inv_Trans_To] (
    [ID]            NUMERIC(18, 0)  NOT NULL IDENTITY(1,1),
    [SourceID]      NUMERIC(18, 0)  NOT NULL,
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [WHCode]        VARCHAR  (15)   NOT NULL,                        --入库库房
    [ORIDCK]        VARCHAR  (50)   NOT NULL,                        --物料包装编号
    [TransferOrder] NVARCHAR (50)   NOT NULL,                        --转移单编号
    [PONO]          NUMERIC  (6)    NOT NULL,                        --PONO
    [ITEM]          NVARCHAR (50)   NOT NULL,                        --料号
    [Qty]           NUMERIC  (18,4) NOT NULL,                        --转移数量
    [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --创建时间 (推送时间)
    [CreateUser]    NVARCHAR (50)   NOT NULL,                        --创建用户 (推送用户)
    [ReceiveTime]   DATETIME            NULL,                        --接收时间
    [ReceiveUser]   NVARCHAR (50)       NULL,                        --接收用户
    [Status]        NVARCHAR (2)    NOT NULL,                        --行记录状态标志, 引用MFG_ConstKeyLists表中的: KeyType=MTL_RECV, KeyName=Status的KeyValue和KeyTip
    [Operate]       NVARCHAR (90)       NULL,                        --操作描述(可以用来记录盘点减账，具体操作描述)
    [Attribute_0]   VARCHAR  (50)       NULL,                        --备用0-6
    [Attribute_1]   VARCHAR  (50)       NULL,
    [Attribute_2]   VARCHAR  (50)       NULL,
    [Attribute_3]   VARCHAR  (50)       NULL,
    [Attribute_4]   VARCHAR  (50)       NULL,
    [Attribute_5]   VARCHAR  (50)       NULL,
    [Attribute_6]   VARCHAR  (50)       NULL
);

-- 物料站点分配配置表: 即根据机种(产品)在各工位的耗料模板表
-- 潜在需求: 在PP_LOTRT表中,没有出现RountCode字段, 当下可以使用View绕开此需求
CREATE TABLE [dbo].[MFG_Station_MTL_UseBase] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [WHCode]        VARCHAR  (15)   NOT NULL,                        --库房编号
    [LineCode]      VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --生产线名称
    [StationNo]     VARCHAR  (15)   NOT NULL,                        --工作站名称, 引用 Info_Process.ProcessCode
    [RountCode]     CHAR     (4)    NOT NULL,                        --产品制途编号, 引用 Info_Rount.RountCode
    [MItem]         NVARCHAR (50)   NOT NULL,                        --主料号
    [SItem]         NVARCHAR (50)   NOT NULL,                        --料号
    [Qty]           NUMERIC  (18,4) NOT NULL,                        --单台产品此站用料数量
    [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --创建时间
    [CreateUser]    NVARCHAR (50)   NOT NULL,                        --创建用户
    [ModifyTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --更新时间
    [ModifyUser]    NVARCHAR (50)   NOT NULL,                        --更新用户
    [Status]        NVARCHAR (2)    NOT NULL,                        --行记录状态标志  0: 新增; 当下只有此一个标志值
    [Attribute_0]   VARCHAR  (50)       NULL,                        --备用0-6
    [Attribute_1]   VARCHAR  (50)       NULL,
    [Attribute_2]   VARCHAR  (50)       NULL,
    [Attribute_3]   VARCHAR  (50)       NULL,
    [Attribute_4]   VARCHAR  (50)       NULL,
    [Attribute_5]   VARCHAR  (50)       NULL,
    [Attribute_6]   VARCHAR  (50)       NULL
);

-- 生产线站点耗料计数表
-- 数据刷新方式: Job定时更新/客户查询触发?
CREATE TABLE [dbo].[MFG_Station_MTL_Usage] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [WHCode]        VARCHAR  (15)   NOT NULL,                        --库房编号
    [LineCode]      VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --生产线编号
    [StationNo]     VARCHAR  (15)   NOT NULL,                        --工作编号
    [TransferOrder] NVARCHAR (50)   NOT NULL,                        --物料推送编号
    [LOT]           NVARCHAR (50)   NOT NULL,                        --批号
    [MItem]         NVARCHAR (50)   NOT NULL,                        --主料号
    [SItem]         NVARCHAR (50)   NOT NULL,                        --料号
    [Qty]           NUMERIC  (18,4) NOT NULL,                        --此站已经用料数量
    [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --创建时间
    [CreateUser]    NVARCHAR (50)   NOT NULL,                        --创建用户
    [ModifyTime]    DATETIME        NOT NULL DEFAULT GETDATE(),      --更新时间
    [ModifyUser]    NVARCHAR (50)   NOT NULL,                        --更新用户
    [Status]        NVARCHAR (2)    NOT NULL,                        --行记录状态标志 0: 等待更新库存; 1:开始更新库存;2:更新库存完成
                                                                     --引用MFG_ConstKeyLists表中的: KeyType=M2I_STAT, KeyName=Status
    [PP_2_MFG_ID]   NUMERIC (18,0)  NOT NULL,                        --PP_2_MFG_Interface: ID
    [Attribute_0]   VARCHAR  (50)       NULL,                        --备用0-6
    [Attribute_1]   VARCHAR  (50)       NULL,
    [Attribute_2]   VARCHAR  (50)       NULL,
    [Attribute_3]   VARCHAR  (50)       NULL,
    [Attribute_4]   VARCHAR  (50)       NULL,
    [Attribute_5]   VARCHAR  (50)       NULL,
    [Attribute_6]   VARCHAR  (50)       NULL
);

--存储定义一组依据类型和名称等常量数据
CREATE TABLE [dbo].[MFG_ConstKeyLists] (
    [KeyType]       VARCHAR  (15)   NOT NULL DEFAULT ('PUSH'),
    [KeyName]       VARCHAR  (15)   NOT NULL DEFAULT ('Status'),
    [KeyValue]      NVARCHAR (15)   NOT NULL DEFAULT (''),
    [KeyTip]        NVARCHAR (50)       NULL DEFAULT (''),
    [Attribute_0]   VARCHAR  (50)       NULL,                        --可以使用这个字段的定义来决定是否可以让客户端用户的可见性等.
    [DisplayOrder]  NUMERIC  (4,0)      NULL DEFAULT (0)             --值显示顺序.
);

-- 如果考虑排产实际，需要引入calendar的概念，
-- 这需要一个比较独立的模块来维护（时间原因，此处略）

-- 生产线排班班次名称及顺序表
CREATE TABLE [dbo].[MFG_ShiftCodeOrders] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [ShiftCode]     VARCHAR  (4)    NOT NULL DEFAULT ('DS'),         --排班班次编号
    [ShiftCodeName] VARCHAR  (50)   NOT NULL DEFAULT ('DS'),         --排班班次名称(如:DS:白班,NS:夜半,AS:早班,MS:中班,PS:下午班,等等)
    [StartTime]     TIME(0)         NOT NULL DEFAULT ('08:30'),      --排班班次开班时刻，结束时刻 = 开班时刻 + 工作时长 + 休息时长
    [WorkHours]     NUMERIC  (4,1)  NOT NULL DEFAULT (8),            --排班班次工作时长
    [RestHours]     NUMERIC  (4,1)  NOT NULL DEFAULT (1),            --排班班次休息时长
    [ShiftCodeOrder]INT             NOT NULL DEFAULT (1)             --排班班次顺序(1，2，3...),目的是便于显示顺序和后期的依据班次的精确统计计算。
);

-- 生产线工作站(工位)名称及排列顺序表: 因为涉及到和Info_Process的对应, 为了不再引入一个映射表,此表最后可能用不到
CREATE TABLE [dbo].[MFG_StationNoOrders] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [LineCode]      VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --生产线编号(如：LineA,LineB等等)
    [StationNo]     VARCHAR  (15)   NOT NULL,                        --工作站编号, 此处引用 Info_Process.ProcessCode
    [StationNoName] NVARCHAR (50)   NOT NULL,                        --工作站名称, 原则上同编号一致，这里可以权当作注释来使用
    [StationNoOrder]INT             NOT NULL DEFAULT (1),            --工作站名称排列顺序(1，2，3...)
    [Status]        NVARCHAR (2)    NOT NULL                         --行记录状态标志
);

-- 生产线线别名称及排列顺序表
CREATE TABLE [dbo].[MFG_LineCodeOrders] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [LineCode]      VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --生产线编号(如：A,B等等)
    [LineCodeName]  VARCHAR  (50)   NOT NULL DEFAULT ('A'),          --生产线名称(如：LineA,LineB等等), 为了避免冲突, LineName在SQL Server中为关键字
    [LineCodeOrder] INT             NOT NULL DEFAULT (1)             --生产线排列顺序(1，2，3...)
);

-- 库房名称及排列顺序表
CREATE TABLE [dbo].[MFG_WHCodeOrders] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门
    [WHCode]        VARCHAR  (15)   NOT NULL DEFAULT ('AAZL'),       --库房编号(如：AAZL：A工厂，A部门，ZL站立车间; AAXB:AA线边库)
    [WHCodeName]    VARCHAR  (15)   NOT NULL DEFAULT ('AAZL'),       --库房名称
    [WHCodeDesc]    NVARCHAR (90)       NULL,                        --库房描述
    [WHCodeOrder]   INT             NOT NULL DEFAULT (1)             --库房排列顺序(1，2，3...)
);

--业务部门定义表
CREATE TABLE [dbo].[MFG_WorkGroups] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂（天津，武汉，青岛，等等）
    [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门(SENA, DECA, RELA, PROA 等等)
    [WorkGroupName] VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --业务部门(传感器、编码器、继电器、工程部等等)
    [Description]   NVARCHAR (50)   NOT NULL DEFAULT ('A')           --描述, 经常为业务部门的全称。
);

-- 公司工厂定义表
CREATE TABLE [dbo].[MFG_Factorys] (
    [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂编号（ELCOA, ELCOB 等等）
    [FactoryName]   VARCHAR  (15)   NOT NULL DEFAULT ('A'),          --工厂名称（ELCO-TJ, ELCO-QINGDAO 等等）
    [Description]   NVARCHAR (50)   NOT NULL DEFAULT ('A')           --描述, 经常为公司的全称。如: ELCO (TIANJIN) ELECTRONICS CORP. LTD.
);

--这是一个为了展开BOM而临时使用的一个表，其是多次循环调用本表查询而实现的。
--因为SQL server不支持递归存储过程调用时使用游标操作。（如果使用递归操作会被认为游标已经存在、重名了）
CREATE TABLE MFG_tmp_Bom_WholeTree(
    [ID]            INT IDENTITY (1, 1) NOT NULL,
    [PID]           INT                     NULL,                    --父级ID
    [ITEMLEVEL]     INT                     NULL,                    --展开层次
    [PONO]          NVARCHAR (10)           NULL,                    --位置号（行号）
    [SEQN]          NVARCHAR (10)           NULL,                    --序号（如:1,2,3 表示:同一位置可以同时就机种料号存在,可以从有效期来判断其有效性）
    [OPNO]          NVARCHAR (10)           NULL,                    --10: MAIN PART; 20: COST PART （工序号）
    [CPHA]          NVARCHAR (10)           NULL,                    --1: TRUE; 2: FALSE （phantom标志）
    [ITEM]          NVARCHAR (50)           NULL,                    --料号
    [DSCA]          NVARCHAR (90)           NULL,                    --描述
    [QANA]          NUMERIC  (18,4)         NULL,                    --数量（用量）
    [PROCESSFLAG]   NVARCHAR (50)           NULL,                    --处理标志（藉由此列作为是否处理完毕的标识）
    [SESSIONFLAG]   VARCHAR  (50)           NULL                     --多用户同时处理的用户标识
);

--用以记录各种序号的序列值
CREATE TABLE MES_SerialNoPool(
    [SerialName]   VARCHAR  (50)        NOT NULL,                    --序列号名称
    [SerialPrefix] VARCHAR  (5)         NOT NULL,                    --序列号前缀
    [SerialNo]     NUMERIC  (18,0)      NOT NULL DEFAULT 0,          --最后一次的获取序列值  
    [ModifyTime]   DATETIME             NOT NULL DEFAULT GETDATE()   --最后一次的获取时间
);

GO

--存储过程定义------------开始----------------------
--用以获得序列号值, 如果当下要取得的序列不存在, 则新建立一个, 其值从1开始, 并且前导8个'0'值
--一般说来, 加入前导字符后, 整体序列号码不要超出12位长度.
CREATE PROCEDURE [dbo].[usp_Mes_getNewSerialNo]
    @SerialName     VARCHAR(50)  = '',  --序列号的系列名称,
    @SerialPrefix   VARCHAR(5)   = '',  --序列号的前导字符.一般情况, 建议三位字符串作为前导符.
    @SerialLength   INT          = 12   --序列号总体长度, 即已经包含最终序列号长度中的前导长度.最大不允许超过12位长度
AS
    IF @SerialLength > 12 
    BEGIN
        SET @SerialLength  = 12;
    END
    --判断序列号以及对应的前缀是否已经定义.
    IF 0 = ( SELECT COUNT(1)
             FROM MES_SerialNoPool
             WHERE
                 SerialName   = @SerialName
             AND SerialPrefix = @SerialPrefix )
    BEGIN
        --新增一个独立前缀的系列号
        INSERT INTO MES_SerialNoPool (SerialName,  SerialPrefix, SerialNo)
                              VALUES(@SerialName, @SerialPrefix, 0);
    END

    --更新缓冲池的数据, 新增一个序列号值
    UPDATE MES_SerialNoPool
        SET SerialNo   = SerialNo + 1
           ,ModifyTime = GetDate()
    WHERE
            SerialName   = @SerialName
        AND SerialPrefix = @SerialPrefix;

    --返回新的序列号
    SELECT
        Upper(@SerialPrefix) + Right('00000000000' + Convert(VARCHAR, SerialNo), @SerialLength - LEN(@SerialPrefix)) AS SerialNo
    FROM MES_SerialNoPool
    WHERE
            SerialName   = @SerialName
        AND SerialPrefix = @SerialPrefix;
GO

--用以添加某种货号(产品,半成品)的物料在某个工位的使用数量的记录实现.
--其它数据项目不进行调整.
CREATE PROCEDURE usp_Mfg_insert_MUB_Records
    @Factory    VARCHAR(15)     =  '',  --工厂编号
    @WorkGroup  VARCHAR(15)     =  '',  --车间编号
    @MItem      NVARCHAR(50)    = N'',  --货号(主料号)
    @WHCode     VARCHAR(15)     =  '',  --库房编号
    @LineCode   VARCHAR(15)     =  '',  --产线编号
    @StationNo  VARCHAR(15)     =  '',  --工位编号
    @RountCode  VARCHAR(10)     =  '',  --工程编码
    @SItem      NVARCHAR(50)    = N'',  --工位消耗料的料号
    @Qty        NUMERIC(18, 4)  =   0,  --消耗数量
    @CreateUser NVARCHAR(50)    = N'',  --创建人
    @ModifyUser NVARCHAR(50)    = N''   --变更人
AS
    INSERT INTO MFG_Station_MTL_UseBase ( Factory, WorkGroup, MItem, WHCode, LineCode, StationNo, RountCode, SItem, Qty, CreateUser, ModifyUser, CreateTime, ModifyTime, Status)
                                  VALUES(@Factory,@WorkGroup,@MItem,@WHCode,@LineCode,@StationNo,@RountCode,@SItem,@Qty,@CreateUser,@ModifyUser, GETDATE(),  GETDATE(),  N'0')
GO

--用以删除某种货号(产品,半成品)的物料在某个工位的使用数量的记录.
--其它数据项目不进行调整.
CREATE PROCEDURE usp_Mfg_delete_MUB_Records
    @Factory    VARCHAR(15)     =  '',  --工厂编号
    @WorkGroup  VARCHAR(15)     =  '',  --车间编号
    @MItem      NVARCHAR(50)    = N'',  --货号(主料号)
    @WHCode     VARCHAR(15)     =  '',  --库房编号
    @LineCode   VARCHAR(15)     =  '',  --产线编号
    @StationNo  VARCHAR(15)     =  '',  --工位编号
    @RountCode  VARCHAR(10)     =  '',  --工程编码
    @SItem      NVARCHAR(50)    = N'',  --工位消耗料的料号
    @Qty        NUMERIC(18, 4)  =   0   --消耗数量
AS
    DELETE 
    FROM 
    MFG_Station_MTL_UseBase 
    WHERE 
            Factory  = @Factory  
        and WorkGroup= @WorkGroup
        and MItem    = @MItem    
     -- and WHCode   = @WHCode   
        and LineCode = @LineCode 
        and StationNo= @StationNo
     -- and RountCode= @RountCode
        and SItem    = @SItem    
        and Qty      = @Qty      
GO

--用以完成把库房库存数据进行手动调整的数据记录实现.
--此存储过程仅仅调整的OnHand项目数据.
--其它数据项目不进行调整.
CREATE PROCEDURE usp_Mfg_insert_MCC_Records
    @Factory    VARCHAR(15)     =  '',  --工厂编号
    @WorkGroup  VARCHAR(15)     =  '',  --车间编号
    @LineCode   VARCHAR(15)     =  '',  --产线编号
    @WHCode     VARCHAR(15)     =  '',  --库房编号
    @OrderNo    VARCHAR(50)     =  '',  --单子编号
    @PONO       NUMERIC(6,0)    =   0,  --行号位置
    @Item       NVARCHAR(50)    = N'',  --料号
    @AdvanceQty NUMERIC(18, 4)  =   0,  --变更后的在线数量(期望在线数量)
    @CreateUser NVARCHAR(50)    = N''   --变更人
AS
    IF (SELECT COUNT(1) FROM [dbo].[MFG_CC_Task_Head] WHERE TransferOrder = @OrderNo)=0
    BEGIN
        INSERT INTO MFG_CC_Task_Head(Factory,  WorkGroup,  WHCode,   LineCode, TransferOrder, CreateUser, Status)
                             Values(@Factory, @WorkGroup, @LineCode,@LineCode,@OrderNo,      @CreateUser, '2');
    END
    INSERT INTO MFG_CC_Task_Detail(TransferOrder, PONO, ITEM, OnhandQty, BlockQty, OrderQty, AllocateQty, AdvanceQty, CreateUser,  ModifyUser, Status)
                           SELECT @OrderNo      ,@PONO,@Item, OnhandQty, BlockQty, OrderQty, AllocateQty,@AdvanceQty,@CreateUser, @CreateUser, '2'
                           From Mfg_Inv_Data
                           WHERE
                                Factory   = @Factory
                            AND WorkGroup = @WorkGroup
                            AND WHCode    = @WHCode
                            AND ITEM      = @Item;
    UPDATE MFG_Inv_Data
    SET
        OnHandQty = @AdvanceQty
    WHERE
            Factory   = @Factory
        AND WorkGroup = @WorkGroup
        AND WHCode    = @WHCode
        AND ITEM      = @Item
GO

--取得某货号的尚未分配(产品耗料模块中的分配操作)的料号清单
CREATE PROCEDURE [dbo].[usp_Mfg_getMubMainBomList]
    @Factory   VARCHAR(15)  = '',       --工厂编号
    @WorkGroup VARCHAR(15)  = '',       --车间编号
    @LineCode  VARCHAR(15)  = '',       --产线编号
    @MainItem  NVARCHAR(50) = N''       --父料号(货号)
AS

    --IF OBJECT_ID('tempdb..#tmp_bom') is not null
    --drop table #tmp_bom
    CREATE TABLE #tmp_bom (
        [ITEM]          NVARCHAR (50)      NULL,
        [DSCA]          NVARCHAR (90)      NULL,
        [QANA]          NUMERIC  (18,4)    NULL
    )

    --IF OBJECT_ID('tempdb..#tmp_mub') is not null
    --drop table #tmp_mub
    CREATE TABLE #tmp_mub (
        StationNo VARCHAR(15),
        SItem NVARCHAR(50),
        Qty   NUMERIC(18,4),
        Desca NVARCHAR(90),
        StationNoName NVARCHAR(50),
        CrTime DateTime
    )

    --获取父料号(货号)的子料号清单, 插入到临时表中
    insert into #tmp_bom(ITEM, DSCA, QANA) exec [usp_Mfg_getBomUsingItemList] @MainItem

    --获取已经分配完成的料号清单
    insert into #tmp_mub(StationNo, SItem, Qty, Desca, StationNoName, CrTime) exec [usp_Mfg_getMUBSelectedList]  @Factory, @WorkGroup, @LineCode, @MainItem

    --获取尚未完成分配的料号,这里的分配是否完成时通过判定待分配数量和已经分配的数量来进行判定的.
    --如此复杂的操作盘点是考虑到: 相同的料号有可能被分配到多个工位, 要完成总体数量被分配到多处.
    select bom.*, ( bom.QANA - isnull(mub.Qty, 0)) as LeftTotal
    from #tmp_bom bom
    left join
    (
        select SItem, sum(Qty) as Qty
        from #tmp_mub
        group by SItem
    ) as mub
    on mub.SItem = bom.Item
    where
    ( bom.QANA-isnull(mub.Qty, 0)) > 0

    drop table #tmp_bom
    drop table #tmp_mub
GO

--取得(产品耗料模块)的已经配好的清单 (MUB)
CREATE PROCEDURE [dbo].[usp_Mfg_getMubSelectedList]
    @Factory   VARCHAR(15)  = '',       --工厂编号
    @WorkGroup VARCHAR(15)  = '',       --车间编号
    @LineCode  VARCHAR(15)  = '',       --产线编号
    @MainItem  NVARCHAR(50) = N''       --父料号(货号)
AS
   select
       mub.StationNo,
       mub.SItem,
       mub.Qty,
       baan.DSCA as Desca,
       sta.StationNoName,
       mub.CreateTime CrTime
   from
        MFG_Station_MTL_Usebase mub
       ,MFG_StationNoOrders     sta
       ,Baan_Item               baan
   where
           mub.SITEM     = baan.ITEM
       and mub.StationNo = sta.StationNo
       and mub.lineCode  = sta.LineCode
       and mub.Factory   = sta.Factory
       and mub.WorkGroup = sta.WorkGroup
       and mub.Factory   = @Factory
       and mub.WorkGroup = @WorkGroup
       and mub.LineCode  = @LineCode
       and mub.MItem     = @MainItem
    ORDER BY mub.StationNo, mub.SItem, mub.Qty
GO


--此存储过程目前在项目中没有被使用, 其只是一个试验验证程序, 用以验证从BaaN系统中取数是否和实际正确与否.
--BOM整体展开清单，一直展到叶节点为止。
CREATE PROCEDURE [dbo].[usp_Mfg_getBomWholeTree]
    @ParentItem nvarchar(50) = '',      --父料号
    @ItemLevel  int          = 0        --设计初衷: 展开到的层次, 目前此参数未使用.
AS
    DECLARE @Item        NVARCHAR(50)
    DECLARE @DSCA        NVARCHAR(90)
    DECLARE @PONO        NVARCHAR(10)
    DECLARE @QANA        NUMERIC(18,4)
    DECLARE @processFlag NVARCHAR(50)
    DECLARE @SessionFlag VARCHAR(50)

    DECLARE @OPNO        INT
    DECLARE @CPHA        INT

    DECLARE @ParentId    int
    DECLARE @RowCount    int

    SELECT @SessionFlag = convert(varchar(50), 
      datepart(y, getdate()) * 1000000  
    + datepart(hh, getdate()) * 24 *10000 
    + datepart(mi, getdate()) * 100  
    + datepart(ss, getdate()))

    SELECT  @ParentId = 0, @processFlag = N'1'

    while(@processflag <> N'')
    BEGIN
        insert into MFG_tmp_Bom_WholeTree (PID,       ITEMLEVEL,      PONO,      SEQN,      OPNO,      CPHA,      ITEM,      DSCA,        QANA,      PROCESSFLAG,        SESSIONFLAG)
             SELECT                        @ParentId, @ItemLevel, pp.[PONO], pp.[SEQN], pp.[OPNO], pp.[CPHA], pp.[SITM], pp.[SDESC],  pp.[QANA], isnull(cc.[MITM],N''), @SessionFlag
             FROM [Baan_BOM] pp
             LEFT JOIN (select distinct mitm from [Baan_BOM]) cc  ON pp.SITM = cc.MITM
             WHERE
                    pp.MITM=@ParentItem 
                and pp.OPNO = N'10'
                and getdate() between pp.INDT and pp.EXDT
             ORDER BY PONO

        if (@ParentId<>0)
        BEGIN
           UPDATE MFG_tmp_Bom_WholeTree set processflag = '' where id = @ParentId and sessionflag = @SessionFlag
        END

        select @RowCount=COUNT(1)
        from MFG_tmp_Bom_WholeTree
        where
            processflag <> N''
        and sessionflag = @SessionFlag

        if (@RowCount > 0)
        BEGIN
            select top 1
                @ParentId    = id,
                @ItemLevel   = itemlevel + 1,
                @ParentItem  = item,
                @processFlag = isnull(processflag, '')
            from 
                MFG_tmp_Bom_WholeTree
            where
                processflag <> N''
            and sessionflag = @SessionFlag
            END
        ELSE
        BEGIN
            select @processFlag = N''
        END
    END

    SELECT *
    from
        MFG_tmp_Bom_WholeTree
    where
        sessionflag = @SessionFlag
    order by
        pid, itemlevel, pono

GO


--展开产品用料清单, 此值仅仅和BOM相关，其和工单无关.
CREATE PROCEDURE [dbo].[usp_Mfg_getBomUsingItemList]
    @ParentItem nvarchar(50) = '',      --父料号
    @ItemLevel  int          = 0        --设计初衷: 展开到的层次, 目前此参数未使用.
AS

    --当下，把这些真正展开BOM（考虑到有phantom的存在而需要逐级展开）的代码给屏蔽掉，
    --目的是为了起初实施时，暂时不考虑phantom料（据说，传感器车间没有这种情况）
    --这样可以迅速的提高系统查询速度，给用户的感觉是爽爽的。

    /*
    DECLARE @Item        NVARCHAR(50)
    DECLARE @DSCA        NVARCHAR(90)
    DECLARE @PONO        NVARCHAR(10)
    DECLARE @QANA        NUMERIC(18,4)
    DECLARE @processFlag NVARCHAR(50)
    DECLARE @SessionFlag VARCHAR(50)

    DECLARE @OPNO        NVARCHAR(10)
    DECLARE @CPHA        NVARCHAR(10)

    DECLARE @ParentId    int
    DECLARE @RowCount    int

    SELECT @SessionFlag =  convert(varchar(50), datepart(y, getdate())*1000000  + datepart(hh, getdate()) * 24 *10000 + datepart(mi, getdate())*100  + datepart(ss, getdate()))

    SELECT  @ParentId = 0, @processFlag=N'1'

    while(@processflag <> N'')
    BEGIN
    insert into MFG_tmp_Bom_WholeTree (PID,       ITEMLEVEL,  PONO,      SEQN,      OPNO,      CPHA,      ITEM,      DSCA,        QANA,      PROCESSFLAG,           SESSIONFLAG)
         SELECT                    @ParentId, @ItemLevel, pp.[PONO], pp.[SEQN], pp.[OPNO], pp.[CPHA], pp.[SITM], pp.[SDESC],  pp.[QANA], isnull(cc.[MITM],N''), @SessionFlag
         FROM [Baan_BOM] pp
         LEFT JOIN (select distinct mitm from [Baan_BOM]) cc
            ON pp.SITM = cc.MITM
         WHERE pp.MITM=@ParentItem and pp.OPNO = N'10' and getdate() between pp.INDT and pp.EXDT
         ORDER BY PONO

         if (@ParentId<>0)
         BEGIN
            UPDATE MFG_tmp_Bom_WholeTree set processflag = '' where id = @ParentId and sessionflag = @SessionFlag
         END

         select @RowCount=sum(1)
         from MFG_tmp_Bom_WholeTree
         where
             processflag <> N''
         and sessionflag = @SessionFlag
         and CPHA = N'1'
         and OPNO = N'10'

         if (@RowCount > 0)
            BEGIN
             select top 1
                 @ParentId    = id,
                 @ItemLevel   = itemlevel + 1,
                 @ParentItem  = item,
                 @processFlag = isnull(processflag, '')
             from MFG_tmp_Bom_WholeTree
             where
                 processflag <> N''
             and sessionflag = @SessionFlag
             and CPHA = N'1'
             and OPNO = N'10'
            END
         ELSE
            BEGIN
             select @processFlag = N''
            END
    END

    SELECT
        ITEM, DSCA, SUM(QANA) AS QANA
    FROM MFG_tmp_Bom_WholeTree
    WHERE
             sessionflag = @SessionFlag
         AND CPHA=N'2'
         AND OPNO='10'
    GROUP BY ITEM, DSCA
    ORDER BY ITEM
    */

    --这个处理小程序段是为了提高速度而临时启用的, 其具体效果需要经过实施后进行验证
    SELECT
         SITM ITEM
        ,SDESC DSCA
        ,SUM(QANA) AS QANA
    FROM BAAN_BOM
    WHERE
            MITM = @ParentItem
        AND OPNO = '10'   --这里的"10"代表BaaN系统的"工序", 当下展开的用料, 当下MES仅仅考虑使用此工序的料
        AND GETDATE() BETWEEN INDT AND EXDT
    GROUP BY SITM, SDESC

GO

--用户录入的工单或者批号模糊匹配查询得出其用料清单（包含折算后的数量）
--此存储过程中的TTISFC001100对应于PP_ScheduleForOrder(流程控制模块的手工上传Excel文件内容表)
CREATE PROCEDURE [dbo].[usp_Mfg_getXNumberEstimateMTL]
    @xNumber as nvarchar(50) = ''       --批号或者工单号, 系统如果根据录入的长度判断为批号, 则只对比输入的数据的前9个字符, 后面的字符不考虑
AS
    select
         ICST.PDNO
        ,ISFC.MITM MITM
        ,ISFC.QRDR MOrderQty
        ,ICST.QUES SOrderQty
        ,PPLOT.LOT
        ,PPLot.InQty LotQty
        ,ICST.PONO, ICST.SITM
        ,ICST.DSCA
        ,FORMAT(CONVERT(NUMERIC(18,4), ICST.QUES)/ISFC.QRDR * PPLOT.InQty, '0.0000') LotItemQty
    from
         [dbo].[PP_Lot] PPLot
        ,[dbo].[Baan_TTICST001100] ICST
        ,[dbo].[Baan_TTISFC001100] ISFC
    where
        (  PPLot.OrderNo      = @xNumber
        or LEFT(PPLot.Lot, 9) = LEFT(@xNumber,  9)
        )
        and PPLot.OrderNo = ICST.PDNO
        and PPLOT.OrderNo = ISFC.PDNO
        and ICST.OPNO     = '10'  --这里的"10"代表BaaN系统的"工序", 当下展开的用料, 当下MES仅仅考虑使用此工序的料
        and ICST.BFLS     = 1
GO

--精确查找到依据批次而得出的用料清单，目的是依据此结果作为计划发料单。
--此存储过程中的TTISFC001100对应于PP_ScheduleForOrder(流程控制模块的手工上传Excel文件内容表)
CREATE PROCEDURE [dbo].[usp_Mfg_getLotEstimateMTL]
    @LotNumber as nvarchar(50) = ''     --批次号码
AS
    select
        PPLOT.LOT, ICST.SITM, ICST.DSCA, FORMAT(CONVERT(NUMERIC(18,4), ICST.QUES)/ISFC.QRDR * PPLOT.InQty, '0.0000') Qty
    from
        [dbo].[PP_Lot] PPLot
       ,[dbo].[Baan_TTICST001100] ICST
       ,[dbo].[Baan_TTISFC001100] ISFC
    where
            PPLot.Lot     = @LotNumber
        and PPLot.OrderNo = ICST.PDNO
        and PPLot.OrderNo = ISFC.PDNO
        and ICST.OPNO     = '10'  --这里的"10"代表BaaN系统的"工序", 当下展开的用料, 当下MES仅仅考虑使用此工序的料
    --  and ICST.BFLS     = 1     --"反冲"标志, BlackFlush, 一般认为, 只有此标志值的料是需要管控的.
                                  --注意:此处要和存储过程: usp_Mfg_insert_MFG_Push_Plan 保持一致, 一定要保证查询条件相同.
GO

--模糊查找并列出批次清单，目的是依据此结果准备制作计划发料单。
--此模块应用于"计划排产"模块
CREATE PROCEDURE [dbo].[usp_Mfg_getLotOrderList]
   @OrderValue as nvarchar(50) = ''     --批号或者工单号, 系统如果根据录入的长度判断为批号, 则只对比输入的数据的前9个字符, 后面的字符不考虑
                                        --如果用户录入的数据为空, 则系统根据PP_Lot记录的计划生产日期的最近30天数据全部列出
AS
    SELECT
        PPLot.Lot,
        PPLot.OrderNo,
        PPLot.GoodsCode,
     -- ISNULL(ISFC.MITM,'--') GoodsCode, --为了解决PPLot里面存储的GoodsCode长度不足问题.
        PPLot.ModelCode,
        PPLot.InQty,
        FORMAT(PPLot.ProDate,  'yyyy-MM-dd') ProDate,
        FORMAT(PPLot.BPro_Date,'yyyy-MM-dd') BPro_Date,
        PPLot.OtherIssue,
        (SELECT KeyTip
        FROM Mfg_ConstKeyLists
        WHERE
               KeyType  = 'MTL_ORHD'
           AND KeyName  = 'Status'
           AND KeyValue = ISNULL(PPlan.Status, '')
        ) AS StatusTip,
        ISNULL(PPlan.Status, '') StatusValue,
        ISNULL(LCO.LineCodeName, '') LineName
    FROM [PP_Lot] PPLot
    LEFT JOIN MFG_Push_Plan_Head PPlan ON PPlan.TransferOrder = PPLot.Lot
    LEFT JOIN MFG_LineCodeOrders LCO   ON LCO.LineCode        = PPlan.LineCode
  --LEFT JOIN Baan_TTISFC001100  ISFC  ON ISFC.PDNO           = PPLot.OrderNo
    WHERE
    (     @OrderValue <> ''
      AND (PPLot.OrderNo = @OrderValue OR LEFT(PPLot.Lot, 9) = LEFT(@OrderValue, 9))
    )
    OR (@OrderValue = '' AND PPLot.BPro_Date > GETDATE() - 30)
    ORDER BY Lot
GO

--模糊查找发料单的头表信息列表，目的是准备依据此结果查找或制作计划发料单。
CREATE PROCEDURE [dbo].[usp_Mfg_getMTLPlanHeads]
  @Factory      AS VARCHAR(15)          --工厂编号
 ,@WorkGroup    AS VARCHAR(15)          --车间编号
 ,@LineCode     AS VARCHAR(15)          --产线编号
 ,@OrderValue   AS NVARCHAR(50) = ''    --批号或者工单号, 系统如果根据录入的长度判断为批号, 则只对比输入的数据的前9个字符, 后面的字符不考虑
                                        --如果用户录入的数据为空, 则系统根据PP_Lot记录的计划生产日期的最近60天数据全部列出
AS
    SELECT
       PPlan.TransferOrder,
       PPlan.ModelCode,
       BItem.DSCA ModelName,
       PPlan.Qty,
       FORMAT(PPlan.PlanDate, 'yyyy-MM-dd') PlanDate,
       PPlan.CreateTime,
       PPlan.CreateUser,
       PPlan.ModifyTime,
       PPlan.ModifyUser,
       (SELECT KeyTip
       FROM Mfg_ConstKeyLists
       WHERE
           KeyType = 'MTL_ORHD'
       AND KeyName = 'Status'
       AND KeyValue= ISNULL(PPlan.Status, '')
       ) AS StatusTip,
       ISNULL(PPlan.Status, '') StatusValue
    FROM
        MFG_Push_Plan_Head PPlan
    LEFT JOIN BaaN_Item BItem ON PPlan.ModelCode = BItem.Item
    WHERE
        (   ( @OrderValue <> '' AND ( PPlan.TransferOrder = @OrderValue OR LEFT(PPlan.TransferOrder, 9) = LEFT(@OrderValue, 9)))
          OR( @OrderValue  = '' AND PPlan.CreateTime > GETDATE() - 60)
        )
        AND PPlan.Factory   = @Factory
        AND PPlan.WorkGroup = @WorkGroup
        AND PPlan.LineCode  = @LineCode
    ORDER BY TransferOrder
GO

--精确找到发料单的头部信息。
CREATE PROCEDURE [dbo].[usp_Mfg_getMTLPlanHead]
    @OrderValue   AS NVARCHAR(50) = ''  --发料单号
AS
    SELECT
       ph.* ,
       fc.FactoryName,
       wg.WorkGroupName,
       lc.LineCodeName,
       (SELECT KeyTip
       FROM Mfg_ConstKeyLists
       WHERE
           KeyType = 'MTL_ORHD'
       AND KeyName = 'Status'
       AND KeyValue= ISNULL(ph.Status, '')
       ) AS StatusTip,
       ISNULL(ph.Status, '') StatusValue
    FROM
       MFG_Push_Plan_Head ph,
       MFG_WorkGroups wg,
       MFG_Factorys fc,
       MFG_LineCodeOrders lc
    where
           ph.Factory       = fc.Factory
       and ph.WorkGroup     = wg.WorkGroup
       and ph.LineCode      = lc.LineCode
       and ph.TransferOrder = @OrderValue
GO

--获得详细的发料单的详细物料信息。
CREATE PROCEDURE [dbo].[usp_Mfg_getMTLPlanDetail]
     @Factory      AS VARCHAR(15)       --工厂编号
    ,@WorkGroup    AS VARCHAR(15)       --车间编号
    ,@LineCode     AS VARCHAR(15)       --产线编号
    ,@OrderValue   AS NVARCHAR(50) = '' --发料单号
 AS
    SELECT
       PPlan.TransferOrder,
       PPlan.PONO,
       PPlan.ITEM,
       BItem.DSCA,
       PPlan.PlanQty,
       PPlan.OffsetQty,
       PPlan.PushedQty,
       PPlan.CreateTime,
       PPlan.CreateUser,
       PPlan.ModifyTime,
       PPlan.ModifyUser,
       (SELECT KeyTip
       FROM Mfg_ConstKeyLists
       WHERE
           KeyType = 'MTL_ORLN'
       AND KeyName = 'Status'
       AND KeyValue= ISNULL(PPlan.Status, '')
       ) AS StatusTip,
       ISNULL(PPlan.Status, '') StatusValue
    FROM
        MFG_Push_Plan_Detail PPlan
     LEFT JOIN BaaN_Item BItem ON PPlan.ITEM = BItem.Item
    WHERE
           PPlan.TransferOrder = @OrderValue
       AND PPlan.Factory   = @Factory
       AND PPlan.WorkGroup = @WorkGroup
       AND PPlan.LineCode  = @LineCode
    ORDER BY PONO
GO

--获得详细的生产线待收货信息。
CREATE PROCEDURE [dbo].[usp_Mfg_getWIPRecMTLDetail]
     @Factory      AS VARCHAR(15)       --工厂编号
    ,@WorkGroup    AS VARCHAR(15)       --车间编号
    ,@LineCode     AS VARCHAR(15)       --产线编号
    ,@OrderValue   AS NVARCHAR(50) = '' --发料单号
AS
    SELECT
       INVT.TransferOrder,
       INVT.ID TABLEID,
       INVT.PONO,
       INVT.ORIDCK,
       INVT.ITEM,
       BItem.DSCA,
       INVT.QTY,
       (SELECT KeyTip
       FROM Mfg_ConstKeyLists
       WHERE
           KeyType = 'MTL_RECV'
       AND KeyName = 'Status'
       AND KeyValue= ISNULL(INVT.Status, '')
       ) AS StatusTip,
       ISNULL(INVT.Status, '') StatusValue
    FROM [dbo].[MFG_Inv_Trans_To] INVT
    LEFT JOIN BaaN_Item BItem ON INVT.ITEM = BItem.Item
    WHERE
           INVT.TransferOrder = @OrderValue
       AND INVT.Factory   = @Factory
       AND INVT.WorkGroup = @WorkGroup
       AND INVT.WHCode    = @LineCode
    ORDER BY PONO, INVT.ID
GO
--手动调整发料计划条目信息, 更新MFG_Push_Plan_Detail条目数据:
--操作动作包括: ADD, UPDATE, DELETE
--其操作之前需要检验单子的状态.
CREATE PROCEDURE [dbo].[usp_Mfg_maintain_Push_Plan_Item]
     @Action       AS VARCHAR(50)           --操作类型: ADD_PUSH_PLAN_ITEM, UPD_PUSH_PLAN_ITEM, DEL_PUSH_PLAN_ITEM
    ,@Factory      AS VARCHAR(15)           --工厂编号
    ,@WorkGroup    AS VARCHAR(15)           --车间编号
    ,@LineCode     AS VARCHAR(15)           --产线编号
    ,@ModifyUser   AS NVARCHAR(50)          --用户
    ,@OrderValue   AS NVARCHAR(50)          --发料单号
    ,@Item         AS VARCHAR(50)           --料号
    ,@PlanQty      AS NUMERIC(18,4)         --数量
    ,@CatchError   AS INT           OUTPUT  --系统判断用户操作异常的次数
    ,@RtnMsg       AS NVARCHAR(100) OUTPUT  --返回状态
AS
    set @CatchError = 0
    set @RtnMsg     = 'OK'

    DECLARE @OrderStatus     AS VARCHAR(15)
    DECLARE @nRowCount       AS INTEGER
    DECLARE @NewPONO         AS INTEGER

    IF      'ADD_PUSH_PLAN_ITEM' <> @Action 
        AND 'UPD_PUSH_PLAN_ITEM' <> @Action
        AND 'DEL_PUSH_PLAN_ITEM' <> @Action
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '系统不认识您当下要进行的操作!'
        RETURN
    END

    SELECT 
         @nRowCount   = COUNT(1)
        ,@OrderStatus = ISNULL(MAX(Status), '')
    FROM MFG_Push_Plan_Head
    WHERE TransferOrder = @OrderValue

    IF @nRowCount=0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '在全部发料计划清单中，未能找到单子号: "' + @OrderValue + '"!'
        RETURN
    END

    if @OrderStatus<>0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '发料计划单: "' + @OrderValue + '", 当前为不可编辑状态.'
        RETURN
    END


    SELECT 
         @nRowCount   = COUNT(1)
        ,@OrderStatus = ISNULL(MAX(Status), '')
    FROM [MFG_Push_Plan_Detail]       
    WHERE
            Factory       = @Factory
        AND WorkGroup     = @WorkGroup
        AND LineCode      = @LineCode
        AND TransferOrder = @OrderValue
        AND ITEM          = @Item

    IF @Action = 'ADD_PUSH_PLAN_ITEM'
    BEGIN
        IF @nRowCount > 0
        BEGIN
            SET @CatchError = @CatchError + 1
            SET @RtnMsg     = '在计划发料单中已经存在将要新增的料: "' + @Item + '"，请确认!'
            RETURN
        END
    END

    --编辑和删除操作, 其都要判断当下要操作的料是否存在, 和是否处于可以编辑的状态, 因此放在一起进行一次性判断
    IF @Action = 'UPD_PUSH_PLAN_ITEM' or @Action = 'DEL_PUSH_PLAN_ITEM'
    BEGIN 
        IF @nRowCount = 0
        BEGIN
            SET @CatchError = @CatchError + 1
            SET @RtnMsg     = '在计划发料单中没有找到料: "' + @Item + '"，请确认!'
            RETURN
        END

        IF @OrderStatus <> '0'
        BEGIN
            SET @CatchError = @CatchError + 1
            SET @RtnMsg     = '在计划发料单中的料: "' + @Item + '", 当前为不可编辑状态!'
            RETURN
        END
    END

  --前面所有的判断均通过, 开始执行数据库操作
    BEGIN TRANSACTION

        IF @Action = 'ADD_PUSH_PLAN_ITEM' 
        BEGIN        
            SELECT
                 @NewPONO = ISNULL(MAX(PONO), 0) + 10
            FROM [MFG_Push_Plan_Detail]       
            WHERE
                    Factory       = @Factory
                AND WorkGroup     = @WorkGroup
                AND LineCode      = @LineCode
                AND TransferOrder = @OrderValue

            INSERT INTO MFG_Push_Plan_Detail(Factory,  WorkGroup,  LineCode,  TransferOrder,  PONO,     Item,  PlanQty, OffsetQty, PushedQty, CreateUser, ModifyUser, Status)
                                     Values(@Factory, @WorkGroup, @LineCode, @OrderValue,    @NewPONO, @Item, @PlanQty, 0,         0,        @ModifyUser,@ModifyUser, 0);

        END

    IF @Action = 'UPD_PUSH_PLAN_ITEM' 
    BEGIN
        UPDATE MFG_Push_Plan_Detail
        SET
                PlanQty    = @PlanQty
              , ModifyTime = GETDATE()
              , ModifyUser = @ModifyUser
        WHERE
              Factory       = @Factory
          AND WorkGroup     = @WorkGroup
          AND LineCode      = @LineCode
          AND TransferOrder = @OrderValue
          AND ITEM          = @Item
          AND ( Status = '0' )  --此处的状态判断不可少, 因为要更新数量
    END

    IF @Action = 'DEL_PUSH_PLAN_ITEM'
    BEGIN
        DELETE FROM MFG_Push_Plan_Detail
        WHERE
              Factory       = @Factory
          AND WorkGroup     = @WorkGroup
          AND LineCode      = @LineCode
          AND TransferOrder = @OrderValue
          AND ITEM          = @Item
          AND ( Status = '0' )  --此处的状态判断不可少, 因为要更新数量
    END

    UPDATE MFG_Push_Plan_Head
    SET
         ModifyTime = GETDATE()
        ,ModifyUser = @ModifyUser
    WHERE
            Factory       = @Factory
        AND WorkGroup     = @WorkGroup
        AND LineCode      = @LineCode
        AND TransferOrder = @OrderValue


    COMMIT TRANSACTION

   RETURN
GO

--Mfg_Insert系列(用以库转操作)存储过程之一: 计划
--创建计划发料内容, 包括生成表头信息和表体信息
CREATE PROCEDURE  [dbo].[usp_Mfg_insert_MFG_Push_Plan]
     @Factory      AS VARCHAR(15)          --工厂编号
    ,@WorkGroup    AS VARCHAR(15)          --车间编号
    ,@LineCode     AS VARCHAR(15)          --产线编号
    ,@LotNumber    AS NVARCHAR(50)         --批次号, 发料单号
    ,@CreateUser   AS NVARCHAR(50)         --用户
    ,@PlanShift    AS VARCHAR(4)  = 'RS'   --计划班次
    ,@SalesOrder   AS VARCHAR(15) = ''     --销售订单
    ,@CatchError   AS INT           OUTPUT --系统判断用户操作异常的数量
    ,@RtnMsg       AS NVARCHAR(100) OUTPUT --返回状态
AS
    set @CatchError = 0
    set @RtnMsg     = ''
    IF (SELECT COUNT(1) FROM MFG_Push_Plan_Head WHERE TransferOrder=@LotNumber) > 0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '在计划发料单中已经发现有此批号：' + @LotNumber + '!'
        RETURN
    END

    INSERT INTO MFG_Push_Plan_Head
           (Factory,  WorkGroup,  LineCode,  transferOrder, PlanDate, PlanShift, ModelCode, ModelName, Qty,   SalesOrder,  LOT,       CreateUser,  ModifyUser,  Status)
    SELECT @Factory, @WorkGroup, @LineCode, @LotNumber,     ProDate, @PlanShift, GoodsCode, ModelCode, InQty, @SalesOrder, @LotNumber,@CreateUser, @CreateUser, '0'
    FROM
        [dbo].[PP_Lot] PPLot
    WHERE
        PPLot.Lot = @LotNumber

    IF (SELECT COUNT(1) FROM MFG_Push_Plan_Detail WHERE TransferOrder=@LotNumber) > 0
    BEGIN
        DELETE FROM MFG_Push_Plan_Detail WHERE TransferOrder=@LotNumber
    END

    INSERT INTO MFG_Push_Plan_Detail
           ( Factory,  WorkGroup,  LineCode,  transferOrder, PONO,      ITEM,      PlanQty,                                                    OffsetQty, PushedQty,  CreateUser,  ModifyUser,  Status)
    SELECT  @Factory, @WorkGroup, @LineCode, @LotNumber,     ICST.PONO, ICST.SITM, CONVERT(NUMERIC(18,4), ICST.QUES)/ISFC.QRDR * PPLOT.InQty , 0,         0,         @CreateUser, @CreateUser , '0'
    FROM
        [dbo].[PP_Lot] PPLot
       ,[dbo].[Baan_TTICST001100] ICST
       ,[dbo].[Baan_TTISFC001100] ISFC
    WHERE
        PPLot.Lot     = @LotNumber
    AND PPLot.OrderNo = ICST.PDNO
    AND PPLOT.OrderNo = ISFC.PDNO
    AND ICST.OPNO     = '10'
 -- AND ICST.BFLS     = 1           --注意:此处要和存储过程: usp_Mfg_getLotEstimateMTL 保持一致, 一定要保证查询条件相同.
    RETURN
GO

--Mfg_Insert系列(用以库转操作)存储过程之二: 发料
--插入发料记录，并更新MFG_Push_Plan_Head表头和MFG_Push_Plan_Detail表体状态信息
CREATE PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Issue]
     @Factory      AS VARCHAR(15)           --工厂编号
    ,@WorkGroup    AS VARCHAR(15)           --车间编号
    ,@LineCode     AS VARCHAR(15)           --产线编号
    ,@CreateUser   AS NVARCHAR(50)          --用户
    ,@OrderValue   AS NVARCHAR(50)          --发料单号
    ,@PackageNo    AS VARCHAR(50)           --物料包装号码
    ,@ScanItem     AS VARCHAR(50)           --扫入的发料料号
    ,@ScanQty      AS NUMERIC(18,4)         --扫入的发料数量
    ,@CatchError   AS INT           OUTPUT  --系统判断用户操作异常的次数
    ,@RtnMsg       AS NVARCHAR(100) OUTPUT  --返回状态
AS
    set @CatchError = 0
    set @RtnMsg     = 'OK'

    DECLARE @PackageItem     AS VARCHAR(50)
    DECLARE @PackageQty      AS NUMERIC(18, 4)
    DECLARE @PackageLeftQty  AS NUMERIC(18, 4)
    DECLARE @RequestQty      AS NUMERIC(18, 4)
    DECLARE @PlanQty         AS NUMERIC(18, 4)
    DECLARE @PlanPONO        AS NUMERIC(6,  0)
    DECLARE @OffsetQty       AS NUMERIC(18, 4)
    DECLARE @PushedQty       AS NUMERIC(18, 4)
    DECLARE @nRowCount       AS INTEGER

    DECLARE @OrderStatus     AS VARCHAR(15)

    SELECT @nRowCount   = COUNT(1)
         , @PackageItem = ISNULL(MAX(Item),   '')
         , @PackageQty  = ISNULL(SUM(RKAmount),0)
    FROM PD_Ware_RK
    WHERE ORIDCK = @PackageNo

    IF @nRowCount=0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '从线边库的原始包装清单中，未能找到此包装号：' + @PackageNo + '!'
        RETURN
    END

    IF UPPER(@PackageItem) <> UPPER(@ScanItem)
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '系统发现您录入的料号和原包装料号不一致：' + @ScanItem + '!'
        RETURN
    END

    --此处建议加入锁处理
    SELECT @nRowCount   = COUNT(1)
         , @PlanPONO    = ISNULL(MAX(PONO),       0)
         , @PackageItem = ISNULL(MAX(Item),      '')
         , @PlanQty     = ISNULL(SUM(PlanQty),    0)
         , @OffsetQty   = ISNULL(SUM(OffsetQty),  0)  --时间关系，没有充分对调整数量的进行考虑，此处写出来仅仅是为了方便日后使用
         , @PushedQty   = ISNULL(SUM(@PushedQty), 0)  --已发数量采用此处, 目的是有不同包装号, 完成一次发料单的需求
         , @RequestQty  = @PlanQty + @OffsetQty - @PushedQty
    FROM [MFG_Push_Plan_Detail]       --WITH (HOLDLOCK)
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND LineCode      = @LineCode
      AND TransferOrder = @OrderValue
      AND ITEM          = @ScanItem
      AND ( Status = '0' OR Status = 'S1' OR Status = 'S2')

    IF @nRowCount = 0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '计划发料单中没有找到您要发送的料，请确认是否已经备足数量了或者本单子根本不需要发送此料？'
        RETURN
    END
    ELSE
    BEGIN
        IF @RequestQty <= 0.0
        BEGIN
            SET @CatchError = @CatchError + 1
            SET @RtnMsg     = '请确认是否已经备足数量了，当下无需再备此料！'
            RETURN
        END
    END

    SELECT
         @PackageLeftQty = @PackageQty - ISNULL(SUM(Qty), 0)
    FROM [dbo].[MFG_Inv_Trans_From]  --WITH (HOLDLOCK)
    WHERE
          ORIDCK    = @PackageNo  --此处不可以限制的过死，因为有可能一个原包料被发送到多个去向
      AND Factory   = @Factory
      AND WorkGroup = @WorkGroup

    IF @PackageLeftQty < @ScanQty
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '包装数量剩余不足，您录入的数量已经大于剩余数量了!'
        RETURN
    END

 --执行数据库插入操作

    BEGIN TRANSACTION

    --此处在考虑是否可以用以保证只最后保留一条记录, 这样收料(拒收)时的就可以避免使用时间表示进行重复记录的标定
    --如果采用此种建议,那么也会带来发料过程中撤销(以及拒收同意)操作的数量限定问题.
    --如:发两次10 + 20 , 撤销一次25后,相当于两次数量混了,如果跟踪不严谨的,也无所谓了.
    --BaaN中是采用只有一条记录的实现方式, 但是其没有包装号, 因此逻辑上可以方便的实现.
    INSERT INTO MFG_Inv_Trans_From
           ( Factory,  WorkGroup,  WHCode,             ORIDCK,     transferOrder,  PONO,       ITEM,      QTY,      CreateUser,  Status, Operate)
    VALUES (@Factory, @WorkGroup, @LineCode + '-XBK', @PackageNo, @OrderValue,    @PlanPONO,  @ScanItem, @ScanQty, @CreateUser,  '3',    'XBK_2_WIP' )
    --此处发料详单表对于每一个料项, 没有过多的步骤(如再次确认之类的流程), 因此其状态都是记录完成.
    --因此其值与计划表的状态不一定一致

    UPDATE MFG_Push_Plan_Detail
    SET
            PushedQty  = PushedQty + @ScanQty
          , Status     = CASE
                            WHEN PushedQty + @ScanQty >= PlanQty + OffsetQty THEN 'S3'
                            ELSE 'S2'
                       END
    --    , ModifyTime = GETDATE()
    --    , ModifyUser = @CreateUser
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND LineCode      = @LineCode
      AND TransferOrder = @OrderValue
      AND ITEM          = @ScanItem
      AND ( Status = '0' OR Status = 'S1' OR Status = 'S2' )  --此处的S2状态不可少, 因为要更新数量

    --找出未备完料的种类数量
    SELECT @nRowCount = COUNT(1)
    FROM MFG_Push_Plan_Detail
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND LineCode      = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status = '0' OR Status = 'S1' OR Status = 'S2' )

    IF @nRowCount = 0
    BEGIN
        SET @OrderStatus = 'S3'
    END
    ELSE
    BEGIN
        SET @OrderStatus = 'S2'
    END

--此处加入对本单子全体物料的检查, 然后自动更新头表的记录状态.
--此处的客户端也进行了判断和给出客户的自动提示.
    UPDATE MFG_Push_Plan_Head
    SET
         Status =  @OrderStatus
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND LineCode      = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status = '0' OR Status = 'S1' OR Status = 'S2')


    COMMIT TRANSACTION

   RETURN
GO

--Mfg_Insert系列(用以库转操作)存储过程之三: 撤回
--删除发料记录，并更新MFG_Push_Plan_Head表头和MFG_Push_Plan_Detail表体状态信息
CREATE PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Revert]
    @Factory      AS VARCHAR(15)            --工厂编号
   ,@WorkGroup    AS VARCHAR(15)            --车间编号
   ,@LineCode     AS VARCHAR(15)            --产线编号
   ,@CreateUser   AS NVARCHAR(50)           --用户
   ,@OrderValue   AS NVARCHAR(50)           --发料单号
   ,@PackageNo    AS VARCHAR(50)            --物料包装号码
   ,@ScanItem     AS VARCHAR(50)            --扫入的发料料号
   ,@ScanQty      AS NUMERIC(18,4)          --扫入的发料数量
   ,@CatchError   AS INT           OUTPUT   --系统判断用户操作异常的次数
   ,@RtnMsg       AS NVARCHAR(100) OUTPUT   --返回状态
AS
    set @CatchError = 0
    set @RtnMsg     = 'OK'

    DECLARE @PackageItem     AS VARCHAR(50)
    DECLARE @PackageQty      AS NUMERIC(18, 4)
    DECLARE @PackageLeftQty  AS NUMERIC(18, 4)
    DECLARE @RequestQty      AS NUMERIC(18, 4)
    DECLARE @PlanQty         AS NUMERIC(18, 4)
    DECLARE @PlanPONO        AS NUMERIC(6,  0)
    DECLARE @OffsetQty       AS NUMERIC(18, 4)
    DECLARE @PushedQty       AS NUMERIC(18, 4)
    DECLARE @nRowCount       AS INTEGER
    DECLARE @OrderStatus     AS VARCHAR(15)

    DECLARE @MAXID           AS INTEGER

    SELECT @nRowCount   = COUNT(1)
         , @PackageItem = ISNULL(MAX(Item),   '')
         , @PackageQty  = ISNULL(SUM(RKAmount),0)
    FROM PD_Ware_RK
    WHERE ORIDCK = @PackageNo

    IF @nRowCount=0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '从线边库的原始包装清单中，未能找到此包装号：' + @PackageNo + '!'
        RETURN
    END

    IF UPPER(@PackageItem) <> UPPER(@ScanItem)
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '系统发现您录入的料号和原包装料号不一致：' + @ScanItem + '!'
        RETURN
    END

    --此处建议加入锁处理
    SELECT  @nRowCount   = COUNT(1)
           ,@MAXID       = MAX(ID)
    FROM [MFG_Inv_Trans_From]       --WITH (HOLDLOCK)
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND WHCode        = @LineCode + '-XBK'
      AND TransferOrder = @OrderValue
      AND ITEM          = @ScanItem
      AND ORIDCK        = @PackageNo
      AND QTY           = @ScanQty
      AND ( Status = '1' OR Status = '2' OR Status = '3')
      --此处还有优化的空间:
      --为了给用户最简操作, 我们可以只给用户留下一个"撤回"按钮, 当下家拒收的情况下, 我们也可以撤回
      --拒收撤回, 我们需要的是更改标记工作, 不要直接删除(目的是保留日志)
      --时间关系, 此处先不考虑此种拒收撤回情况

    IF @nRowCount = 0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '从已发送的清单中没有找到您要撤回的料!(提示:请核对撤回数量是否正确?)'
        RETURN
    END

 --执行数据库删除操作
    BEGIN TRANSACTION

        DELETE FROM [MFG_Inv_Trans_From] WHERE ID = @MAXID;

       --此处已经考虑到同一个料先备小数量, 后备大数量, 然后把小数量撤回时的标记更新情况.
       --在备料时, 并且客户端系统检验数量是否已经满足的状况, 也已经进行了自动提示处理,

        UPDATE MFG_Push_Plan_Detail
        SET
            PushedQty = PushedQty - @ScanQty
           ,Status    = CASE
                            WHEN PushedQty - @ScanQty >= PlanQty + OffsetQty THEN 'S3'
                            ELSE 'S2'
                       END
        WHERE
              Factory       = @Factory
          AND WorkGroup     = @WorkGroup
          AND LineCode      = @LineCode
          AND TransferOrder = @OrderValue
          AND ITEM          = @ScanItem
          AND ( Status = 'S1' OR Status = 'S2' OR Status = 'S3' )

        SELECT @nRowCount = COUNT(1)
        FROM MFG_Push_Plan_Detail
        WHERE
                Factory       = @Factory
            AND WorkGroup     = @WorkGroup
            AND LineCode      = @LineCode
            AND TransferOrder = @OrderValue
            AND ( Status = '0' OR Status = 'S1' OR Status = 'S2')

        IF @nRowCount=0
        BEGIN
            SET @OrderStatus = 'S3'
        END
        ELSE
        BEGIN
            SET @OrderStatus = 'S2'
        END

        UPDATE MFG_Push_Plan_Head
        SET
             Status = @OrderStatus
        WHERE
              Factory       = @Factory
          AND WorkGroup     = @WorkGroup
          AND LineCode      = @LineCode
          AND TransferOrder = @OrderValue
          AND ( Status = 'S1' OR Status = 'S3' )

    COMMIT TRANSACTION

   RETURN
GO

--Mfg_Insert系列(用以库转操作)存储过程之四: 推送
--推送发料操作，并更新MFG_Push_Plan_Head表头和MFG_Push_Plan_Detail表体状态信息
--插入到待接收表记录, 并更新库存记录表, 令其待入数量增加
CREATE PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Deliver]
    @Factory      AS VARCHAR(15)            --工厂编号
   ,@WorkGroup    AS VARCHAR(15)            --车间编号
   ,@LineCode     AS VARCHAR(15)            --产线编号
   ,@CreateUser   AS NVARCHAR(50)           --用户
   ,@OrderValue   AS NVARCHAR(50)           --发料单号
   ,@ForceFlag    AS VARCHAR(50)            --设计初衷:强制推送标志, 此标志目前没有使用, 其是否强制, 当下是系统自己判断而定.
   ,@CatchError   AS INT           OUTPUT   --系统判断用户操作异常的次数
   ,@RtnMsg       AS NVARCHAR(100) OUTPUT   --返回状态
AS
    SET @CatchError = 0
    SET @RtnMsg     = 'OK'

    DECLARE @nRowCount   AS INTEGER
    DECLARE @ForceString AS VARCHAR(40)

    DECLARE @RECITEM AS VARCHAR(50)
    DECLARE @RECQTY  AS NUMERIC(18,4)

    SET @ForceFlag = 1 --此处故意屏蔽了用户的输入选择. 考虑到有的单子是不需要收料的(空单情况),也需要强制结单.

    IF @ForceFlag = 1
    BEGIN
        SET @ForceString = 'Force Release!';
    END
    ELSE
    BEGIN
        SET @ForceString = ''
    END

    SELECT @nRowCount   = COUNT(1)
    FROM MFG_Push_Plan_Head
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND LineCode      = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status = '0' OR Status = 'S1' OR Status = 'S2'  OR Status = 'S3' )


    IF @nRowCount=0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '不能找到您录入的符合状态的批次号：' + @OrderValue + '!'
        RETURN
    END

  --执行数据库操作
  --此处建议加入锁处理
    BEGIN TRANSACTION

    INSERT INTO [MFG_Inv_Trans_To]
     ( SourceID, Factory, WorkGroup,  WHCode,   ORIDCK, TransferOrder, PONO, ITEM, Qty,  CreateUser , Status, Operate )
    SELECT   ID, Factory, WorkGroup, @LineCode, ORIDCK, TransferOrder, PONO, ITEM, Qty, @CreateUser,  '1',    'XBK_2_WIP'
    FROM [MFG_Inv_Trans_From]       --WITH (HOLDLOCK)
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND WHCode        = @LineCode + '-XBK'
      AND TransferOrder = @OrderValue
      AND ( Status = '1' OR Status = '2' OR Status = '3' )

-- do the inventory data table updating begin
    DECLARE RECCUR CURSOR FOR
    SELECT ITEM, SUM(QTY) QTY
    FROM [MFG_Inv_Trans_From]       --WITH (HOLDLOCK)
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND WHCode        = @LineCode + '-XBK'
      AND TransferOrder = @OrderValue
      AND ( Status = '1' OR Status = '2' OR Status = '3')
    GROUP BY ITEM
    ORDER BY ITEM;

    OPEN RECCUR;

    FETCH NEXT FROM RECCUR INTO @RECITEM, @RECQTY;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @nRowCount = COUNT(1)
        FROM [MFG_Inv_Data]
        WHERE
              Factory   = @Factory
          AND WorkGroup = @WorkGroup
          AND WHCode    = @LineCode
          AND ITEM      = @RECITEM

        IF @nRowCount > 0
        BEGIN
            UPDATE [MFG_Inv_Data]
            SET
                OrderQty = OrderQty + @RECQTY
               ,ModifyUser = @CreateUser
               ,ModifyTime = GETDATE()
            WHERE
                  Factory   = @Factory
              AND WorkGroup = @WorkGroup
              AND WHCode    = @LineCode
              AND ITEM      = @RECITEM
        END
        ELSE
        BEGIN
            INSERT INTO [MFG_Inv_Data]
             ( Factory,  WorkGroup,  WHCode,    ITEM,     OnhandQty, BlockQty, OrderQty, AllocateQty, ModifyUser, Status )
            VALUES
             ( @Factory, @WorkGroup, @LineCode, @RECITEM, 0,         0,        @RECQTY,  0,          @CreateUser, '1')
        END

        FETCH NEXT FROM RECCUR INTO @RECITEM, @RECQTY;
    END

    CLOSE RECCUR;
    DEALLOCATE RECCUR;
-- do the inventory data table updating end


    UPDATE [MFG_Inv_Trans_From]
    SET
         Status     = CASE Status
                           WHEN '0' THEN '5'
                           WHEN '1' THEN '5'
                           WHEN '2' THEN '5'
                           WHEN '3' THEN '4'
                       END
        ,Attribute_0 = CASE Status
                           WHEN '0' THEN @ForceString
                           WHEN '1' THEN @ForceString
                           WHEN '2' THEN @ForceString
                           WHEN '3' THEN ''
                       END
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND WHCode        = @LineCode + '-XBK'
      AND TransferOrder = @OrderValue
      AND ( Status = '0' OR Status = '1' OR Status = '2' OR Status = '3' )

    UPDATE  [dbo].[MFG_Push_Plan_Detail]
    SET
         Status      = CASE Status
                           WHEN '0'  THEN 'S5'
                           WHEN 'S1' THEN 'S5'
                           WHEN 'S2' THEN 'S5'
                           WHEN 'S3' THEN 'S4'
                       END
        ,Attribute_0 = CASE Status
                           WHEN '0'  THEN @ForceString
                           WHEN 'S1' THEN @ForceString
                           WHEN 'S2' THEN @ForceString
                           WHEN 'S3' THEN ''
                       END
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND LineCode      = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status = '0' OR Status = 'S1' OR Status = 'S2' OR Status = 'S3')

    UPDATE  [dbo].[MFG_Push_Plan_Head]
    SET
         Status     = CASE Status
                           WHEN '0'  THEN 'S5'
                           WHEN 'S1' THEN 'S5'
                           WHEN 'S2' THEN 'S5'
                           WHEN 'S3' THEN 'S4'
                       END
        ,Attribute_0 = CASE Status
                           WHEN '0'  THEN @ForceString
                           WHEN 'S1' THEN @ForceString
                           WHEN 'S2' THEN @ForceString
                           WHEN 'S3' THEN ''
                       END
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND LineCode      = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status = '0' OR Status = 'S1' OR Status = 'S2' OR Status = 'S3')

   COMMIT TRANSACTION

   RETURN

GO

--Mfg_Insert系列(用以库转操作)存储过程之五: 接收
--完成接收操作，并更新MFG_Push_Plan_Head表头和MFG_Push_Plan_Detail表体状态信息
CREATE PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Receive]
    @Factory      AS VARCHAR(15)            --工厂编号
   ,@WorkGroup    AS VARCHAR(15)            --车间编号
   ,@LineCode     AS VARCHAR(15)            --产线编号
   ,@CreateUser   AS NVARCHAR(50)           --用户
   ,@OrderValue   AS NVARCHAR(50)           --发料单号
   ,@PackageNo    AS VARCHAR(50)            --物料包装号码
   ,@ScanItem     AS VARCHAR(50)            --扫入的发料料号
   ,@ScanQty      AS NUMERIC(18,4)          --扫入的发料数量
   ,@CatchError   AS INT           OUTPUT   --系统判断用户操作异常的次数
   ,@RtnMsg       AS NVARCHAR(100) OUTPUT   --返回状态
AS
    set @CatchError = 0
    set @RtnMsg     = 'OK'

    DECLARE @PackageItem     AS VARCHAR(50)
    DECLARE @PackageQty      AS NUMERIC(18, 4)
    DECLARE @PackageLeftQty  AS NUMERIC(18, 4)
    DECLARE @RequestQty      AS NUMERIC(18, 4)
    DECLARE @PlanQty         AS NUMERIC(18, 4)
    DECLARE @PlanPONO        AS NUMERIC(6,  0)
    DECLARE @OffsetQty       AS NUMERIC(18, 4)
    DECLARE @PushedQty       AS NUMERIC(18, 4)
    DECLARE @nRowCount       AS INTEGER
    DECLARE @TABLEID         AS NUMERIC(18, 0)
    DECLARE @SOURCEID        AS NUMERIC(18, 0)

    DECLARE @OrderStatus     AS VARCHAR(15)

    SELECT @nRowCount   = COUNT(1)
         , @PackageItem = ISNULL(MAX(Item),   '')
         , @PackageQty  = ISNULL(SUM(RKAmount),0)
    FROM PD_Ware_RK
    WHERE ORIDCK = @PackageNo

    IF @nRowCount=0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '从原始包装清单中，未能找到此包装号：' + @PackageNo + '!'
        RETURN
    END

    IF UPPER(@PackageItem) <> UPPER(@ScanItem)
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '系统发现您录入的料号和原包装料号不一致：' + @ScanItem + '!'
        RETURN
    END

    SELECT
        @TABLEID  = ISNULL(MIN(ID), 0)
    FROM  MFG_Inv_Trans_To
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND WHCode        = @LineCode
      AND TransferOrder = @OrderValue
      AND ITEM          = @ScanItem
      AND ORIDCK        = @PackageNo
      AND QTY           = @ScanQty
      AND  ( Status = '0' OR Status = '1' OR Status = '2')

    IF @TABLEID = 0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '系统从待收料清单中没有找到您的收料! 提示:请核对录入的数量是否正确或者此料已经收料完成?'
        RETURN
    END

 --执行数据库更新操作

    BEGIN TRANSACTION

    UPDATE MFG_Inv_Trans_To
    SET Status = '3'
       ,ReceiveTime = GETDATE()
       ,ReceiveUser = @CreateUser
       ,Operate     = Operate + '_REC'
    WHERE ID = @TABLEID
    AND ( Status = '0' OR Status = '1' OR Status = '2')

    SELECT @PushedQty = ISNULL(SUM(QTY) ,0)
    FROM MFG_Inv_Trans_To
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND WHCode        = @LineCode
      AND TransferOrder = @OrderValue
      AND ITEM          = @ScanItem
      AND ( Status = '2' OR Status = '3' )

    UPDATE MFG_Push_Plan_Detail
    SET
        Status  = CASE
                  WHEN PushedQty = @PushedQty THEN 'R3'
                  ELSE 'R2'
                  END
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND LineCode      = @LineCode
      AND TransferOrder = @OrderValue
      AND ITEM          = @ScanItem
      AND ( Status = 'S4' OR Status = 'S5' OR Status = 'R1' OR Status = 'R2')

    SELECT @nRowCount = COUNT(1)
    FROM MFG_Push_Plan_Detail
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND LineCode      = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status = 'S4' OR Status = 'S5' OR Status = 'R1' OR Status = 'R2')

    IF @nRowCount=0
    BEGIN
        SET @OrderStatus = 'R3'
    END
    ELSE
    BEGIN
        SET @OrderStatus = 'R2'
    END

    UPDATE MFG_Push_Plan_Head
    SET
        Status = @OrderStatus
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND LineCode      = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status = 'S4' OR Status = 'S5' OR Status = 'R1' OR Status = 'R2')

    COMMIT TRANSACTION

   RETURN

GO


--Mfg_Insert系列(用以库转操作)存储过程之六: 结单
--完成结单操作，并更新MFG_Push_Plan_Head表头和MFG_Push_Plan_Detail表体状态信息
--更新库存记录表, 令其待入数量减少, 增加相应的在线数量
CREATE PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Close]
     @Factory      AS VARCHAR(15)            --工厂编号
    ,@WorkGroup    AS VARCHAR(15)            --车间编号
    ,@LineCode     AS VARCHAR(15)            --产线编号
    ,@CreateUser   AS NVARCHAR(50)           --用户
    ,@OrderValue   AS NVARCHAR(50)           --发料单号
    ,@ForceFlag    AS VARCHAR(50)            --设计初衷:强制结单标志, 此标志目前没有使用, 其是否强制, 当下是系统自己判断而定.
    ,@CatchError   AS INT           OUTPUT   --系统判断用户操作异常的次数
    ,@RtnMsg       AS NVARCHAR(100) OUTPUT   --返回状态
AS
    SET @CatchError = 0
    SET @RtnMsg     = 'OK'

    DECLARE @nRowCount   AS INTEGER
    DECLARE @ForceString AS VARCHAR(40)

    DECLARE @RECITEM AS VARCHAR(50)
    DECLARE @RECQTY  AS NUMERIC(18,4)


    SET @ForceFlag = 1 --此处故意屏蔽了用户的输入选择. 考虑到有的单子是不需要收料的(空单情况),也需要强制结单.

    IF @ForceFlag = 1
    BEGIN
        SET @ForceString = 'Force Close!';
    END
    ELSE
    BEGIN
        SET @ForceString = ''
    END

    SELECT @nRowCount   = COUNT(1)
    FROM MFG_Push_Plan_Head
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND LineCode      = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status = 'S4' OR Status = 'S5' OR Status = 'R1' OR Status = 'R2' OR Status = 'R3' )

    IF @nRowCount=0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '不能找到您录入的可以结单的批次号：' + @OrderValue + '! 提示:请确认此单的当前状态.'
        RETURN
    END

  --执行数据库操作
  --此处建议加入锁处理
    BEGIN TRANSACTION
/**/

    UPDATE [MFG_Inv_Trans_To]
    SET
        Status      = CASE Status
                    WHEN '0' THEN '5'
                    WHEN '1' THEN '5'
                    WHEN '2' THEN '5'
                    WHEN '3' THEN '4'
                  END
        ,Attribute_0 = CASE Status
                    WHEN '0' THEN @ForceString
                    WHEN '1' THEN @ForceString
                    WHEN '2' THEN @ForceString
                    WHEN '3' THEN ''
                  END
        ,ReceiveUser = CASE Status
                    WHEN '0' THEN @CreateUser
                    WHEN '1' THEN @CreateUser
                    WHEN '2' THEN @CreateUser
                    WHEN '3' THEN ReceiveUser
                  END
        ,ReceiveTime = CASE Status
                    WHEN '0' THEN GETDATE()
                    WHEN '1' THEN GETDATE()
                    WHEN '2' THEN GETDATE()
                    WHEN '3' THEN ReceiveTime
                  END
     WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND WHCode        = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status='0' OR Status='1' OR Status= '2' OR Status = '3' )

    UPDATE  [dbo].[MFG_Push_Plan_Detail]
    SET
        Status      = CASE Status
                    WHEN 'S4' THEN 'R5'
                    WHEN 'S5' THEN 'R5'
                    WHEN 'R1' THEN 'R5'
                    WHEN 'R2' THEN 'R5'
                    WHEN 'R3' THEN 'R4'
                  END
       ,Attribute_1 = CASE Status
                    WHEN 'S4' THEN @ForceString
                    WHEN 'S5' THEN @ForceString
                    WHEN 'R1' THEN @ForceString
                    WHEN 'R2' THEN @ForceString
                    WHEN 'R3' THEN ''
                  END
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND LineCode      = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status='S4' OR Status= 'S5' OR Status = 'R1' OR Status = 'R2' OR Status = 'R3')

    --检查一下是否有强制结单的条目
    SELECT @nRowCount   = COUNT(1)
    FROM [MFG_Inv_Trans_To]
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND WHCode        = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status = 'R5' )

    --如果没有发现强制结单的条目,则认为备料中的表头可以经过下一步的正常结单了.
    IF  @nRowCount > 0
    BEGIN
        UPDATE  [dbo].[MFG_Push_Plan_Head]
        SET
            Status      = 'R5'
           ,Attribute_1 = @ForceString
        WHERE
              Factory       = @Factory
          AND WorkGroup     = @WorkGroup
          AND LineCode      = @LineCode
          AND TransferOrder = @OrderValue
          AND ( Status = 'S4' OR Status = 'S5'OR Status='R1' OR Status= 'R2' OR Status = 'R3')
    END
    ELSE
    BEGIN
        UPDATE  [dbo].[MFG_Push_Plan_Head]
        SET
            Status      = CASE Status
                        WHEN 'S4' THEN 'R5'
                        WHEN 'S5' THEN 'R5'
                        WHEN 'R1' THEN 'R5'
                        WHEN 'R2' THEN 'R5'
                        WHEN 'R3' THEN 'R4'
                      END
           ,Attribute_1 = CASE Status
                        WHEN 'S4' THEN @ForceString
                        WHEN 'S5' THEN @ForceString
                        WHEN 'R1' THEN @ForceString
                        WHEN 'R2' THEN @ForceString
                        WHEN 'R3' THEN ''
                      END
        WHERE
              Factory       = @Factory
          AND WorkGroup     = @WorkGroup
          AND LineCode      = @LineCode
          AND TransferOrder = @OrderValue
          AND ( Status = 'S4' OR Status = 'S5'OR Status='R1' OR Status= 'R2' OR Status = 'R3' )
    END

    INSERT INTO [MFG_Push_Actual]
     (     Factory, WorkGroup,  WHCode_From,       WHCode_To, StationNo_To, TransferOrder, PONO, ITEM, IssueQty, CreateUser,  Status,  Attribute_0       )
    SELECT Factory, WorkGroup, @LineCode + '-XBK', @LineCode, '',           TransferOrder, PONO, ITEM, Qty,      @CreateUser, Status, ORIDCK
    FROM [MFG_Inv_Trans_To]       --WITH (HOLDLOCK)
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND WHCode        = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status = '4' OR Status = '5' )

    DECLARE RECCUR CURSOR FOR
    SELECT ITEM, SUM(QTY) QTY
    FROM [MFG_Inv_Trans_To]       --WITH (HOLDLOCK)
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND WHCode        = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status = '4' OR Status = '5' )
    GROUP BY ITEM
    ORDER BY ITEM;

    OPEN RECCUR;

    FETCH NEXT FROM RECCUR INTO @RECITEM, @RECQTY;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @nRowCount = COUNT(1)
        FROM [MFG_Inv_Data]
        WHERE
              Factory   = @Factory
          AND WorkGroup = @WorkGroup
          AND WHCode    = @LineCode
          AND ITEM      = @RECITEM

        IF @nRowCount > 0
        BEGIN
            UPDATE [MFG_Inv_Data]
            SET
                OnhandQty  = OnhandQty + @RECQTY
               ,OrderQty   = OrderQty  - @RECQTY
               ,ModifyUser = @CreateUser
               ,ModifyTime = GETDATE()
            WHERE
                  Factory   = @Factory
              AND WorkGroup = @WorkGroup
              AND WHCode    = @LineCode
              AND ITEM      = @RECITEM
        END
        ELSE
        BEGIN
            INSERT INTO [MFG_Inv_Data]
             (  Factory,  WorkGroup,  WHCode,    ITEM,     OnhandQty, BlockQty, OrderQty, AllocateQty, ModifyUser,  Status )
            VALUES
             ( @Factory, @WorkGroup, @LineCode, @RECITEM, @RECQTY,    0,        0,        0,          @CreateUser, '1')
        END

        FETCH NEXT FROM RECCUR INTO @RECITEM, @RECQTY;
    END

    CLOSE RECCUR;
    DEALLOCATE RECCUR;

   COMMIT TRANSACTION

   RETURN

GO

--删除计划发料单, 应用于"发料计划"界面模块的"删除"操作
CREATE PROCEDURE  [dbo].[usp_Mfg_delete_MFG_Push_Plan]
    @Factory      AS VARCHAR(15)        --工厂编号
   ,@WorkGroup    AS VARCHAR(15)        --车间编号
   ,@LineCode     AS VARCHAR(15)        --产线编号
   ,@OrderNumber  AS NVARCHAR(50)       --发料单号
AS
    DELETE FROM  MFG_Push_Plan_Head
    WHERE
            Factory       = @Factory
        AND WorkGroup     = @WorkGroup
        AND LineCode      = @LineCode
        AND TransferOrder = @OrderNumber
        AND Status        = N'0'

    IF @@ROWCOUNT <> 0
    BEGIN
        DELETE FROM MFG_Push_Plan_Detail
        WHERE
            Factory       = @Factory
        AND WorkGroup     = @WorkGroup
        AND LineCode      = @LineCode
        AND TransferOrder = @OrderNumber
    END
    RETURN
GO

--线边库发料过程中获得包装物料的相关数据, 给最终用户已尽可能多的有关此包装的提示信息.
--此存储过程可以返回含有三个字段的记录, 其字段为: KeyTip, KeyName, KeyValue
--客户端使用KeyName作为关键字进行需要的数据查询检索, 如: LeftQty
--为用户作为提示信息的KeyTip则可以随便更改.
CREATE PROCEDURE usp_Mfg_getPackageNumberInfo
    @PackageNo  VARCHAR(50) = ''        --物料包装号
AS
    DECLARE @ITEM          AS NVARCHAR(50)
    DECLARE @PackageQty    AS NUMERIC(18,4)
    DECLARE @IssuedQty     AS NUMERIC(18,4)
    DECLARE @LeftQty       AS NUMERIC(18,4)
    DECLARE @SplitTimes    AS INTEGER
    DECLARE @VendorCode    AS VARCHAR(50)
    DECLARE @ProductDate   AS VARCHAR(50)
    DECLARE @SLLDCode      AS VARCHAR(50)
    DECLARE @InputManName  AS NVARCHAR(50)
    DECLARE @InputTime     AS DATETIME

    SELECT
        @ITEM        = PDRK.Item,
        @PackageQty  = PDRK.RKAMount,
        @VendorCode  = PDRK.VendorID,
        @ProductDate = PDRK.ProductDate,
        @SLLDCode    = PDRK.SLLDCode,
        @InputManName= PDRK.InputManName,
        @InputTime   = PDRK.Inputtime,
        @IssuedQty   = ISNULL(ISSUED.QTY, 0),
        @SplitTimes  = ISNULL(ISSUED.Times, 0),
        @LeftQty     = @PackageQty - @IssuedQty
    FROM [dbo].[PD_Ware_RK] PDRK
      LEFT JOIN (
        SELECT
            SUM(Qty)   AS QTY,
            SUM(1)     AS Times,
            ORIDCK     AS ORIDCK
        FROM [dbo].[MFG_Inv_Trans_From]
        GROUP BY ORIDCK
    )  ISSUED
    ON ISSUED.ORIDCK = PDRK.ORIDCK
    WHERE PDRK.ORIDCK = @PackageNo

              SELECT '包装料号' AS KeyTip,  'Item' AS KeyName,  @ITEM AS KeyValue
    UNION ALL SELECT '剩余数量',            'LeftQty',          CONVERT(VARCHAR(50), @LeftQty)
    UNION ALL SELECT '包装数量',            'PackageQty',       CONVERT(VARCHAR(50), @PackageQty)
    UNION ALL SELECT '已发数量',            'IssuedQty',        CONVERT(VARCHAR(50), @IssuedQty)
    UNION ALL SELECT '拆包次数',            'SpliteTimes',      CONVERT(VARCHAR(50), @SplitTimes)
    UNION ALL SELECT '供货商号',            'VendorCode',       CONVERT(VARCHAR(50), @VendorCode)
    UNION ALL SELECT '生产日期',            'ProductDate',      CONVERT(VARCHAR(50), @ProductDate)
    UNION ALL SELECT '收料单号',            'SLLDCode',         CONVERT(VARCHAR(50), @SLLDCode)
    UNION ALL SELECT '收料员工',            'InputManName',     CONVERT(VARCHAR(50), @InputManName)
    UNION ALL SELECT '收料日期',            'InputTime',        CONVERT(VARCHAR(50), FORMAT(@InputTime,'yyyy-MM-dd hh:mm:ss'))
GO

--根据类型值, 关键字值, 取得需要显示给用户的显示字符串
--其值存储在常量数据表:MFG_ConstKeyLists中.
CREATE PROCEDURE usp_Mfg_getStatusValueTips
@KeyType   AS VARCHAR(15) = '',         --常量类型(也可以理解为常量类)
@keyName   AS VARCHAR(15) = '',         --常量名称(也可以理解为常量系列)
@Attribute AS VARCHAR(50) = ''          --常量属性(可以理解为限定条件)
AS
    SELECT *
    FROM
       MFG_ConstKeyLists
    WHERE
           KeyName     = @keyName
       AND KeyType     = @KeyType
       AND Attribute_0 = @Attribute
    ORDER BY
       DisplayOrder
GO


--Mfg_PPData 系列之一: PP_2_MFG接口记录状态重置
--重置PP_2_MFG_Interface的接口定义表, 即发生异常之后的重置标志, 等待下一周期进行再处理的机制.
CREATE PROCEDURE usp_Mfg_PPData_Reset
AS
    UPDATE PP_2_MFG_Interface
    SET Flag        = 'R'
       ,Attribute_5 = 'MFG Reset:' + CONVERT(VARCHAR, GETDATE(),121)
    WHERE
        Flag = 'A'
     OR Flag = 'B'
     OR Flag = 'C'
GO

--Mfg_PPData 系列之二: PP_2_MFG数据导入MFG
--从PP_2_MFG_Interface接口模块导入数据, 把需要更新到生产线库存的数据准备好.
CREATE PROCEDURE usp_Mfg_PPData_Import
AS
    DECLARE @Factory     AS VARCHAR(15);
    DECLARE @WorkGroup   AS VARCHAR(15);
    DECLARE @WHCode      AS VARCHAR(15);
    DECLARE @LineCode    AS VARCHAR(15);
    DECLARE @GoodsCode   AS NVARCHAR(50);
    DECLARE @OutputQty   AS NUMERIC(18,4);
    DECLARE @LOT         AS NVARCHAR(50);
    DECLARE @StationNo   AS VARCHAR(15);
    DECLARE @SourceID    AS INTEGER;
    DECLARE @ValidFlag   AS INTEGER;
    DECLARE @TransferOrder AS NVARCHAR(50);

    SELECT
        @SourceID = ISNULL(MIN(ID), 0)
    FROM
        PP_2_MFG_Interface
    WHERE
        FLAG = '?' OR FLAG ='R';

    WHILE(@SourceID > 0)
    BEGIN
        print @SourceID

        BEGIN TRANSACTION
        --取得接口原始的接口数据
        SELECT
             @ValidFlag = 1
            ,@Factory   = Factory
            ,@WorkGroup = WorkGroup
            ,@LineCode  = LineCode
            ,@StationNo = StationNo
            ,@GoodsCode = GoodsCode
            ,@OutputQty = Qty
            ,@LOT       = LOT
        FROM PP_2_MFG_Interface
        WHERE
                ID = @SourceID
            AND ( FLAG = '?' OR FLAG ='R' );

        --嵌套条件扁平化, 嵌套逻辑转化为顺序处理, 可以变得清晰明了.
        --此处也要判断, 目的是可以将来依据实际情况可以方便的进行顺序调整.
        IF @ValidFlag > 0
        BEGIN
            --设定开始处理标志
            UPDATE PP_2_MFG_Interface
                SET
                    FLAG        = '2'
                   ,OutputTime  = GETDATE()
                   ,Attribute_4 = 'MFG Process:' + CONVERT(VARCHAR, GETDATE(),121)
            WHERE
                    ID   = @SourceID
                AND ( FLAG = '?' OR FLAG ='R' );  --此处的条件不可以省略, 可以避免多个实例争抢一个标志
        END

        IF @ValidFlag > 0
        BEGIN
            --检验是否有此GoodsCode模板(MUB)数据值
            SELECT
                @ValidFlag = COUNT(1)
            FROM
                MFG_Station_MTL_UseBase
            WHERE
                    Factory   = @Factory
                AND WorkGroup = @WorkGroup
                AND LineCode  = @LineCode
                AND MItem     = @GoodsCode;

            IF @ValidFlag = 0
            BEGIN
                UPDATE PP_2_MFG_Interface
                    SET FLAG        = 'A'
                WHERE
                    ID   = @SourceID
                AND FLAG = '2';
            END
        END

        IF @ValidFlag > 0
        BEGIN
            --检验是否有此Station模板(MUB)数据值
            SELECT
                @ValidFlag = COUNT(1)
            FROM
                MFG_Station_MTL_UseBase
            WHERE
                    Factory   = @Factory
                AND WorkGroup = @WorkGroup
                AND LineCode  = @LineCode
                AND StationNo = @StationNo;

            IF @ValidFlag = 0
            BEGIN
                UPDATE PP_2_MFG_Interface
                    SET FLAG        = 'B'
                WHERE
                    ID   = @SourceID
                AND FLAG = '2';
            END
        END

        IF @ValidFlag > 0
        BEGIN
            --取得单子号, 此处的处理方法不好. 在SQL Server数据库的实现只好如此, 目前没有更好的办法.
            CREATE TABLE #TT (PPSerialNo NVARCHAR(50));
            INSERT INTO #TT EXEC usp_Mes_getNewSerialNo 'PP2MFG', 'P2M', 12;
            SELECT @TransferOrder = PPSerialNo FROM #TT;
            DROP TABLE #TT;

            --正式进行接口数据的导入
            INSERT INTO MFG_Station_MTL_Usage
                   (Factory,  WorkGroup,  WHCode,    LineCode,  StationNo,  TransferOrder,  LOT,  MItem,     SItem, Qty,               CreateUser, ModifyUser, Status, PP_2_MFG_ID, Attribute_0,                                                                 Attribute_1)
            SELECT @Factory, @WorkGroup, @LineCode, @LineCode, @StationNo, @TransferOrder, @LOT, @GoodsCode, SItem, Qty * @OutputQty , 'MFG_SYS',  'MFG_SYS',  0,      @SourceID,   'MUB T:' + CONVERT(VARCHAR, CreateTime,121) + ';Q:' + CONVERT(VARCHAR, Qty), 'MUB U:' + CreateUser
            FROM MFG_Station_MTL_UseBase
            WHERE
                    Factory   = @Factory
                AND WorkGroup = @WorkGroup
                AND LineCode  = @LineCode
                AND StationNo = @StationNo
                AND MItem     = @GoodsCode;

            --更新接口表标志以及更新时间.
            UPDATE PP_2_MFG_Interface
            SET
                 FLAG        = '4'
                ,OutloadTime = GETDATE()
            WHERE
                    ID   = @SourceID
                AND FLAG = '2';
        END

        COMMIT TRANSACTION;

        SELECT
            @SourceID = ISNULL(MIN(ID), 0)
        FROM
            PP_2_MFG_Interface
        WHERE
            FLAG = '?' OR FLAG ='R';
    END
GO

--Mfg_PPData 系列之三: MFG更新库存
--把需要更新到生产线库存准备好的数据, 进行实际的更新到在线库存表中
--(时间关系: 这里没有对负库存进行任何处理, 即: 实际会产生负库存的情况发生.
CREATE PROCEDURE usp_Mfg_PPData_Update_Inv
AS
    DECLARE @Factory       AS VARCHAR(15);
    DECLARE @WorkGroup     AS VARCHAR(15);
    DECLARE @WHCode        AS VARCHAR(15);
    DECLARE @TransferOrder AS NVARCHAR(50);

    --把MFG_Station_MTL_Usage表中的生产线已用物料的数据导入到库存表MFG_Inv_Data中.
    BEGIN TRANSACTION
        UPDATE MFG_Station_MTL_Usage
        SET
            Status = '1'
        WHERE
            STATUS = '0'

    -- do the inventory data table updating begin

        DECLARE @nRowCount AS INTEGER;
        DECLARE @INVITEM   AS VARCHAR(50);
        DECLARE @INVQTY    AS NUMERIC(18,4);

        DECLARE INVCUR CURSOR FOR
        SELECT Factory, WorkGroup, WHCode, TransferOrder, SItem AS ITEM, SUM(QTY) QTY
        FROM MFG_Station_MTL_Usage
        WHERE Status = '1'
        GROUP BY Factory, WorkGroup, WHCode, TransferOrder, SItem

        OPEN INVCUR;

        FETCH NEXT FROM INVCUR INTO @Factory, @WorkGroup, @WHCode, @TransferOrder, @INVITEM, @INVQTY;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @nRowCount = COUNT(1)
            FROM [MFG_Inv_Data]
            WHERE
                  Factory   = @Factory
              AND WorkGroup = @WorkGroup
              AND WHCode    = @WHCode
              AND ITEM      = @INVITEM

            IF @nRowCount > 0
            BEGIN
                UPDATE [MFG_Inv_Data]
                SET
                    OnhandQty  = OnhandQty - @INVQTY
                   ,ModifyUser = 'MFG_SYS'
                   ,ModifyTime = GETDATE()
                WHERE
                      Factory   = @Factory
                  AND WorkGroup = @WorkGroup
                  AND WHCode    = @WHCode
                  AND ITEM      = @INVITEM
            END
            ELSE
            BEGIN
                INSERT INTO [MFG_Inv_Data]
                        ( Factory,  WorkGroup,  WHCode,   ITEM,     OnhandQty, BlockQty, OrderQty, AllocateQty, ModifyUser, Status )
                VALUES  ( @Factory, @WorkGroup, @WHCode, @INVITEM, -@INVQTY,  0,        0,        0,           'MFG_SYS',  '1')
            END

            FETCH NEXT FROM INVCUR INTO @Factory, @WorkGroup, @WHCode, @TransferOrder, @INVITEM, @INVQTY;
        END

        CLOSE INVCUR;
        DEALLOCATE INVCUR;
    -- do the inventory data table updating end
        UPDATE MFG_Station_MTL_Usage
        SET
            Status = '2'
        WHERE
            STATUS = '1'

    COMMIT TRANSACTION
GO

--用于制作报告, 目的是依据各种条件进行综合查询发料单的情况。
CREATE PROCEDURE [dbo].[usp_Mfg_rptOrderList]
   @Factory   AS VARCHAR(15)  = '',     --工厂编号
   @WorkGroup AS VARCHAR(15)  = '',     --车间编号
   @LineCode  AS VARCHAR(15)  = '',     --产线编号
   @FromDate  AS DateTime     = '',     --开始时间
   @ToDate    AS DateTime     = '',     --结束时间
   @KeyStatus AS VARCHAR(15)  = '',     --状态码
   @KeyType   AS VARCHAR(15)  = '',     --查询关键字名称(字段名称)
   @KeyValue  AS NVARCHAR(50) = ''      --关键字值
AS
    SELECT
        PPLot.Lot,
        PPLot.OrderNo,
        PPLot.GoodsCode,
        PPLot.ModelCode,
        PPLot.InQty,
        PPLot.OtherIssue,
        FORMAT(PPLot.ProDate,   'yyyy-MM-dd') ProDate,
        FORMAT(PPLot.BPro_Date, 'yyyy-MM-dd') BPro_Date,
        FORMAT(PPlan.CreateTime,'yyyy-MM-dd HH:mm:ss') CreateTime,
        ISNULL(PPlan.CreateUser, '') CreateUser,
        (SELECT KeyTip
        FROM Mfg_ConstKeyLists
        WHERE
            KeyType = 'MTL_ORHD'
        AND KeyName = 'Status'
        AND KeyValue=ISNULL(PPlan.Status, '')
        ) AS StatusTip,
        ISNULL(PPlan.Status, '') StatusValue,
        ISNULL(LCO.LineCodeName, '') LineName
    FROM [PP_Lot] PPLot
    LEFT JOIN MFG_Push_Plan_Head PPlan ON PPlan.TransferOrder = PPLot.Lot
    LEFT JOIN MFG_LineCodeOrders LCO   ON LCO.LineCode = PPlan.LineCode AND LCO.Factory = PPlan.Factory AND LCO.WorkGroup = PPlan.WorkGroup
    WHERE
        PPLot.BPro_Date between @FromDate and @ToDate
    AND (ISNULL(PPlan.Status, '') = @KeyStatus or @KeyStatus = 'X')
    AND
    (
       (@KeyType       = '' )
    OR (PPLot.GoodsCode= @KeyValue and @KeyType='GoodsNumber' )
    OR (PPLot.OrderNo  = @KeyValue and @KeyType='WONumber'    )
    OR (PPLot.Lot      = @KeyValue and @KeyType='LotNumber'   )
    )
    AND
    (
            (ISNULL(LCO.Factory,   '') = @Factory   or @Factory   = '' )
        AND (ISNULL(LCO.WorkGroup, '') = @WorkGroup or @WorkGroup = '' )
        AND (ISNULL(LCO.LineCode,  '') = @LineCode  or @LineCode  = '' )
    )
    ORDER BY Lot
  GO

--用于制作报告, 目的是查询出哪个批次使用指定的料号以及其具体发料情况。
CREATE PROCEDURE [dbo].[usp_Mfg_rptUsesLines]
   @Factory    AS VARCHAR(15)  = '',    --工厂编号
   @WorkGroup  AS VARCHAR(15)  = '',    --车间编号
   @LineCode   AS VARCHAR(15)  = '',    --产线编号
   @FromDate   AS DateTime     = '',    --开始时间
   @ToDate     AS DateTime     = '',    --结束时间
   @KeyStatus  AS VARCHAR(15)  = '',    --状态码
   @ItemValue  AS NVARCHAR(50) = ''     --料号
AS
    SELECT
        PPlan.Lot       LotNumber,
        PPlan.ModelCode LotModel,
        PPlan.Qty       LotQty,
        ISNULL(LCO.LineCodeName, '') LotLineName,
        FORMAT(PPlan.PlanDate,  'yyyy-MM-dd') LotDate,
        FORMAT(PPlan.CreateTime,'yyyy-MM-dd HH:mm:ss') LotCreateTime,
        (SELECT KeyTip
        FROM Mfg_ConstKeyLists
        WHERE
            KeyType = 'MTL_ORHD'
        AND KeyName = 'Status'
        AND KeyValue=ISNULL(PPlan.Status, '')
        ) AS LotStatusTip,
        ISNULL(PPlan.Status, '') LotStatusValue,
        PItem.Item ItemNumber,
        PItem.PlanQty ItemQty,
        PItem.PushedQty ItemPushedQty,
        (SELECT KeyTip
        FROM Mfg_ConstKeyLists
        WHERE
            KeyType = 'MTL_ORLN'
        AND KeyName = 'Status'
        AND KeyValue=ISNULL(PItem.Status, '')
        ) AS ItemStatusTip,
        ISNULL(PItem.Status, '') ItemStatusValue
    FROM MFG_Push_Plan_Head PPlan
    INNER JOIN MFG_Push_Plan_Detail PItem ON PItem.LineCode = PPlan.LineCode AND PItem.Factory = PPlan.Factory AND PItem.WorkGroup = PPlan.WorkGroup AND PItem.TransferOrder = PPlan.TransferOrder
    LEFT  JOIN MFG_LineCodeOrders LCO     ON LCO.LineCode   = PPlan.LineCode AND LCO.Factory   = PPlan.Factory AND LCO.WorkGroup   = PPlan.WorkGroup
    WHERE
        PPlan.CreateTime between @FromDate and @ToDate
    AND (PPlan.Status= @KeyStatus or @KeyStatus = 'X')
    AND (PItem.Item  = @ItemValue or @ItemValue = '' )
    AND
    (
            (ISNULL(LCO.Factory,   '') = @Factory   or @Factory   = '' )
        AND (ISNULL(LCO.WorkGroup, '') = @WorkGroup or @WorkGroup = '' )
        AND (ISNULL(LCO.LineCode,  '') = @LineCode  or @LineCode  = '' )
    )
    ORDER BY LotNumber
GO

--用于制作报告, 目的是查询出指定批次具体发料情况。
CREATE PROCEDURE [dbo].[usp_Mfg_rptTransLines]
   @Factory   AS VARCHAR(15)  = '',     --工厂编号
   @WorkGroup AS VARCHAR(15)  = '',     --车间编号
   @LineCode  AS VARCHAR(15)  = '',     --产线编号
   @FromDate  AS DateTime     = '',     --开始时间
   @ToDate    AS DateTime     = '',     --结束时间
   @KeyStatus AS VARCHAR(15)  = '',     --状态码
   @TransKeyType   AS VARCHAR(50) = '', --查询关键字类型(TransferOrder或ORIDCK, 空则不限制)
   @TransKeyValue  AS NVARCHAR(50) = '' --查询关键字值

AS
    SELECT
        FF.TransferOrder   LotNumber,
        FF.PONO            PONO,
        FF.Item            Item,
        FF.ORIDCK          ORIDCK,
        FF.Qty             Qty,
        FORMAT(FF.CreateTime, 'yyyy-MM-dd HH:mm:ss') SendTime,
        FORMAT(TT.ReceiveTime,'yyyy-MM-dd HH:mm:ss') RecTime,
        FF.CreateUser  SendUser,
        TT.ReceiveUser RecUser,
        (SELECT KeyTip
        FROM Mfg_ConstKeyLists
        WHERE
            KeyType = 'MTL_RECV'
        AND KeyName = 'Status'
        AND KeyValue=ISNULL(TT.Status, '')
        ) AS RecStatusTip,
        ISNULL(TT.Status, '') RecStatusValue,
        (SELECT KeyTip
        FROM Mfg_ConstKeyLists
        WHERE
            KeyType = 'MTL_SEND'
        AND KeyName = 'Status'
        AND KeyValue=ISNULL(FF.Status, '')
        ) AS SendStatusTip,
        ISNULL(FF.Status, '') SendStatusValue,
        LCO.LineCodeName LineName
    FROM        [dbo].[MFG_Inv_Trans_From] FF
      LEFT JOIN [dbo].[MFG_Inv_Trans_To]   TT ON FF.ID = TT.SourceID
      LEFT JOIN MFG_LineCodeOrders LCO  ON LCO.Factory = FF.Factory AND FF.WorkGroup = LCO.WorkGroup AND LCO.LineCode + '-XBK' = FF.WHCode
    WHERE
        FF.CreateTime BETWEEN @FromDate AND @ToDate
    AND (FF.Status = @KeyStatus or @KeyStatus = 'X')
    AND (
            (@TransKeyType    = '')
         OR (FF.TransferOrder = @TransKeyValue AND @TransKeyType ='TransferOrder' )
         OR (FF.ORIDCK        = @TransKeyValue AND @TransKeyType ='ORIDCK'        )
        )
    AND
    (
            (ISNULL(LCO.Factory,   '') = @Factory   or @Factory   = '' )
        AND (ISNULL(LCO.WorkGroup, '') = @WorkGroup or @WorkGroup = '' )
        AND (ISNULL(LCO.LineCode,  '') = @LineCode  or @LineCode  = '' )
    )
    ORDER BY LotNumber, PONO
GO

--用于制作报告, 目的是查询出库存情况。
CREATE PROCEDURE [dbo].[usp_Mfg_rptWHInventoryList]
   @Factory    AS VARCHAR(15)  = '',    --工厂编号
   @WorkGroup  AS VARCHAR(15)  = '',    --车间编号
   @LineCode   AS VARCHAR(15)  = '',    --产线编号
   @ItemValue  AS NVARCHAR(50) = ''     --料号
AS
    SELECT
         Inv.Item        AS Item
        ,Itm.DSCA        AS DSCA
        ,Inv.OnhandQty   AS OnhandQty
        ,Inv.OrderQty    AS OrderQty
        ,Inv.AllocateQty AS AllocateQty
        ,Inv.OnhandQty + Inv.OrderQty - AllocateQty AS AvailableQty
        ,Inv.ModifyUser ModifyUser
        ,FORMAT(Inv.ModifyTime,'yyyy-MM-dd HH:mm:ss') ModifyTime
    FROM [MFG_Inv_Data] Inv
    LEFT JOIN [dbo].[Baan_Item] Itm  ON INV.ITEM = ITM.ITEM
    WHERE
        (Inv.Item  = @ItemValue or @ItemValue = '' )
        AND Inv.Factory   = @Factory
        AND Inv.WorkGroup = @WorkGroup
        AND Inv.WHCode    = @LineCode
    ORDER BY Item
GO

--用于制作报告, 用于查询盘点记录的所有单子的单子号, 如果参数为空, 则默认查询最近半年的记录, 并以时间逆序的顺序返回。
CREATE PROCEDURE [dbo].[usp_Mfg_rptMCCOrdersList]
   @Factory   AS VARCHAR(15)  = '',     --工厂编号
   @WorkGroup AS VARCHAR(15)  = '',     --车间编号
   @LineCode  AS VARCHAR(15)  = '',     --产线编号
   @ItemValue AS NVARCHAR(50) = ''      --料号
AS

 SELECT
     HH.*,
     FORMAT(HH.CreateTime,'yyyy-MM-dd HH:mm:ss') CreateTime
 FROM MFG_CC_Task_HEAD HH
 WHERE
       HH.Factory   = @Factory
   AND HH.WorkGroup = @WorkGroup
   AND HH.LineCode  = @LineCode
   AND
   (
       ( @ItemValue  = '' AND HH.CREATETIME > GETDATE() - 180 )
   OR  ( @ItemValue <> '' AND HH.TransferOrder in (SELECT TransferOrder FROM MFG_CC_TASK_DETAIL WHERE ITEM = @ItemValue))
   )
 ORDER BY
     HH.CREATETIME DESC
GO

--用于制作报告, 用于查询盘点记录中某个单子号对应的盘点料的详细信息, 并以ITEM的顺序返回。
CREATE PROCEDURE [dbo].[usp_Mfg_rptMCCItemsList]
   @TransferOrder  AS NVARCHAR(50) = '' --盘点票票号
AS
  SELECT DD.*,
    FORMAT(DD.CreateTime,'yyyy-MM-dd HH:mm:ss') CreateTime,
    FORMAT(DD.ModifyTime,'yyyy-MM-dd HH:mm:ss') ModifyTime,
    DD.OnhandQty + DD.OrderQty - DD.AllocateQty AvailableQty,
    DD.AdvanceQty + DD.OrderQty - DD.AllocateQty AdvAviQty,
    II.DSCA
  FROM MFG_CC_TASK_DETAIL DD
  LEFT JOIN Baan_Item ii ON ii.ITEM = DD.ITEM
  WHERE DD.TransferOrder = @TransferOrder
  ORDER BY DD.ITEM
GO

--用以查找从'流程控制'数据导出到'生产计划'模块的接口数据查询
CREATE PROCEDURE usp_Mfg_rptP2MInterfaceList
    @Factory   AS VARCHAR(15)  =  '',   --工厂编号
    @WorkGroup AS VARCHAR(15)  =  '',   --车间编号
    @LineCode  AS VARCHAR(15)  =  '',   --产线编号
    @StationNo AS VARCHAR(15)  =  '',   --工位编码
    @FromDate  AS DateTime     =  '',   --开始时间
    @ToDate    AS DateTime     =  '',   --结束时间
    @KeyStatus AS VARCHAR(15)  =  '',   --状态码
    @KeyType   AS VARCHAR(50)  =  '',   --数据类型(GoodsNumber, LotNumber, 空则不限定)
    @KeyValue  AS NVARCHAR(50) = N''    --数据值
AS
 SELECT
        P2M.LOT            LOT,
        P2M.GoodsCode      GoodsCode,
        P2M.Qty            Qty,
        FORMAT(P2M.GenerateTime,'yyyy-MM-dd HH:mm:ss') GenerateTime,
        FORMAT(P2M.OutputTime,  'yyyy-MM-dd HH:mm:ss') OutputTime,
        FORMAT(P2M.OutloadTime, 'yyyy-MM-dd HH:mm:ss') OutloadTime,
        (SELECT KeyTip
        FROM Mfg_ConstKeyLists
        WHERE
            KeyType = 'P2M_FLAG'
        AND KeyName = 'Flag'
        AND KeyValue=ISNULL(P2M.Flag, '-')
        ) AS StatusTip,
        ISNULL(P2M.Flag, '') StatusValue,
        LL.LineCodeName LineName,
        II.DSCA         GoodsDsca,
        SS.StationNoName StationName
    FROM        PP_2_MFG_Interface P2M
      LEFT JOIN MFG_LineCodeOrders  LL ON LL.Factory   = P2M.Factory AND LL.WorkGroup = P2M.WorkGroup AND LL.LineCode = P2M.LineCode
      LEFT JOIN Baan_Item           II ON II.ITEM      = P2M.GoodsCode
      LEFT JOIN MFG_StationNoOrders SS ON SS.StationNo = P2M.StationNo
    WHERE
        P2M.GenerateTime BETWEEN @FromDate AND @ToDate
    AND (P2M.Flag      = @KeyStatus or @KeyStatus = 'X')
    AND (P2M.StationNo = @StationNo or @StationNo = '' )
    AND (
            (@KeyType       = '' )
         OR (P2M.GoodsCode  = @KeyValue AND @KeyType ='GoodsNumber')
         OR (P2M.LOT        = @KeyValue AND @KeyType ='LotNumber'  )
        )
    AND
    (
            (ISNULL(P2M.Factory,   '') = @Factory   or @Factory   = '' )
        AND (ISNULL(P2M.WorkGroup, '') = @WorkGroup or @WorkGroup = '' )
        AND (ISNULL(P2M.LineCode,  '') = @LineCode  or @LineCode  = '' )
    )
    ORDER BY GenerateTime, LineName, LOT
GO


--用于制作报告, 用以查找从'流程控制'数据导出到'生产计划'模块接口获得数据,
--其用来导入到在线库存中的中间中转表MFG_Station_MTL_Usage, 其是基于MUB模板中获得消耗, 等待更新库存.
CREATE PROCEDURE usp_Mfg_rptM2IDetailList
    @Factory   AS VARCHAR(15)  =  '',   --工厂编号
    @WorkGroup AS VARCHAR(15)  =  '',   --车间编号
    @LineCode  AS VARCHAR(15)  =  '',   --产线编号
    @StationNo AS VARCHAR(15)  =  '',   --工位编号
    @FromDate  AS DateTime     =  '',   --开始时间
    @ToDate    AS DateTime     =  '',   --结束时间
    @KeyStatus AS VARCHAR(15)  =  '',   --状态码
    @KeyType   AS VARCHAR(50)  =  '',   --数据类型(MItem, SItem, LotNumber 或空则不限制)
    @KeyValue  AS NVARCHAR(50) = N''    --数据值
AS
 SELECT
        M2I.LOT        LOT,
        M2I.MItem      MItem,
        M2I.SItem      SItem,
        M2I.Qty        Qty,
        FORMAT(M2I.CreateTime,'yyyy-MM-dd HH:mm:ss') CreateTime,
        (SELECT KeyTip
        FROM Mfg_ConstKeyLists
        WHERE
            KeyType = 'M2I_STAT'
        AND KeyName = 'Status'
        AND KeyValue=ISNULL(M2I.Status, '-')
        ) AS StatusTip,
        ISNULL(M2I.Status, '') StatusValue,
        LL.LineCodeName LineName,
        II.DSCA         SItemDsca,
        SS.StationNoName StationName
    FROM        MFG_Station_MTL_Usage M2I
      LEFT JOIN MFG_LineCodeOrders  LL ON LL.Factory   = M2I.Factory 
                                      AND LL.WorkGroup = M2I.WorkGroup 
                                      AND LL.LineCode  = M2I.LineCode
      LEFT JOIN Baan_Item           II ON II.ITEM      = M2I.SItem
      LEFT JOIN MFG_StationNoOrders SS ON SS.StationNo = M2I.StationNo
    WHERE
        M2I.CreateTime BETWEEN @FromDate AND @ToDate
    AND (M2I.Status    = @KeyStatus or @KeyStatus = 'X')
    AND (M2I.StationNo = @StationNo or @StationNo = '' )
    AND (
            (@KeyType   = '' )
         OR (M2I.MItem  = @KeyValue AND @KeyType ='MItem'    )
         OR (M2I.SItem  = @KeyValue AND @KeyType ='SItem'    )
         OR (M2I.LOT    = @KeyValue AND @KeyType ='LotNumber')
        )
    AND
    (
            (ISNULL(M2I.Factory,   '') = @Factory   or @Factory   = '' )
        AND (ISNULL(M2I.WorkGroup, '') = @WorkGroup or @WorkGroup = '' )
        AND (ISNULL(M2I.LineCode,  '') = @LineCode  or @LineCode  = '' )
    )
    ORDER BY CreateTime, LineName, LOT
GO

--用于制作报告, 用以查找从历史库存数据中得出在线库存数量, 主要用于制作图表,
CREATE PROCEDURE usp_Mfg_rptInvSnapShot
AS
    DECLARE @nLineCount     AS INT;
    DECLARE @nDayCount      AS INT;
    DECLARE @Factory        AS VARCHAR(15);
    DECLARE @WorkGroup      AS VARCHAR(15);
    DECLARE @LineCode       AS VARCHAR(15);
    DECLARE @LineCodeName   AS VARCHAR(15);
    DECLARE @LineAlias      as VARCHAR(50);
    DECLARE @SQL0           AS NVARCHAR(MAX);
    DECLARE @SQL1           AS NVARCHAR(MAX);
    DECLARE @SQL2           AS NVARCHAR(MAX);

    SELECT @nLineCount = 0, @nDayCount = 0;
    SELECT @SQL0 = '', @SQL1 = '', @SQL2 = '';

    --获取需要查询数据的日期基准, 即: 获得坐标的category
    WHILE @nDayCount <8 
    BEGIN
        SELECT @SQL0 = @SQL0 + ' INSERT INTO #TMP_SNAPSHOTDATA(CATE) VALUES( ''' + CONVERT(VARCHAR, GETDATE() - @nDayCount, 102) + ''');';
        SELECT @nDayCount = @nDayCount + 1
    END
    SELECT @SQL0 = ' CREATE TABLE #TMP_SNAPSHOTDATA( CATE VARCHAR(18)); ' + @SQL0;

    DECLARE cursor_Line CURSOR SCROLL DYNAMIC FOR 
    SELECT top 1 Factory, WorkGroup, LineCode, LineCodeName 
    FROM MFG_LineCodeOrders 
    ORDER BY Factory, WorkGroup, LineCodeOrder;

    OPEN cursor_Line    
    FETCH NEXT FROM cursor_Line INTO @Factory, @WorkGroup, @LineCode, @LineCodeName;
    WHILE @@FETCH_STATUS = 0  
    BEGIN  
        SELECT @LineAlias = 'LINE_' + CONVERT(VARCHAR, @nLineCount)
        
        --获取需要显示的线别的名称和对应的库存数据字段,即: 获得坐标的series
        SELECT @SQL1 = @SQL1 
        + ',''' + @LineCodeName + '''' 
        + ',ISNULL(' + @LineAlias + '.SQTY, 0)';

        --列示出需要查询的数据源, 即:逐个线别的进行数据统计并与基准进行左连接
        SELECT @SQL2 = @SQL2 
            + ' LEFT JOIN( ' 
            + '   SELECT CONVERT(VARCHAR, INV.SnapTime, 102) DDATE ' 
            + '       ,SUM(OnHandQty + OrderQty - AllocateQty) SQTY '
            + '   FROM MFG_Inv_Data_Snapshot AS INV '
            + '   WHERE '
            + '     INV.SnapTime BETWEEN GETDATE() - ' + CONVERT(VARCHAR, @nDayCount) + ' AND GETDATE() '
            + '     AND INV.Factory  =''' + @Factory   + ''' ' 
            + '     AND INV.WorkGroup=''' + @WorkGroup + ''' ' 
            + '     AND INV.WHCode   =''' + @LineCode  + ''' '
            + '     GROUP BY CONVERT(VARCHAR, INV.SnapTime, 102) '
            + ' ) AS ' + @LineAlias + ' ON ' + @LineAlias + '.DDATE = BCATE.CATE ';

            FETCH NEXT FROM cursor_Line INTO @Factory, @WorkGroup, @LineCode, @LineCodeName;
            SELECT @nLineCount = @nLineCount + 1;
        END

    SELECT @SQL1 = ' SELECT BCATE.CATE ' + @SQL1 
                 + ' FROM #TMP_SNAPSHOTDATA BCATE ' + @SQL2 
                 + ' ORDER BY BCATE.CATE ;'
    SELECT @SQL2 = ' DROP TABLE #TMP_SNAPSHOTDATA; '
    EXEC (@SQL0 + @SQL1 + @SQL2);
    
    CLOSE cursor_Line;
    DEALLOCATE cursor_Line;  
GO

--用以保存库存数据的快照.
CREATE PROCEDURE usp_Mfg_SnapShot_Mfg_Inv_Data
AS
    INSERT INTO MFG_Inv_Data_Snapshot 
    (      Factory, WorkGroup, WHCode, ITEM, OnhandQty, BlockQty, OrderQty, AllocateQty, SnapTime,  Status )
    SELECT Factory, WorkGroup, WHCode, ITEM, OnhandQty, BlockQty, OrderQty, AllocateQty, getdate(), Status
    FROM
    MFG_Inv_Data
GO

--存储过程定义++++++++++++结束++++++++++++++++++++++

--初始化数据
  INSERT INTO MFG_Factorys        (Factory, FactoryName, Description                               ) VALUES('1001', '宜科天津','宜科(天津)电子有限公司');
  INSERT INTO MFG_WorkGroups      (Factory, WorkGroup, WorkGroupName, Description                  ) VALUES('1001', '1001-01', '天津-传感器', '天津传感器车间');
  INSERT INTO MFG_LineCodeOrders  (Factory, WorkGroup, LineCode, LineCodeName, LineCodeOrder       ) VALUES('1001', '1001-01', '1001-01-01', '传感器-01线', 1);
  INSERT INTO MFG_WHCodeOrders    (Factory, WorkGroup, WHCode, WHCodeName, WHCodeDesc, WHCodeOrder ) VALUES('1001', '1001-01', '1001-01-01', '传感器-01库', '传感器-01库（主料）', 1);
      
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01',  1, 1, '0001','导线准备'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01',  2, 1, '0002','屏蔽环感应片焊接');
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01',  3, 1, '0003','一次灌前塞'      );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01',  4, 1, '0004','焊接'            );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01',  5, 1, '0005','组装上电'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01',  6, 1, '0006','一次调试'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01',  7, 1, '0007','二次灌胶'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01',  8, 1, '0008','三次灌胶'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01',  9, 1, '0009','二次调试'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 10, 1, '0010','耐压检测'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 11, 1, '0011','特性检测'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 12, 1, '0012','外观检测'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 13, 1, '0013','附件检查'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 14, 1, '1001','三次调试'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 15, 1, '1002','电感准备'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 16, 1, '1003','导线/LED焊接'    );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 17, 1, '1004','一次灌胶'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 18, 1, '1005','线圈引线焊接'    );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 19, 1, '1006','刻调/调试'       );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 20, 1, '1007','预组镜架'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 21, 1, '1008','预组发射接收管'  );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 22, 1, '1009','热熔指示灯罩'    );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 23, 1, '1010','功能测试'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 24, 1, '1011','前塞灌胶'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 25, 1, 'I801','调试组装'        );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 26, 1, 'I802','组装'            );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 27, 1, 'IG01','准备'            );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 28, 1, 'JQ01','检测'            );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 29, 1, 'P000','包装完成转品质'  );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 30, 1, 'P999','返回完成品'      );
  INSERT INTO MFG_StationNoOrders (Factory, WorkGroup, LineCode, StationNoOrder, Status, StationNo, StationNoName) VALUES('1001','1001-01', '1001-01-01', 31, 1, 'Q999','QA出荷检查'      );   
 
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 141, 'VISIBLE',   '', '--');           --此处的VISIBLE是为了给用户可见而设定的一个过滤字
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 142, 'VISIBLE',  '0', '已计划');       --相当于SEND 0
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 143, '       ', 'S1', '已发行');       --相当于SEND 1   --此状态用不上
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 144, 'VISIBLE', 'S2', '备料中');       --相当于SEND 2   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 145, 'VISIBLE', 'S3', '备料完');       --相当于SEND 3   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 146, 'VISIBLE', 'S4', '已推送-待收');  --相当于SEND 4   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 147, 'VISIBLE', 'S5', '强制推送-待收');--相当于SEND 5   -----
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 148, 'VISIBLE', 'R1', '待收料');       --相当于RECV 1   -----
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 149, 'VISIBLE', 'R2', '收料中');       --相当于RECV 2   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 150, 'VISIBLE', 'R3', '收料完');       --相当于RECV 3   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 151, 'VISIBLE', 'R4', '结单');         --相当于RECV 4   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 152, 'VISIBLE', 'R5', '强制结单');     --相当于RECV 5
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 153, '',        '-1', '锁定');       
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORHD', 'Status', 154, '',        '-2', '删除'); 

  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 161, 'VISIBLE',   '', '--');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 162, 'VISIBLE',  '0', '已计划');  
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 163, '       ', 'S1', '已发行');       --相当于SEND 1   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 164, 'VISIBLE', 'S2', '备料中');       --相当于SEND 2   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 165, 'VISIBLE', 'S3', '备料完');       --相当于SEND 3   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 166, 'VISIBLE', 'S4', '已推送-待收');  --相当于SEND 4   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 167, 'VISIBLE', 'S5', '强制推送-待收');--相当于SEND 5   -----
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 168, 'VISIBLE', 'R1', '待收料');       --相当于RECV 1   -----
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 169, 'VISIBLE', 'R2', '收料中');       --相当于RECV 2   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 170, 'VISIBLE', 'R3', '收料完');       --相当于RECV 3   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 171, 'VISIBLE', 'R4', '结单');         --相当于RECV 4   
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 172, 'VISIBLE', 'R5', '强制结单');     --相当于RECV 5
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 173, '',        '-1', '锁定');       
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_ORLN', 'Status', 174, '',        '-2', '删除'); 
  
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_SEND', 'Status', 181, 'VISIBLE', '0',  '已计划');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_SEND', 'Status', 182, 'VISIBLE', '1',  '待备料');       --此状态用不上
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_SEND', 'Status', 183, 'VISIBLE', '2',  '备料中');       --此状态用不上(我们没有再次确认的过程)
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_SEND', 'Status', 184, 'VISIBLE', '3',  '备料完');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_SEND', 'Status', 185, 'VISIBLE', '4',  '已推送');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_SEND', 'Status', 186, 'VISIBLE', '5',  '强制推送');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_SEND', 'Status', 187, '',       '-1',  '锁定');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_SEND', 'Status', 188, '',       '-2',  '删除');
  
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_RECV', 'Status', 191, 'VISIBLE', '0',  '已计划');       --此状态用不上
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_RECV', 'Status', 192, 'VISIBLE', '1',  '待收料');       
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_RECV', 'Status', 193, 'VISIBLE', '2',  '收料中');       --此状态用不上(我们没有再次确认的过程)
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_RECV', 'Status', 194, 'VISIBLE', '3',  '收料完');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_RECV', 'Status', 195, 'VISIBLE', '4',  '已结单');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_RECV', 'Status', 196, 'VISIBLE', '5',  '强制结单');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_RECV', 'Status', 197, '',       '-1',  '锁定');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('MTL_RECV', 'Status', 198, '',       '-2',  '删除');

  --PP_2_MFG_Interface表的状态标志字的客户提示常量
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('P2M_FLAG', 'Flag',     1, 'VISIBLE',  '?', '新增,等待导入');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('P2M_FLAG', 'Flag',     2, 'VISIBLE',  'X', '异常,原因未知');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('P2M_FLAG', 'Flag',     3, 'VISIBLE',  'R', '复位,等待导入');  
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('P2M_FLAG', 'Flag',     4, 'VISIBLE',  '0', '导入准备');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('P2M_FLAG', 'Flag',     5, 'VISIBLE',  '2', '导入处理中');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('P2M_FLAG', 'Flag',     6, 'VISIBLE',  '4', '导入完成');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('P2M_FLAG', 'Flag',     7, 'VISIBLE',  'A', '异常,货号未知');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('P2M_FLAG', 'Flag',     8, 'VISIBLE',  'B', '异常,工位未知');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('P2M_FLAG', 'Flag',     9, 'VISIBLE',  'C', '异常,库存不足');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('P2M_FLAG', 'Flag',    10, 'VISIBLE',  'D', '异常,导入异常');
  
  --MFG_Station_MTL_Usage表的Status状态 
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('M2I_STAT', 'Status',   1, 'VISIBLE',  '0', '更新库存等待');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('M2I_STAT', 'Status',   2, 'VISIBLE',  '1', '更新库存开始');
  INSERT INTO MFG_ConstKeyLists (KeyType, KeyName, DisplayOrder, Attribute_0, KeyValue, KeyTip) VALUES('M2I_STAT', 'Status',   3, 'VISIBLE',  '2', '更新库存成功');
  
  --delete from UserM_Menu where ParentNo like '300[0,1,2,3,4]';
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3001', '基本设置', '3000', 0, 1, 'fa fa-cog fa-fw'            , ''  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3002', '生产配置', '3000', 0, 1, 'fa fa-cogs fa-fw'           , ''  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3003', '生产运营', '3000', 0, 1, 'fa fa-sun-o fa-fw'          , ''  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3004', '数据报告', '3000', 0, 1, 'fa fa-bar-chart fa-fw'      , ''  );

  -- 3001
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3101', '工厂设置', '3001', 0, 2, 'fa fa-sitemap fa-fw'        , '../Mfg/BaseConfig/SiteConfig.aspx'  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3102', '车间设置', '3001', 0, 2, 'fa fa-cogs fa-fw'           , '../Mfg/BaseConfig/GroupConfig.aspx' );

  -- 3002
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3201', '库房设置', '3002', 0, 2, 'fa fa-cubes fa-fw'          , '../Mfg/OperationConfig/WHCodeConfig.aspx'  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3202', '班次设置', '3002', 0, 2, 'fa fa-adjust fa-fw'         , '../Mfg/OperationConfig/ShiftCodeConfig.aspx' );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3203', '线别设置', '3002', 0, 2, 'fa fa-sliders fa-fw'        , '../Mfg/OperationConfig/LineCodeConfig.aspx'  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3204', '工位设置', '3002', 0, 2, 'fa fa-desktop fa-fw'        , '../Mfg/OperationConfig/StationNoConfig.aspx' );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3205', '审批流程', '3002', 0, 2, 'fa fa-cc fa-fw'             , ''  );

  --3003
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3301', '产品耗料', '3003', 0, 2, 'fa fa-object-group fa-fw'   , '../Mfg/Operation/StationMTLUsebase.aspx'  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3302', '计划排产', '3003', 0, 2, 'fa fa-book fa-fw'           , '../Mfg/Operation/ProductionPlan.aspx'  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3303', '发料计划', '3003', 0, 2, 'fa fa-adjust fa-fw'         , '../Mfg/Operation/MaterialPlan.aspx'  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3304', '线库发料', '3003', 0, 2, 'fa fa-shopping-cart fa-fw'  , '../Mfg/Operation/MtlTransPdr2Wip.aspx'  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3305', '产线收料', '3003', 0, 2, 'fa fa-shopping-bag fa-fw'   , '../Mfg/Operation/MtlTransPdr2Wip_Rec.aspx'  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3306', '产线急料', '3003', 0, 2, 'fa fa-bolt fa-fw'           , ''  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3307', '退料计划', '3003', 0, 2, 'fa fa-retweet fa-fw'        , ''  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3308', '线库补发', '3003', 0, 2, 'fa fa-certificate fa-fw'    , ''  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3309', '盘点申请', '3003', 0, 2, 'fa fa-book fa-fw'           , ''  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3310', '盘点审批', '3003', 0, 2, 'fa fa-thumbs-o-up fa-fw'    , ''  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3311', '盘点操作', '3003', 0, 2, 'fa fa-balance-scale fa-fw'  , '../Mfg/Operation/CCOperation.aspx'  );

  --3004
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3401', '发料查询', '3004', 0, 2, 'fa fa-adjust fa-fw'         , '../Mfg/Reporting/ProdPlanReport.aspx'  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3402', '库存查询', '3004', 0, 2, 'fa fa-book fa-fw'           , '../Mfg/Reporting/WHInvReport.aspx'  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3403', '产线退料', '3004', 0, 2, 'fa fa-retweet fa-fw'        , ''  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3404', '线库收料', '3004', 0, 2, 'fa fa-pencil-square-o fa-fw', ''  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3405', '产线耗料', '3004', 0, 2, 'fa fa-calendar-o fa-fw'     , '../Mfg/Reporting/P2MReport.aspx'  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3406', '线库汇总', '3004', 0, 2, 'fa fa-area-chart fa-fw'     , '../Mfg/Reporting/WHInvSnapshotReport.aspx'  );
  insert into UserM_Menu (MenuNo, MenuName, ParentNo, MenuTyp, MenuTag, Image1, MenuAddr)  values ('3407', '盘点查询', '3004', 0, 2, 'fa fa-gavel fa-fw'          , '../Mfg/Reporting/CycleCountReport.aspx'  );

  --delete from UserM_OperateInfo where MenuNo like '3%'
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('0049', '3001','生产计划','生产计划');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3101', '3101','工厂设置','工厂设置');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3102', '3102','车间设置','车间设置');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3201', '3201','库房设置','库房设置');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3202', '3202','班次设置','班次设置');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3203', '3203','线别设置','线别设置');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3204', '3204','工位设置','工位设置');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3205', '3205','审批流程','审批流程');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3301', '3301','产品耗料','产品耗料');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3302', '3302','计划排产','计划排产');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3303', '3303','发料计划','发料计划');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3304', '3304','发料查询','发料查询');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3305', '3305','库存查询','库存查询');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3306', '3306','产线急料','产线急料');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3307', '3307','退料计划','退料计划');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3308', '3308','线库补发','线库补发');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3309', '3309','盘点申请','盘点申请');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3310', '3310','盘点审批','盘点审批');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3311', '3311','盘点操作','盘点操作');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3401', '3401','线库发料','线库发料');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3402', '3402','产线接收','产线接收');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3403', '3403','产线退料','产线退料');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3404', '3404','线库收料','线库收料');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3405', '3405','产线耗料','产线耗料');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3406', '3406','线库汇总','线库汇总');
  insert into UserM_OperateInfo(OperateNo, MenuNo, OperateName, MenuName) values('3407', '3407','盘点查询','盘点查询');