require_relative 'card'

# holds a deck of cards
class Deck < CardCollection
  def initialize(cards = sorted_deck)
    super
  end

  def top_card
    cards.first
  end

  def take_top_card
    cards.shift
  end

  def shuffle
    shuffled = cards.shuffle
    shuffled = cards.shuffle while shuffled == cards

    self.cards = shuffled
  end

  # untested
  def insert_card_to_top(card)
    cards.unshift(card)
  end

  # untested
  def insert_card_at_random_position(card)
    cards.insert(rand(0..cards.size), card)
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
