/*==============================================================================
DATABASE INITIALIZATION SCRIPT – IPL DATA WAREHOUSE
===============================================================================
PURPOSE:
    This script initializes the IPL Data Warehouse by:
    - Dropping the existing database (if present)
    - Recreating the database
    - Creating Bronze, Silver, and Gold schemas

WARNING:
    ⚠️ CRITICAL – VERIFY DATABASE CONTEXT BEFORE EXECUTION
    This script DROPS the database [IPL_Datawarehouse] if it exists.
    ALL EXISTING DATA WILL BE PERMANENTLY DELETED.

    Execute ONLY in a development or controlled environment.
==============================================================================*/

-- Switch to system database to allow DROP/CREATE operations
USE master;
GO

-- ============================================================================
-- DROP DATABASE IF IT ALREADY EXISTS
-- ============================================================================
IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = 'IPL_Datawarehouse'
)
BEGIN
    -- Force disconnect all active sessions
    ALTER DATABASE IPL_Datawarehouse
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;

    -- Drop the existing database
    DROP DATABASE IPL_Datawarehouse;
END;
GO

-- ============================================================================
-- CREATE DATABASE
-- ============================================================================
CREATE DATABASE IPL_Datawarehouse;
GO

-- Switch context to the newly created database
USE IPL_Datawarehouse;
GO

-- ============================================================================
-- CREATE SCHEMAS (MEDALLION ARCHITECTURE)
-- ============================================================================
-- Bronze  : Raw source data (no transformations)
-- Silver  : Cleaned and transformed data
-- Gold    : Business-ready analytics layer

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
