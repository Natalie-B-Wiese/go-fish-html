# Feature: Prevent playing a card not in a Crazy Eights player's hand

## Feature summary

Currently `CrazyEights::Player#take_card` always returns `Card.new(rank, suit)` even when
that card isn't in the player's hand — `Implementation#play_turn` then unconditionally adds
that fabricated card to the discard pile, switches turns, and logs it to the feed. `Player`
already has `#playable_cards(discard_card)`, which returns only cards the player holds *and*
that are legal to play against the current discard pile (rank/suit match, or any 8 — see
`#pseudo_playable_options`). `play_turn` should reject any card not present in
`current_player.playable_cards(discard_pile.top_card)` — covering both "card not in hand" and
"card in hand but illegal against the discard pile" in one check. On rejection: no discard
change, no hand change, no turn switch, no feed entry, and a falsy result so
`CrazyEightsGame#play_turn?` (which coerces with `!!`) reports failure to the controller with
no further changes needed there.

## Test coverage

### `spec/models/crazy_eights/implementation_spec.rb` (modify existing `#play_turn` describe block)

#### context: when the card is not among the player's playable cards
- [ ] when the card is not in the player's hand at all: does not change the player's hand
- [ ] when the card is not in the player's hand at all: does not change the discard pile
- [ ] when the card is not in the player's hand at all: does not switch turns
- [ ] when the card is not in the player's hand at all: does not add a turn result to the feed
- [ ] when the card is not in the player's hand at all: returns nil
- [ ] when the card is in hand but doesn't match the discard pile (and isn't an 8): returns nil and makes no changes

No new spec file needed — `#playable_cards` is already covered by
`spec/models/crazy_eights/player_spec.rb`; this feature only adds a call site.

## Related specs (regression check)

- `spec/models/crazy_eights/player_spec.rb` — confirm `#playable_cards` behavior unchanged
- `spec/models/crazy_eights_game_spec.rb` — serialization round-trip; unaffected but worth a sanity run
- `spec/system/crazy_eights_games_spec.rb` — end-to-end play flow, to confirm valid plays still work
