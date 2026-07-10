module CrazyEights
  class Implementation
    # Two player game: Deal 5
    SMALL_GAME_CARDS = 5

    # 3+ player game: Deal 7 cards
    BIG_GAME_CARDS = 7

    attr_reader :players, :deck, :discard_pile

    attr_accessor :current_player_index

    def initialize(players, deck: Deck.new, discard_pile: DiscardPile.new, current_player_index: 0)
      @players = players
      @deck = deck
      @discard_pile = discard_pile
      @current_player_index = current_player_index
    end

    def start!
      deal

      # deal a non-8 to the discard pile
      deck.insert_card_at_random_position(discard_pile.take_top_card) while top_deck_card_to_discard.rank == '8'
    end

    # TODO: implement turn result and feed
    def play_turn(rank: nil, suit: nil)
      if rank.nil? && suit.nil?
        draw_from_deck
      else
        play_card(rank, suit)
        switch_turn
      end
    end

    # the Crazy Eights player whose turn it is
    # UNTESTED
    def current_player
      players[current_player_index]
    end

    private

    def switch_turn
      self.current_player_index += 1
      self.current_player_index = 0 if current_player_index >= players.length
    end

    def recreate_deck_from_discard
      cards = discard_pile.cards - [discard_pile.top_card]
      discard_pile.cards = [discard_pile.top_card]

      cards.each do |card|
        deck.insert_card_at_random_position(card)
      end
    end

    def add_discard(card)
      discard_pile.insert_card_to_top(card)
    end

    def draw_from_deck
      recreate_deck_from_discard if deck.empty?

      current_player.add_card(deck.take_top_card)
    end

    def play_card(rank, suit)
      add_discard(current_player.take_card(rank, suit))
    end

    # takes from top of deck and adds it to discard pile
    # Returns the card that was added to the discard pile
    def top_deck_card_to_discard
      top_card = deck.take_top_card
      add_discard(top_card)
      top_card
    end

    def deal
      deck.shuffle
      if players.length == 2
        deal_cards_to_players(SMALL_GAME_CARDS)
      else
        deal_cards_to_players(BIG_GAME_CARDS)
      end
    end

    def deal_cards_to_players(num_cards_to_deal)
      num_cards_to_deal.times do
        players.each do |player|
          player.add_card(deck.take_top_card)
        end
      end
    end
  end
end
