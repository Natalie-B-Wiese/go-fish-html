# BRAVE Breakdown: Rummy — Game Feed for Non-Current Players

## Brainstorm

Rummy's entry partial (`_rummy_game.html.slim`) renders `'rummy_games/forms'` in the grid
slot Go Fish and Crazy Eights use for the shared `application/_game_feed` partial. That
partial is just a "Turn Action" panel wrapping the phase1/phase2/phase3 turn forms — there
is no feed content rendered there for anyone. Since `can_draw?`/`can_meld?`/`can_discard?`
are all gated on `my_turn?`, a non-current player currently sees an empty panel with no
visibility into what other players are doing.

`Rummy::TurnResult` doesn't implement `request_message`/`action_message`/`result_message`,
the methods `_feed_bubble` calls on any turn action — so this isn't a drop-in partial swap;
those methods need to be written first, the way Go Fish and Crazy Eights already have them.

Each Rummy engine action (`draw_deck_turn`, `draw_discard_turn`, `meld_turn`, `lay_off_turn`,
`discard_turn`) already pushes its own distinct `TurnResult` onto `feed` — one action, one
feed entry — so the shape matches Crazy Eights closely (one `TurnResult` per bubble) rather
than needing to describe several actions in a single entry.

**Message content, resolved during breakdown:**
- **Draw from deck** — stays generic ("X drew from the deck"); the card is hidden information
  only the drawing player should see, matching how Crazy Eights and Go Fish avoid naming
  deck-drawn cards.
- **Draw from discard, meld, lay-off, discard** — name the actual card(s), since all of these
  are already face-up/public (the discard pile top, and melds/lay-offs on the table).
- **Lay-off and meld ownership/index** — considered naming the meld's 1-based id (matching the
  `Meld #{index + 1}` label in `_meld.html.slim`), but **scrapped** — no meld index or owner
  reference needed, just the cards involved. This also means no new state needs to be added to
  `TurnResult` or its `as_json`/`from_json`.
- No error/failure states to guard against — every turn action produces a message, so there's
  no "empty bubble" case to test for.

## Approach

Follow the existing Go Fish / Crazy Eights pattern exactly — no new architecture:

1. **View restructuring** — swap `_rummy_game.html.slim`'s `render 'rummy_games/forms'` for
   `render 'game_feed', turn_form_partial: 'rummy_games/turn_form'`, consolidating
   phase1/phase2/phase3 into a new `_turn_form.html.slim`, and dropping the old panel/header
   markup from `_forms.html.slim` since `_game_feed` now supplies that chrome.
2. **`Rummy::TurnResult` message methods** — `request_message` covering the five action
   shapes; `action_message`/`result_message` likely stay empty strings, matching Crazy Eights.

**TDD path — outside-in, starting as far out as possible:**
- Start in `spec/system/rummy_games_spec.rb`: current player sees the turn forms, other
  players see the game feed. This is the spec that forces the view swap.
- That failure then drives work down into `Rummy::TurnResult`, TDD'ing each message method
  (draw-deck generic, draw-discard/meld/lay-off/discard naming cards) to ensure turn actions
  convert to the right strings.

**Known risk:** `_game_feed` expects a `turn_form_partial` local; Rummy's entry partial
currently passes none (it renders `'rummy_games/forms'` directly with no locals). The new
`_turn_form.html.slim` partial needs to be created and threaded through — this is the one
piece of plumbing that doesn't already exist elsewhere to copy from directly.

## Value

- **User value:** non-current players can follow what's happening on the board instead of
  staring at an empty panel — a real improvement to the spectating experience mid-game.
- **Business value:** polish on a game already functionally complete; not fixing a gap in
  correctness.
- **Priority:** explicitly nice-to-have at this stage of Rummy — not blocking any other
  planned card.
- **Optimize for:** speed — this is plumbing work following an established pattern, not a
  place to explore new approaches.

## Estimate

**4 points / Small** (~4 hours), +15% buffer for review/pairing (~4.5 hours). Mostly plumbing
since the pattern already exists twice in the codebase (Go Fish, Crazy Eights) to mirror.

**Risks:**
- Low likelihood, low severity: the `turn_form_partial` local isn't currently threaded
  through anywhere in Rummy's views, so creating and wiring `_turn_form.html.slim` is the one
  step without a direct existing example to copy — everything else is a straight port of the
  Go Fish/Crazy Eights shape.

**No incremental-shipping concern** — this is small enough to land as one PR; splitting
further would just be overhead.

## Implementation Plan

- [ ] Write/extend `spec/system/rummy_games_spec.rb`: current player sees turn forms, other
      players see the game feed — red first
- [ ] Swap `_rummy_game.html.slim` to `render 'game_feed', turn_form_partial:
      'rummy_games/turn_form'`
- [ ] Create `rummy_games/_turn_form.html.slim` consolidating phase1/phase2/phase3; remove the
      old panel/header markup from `_forms.html.slim`
- [ ] TDD `Rummy::TurnResult#request_message` for draw-deck (generic, no card named)
- [ ] TDD `#request_message` for draw-discard, meld, lay-off, discard (name the cards)
- [ ] Confirm `action_message`/`result_message` return empty strings (matching Crazy Eights)
- [ ] Run full system spec + model specs; `bin/rubocop`
