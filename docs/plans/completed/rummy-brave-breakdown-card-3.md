# Rummy — Discard & End Turn (Phase 3)

**Estimate:** 2 pts (X-Small, < 2 hrs) · **Priority:** essential for the Rummy phase

## Context
Rummy's turn is: **draw → (meld, out of scope) → discard & end turn**. Phase 1 (`draw_deck_turn` / `draw_discard_turn`) sets `has_drawn = true` but never advances the turn. This card adds the final step so a full turn completes and play passes to the next player — the prerequisite for the later melds/win work. A player may end their turn without ever melding (legal Rummy).

## Scope & Rules
- Draw → discard → pass. **Melds are out of scope**; ending a turn with no meld is allowed.
- UI (per `docs/rummy-mockups/rummy-final-design.html`, "End Turn" form): a single `select` of the hand's cards + a "Discard & End Turn" button. Shown only once `has_drawn` is true.
- **A player cannot discard the card they just drew** (from deck or discard pile) — **except** when it's the only card in their hand, so they're never stuck unable to end their turn.
- Which card was drawn is **derived from the feed** (current player's latest `TurnResult`), not stored as new engine state. Lookup + validation live on the **Implementation**.
- Invalid discard = **silent no-op** (engine returns `nil`, controller skips `save!`). No error states — the dropdown only lists legal cards.

## Approach
Mirror existing patterns: CrazyEights `play_turn` (`app/models/crazy_eights/implementation.rb:40`) for take-card → `TurnResult` → `switch_turn` → push-to-feed, and CrazyEights' card-key form/controller flow for submitting a specific card.

- **`app/models/rummy/turn_result.rb`** — add `card_discarded` (update `initialize`, `as_json`, `from_json`, `==` — serialization symmetry).
- **`app/models/rummy/implementation.rb`:**
  - `last_drawn_card` — current player's latest `TurnResult` from the feed → `card_received_deck || card_received_discard`.
  - `discardable_cards` — hand **minus** `last_drawn_card`. Single source of truth for both rules (in-hand **and** not-just-drawn).
  - `discard_turn(rank:, suit:)` — guard `has_drawn` + `discardable_cards.include?(Card.new(rank, suit))`, else `nil`. On success: `current_player.take_card` → `discard_pile.unshift_cards` → new `TurnResult(card_discarded:)` → `switch_turn` → `@has_drawn = false` → push to feed.
- **`app/models/rummy_game.rb#play_turn?`** — branch on `card:` present → `Card.from_key(card)` → `discard_turn(rank:, suit:)`; keep existing `source` draw branch. `turn_params_hash` already permits `:card`.
- **`app/presenters/rummy_game_presenter.rb`** — `discardable_cards_h` (`CardCollection.cards_to_h(implementation.discardable_cards)`), `can_discard?` (`my_turn? && implementation.has_drawn`).
- **`app/views/rummy_games/_phase3.html.slim`** — new select form gated on `can_discard?`; wire into the Rummy entry partial after `_phase1`.

**Reuse:** `switch_turn` (`implementation.rb:78`), `Card.from_key` (`card.rb:29`), `CardCollection.cards_to_h`, `current_player.take_card`, `discard_pile.unshift_cards`.

## Risk
~~`last_drawn_card` assumes the drawn `TurnResult` is the current player's latest feed entry — holds only while melds don't push to the feed. Revisit when melds land.~~ Resolved during implementation: `last_drawn_card` is stored directly as engine state (replacing the `has_drawn` boolean) and set/cleared by `draw_deck_turn`/`draw_discard_turn`/`discard_turn`, rather than derived from the feed. This sidesteps the feed-ordering assumption entirely.

## Checklist (TDD)
- [x] `Rummy::TurnResult` gains `card_discarded` (+ serialization symmetry).
- [x] `last_drawn_card` (deck-drawn and discard-drawn cases). Implemented as stored engine state (`@last_drawn_card`, replacing the `has_drawn` boolean) rather than derived from the feed — see note below.
- [x] `discardable_cards` (hand minus drawn card).
- [x] `discardable_cards` edge case: when the drawn card is the only card in hand, it stays discardable (hand of 1 is returned as-is, not subtracted).
- [x] `discard_turn` happy path: card → pile, `TurnResult` pushed, turn switches, `last_drawn_card` reset.
- [x] `discard_turn` guards: `nil` when not drawn / card not in hand / card is the just-drawn card.
- [x] Presenter: `discardable_cards_h`, `can_discard?`.
- [x] Route discard in `RummyGame#play_turn?`.
- [x] `rummy_games/_phase3.html.slim` + render gated on `can_discard?`.
- [x] System spec: draw → discard legal card → turn passes; drawn card absent from dropdown.

## Verification
- `bundle exec rspec` green (models, presenter, system).
- Manual (`bin/dev`): 2-player Rummy — draw, confirm dropdown excludes the drawn card, discard, confirm it lands on the pile and turn passes.
- `bin/rubocop`.
