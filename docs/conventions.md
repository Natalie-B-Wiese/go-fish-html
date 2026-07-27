# Conventions

RoleModel house style and project-specific rules that you won't infer from reading the code alone.

## Method & spec length

- **No method longer than 7 lines.** This is enforced by RuboCop (`Metrics/MethodLength: Max 7`) and actively followed — refactor rather than suppress it.
- **Every spec `it` block is also ≤ 7 lines.** `context`/`describe` blocks may be longer, but individual examples stay within the limit.

## Testing

- **TDD is the expected workflow** — write the failing spec first.
- Run tests with **`bundle exec rspec`** (the RoleModel training standard), not the parallel runner, unless you have a reason.
- Model specs mirror `app/models/` (including `go_fish/`, `crazy_eights/`, and `rummy/` subdirs); system specs live in `spec/system/` and drive a real browser via Capybara + Playwright.
- Presenter specs mirror `app/presenters/` under `spec/presenters/` (added with `GamePresenter#user_names_by_id` — the first presenter spec in the codebase).
- **Asserting on card images in system specs**: `img[src]` is fingerprinted by Propshaft
  (`name-hash.ext`), so a full-filename substring match breaks (`to_image_name` includes the
  extension). Match on the base name only: `File.basename(card.to_image_name, '.*')`.
- **`page.within(selector)` only scopes a block — called without one it silently returns `nil`.**
  `page.within('tbody').find_all('td')` raises `NoMethodError` on `nil`; the fix is
  `page.within('tbody') { find_all('tr') }`. See `spec/system/leaderboard_spec.rb`.
- **GoodJob broadcasts fire fine in `:js` specs as-is** — `broadcast_refresh_later_to` reaches an
  already-open page via GoodJob's default async execution; no test-env queue-adapter change or
  `perform_enqueued_jobs` is needed.
- **Assigning `game_state:` on an unsaved `Game` round-trips through the `serialize` coder's dump/load
  immediately** — `SomeGame.new(game_state: engine)` does *not* keep the object graph you passed in;
  `some_game.game_state` is a freshly deserialized copy. A model spec that builds `Player`/`Implementation`
  objects directly, passes the implementation in as `game_state:`, then calls `play_turn?` must assert
  through `some_game.game_state.current_player` (etc.) afterward — not against the original objects,
  which are no longer the ones being mutated.
- **Planting a hand in a Rummy system spec? Remove those cards from the deck too.**
  `CardCollection.cards_to_h` keys by `card.to_s`, so two equal cards collapse into one entry — and
  the hand checkboxes / discard select are built from it. Setting `hand.cards = [...]` without
  `deck.cards -= [...]` leaves the planted cards in the deck, so a later draw can duplicate one and
  silently drop a checkbox. It fails only on seeds that deal the duplicate, which reads as a flake.
- **Known flake: `spec/system/users_spec.rb` "allows user to choose a state after choosing a
  country".** The `:js` example waits with a fixed `sleep(1)` for JS to repopulate the State select;
  it fails on roughly 2 of 3 whole-file runs on a clean checkout. If it's the only failure, it's not
  your change.
- **Known flake: `spec/system/games_spec.rb` "time on countdown does not reset on refresh".** Off-by-
  one-second timing race (expects the same remaining time before/after a refresh; occasionally ticks
  down by 1 in between). Passes in isolation. If it's the only failure, it's not your change.
- **`CardCollection.new(array)` stores the array reference directly (no `dup`)** — if a spec reuses that
  same array elsewhere (e.g. a `let`), mutating the collection (`push_cards`, `add_card`, a turn that draws
  a card) mutates the shared array too. Pass `.dup` when handing an array to `CardCollection.new` in a spec
  if the original array needs to stay unchanged.

## Ruby style (rubocop-rails-omakase + overrides in `.rubocop.yml`)

- **Single-quoted strings.**
- **No `# frozen_string_literal: true` magic comments** (`Style/FrozenStringLiteralComment: never`).
- **`Array#-`/`Array#include?` compare via `hash`/`eql?` (identity by default), not `==`.** `Card` now defines `eql?`/`hash` matching `==` (fixed while wiring Rummy melds — `Player#make_meld`'s `hand.cards -= meld_cards` was silently failing to remove cards, since the melded cards were different instances than the ones already in hand), so `Array#-`/`include?` work by value for `Card` now. Other value objects (`TurnResult`, `Player`, `Meld`, …) still only override `==` — for those, a membership/removal check against a freshly-constructed equal-but-different-instance object still silently no-ops. To remove/filter by value on a class without `eql?`/`hash`, use `reject { |x| x == target }`, not `-`.
- **`Metrics/ParameterLists` offenses on `Implementation` subclasses are accepted, not fixed.** Constructors grow past the default max (5) as engine state accumulates (e.g. Rummy's `deck:`/`discard_pile:`/`current_player_index:`/`feed:`/`last_drawn_card:`) — don't refactor to shrink the list and don't add an inline `# rubocop:disable` either; just leave the offense.

## Rails patterns

- **Prefer RESTful routes.** Some existing routes (`games/:id/join`, `games/:id/play`, and the state-mutating `games#show`) are pragmatic exceptions, not the pattern to copy.
- **A route can point at a controller action with no method defined** — Rails implicitly renders
  the matching view (`app/views/<controller>/<action>.html.slim`) as long as the template exists.
  `PagesController` (`rules`, `leaderboard`) relies on this: all the logic lives in the view/model
  layer, not a controller method. Use this only for simple, non-branching pages.
- **Avoid instance variables in plain Ruby objects** (the game engine, presenters, service-style classes) — lean on locals and passed-in arguments instead. Instance variables are **fine in controllers** (e.g. `@game`, `@presenter` in `ApplicationController` subclasses), which is the normal Rails way to hand data to views.
- **Presenters** (`app/presenters/`) hold view-facing helper methods for reading engine data so views don't dig into `game.game_state` directly. There's no hard rule forbidding direct access — presenters just keep views clean.
- **Same `name`, different `value` on submit buttons picks an action without JS or a hidden field.** When one form offers a choice between turn actions (e.g. Rummy's "Draw from Deck" vs. "Take from Discard"), give each `f.button` the same nested `name:` (e.g. `name: "turn[source]"`) and a distinct `value:` — only the clicked button's pair is submitted, so the controller reads the chosen action straight off the permitted param. See `app/views/rummy_games/_phase1.html.slim`.
- **`simple_form`'s `f.input as: :select` auto-adds a blank option when the field is required**, even with
  a single-item `collection:`. Pass `include_blank: false` to avoid it (and `selected:` to pre-pick a
  default) — see `rummy_games/_phase2.html.slim`'s "New Meld" dropdown.
- **A model-level `broadcast_*_to` (e.g. `self.broadcast_append_later_to`) always merges an implicit
  `<model_name.element>: self` local into the render** — the same injection `render(record, locals)`
  does via `ActionView::ObjectRenderer`. A strict-locals partial that doesn't declare that key raises
  `ArgumentError: unknown local`. This bit `_game_card.html.slim` (declared `game:, is_in_game: false`)
  when `Player` broadcast into it (`player:` collision) and when an STI `Game` subclass broadcast into
  it (`rummy_game:`/`go_fish_game:` collision). Fix: call the class-level `Turbo::StreamsChannel.broadcast_*_to`
  instead of the instance convenience method — it doesn't know about `self`, so it skips the injection.
  See `Game#add_game_to_index`, `Player#move_game_to_my_games`/`#update_user_game_card`.

## Serialization symmetry

Every game-engine **value object** (`Card`, `Deck`, `CardCollection`, `Player`, `Book`, `TurnResult`, …) implements a matching `as_json` / `self.from_json` pair. **If you touch one, touch the other** — a mismatch silently drops state rather than raising. See [architecture.md](architecture.md#serialization-the-jsonb-boundary).

**`Implementation` subclasses are the exception — don't override `self.from_json`.** The `::Implementation` base owns `from_json` and rebuilds the game from `self.json_attributes` (a hash of constructor keywords). A game with extra state keeps `as_json` and `self.json_attributes` in sync instead — each *extends* the base with `super.merge(...)` (e.g. Crazy Eights' `discard_pile`), and `==` extends with `super && ...`. Don't reference a per-game constant (e.g. `SMALL_GAME_CARDS`) from a method defined on the base: Ruby resolves constants *lexically*, not by the runtime subclass, so the base won't see the subclass's value — expose per-game values through an overridable method hook instead (see `starting_hand_size`). The flip side works in your favor for *classes*: an unqualified `Card`, `Deck`, or `CardCollection` reference inside a game's own module (e.g. bare `Deck.new` in `Rummy::Implementation`) resolves to that game's same-named subclass automatically, once one is defined — no explicit wiring needed. That's what makes the `card_class`/`deck_class` hooks above work without every call site needing to know which game it's in.

## Generated files — don't hand-edit

- `db/schema.rb` — change via migrations.
- `app/javascript/controllers/index.js` — regenerate with `bin/rails stimulus:manifest:update` after adding a Stimulus controller.
