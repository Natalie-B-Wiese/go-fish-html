# holds a collection of cards
class CardCollection
  attr_accessor :cards

  def initialize(cards = [])
    @cards = cards
  end

  def card_count
    cards.length
  end

  delegate :empty?, to: :cards

  def ==(other)
    return false if other.nil?
    return false if card_count != other.card_count

    cards.each_with_index do |card, index|
      return false unless other.cards[index] == card
    end

    true
  end

  def as_json
    {
      cards: cards.map(&:as_json)
    }
  end

  def self.from_json(json)
    json_cards = json['cards'].map { |card_json| Card.from_json(card_json) }
    new(json_cards)
  end
end
