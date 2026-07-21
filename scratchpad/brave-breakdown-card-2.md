# BRAVE Breakdown: Reject Crazy Eights card plays for cards not in the player's hand

## Brainstorm
`CrazyEights::Player#take_card` always returns a freshly constructed `Card.new(rank, suit)`, even when the hand lookup (`cards.find { ... }`) comes back `nil` — so a crafted `play` request can "play" a card the player never held, and nothing downstream checks for the failure. Confirmed the propagation path already works once `take_card`/`play_card`/`play_turn` return something falsy: `CrazyEightsGame#play_turn?` already wraps the result in `!!`, and `GamesController#play` only calls `game.save!` when `play_turn?` is truthy — so the fix is entirely inside the `CrazyEights` engine, no controller changes needed.

Two things sharpened the scope during discussion:
- **The `'8'` wildcard case**: holding *any* `8` (regardless of its actual suit) should count as holding an `8` of every suit, since `8` is the wildcard rank and the declared suit isn't a property of the physical card. The existing `cards.find { |card| card.rank == rank }` lookup for `'8'` already reflects this correctly — it just needs a nil-check wired up like every other rank.
- **Scope expansion (play legality)**: this card was originally just about hand-possession, but there's no enforcement anywhere that a played card is actually *legal* against the current discard pile (matching rank or suit, or being an `8`). That's a known, related gap, and we agreed to fold it into this card rather than leave it as a second, near-identical bug to fix later.
- **Scope expansion (draw legality)**: `CrazyEights::Implementation#draw_deck_turn` has dead commented-out code (`# return nil unless current_player.out_of_cards?` / `# return nil unless current_player.playable_cards(...)`) — leftover from copying the Go Fish implementation, and not the correct Crazy Eights rule. The real rule: a player should only be allowed to draw from the deck when they have *no* playable card against the discard pile. We agreed to close this now too, since it's the exact gap the card's own "Why" section already points at as evidence this was a known-but-unclosed issue, and it reuses the same `playable_cards` check the play-legality guard already needs.

**Error handling decision**: invalid plays should behave exactly like Go Fish's existing invalid-request case — a silent no-op (return `nil`, no save, no special flash) — not a new user-facing error state.

## Approach
Follow the same guard-clause pattern already established in `GoFish::Implementation#request_opponent_turn`:

```ruby
def request_opponent_turn(opponent_user_id:, rank_requested:)
  return nil unless valid_opponent?(opponent_user_id) && valid_request_rank?(rank_requested)
  ...
```

The key insight: `Player#playable_cards(discard_card)` already encodes *both* checks we need in one pass — for non-`8` cards it only returns options that are (a) actually in the player's hand and (b) legal against the discard pile; for `8`s it returns all four suits, but only if the player holds a real `8`. So a single check —

```ruby
current_player.playable_cards(discard_pile.top_card).include?(Card.new(rank, suit))
```

— gives hand-possession *and* discard-legality together, using `Card#==`'s value equality and already-tested logic, instead of writing two parallel checks.

**Where the guard lives**: mirroring the Go Fish precedent exactly. `GoFish::Player#take_cards_with_rank` does zero defensive checking — it trusts it's only called after `Implementation#valid_request_rank?` (which calls `Player#includes_card_with_rank?`) has already passed. So for Crazy Eights: add a private `valid_card_play?(rank, suit)` predicate to `Implementation`, guard `play_turn` with `return nil unless valid_card_play?(rank, suit)` before any mutation, and leave `Player#take_card` completely untouched — no nil handling added there, per `AGENTS.md`'s "only validate at system boundaries, trust internal code" convention. Validating the same thing in two places would be redundant, not safer.

**The same check covers the draw guard**: `draw_deck_turn` gets `return nil if current_player.playable_cards(discard_pile.top_card).any?` in place of the dead commented-out lines — the mirror image of the play guard (draw is legal only when no play is).

**Existing spec fixture conflict discovered while planning**: `spec/models/crazy_eights/implementation_spec.rb:80`'s `#draw_deck_turn` tests currently give `player1` a hand of `[5-Spades, 8-Diamonds, 8-Hearts]` against a discard pile topped with `3-Spades` — player1 already holds a playable `8` (wildcard) in every existing example. Under the new guard, every current `#draw_deck_turn` example (`'does not switch turns'`, `'adds 1 turn result to the feed'`, and both the `'deck has cards'`/`'deck is empty'` nested contexts) would now fail, since the player has a legal play and the draw should be rejected. Agreed fix: restructure the existing examples under an explicit "when player has no playable cards" context with `player1_cards` adjusted to hold no legal play, and add a new "when player has a playable card" context asserting `nil` and no state change (feed/deck/hand/discard_pile/`current_player_index` all unchanged).

**TDD order**: start at the `Implementation` level (`spec/models/crazy_eights/implementation_spec.rb`), not a system spec and not a `Player` spec — this is an engine-internal guard, not a controller-facing or hand-management behavior change.

**Error/recovery state**: unchanged from the existing pattern — both `play_turn` and `draw_deck_turn` return `nil`, `play_turn?` resolves to `false`, `GamesController#play` skips `save!` and redirects. No new messaging.

## Value
- **Business/user value**: prevents cheating — a player crafting a raw turn request could otherwise play cards they don't hold, play an illegal card against the discard pile, or draw from the deck when they have a legal play to stall/manipulate the game state. This is a live cheating vector, not just code hygiene.
- **Priority**: essential — part of the Rails audit improvement backlog (`IMPROVEMENT_CARDS.md`), but treated as a correctness/security bug rather than a nice-to-have, since it directly undermines game integrity.
- **Optimize for**: quality. This is the kind of bug where a rushed fix that misses an edge case (e.g. the `8` wildcard) just reopens the same cheating vector a different way.

## Estimate
**2 points (X-Small, <2 hours)**, including review/pairing buffer — small enough that the buffer doesn't push it into the next bucket. Re-checked after adding the `draw_deck_turn` guard and spec restructuring to scope; the restructure is a fixture change plus moving existing examples under a new context, not new logic, so it stays at 2 points rather than bumping to 4.

- **Risk**: low-to-moderate. The main risk is that reusing `Player#playable_cards` promotes it from a UI-only helper (deciding what to highlight as playable) into a security boundary — worth double-checking its existing edge cases (especially the `8` branch) actually hold up under this new, higher-stakes use, since a bug there now means both a display glitch *and* a validation bypass in two places (`play_turn` and `draw_deck_turn`).
- **Dependencies/sequencing**: none — consistent with Card 1's note that this card has no dependency on Card 1 or Card 3, different models/engine, can ship in any order.
- **Incremental shipping**: not really applicable. Because `playable_cards` unifies hand-possession and discard-legality into one check (and the same check drives both the play and draw guards), there's no natural smaller increment — splitting any of this out would mean writing (and later replacing) a second parallel validation, which is more work, not less.

## Implementation Plan
- [ ] Add specs to `spec/models/crazy_eights/implementation_spec.rb` for `#play_turn` covering: card not in hand at all, card in hand but illegal against the discard pile, `8` played when the player holds no `8`, and `8` played when the player does hold one (any suit) — each asserting `nil` is returned and `feed`/`current_player_index`/hand/`discard_pile` are all unchanged
- [ ] Restructure the existing `#draw_deck_turn` examples under a new "when player has no playable cards" context, adjusting `player1_cards`/discard setup so player1 genuinely has no legal play
- [ ] Add a new "when player has a playable card" context for `#draw_deck_turn` asserting `nil` is returned and `feed`/`current_player_index`/deck/hand/`discard_pile` are all unchanged
- [ ] Run all the new/restructured specs, confirm they fail for the expected reason (nothing currently blocks any of these plays/draws)
- [ ] Add a private `valid_card_play?(rank, suit)` method to `CrazyEights::Implementation` using `current_player.playable_cards(discard_pile.top_card).include?(Card.new(rank, suit))`
- [ ] Add `return nil unless valid_card_play?(rank, suit)` as the first line of `play_turn`
- [ ] Replace `draw_deck_turn`'s dead commented-out lines with `return nil if current_player.playable_cards(discard_pile.top_card).any?`
- [ ] Confirm all new/restructured specs pass and no existing `Implementation`/`Player` specs regress
- [ ] Run full suite (`bundle exec rspec`) and `bin/rubocop` to confirm no regressions or style violations
