module Rummy
  class TurnResult
    attr_reader :current_user_id
    attr_accessor :card_received_deck

    def initialize(current_user_id:, card_received_deck: nil)
      @current_user_id = current_user_id
      @card_received_deck = card_received_deck
    end

    def as_json
      {
        'current_user_id' => current_user_id,
        'card_received_deck' => card_received_deck.as_json
      }
    end

    def self.from_json(json)
      card = json['card_received_deck'].nil? ? nil : Card.from_json(json['card_received_deck'])

      new(current_user_id: json['current_user_id'], card_received_deck: card)
    end

    def ==(other)
      return false if other.nil?

      current_user_id == other.current_user_id && card_received_deck == other.card_received_deck
    end
  end
end
