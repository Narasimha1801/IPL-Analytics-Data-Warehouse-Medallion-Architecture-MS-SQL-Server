/*==============================================================================
BRONZE LAYER – RAW IPL CRICKET DATA TABLES
===============================================================================
PURPOSE:
    This script creates raw (Bronze layer) tables to store IPL cricket data
    exactly as received from source files. No transformations are applied
    at this stage.

WARNING:
    PLEASE VERIFY THE CURRENT DATABASE CONTEXT BEFORE EXECUTION.
    This script DROPS and RECREATES TABLES.
    Running it in the wrong database may result in DATA LOSS.
==============================================================================*/

-- ============================================================================
-- TABLE: bronze.batting_scorecard
-- DESCRIPTION:
-- Stores batter-level performance per match and innings
-- ============================================================================
IF OBJECT_ID('bronze.batting_scorecard', 'U') IS NOT NULL
    DROP TABLE bronze.batting_scorecard;
GO

CREATE TABLE bronze.batting_scorecard (
    match_id        INT,
    innings         INT,
    team            NVARCHAR(50),
    batter          NVARCHAR(50),
    runs            INT,
    balls           INT,
    fours           INT,
    sixes           INT,
    strike_rate     FLOAT,
    dismissal_kind  NVARCHAR(50),
    dismissal_by    NVARCHAR(50),
    fielders        NVARCHAR(50)
);
GO

-- ============================================================================
-- TABLE: bronze.bowling_scorecard
-- DESCRIPTION:
-- Stores bowler-level performance metrics per match and innings
-- ============================================================================
IF OBJECT_ID('bronze.bowling_scorecard', 'U') IS NOT NULL
    DROP TABLE bronze.bowling_scorecard;
GO

CREATE TABLE bronze.bowling_scorecard (
    match_id        INT,
    innings         INT,
    bowling_team    NVARCHAR(50),
    bowler          NVARCHAR(50),
    overs           FLOAT,
    balls           INT,
    runs_conceded   INT,
    wickets         INT,
    economy         FLOAT,
    wides           INT,
    noballs         INT,
    byes            INT,
    legbyes         INT,
    penalty         INT
);
GO

-- ============================================================================
-- TABLE: bronze.deliveries_ballbyball
-- DESCRIPTION:
-- Ball-by-ball delivery data capturing every event in a match
-- ============================================================================
IF OBJECT_ID('bronze.deliveries_ballbyball', 'U') IS NOT NULL
    DROP TABLE bronze.deliveries_ballbyball;
GO

CREATE TABLE bronze.deliveries_ballbyball (
    match_id        INT,
    innings         INT,
    batting_team    NVARCHAR(50),
    over_num        INT,
    ball            INT,
    batter          NVARCHAR(50),
    non_striker     NVARCHAR(50),
    bowler          NVARCHAR(50),
    runs_batter     INT,
    runs_extra      INT,
    runs_total      INT,
    extra_detail    NVARCHAR(50),
    wickets         VARCHAR(MAX)
);
GO

-- ============================================================================
-- TABLE: bronze.innings_total
-- DESCRIPTION:
-- Stores total score summary for each innings of a match
-- ============================================================================
IF OBJECT_ID('bronze.innings_total', 'U') IS NOT NULL
    DROP TABLE bronze.innings_total;
GO

CREATE TABLE bronze.innings_total (
    match_id        INT,
    innings         INT,
    batting_team    NVARCHAR(50),
    runs            INT,
    wickets         INT,
    legal_balls     INT,
    overs           FLOAT,
    extras          INT
);
GO

-- ============================================================================
-- TABLE: bronze.matches
-- DESCRIPTION:
-- Stores match-level metadata including teams, venue, result, and event details
-- ============================================================================


DROP TABLE IF EXISTS bronze.matches;
GO

CREATE TABLE bronze.matches (
    match_id            int,
    season              nvarchar(50),
    match_date          nvarchar(50),
    city                NVARCHAR(100),
    venue               NVARCHAR(300),
    team1               NVARCHAR(100),
    team2               NVARCHAR(100),
    teams               NVARCHAR(200),
    toss_winner         NVARCHAR(100),
    toss_decision       NVARCHAR(50),
    winner              NVARCHAR(100),
    result              NVARCHAR(100),
    win_by_runs         nvarchar(50),
    win_by_wickets      nvarchar(50),
    method              NVARCHAR(50),
    player_of_match     NVARCHAR(100),
    umpire1             NVARCHAR(100),
    umpire2             NVARCHAR(100),
    overs               int,
    balls_per_over      int,
    match_type          NVARCHAR(100),
    event_name          NVARCHAR(200),
    event_stage         NVARCHAR(100),
    event_match_number  nvarchar(50)
);
GO
