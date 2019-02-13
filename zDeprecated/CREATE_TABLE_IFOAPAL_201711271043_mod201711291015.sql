PRINT '--ifoapal.account_group_class';
CREATE TABLE ifoapal.account_group_class
(
    account_class_id        NCHAR(1)                        NOT NULL,
    account_class_name      NVARCHAR(25)                        NULL,
    createdby               NVARCHAR(50)                    NOT NULL                                                    DEFAULT USER_NAME(),
    createddate             DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    lastupdatedby           NVARCHAR(50)                        NULL,
    lastupdated             DATETIME2(2)                        NULL,
    rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL                                                    DEFAULT NEWSEQUENTIALID(),
    versionnumber           ROWVERSION,
    validfrom               DATETIME2(2)                    NOT NULL                                                    DEFAULT SYSUTCDATETIME(),
    validto                 DATETIME2(2)                    NOT NULL                                                    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
    CONSTRAINT PK_ifoapal_accountgroupclass PRIMARY KEY CLUSTERED (account_class_id)
);
GO
INSERT INTO ifoapal.account_group_class (account_class_id,account_class_name) VALUES
    (N'5',N'Revenue'),
    (N'6',N'Expenditure'),
    (N'7',N'Transfer'),
    (N'8',N'Transfer'),
    (N'Z',N'--EMPTY--');
GO

ALTER TABLE ifoapal.account_group ADD
    account_class_id AS CONVERT(NCHAR(1),SUBSTRING(account_group_id,1,1)) PERSISTED 
    CONSTRAINT FK_ifoapal_accountgroup_accountgroupclass_accountclassid 
    FOREIGN KEY (account_class_id)
    REFERENCES ifoapal.account_group_class(account_class_id);
GO