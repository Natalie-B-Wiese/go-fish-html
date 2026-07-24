# BRAVE Breakdown: Rummy — Melds UI

**Estimate:** 4 pts (Small, ~half day) + ~15% review/pairing buffer · **Priority:** essential for the Rummy phase (makes melds playable; unblocks lay-offs + win detection) · **Optimize for:** quality

## Context

Rummy's engine already supports laying melds — `Rummy::Meld` validation, `Player#try_create_meld`,
`Implementation#meld_turn(cards:)`, and full jsonb serialization all exist (commits through `9cfe86b`,
"meld laying — engine only, no UI"). But the feature is invisible and unplayable past draw/discard because
the **entire web layer is stubbed**: the controller has no param to carry a meld's cards, `RummyGame#play_turn?`
never calls `meld_turn`, the presenter exposes nothing about melds, and there's a literal
`TODO: insert rummy_games/phase2 here` in the turn panel. This card wires melds end-to-end: a player selects
cards during their turn and lays them down, and everyone's laid melds render on the board.

Design reference: `docs/rummy-mockups/rummy-final-design.html` (+ `mockup-extras.css`).

## Brainstorm

- **Scope = "B"**: lay a *new* meld **and** render everyone's laid-down melds on the board, plus a new
  `Rummy::Implementation#melds` accessor to expose them. **Out of scope** (later cards): lay-offs (adding a card to
  an existing meld) and win detection.
- **`melds` accessor now, not later:** card-4's plan deferred `Implementation#melds` to the lay-off card, but the
  board render needs it here — so it's pulled into this card.
- **Turn flow** (already in the engine): draw → optionally lay one *or more* melds (`meld_turn` deliberately does
  **not** `switch_turn`) → discard, which ends the turn. Because every action is its own POST → redirect →
  re-render (like draw/discard today), the meld form (phase2) is simply *present* whenever `can_meld?` and
  naturally reappears after each successful meld until discard ends the turn. No special multi-meld handling.
- **Selection UX**: a **2-column grid of checkboxes**, one per hand card (per the mockup) — not click-to-toggle.
  This means **no new Stimulus controller**; it's a plain form submit.
- **Lay-off dropdown**: keep the mockup's "New Meld" `select` for visual consistency and forward-compat, but with
  a **single "New Meld" option** for now. It gains existing-meld options when lay-offs are built.
- **Error feedback = "A" (silent)**: an invalid meld (`try_create_meld` → `nil` → `play_turn?` false → no `save!`)
  just re-renders with cards still in hand, matching current draw/discard behavior. **All flash/error messaging is
  deferred** to a dedicated later card.

## Approach

A cohesive vertical slice that follows patterns already in the codebase (mirrors the existing draw/discard path).

**Backend**
- `app/controllers/games_controller.rb` — `turn_params`: permit an array, `..., cards: []`, alongside the
  existing scalar keys (`:player, :rank, :card, :source`).
- `app/models/rummy_game.rb` — `play_turn?`: add a leading branch — if `cards` present, convert keys via
  `Card.from_key` and call the already-built `game_state.meld_turn(cards:)`. Extract a private helper to keep the
  method ≤ 7 lines, mirroring the existing `discard_turn` helper.
- `app/models/rummy/implementation.rb` — add `melds`: `players.flat_map(&:melds)` so the board can render
  everyone's melds.

**Presenter** (`app/presenters/rummy_game_presenter.rb`)
- `can_meld?` — `my_turn? && implementation.drawn?` (same window as `can_discard?`).
- `melds` — `implementation.melds` for the board, plus a small label helper (Set/Run + count) leaning on
  `Rummy::Meld#set?` / `#run?`.
- Reuse `CardCollection.cards_to_h(my_implementation_player.cards)` to feed the checkbox grid (label → `card.key`).

**Views + CSS**
- New `app/views/rummy_games/_phase2.html.slim` — guarded by `can_meld?`; the single-option "New Meld" `select`,
  the 2-col checkbox grid (`turn[cards][]` = `card.key`), and a "Lay Down Meld" submit → `play_turn_path`.
- `app/views/rummy_games/_forms.html.slim` — replace the `TODO` with `render 'phase2'` (between phase1 and phase3).
- `app/views/rummy_games/_game_board.html.slim` — render `.melds-board` (iterating `@presenter.melds`) above the
  Deck/Discard piles.
- New `app/assets/stylesheets/components/rummy.css` — port the meld styles from `mockup-extras.css`
  (`.melds-board`, `.meld`, `.meld__label`, `.meld__cards`) following BEM. **Render melds fully; defer the
  interactive collapse-long-runs** (`meld--run-collapsed` / `meld__ellipsis`) as cosmetic polish for a later card.

**How we'll know we're on track mid-way**: after the backend + presenter, a model/request spec should lay a valid
meld and see it in `implementation.melds`; then the board should show it after a manual play-through.

**Error / recovery:** silent by decision (Brainstorm "A"). Invalid submissions no-op and re-render.

## Value

- **Business / product:** Melds are the core scoring mechanic of Rummy — without this UI the engine work is
  invisible and the game is unplayable past draw/discard. It also **unblocks the remaining Rummy cards**: lay-offs
  build directly on the phase2 form + the melds-board, and win-detection depends on melds being layable.
- **User:** First time a player can actually *lay a meld* and see melds on the table — the game becomes playable
  toward a win.
- **Priority:** Essential to the Rummy phase; the natural step after the engine melds card.
- **Optimize for:** **Quality** — it's a reusable foundation for the next two cards; follow existing patterns
  rather than inventing new ones.

## Estimate

- **Estimate:** **4 points — Small (~half day)**, plus ~15% buffer for review/pairing. AI-assisted coding speeds
  the boilerplate (controller param, `Implementation#melds`, presenter methods, partial scaffolding), but the
  system-spec setup and CSS work keep it at Small rather than X-Small.
- **Where the time goes:** the **system spec** needs the current player to *hold* three cards forming a valid
  set/run — Rummy deals random hands, so this means stacking the deck or crafting a fixture `game_state`. The
  **CSS port** also needs an in-browser eyeball against the mockup, not just generated code. These are the two
  spots AI accelerates least and review time is unchanged.
- **Top risks (likelihood · severity):**
  - System-spec setup fiddliness (High · Low) — time sink, not a design risk.
  - `meld_turn` takes real `Card` objects; params carry keys — the `Card.from_key` conversion + `Card#==`
    hand-membership check must line up (Med · Med).
  - Keeping `play_turn?` ≤ 7 lines with the new branch (Low · Low) — solved with a private helper.
- **Incremental shipping:** if time runs short, the backend + `_phase2` form (laying a meld works) is shippable
  even before the `.melds-board` render is polished — though the board render is what makes it *visible*, so both
  are really needed for a complete card.

## Implementation Plan

- [ ] Model spec + `Rummy::Implementation#melds` (aggregate `players.flat_map(&:melds)`).
- [ ] Model/request spec + `RummyGame#play_turn?` meld branch (keys → `Card.from_key` → `meld_turn(cards:)`),
      valid lays / invalid returns false; private helper to stay ≤ 7 lines.
- [ ] `GamesController#turn_params` — permit `cards: []`.
- [ ] Presenter specs + `can_meld?`, `melds`, and a Set/Run + count label helper.
- [ ] `rummy_games/_phase2.html.slim` — "New Meld" select (single option) + checkbox grid + "Lay Down Meld".
- [ ] Wire `_phase2` into `_forms.html.slim` (replace the `TODO`).
- [ ] `_game_board.html.slim` — render `.melds-board` above the piles.
- [ ] `components/rummy.css` — port meld styles (BEM); full render, defer collapse.
- [ ] System spec in `spec/system/rummy_games_spec.rb`: draw → check 3 valid cards → lay → meld shows on board;
      opponent's meld visible.
- [ ] Manual play-through via `bin/dev`; run `bundle exec rspec` + `bin/rubocop`.

## Verification

- **Automated**: `bundle exec rspec spec/models/rummy` (engine + `melds`), the `RummyGame`/controller specs, the
  presenter spec, and `spec/system/rummy_games_spec.rb` for the end-to-end lay-a-meld flow. Then `bin/rubocop`
  (watch the 7-line method limit) and the full `bundle exec rspec`.
- **Manual**: `bin/dev`, start a Rummy game with two players, draw, check three cards that form a set or run, click
  "Lay Down Meld", confirm the meld leaves the hand and appears on the melds-board — and that the *opponent* sees it
  on their board too. Compare styling against `docs/rummy-mockups/rummy-final-design.html`.

---

## Condensed Card Note

**Rummy — Melds UI**

**Scope (B):** Wire melds end-to-end (engine already done). Let a player **lay a new meld** during their turn and
**render everyone's laid melds** on the board. Add `Rummy::Implementation#melds`.

**Deferred:** lay-offs, win detection, all error/flash messaging.

**Approach:**
- Controller `turn_params` — permit `cards: []`.
- `RummyGame#play_turn?` — new branch: keys → `Card.from_key` → `game_state.meld_turn(cards:)`; private helper to
  stay ≤ 7 lines.
- `Rummy::Implementation#melds` — `players.flat_map(&:melds)`.
- Presenter — `can_meld?` (my turn + `drawn?`), `melds`, Set/Run + count label helper; reuse
  `CardCollection.cards_to_h` for the checkbox grid.
- New `rummy_games/_phase2.html.slim` — single-option "New Meld" select + 2-col checkbox grid (`turn[cards][]` =
  card key) + "Lay Down Meld"; slot into `_forms.html.slim` at the `TODO`.
- `_game_board.html.slim` — `.melds-board` above the piles.
- New `components/rummy.css` — port meld styles (BEM); full render, defer collapse-long-runs.

**UX decisions:** checkbox grid (no new Stimulus); single "New Meld" dropdown option (forward-compat for
lay-offs); invalid melds fail **silently** (re-render, cards stay in hand).

**Estimate:** 4 pts — Small (~half day), +15% buffer. AI-assisted. Optimize for quality — foundation for
lay-offs + win.

**Top risk:** system-spec setup — need a valid set/run in the current player's hand, so stack the deck / craft a
fixture `game_state`.
