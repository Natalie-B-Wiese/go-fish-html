# Architecture & model relationships

This project deliberately splits **persistence** (Active Record) from **game rules** (plain Ruby). Understanding that boundary is the key to working here.

## The two halves

### 1. Active Record layer (the lobby & persistence)

- **`Game`** — STI base class (`app/models/game.rb`). Concrete types: **`GoFishGame`**, **`CrazyEightsGame`** (the `type` column). Tracks lobby state: `name`, `player_count`, `started_at`, `ended_at`, `archived_at`, `winner`, and the serialized `game_state` (jsonb).
- **`Player`** — join model between `User` and `Game`. This is *not* the in-game player; it just records "this user is in this game."
- **`User`** — `has_secure_password`; `has_many :games, through: :players`.
- **`Session`** / **`Current`** — hand-rolled cookie auth (see `app/controllers/concerns/authentication.rb`). `Current.user` / `Current.session` carry request-scoped identity.

The AR layer knows *almost* nothing about game rules. The one intentional exception: the STI subclass's `play_turn?` will draw from the deck for a player who has no valid card to play (a "draw" turn). Otherwise rules live entirely in the engine.

### 2. Game engine layer (plain Ruby, no DB)

Under `app/models/go_fish/` and `app/models/crazy_eights/`, each game has:

- **`Implementation`** — the rules engine. `GoFish::Implementation` and `CrazyEights::Implementation` both subclass a shared **`::Implementation`** base (`app/models/implementation.rb`) that owns the common state (`players`, `deck`, `feed`, turn index) and shared behavior (serialization, `==`, `switch_turn`, dealing); subclasses add their own state (Crazy Eights' `discard_pile`) and fill in hooks. Exposes turn methods (`request_opponent_turn`, `draw_deck_turn`, `play_turn`), `game_over?`, `winning_player`, `current_user_id`.
- **`Player`** (`GoFish::Player` / `CrazyEights::Player`) — an in-game player holding a hand. Linked to the AR `User`/`Player` **only by `user_id`**. There are deliberately two "Player" concepts; don't conflate them.
- **`TurnResult`** — a record of what happened on one turn; used to render the game feed (see below).
- Game-specific pieces: `GoFish::Book`, `CrazyEights::DiscardPile`.

Shared primitives used by both engines: **`Card`**, **`CardCollection`**, **`Deck`** (all plain Ruby).

The engine knows nothing about the database.

## Serialization: the jsonb boundary

`game_state` is a **jsonb** column. Rails' `serialize` uses each `Implementation` as a **custom coder**:

```ruby
class GoFishGame < Game
  serialize :game_state, coder: GoFish::Implementation
end
```

- `Implementation.dump(obj)` → `obj.as_json`
- `Implementation.load(json)` → `Implementation.from_json(json)` (nil-safe)

Every value object in the engine (`Player`, `Card`, `CardCollection`, `Deck`, `Book`, `TurnResult`, `Implementation`) implements a matching `as_json` / `self.from_json` pair.

The shared `::Implementation` base implements the common half: `dump`/`load`, `as_json`, `from_json` (via an overridable `self.json_attributes` hook), and value `==`. A game with extra state *extends* rather than replaces these — Crazy Eights adds `discard_pile` by overriding `as_json` and `json_attributes` with `super.merge(discard_pile: …)` (hashes) and `==` with `super && discard_pile == other.discard_pile` (boolean). The per-game `self.player_class` / `self.turn_result_class` class methods tell the inherited `from_json` which objects to build.

**The rule that bites people: if you add or change a field, update BOTH `as_json` and `from_json`.** A mismatch doesn't raise — the field silently fails to persist or round-trip. (In practice jsonb itself has caused no trouble as long as the two stay in sync.)

## Request flow

1. **`GamesController#show`** builds a presenter, then **lazily starts the game** (`game.start!`) once it's full, and **ends it** (`game.end!` → redirect to history) once `game.game_over?`. Note this means a **GET can mutate state** — intentional for now, though a more RESTful approach is a possible future improvement.
2. **`GamesController#play`** checks `game.valid_turn?` (is it this user's turn?) then calls the STI subclass's `play_turn?(**turn_params)`, which translates params into an engine call and returns truthy on success. On success the game is saved (re-serializing `game_state`).
3. **Presenters** (`app/presenters/`) wrap a `game` + the current `user`. They are *convenience helpers* for views to read engine data (my hand vs. opponents', whose turn, etc.) without reaching deep into `game_state`. Using them is preferred, but there's no hard "views must never touch the implementation" rule.

## The feed (game log)

`Implementation#feed` is an array of `TurnResult`s rendered as chat-like "bubbles":

- **Crazy Eights:** one `TurnResult` → **one** feed bubble.
- **Go Fish:** one `TurnResult` → **up to three** bubbles (`request_message`, `action_message`, `result_message`), fewer when a player has run out of cards.

## Live updates (Turbo Streams)

Models broadcast Turbo Streams on commit (`broadcast_*_to 'games', user, ...` in `Game` and `Player`; `broadcast_refresh_later_to` for game boards) to update lobby cards and game state in real time. There is no custom Action Cable channel beyond `ApplicationCable::Connection`.

**`broadcast_refresh_later_to` carries no content** — it only signals connected clients to
re-fetch the current page, so each browser re-renders `show` against its own `Current.user`.
This is why the live path can't leak one player's hand to another's screen just by being
live-updated; `spec/system/live_updates_spec.rb` locks this in.

## Views & rendering (the board shell)

The game screen is a **4-panel CSS grid**, and its shared skeleton is factored into
`app/views/application/` so games don't copy it:

- **Shared partials** — `_hand` (the "Hand" panel), `_game_feed` (the "Game Feed" panel skeleton;
  takes a `turn_form_partial:` local so the game-specific form drops in by name), and `_lobby`
  (one game-neutral waiting room showing the game name + player names). Plus the smaller shared
  bits already used across the app: `_game_header`, `_feed_content`, `_turn_badge`,
  `_play_turn_button`.
- **Per-game region partials** in `app/views/<game>_games/` — `_game_board`, `_extra`,
  `_turn_form`, `_player_accordion`. These genuinely differ per game (e.g. Go Fish's `_extra` shows
  your Books; Crazy Eights' shows the opponent list). Region partials **read `@presenter`
  directly** rather than taking locals, which is what lets the shared feed render any game's turn
  form generically.
- **Thin entry partial** — `_<game>_game.html.slim` is just the four renders in order:
  `game_board`, `game_feed` (with `turn_form_partial:`), `hand`, `extra`.

**The fork between lobby and board is in `games/show.html.slim`**, keyed on
`@presenter.implementation?` (nil until the game starts): started → `render @presenter.game`
(dispatched to the entry partial by `to_partial_path`); not started → shared `application/_lobby`.
`turbo_stream_from @presenter.game` lives here so both states live-update (the lobby flips to the
board on its own when the game fills).

**The layout picks the container class, not the content.** `layouts/application_game.slim` sets
`main`'s class to `game-view` when playing or `game-lobby` in the lobby (reading `@presenter`,
which `GamesController#show` sets — the view renders before the layout, so it's always present).
All grid rules are scoped under `.game-view` in
`app/assets/stylesheets/components/game-view.css` (grid areas: `game-board` / `game-feed` /
`hand` / `extra`); the lobby's non-grid centered layout is `game-lobby.css`. Swapping the class is
enough to opt the lobby out of the grid entirely.

## Lobby visibility & cleanup

The index (`app/views/games/index.html.slim`) splits games into "Your Games" and "All Games", with these visibility rules:

- Only games where `ended_at` **and** `archived_at` are nil appear at all.
- **A game that is full and does not include the current player does not show up on that player's index page** — you can only see a full game if you're in it. (Non-full games remain visible so others can join.)
- **`GamesCleanupJob`** (GoodJob) archives games untouched for more than a day: `Game.where(archived_at: nil).where('updated_at <= ?', 1.day.ago).update_all(archived_at: ...)`. This keeps stale in-progress games from cluttering the lobby.

## Adding a new card game (the extension point)

The whole design exists to make this straightforward:

1. Add a `NewGame < Game` STI subclass with `serialize :game_state, coder: NewGame::Implementation`, a `create_and_start_game`, and a `play_turn?`.
2. Build the engine under `app/models/new_game/` (`Implementation`, `Player`, `TurnResult`, …). `NewGame::Implementation` **subclasses `::Implementation`** and implements the hooks it raises `NotImplementedError` for: `self.player_class`, `self.turn_result_class`, `start!`, `game_over?`, `winning_player`, and private `starting_hand_size`. It inherits `from_json`, `as_json`, `==`, `switch_turn`, and dealing — only override `as_json` + `self.json_attributes` + `==` (via `super`) if the game adds state beyond the shared `players`/`deck`/`feed`/`current_player_index`. Every value object still needs its own `as_json`/`from_json`.
   **Validate turn input against actual game state before mutating** — mirror Go Fish's
   `valid_request_rank?`/`includes_card_with_rank?` guards before acting on a turn. Crazy Eights
   shipped without this and allowed playing a card not in the player's hand.
3. Add it to `Game#types`, add a presenter, and specs mirroring `spec/models/new_game/`.
4. For views, you only need the **region partials** under `app/views/new_game_games/`
   (`_game_board`, `_extra`, `_turn_form`, `_player_accordion`) plus a thin `_new_game_game.html.slim`
   entry partial — the board shell, hand, feed, and lobby are already shared in
   `app/views/application/`. See [Views & rendering](#views--rendering-the-board-shell).

Keep every method (and every spec `it` block) to **7 lines or fewer** — see [conventions.md](conventions.md).
