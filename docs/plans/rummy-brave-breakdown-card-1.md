# BRAVE Breakdown: Rummy — Draw-from-Deck Turn Slice (with `has_drawn` state)

## Context

Rummy's lobby/creation/start flow shipped (commit `e421f52`), but the turn engine is
greenfield: `Rummy::Implementation` only deals cards; there is **no** `turn_result_class`,
no `Rummy::TurnResult`, no draw/meld/discard methods, and `game_over?`/`winning_player`
are stubs. The full Rummy turn (draw → meld/lay-off → discard) is large and multi-step.

This card is a deliberately thin **vertical slice** taken first to de-risk the parts of
Rummy that are genuinely new to this codebase — before any of the harder game logic is
built on top. It proves, end-to-end, that a new piece of intra-turn state
(`has_drawn` — "has the current player drawn from the deck this turn?") **persists through
the jsonb `as_json`/`from_json` round-trip and drives the UI**.

## Brainstorm

**Scope — a walking skeleton of a single turn action.** A player, on their turn, clicks
**Draw from Deck**; the top deck card enters their hand; `has_drawn` is set; and the
**Draw from Deck** button then disables/disappears — and *stays* gone across a reload,
proving the state was saved, not just held in the request.

Corrections/clarifications resolved during breakdown:
- The "open turn across multiple engine calls" pattern is **not new** — Crazy Eights already
  does it: `draw_deck_turn` (`crazy_eights/implementation.rb:31`) pushes to `feed` and returns
  **without** `switch_turn`; only the terminating `play_turn` switches. Rummy reuses this shape.
- What *is* new for Rummy is **intra-turn phase/ordering state** — Crazy Eights has no
  "you must draw exactly once, then …" constraint. `has_drawn` is that state.

**In scope**
- `draw_deck_turn` — top deck card → current player's hand; sets `has_drawn`; **no** `switch_turn`.
- `has_drawn` phase state on the engine, including full `as_json`/`from_json` symmetry.
- Guard: a **second** `draw_deck_turn` in the same turn returns `nil` (once-per-turn).
- `Rummy::TurnResult` value object (+ `as_json`/`from_json`) and wiring
  `self.turn_result_class` (fixes a latent `NotImplementedError` on `feed` deserialization).
- Presenter method (`can_draw?`) so the view reads state through the presenter, not the engine.
- View: new `rummy_games/_turn_form` with a **Draw from Deck** button that toggles on `can_draw?`;
  uncomment/wire the `game_feed` render in `_rummy_game.html.slim:2`.
- One new permitted turn param in `GamesController#play`.
- Model spec + system spec (incl. persist-across-reload assertion).

**Explicitly deferred (to later cards)**
- **End Turn card:** `switch_turn`/`end_turn`, **resetting** `has_drawn` on turn switch, and
  enforcing "must have drawn before ending" (needs End Turn to exist to be meaningful).
- Discard pile (draw-from-discard, discard-to-end), melds, lay-off, win condition, whole-game play.

**Known, intentional limitation to note on the card:** with End Turn deferred, the slice is
not playable to completion — you draw once and the turn sits open. So `has_drawn` is
*set-and-guarded* here but not yet *reset* or *consumed by ending*. This is expected for a
spike; call it out so a reviewer doesn't flag it as incomplete.

## Approach

Follow the Crazy Eights turn path end-to-end; it is the closest existing pattern.

- **Engine** (`app/models/rummy/implementation.rb`): add `has_drawn` as engine state
  (constructor keyword defaulting to `false`; include it in `as_json`, `self.json_attributes`,
  and `==` — the symmetry is the whole point). Add `draw_deck_turn` mirroring
  `crazy_eights/implementation.rb:31` but returning `nil` when `has_drawn` is already true,
  and setting `has_drawn = true` on success. Add `self.turn_result_class`.
  - *Open implementation decision:* store `has_drawn` as a single boolean on the Implementation
    ("the current player has drawn") — simplest and matches how the turn is single-seat.
    Alternative: per-`Player` flag. Recommend the boolean-on-Implementation for the spike;
    confirm when coding.
- **TurnResult** (new `app/models/rummy/turn_result.rb`): mirror `CrazyEights::TurnResult` —
  `current_user_id`, `card_received_deck`, with `as_json`/`self.from_json`.
- **STI subclass** (`app/models/rummy_game.rb`): add `play_turn?` that calls
  `game_state.draw_deck_turn` (mirror `CrazyEightsGame#play_turn?`, `crazy_eights_game.rb:15`).
- **Presenter** (`app/presenters/rummy_game_presenter.rb`, currently an empty stub): add
  `can_draw?` (my turn AND not yet drawn), reading `game_state`.
- **Controller** (`app/controllers/games_controller.rb:54`): permit the one new turn param
  used to signal "draw" (Crazy Eights signals draw via absence of `:card`; pick an explicit
  param for clarity).
- **Views**: new `rummy_games/_turn_form.html.slim` (a `simple_form_for :turn` posting to
  `play_turn_path`, Draw button rendered/enabled only when `@presenter.can_draw?`); wire
  `_rummy_game.html.slim:2` to `render 'game_feed', turn_form_partial: 'rummy_games/turn_form'`.

**Mid-way "am I on track?" check:** model spec green for draw + second-draw-`nil` + the
serialization round-trip (`Implementation.load(Implementation.dump(game))` preserves `has_drawn`).
**Error/recovery:** an illegal draw returns `nil`; `GamesController#play` (`games_controller.rb:46`)
already treats falsey `play_turn?` as a no-op (no save), so a bad request just re-renders — no
crash, no state change.

### Turn state (this slice)

```
current player's turn
      │  Draw from Deck  (has_drawn: false → true, card → hand, NO switch)
      ▼
 has_drawn = true  ──► Draw button hidden/disabled (via presenter#can_draw?)
      │  second Draw?  ──► draw_deck_turn returns nil ──► no-op
      ▼
 turn sits open   ── End Turn (switch + reset has_drawn) = NEXT CARD
```

## Value

- **Business/user:** first playable Rummy action on screen, and — more importantly —
  a proof that the platform's jsonb serialization correctly persists *new* intra-turn state.
  Every later Rummy card (discard, melds, lay-off) depends on that state surviving a save.
- **What the user experiences:** on their turn, a **Draw from Deck** button; after drawing,
  the button is gone and the drawn card is in their hand — and it stays that way on refresh.
- **Priority / optimize for:** optimize for **learning/de-risking**. The point is to surface
  the serialization-symmetry gotcha and the presenter→view reactivity pattern cheaply, on the
  smallest possible slice, before the expensive game logic lands on top.

## Estimate

- **4 points — Small (~½ day);** ~5 with the standard 15% review/pairing buffer.
- Justified by heavy reuse of the Crazy Eights turn path (engine method, TurnResult, STI
  `play_turn?`, turn-form). The real effort/uncertainty sits in three places: `has_drawn`
  serialization symmetry, the presenter→view reactive toggle, and the first Rummy system spec.
- **Top risks**
  - *Serialization symmetry* — omit `has_drawn` from `as_json` **or** `json_attributes` and
    the flag silently drops. Likelihood medium, severity medium — but the persist-across-reload
    spec is exactly what catches it (and is the card's reason to exist).
  - *System-spec timing on the reactive button* — likelihood low-medium (GoodJob async
    broadcasts work in `:js` specs here), severity medium.
- **Incremental fallback:** if the view/system-spec portion runs long, the engine + model spec
  (draw + `has_drawn` persistence) is shippable on its own; the button-toggle UI can slide to
  the End Turn card.
- **Sequencing:** this is the first of the Rummy turn-engine cards; the **End Turn** card
  (switch + reset `has_drawn` + draw-before-end enforcement) should follow directly, then
  discard pile, melds/lay-off, and win condition.

## Implementation Plan

- [ ] Spec-first: `spec/models/rummy/turn_result_spec.rb` — `as_json`/`from_json` round-trip.
- [ ] Add `app/models/rummy/turn_result.rb` (`current_user_id`, `card_received_deck`).
- [ ] Spec-first: `spec/models/rummy/implementation_spec.rb` — `draw_deck_turn` adds a card,
      sets `has_drawn`, does not switch turn; a second draw returns `nil`; `Implementation`
      serialization round-trip preserves `has_drawn`.
- [ ] Add `has_drawn` state to `Rummy::Implementation` (constructor, `as_json`,
      `self.json_attributes`, `==`) + `self.turn_result_class` + `draw_deck_turn`.
- [ ] Add `RummyGame#play_turn?` delegating to `game_state.draw_deck_turn`.
- [ ] Add `RummyGamePresenter#can_draw?`.
- [ ] Permit the new turn param in `GamesController#play`.
- [ ] Add `app/views/rummy_games/_turn_form.html.slim` (Draw button gated on `can_draw?`).
- [ ] Wire `_rummy_game.html.slim:2` `game_feed` render to the new turn form.
- [ ] System spec `spec/system/rummy_games_spec.rb`: draw → button gone → **reload** → still gone.
- [ ] `bin/rubocop` (mind the 7-line method / 7-line `it` limits) + full `bundle exec rspec`.

---

## Card Note (condensed — copy-paste into Linear)

**Title:** Rummy: draw-from-deck turn slice + `has_drawn` state

**Estimate:** 4 (Small)

**Description:**
First vertical slice of the Rummy turn engine. On their turn a player can **Draw from Deck**
(top deck card → hand); the engine records `has_drawn` for the current turn and the Draw
button then disables/disappears. The primary goal is to prove the new intra-turn state
persists through jsonb `as_json`/`from_json` and drives the view. Reuses the Crazy Eights
turn path (`draw_deck_turn` with no `switch_turn`, `TurnResult`, STI `play_turn?`, turn form).

**Acceptance criteria**
- On my turn, a **Draw from Deck** button appears; clicking it moves the top deck card to my hand.
- After drawing, the Draw button is disabled/hidden, and stays so **after a page reload**
  (state persisted).
- A second draw in the same turn is a no-op (`draw_deck_turn` returns `nil`).
- `Rummy::TurnResult` + `self.turn_result_class` exist (removes latent `NotImplementedError`).
- Model spec + system spec (incl. persist-across-reload) green; `bin/rubocop` clean.

**Out of scope (later cards):** End Turn (`switch_turn` + reset `has_drawn` + draw-before-end
enforcement), discard pile, melds, lay-off, win condition.

**Note for reviewers:** End Turn is deferred, so the turn intentionally sits open after drawing;
`has_drawn` is set-and-guarded here but not yet reset/consumed. Expected for this spike.
