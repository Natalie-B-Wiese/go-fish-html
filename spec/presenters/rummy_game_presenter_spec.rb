require 'rails_helper'

RSpec.describe RummyGamePresenter, type: :model do
  let(:user1) { create(:user1) }
  let(:user2) { create(:user2) }
  let(:game) { create(:started_game, :rummy, users: [user1, user2], player_count: 2).reload }

  describe '#can_draw?' do
    context 'on the current player’s turn, before drawing' do
      let(:presenter) { described_class.new(game, user1) }

      it 'returns true' do
        expect(presenter.can_draw?).to be true
      end
    end

    context 'when it is not my turn' do
      let(:presenter) { described_class.new(game, user2) }

      it 'returns false' do
        expect(presenter.can_draw?).to be false
      end
    end

    context 'after the current player has drawn' do
      let(:presenter) { described_class.new(game, user1) }

      before do
        game.game_state.draw_deck_turn
        game.save!
      end

      it 'returns false' do
        expect(presenter.can_draw?).to be false
      end
    end
  end

  describe '#discard_card' do
    let(:presenter) { described_class.new(game, user1) }

    it 'returns the top card of the discard pile' do
      expect(presenter.discard_card).to eq game.game_state.discard_pile.top_card
    end
  end

  describe '#can_take_discard?' do
    context 'on the current player’s turn, before drawing' do
      let(:presenter) { described_class.new(game, user1) }

      it 'returns true' do
        expect(presenter.can_take_discard?).to be true
      end
    end

    context 'when it is not my turn' do
      let(:presenter) { described_class.new(game, user2) }

      it 'returns false' do
        expect(presenter.can_take_discard?).to be false
      end
    end

    context 'when the discard pile is empty' do
      let(:presenter) { described_class.new(game, user1) }

      before do
        game.game_state.discard_pile.cards = []
        game.save!
      end

      it 'returns false' do
        expect(presenter.can_take_discard?).to be false
      end
    end
  end
end
