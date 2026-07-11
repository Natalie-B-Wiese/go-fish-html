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

    def cards_to_h(cards_to_convert = cards)
      cards_to_convert.to_h { |card| [card.to_s, card.key] }.stringify_keys
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

      self.cards -= [card_taken]
      Card.new(rank, suit)
    end

    def ==(other)
      return false if other.nil?

      user_id == other.user_id &&
        cards == other.cards
    end

    def as_json
      {
        user_id: user_id,
        cards: cards.map(&:as_json)
      }
    end

    def self.from_json(json)
      json_cards = json['cards'].map { |card_json| Card.from_json(card_json) }

      new(json['user_id'], cards: json_cards)
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
