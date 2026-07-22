module GoFish
  class TurnResult
    NO_CARDS = 'ran out of cards'.freeze
    EMPTY_DECK = 'The deck is empty'.freeze
    GO_AGAIN = 'can go again'.freeze
    BOOK = 'made a book with four'.freeze
    DISQUALIFIED = 'out of the game'.freeze
    REQUEST = 'requested a'.freeze
    GO_FISH = 'Go Fish'.freeze
    TAKE_DECK = 'drew a'.freeze

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

    def request_message(user_names_by_id)
      if player_out_of_cards?
        "#{current_user_name(user_names_by_id)} #{NO_CARDS}. "
      else
        "#{current_user_name(user_names_by_id)} #{REQUEST} #{rank_requested} " \
          "from #{opponent_user_name(user_names_by_id)}. "
      end
    end

    def action_message(user_names_by_id)
      return '' if player_out_of_cards?

      opponent_name = opponent_user_name(user_names_by_id)
      return "#{GO_FISH}: #{opponent_name} doesn't have any #{rank_requested}s" if cards_received_opponent.empty?

      card_word = cards_received_opponent.length == 1 ? 'card' : 'cards'
      current_name = current_user_name(user_names_by_id)
      "#{opponent_name} gave #{cards_received_opponent.length} #{card_word} to #{current_name}. "
    end

    def result_message(user_names_by_id)
      result = deck_messages(user_names_by_id)

      result += "#{EMPTY_DECK}. " if deck_empty? && card_received_deck.nil?
      result += "#{current_user_name(user_names_by_id)} is #{DISQUALIFIED}. " if player_out_of_cards? && deck_empty?

      result += "#{current_user_name(user_names_by_id)} #{GO_AGAIN}. " if go_again?
      result += "#{current_user_name(user_names_by_id)} #{BOOK} #{rank_received}s! " if book_made?

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
      json_cards = if json['cards_received_opponent'].nil?
                     []
                   else
                     json['cards_received_opponent'].map do |card_json|
                       Card.from_json(card_json)
                     end
                   end
      json_deck_card = json['card_received_deck'].nil? ? nil : Card.from_json(json['card_received_deck'])

      new(current_user_id: json['current_user_id'], opponent_user_id: json['opponent_user_id'],
          rank_requested: json['rank_requested'], cards_received_opponent: json_cards,
          card_received_deck: json_deck_card,
          was_book_made: json['was_book_made'])
    end

    def ==(other)
      return false if other.nil?

      current_user_id == other.current_user_id &&
        opponent_user_id == other.opponent_user_id &&
        rank_requested == other.rank_requested &&
        cards_received_opponent == other.cards_received_opponent &&
        was_book_made == other.was_book_made
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

    private

    def current_user_name(user_names_by_id)
      user_names_by_id.fetch(current_user_id)
    end

    def opponent_user_name(user_names_by_id)
      user_names_by_id.fetch(opponent_user_id)
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

    def deck_messages(user_names_by_id)
      return '' unless card_received_deck

      card_str = rank_received == rank_requested ? rank_requested : 'card'
      "#{current_user_name(user_names_by_id)} #{TAKE_DECK} #{card_str} from the deck. "
    end
  end
end
