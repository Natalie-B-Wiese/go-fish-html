module CrazyEights
  class Implementation < ::Implementation
    # Two player game: Deal 5
    SMALL_GAME_CARDS = 5

    # 3+ player game: Deal 7 cards
    BIG_GAME_CARDS = 7

    def self.player_class
      CrazyEights::Player
    end

    def self.turn_result_class
      CrazyEights::TurnResult
    end

    attr_reader :discard_pile

    def initialize(players, deck: Deck.new, discard_pile: DiscardPile.new, current_player_index: 0, feed: [])
      super(players, deck: deck, current_player_index: current_player_index, feed: feed)
      @discard_pile = discard_pile
    end

    def start!
      deal

      # deal a non-8 to the discard pile
      deck.insert_card_at_random(discard_pile.shift_card) while top_deck_card_to_discard.rank == '8'
    end

    def draw_deck_turn
      return nil if current_player.playable_cards(discard_pile.top_card).any?

      turn_result = TurnResult.new(current_user_id: current_user_id)
      draw_from_deck(turn_result)
      feed.push(turn_result)
      turn_result
    end

    def play_turn(rank:, suit:)
      return nil unless current_player.playable_cards(discard_pile.top_card).include?(Card.new(rank, suit))

      card_played = play_card(rank, suit)
      turn_result = TurnResult.new(current_user_id: current_user_id, card_played: card_played)
      switch_turn
      feed.push(turn_result)
      turn_result
    end

    def as_json
      super.merge(discard_pile: discard_pile.as_json)
    end

    def self.json_attributes(json)
      super.merge(discard_pile: DiscardPile.from_json(json['discard_pile']))
    end

    def ==(other)
      super && discard_pile == other.discard_pile
    end

    def game_over?
      players.any? { |player| player.cards.empty? }
    end

    def winning_player
      players.find { |player| player.cards.empty? }
    end

    private

    def starting_hand_size
      players.length == 2 ? SMALL_GAME_CARDS : BIG_GAME_CARDS
    end

    def recreate_deck_from_discard
      cards = discard_pile.cards - [discard_pile.top_card]
      discard_pile.cards = [discard_pile.top_card]

      cards.each do |card|
        deck.insert_card_at_random(card)
      end
    end

    def add_discard(card)
      discard_pile.unshift_cards(card)
    end

    def draw_from_deck(turn_result)
      recreate_deck_from_discard if deck.empty?

      card = deck.shift_card
      turn_result.card_received_deck = card
      current_player.add_card(card)
    end

    def play_card(rank, suit)
      card = current_player.take_card(rank, suit)
      add_discard(card)
      card
    end

    # takes from top of deck and adds it to discard pile
    # Returns the card that was added to the discard pile
    def top_deck_card_to_discard
      top_card = deck.shift_card
      add_discard(top_card)
      top_card
    end
  end
end
