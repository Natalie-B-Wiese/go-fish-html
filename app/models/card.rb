# holds a single playing card
class Card
  attr_reader :rank, :suit

  class InvalidRank < StandardError; end
  class InvalidSuit < StandardError; end

  RANKS = %w[2 3 4 5 6 7 8 9 10 J Q K A].freeze
  SUITS = %w[Spades Hearts Clubs Diamonds].freeze

  RANK_NAMES = {
    'J' => 'Jack',
    'Q' => 'Queen',
    'K' => 'King',
    'A' => 'Ace'
  }.freeze

  SUIT_SYMBOLS = {
    'S' => 'Spades',
    'H' => 'Hearts',
    'C' => 'Clubs',
    'D' => 'Diamonds'
  }.freeze

  def key
    "#{rank}#{SUIT_SYMBOLS.invert[suit]}"
  end

  def self.from_key(key)
    rank = key[0]

    # if the number is two digits (eg 10)
    rank += key[1] if key.length > 2

    suit = SUIT_SYMBOLS[key[-1]]
    Card.new(rank, suit)
  end

  def initialize(rank, suit)
    raise InvalidRank unless RANKS.include? rank
    raise InvalidSuit unless SUITS.include? suit

    @rank = rank
    @suit = suit
  end

  def ==(other)
    return false if other.nil?

    rank == other.rank && suit == other.suit
  end

  def self.rank_to_value(rank)
    RANKS.index(rank)
  end

  def value
    RANKS.index(rank)
  end

  def to_s
    "#{rank} of #{suit}"
  end

  def self.rank_to_s(rank)
    if RANK_NAMES.include?(rank)
      RANK_NAMES[rank]
    else
      rank
    end
  end

  def rank_to_s
    Card.rank_to_s(rank)
  end

  def to_image_name
    "#{rank_to_s.downcase}_of_#{suit.downcase}.png"
  end

  def as_json
    {
      'rank' => rank,
      'suit' => suit
    }
  end

  def self.from_json(json)
    new(json['rank'], json['suit'])
  end
end
