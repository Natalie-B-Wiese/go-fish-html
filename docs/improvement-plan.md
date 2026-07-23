# Improvement Plan — Card Game Platform

## Context

The platform is a Rails 8 / Hotwire multiplayer card-game app (Go Fish, Crazy Eights) built to
grow more games. The goal of this pass is to make the *foundation* trustworthy before adding a
third game — not to add features.

A review found the architecture is in good shape: the model/controller/routing layers are cleanly
polymorphic (STI + `to_partial_path` + `presenter_class`), and the real-time path is currently
**leak-safe** because in-game updates use a Turbo 8 *refresh* broadcast
(`broadcast_refresh_later_to self`) that carries no content — each browser re-renders `show`
against its own `Current.user`.

Two things undermine confidence:

1. **The live-update path has zero automated coverage.** Every system spec signs in a *single*
   user (`spec/support/helpers/authentication_helpers.rb`), so nothing proves that when player A
   moves, player B's screen updates — the exact source of the "it works when I click around, but
   I can't prove it" feeling. The leak-safety is also *fragile*: it holds only because the shared
   game stream never carries content; one change from `broadcast_refresh_later_to` to a content
   broadcast would push one player's hand to everyone, with no test to catch it.

2. **Per-game views are copy-pasted.** Each game ships a 4-partial Slim set
   (`_<game>.html.slim`, `_lobby.slim`, `_player_accordion.slim`, `_turn_form.html.slim`) whose
   lobby and board skeletons are near-byte-identical. This is the least-DRY part of adding a game.

Two items, done well. A third improvement and known risks are captured at the end as explicitly
deferred, so nothing gets lost. Each item can be picked up as a separate task.

---

## Item 1 — Prove the real-time path with tests (tests only; no behavior change)  ✅ DONE

> **Status: implemented.** The result diverged from the proposal below in two intentional ways,
> decided during implementation:
> - **No multi-session harness.** The originally-planned `Capybara.using_session` helper turned out
>   unnecessary: a single already-signed-in session (opened before the update, asserted against
>   with no manual `visit`/refresh in between) is enough to prove both invariants — GoodJob's
>   default async execution actually delivers the `broadcast_refresh_later_to` refresh to the open
>   page during a `:js` spec, with no test-env queue-adapter change required.
> - **One game type, not shared examples across games.** `spec/system/live_updates_spec.rb`
>   exercises the default factory game type (Go Fish) only. The mechanism under test — Turbo
>   refresh broadcast + presenter scoping by `Current.user` — is shared code, not per-game, so this
>   is treated as sufficient proof rather than a gap to fill per game.
>
> See `spec/system/live_updates_spec.rb` for the final two examples: propagation (an opponent's
> move produces a feed bubble with no manual refresh) and no-leak (the open session's hand region
> shows only its own cards — matched via `File.basename(card.to_image_name, '.*')` against the
> rendered `src`, since Propshaft fingerprints filenames as `name-hash.ext` and a naive
> full-filename substring match on `img[src]` breaks).
>
> **Update (2026-07-21):** the `:with_users` factory this item relies on (`spec/factories/games.rb`)
> gained a capacity fix while closing `IMPROVEMENT_CARDS.md` Card 1 — it now sets
> `game.player_count = evaluator.users.count` during its own player-creation loop, mirroring
> `:with_users_and_winner`, so bulk-adding users can't trip the new `Player#game_not_full`
> validation. The game's actual configured `player_count` is unaffected (the override never
> persists past `game.reload`).

### What & why
Lock in the two invariants the live path depends on, so the foundation can be refactored fearlessly:
- **Updates propagate:** when player A takes a turn, player B's board reflects it *without a manual
  refresh*.
- **No private leak:** player B's rendered board never reveals player A's hand (opponents render
  face-down as `cards/playing-card-back.jpg`).

No production code changes. This is purely additive coverage plus a reusable multi-session harness.

### Changes
1. **Multi-session auth helper** — `spec/support/helpers/authentication_helpers.rb`.
   The current `sign_in_as` writes one shared cookie jar, so it can't hold two logged-in browsers
   at once. Add a helper that signs a user into a *named* `Capybara.using_session` block (each
   session gets its own `Session` record + `session_id` cookie). Reusable infra for any future
   multiplayer test.
2. **Live-update system spec** — new `spec/system/live_updates_spec.rb` (`:js`).
   Two sessions (user1, user2) both viewing a full, started game. user1 plays a turn; assert
   user2's page updates on its own — turn badge flips to user2 / the feed shows user1's move —
   using Capybara's auto-waiting matchers, with **no** `visit`/refresh in between.
3. **Private-hand leak guard** — in the same spec (and/or a render-level check).
   Assert user2's board shows user1's cards as card-backs and never user1's real card images
   (`to_image_name`). This nails the invariant independent of the broadcast mechanism, so it fails
   loudly if someone later switches the game stream to a content broadcast.
4. **Make broadcasts fire in tests.** In-game updates go through `broadcast_refresh_later_to`
   (enqueues via ActiveJob → GoodJob). Ensure the test env runs these inline / drains the queue so
   the refresh actually reaches the browser (inline adapter for `:js` specs or
   `perform_enqueued_jobs`). Confirm against `spec/rails_helper.rb` / `config/environments/test.rb`
   before writing assertions — this is the most likely setup snag.
5. **Write 2 + 3 as RSpec shared examples** parameterized by game type, then invoke them for both
   Go Fish and Crazy Eights. A third game reuses the same examples for free.

### Tests to add/update
- New `spec/system/live_updates_spec.rb` (shared examples run for both game types).
- New/extended multi-session helper in `spec/support/helpers/authentication_helpers.rb`.
- Reuse existing factories: `:started_game`, `:with_users` (`spec/factories/games.rb`).

### How it eases extension
The multi-session harness + shared examples become the safety net every future game inherits:
adding a game means invoking the shared examples, and the platform proves live sync + no-leak for
it automatically.

---

## Item 2 — DRY the per-game views into a shared board shell  ✅ DONE

> **Status: implemented.** The result diverged from the proposal below in three intentional ways,
> decided during implementation:
> - **No `_game_shell` partial.** The shared skeleton was factored into `application/_hand` and
>   `application/_game_feed` (the latter takes a `turn_form_partial:` local); each game's thin
>   `_<game>_game.html.slim` renders the four panels directly. A wrapping shell was judged to add
>   indirection without enough payoff.
> - **The lobby became its own standalone screen**, not a branch inside the board shell. The
>   started-vs-lobby fork lives in `games/show.html.slim`; the layout swaps the container class
>   (`game-view` grid vs. a new non-grid `game-lobby`), and one shared `application/_lobby` shows
>   just player names. Both per-game `_lobby.slim` were deleted.
> - **The 4th grid slot was renamed** `books` → `extra` (and `cards` → `hand`) so no Go-Fish-only
>   concept leaks into shared layout. Each game's `_extra` owns its own panel header, so no
>   header local was needed.
>
> See [architecture.md → Views & rendering](architecture.md#views--rendering-the-board-shell) for
> the final structure.

### What & why
Collapse the duplicated Slim skeleton so a new game supplies only its game-specific regions, not a
full 4-partial copy. Shared UI partials already live in `app/views/application/` (`_game_header`,
`_feed_content`, `_turn_badge`, `_play_turn_button`) — extend that pattern to the board layout.

### The duplication (confirmed)
- `go_fish_games/_lobby.slim` and `crazy_eights_games/_lobby.slim` are byte-identical except one
  panel header ("Books" vs "Deck").
- Board partials share the same 4-panel skeleton. Identical across games: the **game-feed panel**
  (`_turn_badge` + `_feed_content` + turn form) and the **hand panel** (my cards). Differ only in:
  the **game-board panel content** (Go Fish: opponent accordions; Crazy Eights: discard/deck piles)
  and the **4th panel** (Go Fish: my Books; Crazy Eights: opponent accordions).
- `_player_accordion.slim` differs only in whether a Books count/row is shown.

### Changes
1. **New shared shell** — `app/views/application/_game_shell.html.slim`.
   Renders lobby-vs-board via `@presenter.implementation?`, the shared feed + hand panels directly
   from `@presenter`, and takes locals naming the two game-specific region partials + the 4th-panel
   header label.
2. **Thin per-game entry partials** — `_<game>.html.slim` becomes a few lines that render
   `application/game_shell` with the game's region partial names (keeps `render @presenter.game`
   dispatch working via `to_partial_path`).
3. **Small game-specific region partials** per game: the game-board region, the side/4th-panel
   region, plus the existing `_turn_form` and `_player_accordion` (kept per-game — they genuinely
   differ). Delete the two near-identical `_lobby.slim` files in favor of the shell's lobby branch.
4. Keep presenters as the seam for game-specific data (`CrazyEightsGamePresenter#playable_cards_h`,
   `#discard_card`) — no presenter changes required.

### Tests to add/update
- No new production behavior, so lean on the **existing** system specs as the safety net:
  `spec/system/go_fish_games_spec.rb`, `spec/system/crazy_eights_games_spec.rb`. They must stay
  green through the refactor (board renders, dropdowns, turn play, feed messages).
- Optional: a lightweight view/presenter spec asserting the shell renders the correct 4th-panel
  header per game, if a regression surfaces.

### How it eases extension
Adding a game drops from "copy 4 partials and keep them in sync" to "write the presenter + two
small region partials." Fixes to shared layout/markup happen once, for every game.

---

## Deferred (considered, intentionally out of scope for this pass)

Captured so they aren't lost; each is a good standalone future task.

- **Rummy (third game) — engine in progress, card by card.** View design:
  `docs/plans/rummy-view-design.md`. Built outside-in on branch `phase3-rummy`, one thin
  BRAVE-sized card at a time: draw-from-deck (`docs/plans/rummy-brave-breakdown-card-1.md`) and
  discard-pile + draw-from-discard (`docs/plans/rummy-brave-breakdown-card-2.md`), and
  discard-&-end-turn (`docs/plans/rummy-brave-breakdown-card-3.md`) are done. Next: melds/lay-off,
  then the win condition.
- **Concurrency race on `game_state`** (`app/controllers/games_controller.rb#play`, `Game#start!`
  / `#end!`): read-modify-write with no lock. A double-submit or the auto-timer
  (`autorun_turn_controller.js`) firing alongside a manual submit can clobber a turn; `start!`/
  `end!` can double-run. Fix later with `with_lock`/optimistic `lock_version` + idempotent
  lifecycle.
- **AR-level serialization round-trip test:** the `serialize :game_state, coder:` mechanism is
  tested only on the coder object, never through a real `save!`/`reload` of a `Game`. This is the
  documented "silently drops state" failure mode. A shared example that saves and reloads each
  game's `game_state` would be high-value, low-risk.
- **`Game#types` registry & `turn_params_hash` union:** the one hardcoded game list
  (`app/models/game.rb`) and the all-games param union in the controller
  (`app/controllers/games_controller.rb`) are minor extension friction; could be derived from STI
  subclasses later.
- **Duplicated cross-user broadcast fan-out** (`Game#on_new_game_created`, `Player#on_player_joined`):
  both loop `User.all.each` and hardcode Turbo Stream partial/target names in AR callbacks. Extract
  a shared `GameIndexBroadcaster` PORO. See `RAILS_AUDIT_REPORT.md` M1.
- **Presenter contract gap:** `crazy_eights_games/_game_board` reaches past `CrazyEightsGamePresenter`
  directly into `implementation.discard_pile`/`deck`; `GoFishGamePresenter` is an empty stub. See
  `RAILS_AUDIT_REPORT.md` D1.
- **Duplicated `self.load`/`self.dump` coder boilerplate** across `GoFish::Implementation` and
  `CrazyEights::Implementation` — candidate for the same shared-coder-module fix as the AR
  round-trip test item above. See `RAILS_AUDIT_REPORT.md` D2.
- **`Player#game_not_full` can crash on a blank `player_count`** (`app/models/player.rb`): the
  validation calls `game.full?` on whatever `game` it's given, including the brand-new, unsaved
  `Game.new(game_params)` built in `GamesController#create`. If the "Player count" field is
  submitted blank — nothing stops that; the form has no `required` and `Game` only has a
  `comparison` validator, not a presence one — `game.player_count` is `nil`, and `0 >= nil` raises
  `ArgumentError: comparison of Integer with nil failed` instead of failing validation gracefully
  (confirmed via `bin/rails runner` reproduction). Previously this reached `Game`'s own comparison
  validator on `@game.save` and produced a normal "can't be blank" error. Likely fix: scope the
  check to persisted games, e.g. `game.persisted? && game.full?`, since a brand-new game can't be
  full yet anyway. No test currently covers a blank `player_count` on game creation.
- **Coverage gaps:** `passwords_controller.rb` (55% line coverage) and `PasswordsMailer` (0%) are
  the lowest-covered files in the app. See `RAILS_AUDIT_REPORT.md` T1/T2.
- **`Implementation#feed` grows unbounded:** confirmed while fixing the game-feed N+1
  (`IMPROVEMENT_CARDS.md` Card 3) — nothing trims, paginates, or windows the feed array; it's
  appended to every turn and persisted whole in the `game_state` jsonb column, and every render
  re-processes the full history. The N+1 query fix doesn't address this — a long-running game
  still means an ever-growing jsonb blob and linear per-render work. Candidate fix: cap/paginate
  the rendered feed (e.g. last N turns) or archive older entries out of the hot jsonb column.

---

## Verification

- **Item 1:** `bundle exec rspec spec/system/live_updates_spec.rb` — passes; confirm it *fails* if
  you temporarily swap `broadcast_refresh_later_to` for a content broadcast
  (proves the leak guard bites) and if you stub the refresh to no-op (proves the propagation test
  bites). Then revert.
- **Item 2:** `bundle exec rspec spec/system/go_fish_games_spec.rb spec/system/crazy_eights_games_spec.rb`
  stay green through the refactor. Manually run `bin/dev` and open a game in two browsers to eyeball
  the board.
- **Whole pass:** `bundle exec rspec` (or `bin/turbo_tests`) clean, `bin/rubocop` clean (mind the
  7-line method / 7-line `it`-block limits), `bin/ci` before merge.
