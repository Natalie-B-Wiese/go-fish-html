module Rummy
  class Meld
    attr_reader :cards

    def initialize(cards)
      @cards = cards.sort_by(&:value)
    end

    def valid?
      cards.size >= 3 && (set? || run?)
    end

    def ==(other)
      return false if other.nil?

      cards == other.cards
    end

    def as_json
      { 'cards' => cards.map(&:as_json) }
    end

    def self.from_json(json)
      new(json['cards'].map { |card_json| Card.from_json(card_json) })
    end

    private

    def set?
      cards.map(&:rank).uniq.size == 1
    end

    def run?
      return false unless cards.map(&:suit).uniq.size == 1

      values = cards.map(&:value)
      values == ((values.first)..(values.last)).to_a
    end
  end
end
