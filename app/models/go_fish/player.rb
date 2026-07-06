module GoFish
  class Player
    attr_reader :user_id
    attr_accessor :cards

    def initialize(user_id, cards: [])
      @user_id=user_id
      @cards = cards
    end

    def ==(other)
      return false if other.nil?

      as_json==other.as_json
    end

    def as_json(*)
      {
        user_id: user_id,
        cards: cards.map(&:as_json)
      }
    end

    def self.from_json(json)
      json_cards=json["cards"].map { |card_json| Card.from_json(card_json) }

      self.new(json["user_id"], cards: json_cards)
    end

    def add_card(card)
      cards.push(card)
    end

    def add_cards(card_array)
      card_array.each { |card| add_card(card) }
    end

  end
end