USE [master]
GO

/****** Object:  LinkedServer [DW_DB]    Script Date: 02/06/2018 11:30:09 AM ******/
EXEC master.dbo.sp_addlinkedserver @server = N'DW_DB', @srvproduct=N'dw_db', @provider=N'MSDASQL', @datasrc=N'dw_db_p', @catalog=N'tcpip node db2actp remote hopper.ucsd.edu server 55000'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'DW_DB',@useself=N'False',@locallogin=NULL,@rmtuser=N'MDCMV1',@rmtpassword='########'
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'rpc', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'rpc out', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'connect timeout', @optvalue=N'99999'
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'use remote collation', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'DW_DB', @optname=N'remote proc transaction promotion', @optvalue=N'true'
GO


