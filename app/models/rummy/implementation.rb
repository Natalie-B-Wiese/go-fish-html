module Rummy
  class Implementation < ::Implementation
    SMALL_GAME_CARDS = 10
    MEDIUM_GAME_CARDS = 7
    BIG_GAME_CARDS = 6

    attr_reader :has_drawn, :discard_pile

    def self.player_class
      Rummy::Player
    end

    def self.turn_result_class
      Rummy::TurnResult
    end

    def initialize(players, deck: Deck.new, discard_pile: DiscardPile.new, current_player_index: 0, feed: [],
                   has_drawn: false)
      super(players, deck: deck, current_player_index: current_player_index, feed: feed)
      @discard_pile = discard_pile
      @has_drawn = has_drawn
    end

    def start!
      deal
      discard_pile.unshift_cards(deck.shift_card)
    end

    def draw_deck_turn
      return nil if has_drawn

      card = deck.shift_card
      turn_result = TurnResult.new(current_user_id: current_user_id, card_received_deck: card)
      current_player.add_card(card)
      @has_drawn = true
      feed.push(turn_result)
      turn_result
    end

    def draw_discard_turn
      return nil if has_drawn || discard_pile.empty?

      card = discard_pile.shift_card
      turn_result = TurnResult.new(current_user_id: current_user_id, card_received_discard: card)
      current_player.add_card(card)
      @has_drawn = true
      feed.push(turn_result)
      turn_result
    end

    def as_json
      super.merge(has_drawn: has_drawn, discard_pile: discard_pile.as_json)
    end

    def self.json_attributes(json)
      super.merge(has_drawn: json['has_drawn'], discard_pile: DiscardPile.from_json(json['discard_pile']))
    end

    def ==(other)
      super && has_drawn == other.has_drawn && discard_pile == other.discard_pile
    end

    # TODO: a player wins by emptying their hand; not yet implemented
    def game_over?
      false
    end

    # TODO: a player wins by emptying their hand; not yet implemented
    def winning_player
      nil
    end

    private

    def starting_hand_size
      return SMALL_GAME_CARDS if players.length == 2
      return MEDIUM_GAME_CARDS if players.length <= 4

      BIG_GAME_CARDS
    end
  end
end
