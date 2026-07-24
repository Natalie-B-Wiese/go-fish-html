module Rummy
  class Player
    attr_reader :user_id
    attr_accessor :hand, :melds

    def initialize(user_id, hand: nil, melds: [])
      @user_id = user_id
      @hand = hand || CardCollection.new
      @melds = melds
    end

    def cards
      hand.cards
    end

    def add_card(card)
      hand.push_cards(card)
    end

    def take_card(rank, suit)
      card_taken = cards.find { |card| card.rank == rank && card.suit == suit }
      hand.cards -= [card_taken]
      card_taken
    end

    def add_meld(meld)
      melds.push(meld)
    end

    def try_create_meld(meld_cards)
      return nil unless meld_cards.all? { |card| cards.include?(card) }

      meld = Meld.new(meld_cards)
      return nil unless meld.valid?

      make_meld(meld_cards, meld)
    end

    def ==(other)
      return false if other.nil?

      user_id == other.user_id && hand == other.hand && melds == other.melds
    end

    def as_json
      { user_id: user_id, hand: hand.as_json, melds: melds.map(&:as_json) }
    end

    def self.from_json(json)
      new(json['user_id'],
          hand: CardCollection.from_json(json['hand']),
          melds: json['melds'].map { |meld_json| Meld.from_json(meld_json) })
    end

    private

    def make_meld(meld_cards, meld)
      hand.cards -= meld_cards
      add_meld(meld)
      meld
    end
  end
end
