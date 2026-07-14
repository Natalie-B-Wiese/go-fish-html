module CrazyEights
  class Player
    attr_reader :user_id
    attr_accessor :hand

    def cards
      hand.cards.sort_by(&:value)
    end

    def initialize(user_id, cards: [], hand: CardCollection.new(cards))
      @user_id = user_id

      @hand = hand
    end

    def add_card(card)
      hand.push_cards(card)
    end

    def playable_cards(discard_card)
      card_options = []

      cards.each do |card|
        card_options.concat(pseudo_playable_options(card: card, discard_card: discard_card))
      end

      card_options
    end

    def take_card(rank, suit)
      card_taken = if rank == '8'
                     cards.find { |card| card.rank == rank }
                   else
                     cards.find { |card| card.rank == rank && card.suit == suit }
                   end

      hand.cards -= [card_taken]
      Card.new(rank, suit)
    end

    def ==(other)
      return false if other.nil?

      user_id == other.user_id &&
        hand == other.hand
    end

    def as_json
      {
        user_id: user_id,
        hand: hand.as_json
      }
    end

    def self.from_json(json)
      json_hand = CardCollection.from_json(json['hand'])

      new(json['user_id'], hand: json_hand)
    end

    private

    def pseudo_playable_options(card:, discard_card:)
      return Card::SUITS.map { |suit| Card.new('8', suit) } if card.rank == '8'

      if discard_card.rank == card.rank || discard_card.suit == card.suit
        [card]
      else
        []
      end
    end
  end
end
