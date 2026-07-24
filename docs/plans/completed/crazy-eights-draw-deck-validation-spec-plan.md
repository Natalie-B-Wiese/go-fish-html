# Feature: Reject `draw_deck_turn` when the Crazy Eights player has a playable card

## Feature summary

`Implementation#draw_deck_turn` currently always lets the current player draw from the deck,
even when they hold a card that's legal to play against the discard pile. Per house rules
(`docs/crazy-eights-rules.md`), drawing is only allowed when the player has **no** playable
card. This closes the `draw_deck_turn` half of `IMPROVEMENT_CARDS.md` Card 2, reusing
`current_player.playable_cards(discard_pile.top_card)` (already the source of truth for legal
plays) rather than a parallel check. On rejection: no hand/deck/discard change, no turn switch,
no feed entry, and a falsy (`nil`) result — matching the `play_turn` guard's shape and Go Fish's
existing `request_opponent_turn` guard-clause convention.

## Test coverage

### `spec/models/crazy_eights/implementation_spec.rb` (restructure existing `#draw_deck_turn` describe block)

The current fixture (`player1_cards` includes an `8`, which is always playable) makes every
existing example implicitly rely on "player has no playable cards" being false — since 8s are
wild, this fixture is actually the *invalid* case once the guard exists. All 6 existing examples
move under a new context with a fixture that truly has no playable card, and a new context covers
the rejection path.

#### context: when the player has no playable cards (existing 6 examples, fixture adjusted to drop the wild `8`s)
- [x] does not switch turns
- [x] adds 1 turn result to the feed
- [x] (deck has cards) removes the card from the top of the deck and gives to player
- [x] (deck has cards) returns the correct turn result
- [x] (deck is empty) creates a new deck from all but top card of discard pile and draws from deck
- [x] (deck is empty) returns the correct turn result

#### context: when the player has a playable card
- [x] does not change the player's hand
- [x] does not change the deck
- [x] does not change the discard pile
- [x] does not switch turns
- [x] does not add a turn result to the feed
- [x] returns nil

## Related specs (regression check)

- `spec/models/crazy_eights/implementation_spec.rb` `#play_turn` — confirm unaffected
- `spec/system/crazy_eights_games_spec.rb` — end-to-end draw flow ("when current player has no
  playable cards" / "when current player has card to play") must stay green
