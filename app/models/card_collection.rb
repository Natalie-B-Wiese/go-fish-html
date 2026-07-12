# holds a collection of cards
class CardCollection
  attr_accessor :cards

  def initialize(cards = [])
    @cards = cards
  end

  def push_cards(*cards_to_add)
    cards_to_add = cards_to_add.flatten
    self.cards = cards.concat(cards_to_add)
    self
  end

  def pop_card
    cards.pop
  end

  def unshift_cards(*cards_to_add)
    cards_to_add = cards_to_add.flatten
    cards.unshift(*cards_to_add)
    self
  end

  def shift_card
    cards.shift
  end

  def insert_card_at_random(card)
    cards.insert(rand(0..cards.length), card)
    self
  end

  def take_card_at_random
    cards.delete_at(rand(cards.length))
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
