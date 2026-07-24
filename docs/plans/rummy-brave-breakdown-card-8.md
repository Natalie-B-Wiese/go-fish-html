# BRAVE Breakdown: Rummy Stock Runs Out — refill from discard (engine)

> **Engine-only, like card 7 (Winner & Game Over).** No AR / controller / UI / feed work.
> This card implements the piece card 7 explicitly deferred: what happens when the draw
> pile (stock) empties. Card 7's non-goal note ("Stock exhaustion is NOT an end condition…
> No reshuffle behavior is being added here either") is fulfilled here.

## Brainstorm

**Scope:** Teach `Rummy::Implementation#draw_deck_turn` to handle an empty stock. Today it
calls `deck.shift_card` unconditionally; on an empty deck that returns `nil` and a `nil`
card silently enters the player's hand. This card replaces that with a **player-triggered
refill**.

**Rule (as confirmed):**

- When the stock is empty and it's the current player's turn to draw, **nothing happens
  automatically** — the player still chooses a source.
- **Draw from discard** → unchanged; normal draw from the top of the discard pile. The
  stock stays empty. (Already works via `draw_discard_turn`.)
- **Draw from deck** → the **entire discard pile is flipped over — no shuffle — to become
  the new stock**, then the player takes the top card as usual. "Flip, no shuffle" means the
  order simply reverses: the bottom of the discard pile (oldest discard) becomes the top of
  the new stock and is drawn first. Fully deterministic — no randomness to serialize.

**Out of scope / non-goals:**

- **Both piles empty → play without drawing.** If a player draws the discard pile's last
  card, the next player can face an empty stock *and* an empty discard. The intended rule
  (the player may skip drawing and still meld / lay off / discard) is a real relaxation of
  the current turn flow — `meld_turn` and `discard_turn` are gated on `drawn?` today — so it
  gets **its own later card**. This card does **not** add a guard for that case; with both
  piles empty, `draw_deck_turn` will behave as it does today. We deliberately avoid writing
  a test for temporary guard code that the later card will replace.
- **No UI / feed changes.** No "stock refilled from discard" message, no board changes. The
  draw returns a normal `TurnResult` with `card_received_deck`, exactly like a normal deck
  draw.
- **No serialization changes.** `deck` (base) and `discard_pile` (Rummy) are already
  serialized; the refill only moves cards between two already-persisted collections, so
  `as_json` / `from_json` are untouched.

## Approach

**Follow the existing engine patterns in `Rummy::Implementation`.** The change is local to
one public method plus one small private helper, both under the 7-line limit:

```ruby
def draw_deck_turn
  return nil if drawn?

  refill_deck_from_discard if deck.empty?
  card = deck.shift_card
  turn_result = TurnResult.new(current_user_id: current_user_id, card_received_deck: card)
  draw_turn(card, turn_result)
end

private

def refill_deck_from_discard
  deck.push_cards(discard_pile.cards.reverse) # flip, no shuffle → order reverses
  discard_pile.cards = []
end
```

- `deck` starts empty in this branch, so `push_cards(discard_pile.cards.reverse)` sets the
  new stock with the oldest discard at the top (index 0), which `shift_card` draws first —
  matching "flipped over."
- Reuses existing `CardCollection` primitives (`push_cards`, `shift_card`, `cards=`) — no
  new collection behavior needed.
- The `drawn?` guard and the `draw_turn` helper are unchanged; only the deck-empty branch
  is new.

**Initial spike / mid-way check:** Write the empty-deck spec first (red), add
`refill_deck_from_discard` + the `if deck.empty?` call (green). You're on track the moment
the new context passes and the existing `#draw_deck_turn` / full suite stay green.

**Error/recovery states:** None at this layer for the in-scope cases. The refill is a pure
state move over already-valid cards. The only "unhappy" state (both piles empty) is
explicitly deferred.

## Value

- **Business:** Removes a correctness gap that lets a `nil` card enter a hand, and makes
  long Rummy games actually playable past stock exhaustion — a required part of a complete,
  shippable Rummy engine.
- **User:** Players in a longer game can keep drawing instead of hitting a broken/empty
  stock; drawing from the deck "just works" and refills from the discard pile.
- **Priority:** Essential to the Rummy vertical slice — one of the last engine gaps
  alongside card 7.
- **Optimize for: quality (at small scale).** Unlike card 7's verbatim port, this is new
  logic with an order-sensitive detail (the flip). Small, but worth getting the reversal and
  the "player-triggered, not automatic" semantics exactly right, well covered by tests.

## Estimate

- **2 points (X-Small).** One new private helper + a one-line branch in an existing method,
  plus a focused spec context. New logic (not a port), so slightly above card 7's 1-point
  pure port, but still trivially small.
- **Buffer:** +15% for review/pairing is negligible at this size — a quick review pass.
- **Risks:**
  - *Likelihood low / severity low:* getting the flip order backwards (reverse vs. keep).
    Caught directly by an order-asserting spec.
  - *Likelihood low / severity low:* forgetting to clear the discard pile after the flip
    (cards duplicated across both piles). Caught by asserting the discard pile is empty
    post-refill.
- **Incremental shipping:** Already atomic. The deferred both-empty / play-without-drawing
  rule is the natural next increment and is its own card.
- **Dependencies / sequencing:** No code dependency on card 7 (Winner) — they touch
  different methods. Sequence freely. The both-empty follow-up card depends conceptually on
  this one (it extends the same draw/turn-flow area).

## Implementation Plan

- [ ] Add a `context 'when the deck is empty'` under `describe '#draw_deck_turn'` in
      `spec/models/rummy/implementation_spec.rb`: set up an empty deck + a known discard
      pile, draw from deck, assert the drawn card is the *bottom* of the old discard pile
      (flip order) — run red.
- [ ] Add `refill_deck_from_discard` (private) and the `refill_deck_from_discard if
      deck.empty?` call in `draw_deck_turn` — run green.
- [ ] Add a spec asserting the discard pile is **empty** after the refill draw (no
      duplicated cards) — confirm green.
- [ ] Add a spec asserting the new stock holds the remaining flipped cards in reversed
      order (draw again, or inspect) so the full reversal is pinned — confirm green.
- [ ] Confirm the existing `#draw_deck_turn` specs (non-empty deck) and `#draw_discard_turn`
      still pass; run `bin/rubocop` for the 7-line limit and house style.
