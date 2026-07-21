# Feature: Prevent Player creation when the game is full

## Feature summary

A `Player` join record (a user joining a `Game`) must not be created once the game
already has `player_count` players. Today `GamesController#join` has a `# TODO: don't
let them join a game that is full` comment — nothing stops a second request from
adding a player past capacity (e.g. two users clicking "Join" on the last open slot
at nearly the same time). The fix is an Active Record validation on `Player` itself,
so the guarantee holds regardless of caller (controller, console, future code paths).

Constraints:
- `Game#full?` (`num_joined_players >= player_count`) is the existing source of truth
  for fullness — reuse it rather than re-deriving the check.
- The validation applies to new players only; it must not block updates to an
  already-persisted player (e.g. `winner` assignment via `game.update!(winner: player)`
  in `Game#end!`).
- `games_controller#join` already renders a flash alert when `Player.create` returns
  falsy, so no controller changes are needed beyond removing the now-stale TODO.

## Test coverage

### `spec/models/player_spec.rb` (modify existing)

#### validations
- [ ] is invalid when the game already has its full number of players
- [ ] is valid when the game has not yet reached its player count

## Related specs (regression check)

- `spec/system/games_spec.rb` — `join game flow` context: confirms joining an
  unfull game still works, and that full games stay hidden/non-joinable in the UI
  for players not already in them.
