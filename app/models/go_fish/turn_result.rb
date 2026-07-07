module GoFish
  class TurnResult
    NO_CARDS = 'ran out of cards'
    EMPTY_DECK = 'The deck is empty'
    GO_AGAIN = 'can go again'
    BOOK = 'made a book with four'
    DISQUALIFIED = 'out of the game'
    REQUEST = 'requested a'
    GO_FISH = 'Go Fish'
    TAKE_DECK = 'drew a'

    attr_reader :current_user_id, :opponent_user_id, :rank_requested

    attr_accessor :was_book_made, :card_received_deck, :cards_received_opponent

    def initialize(current_user_id:, opponent_user_id: nil, rank_requested: nil,
                  cards_received_opponent: [], card_received_deck: nil, was_book_made: false)
      @current_user_id = current_user_id
      @opponent_user_id = opponent_user_id
      @rank_requested = rank_requested
      @cards_received_opponent = cards_received_opponent
      @card_received_deck = card_received_deck
      @was_book_made = was_book_made
    end

    def go_again?
      out_of_cards_and_drew_from_deck? || ((!rank_received.nil? || book_made?) && rank_received == rank_requested)
    end

    def request_message
      if player_out_of_cards?
        "#{current_user_name} #{NO_CARDS}. "
      else
        "#{current_user_name} #{REQUEST} #{rank_requested} from #{opponent_user_name}. "
      end
    end

    def action_message
      return '' if player_out_of_cards?

      if cards_received_opponent.nil? || cards_received_opponent.empty?
        "#{GO_FISH}: #{opponent_user_name} doesn't have any #{rank_requested}s"
      else
        card_word = cards_received_opponent.length == 1 ? 'card' : 'cards'
        "#{opponent_user_name} gave #{cards_received_opponent.length} #{card_word} to #{current_user_name}. "
      end
    end

    def result_message
      result = deck_messages

      result += "#{EMPTY_DECK}. " if deck_empty? && card_received_deck.nil?
      result += "#{current_user_name} is #{DISQUALIFIED}. " if player_out_of_cards? && deck_empty?

      result += "#{current_user_name} #{GO_AGAIN}. " if go_again?
      result += "#{current_user_name} #{BOOK} #{rank_received}s! " if book_made?

      result
    end

    def as_json
      {
        'current_user_id' => current_user_id,
        'opponent_user_id' => opponent_user_id,
        'rank_requested' => rank_requested,
        'cards_received_opponent' => cards_received_opponent.map(&:as_json),
        'card_received_deck' => card_received_deck.as_json,
        'was_book_made' => was_book_made
      }

      #  'display' => request_message + action_message + result_message
    end

    def self.from_json(json)
      json_cards= json["cards_received_opponent"].nil? ? [] : json["cards_received_opponent"].map { |card_json| Card.from_json(card_json) }

      
      self.new(current_user_id:json["current_user_id"], opponent_user_id: json["opponent_user_id"],
              rank_requested: json["rank_requested"], cards_received_opponent: json_cards,
              card_received_deck: Card.from_json(json["card_received_deck"]),
              was_book_made: json["was_book_made"])
    end

    def ==(other)
      return false if other.nil?

      (current_user_id==other.current_user_id &&
      opponent_user_id==other.opponent_user_id &&
      rank_requested==other.rank_requested &&
      cards_received_opponent==other.cards_received_opponent &&
      was_book_made==other.was_book_made)
    end

    private
    def current_user_name
      User.find(current_user_id).name
    end

    def opponent_user_name
      User.find(opponent_user_id).name
    end

    def out_of_cards_and_drew_from_deck?
      !rank_received.nil? && rank_requested.nil?
    end

    def deck_empty?
      went_fish? && card_received_deck.nil?
    end

    def player_out_of_cards?
      opponent_user_id.nil?
    end

    def book_made?
      !!was_book_made
    end

    def went_fish?
      cards_received_opponent.empty?
    end

    def deck_messages
      return '' unless card_received_deck

      card_str = rank_received == rank_requested ? rank_requested : 'card'
      "#{current_user_name} #{TAKE_DECK} #{card_str} from the deck. "
    end

    def rank_received
      if went_fish? && card_received_deck
        card_received_deck.rank
      elsif !cards_received_opponent.empty?
        cards_received_opponent.first.rank
      else
        nil
      end
    end
  end
end