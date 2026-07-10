module CrazyEights
  class Implementation
    # Two player game: Deal 5
    SMALL_GAME_CARDS = 5

    # 3+ player game: Deal 7 cards
    BIG_GAME_CARDS = 7

    attr_reader :players, :deck, :discard_pile

    def initialize(players, deck: Deck.new, discard_pile: DiscardPile.new)
      @players = players
      @deck = deck
      @discard_pile = discard_pile
    end

    def start!
      deal

      # deal a non-8 to the discard pile
      deck.cards.push(discard_pile.take_top_card) while top_deck_card_to_discard.rank == '8'
    end

    private

    # takes from top of deck and adds it to discard pile
    # Returns the card that was added to the discard pile
    def top_deck_card_to_discard
      top_card = deck.take_top_card
      discard_pile.cards.push(top_card)
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
