require 'rails_helper'

RSpec.describe RummyGame, type: :model do
  describe '#play_turn?' do
    let(:meld_cards) do
      [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]
    end
    let(:player1) { Rummy::Player.new(1, hand: Rummy::CardCollection.new(meld_cards.dup)) }
    let(:player2) { Rummy::Player.new(2) }
    let(:game_state) do
      Rummy::Implementation.new([player1, player2], deck: Rummy::Deck.new, current_player_index: 0)
    end
    let(:rummy_game) { described_class.new(game_state: game_state) }

    before { game_state.draw_deck_turn }

    context 'when the cards form a valid meld' do
      it 'returns true' do
        expect(rummy_game.play_turn?(cards: meld_cards.map(&:key))).to be true
      end

      it 'lays the meld on the current player' do
        rummy_game.play_turn?(cards: meld_cards.map(&:key))

        expect(rummy_game.game_state.current_player.melds.first.cards).to match_array meld_cards
      end

      it 'removes the melded cards from the hand' do
        rummy_game.play_turn?(cards: meld_cards.map(&:key))

        expect(rummy_game.game_state.current_player.cards).to_not include(*meld_cards)
      end
    end

    context 'when the cards do not form a valid meld' do
      let(:invalid_card_keys) { [meld_cards.first.key] }

      it 'returns false' do
        expect(rummy_game.play_turn?(cards: invalid_card_keys)).to be false
      end
    end
  end
end
