require_relative 'card'

# holds a deck of cards
class Deck < CardCollection
  def initialize(cards = sorted_deck)
    super
  end

  def top_card
    cards.first
  end

  def shuffle
    shuffled = cards.shuffle
    shuffled = cards.shuffle while shuffled == cards && cards.length > 1

    self.cards = shuffled
  end

  private

  def sorted_deck
    Card::SUITS.flat_map do |suit|
      Card::RANKS.map do |rank|
        self.class.card_class.new(rank, suit)
      end
    end
  end
end
