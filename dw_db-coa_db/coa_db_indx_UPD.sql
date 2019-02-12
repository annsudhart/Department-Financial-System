/***************************************************************************************
Name      : Medicine Financial System - COA_DB Schema
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Updates coa_db.indx
****************************************************************************************
PREREQUISITES:
- coa_db_TABLES Execution
- Error Handling
***************************************************************************************/

/*  GENERAL CONFIGURATION AND SETUP ***************************************************/
PRINT '** General Configuration & Setup';
/*  Change database context to the specified database in SQL Server. 
    https://docs.microsoft.com/en-us/sql/t-sql/language-elements/use-transact-sql */
USE dw_db;
GO

/*  Specify ISO compliant behavior of the Equals (=) and Not Equal To (<>) comparison
    operators when they are used with null values.
    https://docs.microsoft.com/en-us/sql/t-sql/statements/set-ansi-nulls-transact-sql
    -   When SET ANSI_NULLS is ON, a SELECT statement that uses WHERE column_name = NULL 
        returns zero rows even if there are null values in column_name. A SELECT 
        statement that uses WHERE column_name <> NULL returns zero rows even if there 
        are nonnull values in column_name. 
    -   When SET ANSI_NULLS is OFF, the Equals (=) and Not Equal To (<>) comparison 
        operators do not follow the ISO standard. A SELECT statement that uses WHERE 
        column_name = NULL returns the rows that have null values in column_name. A 
        SELECT statement that uses WHERE column_name <> NULL returns the rows that 
        have nonnull values in the column. Also, a SELECT statement that uses WHERE 
        column_name <> XYZ_value returns all rows that are not XYZ_value and that are 
        not NULL. */
SET ANSI_NULLS ON;
GO

/*  Causes SQL Server to follow  ISO rules regarding quotation mark identifiers &
    literal strings.
    https://docs.microsoft.com/en-us/sql/t-sql/statements/set-quoted-identifier-transact-sql
    -   When SET QUOTED_IDENTIFIER is ON, identifiers can be delimited by double 
        quotation marks, and literals must be delimited by single quotation marks. When 
        SET QUOTED_IDENTIFIER is OFF, identifiers cannot be quoted and must follow all 
        Transact-SQL rules for identifiers. */
SET QUOTED_IDENTIFIER ON;
GO

/*  VALIDATION & CLEANUP **************************************************************/
IF OBJECT_ID('coa_db.indx') IS NULL RETURN;
GO

IF OBJECT_ID('coa_db.indx_UPD','P') IS NOT NULL DROP PROCEDURE coa_db.indx_UPD;
GO

/*  PROCEDURE CREATION ****************************************************************/
PRINT '** CREATE PROCEDURE';
GO
CREATE PROCEDURE    coa_db.indx_UPD
                    AS
                    BEGIN
                        BEGIN TRY
                            DECLARE         @lastActivityDate AS DATE;
                            DECLARE         @lastRefreshDate AS DATE;
                            DECLARE         @cutoffDate_Activity AS DATE;
                            DECLARE         @cutoffDate_Refresh AS DATETIME2(7);
                            DECLARE         @recordCount AS INT = 0;

                            SELECT @recordCount = COUNT(*) FROM coa_db.indx;

                            IF @recordCount > 0
                            BEGIN
                                SELECT @lastActivityDate = MAX(d.last_activity_date) FROM coa_db.indx AS d;
                                SELECT @lastRefreshDate = CAST(MAX(d.refresh_date) AS DATE) FROM coa_db.indx AS d;

                                IF @lastActivityDate < @lastRefreshDate SET @lastRefreshDate = @lastActivityDate;
                                IF @lastActivityDate > @lastRefreshDate SET @lastActivityDate = @lastRefreshDate;
                                SET @cutoffDate_Activity = @lastActivityDate;
                                SET @cutoffDate_Refresh = CAST(@lastRefreshDate AS DATETIME2(7));

                                DELETE FROM coa_db.indx WHERE   coa_db.indx.last_activity_date >= @cutoffDate_Activity
                                                                OR coa_db.indx.refresh_date >= @cutoffDate_Refresh;

                                UPDATE  i
                                SET     i.indx_key = dw.indx_key,
                                        i.indx = dw.indx,
                                        i.most_recent_flag = dw.most_recent_flag,
                                        i.start_effective_date = dw.start_effective_date,
                                        i.end_effective_date = dw.end_effective_date,
                                        i.last_activity_date = dw.last_activity_date,
                                        i.[status] = dw.[status],
                                        i.indx_title = dw.indx_title,
                                        i.fund = dw.fund,
                                        i.fund_title = dw.fund_title,
                                        i.organization = dw.organization,
                                        i.organization_title = dw.organization_title,
                                        i.account = dw.account,
                                        i.account_title = dw.account_title,
                                        i.program = dw.program,
                                        i.program_title = dw.program_title,
                                        i.[location] = dw.[location],
                                        i.location_title = dw.location_title,
                                        i.early_inactivation_date = dw.early_inactivation_date,
                                        i.refresh_date = dw.refresh_date,
                                        i.lastupdatedby = USER_NAME(),
                                        i.lastupdated = SYSUTCDATETIME()
                                FROM    coa_db.indx AS i
                                        INNER JOIN DW_DB..COA_DB.INDX AS dw ON i.indx_key = dw.indx_key
                                WHERE   dw.last_activity_date >= @cutoffDate_Activity
                                        OR dw.refresh_date >= @cutoffDate_Refresh

                                INSERT INTO coa_db.indx
                                    (
                                        indx_key,
                                        indx,
                                        most_recent_flag,
                                        start_effective_date,
                                        end_effective_date,
                                        last_activity_date,
                                        [status],
                                        indx_title,
                                        fund,
                                        fund_title,
                                        organization,
                                        organization_title,
                                        account,
                                        account_title,
                                        program,
                                        program_title,
                                        [location],
                                        location_title,
                                        early_inactivation_date,
                                        refresh_date
                                    )
                                SELECT  dw.indx_key,
                                        dw.indx,
                                        dw.most_recent_flag,
                                        dw.start_effective_date,
                                        dw.end_effective_date,
                                        dw.last_activity_date,
                                        dw.[status],
                                        dw.indx_title,
                                        dw.fund,
                                        dw.fund_title,
                                        dw.organization,
                                        dw.organization_title,
                                        dw.account,
                                        dw.account_title,
                                        dw.program,
                                        dw.program_title,
                                        dw.[location],
                                        dw.location_title,
                                        dw.early_inactivation_date,
                                        dw.refresh_date
                                FROM    DW_DB..COA_DB.INDX AS dw
                                WHERE   dw.last_activity_date >= @cutoffDate_Activity
                                        OR dw.refresh_date >= @cutoffDate_Refresh

                            END

                            IF @recordCount = 0
                            BEGIN
                                INSERT INTO coa_db.indx
                                            (
                                                indx_key,
                                                indx,
                                                most_recent_flag,
                                                start_effective_date,
                                                end_effective_date,
                                                last_activity_date,
                                                [status],
                                                indx_title,
                                                fund,
                                                fund_title,
                                                organization,
                                                organization_title,
                                                account,
                                                account_title,
                                                program,
                                                program_title,
                                                [location],
                                                location_title,
                                                early_inactivation_date,
                                                refresh_date
                                            )
                                SELECT      dw.indx_key,
                                            dw.indx,
                                            dw.most_recent_flag,
                                            dw.start_effective_date,
                                            dw.end_effective_date,
                                            dw.last_activity_date,
                                            dw.[status],
                                            dw.indx_title,
                                            dw.fund,
                                            dw.fund_title,
                                            dw.organization,
                                            dw.organization_title,
                                            dw.account,
                                            dw.account_title,
                                            dw.program,
                                            dw.program_title,
                                            dw.[location],
                                            dw.location_title,
                                            dw.early_inactivation_date,
                                            dw.refresh_date
                                FROM        DW_DB..COA_DB.INDX AS dw
                            END

                        END TRY
                        BEGIN CATCH
                            IF OBJECT_ID('dbo.PrintError') IS NOT NULL EXEC('EXEC dbo.PrintError');
                            IF OBJECT_ID('dbo.LogError') IS NOT NULL EXEC('EXEC dbo.LogError');
                        END CATCH
                    END;
GO