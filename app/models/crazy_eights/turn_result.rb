module CrazyEights
  class TurnResult
    TAKE_DECK = 'drew a'.freeze
    PLAY_CARD = 'placed a'.freeze

    attr_reader :current_user_id, :card_played
    attr_accessor :card_received_deck

    def initialize(current_user_id:, card_played: nil, card_received_deck: nil)
      @current_user_id = current_user_id
      @card_played = card_played
      @card_received_deck = card_received_deck
    end

    def as_json
      {
        'current_user_id' => current_user_id,
        'card_received_deck' => card_received_deck.as_json,
        'card_played' => card_played.as_json
      }
    end

    def self.from_json(json)
      json_deck_card = json['card_received_deck'].nil? ? nil : Card.from_json(json['card_received_deck'])
      json_card_played = json['card_played'].nil? ? nil : Card.from_json(json['card_played'])

      new(current_user_id: json['current_user_id'],
          card_received_deck: json_deck_card,
          card_played: json_card_played)
    end

    def ==(other)
      return false if other.nil?

      current_user_id == other.current_user_id &&
        card_received_deck == other.card_received_deck &&
        card_played == other.card_played
    end

    def request_message(user_names_by_id)
      if card_played
        "#{current_user_name(user_names_by_id)} #{PLAY_CARD} #{card_played}."
      else
        "#{current_user_name(user_names_by_id)} #{TAKE_DECK} card from the deck."
      end
    end

    def action_message(_user_names_by_id)
      ''
    end

    def result_message(_user_names_by_id)
      ''
    end

    private

    def current_user_name(user_names_by_id)
      user_names_by_id.fetch(current_user_id)
    end
  end
end
