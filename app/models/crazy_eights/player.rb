module CrazyEights
  class Player
    attr_reader :user_id
    attr_accessor :cards

    def initialize(user_id, cards: [])
      @user_id = user_id
      @cards = cards
    end

    def add_card(card)
      cards.push(card)
    end
  end
end
