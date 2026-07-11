module CrazyEights
  class Implementation
    # Two player game: Deal 5
    SMALL_GAME_CARDS = 5

    # 3+ player game: Deal 7 cards
    BIG_GAME_CARDS = 7

    attr_reader :players, :deck, :discard_pile, :feed

    attr_accessor :current_player_index

    # keys are the user id and values are the Go Fish Players
    def players_hash
      players.index_by(&:user_id)
    end

    def initialize(players, deck: Deck.new, discard_pile: DiscardPile.new, current_player_index: 0, feed: [])
      @players = players
      @deck = deck
      @discard_pile = discard_pile
      @current_player_index = current_player_index
      @feed = feed
    end

    def start!
      deal

      # deal a non-8 to the discard pile
      deck.insert_card_at_random_position(discard_pile.take_top_card) while top_deck_card_to_discard.rank == '8'
    end

    def draw_deck_turn
      # return nil unless current_player.out_of_cards?
      # To draw from the deck, player must not have any playable cards
      # Add a safe check here

      draw_from_deck
      true

      # turn_result = TurnResult.new(current_user_id: current_user_id)
      # finish_turn(turn_result)
    end

    # TODO: implement turn result and feed
    def play_turn(rank:, suit:)
      play_card(rank, suit)
      switch_turn
      true
    end

    # the Crazy Eights player whose turn it is
    # UNTESTED
    def current_player
      players[current_player_index]
    end

    def current_user_id
      players[current_player_index].user_id
    end

    def self.load(json)
      return nil if json.blank?

      from_json(json)
    end

    def self.dump(obj)
      obj.as_json
    end

    def as_json
      {
        players: players.map(&:as_json),
        deck: deck.as_json,
        discard_pile: discard_pile.as_json,
        current_player_index: current_player_index,
        feed: feed.map(&:as_json)
      }
    end

    def ==(other)
      return false if other.nil?

      players == other.players &&
        deck == other.deck &&
        discard_pile == other.discard_pile &&
        current_player_index == other.current_player_index &&
        feed == other.feed
    end

    def self.from_json(json)
      players = json['players'].map { |player_json| CrazyEights::Player.from_json(player_json) }
      deck = Deck.from_json(json['deck'])

      # feed = json['feed'].map { |turn_result_json| CrazyEights::TurnResult.from_json(turn_result_json) }
      feed = []
      player_index = json['current_player_index']
      discard_pile = DiscardPile.from_json(json['discard_pile'])

      new(players, deck: deck, discard_pile: discard_pile, current_player_index: player_index, feed: feed)
    end

    def game_over?
      false
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
