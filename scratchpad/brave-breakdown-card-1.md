# BRAVE Breakdown: Prevent joining a game that's already full

## Brainstorm
`GamesController#join` currently only guards against a user double-joining a game they're already in (via a `Player` uniqueness validation) — it never checks whether the game is already at capacity. A game configured for `player_count: 3` can be over-joined to 4+ players, which corrupts turn-order and player-count assumptions baked into game start (e.g. `GoFish::Implementation#deal!`'s small/big game split at `players.length <= 3`). The fix only needs to close the gap at the point where a `Player` record is created — no UI changes are needed, since the lobby already hides full games from non-members. The one open question (flash message wording for the failure case) was resolved: reuse the existing generic message for both "already joined" and "game full" failures — no need to distinguish them to the user.

## Approach
Follow the existing pattern already used for the double-join guard: a validation on the `Player` model, not new branching in the controller. Add a second validation alongside the existing `game_id` uniqueness one:

```ruby
validates :game_id, uniqueness: { scope: :user_id, message: 'You already joined the game' }
validate :game_not_full

private

def game_not_full
  errors.add(:game, 'is already full') if game&.full?
end
```

This reuses `Game#full?` (already defined at `app/models/game.rb:44-46`) and the controller's existing failure path (`GamesController#join`'s `else` branch — generic flash + `render :index, status: :unprocessable_content`) with zero controller changes. No custom `validate { }` proc is used since there's no existing precedent for that style in this codebase, and a named method fits the house 7-line-method convention better.

**TDD order (outside-in, RoleModel convention):**
1. System spec first, in the existing `spec/system/games_spec.rb` `'join game flow'` > `'when game is full'` > `'when player is not in the game'` context (currently only asserts the game is hidden from the index — extend or add a sibling test that hits the join path directly and asserts no player is created / alert shown).
2. Drop down to a `Player` model spec covering the new `game_not_full` validation directly — written before the validation exists, so it drives the implementation rather than confirming it after the fact.
3. Only then add `validate :game_not_full` to `Player`, which should turn both specs green.

**Error/recovery state:** unchanged from the existing pattern — failed `Player.create` renders `:index` with the existing generic flash (`'There was a problem joining a game.'`). No new distinct messaging for the full-game case.

## Value
- **Business value:** closes a known, already-flagged correctness bug (the `# TODO` at `games_controller.rb:34`) before it corrupts a game's turn order in production.
- **User value:** a player attempting to join a full game (e.g. via a stale page or direct link) gets a clear alert and stays on the index instead of silently breaking the game for everyone already in it.
- **Priority:** part of the Rails audit improvement backlog (`IMPROVEMENT_CARDS.md`), being worked in priority order — not an active incident, no urgency beyond backlog sequencing.
- **Optimize for:** quality. Small, well-scoped fix — no reason to rush it.

## Estimate
**2 points (X-Small, <2 hours)**, includes buffer for review/pairing given the small size. Scope is a one-method model validation plus two specs (system + model) — no new controller logic, no view changes.

- **Risk:** low. The one real risk — the shared `Player.create` failure path now covers two distinct causes (already-joined vs. full) — is mitigated by writing tests for both scenarios up front; a regression in either validation would surface immediately.
- **Dependencies/sequencing:** none. This card is independent of Card 2 (Crazy Eights hand validation) and Card 3 (game-feed N+1 query) — different models, no shared code, can ship in any order relative to those.
- **Incremental shipping:** not applicable — the fix is small enough that there's no meaningful partial version to ship.

## Implementation Plan
- [ ] Write/extend the system spec in `spec/system/games_spec.rb` (`'join game flow'` > `'when game is full'` > `'when player is not in the game'`) asserting a join attempt on a full game does not create a `Player` and shows the alert
- [ ] Run the spec, confirm it fails for the expected reason (game currently allows the over-join)
- [ ] Add a `Player` model spec covering `game_not_full` directly (valid when game has room, invalid when `game.full?`), confirm it fails for the expected reason
- [ ] Add `validate :game_not_full` and the private `game_not_full` method to `app/models/player.rb`
- [ ] Confirm both the model spec and the system spec pass
- [ ] Run full suite (`bundle exec rspec`) and `bin/rubocop` to confirm no regressions or style violations
- [ ] Remove the `# TODO: don't let them join a game that is full` comment from `GamesController#join` (no longer applicable — the controller itself doesn't change otherwise)
