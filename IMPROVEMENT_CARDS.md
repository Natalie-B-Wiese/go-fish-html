# Improvement Cards

Selected from the `/rails-audit` (see `RAILS_AUDIT_REPORT.md`) and `/improve-codebase-architecture` assessments run on 2026-07-21. Prioritized as correctness bugs first; each is scoped to ~1-2 hours.

---

## Card 1: Prevent joining a game that's already full

**Title**: Add capacity check to `GamesController#join`

**Goal**: A player attempting to join a game whose `players.count` already equals `player_count` is redirected back with an alert instead of being added. `Game#full?` (already defined) governs the check. A test covers both the "game has room" and "game is full" cases.

**Why**: The audit found the bug already flagged in the code itself — `app/controllers/games_controller.rb:34` carries `# TODO: don't let them join a game that is full`. Nothing currently calls `game.full?` before `Player.create` in the `join` action, so a game can be over-joined past its configured player count, which would corrupt turn order and player-count assumptions baked into `create_and_start_game` (e.g. `GoFish::Implementation#deal!`'s small/big game split at `players.length <= 3`).

**Files and code referenced**:
- `app/controllers/games_controller.rb:31-43` (the `join` action)
  ```ruby
  def join
    game = Game.find(params[:id])

    # TODO: don't let them join a game that is full

    # prevents user from joining a game they are already in
    if Player.create(user: Current.user, game: game)
      redirect_to show_game_path(game)
    else
      flash.now[:alert] = 'There was a problem joining a game.'
      render :index, status: :unprocessable_content
    end
  end
  ```
- `app/models/game.rb:44-46` — existing `full?` method to guard with:
  ```ruby
  def full?
    num_joined_players >= player_count
  end
  ```

---

## Card 2: Reject Crazy Eights card plays for cards not in the player's hand

**Title**: Validate `CrazyEights::Player#take_card` against the player's actual hand

**Goal**: Submitting a `rank`/`suit` the current player doesn't hold no longer succeeds as a legal play — `take_card` returns `nil` in that case, and the failure propagates up through `Implementation#play_card` / `play_turn` / `CrazyEightsGame#play_turn?` so `GamesController#play` doesn't persist the turn. A test confirms a turn attempting to play a card outside the player's hand is rejected and the game state is unchanged.

**Why**: The audit found `take_card` always returns a freshly constructed `Card.new(rank, suit)` even when the card lookup (`cards.find { ... }`) comes back `nil` — meaning a crafted turn request can "play" a card the player never held, since nothing downstream checks for this failure. Go Fish already has the equivalent guard (`GoFish::Implementation#valid_request_rank?` checks `current_player.includes_card_with_rank?(rank)` before acting) — Crazy Eights never got the matching validation, and there's dead commented-out code in `CrazyEights::Implementation#draw_deck_turn` suggesting this gap was known but never closed.

**Files and code referenced**:
- `app/models/crazy_eights/player.rb:29-35` (the bug)
  ```ruby
  def take_card(rank, suit)
    card_taken = if rank == '8'
                   cards.find { |card| card.rank == rank }
                 else
                   cards.find { |card| card.rank == rank && card.suit == suit }
                 end

    hand.cards -= [card_taken]
    Card.new(rank, suit)
  end
  ```
- `app/models/crazy_eights/implementation.rb:140-144` (`play_card`, calls `take_card` with no nil check) and `:33-43` (`draw_deck_turn`'s dead commented-out validation, same theme)
- `app/models/crazy_eights_game.rb:15-24` (`play_turn?`, where a `nil`/false result needs to propagate to stop `GamesController#play` from saving)
- Reference pattern already correct in `app/models/go_fish/implementation.rb:119-125` (`valid_opponent?`/`valid_request_rank?`) and `app/models/go_fish/player.rb:60-65` (`includes_card_with_rank?`)

---

## Card 3: Fix N+1 query building game-feed turn messages

**Title**: Stop querying `User.find` per turn result in the game feed

**Goal**: Rendering a game's feed no longer issues one `User.find` query per historical turn result per user lookup. `current_user_name`/`opponent_user_name` in both `TurnResult` classes resolve names from data already available to the presenter (e.g. a `{user_id => name}` hash built once per request) instead of querying per call. A test/benchmark confirms the query count for rendering a feed with N turns no longer scales with N.

**Why**: The audit found `GoFish::TurnResult#current_user_name`/`#opponent_user_name` (and the equivalent in `CrazyEights::TurnResult`) call `User.find(id).name` fresh every time they're invoked. `app/views/application/_feed_content.html.slim` calls `request_message`/`action_message`/`result_message` — each of which calls these name methods — for every entry in `@presenter.implementation.feed`, and the feed is never trimmed, so it grows for the life of the game. A game with 20+ turns issues dozens of redundant per-turn `User.find` queries on every single page render while the game is in progress.

**Files and code referenced**:
- `app/models/go_fish/turn_result.rb:112-118` (the duplicated N+1 pattern)
  ```ruby
  def current_user_name
    User.find(current_user_id).name
  end

  def opponent_user_name
    User.find(opponent_user_id).name
  end
  ```
- `app/models/crazy_eights/turn_result.rb:58-60` (same pattern, `current_user_name` only — Crazy Eights turn results don't reference an opponent)
- `app/views/application/_feed_content.html.slim:1-4` (the render loop that multiplies the query count by feed length)
  ```slim
  - feed= @presenter.implementation.feed
  .feed-content.op-stack.gap-xs.flex-grow-1
    - feed.each do |turn_action|
  ```
- `app/presenters/game_presenter.rb` — natural place to build and pass through a `{user_id => name}` lookup, since presenters already hold `game` + `my_user` and are meant to be the seam between the engine and the view
