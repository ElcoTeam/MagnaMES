--���Ի�����к�ֵ, �������Ҫȡ�õ����в�����, ���½���һ��, ��ֵ��1��ʼ, ����ǰ��8��'0'ֵ
--һ��˵��, ����ǰ���ַ���, �������к��벻Ҫ����12λ����.
ALTER PROCEDURE [dbo].[usp_Mes_getNewSerialNo]
    @SerialName     VARCHAR(50)  = '',  --���кŵ�ϵ������,
    @SerialPrefix   VARCHAR(5)   = '',  --���кŵ�ǰ���ַ�.һ�����, ������λ�ַ�����Ϊǰ����.
    @SerialLength   INT          = 12   --���к����峤��, ���Ѿ������������кų����е�ǰ������.���������12λ����
AS
    IF @SerialLength > 12 
    BEGIN
        SET @SerialLength  = 12;
    END
    --�ж����к��Լ���Ӧ��ǰ׺�Ƿ��Ѿ�����.
    IF 0 = ( SELECT COUNT(1)
             FROM MES_SerialNoPool
             WHERE
                 SerialName   = @SerialName
             AND SerialPrefix = @SerialPrefix )
    BEGIN
        --����һ������ǰ׺��ϵ�к�
        INSERT INTO MES_SerialNoPool (SerialName,  SerialPrefix, SerialNo)
                              VALUES(@SerialName, @SerialPrefix, 0);
    END

    --���»���ص�����, ����һ�����к�ֵ
    UPDATE MES_SerialNoPool
        SET SerialNo   = SerialNo + 1
           ,ModifyTime = GetDate()
    WHERE
            SerialName   = @SerialName
        AND SerialPrefix = @SerialPrefix;

    --�����µ����к�
    SELECT
        Upper(@SerialPrefix) + Right('00000000000' + Convert(VARCHAR, SerialNo), @SerialLength - LEN(@SerialPrefix)) AS SerialNo
    FROM MES_SerialNoPool
    WHERE
            SerialName   = @SerialName
        AND SerialPrefix = @SerialPrefix;
GO

--��֤Item�Ƿ���Ч
ALTER PROCEDURE usp_Mfg_CheckItemValid
    @VItem      NVARCHAR(50)    = ''  --��Ҫ��֤��Itemֵ
AS
    SELECT COUNT(1) SL FROM BAAN_ITEM WHERE Item = @VItem
GO


--��ȡ��λ���嵥
--ֻ���԰�������������, 
--Ŀ����Ϊ�˽������԰�StationNo����Ҫ����ά��, ������ֱ��ʹ�ò�Ʒ��Ҫ������rout�Ĺ�λ.
--���,ȡ��һ�����еİ취, �����40��ʹ�ù���ProcessCode��ȡ������ʹ�ü���.
ALTER PROCEDURE [dbo].[usp_Mfg_getStationList]
    @Factory    VARCHAR(15)     =  '',  --�������
    @WorkGroup  VARCHAR(15)     =  '',  --������
    @LineCode   VARCHAR(15)     =  '',  --���߱��
    @MItem      NVARCHAR(50)    = N''   --����(���Ϻ�)
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

--�������ĳ�ֻ���(��Ʒ,���Ʒ)��������ĳ����λ��ʹ�������ļ�¼ʵ��.
--����������Ŀ�����е���.
ALTER PROCEDURE usp_Mfg_insert_MUB_Records
    @Factory    VARCHAR(15)     =  '',  --�������
    @WorkGroup  VARCHAR(15)     =  '',  --������
    @MItem      NVARCHAR(50)    = N'',  --����(���Ϻ�)
    @WHCode     VARCHAR(15)     =  '',  --�ⷿ���
    @LineCode   VARCHAR(15)     =  '',  --���߱��
    @StationNo  VARCHAR(15)     =  '',  --��λ���
    @RountCode  VARCHAR(10)     =  '',  --���̱���
    @SItem      NVARCHAR(50)    = N'',  --��λ�����ϵ��Ϻ�
    @Qty        NUMERIC(18, 4)  =   0,  --��������
    @CreateUser NVARCHAR(50)    = N'',  --������
    @ModifyUser NVARCHAR(50)    = N''   --�����
AS
    INSERT INTO MFG_Station_MTL_UseBase ( Factory, WorkGroup, MItem, WHCode, LineCode, StationNo, RountCode, SItem, Qty, CreateUser, ModifyUser, CreateTime, ModifyTime, Status)
                                  VALUES(@Factory,@WorkGroup,@MItem,@WHCode,@LineCode,@StationNo,@RountCode,@SItem,@Qty,@CreateUser,@ModifyUser, GETDATE(),  GETDATE(),  N'0')
GO

--����ɾ��ĳ�ֻ���(��Ʒ,���Ʒ)��������ĳ����λ��ʹ�������ļ�¼.
--����������Ŀ�����е���.
ALTER PROCEDURE usp_Mfg_delete_MUB_Records
    @Factory    VARCHAR(15)     =  '',  --�������
    @WorkGroup  VARCHAR(15)     =  '',  --������
    @MItem      NVARCHAR(50)    = N'',  --����(���Ϻ�)
    @WHCode     VARCHAR(15)     =  '',  --�ⷿ���
    @LineCode   VARCHAR(15)     =  '',  --���߱��
    @StationNo  VARCHAR(15)     =  '',  --��λ���
    @RountCode  VARCHAR(10)     =  '',  --���̱���
    @SItem      NVARCHAR(50)    = N'',  --��λ�����ϵ��Ϻ�
    @Qty        NUMERIC(18, 4)  =   0   --��������
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

--������ɰѿⷿ������ݽ����ֶ����������ݼ�¼ʵ��.
--�˴洢���̽���������OnHand��Ŀ����.
--����������Ŀ�����е���.
ALTER PROCEDURE usp_Mfg_insert_MCC_Records
    @Factory    VARCHAR(15)     =  '',  --�������
    @WorkGroup  VARCHAR(15)     =  '',  --������
    @LineCode   VARCHAR(15)     =  '',  --���߱��
    @WHCode     VARCHAR(15)     =  '',  --�ⷿ���
    @OrderNo    VARCHAR(50)     =  '',  --���ӱ��
    @PONO       NUMERIC(6,0)    =   0,  --�к�λ��
    @Item       NVARCHAR(50)    = N'',  --�Ϻ�
    @AdvanceQty NUMERIC(18, 4)  =   0,  --��������������(������������)
    @CreateUser NVARCHAR(50)    = N''   --�����
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

--ȡ��ĳ���ŵ���δ����(��Ʒ����ģ���еķ������)���Ϻ��嵥
ALTER PROCEDURE [dbo].[usp_Mfg_getMubMainBomList]
    @Factory   VARCHAR(15)  = '',       --�������
    @WorkGroup VARCHAR(15)  = '',       --������
    @LineCode  VARCHAR(15)  = '',       --���߱��
    @MainItem  NVARCHAR(50) = N''       --���Ϻ�(����)
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

    --��ȡ���Ϻ�(����)�����Ϻ��嵥, ���뵽��ʱ����
    insert into #tmp_bom(ITEM, DSCA, QANA) exec [usp_Mfg_getBomUsingItemList] @MainItem

    --��ȡ�Ѿ�������ɵ��Ϻ��嵥
    insert into #tmp_mub(StationNo, SItem, Qty, Desca, StationNoName, CrTime) exec [usp_Mfg_getMubSelectedList]  @Factory, @WorkGroup, @LineCode, @MainItem

    --��ȡ��δ��ɷ�����Ϻ�,����ķ����Ƿ����ʱͨ���ж��������������Ѿ�����������������ж���.
    --��˸��ӵĲ����̵��ǿ��ǵ�: ��ͬ���Ϻ��п��ܱ����䵽�����λ, Ҫ����������������䵽�ദ.
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

--ȡ��(��Ʒ����ģ��)���Ѿ���õ��嵥 (MUB)
ALTER PROCEDURE [dbo].[usp_Mfg_getMubSelectedList]
    @Factory   VARCHAR(15)  = '',       --�������
    @WorkGroup VARCHAR(15)  = '',       --������
    @LineCode  VARCHAR(15)  = '',       --���߱��
    @MainItem  NVARCHAR(50) = N''       --���Ϻ�(����)
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


--�˴洢����Ŀǰ����Ŀ��û�б�ʹ��, ��ֻ��һ��������֤����, ������֤��BaaNϵͳ��ȡ���Ƿ��ʵ����ȷ���.
--BOM����չ���嵥��һֱչ��Ҷ�ڵ�Ϊֹ��
ALTER PROCEDURE [dbo].[usp_Mfg_getBomWholeTree]
    @ParentItem nvarchar(50) = '',      --���Ϻ�
    @ItemLevel  int          = 0        --��Ƴ���: չ�����Ĳ��, Ŀǰ�˲���δʹ��.
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


--չ����Ʒ�����嵥, ��ֵ������BOM��أ���͹����޹�.
ALTER PROCEDURE [dbo].[usp_Mfg_getBomUsingItemList]
    @ParentItem nvarchar(50) = '',      --���Ϻ�
    @ItemLevel  int          = 0        --��Ƴ���: չ�����Ĳ��, Ŀǰ�˲���δʹ��.
AS

    --���£�����Щ����չ��BOM�����ǵ���phantom�Ĵ��ڶ���Ҫ��չ�����Ĵ�������ε���
    --Ŀ����Ϊ�����ʵʩʱ����ʱ������phantom�ϣ���˵������������û�����������
    --��������Ѹ�ٵ����ϵͳ��ѯ�ٶȣ����û��ĸо���ˬˬ�ġ�

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

    --�������С�������Ϊ������ٶȶ���ʱ���õ�, �����Ч����Ҫ����ʵʩ�������֤
    SELECT
         SITM ITEM
        ,SDESC DSCA
        ,SUM(QANA) AS QANA
    FROM BAAN_BOM
    WHERE
            MITM = @ParentItem
        AND OPNO = '10'   --�����"10"����BaaNϵͳ��"����", ����չ��������, ����MES��������ʹ�ô˹������
        AND GETDATE() BETWEEN INDT AND EXDT
    GROUP BY SITM, SDESC

GO

--�û�¼��Ĺ�����������ģ��ƥ���ѯ�ó��������嵥������������������
--�˴洢�����е�TTISFC001100��Ӧ��PP_ScheduleForOrder(���̿���ģ����ֹ��ϴ�Excel�ļ����ݱ�)
ALTER PROCEDURE [dbo].[usp_Mfg_getXNumberEstimateMTL]
    @xNumber as nvarchar(50) = ''       --���Ż��߹�����, ϵͳ�������¼��ĳ����ж�Ϊ����, ��ֻ�Ա���������ݵ�ǰ9���ַ�, ������ַ�������
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
        and ICST.OPNO     = '10'  --�����"10"����BaaNϵͳ��"����", ����չ��������, ����MES��������ʹ�ô˹������
        and ICST.BFLS     = 1
GO

--��ȷ���ҵ��������ζ��ó��������嵥��Ŀ�������ݴ˽����Ϊ�ƻ����ϵ���
--�˴洢�����е�TTISFC001100��Ӧ��PP_ScheduleForOrder(���̿���ģ����ֹ��ϴ�Excel�ļ����ݱ�)
ALTER PROCEDURE [dbo].[usp_Mfg_getLotEstimateMTL]
    @LotNumber as nvarchar(50) = ''     --���κ���
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
        and ICST.OPNO     = '10'  --�����"10"����BaaNϵͳ��"����", ����չ��������, ����MES��������ʹ�ô˹������
    --  and ICST.BFLS     = 1     --"����"��־, BlackFlush, һ����Ϊ, ֻ�д˱�־ֵ��������Ҫ�ܿص�.
                                  --ע��:�˴�Ҫ�ʹ洢����: usp_Mfg_insert_MFG_Push_Plan ����һ��, һ��Ҫ��֤��ѯ������ͬ.
GO

--ģ�����Ҳ��г������嵥��Ŀ�������ݴ˽��׼�������ƻ����ϵ���
--��ģ��Ӧ����"�ƻ��Ų�"ģ��
ALTER PROCEDURE [dbo].[usp_Mfg_getLotOrderList]
   @OrderValue as nvarchar(50) = ''     --���Ż��߹�����, ϵͳ�������¼��ĳ����ж�Ϊ����, ��ֻ�Ա���������ݵ�ǰ9���ַ�, ������ַ�������
                                        --����û�¼�������Ϊ��, ��ϵͳ����PP_Lot��¼�ļƻ��������ڵ����30������ȫ���г�
AS
    SELECT
        PPLot.Lot,
        PPLot.OrderNo,
        PPLot.GoodsCode,
     -- ISNULL(ISFC.MITM,'--') GoodsCode, --Ϊ�˽��PPLot����洢��GoodsCode���Ȳ�������.
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

--ģ�����ҷ��ϵ���ͷ����Ϣ�б�Ŀ����׼�����ݴ˽�����һ������ƻ����ϵ���
ALTER PROCEDURE [dbo].[usp_Mfg_getMTLPlanHeads]
  @Factory      AS VARCHAR(15)          --�������
 ,@WorkGroup    AS VARCHAR(15)          --������
 ,@LineCode     AS VARCHAR(15)          --���߱��
 ,@OrderValue   AS NVARCHAR(50) = ''    --���Ż��߹�����, ϵͳ�������¼��ĳ����ж�Ϊ����, ��ֻ�Ա���������ݵ�ǰ9���ַ�, ������ַ�������
                                        --����û�¼�������Ϊ��, ��ϵͳ����PP_Lot��¼�ļƻ��������ڵ����60������ȫ���г�
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

--��ȷ�ҵ����ϵ���ͷ����Ϣ��
ALTER PROCEDURE [dbo].[usp_Mfg_getMTLPlanHead]
    @OrderValue   AS NVARCHAR(50) = ''  --���ϵ���
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

--�����ϸ�ķ��ϵ�����ϸ������Ϣ��
ALTER PROCEDURE [dbo].[usp_Mfg_getMTLPlanDetail]
     @Factory      AS VARCHAR(15)       --�������
    ,@WorkGroup    AS VARCHAR(15)       --������
    ,@LineCode     AS VARCHAR(15)       --���߱��
    ,@OrderValue   AS NVARCHAR(50) = '' --���ϵ���
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

--�����ϸ�������ߴ��ջ���Ϣ��
ALTER PROCEDURE [dbo].[usp_Mfg_getWIPRecMTLDetail]
     @Factory      AS VARCHAR(15)       --�������
    ,@WorkGroup    AS VARCHAR(15)       --������
    ,@LineCode     AS VARCHAR(15)       --���߱��
    ,@OrderValue   AS NVARCHAR(50) = '' --���ϵ���
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

--������μ��ӵļ�¼��
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

--����쳣���εļ�¼��
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


--����쳣���εļ�¼��
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


--�ֶ��������ϼƻ���Ŀ��Ϣ, ����MFG_Push_Plan_Detail��Ŀ����:
--������������: ADD, UPDATE, DELETE
--�����֮ǰ��Ҫ���鵥�ӵ�״̬.
ALTER PROCEDURE [dbo].[usp_Mfg_maintain_Push_Plan_Item]
     @Action       AS VARCHAR(50)           --��������: ADD_PUSH_PLAN_ITEM, UPD_PUSH_PLAN_ITEM, DEL_PUSH_PLAN_ITEM
    ,@Factory      AS VARCHAR(15)           --�������
    ,@WorkGroup    AS VARCHAR(15)           --������
    ,@LineCode     AS VARCHAR(15)           --���߱��
    ,@ModifyUser   AS NVARCHAR(50)          --�û�
    ,@OrderValue   AS NVARCHAR(50)          --���ϵ���
    ,@Item         AS VARCHAR(50)           --�Ϻ�
    ,@PlanQty      AS NUMERIC(18,4)         --����
    ,@CatchError   AS INT           OUTPUT  --ϵͳ�ж��û������쳣�Ĵ���
    ,@RtnMsg       AS NVARCHAR(100) OUTPUT  --����״̬
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
        SET @RtnMsg     = 'ϵͳ����ʶ������Ҫ���еĲ���!'
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
        SET @RtnMsg     = '��ȫ�����ϼƻ��嵥�У�δ���ҵ����Ӻ�: "' + @OrderValue + '"!'
        RETURN
    END

    if @OrderStatus<>0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '���ϼƻ���: "' + @OrderValue + '", ��ǰΪ���ɱ༭״̬.'
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
            SET @RtnMsg     = '�ڼƻ����ϵ����Ѿ����ڽ�Ҫ��������: "' + @Item + '"����ȷ��!'
            RETURN
        END
    END

    --�༭��ɾ������, �䶼Ҫ�жϵ���Ҫ���������Ƿ����, ���Ƿ��ڿ��Ա༭��״̬, ��˷���һ�����һ�����ж�
    IF @Action = 'UPD_PUSH_PLAN_ITEM' or @Action = 'DEL_PUSH_PLAN_ITEM'
    BEGIN 
        IF @nRowCount = 0
        BEGIN
            SET @CatchError = @CatchError + 1
            SET @RtnMsg     = '�ڼƻ����ϵ���û���ҵ���: "' + @Item + '"����ȷ��!'
            RETURN
        END

        IF @OrderStatus <> '0'
        BEGIN
            SET @CatchError = @CatchError + 1
            SET @RtnMsg     = '�ڼƻ����ϵ��е���: "' + @Item + '", ��ǰΪ���ɱ༭״̬!'
            RETURN
        END
    END

  --ǰ�����е��жϾ�ͨ��, ��ʼִ�����ݿ����
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
          AND ( Status = '0' )  --�˴���״̬�жϲ�����, ��ΪҪ��������
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
          AND ( Status = '0' )  --�˴���״̬�жϲ�����, ��ΪҪ��������
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

--Mfg_Insertϵ��(���Կ�ת����)�洢����֮һ: �ƻ�
--�����ƻ���������, �������ɱ�ͷ��Ϣ�ͱ�����Ϣ
ALTER PROCEDURE  [dbo].[usp_Mfg_insert_MFG_Push_Plan]
     @Factory      AS VARCHAR(15)          --�������
    ,@WorkGroup    AS VARCHAR(15)          --������
    ,@LineCode     AS VARCHAR(15)          --���߱��
    ,@LotNumber    AS NVARCHAR(50)         --���κ�, ���ϵ���
    ,@CreateUser   AS NVARCHAR(50)         --�û�
    ,@PlanShift    AS VARCHAR(4)  = 'RS'   --�ƻ����
    ,@SalesOrder   AS VARCHAR(15) = ''     --���۶���
    ,@CatchError   AS INT           OUTPUT --ϵͳ�ж��û������쳣������
    ,@RtnMsg       AS NVARCHAR(100) OUTPUT --����״̬
AS
    set @CatchError = 0
    set @RtnMsg     = ''
    IF (SELECT COUNT(1) FROM MFG_Push_Plan_Head WHERE TransferOrder=@LotNumber) > 0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '�ڼƻ����ϵ����Ѿ������д����ţ�' + @LotNumber + '!'
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
 -- AND ICST.BFLS     = 1           --ע��:�˴�Ҫ�ʹ洢����: usp_Mfg_getLotEstimateMTL ����һ��, һ��Ҫ��֤��ѯ������ͬ.
    RETURN
GO

--Mfg_Insertϵ��(���Կ�ת����)�洢����֮��: ����
--���뷢�ϼ�¼��������MFG_Push_Plan_Head��ͷ��MFG_Push_Plan_Detail����״̬��Ϣ
ALTER PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Issue]
     @Factory      AS VARCHAR(15)           --�������
    ,@WorkGroup    AS VARCHAR(15)           --������
    ,@LineCode     AS VARCHAR(15)           --���߱��
    ,@CreateUser   AS NVARCHAR(50)          --�û�
    ,@OrderValue   AS NVARCHAR(50)          --���ϵ���
    ,@PackageNo    AS VARCHAR(50)           --���ϰ�װ����
    ,@ScanItem     AS VARCHAR(50)           --ɨ��ķ����Ϻ�
    ,@ScanQty      AS NUMERIC(18,4)         --ɨ��ķ�������
    ,@CatchError   AS INT           OUTPUT  --ϵͳ�ж��û������쳣�Ĵ���
    ,@RtnMsg       AS NVARCHAR(100) OUTPUT  --����״̬
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
        SET @RtnMsg     = '���߱߿��ԭʼ��װ�嵥�У�δ���ҵ��˰�װ�ţ�' + @PackageNo + '!'
        RETURN
    END

    IF UPPER(@PackageItem) <> UPPER(@ScanItem)
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = 'ϵͳ������¼����Ϻź�ԭ��װ�ϺŲ�һ�£�' + @ScanItem + '!'
        RETURN
    END

    --�˴��������������
    SELECT @nRowCount   = COUNT(1)
         , @PlanPONO    = ISNULL(MAX(PONO),       0)
         , @PackageItem = ISNULL(MAX(Item),      '')
         , @PlanQty     = ISNULL(SUM(PlanQty),    0)
         , @OffsetQty   = ISNULL(SUM(OffsetQty),  0)  --ʱ���ϵ��û�г�ֶԵ��������Ľ��п��ǣ��˴�д����������Ϊ�˷����պ�ʹ��
         , @PushedQty   = ISNULL(SUM(@PushedQty), 0)  --�ѷ��������ô˴�, Ŀ�����в�ͬ��װ��, ���һ�η��ϵ�������
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
        SET @RtnMsg     = '�ƻ����ϵ���û���ҵ���Ҫ���͵��ϣ���ȷ���Ƿ��Ѿ����������˻��߱����Ӹ�������Ҫ���ʹ��ϣ�'
        RETURN
    END
    ELSE
    BEGIN
        IF @RequestQty <= 0.0
        BEGIN
            SET @CatchError = @CatchError + 1
            SET @RtnMsg     = '��ȷ���Ƿ��Ѿ����������ˣ����������ٱ����ϣ�'
            RETURN
        END
    END

    SELECT
         @PackageLeftQty = @PackageQty - ISNULL(SUM(Qty), 0)
    FROM [dbo].[MFG_Inv_Trans_From]  --WITH (HOLDLOCK)
    WHERE
          ORIDCK    = @PackageNo  --�˴����������ƵĹ�������Ϊ�п���һ��ԭ���ϱ����͵����ȥ��
      AND Factory   = @Factory
      AND WorkGroup = @WorkGroup

    IF @PackageLeftQty < @ScanQty
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '��װ����ʣ�಻�㣬��¼��������Ѿ�����ʣ��������!'
        RETURN
    END

 --ִ�����ݿ�������

    BEGIN TRANSACTION

    --�˴��ڿ����Ƿ�������Ա�ֻ֤�����һ����¼, ��������(����)ʱ�ľͿ��Ա���ʹ��ʱ���ʾ�����ظ���¼�ı궨
    --������ô��ֽ���,��ôҲ��������Ϲ����г���(�Լ�����ͬ��)�����������޶�����.
    --��:������10 + 20 , ����һ��25��,�൱��������������,������ٲ��Ͻ���,Ҳ����ν��.
    --BaaN���ǲ���ֻ��һ����¼��ʵ�ַ�ʽ, ������û�а�װ��, ����߼��Ͽ��Է����ʵ��.
    INSERT INTO MFG_Inv_Trans_From
           ( Factory,  WorkGroup,  WHCode,             ORIDCK,     transferOrder,  PONO,       ITEM,      QTY,      CreateUser,  Status, Operate)
    VALUES (@Factory, @WorkGroup, @LineCode + '-XBK', @PackageNo, @OrderValue,    @PlanPONO,  @ScanItem, @ScanQty, @CreateUser,  '3',    'XBK_2_WIP' )
    --�˴������굥�����ÿһ������, û�й���Ĳ���(���ٴ�ȷ��֮�������), �����״̬���Ǽ�¼���.
    --�����ֵ��ƻ����״̬��һ��һ��

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
      AND ( Status = '0' OR Status = 'S1' OR Status = 'S2' )  --�˴���S2״̬������, ��ΪҪ��������

    --�ҳ�δ�����ϵ���������
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

--�˴�����Ա�����ȫ�����ϵļ��, Ȼ���Զ�����ͷ��ļ�¼״̬.
--�˴��Ŀͻ���Ҳ�������жϺ͸����ͻ����Զ���ʾ.
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

--Mfg_Insertϵ��(���Կ�ת����)�洢����֮��: ����
--ɾ�����ϼ�¼��������MFG_Push_Plan_Head��ͷ��MFG_Push_Plan_Detail����״̬��Ϣ
ALTER PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Revert]
    @Factory      AS VARCHAR(15)            --�������
   ,@WorkGroup    AS VARCHAR(15)            --������
   ,@LineCode     AS VARCHAR(15)            --���߱��
   ,@CreateUser   AS NVARCHAR(50)           --�û�
   ,@OrderValue   AS NVARCHAR(50)           --���ϵ���
   ,@PackageNo    AS VARCHAR(50)            --���ϰ�װ����
   ,@ScanItem     AS VARCHAR(50)            --ɨ��ķ����Ϻ�
   ,@ScanQty      AS NUMERIC(18,4)          --ɨ��ķ�������
   ,@CatchError   AS INT           OUTPUT   --ϵͳ�ж��û������쳣�Ĵ���
   ,@RtnMsg       AS NVARCHAR(100) OUTPUT   --����״̬
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
        SET @RtnMsg     = '���߱߿��ԭʼ��װ�嵥�У�δ���ҵ��˰�װ�ţ�' + @PackageNo + '!'
        RETURN
    END

    IF UPPER(@PackageItem) <> UPPER(@ScanItem)
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = 'ϵͳ������¼����Ϻź�ԭ��װ�ϺŲ�һ�£�' + @ScanItem + '!'
        RETURN
    END

    --�˴��������������
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
      --�˴������Ż��Ŀռ�:
      --Ϊ�˸��û�������, ���ǿ���ֻ���û�����һ��"����"��ť, ���¼Ҿ��յ������, ����Ҳ���Գ���
      --���ճ���, ������Ҫ���Ǹ��ı�ǹ���, ��Ҫֱ��ɾ��(Ŀ���Ǳ�����־)
      --ʱ���ϵ, �˴��Ȳ����Ǵ��־��ճ������

    IF @nRowCount = 0
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = '���ѷ��͵��嵥��û���ҵ���Ҫ���ص���!(��ʾ:��˶Գ��������Ƿ���ȷ?)'
        RETURN
    END

 --ִ�����ݿ�ɾ������
    BEGIN TRANSACTION

        DELETE FROM [MFG_Inv_Trans_From] WHERE ID = @MAXID;

       --�˴��Ѿ����ǵ�ͬһ�����ȱ�С����, �󱸴�����, Ȼ���С��������ʱ�ı�Ǹ������.
       --�ڱ���ʱ, ���ҿͻ���ϵͳ���������Ƿ��Ѿ������״��, Ҳ�Ѿ��������Զ���ʾ����,

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

--Mfg_Insertϵ��(���Կ�ת����)�洢����֮��: ����
--���ͷ��ϲ�����������MFG_Push_Plan_Head��ͷ��MFG_Push_Plan_Detail����״̬��Ϣ
--���뵽�����ձ��¼, �����¿���¼��, ���������������
ALTER PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Deliver]
    @Factory      AS VARCHAR(15)            --�������
   ,@WorkGroup    AS VARCHAR(15)            --������
   ,@LineCode     AS VARCHAR(15)            --���߱��
   ,@CreateUser   AS NVARCHAR(50)           --�û�
   ,@OrderValue   AS NVARCHAR(50)           --���ϵ���
   ,@ForceFlag    AS VARCHAR(50)            --��Ƴ���:ǿ�����ͱ�־, �˱�־Ŀǰû��ʹ��, ���Ƿ�ǿ��, ������ϵͳ�Լ��ж϶���.
   ,@CatchError   AS INT           OUTPUT   --ϵͳ�ж��û������쳣�Ĵ���
   ,@RtnMsg       AS NVARCHAR(100) OUTPUT   --����״̬
AS
    SET @CatchError = 0
    SET @RtnMsg     = 'OK'

    DECLARE @nRowCount   AS INTEGER
    DECLARE @ForceString AS VARCHAR(40)

    DECLARE @RECITEM AS VARCHAR(50)
    DECLARE @RECQTY  AS NUMERIC(18,4)

    SET @ForceFlag = 1 --�˴������������û�������ѡ��. ���ǵ��еĵ����ǲ���Ҫ���ϵ�(�յ����),Ҳ��Ҫǿ�ƽᵥ.

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
        SET @RtnMsg     = '�����ҵ���¼��ķ���״̬�����κţ�' + @OrderValue + '!'
        RETURN
    END

  --ִ�����ݿ����
  --�˴��������������
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

--Mfg_Insertϵ��(���Կ�ת����)�洢����֮��: ����
--��ɽ��ղ�����������MFG_Push_Plan_Head��ͷ��MFG_Push_Plan_Detail����״̬��Ϣ
ALTER PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Receive]
    @Factory      AS VARCHAR(15)            --�������
   ,@WorkGroup    AS VARCHAR(15)            --������
   ,@LineCode     AS VARCHAR(15)            --���߱��
   ,@CreateUser   AS NVARCHAR(50)           --�û�
   ,@OrderValue   AS NVARCHAR(50)           --���ϵ���
   ,@PackageNo    AS VARCHAR(50)            --���ϰ�װ����
   ,@ScanItem     AS VARCHAR(50)            --ɨ��ķ����Ϻ�
   ,@ScanQty      AS NUMERIC(18,4)          --ɨ��ķ�������
   ,@CatchError   AS INT           OUTPUT   --ϵͳ�ж��û������쳣�Ĵ���
   ,@RtnMsg       AS NVARCHAR(100) OUTPUT   --����״̬
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
        SET @RtnMsg     = '��ԭʼ��װ�嵥�У�δ���ҵ��˰�װ�ţ�' + @PackageNo + '!'
        RETURN
    END

    IF UPPER(@PackageItem) <> UPPER(@ScanItem)
    BEGIN
        SET @CatchError = @CatchError + 1
        SET @RtnMsg     = 'ϵͳ������¼����Ϻź�ԭ��װ�ϺŲ�һ�£�' + @ScanItem + '!'
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
        SET @RtnMsg     = 'ϵͳ�Ӵ������嵥��û���ҵ���������! ��ʾ:��˶�¼��������Ƿ���ȷ���ߴ����Ѿ��������?'
        RETURN
    END

 --ִ�����ݿ���²���

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


--Mfg_Insertϵ��(���Կ�ת����)�洢����֮��: �ᵥ
--��ɽᵥ������������MFG_Push_Plan_Head��ͷ��MFG_Push_Plan_Detail����״̬��Ϣ
--���¿���¼��, ���������������, ������Ӧ����������
ALTER PROCEDURE [dbo].[usp_Mfg_insert_MFG_Push_Close]
     @Factory      AS VARCHAR(15)            --�������
    ,@WorkGroup    AS VARCHAR(15)            --������
    ,@LineCode     AS VARCHAR(15)            --���߱��
    ,@CreateUser   AS NVARCHAR(50)           --�û�
    ,@OrderValue   AS NVARCHAR(50)           --���ϵ���
    ,@ForceFlag    AS VARCHAR(50)            --��Ƴ���:ǿ�ƽᵥ��־, �˱�־Ŀǰû��ʹ��, ���Ƿ�ǿ��, ������ϵͳ�Լ��ж϶���.
    ,@CatchError   AS INT           OUTPUT   --ϵͳ�ж��û������쳣�Ĵ���
    ,@RtnMsg       AS NVARCHAR(100) OUTPUT   --����״̬
AS
    SET @CatchError = 0
    SET @RtnMsg     = 'OK'

    DECLARE @nRowCount   AS INTEGER
    DECLARE @ForceString AS VARCHAR(40)

    DECLARE @RECITEM AS VARCHAR(50)
    DECLARE @RECQTY  AS NUMERIC(18,4)


    SET @ForceFlag = 1 --�˴������������û�������ѡ��. ���ǵ��еĵ����ǲ���Ҫ���ϵ�(�յ����),Ҳ��Ҫǿ�ƽᵥ.

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
        SET @RtnMsg     = '�����ҵ���¼��Ŀ��Խᵥ�����κţ�' + @OrderValue + '! ��ʾ:��ȷ�ϴ˵��ĵ�ǰ״̬.'
        RETURN
    END

  --ִ�����ݿ����
  --�˴��������������
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

    --���һ���Ƿ���ǿ�ƽᵥ����Ŀ
    SELECT @nRowCount   = COUNT(1)
    FROM [MFG_Inv_Trans_To]
    WHERE
          Factory       = @Factory
      AND WorkGroup     = @WorkGroup
      AND WHCode        = @LineCode
      AND TransferOrder = @OrderValue
      AND ( Status = 'R5' )

    --���û�з���ǿ�ƽᵥ����Ŀ,����Ϊ�����еı�ͷ���Ծ�����һ���������ᵥ��.
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

--ɾ���ƻ����ϵ�, Ӧ����"���ϼƻ�"����ģ���"ɾ��"����
ALTER PROCEDURE  [dbo].[usp_Mfg_delete_MFG_Push_Plan]
    @Factory      AS VARCHAR(15)        --�������
   ,@WorkGroup    AS VARCHAR(15)        --������
   ,@LineCode     AS VARCHAR(15)        --���߱��
   ,@OrderNumber  AS NVARCHAR(50)       --���ϵ���
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

--�߱߿ⷢ�Ϲ����л�ð�װ���ϵ��������, �������û��Ѿ����ܶ���йش˰�װ����ʾ��Ϣ.
--�˴洢���̿��Է��غ��������ֶεļ�¼, ���ֶ�Ϊ: KeyTip, KeyName, KeyValue
--�ͻ���ʹ��KeyName��Ϊ�ؼ��ֽ�����Ҫ�����ݲ�ѯ����, ��: LeftQty
--Ϊ�û���Ϊ��ʾ��Ϣ��KeyTip�����������.
ALTER PROCEDURE usp_Mfg_getPackageNumberInfo
    @PackageNo  VARCHAR(50) = ''        --���ϰ�װ��
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

              SELECT '��װ�Ϻ�' AS KeyTip,  'Item' AS KeyName,  @ITEM AS KeyValue
    UNION ALL SELECT 'ʣ������',            'LeftQty',          CONVERT(VARCHAR(50), @LeftQty)
    UNION ALL SELECT '��װ����',            'PackageQty',       CONVERT(VARCHAR(50), @PackageQty)
    UNION ALL SELECT '�ѷ�����',            'IssuedQty',        CONVERT(VARCHAR(50), @IssuedQty)
    UNION ALL SELECT '�������',            'SpliteTimes',      CONVERT(VARCHAR(50), @SplitTimes)
    UNION ALL SELECT '�����̺�',            'VendorCode',       CONVERT(VARCHAR(50), @VendorCode)
    UNION ALL SELECT '��������',            'ProductDate',      CONVERT(VARCHAR(50), @ProductDate)
    UNION ALL SELECT '���ϵ���',            'SLLDCode',         CONVERT(VARCHAR(50), @SLLDCode)
    UNION ALL SELECT '����Ա��',            'InputManName',     CONVERT(VARCHAR(50), @InputManName)
    UNION ALL SELECT '��������',            'InputTime',        CONVERT(VARCHAR(50), FORMAT(@InputTime,'yyyy-MM-dd hh:mm:ss'))
GO

--��������ֵ, �ؼ���ֵ, ȡ����Ҫ��ʾ���û�����ʾ�ַ���
--��ֵ�洢�ڳ������ݱ�:MFG_ConstKeyLists��.
ALTER PROCEDURE usp_Mfg_getStatusValueTips
@KeyType   AS VARCHAR(15) = '',         --��������(Ҳ�������Ϊ������)
@keyName   AS VARCHAR(15) = '',         --��������(Ҳ�������Ϊ����ϵ��)
@Attribute AS VARCHAR(50) = ''          --��������(�������Ϊ�޶�����)
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


--Mfg_PPData ϵ��֮һ: PP_2_MFG�ӿڼ�¼״̬����
--����PP_2_MFG_Interface�Ľӿڶ����, �������쳣֮������ñ�־, �ȴ���һ���ڽ����ٴ���Ļ���.
ALTER PROCEDURE usp_Mfg_PPData_Reset
    @Factory    VARCHAR(15)     =  '',  --�������
    @WorkGroup  VARCHAR(15)     =  '',  --������
    @MItem      NVARCHAR(50)    = N'',  --����(���Ϻ�)
    @WHCode     VARCHAR(15)     =  '',  --�ⷿ���
    @LineCode   VARCHAR(15)     =  ''   --���߱��
AS
    -- ���û�в���, ��ȫ��������ļ�¼����λ�ȴ���һ���ڽ��д���.
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

--Mfg_PPData ϵ��֮��: PP_2_MFG���ݵ���MFG
--��PP_2_MFG_Interface�ӿ�ģ�鵼������, ����Ҫ���µ������߿�������׼����.
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
        --ȡ�ýӿ�ԭʼ�Ľӿ�����
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

        --Ƕ��������ƽ��, Ƕ���߼�ת��Ϊ˳����, ���Ա����������.
        --�˴�ҲҪ�ж�, Ŀ���ǿ��Խ�������ʵ��������Է���Ľ���˳�����.
        IF @ValidFlag > 0
        BEGIN
            --�趨��ʼ�����־
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
                AND ( FLAG = '?' OR FLAG ='R' );  --�˴�������������ʡ��, ���Ա�����ʵ������һ����־
        END

        IF @ValidFlag > 0
        BEGIN
            --�����Ƿ��д�GoodsCodeģ��(MUB)����ֵ
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
            --�����Ƿ��д�Stationģ��(MUB)����ֵ
            SELECT
                @ValidFlag = COUNT(1)
            FROM
                MFG_Station_MTL_UseBase
            WHERE
                    Factory   = @Factory
                AND WorkGroup = @WorkGroup
                AND LineCode  = @LineCode
                AND MItem     = @GoodsCode
                AND StationNo = @StationNo;  --2017-02-17: ����һ��©��, 
                                             -- ����Ϊ���ܹ���ȷ����, �Ѵ����������ȥ����.
                                             -- ������ֻҪ�д˻��ŵ�����, ��ȫ�������趨Ϊ�������. 
                                             -- ����, ������Ĺ������д���������, ���û�жԿ����ɻ���.

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
            --ȡ�õ��Ӻ�, �˴��Ĵ���������. ��SQL Server���ݿ��ʵ��ֻ�����, Ŀǰû�и��õİ취.
            CREATE TABLE #TT (PPSerialNo NVARCHAR(50));
            INSERT INTO #TT EXEC usp_Mes_getNewSerialNo 'PP2MFG', 'P2M', 12;
            SELECT @TransferOrder = PPSerialNo FROM #TT;
            DROP TABLE #TT;

            --��ʽ���нӿ����ݵĵ���
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

            --���½ӿڱ��־�Լ�����ʱ��.
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

--Mfg_PPData ϵ��֮��: MFG���¿��
--����Ҫ���µ������߿��׼���õ�����, ����ʵ�ʵĸ��µ����߿�����
--(ʱ���ϵ: ����û�жԸ��������κδ���, ��: ʵ�ʻ�����������������.
ALTER PROCEDURE usp_Mfg_PPData_Update_Inv
AS
    DECLARE @Factory       AS VARCHAR(15);
    DECLARE @WorkGroup     AS VARCHAR(15);
    DECLARE @WHCode        AS VARCHAR(15);
    DECLARE @TransferOrder AS NVARCHAR(50);

    --��MFG_Station_MTL_Usage���е��������������ϵ����ݵ��뵽����MFG_Inv_Data��.
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

--������������, Ŀ�������ݸ������������ۺϲ�ѯ���ϵ��������
ALTER PROCEDURE [dbo].[usp_Mfg_rptOrderList]
   @Factory   AS VARCHAR(15)  = '',     --�������
   @WorkGroup AS VARCHAR(15)  = '',     --������
   @LineCode  AS VARCHAR(15)  = '',     --���߱��
   @FromDate  AS DateTime     = '',     --��ʼʱ��
   @ToDate    AS DateTime     = '',     --����ʱ��
   @KeyStatus AS VARCHAR(15)  = '',     --״̬��
   @KeyType   AS VARCHAR(15)  = '',     --��ѯ�ؼ�������(�ֶ�����)
   @KeyValue  AS NVARCHAR(50) = ''      --�ؼ���ֵ
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

--������������, Ŀ���ǲ�ѯ���ĸ�����ʹ��ָ�����Ϻ��Լ�����巢�������
ALTER PROCEDURE [dbo].[usp_Mfg_rptUsesLines]
   @Factory    AS VARCHAR(15)  = '',    --�������
   @WorkGroup  AS VARCHAR(15)  = '',    --������
   @LineCode   AS VARCHAR(15)  = '',    --���߱��
   @FromDate   AS DateTime     = '',    --��ʼʱ��
   @ToDate     AS DateTime     = '',    --����ʱ��
   @KeyStatus  AS VARCHAR(15)  = '',    --״̬��
   @ItemValue  AS NVARCHAR(50) = ''     --�Ϻ�
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

--������������, Ŀ���ǲ�ѯ��ָ�����ξ��巢�������
ALTER PROCEDURE [dbo].[usp_Mfg_rptTransLines]
   @Factory   AS VARCHAR(15)  = '',     --�������
   @WorkGroup AS VARCHAR(15)  = '',     --������
   @LineCode  AS VARCHAR(15)  = '',     --���߱��
   @FromDate  AS DateTime     = '',     --��ʼʱ��
   @ToDate    AS DateTime     = '',     --����ʱ��
   @KeyStatus AS VARCHAR(15)  = '',     --״̬��
   @TransKeyType   AS  VARCHAR(50) = '',--��ѯ�ؼ�������(TransferOrder��ORIDCK, ��������)
   @TransKeyValue  AS NVARCHAR(50) = '' --��ѯ�ؼ���ֵ

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

--������������, Ŀ���ǲ�ѯ����������
ALTER PROCEDURE [dbo].[usp_Mfg_rptWHInventoryList]
   @Factory    AS VARCHAR(15)  = '',    --�������
   @WorkGroup  AS VARCHAR(15)  = '',    --������
   @LineCode   AS VARCHAR(15)  = '',    --���߱��
   @ItemValue  AS NVARCHAR(50) = ''     --�Ϻ�
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

--������������, ���ڲ�ѯ�̵��¼�����е��ӵĵ��Ӻ�, �������Ϊ��, ��Ĭ�ϲ�ѯ�������ļ�¼, ����ʱ�������˳�򷵻ء�
ALTER PROCEDURE [dbo].[usp_Mfg_rptMCCOrdersList]
   @Factory   AS VARCHAR(15)  = '',     --�������
   @WorkGroup AS VARCHAR(15)  = '',     --������
   @LineCode  AS VARCHAR(15)  = '',     --���߱��
   @ItemValue AS NVARCHAR(50) = ''      --�Ϻ�
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

--������������, ���ڲ�ѯ�̵��¼��ĳ�����ӺŶ�Ӧ���̵��ϵ���ϸ��Ϣ, ����ITEM��˳�򷵻ء�
ALTER PROCEDURE [dbo].[usp_Mfg_rptMCCItemsList]
   @TransferOrder  AS NVARCHAR(50) = '' --�̵�ƱƱ��
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

--���Բ��Ҵ�'���̿���'���ݵ�����'�����ƻ�'ģ��Ľӿ����ݲ�ѯ
ALTER PROCEDURE usp_Mfg_rptP2MInterfaceList
    @Factory   AS VARCHAR(15)  =  '',   --�������
    @WorkGroup AS VARCHAR(15)  =  '',   --������
    @LineCode  AS VARCHAR(15)  =  '',   --���߱��
    @StationNo AS VARCHAR(15)  =  '',   --��λ����
    @FromDate  AS DateTime     =  '',   --��ʼʱ��
    @ToDate    AS DateTime     =  '',   --����ʱ��
    @KeyStatus AS VARCHAR(15)  =  '',   --״̬��
    @KeyType   AS VARCHAR(50)  =  '',   --��������(GoodsNumber, LotNumber, �����޶�)
    @KeyValue  AS NVARCHAR(50) = N''    --����ֵ
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


--������������, ���Բ��Ҵ�'���̿���'���ݵ�����'�����ƻ�'ģ��ӿڻ������,
--���������뵽���߿���е��м���ת��MFG_Station_MTL_Usage, ���ǻ���MUBģ���л������, �ȴ����¿��.
ALTER PROCEDURE usp_Mfg_rptM2IDetailList
    @Factory   AS VARCHAR(15)  =  '',   --�������
    @WorkGroup AS VARCHAR(15)  =  '',   --������
    @LineCode  AS VARCHAR(15)  =  '',   --���߱��
    @StationNo AS VARCHAR(15)  =  '',   --��λ���
    @FromDate  AS DateTime     =  '',   --��ʼʱ��
    @ToDate    AS DateTime     =  '',   --����ʱ��
    @KeyStatus AS VARCHAR(15)  =  '',   --״̬��
    @KeyType   AS VARCHAR(50)  =  '',   --��������(MItem, SItem, LotNumber ���������)
    @KeyValue  AS NVARCHAR(50) = N''    --����ֵ
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

--������������, ���Բ��Ҵ���ʷ��������еó����߿������, ��Ҫ��������ͼ��,
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

    --��ȡ��Ҫ��ѯ���ݵ����ڻ�׼, ��: ��������category
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
        
        --��ȡ��Ҫ��ʾ���߱�����ƺͶ�Ӧ�Ŀ�������ֶ�,��: ��������series
        SELECT @SQL1 = @SQL1 
        + ',''' + @LineCodeName + '''' 
        + ',ISNULL(' + @LineAlias + '.SQTY, 0)';

        --��ʾ����Ҫ��ѯ������Դ, ��:����߱�Ľ�������ͳ�Ʋ����׼����������
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

--���Ա��������ݵĿ���.
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

--Ϊ��Ӧ��ʵʩ������, ����Ĳ�Ʒ��������, �ش�д��һ����ʱ����:
--�������ֻҪû�м����Ļ���,����Զ��ѳ���"QA����"��λ�Զ�����������,
--��:Ŀǰ�������ϵ��������Ƕ���Ϊ����"����"��λ���ĵ�.
ALTER PROCEDURE usp_Mfg_insert_MUB_Automatic
AS
    CREATE TABLE #tmp_StationList(
        [Factory]       VARCHAR  (15)   NOT NULL DEFAULT ('1001'),        --����
        [WorkGroup]     VARCHAR  (15)   NOT NULL DEFAULT ('1001-01'),     --ҵ����
        [WHCode]        VARCHAR  (15)   NOT NULL DEFAULT ('1001-01-01'),  --�ⷿ���
        [LineCode]      VARCHAR  (15)   NOT NULL DEFAULT ('1001-01-01'),  --����������
        [StationNo]     VARCHAR  (15)   NOT NULL,                         --����վ����, ���� Info_Process.ProcessCode
        [RountCode]     CHAR     (4)    NOT NULL,                         --��Ʒ��;���, ���� Info_Rount.RountCode
        [MItem]         NVARCHAR (50)   NOT NULL,                         --���Ϻ�
        [SItem]         NVARCHAR (50)   NOT NULL DEFAULT ('NA'),          --�Ϻ�
        [Qty]           NUMERIC  (18,4) NOT NULL DEFAULT 0.0001,          --��̨��Ʒ��վ��������
        [CreateTime]    DATETIME        NOT NULL DEFAULT GETDATE(),       --����ʱ��
        [CreateUser]    NVARCHAR (50)   NOT NULL DEFAULT ('SYSTEM'),      --�����û�
        [ModifyTime]    DATETIME        NOT NULL DEFAULT GETDATE(),       --����ʱ��
        [ModifyUser]    NVARCHAR (50)   NOT NULL DEFAULT ('SYSTEM'),      --�����û�
        [Status]        NVARCHAR (2)    NOT NULL DEFAULT ('0')            --�м�¼״̬��־  0: ����; ����ֻ�д�һ����־ֵ 
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
    LEFT JOIN MFG_Station_MTL_UseBase mub on tmp.MItem = mub.MItem --�˴������趨ֻ��һ������,Ŀ����ֻҪĳ�ֻ����趨�˺�������, �����ڲ��ľ��幤λϸ�������Զ�����.
    where mub.SItem is null;

    IF @@ROWCOUNT>0 
    BEGIN
      EXEC usp_Mfg_PPData_Reset;  
    END

    DROP TABLE #tmp_StationList;    
GO