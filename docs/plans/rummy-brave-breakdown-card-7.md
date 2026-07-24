# BRAVE Breakdown: Rummy Winner & Game Over (engine)

> **This is essentially a copy-paste of Crazy Eights.** Rummy's win/game-over rule is
> identical to Crazy Eights: the game ends when a player empties their hand, and that
> player wins. Both the two methods and their specs can be lifted almost verbatim from
> `app/models/crazy_eights/implementation.rb` and
> `spec/models/crazy_eights/implementation_spec.rb`, with only Rummy-flavored spec
> scaffolding as the tweaks.

## Brainstorm

**Scope:** Implement the engine-level win condition for Rummy — replacing the two TODO
stubs in `Rummy::Implementation`:

- `#game_over?` — currently returns `false` (line ~106)
- `#winning_player` — currently returns `nil` (line ~111)

**Win rule (as confirmed):**

- The game is over the moment **any player's hand is empty**.
- The player who emptied their hand is the **winner**.
- A player can go out **either** by laying off / melding their last cards **or** by
  discarding their last card. `game_over?` should be true whenever a hand is empty, at
  any point in the turn — the two methods just inspect hand state, so they don't care
  *how* the hand became empty.

**Out of scope / non-goals:**

- **Stock exhaustion is NOT an end condition.** If the draw pile runs out before anyone
  goes out, the game simply continues; it does not trigger game over. (No reshuffle
  behavior is being added here either.)
- **No AR / controller / UI wiring.** Recording the winner and ending the game is
  already handled generically in `GamesController#show` / the `Game` STI layer and is
  tested + shared across all games. This card is engine-only.
- **No serialization changes.** Both methods are pure reads over existing player hand
  state — nothing new to persist, so `as_json` / `from_json` are untouched.

## Approach

**Follow Crazy Eights exactly — it is the established pattern for this identical rule.**

Port the two methods verbatim:

```ruby
def game_over?
  players.any? { |player| player.cards.empty? }
end

def winning_player
  players.find { |player| player.cards.empty? }
end
```

- `Rummy::Player` already responds to `cards` (the engine uses `current_player.cards`
  elsewhere), so the logic drops in unchanged.
- Replace the two existing TODO stubs; remove their `# TODO:` comments.

**Specs:** Copy the `describe '#game_over?'` and `describe '#winning_player'` blocks from
`spec/models/crazy_eights/implementation_spec.rb` into
`spec/models/rummy/implementation_spec.rb`. The **tweaks** are only in the scaffolding,
not the assertions:

- Use Rummy's players/factories and `Rummy::Implementation`.
- Rummy's `start!` deals a different hand size and has no "never start on an 8" rule —
  drop any 8-specific setup.
- Keep the same two contexts per method: all players have cards → not over / `nil`; a
  player is out of cards → over / returns that player.

**Initial spike / mid-way check:** Write the two `describe` blocks first (red), drop in
the two methods (green). You'll know you're on track the instant those specs pass and the
full suite stays green — there are no interactions with other engine methods to worry
about.

**Error/recovery states:** None meaningful at this layer. The methods are total (never
raise); a hand is either empty or not. Nothing for the user to "get wrong" here.

## Value

- **Business:** Completes the core Rummy engine loop — with a win condition, a Rummy game
  can actually *end* and declare a winner, which is the last engine gate before Rummy is a
  fully playable game end-to-end.
- **User:** Players see a game conclude and a winner recorded (via the already-built shared
  end-game wiring) instead of a game that never resolves.
- **Priority:** Essential to finishing the Rummy vertical slice; small and unblocking.
- **Optimize for: speed.** This is a known, mechanical port — no learning or design
  exploration needed. Get it in, keep the suite green.

## Estimate

- **1 point (XS).** A two-method port plus two `describe` blocks copied and lightly
  adjusted. No AR/UI/serialization surface.
- **Buffer:** +15% for review/pairing is negligible at this size — a quick review pass.
- **Risks:** None material.
  - *Likelihood low / severity low:* spec scaffolding drift (wrong hand size or leftover
    8-specific setup copied from Crazy Eights). Caught immediately by a green/red run.
- **Incremental shipping:** Already atomic — nothing smaller worth splitting out.
- **Dependencies / sequencing:** Logically the **last** Rummy engine card (after melds UI
  = card 5 and lay-offs = card 6). It has no code dependency on those — the methods only
  read hand emptiness — but it's the natural capstone. Winner *recording* depends on the
  shared `Game`/controller layer, which already exists and is tested.

## Implementation Plan

- [ ] Add `describe '#game_over?'` to `spec/models/rummy/implementation_spec.rb`
      (not-over + out-of-cards contexts), adapted to Rummy scaffolding — run red.
- [ ] Replace the `#game_over?` TODO stub with the `players.any? { |p| p.cards.empty? }`
      implementation — run green.
- [ ] Add `describe '#winning_player'` (returns `nil` when all have cards; returns the
      empty-handed player otherwise) — run red.
- [ ] Replace the `#winning_player` TODO stub with the
      `players.find { |p| p.cards.empty? }` implementation — run green.
- [ ] Remove both `# TODO:` comments; run the full engine spec + `bin/rubocop` to confirm
      the suite is green and style-clean.
