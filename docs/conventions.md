# Conventions

RoleModel house style and project-specific rules that you won't infer from reading the code alone.

## Method & spec length

- **No method longer than 7 lines.** This is enforced by RuboCop (`Metrics/MethodLength: Max 7`) and actively followed — refactor rather than suppress it.
- **Every spec `it` block is also ≤ 7 lines.** `context`/`describe` blocks may be longer, but individual examples stay within the limit.

## Testing

- **TDD is the expected workflow** — write the failing spec first.
- Run tests with **`bundle exec rspec`** (the RoleModel training standard), not the parallel runner, unless you have a reason.
- Model specs mirror `app/models/` (including `go_fish/` and `crazy_eights/` subdirs); system specs live in `spec/system/` and drive a real browser via Capybara + Playwright.

## Ruby style (rubocop-rails-omakase + overrides in `.rubocop.yml`)

- **Single-quoted strings.**
- **No `# frozen_string_literal: true` magic comments** (`Style/FrozenStringLiteralComment: never`).

## Rails patterns

- **Prefer RESTful routes.** Some existing routes (`games/:id/join`, `games/:id/play`, and the state-mutating `games#show`) are pragmatic exceptions, not the pattern to copy.
- **Avoid instance variables in plain Ruby objects** (the game engine, presenters, service-style classes) — lean on locals and passed-in arguments instead. Instance variables are **fine in controllers** (e.g. `@game`, `@presenter` in `ApplicationController` subclasses), which is the normal Rails way to hand data to views.
- **Presenters** (`app/presenters/`) hold view-facing helper methods for reading engine data so views don't dig into `game.game_state` directly. There's no hard rule forbidding direct access — presenters just keep views clean.

## Serialization symmetry

Every game-engine object implements `as_json` / `self.from_json`. **If you touch one, touch the other** — a mismatch silently drops state rather than raising. See [architecture.md](architecture.md#serialization-the-jsonb-boundary).

## Generated files — don't hand-edit

- `db/schema.rb` — change via migrations.
- `app/javascript/controllers/index.js` — regenerate with `bin/rails stimulus:manifest:update` after adding a Stimulus controller.
