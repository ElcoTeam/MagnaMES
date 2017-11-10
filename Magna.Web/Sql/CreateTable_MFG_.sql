
----  菜单列表
IF OBJECT_ID('UserM_Menu') is not null
DROP TABLE UserM_Menu;
CREATE TABLE [dbo].[UserM_Menu](
	[ID]                [int] IDENTITY(1,1)  NOT NULL,
	[MenuNo]            [varchar](10)        NOT NULL,    
	[MenuName]          [nvarchar](20)       NOT NULL,         
	[MenuAddr]          [varchar](100)           NULL,     
	[ParentNo]          [varchar](10)            NULL,           
	[MenuTag]           [varchar](1)             NULL,         
	[Image]             [varchar](100)           NULL
);

INSERT INTO UserM_Menu (MenuNo,MenuName,MenuAddr,ParentNo,MenuTag,Image)
VALUES 
(1000,N'系统设置',NULL,'0000','0',NULL),
(1100,N'用户管理',NULL,'1000','1',NULL),
(1200,N'角色管理',NULL,'1000','1',NULL),
(1300,N'部门管理',NULL,'1000','1',NULL)