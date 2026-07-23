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
- **GoodJob broadcasts fire fine in `:js` specs as-is** — `broadcast_refresh_later_to` reaches an
  already-open page via GoodJob's default async execution; no test-env queue-adapter change or
  `perform_enqueued_jobs` is needed.

## Ruby style (rubocop-rails-omakase + overrides in `.rubocop.yml`)

- **Single-quoted strings.**
- **No `# frozen_string_literal: true` magic comments** (`Style/FrozenStringLiteralComment: never`).
- **`Array#-`/`Array#include?` compare via `hash`/`eql?` (identity by default), not `==`.** Value objects like `Card`/`TurnResult` only override `==`. `array - [some_value_equal_card]` or a membership check against a freshly-constructed object silently no-ops if the array holds a *different instance* with the same value — this surfaced as flaky specs when a hand-built `Card.new(...)` fixture happened to collide with a randomly dealt hand. To remove/filter by value, use `reject { |x| x == target }`, not `-`.
- **`Metrics/ParameterLists` offenses on `Implementation` subclasses are accepted, not fixed.** Constructors grow past the default max (5) as engine state accumulates (e.g. Rummy's `deck:`/`discard_pile:`/`current_player_index:`/`feed:`/`last_drawn_card:`) — don't refactor to shrink the list and don't add an inline `# rubocop:disable` either; just leave the offense.

## Rails patterns

- **Prefer RESTful routes.** Some existing routes (`games/:id/join`, `games/:id/play`, and the state-mutating `games#show`) are pragmatic exceptions, not the pattern to copy.
- **Avoid instance variables in plain Ruby objects** (the game engine, presenters, service-style classes) — lean on locals and passed-in arguments instead. Instance variables are **fine in controllers** (e.g. `@game`, `@presenter` in `ApplicationController` subclasses), which is the normal Rails way to hand data to views.
- **Presenters** (`app/presenters/`) hold view-facing helper methods for reading engine data so views don't dig into `game.game_state` directly. There's no hard rule forbidding direct access — presenters just keep views clean.
- **Same `name`, different `value` on submit buttons picks an action without JS or a hidden field.** When one form offers a choice between turn actions (e.g. Rummy's "Draw from Deck" vs. "Take from Discard"), give each `f.button` the same nested `name:` (e.g. `name: "turn[source]"`) and a distinct `value:` — only the clicked button's pair is submitted, so the controller reads the chosen action straight off the permitted param. See `app/views/rummy_games/_phase1.html.slim`.

## Serialization symmetry

Every game-engine **value object** (`Card`, `Deck`, `CardCollection`, `Player`, `Book`, `TurnResult`, …) implements a matching `as_json` / `self.from_json` pair. **If you touch one, touch the other** — a mismatch silently drops state rather than raising. See [architecture.md](architecture.md#serialization-the-jsonb-boundary).

**`Implementation` subclasses are the exception — don't override `self.from_json`.** The `::Implementation` base owns `from_json` and rebuilds the game from `self.json_attributes` (a hash of constructor keywords). A game with extra state keeps `as_json` and `self.json_attributes` in sync instead — each *extends* the base with `super.merge(...)` (e.g. Crazy Eights' `discard_pile`), and `==` extends with `super && ...`. Don't reference a per-game constant (e.g. `SMALL_GAME_CARDS`) from a method defined on the base: Ruby resolves constants *lexically*, not by the runtime subclass, so the base won't see the subclass's value — expose per-game values through an overridable method hook instead (see `starting_hand_size`). The flip side works in your favor for *classes*: an unqualified `Card`, `Deck`, or `CardCollection` reference inside a game's own module (e.g. bare `Deck.new` in `Rummy::Implementation`) resolves to that game's same-named subclass automatically, once one is defined — no explicit wiring needed. That's what makes the `card_class`/`deck_class` hooks above work without every call site needing to know which game it's in.

## Generated files — don't hand-edit

- `db/schema.rb` — change via migrations.
- `app/javascript/controllers/index.js` — regenerate with `bin/rails stimulus:manifest:update` after adding a Stimulus controller.
