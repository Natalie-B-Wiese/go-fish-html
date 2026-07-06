require_relative 'card'

# holds a deck of cards
class Deck
  attr_accessor :cards

  def initialize(cards=sorted_deck)
    @cards = cards
  end

  def ==(other)
      return false if other.nil?

      return as_json==other.as_json   
  end

  def as_json(*)
    {
      cards: cards.map(&:as_json)
    }
  end

  def self.from_json(json)
    # makes it not care whether json uses string or keys to index

    json_cards=json["cards"].map { |card_json| Card.from_json(card_json) }
    self.new(json_cards)
  end

  def cards_left
    cards.length
  end

  def empty?
    cards.empty?
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
