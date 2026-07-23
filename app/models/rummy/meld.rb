module Rummy
  class Meld
    attr_reader :cards

    def initialize(cards)
      @cards = cards
    end

    def valid?
      set?
    end

    private

    def set?
      cards.map(&:rank).uniq.size == 1
    end
  end
end
