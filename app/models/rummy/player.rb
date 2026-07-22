module Rummy
  class Player
    attr_reader :user_id
    attr_accessor :hand

    def initialize(user_id, hand: nil)
      @user_id = user_id
      @hand = hand || CardCollection.new
    end

    def cards
      hand.cards
    end

    def add_card(card)
      hand.push_cards(card)
    end

    def ==(other)
      return false if other.nil?

      user_id == other.user_id && hand == other.hand
    end

    def as_json
      { user_id: user_id, hand: hand.as_json }
    end

    def self.from_json(json)
      new(json['user_id'], hand: CardCollection.from_json(json['hand']))
    end
  end
end
