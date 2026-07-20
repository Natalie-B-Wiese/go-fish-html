# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A web-based multiplayer card-game platform. Players sign up, create or join games in a lobby, and play turn-based card games (Go Fish, Crazy Eights) in real time. The UI updates live over WebSockets, and the app is installable as a PWA with offline support.

## Tech stack

- **Ruby on Rails 8.1** (Ruby 4.0.5), PostgreSQL via Active Record
- **Hotwire** (Turbo + Stimulus) for the front end — server-rendered HTML over the wire, no SPA framework
- **Slim** templates, **SCSS** compiled with **esbuild** (`yarn build`), **@rolemodel/optics** design system
- **GoodJob** for background jobs (backed by Postgres)
- **RSpec** + **FactoryBot** + **Capybara** with the **Playwright** driver for system tests
- **Kamal** + Docker for deployment; **Propshaft** asset pipeline

## Running the app

```sh
bin/setup            # install deps, prepare DB
bin/dev              # foreman: Rails server + `yarn build --watch` + GoodJob worker (Procfile.dev)
```

`bin/dev` runs three processes (web, js, worker). If you change JS/SCSS you need the `js` process (or run `yarn build`).

## Testing

```sh
bundle exec rspec                              # full suite
bundle exec rspec spec/models/card_spec.rb     # one file
bundle exec rspec spec/models/card_spec.rb:42  # one example by line
bin/turbo_tests                                # parallelized run (turbo_tests gem)
```

- Model specs live in `spec/models/` (mirroring `app/models/`, including `go_fish/` and `crazy_eights/` subdirs).
- System specs in `spec/system/` drive a real browser via Capybara + Playwright.
- Shared helpers are auto-required from `spec/support/**`.

## Lint & security (mirrors CI — see `config/ci.rb`, `.github/workflows/`)

```sh
bin/rubocop          # rubocop-rails-omakase house style (single quotes, no frozen-string comment, MethodLength max 7)
bin/brakeman         # static security analysis
bin/bundler-audit    # gem CVE audit
bin/ci               # runs setup + rubocop + audits together
```

## Architecture (big picture)

**Persistence vs. game logic are deliberately separated.** `Game` (STI: `GoFishGame`, `CrazyEightsGame`) is the Active Record model that lives in the lobby and tracks players, turns started/ended, and the winner. The *actual game rules* live in plain Ruby objects under `app/models/go_fish/` and `app/models/crazy_eights/` — each has an `Implementation` (the game engine), `Player`, `TurnResult`, and game-specific pieces (`Book`, `DiscardPile`). None of these are Active Record.

The engine is stored in the `games.game_state` jsonb column and (de)serialized through Rails' `serialize` with a **custom coder**: each `Implementation` implements `self.dump`/`self.load` and every value object implements `as_json`/`self.from_json`. When adding a field to any game object, you must update both `as_json` and `from_json` or it silently won't persist.

`Card`, `CardCollection`, and `Deck` are shared plain-Ruby primitives used by both games.

**Request flow:** `GamesController#show` lazily starts a game once it's full (`game.start!`) and ends it when over. `#play` validates it's the caller's turn (`game.valid_turn?`) then delegates to the STI subclass's `play_turn?`, which calls into the `Implementation`. **Presenters** (`app/presenters/`) wrap a game + the current user for view rendering (whose turn, my hand vs. opponents).

**Live updates:** models broadcast Turbo Streams (`broadcast_*_to`) on create/update to refresh lobby cards and game boards; there is no custom Action Cable channel beyond the connection.

## Conventions worth knowing

See [docs/conventions.md](docs/conventions.md) for the full list. The ones you'll trip on:

- **No method longer than 7 lines**, and **every spec `it` block ≤ 7 lines** too (`context` blocks may be longer). RuboCop enforces the method limit; it's actively followed here, not tolerated — refactor rather than disable it.
- **TDD** is the expected workflow; run tests with `bundle exec rspec`.
- **`as_json` / `from_json` symmetry**: every game-engine object serializes both ways. Change one, change the other — a mismatch silently drops state instead of raising.
- **Prefer RESTful routes** (RoleModel house style). **Avoid instance variables in plain Ruby objects** (engine, presenters) — they're fine in controllers, as usual for Rails.
- **Presenters** hold view-facing helpers for reading `game_state`; use them so views don't dig into the engine.
- **Never hand-edit `db/schema.rb`** (use migrations) or `app/javascript/controllers/index.js` (regenerate with `bin/rails stimulus:manifest:update`).
- Authentication is a hand-rolled `Session`/`Current` cookie scheme (`app/controllers/concerns/authentication.rb`), not Devise. `Current.user` / `Current.session` carry request-scoped identity.

## Key context

- [docs/architecture.md](docs/architecture.md) — the AR/engine split, jsonb serialization, request flow, presenters, live updates, lobby visibility, and how to add a new game.
- [docs/conventions.md](docs/conventions.md) — house style and project rules (7-line limit, TDD, RESTful routes, serialization symmetry).
- [docs/go-fish-rules.md](docs/go-fish-rules.md) — Go Fish rules as implemented.
- [docs/crazy-eights-rules.md](docs/crazy-eights-rules.md) — Crazy Eights rules as implemented.
