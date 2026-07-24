# Feature: Rummy — Melds UI (card 5)

## Feature summary

The Rummy engine already supports laying melds (`Rummy::Meld`, `Player#try_create_meld`,
`Implementation#meld_turn`), but nothing on the web layer exposes it. This card wires melds
end-to-end: during their turn, after drawing, a player can check cards in their hand that form a
valid set/run and lay them down as a new meld. Everyone's laid melds render on the game board,
including opponents'. Laying a meld does not end the turn — the player can lay multiple melds
before discarding. Invalid meld submissions fail silently (re-render, cards stay in hand).

Out of scope: lay-offs (adding to an existing meld), win detection, flash/error messaging.

## Test coverage

### `spec/models/rummy/implementation_spec.rb` (modify existing)

#### `#melds`
- [x] returns melds laid by all players combined
- [x] returns live references to the stored `Meld` objects, not copies (mutating a returned meld mutates the player's meld)

### `spec/models/rummy_game_spec.rb` (new file — no existing `RummyGame` model spec; `play_turn?` is currently only covered indirectly via the system spec)

#### `#play_turn?` with `cards:` present
- [x] converts card keys to `Card` objects and calls `game_state.meld_turn`, returning true on a valid meld
- [x] returns false when the meld is invalid — scoped down to just the return value per user direction;
      the "does not mutate hand/melds" specifics are left to the `Player`/`Implementation` specs, which
      already cover that layer

### `spec/presenters/rummy_game_presenter_spec.rb` (modify existing)

#### `#can_meld?`
- [x] returns true on the current player's turn after drawing
- [x] returns false when it is not my turn
- [x] returns false before drawing

#### `#melds`
- [x] returns `implementation.melds` for board rendering

#### `#hand_cards_h`
- [x] returns the current player's hand as a hash for the checkbox grid

### `spec/system/rummy_games_spec.rb` (modify existing)

#### laying a meld
- [x] shows the meld checkbox grid and "New Meld" option after drawing
- [x] lays a valid meld: cards leave the hand and the meld appears on the melds-board
- [x] an opponent sees the laid meld on their board too
- [x] does not end the turn after laying a meld (draw/discard flow still available)
- [x] silently no-ops on an invalid selection (cards remain in hand, no meld added)

## Related specs (regression check)

- `spec/models/rummy/player_spec.rb` — `try_create_meld` already covered; no expected change
- `spec/models/rummy/meld_spec.rb` — changed: `#set?`/`#run?` were made public (previously private,
  used only inside `#valid?`) and each got its own focused spec; `#valid?`'s spec was slimmed down
  afterward since the set/run-specific cases now live in their own describe blocks
- existing `rummy_games_spec.rb` draw/discard contexts — confirmed still passing; `_forms.html.slim`
  now always renders `_phase2`

## Notes on current WIP

Uncommitted scaffolding already exists (`_phase2.html.slim` stub with TODOs, `_forms.html.slim`
wired to render it). We'll drive it out via TDD rather than filling in the TODOs directly —
likely ending in the same place, but each piece gets a failing test first.
