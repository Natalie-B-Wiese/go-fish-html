# Rummy — View Design

## Context

We're adding **Rummy** as a third game to the platform (alongside Go Fish and Crazy Eights). Before touching the engine, we brainstormed **what the Rummy game page should look like** — how it maps onto the existing 2×2 board grid and the shared partial system.

The driving realization: **a Rummy turn is not a single action.** Go Fish and Crazy Eights each model a turn as one form submission → one `play_turn?` call. Rummy's turn is a *sequence* — draw, then optionally meld / lay off (repeatable), then discard — and the player must **see the card they drew before deciding what to do next.** That single fact means one form submission cannot handle a whole turn; the turn becomes **multiple server round-trips**, and the server must track *where in the turn the current player is*. This is the biggest new concept the view has to accommodate.

This document is the agreed **view design only** — the engine (`Implementation`, `Player`, meld/set/run rules, serialization) is a separate follow-up.

## The turn as a state machine (drives the whole view)

**Phase 1 — Draw.** Player must see the discard pile's top card, then choose: draw from **deck** or take the **discard top**. One submission → server resolves → board re-renders with the drawn card now in hand.

**Phase 2 — three independent actions, taken in any order** (not a wizard — the player picks whichever they want, as often as they want, and discard is the exit):
- **Make a meld** — select 3+ cards from hand (0..many melds per turn allowed). Repeatable.
- **Lay off** — add a hand card onto an existing meld. Repeatable. Can be interleaved with melding in any order.
- **Discard** — lay exactly one card on the discard pile. Always available (a player who doesn't want to meld at all can just discard immediately). **This ends the turn.** No separate "end turn" button.

**Make a Meld and Lay Off are merged into a single form** — a "target" dropdown (`New Meld` or an existing meld's stable label) plus hand-card checkboxes plus one submit button. They turned out to be nearly identical controls (both are "pick hand cards, pick a target"), so a separate Lay Off form was redundant. Discard remains its own, separate form. See `docs/rummy-mockups/rummy-final-design.html`. Every action in both phases is server-judged (see below); the view never re-implements Rummy rules in JavaScript.

> Rules detail for the engine phase: confirm whether lay-off is allowed before a player has made their own first meld (standard Rummy requires an initial meld first). The view supports either — it's an engine-side eligibility check, not a form-structure change.

## Region-by-region layout (2×2 grid, `components/game-view.css`)

The grid areas are `game-board` / `game-feed` (top row) and `hand` / `extra` (bottom row). New game adds only its region partials in `app/views/rummy_games/` plus a thin entry partial that renders them in order (mirror `app/views/crazy_eights_games/_crazy_eights_game.html.slim`).

- **`game-board` (largest) — the melds table + the piles, stacked in one scrollable panel (melds first, piles below).**
  - **Stock (deck back + count) + discard pile (top card + count)** — mirror `crazy_eights_games/_game_board.html.slim`.
  - **All players' melds**, laid out flat (NOT grouped by owner — ownership is irrelevant since melds have no points). Each meld carries a **stable label** ("Meld 1", "Meld 2", …) so it can be referenced from the lay-off dropdown.
    - **Runs render collapsed to their endpoints** — e.g. `4♥ … 9♥` with a "6 cards" badge — since a *validated* run is fully determined by its first and last card (no information lost), and the endpoints are exactly where lay-offs attach. This saves space so more melds fit. **Sets** (≤ 4 cards, same rank) render in full. Requires the presenter to expose each meld's **type** (run vs set). Optional nicety: click a collapsed run to expand the full sequence.
  - **Decided against tabs and against pinning the pile to a fixed corner** — both were explored in `docs/rummy-mockups/scrapped/` (`rummy-2-melds-tabs.html`, `rummy-3-tabs-experiment.html`, `rummy-3-pinned-corner.html`). Stacking both sections and letting the panel scroll read more clearly with 5+ melds on the table. See `docs/rummy-mockups/rummy-final-design.html` for the chosen layout.

- **`game-feed` — adaptive: turn form(s) vs feed history.** Injected via `render 'game_feed', turn_form_partial: 'rummy_games/turn_form'` (same seam as the other games). The panel rebalances by whose turn it is, because the feed's importance flips: it's noise to the active player and the whole show to a waiting one.
  - **On your turn:** the forms fill the panel; the feed collapses to a small scrollable strip (or hides). **Phase 1** shows a single deck/discard choice (dropdown). **Phase 2** shows the merged Meld/Lay-off form together with the Discard form — each posting to `play_turn_path` with an action discriminator (hidden field / distinct param) so the controller+engine knows which was submitted. Used in any order; discard ends the turn.
  - **When waiting:** no forms to show, so the feed fills the panel (keeps the waiting player engaged as melds/actions land live).
  - **Error messaging rides with the forms** — invalid-meld and other rule errors must render next to the Phase-2 forms, not buried in the collapsed feed.

- **`hand` — my hand with selectable cards.** Extend `application/_hand.html.slim` (or a Rummy variant) so cards render as **checkboxes** for multi-select melding, and single-select for discard. Card selection happens here; the meld/lay-off *targets* live in the turn form.

- **`extra` — player list.** Reuse the Crazy-Eights pattern exactly (`_extra.html.slim` + `_player_accordion.slim`): opponents with names, card counts, turn badge.

## Interaction details

- **Meld building:** checkboxes over hand cards → submit → **server judges** whether they form a legal set/run (rules stay in the engine, matching how Crazy Eights uses `playable_cards_h`). Illegal selection → error message in the feed, cards not melded. No live client-side validation / no JS-disabled button.
- **Laying off:** two selections — *which hand card* (in `hand`) + *which target meld* (a dropdown in the turn form keyed by the meld's stable label). Requires each meld to expose a stable identifier (append-only array index works).
- **Discard:** select one hand card → submit → turn ends.
- **Waiting players:** live board updates via the existing Turbo Stream `broadcast_*` pattern (melds/piles refresh as each action lands — keeps others engaged), with their own controls disabled until it's their turn — identical to Go Fish / Crazy Eights.

## What this view design implies for the engine/presenter (follow-up, not this task)

Named here only so the view has something to read — to be designed separately:
- **Mid-turn phase state** on the engine (has-drawn?, current phase) + a presenter method the phase-aware turn form and tab auto-switch can read (`my_turn?` exists; add e.g. `turn_phase`).
- **Melds collection** with stable per-meld identifiers/labels **and each meld's type (run vs set)** so the view can collapse runs to endpoints, exposed via a `RummyGamePresenter` (subclass `GamePresenter`, like `CrazyEightsGamePresenter`).
- Presenter helpers analogous to `discard_card` / `playable_cards_h` for: discard top, deck count, meldable/laid-off targets.

## Files to create / mirror

- `app/views/rummy_games/_rummy_game.html.slim` — entry partial (renders the 4 regions in order).
- `app/views/rummy_games/_game_board.html.slim` — piles + melds, stacked.
- `app/views/rummy_games/_turn_form.html.slim` — phase-aware form.
- `app/views/rummy_games/_extra.html.slim`, `_player_accordion.slim` — mirror Crazy Eights.
- Hand: extend `app/views/application/_hand.html.slim` (or a Rummy-specific variant) for checkbox selection.
- `app/presenters/rummy_game_presenter.rb` — view-facing helpers.
- CSS: extend `app/assets/stylesheets/components/game-view.css` scope for the meld layout.

## Verification (once built)

- `bin/dev`, create a Rummy game, seat enough players, confirm it starts (`game.start!` path in `GamesController#show`).
- Walk one full turn in the browser: draw (see the card appear in hand) → build a meld (try an illegal one, confirm feed error) → lay off onto a labeled meld → discard → turn passes.
- Confirm a second browser (waiting player) sees melds/piles update live and has disabled controls.
- System spec under `spec/system/` driving the full turn; presenter specs for the new helpers.
