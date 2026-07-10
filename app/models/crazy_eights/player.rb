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

    def take_card(rank, suit)
      card_taken = if rank == '8'
                     cards.find { |card| card.rank == rank }
                   else
                     cards.find { |card| card.rank == rank && card.suit == suit }
                   end

      self.cards -= [card_taken]
      Card.new(rank, suit)
    end
  end
end
