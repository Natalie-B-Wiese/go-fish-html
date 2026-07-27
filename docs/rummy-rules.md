# Rummy — rules as implemented

Source of truth: `app/models/rummy/`. This describes the behavior the engine actually enforces.

## Setup

- Standard 52-card deck, shuffled.
- Deal:
  - **2 players:** 10 cards each (`SMALL_GAME_CARDS`)
  - **3-4 players:** 7 cards each (`MEDIUM_GAME_CARDS`)
  - **5-6 players:** 6 cards each (`BIG_GAME_CARDS`)
- One card is turned up to start the **discard pile**.

## A turn

On your turn:

1. **Draw a card** from either the deck or discard pile (`draw_deck_turn` / `draw_discard_turn`).
2. **Meld and/or lay off** as many times as you like (both are optional):
   - A **meld** is 3+ cards forming either a **set** (same rank, any suits) or a **run** (consecutive ranks, same suit). Once melded, those cards leave your hand and are placed on the table.
   - A **lay-off** is adding 1+ cards from your hand to an existing meld (on the table or from other players). You can only lay off after creating at least one meld.
3. **Discard one card** to end your turn. You cannot discard the card you just drew, unless it is your only remaining card (`discardable_cards`).

## Winning

- The game is over as soon as **any player empties their hand** (`game_over?`); that player is the winner.

## Deck refill

- When the deck runs out of cards, the discard pile is **flipped over** (reversed) and becomes the new deck (`refill_deck_from_discard`).

## The turn feed

Each `Rummy::TurnResult` renders feed bubbles for card draws, melds, and lay-offs.

## Hand sorting

A player can sort their own hand by rank or by suit, via buttons in the Hand panel
(`Rummy::Player#sort_preference`, persisted per-player in `game_state`). It works regardless of
whose turn it is. Both modes break ties using the same suit order — **Clubs, Diamonds, Spades,
Hearts** (`Card::SUITS`) — so a "sort by rank" hand groups same-rank cards in that suit order, and
a "sort by suit" hand groups suits in that order before sorting by rank within each suit.
