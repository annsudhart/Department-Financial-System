/***************************************************************************************
Name      : BSO Financial Management Interface
License   : Copyright (C) 2018 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates Care Payment - Detailed Budget - Epic Inside Billed Table
***************************************************************************************/
USE [dw_db];
GO

IF OBJECT_ID('cpo.care_payment','U') IS NOT NULL
    DROP TABLE cpo.care_payment;
GO
IF OBJECT_ID('cpo.provider','U') IS NOT NULL
    DROP TABLE cpo.provider;
GO
IF OBJECT_ID('cpo.provider_type','U') IS NOT NULL
    DROP TABLE cpo.provider_type;
GO
IF OBJECT_ID('cpo.provider_type_group','U') IS NOT NULL
    DROP TABLE cpo.provider_type_group;
GO
IF OBJECT_ID('cpo.specialty','U') IS NOT NULL
    DROP TABLE cpo.specialty;
GO
IF OBJECT_ID('cpo.bill_area','U') IS NOT NULL
    DROP TABLE cpo.bill_area;
GO
IF OBJECT_ID('cpo.div','U') IS NOT NULL
    DROP TABLE cpo.div;
GO
IF OBJECT_ID('cpo.subdiv','U') IS NOT NULL
    DROP TABLE cpo.subdiv;
GO
IF OBJECT_ID('cpo.employee','U') IS NOT NULL
    DROP TABLE cpo.employee;
GO

CREATE TABLE cpo.provider
    (
        provider_id             CHAR(9)                         NOT NULL,
        provider_name           VARCHAR(35)                         NULL,
        createdby               NVARCHAR(255)                   NOT NULL    DEFAULT USER_NAME(),
        createddate             DATETIME2	                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        lastupdatedby           NVARCHAR(255)                       NULL,
        lastupdated             DATETIME2(2)                        NULL,
        rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL    DEFAULT NEWSEQUENTIALID(),
        versionnumber           ROWVERSION						NOT	NULL,
        validfrom               DATETIME2(2)                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        validto                 DATETIME2(2)                    NOT NULL    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT              PK_cpo_provider                 PRIMARY KEY CLUSTERED(provider_id)
    );
GO

CREATE TABLE cpo.provider_type_group
    (
        provider_type_group_id      INT                             NOT NULL    IDENTITY(1,1),
        provider_type_group_name    VARCHAR(35)                         NULL	UNIQUE,
        createdby                   NVARCHAR(255)                   NOT NULL    DEFAULT USER_NAME(),
        createddate                 DATETIME2	                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        lastupdatedby               NVARCHAR(255)                       NULL,
        lastupdated                 DATETIME2(2)                        NULL,
        rowguid                     UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL    DEFAULT NEWSEQUENTIALID(),
        versionnumber               ROWVERSION						NOT	NULL,
        validfrom                   DATETIME2(2)                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        validto                     DATETIME2(2)                    NOT NULL    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT                  PK_cpo_provider_type_group      PRIMARY KEY CLUSTERED(provider_type_group_id)
    );
GO

CREATE TABLE cpo.provider_type
    (
        provider_type_id        INT                             NOT NULL    IDENTITY(1,1),
        provider_type_group_id  INT                                 NULL,
        provider_type_name      VARCHAR(35)                         NULL	UNIQUE,
        createdby               NVARCHAR(255)                   NOT NULL    DEFAULT USER_NAME(),
        createddate             DATETIME2	                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        lastupdatedby           NVARCHAR(255)                       NULL,
        lastupdated             DATETIME2(2)                        NULL,
        rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL    DEFAULT NEWSEQUENTIALID(),
        versionnumber           ROWVERSION						NOT	NULL,
        validfrom               DATETIME2(2)                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        validto                 DATETIME2(2)                    NOT NULL    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT              PK_cpo_provider_type            PRIMARY KEY CLUSTERED(provider_type_id),
        CONSTRAINT              FK_cpo_provider_type_group      FOREIGN KEY (provider_type_group_id)    REFERENCES cpo.provider_type_group(provider_type_group_id)
    );
    CREATE INDEX I_cp_provider_type_group_id1   ON  cpo.provider_type(provider_type_group_id)
GO

CREATE TABLE cpo.specialty
    (
        specialty_id            INT                             NOT NULL    IDENTITY(1,1),
        specialty_name          VARCHAR(55)                         NULL	UNIQUE,
        createdby               NVARCHAR(255)                   NOT NULL    DEFAULT USER_NAME(),
        createddate             DATETIME2	                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        lastupdatedby           NVARCHAR(255)                       NULL,
        lastupdated             DATETIME2(2)                        NULL,
        rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL    DEFAULT NEWSEQUENTIALID(),
        versionnumber           ROWVERSION						NOT	NULL,
        validfrom               DATETIME2(2)                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        validto                 DATETIME2(2)                    NOT NULL    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT              PK_cpo_specialty                PRIMARY KEY CLUSTERED(specialty_id)
    );
GO

INSERT INTO cpo.specialty(specialty_name)
    VALUES('zUnknown / Other');
GO

CREATE TABLE cpo.bill_area
    (
        bill_area_id            INT                             NOT NULL,
        bill_area_name          VARCHAR(35)                         NULL,
        createdby               NVARCHAR(255)                   NOT NULL    DEFAULT USER_NAME(),
        createddate             DATETIME2	                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        lastupdatedby           NVARCHAR(255)                       NULL,
        lastupdated             DATETIME2(2)                        NULL,
        rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL    DEFAULT NEWSEQUENTIALID(),
        versionnumber           ROWVERSION						NOT	NULL,
        validfrom               DATETIME2(2)                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        validto                 DATETIME2(2)                    NOT NULL    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT              PK_cpo_bill_area                PRIMARY KEY CLUSTERED(bill_area_id)
    );
GO

CREATE TABLE cpo.div
    (
        div_id                  INT                             NOT NULL,
        div_name                VARCHAR(35)                         NULL,
        createdby               NVARCHAR(255)                   NOT NULL    DEFAULT USER_NAME(),
        createddate             DATETIME2	                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        lastupdatedby           NVARCHAR(255)                       NULL,
        lastupdated             DATETIME2(2)                        NULL,
        rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL    DEFAULT NEWSEQUENTIALID(),
        versionnumber           ROWVERSION						NOT	NULL,
        validfrom               DATETIME2(2)                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        validto                 DATETIME2(2)                    NOT NULL    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT              PK_cpo_div                      PRIMARY KEY CLUSTERED(div_id)
    );
GO

CREATE TABLE cpo.subdiv
    (
        subdiv_id               INT                             NOT NULL,
        subdiv_name             VARCHAR(35)                         NULL,
        createdby               NVARCHAR(255)                   NOT NULL    DEFAULT USER_NAME(),
        createddate             DATETIME2	                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        lastupdatedby           NVARCHAR(255)                       NULL,
        lastupdated             DATETIME2(2)                        NULL,
        rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL    DEFAULT NEWSEQUENTIALID(),
        versionnumber           ROWVERSION						NOT	NULL,
        validfrom               DATETIME2(2)                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        validto                 DATETIME2(2)                    NOT NULL    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT              PK_cpo_subdiv                   PRIMARY KEY CLUSTERED(subdiv_id)
    );
GO

CREATE TABLE cpo.employee
    (
        employee_id             VARCHAR(9)                      NOT NULL,
        employee_name           VARCHAR(35)                         NULL,
        createdby               NVARCHAR(255)                   NOT NULL    DEFAULT USER_NAME(),
        createddate             DATETIME2	                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        lastupdatedby           NVARCHAR(255)                       NULL,
        lastupdated             DATETIME2(2)                        NULL,
        rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL    DEFAULT NEWSEQUENTIALID(),
        versionnumber           ROWVERSION						NOT	NULL,
        validfrom               DATETIME2(2)                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        validto                 DATETIME2(2)                    NOT NULL    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT              PK_cpo_emp_id_mpi_id            PRIMARY KEY CLUSTERED(employee_id)
    );
GO

INSERT INTO cpo.employee(employee_id, employee_name)
    VALUES('ZZZZZZZZZ','zUnknown / Other');
GO

CREATE TABLE cpo.care_payment
    (
        care_payment_id         INT                             NOT NULL    IDENTITY(1,1),
        post_period             INT                             NOT NULL,
        effective_period        INT                             NOT NULL,
        bill_prov_id            CHAR(9)                             NULL,/*shared ID with serv_prov_id*/
        bill_prov_type_id       INT                                 NULL,/*shared ID with serv_prov_type_id*/
        bill_prov_specialty_id  INT                                 NULL    DEFAULT 1,/*shared ID with <multiple>*/
        serv_prov_id            CHAR(9)                             NULL,/*shared ID with bill_prov_id*/
        serv_prov_type_id       INT                                 NULL,/*shared ID with bill_prov_type_id*/
        bill_area_id            INT                                 NULL,/*done*/
        index_code              VARCHAR(10)                         NULL,
        pos_type_c              INT                                 NULL,
        pos_id                  DECIMAL(19,4)                   NOT NULL    DEFAULT 0,
        bill_area_speciality_id INT                                 NULL    DEFAULT 1,/*shared ID with <multiple>*/
        div_id                  INT                                 NULL,/*done*/
        subdiv_id               INT                                 NULL,/*done*/
        ser_median              DECIMAL(19,4)                       NULL,
        ba_median               DECIMAL(19,4)                       NULL,
        employee_id             VARCHAR(9)                          NULL,/*done*/
        asa                     DECIMAL(19,4)                   NOT NULL    DEFAULT 0,
        wrvu                    DECIMAL(19,4)                   NOT NULL    DEFAULT 0,
        derived_wrvu            DECIMAL(19,4)                   NOT NULL    DEFAULT 0,
        asa_payment             DECIMAL(19,4)                   NOT NULL    DEFAULT 0,
        wrvu_payment            DECIMAL(19,4)                   NOT NULL    DEFAULT 0,
        logic                   VARCHAR(10)                         NULL,
        rate_specialty_id       INT                                 NULL    DEFAULT 1,/*shared ID with <multiple>*/
        rate_used               DECIMAL(19,4)                   NOT NULL    DEFAULT 0,
		care_payment        DECIMAL(19,4)                   NOT NULL    DEFAULT 0,
        asa_care_payment        DECIMAL(19,4)                   NOT NULL    DEFAULT 0,
        wrvu_care_payment       DECIMAL(19,4)                   NOT NULL    DEFAULT 0,
        derived_care_payment    DECIMAL(19,4)                   NOT NULL    DEFAULT 0,
        non_wrvu_care_payment   DECIMAL(19,4)                   NOT NULL    DEFAULT 0,
        createdby               NVARCHAR(255)                   NOT NULL    DEFAULT USER_NAME(),
        createddate             DATETIME2	                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        lastupdatedby           NVARCHAR(255)                       NULL,
        lastupdated             DATETIME2(2)                        NULL,
        rowguid                 UNIQUEIDENTIFIER    ROWGUIDCOL  NOT NULL    DEFAULT NEWSEQUENTIALID(),
        versionnumber           ROWVERSION						NOT	NULL,
        validfrom               DATETIME2(2)                    NOT NULL    DEFAULT SYSUTCDATETIME(),
        validto                 DATETIME2(2)                    NOT NULL    DEFAULT CAST('9999-12-31 12:00:00' AS DATETIME2(2)),
        CONSTRAINT              PK_cpo_care_payment             PRIMARY KEY CLUSTERED(care_payment_id),
        CONSTRAINT              FK_cp_bill_prov_id              FOREIGN KEY (bill_prov_id)              REFERENCES cpo.provider(provider_id),
        CONSTRAINT              FK_cp_serv_prov_id              FOREIGN KEY (serv_prov_id)              REFERENCES cpo.provider(provider_id),
        CONSTRAINT              FK_cp_bill_prov_type_id         FOREIGN KEY (bill_prov_type_id)         REFERENCES cpo.provider_type(provider_type_id),
        CONSTRAINT              FK_cp_serv_prov_type_id         FOREIGN KEY (serv_prov_type_id)         REFERENCES cpo.provider_type(provider_type_id),
        CONSTRAINT              FK_cp_bill_prov_specialty_id    FOREIGN KEY (bill_prov_specialty_id)    REFERENCES cpo.specialty(specialty_id),
        CONSTRAINT              FK_cp_bill_area_specialty_id    FOREIGN KEY (bill_area_speciality_id)   REFERENCES cpo.specialty(specialty_id),
        CONSTRAINT              FK_cp_rate_specialty_id         FOREIGN KEY (rate_specialty_id)         REFERENCES cpo.specialty(specialty_id),
        CONSTRAINT              FK_cp_bill_area_id              FOREIGN KEY (bill_area_id)              REFERENCES cpo.bill_area(bill_area_id),
        CONSTRAINT              FK_cp_div_id                    FOREIGN KEY (div_id)                    REFERENCES cpo.div(div_id),
        CONSTRAINT              FK_cp_subdiv_id                 FOREIGN KEY (subdiv_id)                 REFERENCES cpo.subdiv(subdiv_id),
        CONSTRAINT              FK_cp_employee_id               FOREIGN KEY (employee_id)               REFERENCES cpo.employee(employee_id)
    )
    CREATE INDEX I_cp_post_period1              ON  cpo.care_payment(post_period)
    CREATE INDEX I_cp_effective_period1         ON  cpo.care_payment(effective_period)
    CREATE INDEX I_cp_bill_prov_id1             ON  cpo.care_payment(bill_prov_id)
    CREATE INDEX I_cp_bill_prov_type_id1        ON  cpo.care_payment(bill_prov_type_id)
    CREATE INDEX I_cp_bill_prov_specialty_id1   ON  cpo.care_payment(bill_prov_specialty_id)
    CREATE INDEX I_cp_serv_prov_id1             ON  cpo.care_payment(serv_prov_id)
    CREATE INDEX I_cp_serv_prov_type_id1        ON  cpo.care_payment(serv_prov_type_id)
    CREATE INDEX I_cp_bill_area_id1             ON  cpo.care_payment(bill_area_id)
    CREATE INDEX I_cp_index_code1               ON  cpo.care_payment(index_code)
    CREATE INDEX I_cp_bill_area_specialty_id1   ON  cpo.care_payment(bill_area_speciality_id)
    CREATE INDEX I_cp_div_id1                   ON  cpo.care_payment(div_id)
    CREATE INDEX I_cp_subdiv_id1                ON  cpo.care_payment(subdiv_id)
    CREATE INDEX I_cp_employee_id1              ON  cpo.care_payment(employee_id)
    CREATE INDEX I_cp_rate_specialty_id1        ON  cpo.care_payment(rate_specialty_id)
    ;
GO