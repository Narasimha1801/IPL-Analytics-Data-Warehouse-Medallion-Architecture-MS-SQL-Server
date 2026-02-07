/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================

Purpose:
    This procedure transforms IPL data from the Bronze layer into the Silver layer.

Silver Layer Responsibilities:
    - Standardize team names
    - Handle NULL values
    - Normalize dismissal logic
    - Fix missing bowling teams
    - Convert wickets to numeric flags
    - Remove invalid deliveries
    - Clean match metadata
    - Prepare analytics-ready tables

Tables Loaded:
    - silver.batting_scorecard
    - silver.bowling_scorecard
    - silver.deliveries_ballbyball
    - silver.innings_total
    - silver.matches

Usage:
    EXEC silver.load_silver_ipl;

===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver_ipl
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
        PRINT 'Loading Silver Layer - IPL Data';
        PRINT '================================================';



/* =========================================================
   BATTTING SCORECARD
========================================================= */

        PRINT 'Loading silver.batting_scorecard';
        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.batting_scorecard;

        INSERT INTO silver.batting_scorecard (
            match_id, innings, team, batter, runs, balls,
            fours, sixes, strike_rate, dismissal_kind,
            dismissal_by, fielders
        )
        SELECT
            match_id,
            innings,
            CASE
                WHEN team = 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
                WHEN team = 'Royal Challengers Bangalore' THEN 'Royal Challengers Bengaluru'
                WHEN team = 'Delhi Daredevils' THEN 'Delhi Capitals'
                WHEN team = 'Kings XI Punjab' THEN 'Punjab Kings'
                ELSE team
            END,
            batter,
            runs,
            balls,
            fours,
            sixes,
            strike_rate,
            dismissal_kind,
            CASE
                WHEN UPPER(dismissal_kind) = 'NOT OUT' THEN 'Not Out'
                WHEN UPPER(dismissal_kind) = 'RUN OUT' AND dismissal_by IS NULL THEN 'N/A'
                WHEN UPPER(dismissal_kind) IN ('RETIRED OUT','RETIRED HURT','OBSTRUCTING THE FIELD')
                     AND dismissal_by IS NULL THEN 'N/A'
                ELSE dismissal_by
            END,
            COALESCE(fielders,'N/A')
        FROM (
            SELECT
                match_id,
                innings,
                team,
                batter,
                runs,
                balls,
                fours,
                sixes,
                COALESCE(strike_rate,0) AS strike_rate,
                CASE
                    WHEN dismissal_kind IS NULL THEN 'Not Out'
                    ELSE dismissal_kind
                END AS dismissal_kind,
                dismissal_by,
                fielders
            FROM bronze.batting_scorecard
        ) t;

        SET @end_time = GETDATE();
        PRINT '>> silver.batting_scorecard loaded in '
              + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';


   PRINT'---------------------------------------------------------'
/* =========================================================
   BOWLING SCORECARD
========================================================= */

        PRINT 'Loading silver.bowling_scorecard';
        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.bowling_scorecard;

        INSERT INTO silver.bowling_scorecard (
            match_id, innings, bowling_team, bowler,
            overs, runs_conceded, wickets, economy,
            wides, noballs, byes, legbyes, penalty
        )
        SELECT
            match_id,
            innings,
            CASE
                WHEN bowling_team = 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
                WHEN bowling_team = 'Royal Challengers Bangalore' THEN 'Royal Challengers Bengaluru'
                WHEN bowling_team = 'Delhi Daredevils' THEN 'Delhi Capitals'
                WHEN bowling_team = 'Kings XI Punjab' THEN 'Punjab Kings'
                ELSE TRIM(bowling_team)
            END,
            bowler,
            overs,
            runs_conceded,
            wickets,
            economy,
            wides,
            noballs,
            byes,
            legbyes,
            penalty
        FROM (
            SELECT
                match_id,
                innings,
                CASE
                    WHEN match_id=1359519 AND bowling_team IS NULL THEN ' Chennai Super Kings'
                    WHEN match_id=829763  AND bowling_team IS NULL THEN 'Royal Challengers Bengaluru'
                    WHEN match_id=501265  AND bowling_team IS NULL THEN 'Pune Warriors'
                    WHEN match_id=1473495 AND bowling_team IS NULL THEN 'Delhi Capitals'
                    WHEN match_id=1473492 AND bowling_team IS NULL THEN 'Sunrisers Hyderabad'
                    ELSE bowling_team
                END AS bowling_team,
                bowler,
                overs,
                runs_conceded,
                wickets,
                COALESCE(economy,0) AS economy,
                wides,
                noballs,
                byes,
                legbyes,
                penalty
            FROM bronze.bowling_scorecard
        ) t;

        SET @end_time = GETDATE();
        PRINT '>> silver.bowling_scorecard loaded in '
              + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';


PRINT'---------------------------------------------------------'
/* =========================================================
   DELIVERIES BALL BY BALL
========================================================= */

        PRINT 'Loading silver.deliveries_ballbyball';
        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.deliveries_ballbyball;

        INSERT INTO silver.deliveries_ballbyball (
            match_id, innings, batting_team, over_num, ball,
            batter, non_striker, bowler,
            runs_batter, runs_extra, runs_total, wickets
        )
        SELECT
            match_id,
            innings,
            CASE
                WHEN batting_team = 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
                WHEN batting_team = 'Royal Challengers Bangalore' THEN 'Royal Challengers Bengaluru'
                WHEN batting_team = 'Delhi Daredevils' THEN 'Delhi Capitals'
                WHEN batting_team = 'Kings XI Punjab' THEN 'Punjab Kings'
                ELSE batting_team
            END,
            over_num,
            ball,
            batter,
            non_striker,
            bowler,
            runs_batter,
            runs_extra,
            runs_total,
            CASE WHEN wickets <> 'n/a' THEN 1 ELSE 0 END
        FROM bronze.deliveries_ballbyball
        WHERE ball <> 7;

        SET @end_time = GETDATE();
        PRINT '>> silver.deliveries_ballbyball loaded in '
              + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';

PRINT'---------------------------------------------------------'
/* =========================================================
   INNINGS TOTAL
========================================================= */

        PRINT 'Loading silver.innings_total';
        SET @start_time = GETDATE();

        TRUNCATE TABLE silver.innings_total;

        INSERT INTO silver.innings_total (
            match_id, innings, batting_team,
            runs, wickets, legal_balls, overs, extras
        )
        SELECT
            match_id,
            innings,
            CASE
                WHEN batting_team = 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
                WHEN batting_team ='Royal Challengers Bangalore' THEN 'Royal Challengers Bengaluru'
                WHEN batting_team ='Delhi Daredevils' THEN 'Delhi Capitals'
                WHEN batting_team ='Kings XI Punjab' THEN 'Punjab Kings'
                ELSE batting_team
            END,
            runs,
            wickets,
            legal_balls,
            overs,
            extras
        FROM bronze.innings_total;

        SET @end_time = GETDATE();
        PRINT '>> silver.innings_total loaded in '
              + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';

PRINT'---------------------------------------------------------'
/* =========================================================
   MATCHES
========================================================= */

PRINT 'Loading silver.matches';
SET @start_time = GETDATE();

TRUNCATE TABLE silver.matches;

INSERT INTO silver.matches (
    match_id,
    season,
    match_date,
    city,
    venue,
    team1,
    team2,
    toss_winner,
    toss_decision,
    winner,
    result,
    win_by_runs,
    win_by_wickets,
    method,
    player_of_match,
    umpire1,
    umpire2,
    overs,
    balls_per_over,
    match_type,
    event_name,
    event_stage,
    event_match_number
)
SELECT
    match_id,
    YEAR(match_date) AS season,
    match_date,
    city,
    venue,
    CASE 
	    WHEN team1= 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
	    WHEN team1 ='Royal Challengers Bangalore' THEN 'Royal Challengers Bengaluru'
	    WHEN team1 ='Delhi Daredevils' THEN 'Delhi Capitals'
	    WHEN team1 ='Kings XI Punjab' THEN 'Punjab Kings'
	    ELSE team1
    END as team1,
    CASE 
	    WHEN team2= 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
	    WHEN team2 ='Royal Challengers Bangalore' THEN 'Royal Challengers Bengaluru'
	    WHEN team2  ='Delhi Daredevils' THEN 'Delhi Capitals'
	    WHEN team2 ='Kings XI Punjab' THEN 'Punjab Kings'
	    ELSE team2
    END as team2,
    CASE 
	    WHEN toss_winner= 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
	    WHEN toss_winner ='Royal Challengers Bangalore' THEN 'Royal Challengers Bengaluru'
	    WHEN toss_winner  ='Delhi Daredevils' THEN 'Delhi Capitals'
	    WHEN toss_winner ='Kings XI Punjab' THEN 'Punjab Kings'
	    ELSE toss_winner
    END as toss_winner,
    toss_decision,
    CASE 
	    WHEN winner= 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
	    WHEN winner ='Royal Challengers Bangalore' THEN 'Royal Challengers Bengaluru'
	    WHEN winner  ='Delhi Daredevils' THEN 'Delhi Capitals'
	    WHEN winner ='Kings XI Punjab' THEN 'Punjab Kings'
	    ELSE winner
    END as winner,
    result,
    win_by_runs,
    win_by_wickets,
    method,
    player_of_match,
    umpire1,
    umpire2,
    overs,
    balls_per_over,
    match_type,
    event_name,
    event_stage,
    COALESCE(
        TRY_CAST(REPLACE(event_match_number,'.0','') AS INT),
        0
    )
FROM (
    SELECT
        TRY_CAST(match_id AS INT) AS match_id,
        TRY_CONVERT(date, match_date, 105) AS match_date,

        CASE
            WHEN venue = 'Sharjah Cricket Stadium' THEN 'Sharjah'
            WHEN venue = 'Dubai International Cricket Stadium' THEN 'Dubai'
            ELSE city
        END AS city,

        venue,
        team1,
        team2,
        toss_winner,
        toss_decision,
        winner,
        COALESCE(result,'normal') AS result,
        TRY_CAST(REPLACE(win_by_runs,'.0','') AS INT) AS win_by_runs,
        TRY_CAST(REPLACE(win_by_wickets,'.0','') AS INT) AS win_by_wickets,
        COALESCE(method,'normal') AS method,
        player_of_match,
        umpire1,
        umpire2,
        TRY_CAST(overs AS INT) AS overs,
        balls_per_over,
        match_type,
        event_name,
        COALESCE(event_stage,'Group stage') AS event_stage,
        event_match_number
    FROM bronze.matches
) t;

SET @end_time = GETDATE();
PRINT '>> silver.matches loaded in '
      + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';



        SET @batch_end_time = GETDATE();

        PRINT '==========================================';
        PRINT 'Silver Layer Load Completed';
        PRINT 'Total Duration: '
              + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR)
              + ' seconds';
        PRINT '==========================================';

    END TRY
    BEGIN CATCH

        PRINT '==========================================';
        PRINT 'ERROR DURING SILVER LOAD';
        PRINT ERROR_MESSAGE();
        PRINT CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';

    END CATCH

END;

EXEC silver.load_silver_ipl
