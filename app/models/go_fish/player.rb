module GoFish
  class Player
    attr_reader :user_id
    attr_accessor :cards, :books, :was_book_made

    def initialize(user_id, cards: [], books: [])
      @user_id = user_id
      @cards = cards
      @books = books
      @was_book_made = false
    end

    def ==(other)
      return false if other.nil?

      as_json == other.as_json
    end

    def book_made?
      !!was_book_made
    end

    def as_json
      {
        user_id: user_id,
        cards: cards.map(&:as_json),
        books: books.map(&:as_json)
      }
    end

    def self.from_json(json)
      json_cards = json['cards'].map { |card_json| Card.from_json(card_json) }
      json_books = json['books'].map { |book_json| Book.from_json(book_json) }

      new(json['user_id'], cards: json_cards, books: json_books)
    end

    def add_card(card)
      cards.push(card)
      try_make_book(card.rank)
    end

    def add_cards(card_array)
      card_array.each { |card| add_card(card) }
    end

    def card_ranks
      cards.map(&:rank).uniq
    end

    def take_cards_with_rank(rank)
      cards_taken = cards_with_rank(rank)
      self.cards -= cards_taken
      cards_taken
    end

    def book_count
      books.length
    end

    def biggest_book_value
      return 0 if books.empty?

      books.max_by(&:value).value
    end

    def includes_card_with_rank?(rank)
      cards.any? { |card| card.rank == rank }
    end

    def out_of_cards?
      cards.empty?
    end

    private

    def cards_with_rank(rank)
      cards.select { |card| card.rank == rank }
    end

    def try_make_book(rank)
      self.was_book_made = false
      cards_in_book = cards_with_rank(rank)
      return nil unless cards_in_book.length == Book::SIZE

      make_book(cards_in_book)
    end

    def make_book(cards)
      self.was_book_made = true
      self.cards -= cards
      book = Book.new(cards.first.rank)
      books.push(book)
      book
    end
  end
end
