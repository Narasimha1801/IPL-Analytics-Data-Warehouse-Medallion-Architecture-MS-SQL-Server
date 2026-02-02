/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads IPL data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the BULK INSERT command to load data from CSV files into bronze tables.

Parameters:
    None.

Usage Example:
    EXEC bronze.load_bronze_ipl;
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze_ipl
AS
BEGIN
    DECLARE 
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Bronze Layer - IPL Data';
        PRINT '================================================';

        /* ------------------------------------------------ */
        PRINT 'Loading Batting Scorecard';
        PRINT '------------------------------------------------';

        IF OBJECT_ID('bronze.batting_scorecard') IS NOT NULL
        BEGIN
            SET @start_time = GETDATE();

            PRINT '>> Truncating Table: bronze.batting_scorecard';
            TRUNCATE TABLE bronze.batting_scorecard;

            PRINT '>> Inserting Data Into: bronze.batting_scorecard';
            BULK INSERT bronze.batting_scorecard
            FROM 'D:\IPL\batting_scorecard.csv'
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
            );

            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' 
                + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
                + ' seconds';
            PRINT '>> -------------';
        END

        /* ------------------------------------------------ */
        PRINT 'Loading Bowling Scorecard';
        PRINT '------------------------------------------------';

        IF OBJECT_ID('bronze.bowling_scorecard') IS NOT NULL
        BEGIN
            SET @start_time = GETDATE();

            PRINT '>> Truncating Table: bronze.bowling_scorecard';
            TRUNCATE TABLE bronze.bowling_scorecard;

            PRINT '>> Inserting Data Into: bronze.bowling_scorecard';
            BULK INSERT bronze.bowling_scorecard
            FROM 'D:\IPL\bowling_scorecard.csv'
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
            );

            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' 
                + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
                + ' seconds';
            PRINT '>> -------------';
        END

        /* ------------------------------------------------ */
        PRINT 'Loading Deliveries Ball By Ball';
        PRINT '------------------------------------------------';

        IF OBJECT_ID('bronze.deliveries_ballbyball') IS NOT NULL
        BEGIN
            SET @start_time = GETDATE();

            PRINT '>> Truncating Table: bronze.deliveries_ballbyball';
            TRUNCATE TABLE bronze.deliveries_ballbyball;

            PRINT '>> Inserting Data Into: bronze.deliveries_ballbyball';
            BULK INSERT bronze.deliveries_ballbyball
            FROM 'D:\IPL\deliveries_ball_by_ball.csv'
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
            );

            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' 
                + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
                + ' seconds';
            PRINT '>> -------------';
        END

        /* ------------------------------------------------ */
        PRINT 'Loading Innings Totals';
        PRINT '------------------------------------------------';

        IF OBJECT_ID('bronze.innings_total') IS NOT NULL
        BEGIN
            SET @start_time = GETDATE();

            PRINT '>> Truncating Table: bronze.innings_total';
            TRUNCATE TABLE bronze.innings_total;

            PRINT '>> Inserting Data Into: bronze.innings_total';
            BULK INSERT bronze.innings_total
            FROM 'D:\IPL\innings_totals.csv'
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                ROWTERMINATOR = '0x0A',
                CODEPAGE = '65001',
                TABLOCK
            );

            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' 
                + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
                + ' seconds';
            PRINT '>> -------------';
        END

        /* ------------------------------------------------ */
        PRINT 'Loading Matches';
        PRINT '------------------------------------------------';

        IF OBJECT_ID('bronze.matches') IS NOT NULL
        BEGIN
            SET @start_time = GETDATE();

            PRINT '>> Truncating Table: bronze.matches';
            TRUNCATE TABLE bronze.matches;

            PRINT '>> Inserting Data Into: bronze.matches';
            BULK INSERT bronze.matches
            FROM 'D:\IPL\matches.csv'
            WITH (
                FIRSTROW=2,
                FIELDTERMINATOR=',',
                TABLOCK)

            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' 
                + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
                + ' seconds';
            PRINT '>> -------------';
        END

        SET @batch_end_time = GETDATE();

        PRINT '==========================================';
        PRINT 'Loading Bronze Layer - IPL Completed';
        PRINT '   - Total Load Duration: ' 
            + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) 
            + ' seconds';
        PRINT '==========================================';

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER - IPL';
        PRINT 'Error Message : ' + ERROR_MESSAGE();
        PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State   : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END;
