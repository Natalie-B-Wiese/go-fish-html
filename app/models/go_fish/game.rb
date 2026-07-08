module GoFish
  class Game
    SMALL_GAME_CARDS = 7
    BIG_GAME_CARDS = 5
    BOOKS_TO_WIN = (Card::SUITS.length * Card::RANKS.length) / Book::SIZE

    attr_reader :players, :deck, :feed

    attr_accessor :current_player_index

    def initialize(players, deck: Deck.new, current_player_index: 0, feed: [])
      @players=players
      @deck = deck
      @feed=feed
      @current_player_index=current_player_index
    end

    def deal!
      deck.shuffle
      if players.length <= 3
        deal_cards_to_players(SMALL_GAME_CARDS)
      else
        deal_cards_to_players(BIG_GAME_CARDS)
      end
    end

    def as_json
      {
        players: players.map(&:as_json),
        deck: deck.as_json,
        current_player_index: current_player_index,
        feed: feed.map(&:as_json)
      }
    end

    def ==(other)
      return false if other.nil?

      (players==other.players &&
      deck==other.deck &&
      current_player_index==other.current_player_index &&
      feed==other.feed)
    end

    def self.from_json(json)
      json_players=json["players"].map { |player_json| GoFish::Player.from_json(player_json) }
      json_deck=Deck.from_json(json["deck"])
      json_feed=json["feed"].map { |turn_result_json| GoFish::TurnResult.from_json(turn_result_json) }

      self.new(json_players, deck: json_deck, current_player_index: json["current_player_index"], feed: json_feed)
    end

    def self.load(json)
      return nil if json.blank?
      from_json(json)
    end

    def self.dump(obj)
      obj.as_json
    end

    def play_turn(opponent_user_id: nil, rank_requested: nil)
      turn_result = TurnResult.new(current_user_id: current_user_id, opponent_user_id: opponent_user_id, rank_requested: rank_requested)
      preform_move(turn_result)
      try_make_book(turn_result) if turn_result.rank_received

      switch_turn unless turn_result.go_again?

      feed.push(turn_result)

      turn_result
    end

    def current_go_fish_player
      player_from_user_id(current_user_id)
    end



    # the player currently in the lead
    def winning_player
      winning_players = players_with_most_books

      return winning_players[0] if winning_players.length == 1

      player_with_biggest_value_book(winning_players)
    end

    def game_over?
      total_book_count == BOOKS_TO_WIN
    end

    private
    def request_deck_card(turn_result = TurnResult.new(current_user_id: current_user_id))
      unless deck.empty?
        card_taken = deck.take_top_card
        turn_result.card_received_deck = card_taken
        current_go_fish_player.add_card(card_taken)
      end

      turn_result
    end

    def total_book_count
      players.inject(0) { |sum, player| sum + player.book_count }
    end

    def players_with_most_books
      players.select { |player| player.book_count == most_books }
    end

    def player_with_biggest_value_book(players_array)
      players_array.max_by(&:biggest_book_value)
    end

    def most_books
      players.max_by(&:book_count).book_count
    end

    def switch_turn
      self.current_player_index += 1
      self.current_player_index = 0 if current_player_index >= players.length
    end

    def current_user_id
      players[current_player_index].user_id
    end

    def player_from_user_id(user_id)
      players.find { |player| player.user_id==user_id }
    end

    def try_make_book(turn_result)
      book_made = current_go_fish_player.try_make_book(turn_result.rank_received)
      turn_result.was_book_made = true if book_made
    end

    def deal_cards_to_players(num_cards_to_deal)
      num_cards_to_deal.times do
        players.each do |player|
          player.add_card(deck.take_top_card)
        end
      end
    end

    def preform_move(turn_result)
      if turn_result.opponent_user_id.nil? && turn_result.rank_requested.nil?
        request_deck_card(turn_result)
      else
        preform_take_from_opponent_move(turn_result)
      end
    end

    def preform_take_from_opponent_move(turn_result)
      opponent=player_from_user_id(turn_result.opponent_user_id)

      cards_taken_from_opponent = opponent.take_cards_with_rank(turn_result.rank_requested)

      if cards_taken_from_opponent.empty?
        request_deck_card(turn_result)
      else
        turn_result.cards_received_opponent = cards_taken_from_opponent
        current_go_fish_player.add_cards(cards_taken_from_opponent)
      end
    end
  end
end
