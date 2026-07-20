# Go Fish — rules as implemented

Source of truth: `app/models/go_fish/`. This describes the behavior the engine actually enforces.

## Setup

- Standard 52-card deck, shuffled.
- Deal:
  - **≤ 3 players:** 7 cards each (`SMALL_GAME_CARDS`)
  - **4+ players:** 5 cards each (`BIG_GAME_CARDS`)

## A turn

On your turn you **request a rank** from a specific opponent. You must already hold at least one card of that rank (`valid_request_rank?`).

- **Opponent has cards of that rank:** you take all of them. Because you received the rank you asked for, you **go again**.
- **Opponent has none ("Go Fish"):** you draw the top card from the deck.
  - If the drawn card is the rank you requested, you **go again**.
  - Otherwise your turn ends.

If you have **no cards** at the start of your turn, you draw from the deck (`draw_deck_turn`). If the deck is also empty, you are effectively **disqualified** (out of the game) and the turn passes.

## Books

- Collecting **4 cards of the same rank** forms a **book** (`Book::SIZE == 4`); those cards leave your hand.
- A book is checked/made automatically whenever you add a card.

## Winning

- The game is over when **all 13 books** have been made (`BOOKS_TO_WIN = 52 / 4`).
- Winner = the player with the **most books**. Ties are broken by the **highest-value book** (`biggest_book_value`).

## The turn feed

Each `GoFish::TurnResult` renders as **up to three** feed bubbles — a request message, an action message ("gave N cards" / "Go Fish"), and a result message (drew from deck, made a book, deck empty, disqualified, go again). Fewer bubbles appear when a player has run out of cards.
