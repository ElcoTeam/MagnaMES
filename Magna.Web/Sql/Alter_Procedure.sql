--用以获得序列号值, 如果当下要取得的序列不存在, 则新建立一个, 其值从1开始, 并且前导8个'0'值
--一般说来, 加入前导字符后, 整体序列号码不要超出12位长度.
ALTER PROCEDURE [dbo].[usp_Mes_getNewSerialNo]
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

--验证Item是否有效
ALTER PROCEDURE usp_Mfg_CheckItemValid
    @VItem      NVARCHAR(50)    = ''  --需要验证的Item值
AS
    SELECT COUNT(1) SL FROM BAAN_ITEM WHERE Item = @VItem
GO


--获取工位号清单
--只所以把这个功能提出来, 
--目的是为了将来可以把StationNo不需要单独维护, 设想其直接使用产品需要经过的rout的工位.
--最后,取了一个折中的办法, 把最近40天使用过的ProcessCode提取出来供使用即可.
ALTER PROCEDURE [dbo].[usp_Mfg_getStationList]
    @Factory    VARCHAR(15)     =  '',  --工厂编号
    @WorkGroup  VARCHAR(15)     =  '',  --车间编号
    @LineCode   VARCHAR(15)     =  '',  --产线编号
    @MItem      NVARCHAR(50)    = N''   --货号(主料号)
AS
    SELECT 
        StationNo, StationNoName 
    FROM MFG_StationNoOrders 
    WHERE 
        Factory   = @Factory   
    and WorkGroup = @WorkGroup 
    and LineCode  = @LineCode
    and StationNo in
    (
        SELECT DISTINCT processcode
        FROM [dbo].[Info_Rount] RR
        WHERE RR.WorkGroup IN ( 
          SELECT DISTINCT workgroup
          from [dbo].[Info_Rount] A, [Info_ModelName] B
          WHERE A.WorkGroup = B.Rount
             and createtime > getdate()-90
        )
    ) 
    ORDER BY 
    StationNoOrder  
GO

--用以添加某种货号(产品,半成品)的物料在某个工位的使用数量的记录实现.
--其它数据项目不进行调整.
ALTER PROCEDURE usp_Mfg_insert_MUB_Records
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
ALTER PROCEDURE usp_Mfg_delete_MUB_Records
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
ALTER PROCEDURE usp_Mfg_insert_MCC_Records
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
ALTER PROCEDURE [dbo].[usp_Mfg_getMubMainBomList]
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
    insert into #tmp_mub(StationNo, SItem, Qty, Desca, StationNoName, CrTime) exec [usp_Mfg_getMubSelectedList]  @Factory, @WorkGroup, @LineCode, @MainItem

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
ALTER PROCEDURE [dbo].[usp_Mfg_getMubSelectedList]
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
ALTER PROCEDURE [dbo].[usp_Mfg_getBomWholeTree]
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
ALTER PROCEDURE [dbo].[usp_Mfg_getBomUsingItemList]
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
ALTER PROCEDURE [dbo].[usp_Mfg_getXNumberEstimateMTL]
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
ALTER PROCEDURE [dbo].[usp_Mfg_getLotEstimateMTL]
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
ALTER PROCEDURE [dbo].[usp_Mfg_getLotOrderList]
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
ALTER PROCEDURE [dbo].[usp_Mfg_getMTLPlanHeads]
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
ALTER PROCEDURE [dbo].[usp_Mfg_getMTLPlanHead]
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
ALTER PROCEDURE [dbo].[usp_Mfg_getMTLPlanDetail]
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
ALTER PROCEDURE [dbo].[usp_Mfg_getWIPRecMTLDetail]
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

--获得批次监视的记录。
ALTER PROCEDURE [dbo].[usp_Mfg_getLotMonitorList]
     @FromDate     AS DATETIME
    ,@ToDate       AS DATETIME
AS

    SELECT 
         BASELIST.LOT
        ,BASELIST.GoodsCode
        ,BASELIST.Qty
        ,SUMLIST.MaxInTime
        ,SUMLIST.MinInTime
        ,SUMLIST.OpCounts 
        ,MTLBILLLIST.MTLBillStatus
    FROM
    (
    SELECT
        LOT       LOT
       ,ModelCode GoodsCode
       ,InQty     Qty
    FROM [dbo].[PP_LOTRT]
    WHERE 
          Intime BETWEEN @FromDate AND @ToDate
      AND OutTime IS NULL
    ) AS BASELIST

    LEFT JOIN
    (
      SELECT 
           LOT
          ,MIN(INTIME) MinInTime
          ,Max(INTIME) MaxInTime
          ,SUM(1) OpCounts
     FROM
         [dbo].[PP_LOTRT]
     WHERE 
         Intime <= @ToDate 
     GROUP BY LOT
     ) AS SUMLIST ON BASELIST.LOT = SUMLIST.LOT

    LEFT JOIN
    (SELECT PO.LOT, POTIP.KeyTip MTLBillStatus
     FROM [MFG_Push_Plan_Head] PO, [MFG_ConstKeyLists] POTIP
     WHERE PO.Status = POTIP.KeyValue
           AND POTIP.KeyType = 'MTL_ORHD'
     ) AS MTLBILLLIST ON BASELIST.LOT = MTLBILLLIST.LOT
     ORDER BY MaxInTime, LOT
GO

--获得异常批次的记录。
ALTER PROCEDURE [dbo].[usp_Mfg_getLotExceptionList]
     @FromDate     AS DATETIME
    ,@ToDate       AS DATETIME
AS
    SELECT 
      PlanList.LOT LOT
    , PlanList.GoodsCode GoodsCode
    , PlanList.ModelCode ModelCode 
    , PlanList.PlanQty PlanQty
    , MIN(PlanList.PlanStartTime) PlanStartTime
    , MAX(PlanList.PlanFinishTime) PlanFinishTime
    , PlanList.RountType RountType
    , PlanList.RountStepQty RountStepQty
    , SUM(1) OperateStepQty
    , MIN(CASE WHEN LineRecord.OutTime IS NULL THEN 0 ELSE 1 END) ExceptFlag
FROM 
      PP_LOTRT LineRecord
      ,(
        SELECT 
              Info_Process.ProcessCode
            , Info_Process.ProcessName
            , Info_Rount.WorkGroup RountType
            , CONVERT(INT, Info_Rount.RountCode) RountOrder
        FROM  
          Info_Process 
        , Info_Rount
        WHERE
          Info_Process.ProcessCode = Info_Rount.ProcessCode
     ) AS ProcessList
    ,(
        SELECT 
              OrderList.Orderno
            , FORMAT(OrderList.PlanStartTime,  'yyyy-MM-dd') PlanStartTime
            , FORMAT(OrderList.PlanFinishTime, 'yyyy-MM-dd') PlanFinishTime
            , OrderList.RountType
            , OrderList.RountStepQty
            , LotList.Lot LOT
            , LotList.InQty PlanQty
            , LotList.GoodsCode GoodsCode
            , LotList.ModelCode ModelCode
        FROM PP_Lot LotList
        ,(
            SELECT 
                  ScheduleList.OrderNo
                , ScheduleList.RountType
                , ScheduleList.PlanStartTime
                , ScheduleList.PlanFinishTime
                , RountStep.RountStepQty
            FROM
            (
                SELECT 
                      OrderNo
                    , MAX(OrderFlag) + '00' RountType
                    , MIN(ProDate) as PlanFinishTime
                    , MAX(Bpro_Date) PlanStartTime 
                FROM [PP_ScheduleForOrder] 
                GROUP BY OrderNo  
            ) ScheduleList
            , 
            (
                SELECT 
                      WorkGroup AS RountType
                    , SUM(1) as RountStepQty 
                FROM
                [Info_Rount]
                GROUP BY 
                     WorkGroup
            ) RountStep
            WHERE ScheduleList.RountType = RountStep.RountType
        ) AS OrderList
        WHERE LotList.OrderNo = OrderList.OrderNo
    ) AS PlanList
WHERE 
        PlanList.PlanStartTime >= @FromDate 
    AND PlanList.PlanStartTime <= @ToDate
    AND LineRecord.LOT          = PlanList.LOT
    AND PlanList.RountType      = ProcessList.RountType
    AND LineRecord.ProcessCode  = ProcessList.ProcessCode
 GROUP BY
      PlanList.Lot
    , PlanList.GoodsCode
    , PlanList.ModelCode
    , PlanList.RountType
    , PlanList.RountStepQty
    , PlanList.PlanQty
 HAVING 
     SUM(1) < PlanList.RountStepQty
  OR MIN(CASE WHEN LineRecord.OutTime IS NULL THEN 0 ELSE 1 END) = 0
 ORDER BY
      PlanList.Lot
    , PlanList.PlanQty
    , PlanList.RountStepQty
GO


--获得异常批次的记录。
ALTER PROCEDURE [dbo].[usp_Mfg_getLotDetailList]
     @Lot          AS VARCHAR(50)
    ,@FromDate     AS DATETIME
    ,@ToDate       AS DATETIME
AS
    SELECT 
      LineRecord.*,
      Info_Process.ProcessName
FROM 
      PP_LOTRT LineRecord,
      Info_Process            
WHERE 
    (
        (   
            @LOT = LOT
        )
        OR 
        (
            @Lot = '' 
        AND LineRecord.InTime  >= @FromDate 
        AND LineRecord.OutTime <= @ToDate            
        )
    )
    AND
    LineRecord.ProcessCode = Info_Process.ProcessCode 
 ORDER BY
      Lot
    , Intime
GO


--手动调整发料计划条目信息, 更新MFG_Push_Plan_Detail条目数据:
--操作动作包括: ADD, UPDATE, DELETE
--其操作之前需要检验单子的状态.
ALTER PROCEDURE [dbo].[usp_Mfg_maintain_Push_Plan_Item]
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
ALTER PROCEDURE  [dbo].[usp_Mfg_insert_MFG_Push_Plan]
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
ALTER PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Issue]
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
ALTER PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Revert]
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
ALTER PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Deliver]
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
ALTER PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Receive]
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
ALTER PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Close]
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
ALTER PROCEDURE  [dbo].[usp_Mfg_delete_MFG_Push_Plan]
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
ALTER PROCEDURE usp_Mfg_getPackageNumberInfo
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
ALTER PROCEDURE usp_Mfg_getStatusValueTips
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
ALTER PROCEDURE usp_Mfg_PPData_Reset
    @Factory    VARCHAR(15)     =  '',  --工厂编号
    @WorkGroup  VARCHAR(15)     =  '',  --车间编号
    @MItem      NVARCHAR(50)    = N'',  --货号(主料号)
    @WHCode     VARCHAR(15)     =  '',  --库房编号
    @LineCode   VARCHAR(15)     =  ''   --产线编号
AS
    -- 如果没有参数, 则全体有问题的记录都复位等待下一周期进行处理.
    IF @Factory = ''
    BEGIN
        UPDATE PP_2_MFG_Interface
        SET Flag        = 'R'
           ,Attribute_5 = 'MFG Reset:' + CONVERT(VARCHAR, GETDATE(),121)
        WHERE
            Flag = 'A'
         OR Flag = 'B'
         OR Flag = 'C'
     END
     ELSE
     BEGIN
        UPDATE PP_2_MFG_Interface
        SET Flag        = 'R'
           ,Attribute_5 = 'MFG Reset:' + CONVERT(VARCHAR, GETDATE(),121)
        WHERE
         (  
               Flag = 'A'
            OR Flag = 'B'
            OR Flag = 'C'
         )
         AND Factory   = @Factory
         AND WorkGroup = @WorkGroup
         AND LineCode  = @LineCode
         AND WHCode    = @WHCode
         AND GoodsCode = @MItem;
     END
GO

--Mfg_PPData 系列之二: PP_2_MFG数据导入MFG
--从PP_2_MFG_Interface接口模块导入数据, 把需要更新到生产线库存的数据准备好.
ALTER PROCEDURE usp_Mfg_PPData_Import
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
                   ,OutputTime  = CASE 
                                     WHEN FLAG='?' THEN GETDATE() 
                                     WHEN FLAG='R' THEN OutputTime 
                                  END
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
                AND MItem     = @GoodsCode
                AND StationNo = @StationNo;  --2017-02-17: 发现一个漏洞, 
                                             -- 当初为了能够精确报警, 把此条件错误的去掉了.
                                             -- 导致了只要有此货号的配置, 即全部都会设定为处理完成. 
                                             -- 好在, 处理库存的过程中有此条件限制, 因此没有对库存造成混乱.

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
ALTER PROCEDURE usp_Mfg_PPData_Update_Inv
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
ALTER PROCEDURE [dbo].[usp_Mfg_rptOrderList]
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
        PPlan.CreateTime between @FromDate and @ToDate + 1
    AND (ISNULL(PPlan.Status, '') = @KeyStatus or @KeyStatus = '')
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
ALTER PROCEDURE [dbo].[usp_Mfg_rptUsesLines]
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
        PPlan.CreateTime between @FromDate and @ToDate + 1
    AND (PPlan.Status= @KeyStatus or @KeyStatus = '')
    AND (PItem.Item  = @ItemValue or @ItemValue = '' )
    AND
    (
            (ISNULL(LCO.Factory,   '') = @Factory   or @Factory   = '' )
        AND (ISNULL(LCO.WorkGroup, '') = @WorkGroup or @WorkGroup = '' )
        AND (ISNULL(LCO.LineCode,  '') = @LineCode  or @LineCode  = '' )
    )
    ORDER BY LotCreateTime
GO

--用于制作报告, 目的是查询出指定批次具体发料情况。
ALTER PROCEDURE [dbo].[usp_Mfg_rptTransLines]
   @Factory   AS VARCHAR(15)  = '',     --工厂编号
   @WorkGroup AS VARCHAR(15)  = '',     --车间编号
   @LineCode  AS VARCHAR(15)  = '',     --产线编号
   @FromDate  AS DateTime     = '',     --开始时间
   @ToDate    AS DateTime     = '',     --结束时间
   @KeyStatus AS VARCHAR(15)  = '',     --状态码
   @TransKeyType   AS  VARCHAR(50) = '',--查询关键字类型(TransferOrder或ORIDCK, 空则不限制)
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
        FF.CreateTime BETWEEN @FromDate AND @ToDate + 1
    AND (FF.Status = @KeyStatus or @KeyStatus = '')
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
ALTER PROCEDURE [dbo].[usp_Mfg_rptWHInventoryList]
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
ALTER PROCEDURE [dbo].[usp_Mfg_rptMCCOrdersList]
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
ALTER PROCEDURE [dbo].[usp_Mfg_rptMCCItemsList]
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
ALTER PROCEDURE usp_Mfg_rptP2MInterfaceList
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
    AND (P2M.Flag      = @KeyStatus or @KeyStatus = '' )
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
ALTER PROCEDURE usp_Mfg_rptM2IDetailList
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
    AND (M2I.Status    = @KeyStatus or @KeyStatus = '' )
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
ALTER PROCEDURE usp_Mfg_rptInvSnapShot
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

    CREATE TABLE #TMP_SNAPSHOTDATA( CATE VARCHAR(18)); 

    --获取需要查询数据的日期基准, 即: 获得坐标的category
    WHILE @nDayCount <8 
    BEGIN
        INSERT INTO #TMP_SNAPSHOTDATA(CATE) VALUES(  CONVERT(VARCHAR, GETDATE() - @nDayCount, 102) );
        SELECT @nDayCount = @nDayCount + 1
    END

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
            + '   SELECT CONVERT(VARCHAR, INV.SnapTime-1, 102) DDATE ' 
            + '       ,SUM(OnHandQty + OrderQty - AllocateQty) SQTY '
            + '   FROM MFG_Inv_Data_Snapshot AS INV '
            + '   WHERE '
            + '         INV.SnapTime BETWEEN GETDATE() - ' + CONVERT(VARCHAR, @nDayCount) + ' AND GETDATE() '
            + '     AND INV.Factory  =''' + @Factory   + ''' ' 
            + '     AND INV.WorkGroup=''' + @WorkGroup + ''' ' 
            + '     AND INV.WHCode   =''' + @LineCode  + ''' '
            + '     GROUP BY CONVERT(VARCHAR, INV.SnapTime-1, 102) '
            + ' UNION ALL '
            + '   SELECT CONVERT(VARCHAR, GETDATE(), 102) DDATE ' 
            + '       ,SUM(OnHandQty + OrderQty - AllocateQty) SQTY '
            + '   FROM MFG_Inv_Data AS INV '
            + '   WHERE '
            + '         INV.Factory  =''' + @Factory   + ''' ' 
            + '     AND INV.WorkGroup=''' + @WorkGroup + ''' ' 
            + '     AND INV.WHCode   =''' + @LineCode  + ''' '
            + ' ) AS ' + @LineAlias + ' ON ' + @LineAlias + '.DDATE = BCATE.CATE ';

            FETCH NEXT FROM cursor_Line INTO @Factory, @WorkGroup, @LineCode, @LineCodeName;
            SELECT @nLineCount = @nLineCount + 1;
        END

    SELECT @SQL0 = ' SELECT BCATE.CATE ' + @SQL1 
                 + ' FROM #TMP_SNAPSHOTDATA BCATE ' + @SQL2 
                 + ' ORDER BY BCATE.CATE ;'

    EXEC ( @SQL0 );
    DROP TABLE #TMP_SNAPSHOTDATA;    

    CLOSE cursor_Line;
    DEALLOCATE cursor_Line;   
GO

--用以保存库存数据的快照.
ALTER PROCEDURE usp_Mfg_SnapShot_Mfg_Inv_Data
AS
    INSERT INTO MFG_Inv_Data_Snapshot 
    (      Factory, WorkGroup, WHCode, ITEM, OnhandQty, BlockQty, OrderQty, AllocateQty, SnapTime,  Status )
    SELECT Factory, WorkGroup, WHCode, ITEM, OnhandQty, BlockQty, OrderQty, AllocateQty, getdate(), Status
    FROM
    MFG_Inv_Data
    where NOT EXISTS(
        SELECT 1
        FROM [dbo].[MFG_Inv_Data_Snapshot]
        WHERE DATEDIFF(dd, SnapTime, GETDATE()) = 0
    )
GO

--为了应对实施过程中, 过多的产品耗料配置, 特此写了一个临时工具:
--可以完成只要没有见过的货号,则会自动把除了"QA出荷"工位自动加入虚拟料,
--即:目前所有物料的消耗我们都认为是在"出荷"工位消耗的.
ALTER PROCEDURE usp_Mfg_insert_MUB_Automatic
AS
    CREATE TABLE #tmp_StationList(
        [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('1001'),        --工厂
        [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('1001-01'),     --业务部门
        [WHCode]        VARCHAR  (15)   NOT NULL DEFAULT ('1001-01-01'),  --库房编号
        [LineCode]      VARCHAR  (15)   NOT NULL DEFAULT ('1001-01-01'),  --生产线名称
        [StationNo]     VARCHAR  (15)   NOT NULL,                         --工作站名称, 引用 Info_Process.ProcessCode
        [RountCode]     CHAR     (4)    NOT NULL,                         --产品制途编号, 引用 Info_Rount.RountCode
        [MItem]         NVARCHAR (50)   NOT NULL,                         --主料号
        [SItem]         NVARCHAR (50)   NOT NULL DEFAULT ('NA'),          --料号
        [Qty]           NUMERIC  (18,4) NOT NULL DEFAULT 0.0001,          --单台产品此站用料数量
        [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),       --创建时间
        [CreateUser]    NVARCHAR (50)   NOT NULL DEFAULT ('SYSTEM'),      --创建用户
        [ModifyTime]    DATETIME        NOT NULL DEFAULT GETDATE(),       --更新时间
        [ModifyUser]    NVARCHAR (50)   NOT NULL DEFAULT ('SYSTEM'),      --更新用户
        [Status]        NVARCHAR (2)    NOT NULL DEFAULT ('0')            --行记录状态标志  0: 新增; 当下只有此一个标志值 
     )

    INSERT INTO #tmp_StationList(StationNo, RountCode, MItem)
    SELECT StationNo, StationNo, MItem
    FROM
    (SELECT DISTINCT GOODSCODE AS MItem
     FROM PP_2_MFG_Interface ) AA
    ,
    (
         SELECT DISTINCT processcode AS StationNo
         FROM [dbo].[Info_Rount] RR
         WHERE RR.WorkGroup IN ( 
           SELECT DISTINCT workgroup
           from [dbo].[Info_Rount] A, [Info_ModelName] B
           WHERE A.WorkGroup = B.Rount
         --     and createtime > getdate()-198
         )
         AND processcode NOT IN ('Q999')
    ) BB

    INSERT INTO MFG_Station_MTL_UseBase (
        [Factory]   ,
        [WorkGroup] ,
        [WHCode]    ,
        [LineCode]  ,
        [StationNo] ,
        [RountCode] ,
        [MItem]     ,
        [SItem]     ,
        [Qty]       ,
        [CreateTime],
        [CreateUser],
        [ModifyTime],
        [ModifyUser],
        [Status]     
    )
    SELECT 
        TMP.[Factory]   ,
        TMP.[WorkGroup] ,
        TMP.[WHCode]    ,
        TMP.[LineCode]  ,
        TMP.[StationNo] ,
        TMP.[RountCode] ,
        TMP.[MItem]     ,
        TMP.[SItem]     ,
        TMP.[Qty]       ,
        TMP.[CreateTime],
        TMP.[CreateUser],
        TMP.[ModifyTime],
        TMP.[ModifyUser],
        TMP.[Status]      
    FROM 
    #tmp_StationList TMP
    LEFT JOIN MFG_Station_MTL_UseBase mub on tmp.MItem = mub.MItem --此处故意设定只有一个条件,目的是只要某种货号设定了耗料条件, 则其内部的具体工位细节则不再自动补足.
    where mub.SItem is null;

    IF @@ROWCOUNT>0 
    BEGIN
      EXEC usp_Mfg_PPData_Reset;  
    END

    DROP TABLE #tmp_StationList;    
GO