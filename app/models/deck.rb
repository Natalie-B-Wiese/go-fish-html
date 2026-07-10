require_relative 'card'

# holds a deck of cards
class Deck < CardCollection
  def initialize(cards = sorted_deck)
    super
  end

  def take_top_card
    cards.shift
  end

  def shuffle
    shuffled = cards.shuffle
    shuffled = cards.shuffle while shuffled == cards

    self.cards = shuffled
  end

  private

  def sorted_deck
    Card::SUITS.flat_map do |suit|
      Card::RANKS.map do |rank|
        Card.new(rank, suit)
      end
    end
  end
end
