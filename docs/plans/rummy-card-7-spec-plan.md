# Spec Plan: Rummy Winner & Game Over

## Feature Summary

The Rummy engine needs a win condition to determine when a game is over and who won. A game ends the moment any player's hand becomes empty (either by laying off their last cards or discarding their last card). The player with an empty hand is the winner.

This card ports the win-condition methods from the Crazy Eights engine, which uses the same rule. No AR/controller/UI changes needed—the shared game-ending wiring already exists and handles recording the winner.

## Test Coverage

### `spec/models/rummy/implementation_spec.rb` (modify existing)

#### `#game_over?`
- [ ] returns `false` when all players have cards in their hand
- [ ] returns `true` when a player has emptied their hand

#### `#winning_player`
- [ ] returns `nil` when all players have cards in their hand
- [ ] returns the player whose hand is empty when the game is over

## Implementation Checklist

- [x] Write `#game_over?` test contexts (all have cards / one is empty) — confirm red
- [x] Implement `#game_over?` method — confirm green
- [x] Write `#winning_player` test contexts (all have cards / one is empty) — confirm red
- [x] Implement `#winning_player` method — confirm green
- [x] Remove TODO comments from both stubs
- [x] Run full engine spec suite + rubocop — confirm clean

## Related Specs (Regression Check)

- `spec/models/rummy/*_spec.rb` — all Rummy engine specs (ensure no regressions when hand state is checked)
- `spec/system/rummy_games_spec.rb` — Rummy system specs (game ending flow already tested at system level via shared code)

## Notes

- Both methods are pure reads over existing player hand state; no serialization changes needed
- Methods should be total (never raise); a hand is either empty or not
- Copy test structure directly from Crazy Eights, tweaking only the scaffolding (factories, start conditions)
