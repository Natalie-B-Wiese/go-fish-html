module GoFish
  class Player
    attr_reader :user_id
    attr_accessor :cards, :books

    def initialize(user_id, cards: [], books: [])
      @user_id=user_id
      @cards = cards
      @books=books
    end

    def ==(other)
      return false if other.nil?

      as_json==other.as_json
    end

    def as_json(*)
      {
        user_id: user_id,
        cards: cards.map(&:as_json),
        books: books.map(&:as_json)
      }
    end

    def self.from_json(json)
      json_cards=json["cards"].map { |card_json| Card.from_json(card_json) }
      json_books=json["books"].map { |book_json| Book.from_json(book_json) }

      self.new(json["user_id"], cards: json_cards, books: json_books)
    end

    def add_card(card)
      cards.push(card)
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

    def try_make_book(rank)
      cards_in_book = cards_with_rank(rank)
      return nil unless cards_in_book.length == Book::SIZE

      self.cards -= cards_in_book
      book = Book.new(rank)
      books.push(book)
      book
    end

    def biggest_book_value
      return 0 if books.empty?

      return books.max_by(&:value).value      
    end

    
    private

    def cards_with_rank(rank)
      cards.select { |card| card.rank == rank }
    end

  end
end