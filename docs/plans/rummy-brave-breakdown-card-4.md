# BRAVE Breakdown: Rummy — Lay Down Melds (Engine)

**Estimate:** 4 pts (Small, ~half day) + ~15% review/pairing buffer · **Priority:** essential for the Rummy phase (unblocks win detection + lay-offs) · **Optimize for:** quality

## Brainstorm

Add the ability for a Rummy player to lay down **melds** — a grouping of 3+ cards that is
either a **set** (same rank) or a **run** (consecutive, same suit). This is **engine-only**;
the UI for selecting cards and rendering melds is a **follow-up card**.

**Rules as scoped:**
- A meld is 3+ cards: a **set** (same rank) or a **run** (same suit, consecutive ranks).
- **Aces are low only** (Ace = 1). `A-2-3` is a valid run; `Q-K-A` is **not** valid.
- Melds accumulate **on the player** (not a shared table area); a player may lay **zero or more**
  melds per turn, after drawing and before discarding.
- **Laying off** onto existing melds is explicitly **deferred** to a later card.
- Invalid meld attempts return `nil` with **no state change and no warning message** — consistent
  with the existing `discard_turn` pattern.
- **Win detection stays out of scope** (next card), even though melding is what empties a hand.

**Scope boundaries:**
- IN: `Rummy::Meld` value object + validation, `meld_turn`, per-player `melds`, an ordered
  cross-player `melds` accessor on the implementation, a feed/`TurnResult` entry for melds.
- OUT: lay-offs, win detection, all UI (card selection, board rendering).

## Approach

Follows the established Rummy engine patterns (plain-Ruby objects under `app/models/rummy/`,
jsonb serialization via `as_json`/`from_json` symmetry, thin turn-action methods on
`Implementation` mirroring `draw_deck_turn` / `discard_turn`).

**New value object — `Rummy::Meld`:**
- Holds its cards; exposes `valid?` (a valid set OR a valid run, size ≥ 3).
- Owns a **Rummy-specific rank order** constant with **Ace low** (`A 2 3 … 10 J Q K`),
  deliberately *separate from* `Card::RANKS` (which is Ace-high) and `Card#value`.
- Run check: single suit + consecutive by the Rummy order (sort first — cards may arrive unsorted).
- Set check: single rank.
- `as_json` / `from_json`.

**`Rummy::Player`:** add `melds` (array of `Meld`) + `add_meld`; extend `as_json` / `from_json` / `==`.

**`Rummy::TurnResult`:** add a `meld` field; extend `as_json` / `from_json` / `==`.

**`Rummy::Implementation`:**
- `meld_turn(...)` — requires `drawn?`; every card must be in the player's hand; build a `Meld`
  and require `valid?`; on success move cards hand → player's `melds`, build a `TurnResult`
  carrying the meld, push to `feed`; **does NOT** call `switch_turn` (only discard ends a turn);
  returns `nil` on any invalid input (no state change).
- `melds` reader — returns all players' melds in a **stable, deterministic order** (seat order,
  then each player's lay-down order) so a future lay-off card can address a meld by array index.

**Serialization note (symmetry rule):** three objects change their JSON shape (`Meld` new,
`Player`, `TurnResult`). Player melds persist *through* `Player#as_json` (already nested in
`Implementation#as_json` via `super`), so no new top-level implementation JSON field is needed —
but each of the three must update both `as_json` and `from_json` or state silently drops.

**Initial spike (proves the riskiest unknown first):** write `meld_spec` for just "valid set"
and "valid `A-2-3` run" and get `Rummy::Meld#valid?` green. This validates the Ace-low ordering
decision — the one place the existing `Card` primitives actively work against us — before building
anything on top of it.

**TDD order (outside-in on the engine):**
1. `meld_spec` — set valid; run valid; `A-2-3` ✓; `Q-K-A` ✗; wrong-suit run ✗; size < 3 ✗;
   mixed rank+suit ✗; round-trip `as_json`/`from_json`.
2. `player_spec` — `add_meld`; melds round-trip serialization; `==`.
3. `turn_result_spec` — `meld` field round-trips; `==`.
4. `implementation_spec` — `meld_turn` moves cards hand→melds; requires `drawn?`; rejects a card
   not in hand (returns `nil`, no change); records a feed entry; does **not** switch turn;
   `melds` returns the stable ordered array.

**Error / recovery:** none surfaced this card — `nil` + no state change. User-facing feedback
is the UI card's concern.

## Value

- **Business / product:** Melds are the core scoring mechanic of Rummy — without them there is no
  path to winning. This unblocks both the **win-detection card** and the **lay-off card**, so it's
  on the critical path for a playable Rummy game.
- **User:** No direct user-visible change yet (engine-only); the payoff lands with the UI card.
- **Priority:** Essential to the Rummy phase; the next roadmap step after draw/discard.
- **Optimize for:** **Quality** — get the validation rules (especially Ace-low runs) and the stable
  meld ordering right, since the deferred lay-off card builds directly on both.

## Estimate

- **Estimate:** **4 points — Small (~half day)**, plus ~15% buffer for review/pairing.
  (Note: 4 pts maps to Small on the RoleModel chart; confirm if Medium/8 was intended.)
- **Pairing:** light — a quick check-in after the spike proves the Ace-low ordering, then solo.
- **Top risks:**
  - *Ace-low run ordering conflicts with `Card#value` (Ace-high).* Likelihood: medium.
    Severity: low — caught immediately by the `A-2-3` / `Q-K-A` spec in the spike.
  - *Cards arrive unsorted for run detection.* Likelihood: medium. Severity: low — sort before
    checking consecutiveness; covered by a spec.
  - *Meld ordering not stable across turns, breaking future lay-off indexing.* Likelihood: low.
    Severity: medium (future card) — pin it with a deterministic-order spec now.
- **Incremental shipping:** could ship sets-only, then runs — but they're small enough to land
  together. The natural smaller increment is "valid `Meld` + `meld_turn`" without the feed entry;
  the feed is included here deliberately to exercise `TurnResult` symmetry while we're in it.

## Implementation Plan

- [ ] Spike: `meld_spec` for valid set + valid `A-2-3` run; implement `Rummy::Meld#valid?` with
      Ace-low rank order → green (proves the ordering decision).
- [ ] Finish `Rummy::Meld` validation: `Q-K-A` invalid, wrong-suit run, size < 3, mixed — and
      `as_json` / `from_json` round-trip.
- [ ] `Rummy::Player`: `melds` + `add_meld`; extend `as_json` / `from_json` / `==`.
- [ ] `Rummy::TurnResult`: add `meld` field; extend `as_json` / `from_json` / `==`.
- [ ] `Rummy::Implementation#meld_turn`: guard `drawn?` + all-cards-in-hand + `Meld#valid?`;
      move cards hand→melds; build `TurnResult`; push feed; no `switch_turn`; `nil` on invalid.
- [ ] `Rummy::Implementation#melds`: stable seat-then-lay-down-ordered array across all players.
- [ ] Full `implementation_spec` coverage for the above; run `bundle exec rspec` + `bin/rubocop`.

---

## Condensed Card Note

**Rummy — Lay Down Melds (Engine)**

**Scope:** Engine only. Let a player lay down **melds** (3+ cards): a **set** (same rank) or a
**run** (same suit, consecutive). **Aces are low only** — `A-2-3` valid, `Q-K-A` invalid. Melds
accumulate on the *player*, zero or more per turn, between draw and discard. Invalid attempts
return `nil`, no state change, no message.

**Deferred:** lay-offs, win detection, all UI.

**Approach:**
- New `Rummy::Meld` PORO — `valid?` (set or run, size ≥ 3), owns a **Rummy Ace-low rank order**
  constant *separate from* `Card::RANKS`/`Card#value` (Ace-high). Sort before checking run
  consecutiveness.
- `Rummy::Player` — `melds` + `add_meld`; serialization symmetry.
- `Rummy::TurnResult` — `meld` field; serialization symmetry.
- `Rummy::Implementation#meld_turn` — guard `drawn?` + cards-in-hand + `valid?`; move hand→melds;
  record feed; **no** `switch_turn`; `nil` on invalid.
- `Rummy::Implementation#melds` — stable seat-then-lay-down-ordered array (for future lay-off
  indexing).

**Spike first:** `meld_spec` "valid set" + "valid `A-2-3` run" → green. Proves the Ace-low
ordering, the one risk where `Card` works against us.

**Estimate:** 4 pts — Small (~half day), +15% buffer. Optimize for quality (lay-off card builds
on the validation + stable ordering).

**Top risk:** Ace-low ordering vs. `Card#value` Ace-high — caught by the spike's `A-2-3`/`Q-K-A`
specs.
