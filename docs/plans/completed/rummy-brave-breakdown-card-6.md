# BRAVE Breakdown: Rummy — Lay-Offs (Engine + UI)

**Estimate:** 4 pts (Small, ~half day) + ~15% review/pairing buffer · **Priority:** core Rummy
mechanic, nothing downstream blocks on it · **Optimize for:** speed

## Brainstorm

Add the ability for a Rummy player to **lay off** — play a card (or cards) from their hand onto a
meld that is **already on the table**, extending an existing set (a 4th `7` onto three `7`s) or a
run (the `8♠` onto a `5♠-6♠-7♠` run). This card covers **both the engine and the UI**; most of the
UI is inherited from card 5 (meld UI), so the only net-new UI is a **dropdown to choose which meld**
to lay onto.

**Rules as scoped:**
- A player may lay off onto **any** player's meld on the table — not just their own.
- **Critical gating rule:** a player may only lay off if they have **created at least one of their
  own melds** earlier in the game (`current_player.melds.any?`). This is what creates the risk/reward
  tension — you can't ride on others' melds until you've committed one yourself.
- Lay-offs work **exactly like melding**: allowed after drawing (`drawn?`), any number of times per
  turn, as a mid-turn action that does **not** end the turn — the player still discards to end.
- The extended meld must remain a **valid** set or run.
- Invalid attempts return `nil` with **no state change and no message** — consistent with
  `meld_turn` / `discard_turn`. **Error/recovery UI is explicitly deferred to a later card.**

**Scope boundaries:**
- IN: `Meld#try_add_cards`, `Meld#to_s`, `Player#try_lay_off` (orchestration + eligibility),
  `Implementation#lay_off_turn`, `TurnResult#laid_off_cards` (+ reuse of the existing `meld` field),
  controller/`play_turn?` wiring, and the meld-selection **dropdown**.
- OUT: error/warning surfaces, win detection, any UI beyond the dropdown (card 5 supplies the rest).

## Approach

Follows the established Rummy engine patterns (plain-Ruby objects under `app/models/rummy/`, jsonb
serialization via `as_json`/`from_json` symmetry, thin turn-action methods on `Implementation`
mirroring `meld_turn`). The lay-off flow is a near-mirror of the `try_create_meld` → `meld_turn`
path, so it is largely pattern-following, not new invention.

**Object responsibilities (each owns its own invariant):**
- **`Rummy::Meld#try_add_cards(cards)`** — validate that the meld *with the new cards added* is still
  a legal set/run; on success mutate the meld and return non-nil; on failure return `nil` with no
  change. This is where the "does this card extend the meld?" logic lives.
- **`Rummy::Meld#to_s`** — label for the dropdown. **Run:** each card's rank+suit concatenated,
  first→last (e.g. `5♠6♠7♠`). **Set:** the rank followed by `s` (e.g. `7s`).
- **`Rummy::Player#try_lay_off(meld, cards)`** — orchestrates: check own eligibility
  (`melds.any?`), call the *target* `meld.try_add_cards(cards)`, and **only if it returns non-nil**
  remove those cards from the player's hand. Returns the result (or `nil`).
- **`Rummy::Implementation#lay_off_turn(meld_index:, cards:)`** — guard `drawn?`; resolve the target
  meld from `melds[meld_index]` (the stable cross-player ordered accessor from card 5); delegate to
  `current_player.try_lay_off`; on success build a `TurnResult`, push to `feed`; **no** `switch_turn`
  (only discard ends a turn); `nil` on any invalid input.

**No owner lookup needed — but it rests on one assumption.** A lay-off mutates exactly two things:
the target meld (gains cards) and the *current* player's hand (loses them). The current player is
always `current_player`, and `Meld#try_add_cards` **mutates the meld in place** — so the owner of
the target meld is never queried and no find-player-by-meld method is required. This is only sound
if **`Implementation#melds` returns live references to the stored `Meld` objects** (e.g.
`players.flat_map(&:melds)`), not reconstructed copies. If card 5 built `melds` by rebuilding from
JSON or mapping into fresh objects, mutating the returned meld would update a throwaway and the
owner's stored meld would silently not change — **verify this when checking card 5's shape.**

**`Rummy::TurnResult`:** add a `laid_off_cards` field and **reuse the existing `meld` field** to
point at the target meld. Extend `as_json` / `from_json` / `==` (symmetry rule — three touch points
on one object).

**UI — the dropdown (only net-new UI):** a `<select>` of every meld on the table, sourced from
`Implementation#melds`. Each **option value is the raw array index** (what `lay_off_turn` consumes);
each **option label is `1 + index` followed by `Meld#to_s`** (1-based for humans, e.g.
`3: 5♠6♠7♠`). The rest of the interaction (selecting hand cards, submitting) reuses card 5's meld
UI.

**Controller wiring:** `RummyGame#play_turn?` currently branches on draw vs. discard only; card 5
adds the meld branch and its params. Card 6 adds a **lay-off branch** plus permitting the new
`:meld` (index) param in `turn_params_hash` alongside whatever card-selection param card 5
establishes. **Follow card 5's convention here rather than inventing a parallel one.**

**Serialization note (symmetry rule):** only `TurnResult` changes JSON shape (new `laid_off_cards`;
`meld` already serialized). The extended meld persists through `Player#as_json` (already nested via
`Implementation#as_json`), so no new top-level field — but `TurnResult#as_json` **and**
`from_json` **and** `==` must all move together or state silently drops.

**Initial spike (proves the riskiest unknown first):** write `meld_spec` for `try_add_cards` — a
valid extension to a set and a valid extension to a run — and get it green. This proves the
extend-and-revalidate logic (the one genuinely new engine behavior) before wiring anything on top.

**TDD order (outside-in, one behavior at a time):**
1. `meld_spec` — `try_add_cards`: extends a set ✓; extends a run at either end ✓; rejects a
   non-matching card (`nil`, no change) ✗; `to_s` for a run and for a set; round-trip unaffected.
2. `player_spec` — `try_lay_off`: eligible (has own meld) + valid → cards leave hand, meld grows;
   ineligible (no own meld) → `nil`, no change; card not in hand → `nil`; target-meld rejects → `nil`.
3. `turn_result_spec` — `laid_off_cards` + `meld` round-trip; `==`.
4. `implementation_spec` — `lay_off_turn`: requires `drawn?`; resolves meld by index; records feed;
   does **not** switch turn; `nil` on invalid index / ineligible player.
5. System spec — dropdown lists melds with 1-based labels; laying off extends the meld on the board.

**How we'll know mid-way we're on track:** after step 2, a player can lay off in a console/spec end
to end (eligibility + extend + hand removal) with zero UI — the engine is done and the rest is
wiring the already-built card 5 UI to it.

**Error / recovery:** none this card — `nil` + no state change, matching the other turn actions.
User-facing feedback is a deferred card.

## Value

- **Business / product:** Lay-offs are a core Rummy mechanic — without them melded cards can't grow
  and the "must have melded first" rule (the game's central risk/reward lever) has no effect. Brings
  Rummy materially closer to fully playable.
- **User:** Players can extend melds (their own and opponents'), unlocking real Rummy strategy.
- **Priority:** Core to the Rummy phase, but **not on any critical path** — nothing (including the
  win-condition card) depends on lay-offs landing first, so it can slot flexibly.
- **Optimize for:** **Speed** — lean on card 5's UI and the `try_create_meld`/`meld_turn` template;
  don't gold-plate error handling (explicitly deferred).

## Estimate

- **Estimate:** **4 points — Small (~half day)**, plus ~15% buffer for review/pairing. The work is
  heavily pattern-following (mirror of the meld path) and most UI is inherited from card 5.
- **Pairing:** light — a quick check-in after the `try_add_cards` spike, then solo.
- **Top risks:**
  - *Card 5 dependency (`Implementation#melds` + meld UI).* Card 5 was **just written** by another
    agent, which largely retires this — but the dropdown and the `meld_index` resolution both assume
    its shape. Likelihood: low (now landed). Severity: medium if its `melds` ordering/shape differs
    from assumed — verify the accessor's signature before building the dropdown.
  - *Multi-card lay-off onto a run revalidating incorrectly* (e.g. laying off `8♠,9♠` at once).
    Likelihood: low. Severity: low — covered by a `try_add_cards` spec with 2 cards.
  - *Eligibility gate placed in the wrong object.* Likelihood: low. Severity: low — keep it in
    `Player#try_lay_off` (it's the player's own state), pinned by an "ineligible → nil" spec.
- **Incremental shipping:** the engine (steps 1–4) is a shippable increment on its own — a working,
  spec-covered lay-off with no dropdown — mirroring how card 4 shipped meld engine before its UI.
  The dropdown (step 5) can become its own follow-up if needed, though it's small enough to land
  together.

## Implementation Plan

- [x] Verify card 5's `Implementation#melds` accessor shape + the meld param/`play_turn?` branch it
      established (dependency check before building on it). — `melds` returns live refs
      (`players.flat_map(&:melds)`); card 5's `_phase2` form already has a placeholder `:meld` select,
      but `:meld` is **not yet permitted** in `turn_params_hash` and `play_turn?` ignores it.
- [x] Spike: `meld_spec` for `Meld#try_add_cards` — valid set extension + valid run extension →
      green (proves extend-and-revalidate).
- [x] Finish `Meld#try_add_cards`: reject non-matching card (`nil`, no change), run extension at
      both ends, multi-card lay-off, both-ends-at-once, mixed valid+invalid batches. Add `Meld#to_s`
      (run: first–last range `5♠-7♠`; set: `7s`) built on a new base-`Card#to_short_s` (+ `SUIT_GLYPHS`).
- [x] `Player#try_lay_off(meld, cards)`: eligibility gate via new public `Player#melded?` (reused by
      the form later), delegate to `meld.try_add_cards`, remove cards from hand only on non-nil.
      Specs for ineligible / not-in-hand / rejected.
- [x] `TurnResult`: add `laid_off_cards` (defaults `[]`, `|| []` fallback for old rows), reuse `meld`;
      extend `as_json` / `from_json` / `==`.
- [x] `Implementation#lay_off_turn(meld_index:, cards:)`: guard `drawn?` + `meld_index < melds.length`;
      delegate; feed entry; no `switch_turn`; `nil` on invalid. Full `implementation_spec` coverage.
- [x] Wire `RummyGame#play_turn?` lay-off branch + permit `:meld` (index) in `turn_params_hash`
      (following card 5's meld-param convention). A card selection now dispatches through a private
      `cards_turn` — blank `:meld` (the "New Meld" option) → `meld_turn`, an index → `lay_off_turn`,
      which rejects non-numeric params via `Integer(..., exception: false)`. Also tightened
      `Implementation#lay_off_turn`'s bounds check to `(0...melds.length).include?` — a negative index
      previously wrapped to the last meld.
- [x] Meld-selection dropdown: `RummyGamePresenter#meld_options_h` (options valued by raw index,
      labeled `1 + index` + `Meld#to_s`, `NEW_MELD_LABEL` first), gated by new `#can_lay_off?`
      (`can_meld?` + `melded?`) so an un-melded player only sees "New Meld". Presenter spec covers the
      label→index mapping and the gate; system spec covers the end-to-end lay-off.
- [x] Run `bundle exec rspec` + `bin/rubocop`. Suite green except a **pre-existing** flake in
      `spec/system/users_spec.rb:107` (`:js` country→state select with a `sleep(1)`; fails on a clean
      checkout too). Rubocop adds no new offenses (`bin/rubocop` runs default config, not the
      commented-out omakase inherit, so the repo baseline is noisy).

---

## Condensed Card Note

**Rummy — Lay-Offs (Engine + UI)**

**Scope:** Engine + UI. Let a player **lay off** a card (or cards) from hand onto a meld already on
the table — extending a **set** (matching rank) or **run** (same suit, contiguous). Allowed onto
**any** player's meld, but **only if the current player has laid down ≥1 of their own melds**
(`melds.any?`). Same phase rules as melding: after `drawn?`, any number of times, does **not** end
the turn (discard ends it). Invalid → `nil`, no change, no message. Only net-new UI is the
meld-selection **dropdown**; rest reused from card 5.

**Deferred:** error/warning UI, win detection.

**Approach:**
- `Meld#try_add_cards(cards)` — revalidate extended meld; mutate + return non-nil on success, else
  `nil`. `Meld#to_s` — run `5♠6♠7♠`, set `7s`.
- `Player#try_lay_off(meld, cards)` — orchestrates: eligibility gate, call `meld.try_add_cards`,
  strip from hand only on non-nil.
- `Implementation#lay_off_turn(meld_index:, cards:)` — guard `drawn?`; resolve `melds[meld_index]`;
  delegate; feed entry; **no** `switch_turn`; `nil` on invalid.
- `TurnResult` — add `laid_off_cards`, reuse `meld`; serialization symmetry.
- Dropdown — option value = raw index; label = `1 + index` + `Meld#to_s`.
- `RummyGame#play_turn?` lay-off branch + `:meld` param (follow card 5's convention).

**Spike first:** `Meld#try_add_cards` valid set + valid run extension → green.

**Estimate:** 4 pts — Small (~half day), +15% buffer. Optimize for **speed** (mirror the
meld path; inherit card 5's UI).

**Top risk:** card 5 dependency (`Implementation#melds` + meld param/UI) — just landed, so mostly
retired; verify its shape before building the dropdown.
