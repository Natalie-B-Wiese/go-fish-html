-- Contains data:
-- user_id,
-- user_name,
-- total_games,
-- games_won,
-- total_time_played,
-- win_percentage

WITH user_stats AS (
    SELECT
        users.id AS user_id,
        users.name AS user_name,
        COUNT(games.id) AS total_games,
        COUNT(CASE WHEN games.winner_id=users.id THEN 1 END) as games_won,
        SUM(games.ended_at-games.started_at) as total_time_played

    FROM users
    INNER JOIN players ON players.user_id=users.id
    INNER JOIN games
        ON players.game_id=games.id
        AND games.ended_at IS NOT NULL
    GROUP BY users.id
)
SELECT
    user_id,
    user_name,
    total_games,
    games_won,
    total_time_played,
    -- uses float division and rounds the percentage to 1 decimal
    ROUND(((games_won*1.0)/total_games)*100, 1) AS win_percentage
FROM user_stats