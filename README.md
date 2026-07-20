# Game Platform

A web-based multiplayer card-game platform built as a RoleModel Software learning project. Players sign up, create or join games from a lobby, and play turn-based card games — currently **Go Fish** and **Crazy Eights** — in real time. The UI updates live over WebSockets (Hotwire/Turbo), and the app is installable as a PWA with offline support.

The architecture deliberately separates persistence from game rules so that adding a new card game is straightforward. See [AGENTS.md](AGENTS.md) and [docs/architecture.md](docs/architecture.md) for the full picture.

## Tech stack

- **Ruby on Rails 8.1** (Ruby 4.0.5), **PostgreSQL** via Active Record
- **Hotwire** (Turbo + Stimulus) — server-rendered HTML over the wire, no SPA framework
- **Slim** templates, **SCSS** compiled with **esbuild**, **@rolemodel/optics** design system
- **GoodJob** for background jobs (backed by Postgres)
- **RSpec** + **FactoryBot** + **Capybara** with the **Playwright** driver
- **Kamal** + Docker for deployment; **Propshaft** asset pipeline

## Requirements

- Ruby 4.0.5 (see `.ruby-version`)
- Node 24.12.0 (see `.node-version`) and Yarn 4
- PostgreSQL

## Getting started

```sh
bin/setup      # install dependencies and prepare the database
bin/dev        # start the app (Rails server + JS build watcher + GoodJob worker)
```

`bin/dev` uses `foreman` to run the three processes defined in `Procfile.dev`:

- `web` — the Rails server
- `js` — `yarn build --watch` (rebuilds JS/SCSS on change)
- `worker` — the GoodJob background-job worker

The app is served at http://localhost:3000.

## Testing

Run the suite with RSpec:

```sh
bundle exec rspec                              # full suite
bundle exec rspec spec/models/card_spec.rb     # one file
bundle exec rspec spec/models/card_spec.rb:42  # one example by line
```

- **Model specs** (`spec/models/`) cover the game engines and shared card primitives.
- **System specs** (`spec/system/`) drive a real browser via Capybara + Playwright.

## Lint & security

These mirror CI (`config/ci.rb`, `.github/workflows/`):

```sh
bin/rubocop          # rubocop-rails-omakase house style
bin/brakeman         # static security analysis
bin/bundler-audit    # gem CVE audit
bin/ci               # run setup + lint + audits together
```

## Deployment

Deployed as a Docker container via [Kamal](https://kamal-deploy.org) (see `config/deploy.yml`).

## Documentation

- [AGENTS.md](AGENTS.md) — orientation for working in this codebase
- [docs/architecture.md](docs/architecture.md) — model relationships and the persistence/engine split
- [docs/conventions.md](docs/conventions.md) — house style and project conventions
- [docs/go-fish-rules.md](docs/go-fish-rules.md) · [docs/crazy-eights-rules.md](docs/crazy-eights-rules.md) — game rules as implemented
