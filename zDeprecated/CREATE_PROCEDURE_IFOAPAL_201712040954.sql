/***************************************************************************************
Name      : BSO Financial Management Interface - IFOAPAL
License   : Copyright (C) 2017 University of California San Diego
            Developed for Department of Medicine by Matthew C. Vanderbilt
****************************************************************************************
DESCRIPTION / NOTES:
- Creates IFOAPAL/FinLink Procedures
****************************************************************************************
PREREQUISITES:
- none
***************************************************************************************/

/*  GENERAL CONFIGURATION AND SETUP ***************************************************/
PRINT '** General Configuration & Setup';
/*  Change database context to the specified database in SQL Server. 
    https://docs.microsoft.com/en-us/sql/t-sql/language-elements/use-transact-sql */
USE [bso];
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

IF OBJECT_ID('ifoapal.Get_location','P') IS NOT NULL
    DROP PROCEDURE ifoapal.Get_location;
GO
IF OBJECT_ID('ifoapal.Add_location_type','P') IS NOT NULL
    DROP PROCEDURE ifoapal.Add_location_type;
GO
IF OBJECT_ID('ifoapal.Add_location','P') IS NOT NULL
    DROP PROCEDURE ifoapal.Add_location;
GO

CREATE PROCEDURE    ifoapal.Get_location
                    (
                        @location_id NVARCHAR(6) = '',
                        @location_name NVARCHAR(50) = '',
                        @location_type_id NVARCHAR(2) = '',
                        @location_type_name NVARCHAR(25) = '',
                        @full_detail bit = 1,
                        @valid_only bit = 0,
                        @verbose_return bit = 0,
                        @echo_sql bit = 0
                    )
                    AS
                    BEGIN
                        -- SET NOCOUNT ON added to prevent extra result sets from
						-- interfering with SELECT statements.
                        SET NOCOUNT ON

                        DECLARE @SQL NVARCHAR(MAX) = NULL;

                        SET @SQL = 'SELECT d.location_id, ';
                        SET @SQL = @SQL + 'd.location_name, ';
                        IF @full_detail = 1
                            BEGIN
                                SET @SQL = @SQL + 'd.location_type_id, ';
                                SET @SQL = @SQL + 't.location_type_name, ';
                            END;
                        SET @SQL = @SQL + '(CASE WHEN t.validto < CAST(SYSUTCDATETIME() AS DATETIME2(2)) THEN 0 ELSE 1 END) AS [valid] ';
                        
                        IF @verbose_return = 1
                            BEGIN
                                SET @SQL = @SQL + ', '
                                SET @SQL = @SQL + 'd.createdby, '
                                SET @SQL = @SQL + 'd.createddate, '
                                SET @SQL = @SQL + 'd.lastupdatedby, '
                                SET @SQL = @SQL + 'd.lastupdated, '
                                SET @SQL = @SQL + 'd.rowguid, '
                                SET @SQL = @SQL + 'd.versionnumber, '
                                SET @SQL = @SQL + 'd.validfrom, '
                                SET @SQL = @SQL + 'd.validto '
                            END;

                        SET @SQL = @SQL + 'FROM ifoapal.location AS d ' +
                                    'INNER JOIN ifoapal.location_type AS t ON d.location_type_id = t.location_type_id ';
                        
                        SET @SQL = @SQL + 'WHERE 1=1 ';
                        SET @SQL = @SQL + CASE WHEN @location_id<>'' THEN 'AND d.location_id LIKE ' + '''' + '%' + @location_id + '%' + ''' ' ELSE '' END;
                        SET @SQL = @SQL + CASE WHEN @location_name<>'' THEN 'AND d.location_name LIKE ' + '''' + '%' + @location_name + '%' + ''' ' ELSE '' END;
                        SET @SQL = @SQL + CASE WHEN @location_type_id<>'' THEN 'AND t.location_type_id LIKE ' + '''' + '%' + @location_type_id + '%' + ''' ' ELSE '' END;
                        SET @SQL = @SQL + CASE WHEN @location_type_name<>'' THEN 'AND t.location_type_name LIKE ' + '''' + '%' + @location_type_name + '%' + ''' ' ELSE '' END;
                        SET @SQL = @SQL + CASE WHEN @valid_only=1 THEN 'AND (CASE WHEN t.validto < CAST(SYSUTCDATETIME() AS DATETIME2(2)) THEN 0 ELSE 1 END) = 1 ' ELSE '' END;
                        SET @SQL = @SQL + ' AND 1=1 ';

                        SET @SQL = @SQL + 'ORDER BY d.location_name ';

                        SET @SQL = @SQL + ';'
                        
                        IF @echo_sql=1 PRINT @SQL;
                        
                        EXEC(@SQL);
                    END;
GO

CREATE PROCEDURE    ifoapal.Add_location_type
                    (
                        @location_type_id NVARCHAR(2) = '',
                        @location_type_name NVARCHAR(25) = '',
                        @echo_sql bit = 1
                    )
                    AS
                    BEGIN
                        -- SET NOCOUNT ON added to prevent extra result sets from
						-- interfering with SELECT statements.
                        SET NOCOUNT ON

                        IF @location_type_id = '' SET @location_type_id = 'ZZ';
                        IF @location_type_name = '' SET @location_type_name = '--EMPTY--';

                        DECLARE @SQL NVARCHAR(MAX) = NULL;
                        DECLARE @RETURN NVARCHAR(2) = '';
                        DECLARE @NewIDs TABLE (location_type_id NVARCHAR(2));

                        SELECT @RETURN = D.location_type_id FROM ifoapal.location_type D WHERE D.location_type_id = @location_type_id;

                        IF ISNULL(@RETURN,'') = ''
                            BEGIN
                                INSERT INTO ifoapal.location_type (location_type_id, location_type_name) 
                                OUTPUT inserted.location_type_id INTO @NewIDs(location_type_id) 
                                VALUES (@location_type_id, @location_Type_name);
                                SELECT @RETURN = location_type_id FROM @NewIDs;
                            END;

                        SELECT @RETURN;

                    END;
GO

CREATE PROCEDURE    ifoapal.Add_location
                    (
                        @location_name NVARCHAR(5) = '',
                        @location_type_id NVARCHAR(2) = '',
                        @location_type_name NVARCHAR(25) = '',
                        @echo_sql bit = 0
                    )
                    AS
                    BEGIN
                        -- SET NOCOUNT ON added to prevent extra result sets from
						-- interfering with SELECT statements.
                        SET NOCOUNT ON

                        IF @location_type_id = '' SET @location_type_id = 'ZZ';
                        IF @location_type_name = '' SET @location_type_name = '--EMPTY--';

                        DECLARE @SQL NVARCHAR(MAX) = NULL;

                        IF @echo_sql=1 PRINT @SQL;

                        SELECT SCOPE_IDENTITY() AS new;
                    END;
GO