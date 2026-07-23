module Rummy
  class TurnResult
    attr_reader :current_user_id
    attr_accessor :card_received_deck, :card_received_discard

    def initialize(current_user_id:, card_received_deck: nil, card_received_discard: nil)
      @current_user_id = current_user_id
      @card_received_deck = card_received_deck
      @card_received_discard = card_received_discard
    end

    def as_json
      {
        'current_user_id' => current_user_id,
        'card_received_deck' => card_received_deck.as_json,
        'card_received_discard' => card_received_discard.as_json
      }
    end

    def self.from_json(json)
      new(
        current_user_id: json['current_user_id'],
        card_received_deck: card_from_json(json['card_received_deck']),
        card_received_discard: card_from_json(json['card_received_discard'])
      )
    end

    def self.card_from_json(card_json)
      card_json.nil? ? nil : Card.from_json(card_json)
    end

    def ==(other)
      return false if other.nil?

      current_user_id == other.current_user_id &&
        card_received_deck == other.card_received_deck &&
        card_received_discard == other.card_received_discard
    end
  end
end
