-- Overview:
-- users (joined to players, joined to games)

-- Stuff from users:
-- user.id (done)
-- user.name (done)

-- Stuff from games:
-- started_at (need to do)
-- ended_at (ntd)
-- elapsed_time (ended_at-started_at) (ntd)

--Other:
--winner (needs access to game and to user_id) (ntd)

--User needs to know count of finished games (ntd)
-- User needs to know number of games won (ntd)

SELECT
    users.id as user_id,
    users.name as user_name,
    count(games.id) as total_games
FROM users
INNER JOIN players on players.user_id=users.id
INNER JOIN games on players.game_id=games.id
GROUP BY users.id