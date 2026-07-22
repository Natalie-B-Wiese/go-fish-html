module Rummy
  class Implementation < ::Implementation
    SMALL_GAME_CARDS = 10
    MEDIUM_GAME_CARDS = 7
    BIG_GAME_CARDS = 6

    def self.player_class
      Rummy::Player
    end

    def start!
      deal
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
