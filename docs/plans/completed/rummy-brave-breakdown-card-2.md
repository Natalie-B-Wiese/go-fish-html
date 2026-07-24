# BRAVE Breakdown: Rummy — DiscardPile + Draw-from-Discard slice

## Context

Rummy's turn engine is being built outside-in, one thin slice per card (branch
`phase3-rummy`). **Card 1 shipped** (commit `caf73be`): draw-from-deck + the `has_drawn`
intra-turn phase flag, proving new state survives the jsonb `as_json`/`from_json` round-trip
and drives the UI. This card adds the **discard pile** and the *second* way to draw — taking
the pile's top card into your hand.

**Scope was deliberately narrowed during breakdown.** The originally-planned "End Turn" card
was split apart:
- **`switch_turn` (advancing to the next player + resetting `has_drawn`) is its own separate,
  deferred card.**
- **Discarding a card *onto* the pile is also deferred** — in real Rummy, discarding *is* how
  you end your turn, so it's naturally coupled to that `switch_turn` card.
- **This card is only the pile + draw-*from*-discard**, which is cleanly independent of turn
  switching. It's the thinnest useful discard-pile slice.

Intended outcome: on your turn you can choose to draw from the **deck** *or* **take the
discard top**; either sets `has_drawn` and the draw buttons then disappear (and stay gone
across a reload). The turn still sits open afterward — consistent with Card 1, since
`switch_turn` is deferred.

## Brainstorm

**In scope**
- `Rummy::DiscardPile` value object — mirror `CrazyEights::DiscardPile` (a thin `Deck`
  subclass defaulting to an *empty* collection; `as_json`/`from_json`/`==` inherited from
  `CardCollection`, so nothing new to serialize by hand).
- Thread `discard_pile` through `Rummy::Implementation`: `discard_pile:` ctor keyword,
  `as_json`, `self.json_attributes`, `==` — the same `super.merge(...)` symmetry already used
  for `has_drawn`.
- **Seed the pile at deal:** `start!` turns the top stock card face-up onto the discard pile
  after dealing (no CE-style non-8 rule — Rummy seeds unconditionally).
- **`draw_discard_turn`:** top discard card → current player's hand, sets `has_drawn`, pushes
  a `TurnResult`, **no `switch_turn`**. Guard: returns `nil` if `has_drawn` already true *or*
  the pile is empty.
- Draw-source discriminator so `play_turn?` knows which pile — an explicit `source` param
  (the YAGNI param deliberately skipped in Card 1, now needed because there are two draw
  actions).
- Presenter helper for the discard top card so the view reads it through the presenter.
- View: the Phase-1 draw panel gains a **"Take Discard"** button next to **"Draw from Deck"**,
  both gated on `can_draw?` (lives in Rummy's `_phase1` Turn Action panel — Rummy does **not**
  use the shared `application/_game_feed`).
- Model spec + system spec (incl. persist-across-reload).

**Explicitly deferred (later cards)**
- **`switch_turn` card:** advance current player + reset `has_drawn` + "must have drawn before
  ending" enforcement.
- **Discard-*to*-pile** (taking a hand card onto the pile) — rides with the `switch_turn` card,
  since discarding ends the turn. This also means `Rummy::Player#take_card` is **not** needed
  in this card.
- **Empty-stock reshuffle** (`recreate_deck_from_discard`): CE reshuffles the discard into the
  deck when the stock empties; Rummy's `draw_deck_turn` already skips this (Card 1). Keep it
  deferred; don't add it here.
- Melds/lay-off, win condition.

**Known intentional limitation (note for reviewers):** with `switch_turn` deferred, the turn
still sits open after drawing — you can draw once (from either pile) and the turn doesn't end.
Expected for this slice, same as Card 1.

## Approach

Follow the Crazy Eights discard pattern and the Card-1 Rummy patterns end-to-end — this card is
almost entirely repetition of proven shapes.

- **DiscardPile** (`app/models/rummy/discard_pile.rb`, new): copy `CrazyEights::DiscardPile`
  verbatim (empty-default `Deck` subclass). Top card = `cards.first`; take the top with
  `shift_card`; place with `unshift_cards`.
- **Engine** (`app/models/rummy/implementation.rb`): add `discard_pile` exactly like CE's
  (`attr_reader`, ctor keyword `discard_pile: DiscardPile.new`, and `super.merge(...)` in
  `as_json` / `self.json_attributes` / `==`). Seed in `start!` after `deal`
  (`discard_pile.unshift_cards(deck.shift_card)`). Add `draw_discard_turn` mirroring
  `draw_deck_turn` but pulling from `discard_pile` and guarding on `discard_pile.empty?` too.
  Leave `draw_deck_turn` untouched.
- **TurnResult** (`app/models/rummy/turn_result.rb`): add a `card_received_discard` field
  parallel to `card_received_deck`, with `as_json`/`from_json`/`==` symmetry.
  *Confirm when coding* — the alternative is reusing the single `card_received_deck` field;
  a distinct field is clearer and the feed isn't rendered yet, so either is cheap.
- **STI subclass** (`app/models/rummy_game.rb`): change `play_turn?(**)` to fork on the source
  param, mirroring `CrazyEightsGame#play_turn?(card:)` —
  `source == 'discard' ? game_state.draw_discard_turn : game_state.draw_deck_turn`.
- **Controller** (`app/controllers/games_controller.rb#turn_params_hash`): permit the new
  `:source` param alongside the existing `:player, :rank, :card`.
- **Presenter** (`app/presenters/rummy_game_presenter.rb`): add `discard_card` (top of the
  discard pile, for display) and `can_take_discard?` (`can_draw? && discard pile not empty`).
  `can_draw?` already gates the deck button.
- **View** (`app/views/rummy_games/_phase1.html.slim`): inside the existing
  `if @presenter.can_draw?` block, render two buttons — the existing "Draw from Deck" (submits
  `source: 'deck'`) and a new "Take Discard" (submits `source: 'discard'`, gated on
  `can_take_discard?`), each via a hidden `source` field. The board's pile display
  (`_game_board`) can show the discard top; the view design specs deck + discard side-by-side,
  mirroring `crazy_eights_games/_game_board`, but the board visual can stay minimal for this
  slice if time is tight.

**Mid-way "am I on track?" check:** model spec green for `draw_discard_turn` (draws top
discard, sets `has_drawn`, empty-pile + already-drawn both return `nil`) **and** the
serialization round-trip preserving `discard_pile` (`Implementation.load(dump(game))`).

**Error/recovery:** an illegal draw (already drawn, or empty pile) returns `nil`;
`GamesController#play` already treats a falsey `play_turn?` as a no-op (no save), so a bad
request just re-renders — no crash, no state change. Same safety net as Card 1.

## Value

- **Business/user:** the second half of the Rummy "draw" phase — players get a real choice
  (deck vs. discard top), the first strategic decision in a Rummy turn. Also proves a second
  serialized collection (the discard pile) round-trips, which melds and win-condition will
  build on.
- **What the user experiences:** on their turn, two draw options; taking either puts the card
  in their hand and hides both buttons — and it stays that way on refresh.
- **Priority / optimize for:** speed. The risky learning happened in Card 1; this is repetition
  of known patterns, so optimize for shipping it quickly and cleanly.

## Estimate

- **2 points — X-Small (< 2 hrs);** ~2.3 with the 15% review/pairing buffer.
- Justified by near-total reuse: `DiscardPile` is ~5 lines, engine threading mirrors `has_drawn`
  exactly, `draw_discard_turn` mirrors `draw_deck_turn`, and the `play_turn?` fork mirrors
  `CrazyEightsGame`. No new serialization or reactivity patterns to discover.
- **Top risks**
  - *Scope creep past 2 hrs* — the `source`-param wiring + the two-button view + a fresh system
    spec are the only genuinely new work; if the board pile visual is polished, it grows.
    Likelihood low-medium, severity low.
  - *Serialization symmetry* — omit `discard_pile` from `as_json` **or** `json_attributes` and
    it silently drops; the round-trip spec catches it. Likelihood low (pattern now familiar).
- **Incremental fallback:** if the view runs long, the engine + model spec (DiscardPile,
  `draw_discard_turn`, seed-at-deal, serialization) is shippable on its own; the "Take Discard"
  button can slide forward.
- **Sequencing:** next after this is the **`switch_turn` card** (advance player + reset
  `has_drawn` + draw-before-end enforcement), which will also add discard-*to*-pile
  (`Rummy::Player#take_card`, discard action). Then melds/lay-off, then win condition.

## Implementation Plan

- [x] Spec-first: `spec/models/rummy/implementation_spec.rb` — `draw_discard_turn` (draws top
      discard into hand, sets `has_drawn`, no `switch_turn`; `nil` when already drawn; `nil`
      when pile empty) + `start!` seeds one discard card + serialization round-trip preserves
      `discard_pile`.
- [x] Add `app/models/rummy/discard_pile.rb` (mirror `CrazyEights::DiscardPile`).
- [x] Add `discard_pile` to `Rummy::Implementation` (ctor / `as_json` / `json_attributes` /
      `==`), seed in `start!`, add `draw_discard_turn`.
- [x] Spec-first + add `card_received_discard` to `Rummy::TurnResult` (as_json/from_json/==).
- [x] Fork `RummyGame#play_turn?` on the `source` param.
- [x] Permit `:source` in `GamesController#turn_params_hash`.
- [x] Spec-first + add `RummyGamePresenter#discard_card` and `#can_take_discard?`.
- [x] Add the "Take Discard" button to `_phase1.html.slim` (shares a `turn[source]` name/value
      pair with "Draw from Deck" so the clicked button determines source; both live under the
      existing `can_draw?` gate — no separate `can_take_discard?` gating needed since an empty-pile
      or already-drawn click is already a safe no-op in the engine).
- [x] System spec `spec/system/rummy_games_spec.rb`: take discard → card in hand + top-of-pile
      moved → both draw buttons gone → **reload** → still gone.
- [x] `bin/rubocop` (7-line method / `it` limits) + full `bundle exec rspec`.

---

## Card Note (condensed — copy-paste into Linear)

**Title:** Rummy: discard pile + draw-from-discard

**Estimate:** 2 (X-Small)

**Description:**
Adds the Rummy discard pile and the second draw option. Introduces `Rummy::DiscardPile`
(mirrors `CrazyEights::DiscardPile`), threads it through `Rummy::Implementation` with full
`as_json`/`from_json`/`==` symmetry, seeds one face-up card at deal, and adds
`draw_discard_turn` (top discard → hand, sets `has_drawn`, **no** `switch_turn`; guarded on
already-drawn and empty-pile). `RummyGame#play_turn?` forks on a new `source` param
(`deck`/`discard`), mirroring `CrazyEightsGame`. Reuses all Card-1 patterns.

**Acceptance criteria**
- On my turn I see two options: **Draw from Deck** and **Take Discard**; taking either moves a
  card to my hand.
- After drawing, both draw buttons are hidden and stay so **after a page reload** (state
  persisted).
- A second draw in the same turn is a no-op; taking from an empty discard pile is a no-op.
- The discard pile round-trips through jsonb serialization.
- Model spec + system spec (incl. persist-across-reload) green; `bin/rubocop` clean.

**Out of scope (later cards):** `switch_turn` / turn-ending (own card), discarding a card *onto*
the pile (rides with switch_turn), empty-stock reshuffle, melds, lay-off, win condition.

**Note for reviewers:** `switch_turn` is deferred, so the turn intentionally sits open after
drawing — you can draw once (deck or discard) and it doesn't end. Expected for this slice.
