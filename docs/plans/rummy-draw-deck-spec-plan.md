# Feature: Rummy — Draw-from-Deck turn slice + `has_drawn` state

## Feature summary

On their turn, a Rummy player sees a **Draw from Deck** button. Clicking it moves the
top card of the deck into their hand and records `has_drawn` for the current turn.
Once drawn, the button disappears/disables — and stays gone across a page reload,
proving `has_drawn` survives the jsonb `as_json`/`from_json` round-trip. A second draw
in the same turn is a no-op (`draw_deck_turn` returns `nil`). No turn switch, no discard,
no melds — those are later cards. Mirrors the Crazy Eights turn path.

## Test coverage

### `spec/models/rummy/turn_result_spec.rb` (new file)

#### serialization round trip
- [ ] dumps and restores a `card_received_deck` turn result (`from_json(as_json) == original`)

### `spec/models/rummy/implementation_spec.rb` (modify existing)

#### `#draw_deck_turn`
- [ ] moves the top deck card into the current player's hand
- [ ] sets `has_drawn` to true
- [ ] does not switch turns
- [ ] pushes one turn result to the feed
- [ ] returns a turn result carrying the drawn card
- [ ] returns `nil` and does not draw again when `has_drawn` is already true

#### `#as_json, .from_json, and #==` (extend existing)
- [ ] round-trip preserves `has_drawn` (drawn game restores as drawn)
- [ ] is not equal when only `has_drawn` differs

### `spec/system/rummy_games_spec.rb` (modify existing) — the outer driver

#### drawing from the deck
- [ ] current player sees a **Draw from Deck** button
- [ ] clicking it adds one card to their hand and the button disappears
- [ ] button stays gone after a page reload (state persisted)

## Implementation touched (from BRAVE card `rummy-brave-breakdown-card-1.md`)

- `app/models/rummy/turn_result.rb` (new) — `current_user_id`, `card_received_deck`, `as_json`/`from_json`
- `app/models/rummy/implementation.rb` — `has_drawn` state (ctor, `as_json`, `json_attributes`, `==`),
  `self.turn_result_class`, `draw_deck_turn`
- `app/models/rummy_game.rb` — `play_turn?` delegating to `game_state.draw_deck_turn`
- `app/presenters/rummy_game_presenter.rb` — `can_draw?` (my turn AND not yet drawn)
- `app/controllers/games_controller.rb` — permit the new draw turn param
- View — Draw button gated on `can_draw?` (structure TBD, see question)

## Related specs (regression check)

- `spec/models/crazy_eights/implementation_spec.rb` — shared base `Implementation` (`as_json`/`==`) changes
- `spec/presenters/game_presenter_spec.rb` — base presenter untouched, but confirm
- Full `bundle exec rspec` + `bin/rubocop` before done
