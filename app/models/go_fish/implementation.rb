module GoFish
  class Implementation < ::Implementation
    SMALL_GAME_CARDS = 7
    BIG_GAME_CARDS = 5
    BOOKS_TO_WIN = (Card::SUITS.length * Card::RANKS.length) / Book::SIZE

    def self.player_class
      GoFish::Player
    end

    def self.turn_result_class
      GoFish::TurnResult
    end

    def start!
      deal
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

    def starting_hand_size
      players.length <= 3 ? SMALL_GAME_CARDS : BIG_GAME_CARDS
    end

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
        card_taken = deck.shift_card
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

    def preform_take_from_opponent_move(turn_result)
      opponent = players_hash[turn_result.opponent_user_id]

      cards_taken_from_opponent = opponent.take_cards_with_rank(turn_result.rank_requested)

      return request_deck_card(turn_result) if cards_taken_from_opponent.empty?

      turn_result.cards_received_opponent = cards_taken_from_opponent
      current_player.add_cards(cards_taken_from_opponent)
    end
  end
end
