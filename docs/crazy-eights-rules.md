# Crazy Eights — rules as implemented

Source of truth: `app/models/crazy_eights/`. This describes the behavior the engine actually enforces.

## Setup

- Standard 52-card deck, shuffled.
- Deal:
  - **2 players:** 5 cards each (`SMALL_GAME_CARDS`)
  - **3+ players:** 7 cards each (`BIG_GAME_CARDS`)
- One card is turned up to start the **discard pile**. If it's an 8, it's reshuffled back in and another is drawn until the starter is **not** an 8.

## A turn

On your turn you either **play a card** or **draw** from the deck.

- **Playing a card** (`play_turn`): the card must match the top of the discard pile by **rank or suit** — unless it's an **8, which is wild** and may be played on anything.
  - An 8 lets you **declare the suit** in play: the engine takes any 8 from your hand and records the suit you chose (`take_card`), so the next player must match that declared suit.
  - Playing a card advances to the next player. There is no "go again" for playing.
- **Drawing** (`draw_deck_turn`): if you have no playable card, you take the top card of the deck. Drawing **does not end your turn** — you **keep drawing (and going again) until you draw a card you can play**, then play it. If the deck runs out mid-draw, it is **rebuilt from the discard pile** (all cards except the current top card, shuffled back in) so you can keep drawing.

> **Known gap (as of 2026-07-21):** the "no playable card" check and "card must be in your hand"
> validation described above are not currently enforced — `Implementation#draw_deck_turn` has the
> check commented out, and `CrazyEights::Player#take_card` doesn't verify the played card is in
> hand. See `IMPROVEMENT_CARDS.md` Card 2. Remove this note once fixed.

## Winning

- The game is over as soon as **any player empties their hand** (`game_over?`); that player is the winner.

## The turn feed

Each `CrazyEights::TurnResult` renders as exactly **one** feed bubble — either "placed a &lt;card&gt;" or "drew a card from the deck."
