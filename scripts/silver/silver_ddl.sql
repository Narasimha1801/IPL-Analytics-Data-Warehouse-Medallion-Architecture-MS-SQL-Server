/*
===============================================================================
SCRIPT NAME : SILVER_SCHEMA.SQL
PURPOSE     : CREATE ALL SILVER TABLES WITH SURROGATE KEYS AND AUDIT COLUMNS
LAYER       : SILVER
===============================================================================
*/

PRINT '====================================================';
PRINT 'CREATING SILVER TABLES';
PRINT '====================================================';

--------------------------------------------------------------------
-- BATTTING SCORECARD
--------------------------------------------------------------------

PRINT 'CREATING TABLE : SILVER.BATTING_SCORECARD';

IF OBJECT_ID('silver.batting_scorecard') IS NOT NULL
    DROP TABLE silver.batting_scorecard;

CREATE TABLE silver.batting_scorecard (
    batting_key INT IDENTITY(1,1) PRIMARY KEY,

    MATCH_ID INT,
    INNINGS INT,
    TEAM NVARCHAR(50),
    BATTER NVARCHAR(50),
    RUNS INT,
    BALLS INT,
    FOURS INT,
    SIXES INT,
    STRIKE_RATE FLOAT,
    DISMISSAL_KIND NVARCHAR(50),
    DISMISSAL_BY NVARCHAR(50),
    FIELDERS NVARCHAR(50),

    DWCREATIONTIME DATETIME DEFAULT GETDATE()
);

--------------------------------------------------------------------
-- BOWLING SCORECARD
--------------------------------------------------------------------

PRINT 'CREATING TABLE : SILVER.BOWLING_SCORECARD';

IF OBJECT_ID('silver.bowling_scorecard') IS NOT NULL
    DROP TABLE silver.bowling_scorecard;

CREATE TABLE silver.bowling_scorecard (
    bowling_key INT IDENTITY(1,1) PRIMARY KEY,

    MATCH_ID INT,
    INNINGS INT,
    BOWLING_TEAM NVARCHAR(50),
    BOWLER NVARCHAR(50),
    OVERS FLOAT,
    RUNS_CONCEDED INT,
    WICKETS INT,
    ECONOMY FLOAT,
    WIDES INT,
    NOBALLS INT,
    BYES INT,
    LEGBYES INT,
    PENALTY INT,

    DWCREATIONTIME DATETIME DEFAULT GETDATE()
);

--------------------------------------------------------------------
-- DELIVERIES BALL BY BALL
--------------------------------------------------------------------

PRINT 'CREATING TABLE : SILVER.DELIVERIES_BALLBYBALL';

IF OBJECT_ID('silver.deliveries_ballbyball') IS NOT NULL
    DROP TABLE silver.deliveries_ballbyball;

CREATE TABLE silver.deliveries_ballbyball (
    delivery_key INT IDENTITY(1,1) PRIMARY KEY,

    MATCH_ID INT,
    INNINGS INT,
    BATTING_TEAM NVARCHAR(50),
    OVER_NUM INT,
    BALL INT,
    BATTER NVARCHAR(50),
    NON_STRIKER NVARCHAR(50),
    BOWLER NVARCHAR(50),
    RUNS_BATTER INT,
    RUNS_EXTRA INT,
    RUNS_TOTAL INT,
    WICKETS INT,

    DWCREATIONTIME DATETIME DEFAULT GETDATE()
);

--------------------------------------------------------------------
-- INNINGS TOTAL
--------------------------------------------------------------------

PRINT 'CREATING TABLE : SILVER.INNINGS_TOTAL';

IF OBJECT_ID('silver.innings_total') IS NOT NULL
    DROP TABLE silver.innings_total;

CREATE TABLE silver.innings_total (
    innings_key INT IDENTITY(1,1) PRIMARY KEY,

    MATCH_ID INT,
    INNINGS INT,
    BATTING_TEAM NVARCHAR(50),
    RUNS INT,
    WICKETS INT,
    LEGAL_BALLS INT,
    OVERS INT,
    EXTRAS INT,

    DWCREATIONTIME DATETIME DEFAULT GETDATE()
);

--------------------------------------------------------------------
-- MATCHES (DIMENSION STYLE)
--------------------------------------------------------------------

PRINT 'CREATING TABLE : SILVER.MATCHES';

IF OBJECT_ID('silver.matches') IS NOT NULL
    DROP TABLE silver.matches;

CREATE TABLE silver.matches (
    match_key INT IDENTITY(1,1) PRIMARY KEY,

    MATCH_ID INT,
    SEASON INT,
    MATCH_DATE DATE,
    CITY NVARCHAR(50),
    VENUE NVARCHAR(100),
    TEAM1 NVARCHAR(50),
    TEAM2 NVARCHAR(50),
    TOSS_WINNER NVARCHAR(50),
    TOSS_DECISION NVARCHAR(50),
    WINNER NVARCHAR(50),
    RESULT NVARCHAR(50),
    WIN_BY_RUNS INT,
    WIN_BY_WICKETS INT,
    METHOD NVARCHAR(50),
    PLAYER_OF_MATCH NVARCHAR(100),
    UMPIRE1 NVARCHAR(50),
    UMPIRE2 NVARCHAR(50),
    OVERS INT,
    BALLS_PER_OVER INT,
    MATCH_TYPE NVARCHAR(50),
    EVENT_NAME NVARCHAR(50),
    EVENT_STAGE NVARCHAR(50),
    EVENT_MATCH_NUMBER INT,

    DWCREATIONTIME DATETIME DEFAULT GETDATE()
);

PRINT '====================================================';
PRINT 'SILVER TABLE CREATION COMPLETED SUCCESSFULLY';
PRINT '====================================================';
GO
