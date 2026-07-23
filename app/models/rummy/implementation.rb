module Rummy
  class Implementation < ::Implementation
    SMALL_GAME_CARDS = 10
    MEDIUM_GAME_CARDS = 7
    BIG_GAME_CARDS = 6

    attr_accessor :last_drawn_card

    attr_reader :discard_pile

    def self.player_class
      Rummy::Player
    end

    def self.turn_result_class
      Rummy::TurnResult
    end

    def self.deck_class
      Deck
    end

    def initialize(players, deck: Deck.new, discard_pile: DiscardPile.new, current_player_index: 0, feed: [],
                   last_drawn_card: nil)
      super(players, deck: deck, current_player_index: current_player_index, feed: feed)
      @discard_pile = discard_pile
      @last_drawn_card = last_drawn_card
    end

    def drawn?
      !!last_drawn_card
    end

    def start!
      deal
      discard_pile.unshift_cards(deck.shift_card)
    end

    def draw_deck_turn
      return nil if drawn?

      card = deck.shift_card
      turn_result = TurnResult.new(current_user_id: current_user_id, card_received_deck: card)
      draw_turn(card, turn_result)
    end

    def draw_discard_turn
      return nil if drawn? || discard_pile.empty?

      card = discard_pile.shift_card
      turn_result = TurnResult.new(current_user_id: current_user_id, card_received_discard: card)
      draw_turn(card, turn_result)
    end

    def discardable_cards
      hand = current_player.cards
      return hand if hand.length == 1

      hand - [last_drawn_card]
    end

    def discard_turn(rank:, suit:)
      return nil unless drawn? && discardable_cards.include?(Card.new(rank, suit))

      card_discarded = discard_card(rank, suit)
      turn_result = TurnResult.new(current_user_id: current_user_id, card_discarded: card_discarded)
      switch_turn
      self.last_drawn_card = nil
      feed.push(turn_result)
      turn_result
    end

    def as_json
      super.merge(last_drawn_card: last_drawn_card.as_json, discard_pile: discard_pile.as_json)
    end

    def self.json_attributes(json)
      super.merge(last_drawn_card: card_from_json(json['last_drawn_card']),
                  discard_pile: DiscardPile.from_json(json['discard_pile']))
    end

    def self.card_from_json(card_json)
      card_json.nil? ? nil : Card.from_json(card_json)
    end

    def ==(other)
      super && last_drawn_card == other.last_drawn_card && discard_pile == other.discard_pile
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

    def draw_turn(card, turn_result)
      current_player.add_card(card)
      self.last_drawn_card = card
      feed.push(turn_result)
      turn_result
    end

    def discard_card(rank, suit)
      card = current_player.take_card(rank, suit)
      discard_pile.unshift_cards(card)
      card
    end

    def starting_hand_size
      return SMALL_GAME_CARDS if players.length == 2
      return MEDIUM_GAME_CARDS if players.length <= 4

      BIG_GAME_CARDS
    end
  end
end
