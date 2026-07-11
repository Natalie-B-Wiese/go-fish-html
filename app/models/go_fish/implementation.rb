module GoFish
  class Implementation
    SMALL_GAME_CARDS = 7
    BIG_GAME_CARDS = 5
    BOOKS_TO_WIN = (Card::SUITS.length * Card::RANKS.length) / Book::SIZE

    attr_reader :players, :deck, :feed

    attr_accessor :current_player_index

    # keys are the user id and values are the Go Fish Players
    def players_hash
      players.index_by(&:user_id)
    end

    def initialize(players, deck: Deck.new, current_player_index: 0, feed: [])
      @players = players
      @deck = deck
      @feed = feed
      @current_player_index = current_player_index
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

      players == other.players &&
        deck == other.deck &&
        current_player_index == other.current_player_index &&
        feed == other.feed
    end

    def self.from_json(json)
      json_players = json['players'].map { |player_json| GoFish::Player.from_json(player_json) }
      json_deck = Deck.from_json(json['deck'])
      json_feed = json['feed'].map { |turn_result_json| GoFish::TurnResult.from_json(turn_result_json) }

      new(json_players, deck: json_deck, current_player_index: json['current_player_index'], feed: json_feed)
    end

    def self.load(json)
      return nil if json.blank?

      from_json(json)
    end

    def self.dump(obj)
      obj.as_json
    end

    # returns nil if move could not be preformed, otherwise returns a turn result
    def draw_deck_turn
      return nil unless current_player.out_of_cards?

      turn_result = TurnResult.new(current_user_id: current_user_id)
      request_deck_card(turn_result)
      finish_turn(turn_result)
    end

    # returns nil if move could not be preformed, otherwise returns a turn result
    def request_opponent_turn(opponent_user_id:, rank_requested:)
      return nil unless valid_opponent?(opponent_user_id) && valid_request_rank?(rank_requested)

      turn_result = TurnResult.new(current_user_id: current_user_id, opponent_user_id: opponent_user_id,
                                   rank_requested: rank_requested)

      preform_take_from_opponent_move(turn_result)
      finish_turn(turn_result)
    end

    # the Go Fish player whose turn it is
    def current_player
      players[current_player_index]
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

    def current_user_id
      players[current_player_index].user_id
    end

    private

    def finish_turn(turn_result)
      turn_result.was_book_made = current_player.book_made? if turn_result.rank_received
      switch_turn unless turn_result.go_again?
      feed.push(turn_result)
      turn_result
    end

    def valid_opponent?(opponent_user_id)
      opponents.any? { |opponent| opponent.user_id == opponent_user_id }
    end

    def valid_request_rank?(rank)
      current_player.includes_card_with_rank?(rank)
    end

    def opponents
      players - [current_player]
    end

    def request_deck_card(turn_result = TurnResult.new(current_user_id: current_user_id))
      unless deck.empty?
        card_taken = deck.take_top_card
        turn_result.card_received_deck = card_taken
        current_player.add_card(card_taken)
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

    def deal_cards_to_players(num_cards_to_deal)
      num_cards_to_deal.times do
        players.each do |player|
          player.add_card(deck.take_top_card)
        end
      end
    end

    def preform_take_from_opponent_move(turn_result)
      opponent = players_hash[turn_result.opponent_user_id]

      cards_taken_from_opponent = opponent.take_cards_with_rank(turn_result.rank_requested)

      return request_deck_card(turn_result) if cards_taken_from_opponent.empty?

      turn_result.cards_received_opponent = cards_taken_from_opponent
      current_player.add_cards(cards_taken_from_opponent)
    end
  end
end
