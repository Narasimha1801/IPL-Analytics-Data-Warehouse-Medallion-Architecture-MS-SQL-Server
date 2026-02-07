/*
===============================================================================
GOLD LAYER – IPL ANALYTICS STAR SCHEMA (VIEWS)
===============================================================================

Purpose:
--------
This Gold layer exposes analytics-ready star schema views built on top of Silver.

It provides:

Dimensions:
 - dim_team      : Unique teams with surrogate keys
 - dim_player    : Unique players with surrogate keys
 - dim_match     : Match-level attributes (winner, venue, umpires, etc.)

Facts:
 - fact_batting     : Player batting performance per innings
 - fact_bowling     : Player bowling performance per innings
 - fact_deliveries  : Ball-by-ball facts
 - fact_innings     : Innings-level totals

Design Notes:
-------------
- Uses surrogate keys via ROW_NUMBER() in dimensions
- Implements role-playing team dimension (team1_key / team2_key)
- Optional relationships handled via LEFT JOIN
- Business-friendly flags added (win_by_runs_flag, win_by_wickets_flag)

===============================================================================
*/

PRINT '================================================';
PRINT 'STARTING GOLD LAYER VIEW CREATION';
PRINT '================================================';

---------------------------------------------------
-- DIM TEAM
---------------------------------------------------
PRINT 'CREATING VIEW: gold.dim_team';

IF OBJECT_ID('gold.dim_team', 'V') IS NOT NULL
    DROP VIEW gold.dim_team;
GO

CREATE VIEW gold.dim_team AS
SELECT DISTINCT
    team_key = ROW_NUMBER() OVER (ORDER BY team_name),
    team_name
FROM (
    SELECT team AS team_name FROM silver.batting_scorecard
    UNION
    SELECT bowling_team FROM silver.bowling_scorecard
    UNION
    SELECT team1 FROM silver.matches
    UNION
    SELECT team2 FROM silver.matches
) t;
GO


---------------------------------------------------
-- DIM PLAYER
---------------------------------------------------
PRINT 'CREATING VIEW: gold.dim_player';

IF OBJECT_ID('gold.dim_player', 'V') IS NOT NULL
    DROP VIEW gold.dim_player;
GO

CREATE VIEW gold.dim_player AS
SELECT DISTINCT
    player_key = ROW_NUMBER() OVER (ORDER BY player_name),
    player_name
FROM ( 
    SELECT batter as player_name FROM silver.batting_scorecard
    UNION
    SELECT bowler FROM silver.bowling_scorecard
    UNION 
    SELECT batter FROM silver.deliveries_ballbyball
    UNION
    SELECT non_striker FROM silver.deliveries_ballbyball
    UNION
    SELECT bowler FROM silver.deliveries_ballbyball
)t;
GO


---------------------------------------------------
-- DIM MATCH
---------------------------------------------------
PRINT 'CREATING VIEW: gold.dim_match';

IF OBJECT_ID('gold.dim_match', 'V') IS NOT NULL
    DROP VIEW gold.dim_match;
GO

CREATE VIEW gold.dim_match AS
SELECT 
    m.match_key,
    m.match_date,
    m.season,
    m.city,
    m.venue,
    t1.team_key AS team1_key,
    t2.team_key AS team2_key,
    m.toss_winner,
    m.toss_decision,

    CASE
        WHEN m.winner IS NULL AND LOWER(m.result) LIKE '%tie%' THEN 'Tie'
        WHEN m.winner IS NULL AND LOWER(m.result) LIKE '%no result%' THEN 'No Result'
        WHEN m.winner IS NULL THEN 'No Result'
        ELSE m.winner
    END AS winner,

    CASE WHEN m.win_by_runs > 0 THEN 1 ELSE 0 END AS win_by_runs_flag,
    CASE WHEN m.win_by_wickets > 0 THEN 1 ELSE 0 END AS win_by_wickets_flag,

    m.win_by_runs,
    m.win_by_wickets,
    m.method,
    p.player_name AS player_of_the_match,
    m.umpire1,
    m.umpire2,
    m.event_stage,
    m.event_match_number

FROM silver.matches m
LEFT JOIN gold.dim_team t1 ON m.team1 = t1.team_name
LEFT JOIN gold.dim_team t2 ON m.team2 = t2.team_name
LEFT JOIN gold.dim_player p ON m.player_of_match = p.player_name;
GO


---------------------------------------------------
-- FACT BATTING
---------------------------------------------------
PRINT 'CREATING VIEW: gold.fact_batting';

IF OBJECT_ID('gold.fact_batting', 'V') IS NOT NULL
    DROP VIEW gold.fact_batting;
GO

CREATE VIEW gold.fact_batting AS
SELECT
    m.match_key,
    t.team_key,
    p1.player_key,
    b.innings,
    b.runs,
    b.strike_rate,
    b.balls,
    b.fours,
    b.sixes,
    p2.player_key AS dismissal_by_key,
    b.dismissal_kind,
    p3.player_key AS fielder_key,
    m.event_match_number
FROM silver.batting_scorecard b
JOIN silver.matches m ON b.match_id = m.match_id
JOIN gold.dim_team t ON b.team = t.team_name
JOIN gold.dim_player p1 ON b.batter = p1.player_name
LEFT JOIN gold.dim_player p2 ON b.dismissal_by = p2.player_name
LEFT JOIN gold.dim_player p3 ON b.fielders = p3.player_name;
GO


---------------------------------------------------
-- FACT BOWLING
---------------------------------------------------
PRINT 'CREATING VIEW: gold.fact_bowling';

IF OBJECT_ID('gold.fact_bowling', 'V') IS NOT NULL
    DROP VIEW gold.fact_bowling;
GO

CREATE VIEW gold.fact_bowling AS
SELECT
    m.match_key,
    t.team_key,
    p.player_key,
    b.innings,
    b.overs,
    b.runs_conceded,
    b.wickets,
    b.economy,
    b.wides,
    b.noballs,
    b.byes,
    b.legbyes,
    b.penalty,
    m.event_match_number
FROM silver.bowling_scorecard b
JOIN silver.matches m ON b.match_id = m.match_id
JOIN gold.dim_team t ON b.bowling_team = t.team_name
JOIN gold.dim_player p ON b.bowler = p.player_name;
GO


---------------------------------------------------
-- FACT DELIVERIES
---------------------------------------------------
PRINT 'CREATING VIEW: gold.fact_deliveries';

IF OBJECT_ID('gold.fact_deliveries', 'V') IS NOT NULL
    DROP VIEW gold.fact_deliveries;
GO

CREATE VIEW gold.fact_deliveries AS
SELECT
    m.match_key,
    t.team_key,
    pb1.player_key AS batter_key,
    pb2.player_key AS non_striker_key,
    pw.player_key AS bowler_key,
    d.innings,
    d.over_num,
    d.ball,
    d.runs_batter,
    d.runs_extra,
    d.runs_total,
    d.wickets AS wicket_flag,
    m.event_match_number
FROM silver.deliveries_ballbyball d
JOIN silver.matches m ON d.match_id = m.match_id
JOIN gold.dim_team t ON d.batting_team = t.team_name
JOIN gold.dim_player pb1 ON d.batter = pb1.player_name
LEFT JOIN gold.dim_player pb2 ON d.non_striker = pb2.player_name
JOIN gold.dim_player pw ON d.bowler = pw.player_name;
GO


---------------------------------------------------
-- FACT INNINGS
---------------------------------------------------
PRINT 'CREATING VIEW: gold.fact_innings';

IF OBJECT_ID('gold.fact_innings', 'V') IS NOT NULL
    DROP VIEW gold.fact_innings;
GO

CREATE VIEW gold.fact_innings AS
SELECT
    m.match_key,
    t.team_key,
    i.innings_key,
    i.runs,
    i.wickets,
    i.legal_balls,
    i.overs,
    i.extras
FROM silver.innings_total i
LEFT JOIN silver.matches m ON i.match_id = m.match_id
LEFT JOIN gold.dim_team t ON i.batting_team = t.team_name;
GO


PRINT '================================================';
PRINT 'GOLD LAYER CREATED SUCCESSFULLY';
PRINT '================================================';
