require 'rails_helper'

RSpec.describe RummyGame, type: :model do
  describe '#play_turn?' do
    let(:rank) { '7' }
    let(:meld_cards) do
      [
        Rummy::Card.new(rank, 'Spades'),
        Rummy::Card.new(rank, 'Hearts'),
        Rummy::Card.new(rank, 'Clubs')
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

    context 'when laying off onto a meld already on the table' do
      let(:lay_off_card) { Rummy::Card.new(rank, 'Diamonds') }
      let(:invalid_card) { Rummy::Card.new('9', 'Diamonds') }
      let(:player1) do
        Rummy::Player.new(1,
                          hand: Rummy::CardCollection.new([lay_off_card, invalid_card]),
                          melds: [Rummy::Meld.new(meld_cards)])
      end

      context 'when the lay-off is successful' do
        it 'returns true' do
          expect(rummy_game.play_turn?(meld: '0', cards: [lay_off_card.key])).to be true
        end

        it 'adds the card to the target meld' do
          rummy_game.play_turn?(meld: '0', cards: [lay_off_card.key])

          expect(rummy_game.game_state.melds.first.cards).to include lay_off_card
        end

        it 'removes the laid-off card from the hand' do
          rummy_game.play_turn?(meld: '0', cards: [lay_off_card.key])

          expect(rummy_game.game_state.current_player.cards).to_not include lay_off_card
        end
      end

      context 'when the lay-off is invalid' do
        it 'returns false' do
          expect(rummy_game.play_turn?(meld: '0', cards: [invalid_card.key])).to be false
        end

        it 'leaves the meld and the hand unchanged' do
          rummy_game.play_turn?(meld: '0', cards: [invalid_card.key])

          expect(rummy_game.game_state.melds.first.cards).to match_array meld_cards
          expect(rummy_game.game_state.current_player.cards).to include invalid_card
        end
      end

      context 'when the meld index is invalid' do
        it 'returns false for an index with no meld' do
          expect(rummy_game.play_turn?(meld: '9', cards: [lay_off_card.key])).to be false
        end

        it 'returns false for an index that is not a number' do
          expect(rummy_game.play_turn?(meld: 'not-an-index', cards: [lay_off_card.key])).to be false
        end
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
