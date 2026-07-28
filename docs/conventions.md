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
  `page.within('tbody') { find_all('tr') }`. See `spec/system/leaderboards_spec.rb`.
- **GoodJob broadcasts fire fine in `:js` specs as-is** — `broadcast_refresh_later_to` reaches an
  already-open page via GoodJob's default async execution; no test-env queue-adapter change or
  `perform_enqueued_jobs` is needed.
- **A system spec's `have_content` can false-positive match an error page.** System specs drive a
  real browser against a real server, so a Ruby exception can't propagate back to RSpec — it
  renders as an HTML error page instead, and the test still "passes" if the expected string is a
  substring of that page's text. Bit us when `expect(page).to have_content 'Leaderboard'` matched
  the routing-error page for a missing `LeaderboardsController#index` action, since `'Leaderboard'`
  is a substring of `'LeaderboardsController'`. Assert on content specific enough that an error
  page can't coincidentally contain it (e.g. a real column header, not the resource name).
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
  `PagesController#rules` relies on this: all the logic lives in the view/model
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

## Database views (Scenic)

- **Postgres `interval` columns come back as `ActiveSupport::Duration`, not a plain number.** A
  view column like `SUM(games.ended_at - games.started_at)` is cast automatically by the `pg`
  adapter/ActiveRecord. Use `.in_minutes`, `.in_hours`, or `.to_i` (seconds) rather than assuming
  a raw numeric — see `Leaderboard#total_time_played`.
- **Hand-editing a new versioned view SQL file (e.g. `db/views/foo_v02.sql`) without running the
  generator confuses the next `rails generate scenic:view` call.** It detects the highest existing
  version file and assumes a migration for it already exists, so it skips straight to `v03` —
  producing a duplicate file and a migration for the wrong version range. Either always use the
  generator to create the next version file, or hand-write the `update_view` migration yourself
  (`version: N, revert_to_version: N-1`) to match a manually-created SQL file.

## Sorting & filtering (Ransack)

- **Ransack 4+ raises unless the model whitelists columns.** Define `self.ransackable_attributes(_auth_object = nil)`
  returning only the columns you actually want sortable/searchable — see `Leaderboard`. Omitting the method entirely
  fails closed (raises), not open.
- **Marking the active sort button:** a plain helper (`LeaderboardsHelper#active_sort_class`) compares
  `query.sorts.first&.name` to the attribute name to decide whether to add `btn--active`. `sort_link` itself has
  no built-in "is this the current sort" hook for custom styling — you have to inspect `@q.sorts` yourself.
- **A misspelled predicate suffix (e.g. `games_won_greg` instead of `games_won_gteq`) raises, not silently
  ignores the filter.** Ransack parses the field name as `<attribute>_<predicate>` at query time, so it's easy to
  typo the predicate half and not notice until the form errors.
- **`search_form_for` accepts `builder: SimpleForm::FormBuilder`**, which pulls in this app's existing
  simple_form config (`form-group`/`form-label`, `btn btn--primary` defaults from
  `config/initializers/simple_form.rb`) instead of hand-writing Optics wrapper markup — see the leaderboard
  filter form in `app/views/leaderboards/index.html.slim`.

## Pagination (Kaminari)

- **`rails g kaminari:views` crashes on Rails 8.1** (`NoMethodError: private method 'warn' called for
  class ActiveSupport::Deprecation`, from `kaminari-core`'s generator calling a deprecation API Rails 8.1
  removed). The Optics-styled partials in `app/views/kaminari/` were hand-written from the gem's own
  default templates instead of generated.
- **Disabled pagination buttons (first/prev/next/last at the boundary) render as a non-link `<span>`
  with `btn--disabled`, not Kaminari's default bare-text fallback.** `link_to_unless`'s disabled branch
  just prints the content with no wrapping tag, which would drop the Optics `btn` classes entirely —
  each partial branches explicitly instead so the disabled state keeps its button styling.
- **`config/locales/en.yml` overrides `views.pagination.previous`/`next`** to plain "Prev"/"Next".
  Kaminari's own default locale bakes in `&lsaquo;`/`&rsaquo;` arrow entities, which doubled up with the
  Optics `ph-caret-*` icons already in those partials.
- **Slim escapes HTML entities by default — unlike the gem's ERB originals, `t(...)` needs an explicit
  `.html_safe`.** `_gap.html.slim`'s ellipsis (`t('views.pagination.truncate')`) printed literal
  `&hellip;` text until `.html_safe` was added back; easy to drop when porting an ERB partial to Slim.
- **`config/initializers/kaminari_config.rb`'s `default_per_page`/`max_per_page` are currently a no-op.**
  `LeaderboardsController#index` calls `.per(10)` explicitly, and an explicit `.per` always wins over
  `config.default_per_page`; `max_per_page` only matters if something (e.g. a `per_page` query param)
  lets a caller request more than that. Neither applies until the hardcoded `.per(10)` is replaced with
  a user-adjustable per-page value.

## Optics / CSS

- **The Optics CDN import in `application.css` is a hand-written version string, separate from
  `yarn.lock`.** `node_modules`/`yarn.lock` can be ahead of the pinned CDN URL (found this at 2.3.1
  vs. 2.4.0 in `node_modules`) — if a utility class documented in Optics docs seems to do nothing,
  check both versions agree before assuming a markup bug.
- **`stylesheet_link_tag :app` auto-links every file under `app/assets/stylesheets/**` individually**
  (Propshaft convention, no manifest/`@import` needed) — dropping a new `.css` file under
  `components/` is enough for it to load on the next request.
- **A right sidebar that stays fixed while the page scrolls is `.op-page__sidebar.op-page__sidebar--right`**,
  Optics' own grid area (`position: sticky`, `block-size: 100dvh`) — not something you need to hand-roll
  with custom `position: fixed` CSS. It expects a `.side-panel` (or similar) as its child.
- **`.side-panel`'s width is a public CSS custom property (`--_op-side-panel-width`), meant to be
  overridden inline per instance** rather than via a new CSS rule — e.g.
  `style="--_op-side-panel-width: calc(56 * var(--op-size-unit));"` to narrow one specific sidebar
  without affecting other `.side-panel` usages.
- **`.op-split`'s `flex-wrap` decision is based on children's unwrapped (max-content) width, not
  their shrunk size** — two fields with long labels will wrap onto separate lines even in a wide
  container, and even with small inputs, because the label text alone doesn't fit unwrapped. Fix by
  giving the children `flex: 1 1 0; min-inline-size: 0` so they can shrink and let the label wrap
  inside its half — see `.input__pair` in `app/assets/stylesheets/components/input-pair.css`.

## Generated files — don't hand-edit

- `db/schema.rb` — change via migrations.
- `app/javascript/controllers/index.js` — regenerate with `bin/rails stimulus:manifest:update` after adding a Stimulus controller.
