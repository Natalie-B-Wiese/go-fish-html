# Feature: Rummy game feed for non-current players

## Feature summary

Rummy's entry partial currently renders a "Turn Action" panel with only the turn forms —
no game feed — so the shared `application/_game_feed` partial (used by Go Fish and Crazy
Eights) is never rendered for anyone. This feature swaps Rummy onto that shared partial:
the current player still sees their turn forms, and every player (including non-current
ones) sees a feed of turn-action messages. `Rummy::TurnResult` gains `request_message`
(and empty `action_message`/`result_message`, matching Crazy Eights) so the shared
`_feed_bubble` partial can render it. Draw-from-deck messages stay generic (hidden card);
draw-from-discard, meld, lay-off, and discard messages name the actual card(s) involved,
since those are already public information. No meld index/ownership is referenced.

## Test coverage

### `spec/system/rummy_games_spec.rb` (modify existing)

#### the game feed panel
- [x] shows the turn action form to the current player inside the game feed panel
- [x] does not show any feed message to the current player (current player only ever sees
      the turn form, never the feed — mutually exclusive by `my_turn?`)
- [x] shows a feed message to the other player after the current player draws from the deck
- [x] the deck-draw feed message does not name the card drawn

Message content for discard-draw/meld/lay-off/discard is covered at the model level only
(`Rummy::TurnResult#request_message` below) — the system spec already proves the feed
renders for other players generically; no need to re-assert message text at that seam.

### `spec/models/rummy/turn_result_spec.rb` (modify existing)

#### `#request_message`
- [x] when card_received_deck is present, returns a message with the user's name but not the card
- [x] when card_received_discard is present, returns a message with the user's name and the card
- [x] when meld is present (no laid_off_cards), returns a message naming the melded cards
      (and does not return a lay-off message)
- [x] when meld and laid_off_cards are both present, returns a message naming the laid-off
      card(s) (and does not return a meld message)
- [x] when card_discarded is present, returns a message with the user's name and the card

#### `#action_message` / `#result_message`
- [x] both return an empty string regardless of turn action (matching Crazy Eights) —
      implemented directly, not separately tested (Crazy Eights doesn't test these either;
      covered implicitly by `_feed_bubble` rendering no extra sub-bubbles in system specs)

## Related specs (regression check)

- `spec/system/crazy_eights_games_spec.rb` — feed-bubble pattern being mirrored; no expected
  behavior change, just confirming the shared partial still works for Crazy Eights
- `spec/system/go_fish_games_spec.rb` — same shared partial, same reasoning
- `spec/models/crazy_eights/turn_result_spec.rb` — pattern reference, no change expected
