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

  describe '#can_meld?' do
    context 'on the current player’s turn, before drawing' do
      let(:presenter) { described_class.new(game, user1) }

      it 'returns false' do
        expect(presenter.can_meld?).to be false
      end
    end

    context 'when it is not my turn' do
      let(:presenter) { described_class.new(game, user2) }

      it 'returns false' do
        expect(presenter.can_meld?).to be false
      end
    end

    context 'after the current player has drawn' do
      let(:presenter) { described_class.new(game, user1) }

      before do
        game.game_state.draw_deck_turn
        game.save!
      end

      it 'returns true' do
        expect(presenter.can_meld?).to be true
      end
    end
  end

  describe '#hand_cards_h' do
    let(:presenter) { described_class.new(game, user1) }

    it 'returns the current player’s hand as a hash for the checkbox grid' do
      expect(presenter.hand_cards_h).to eq CardCollection.cards_to_h(game.game_state.current_player.cards)
    end
  end

  describe '#melds' do
    let(:presenter) { described_class.new(game, user1) }

    it 'returns the melds laid by all players' do
      expect(presenter.melds).to eq game.game_state.melds
    end
  end

  describe '#can_lay_off?' do
    let(:presenter) { described_class.new(game, user1) }
    let(:my_meld) do
      Rummy::Meld.new([Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'),
                       Rummy::Card.new('7', 'Clubs')])
    end

    context 'after drawing, when I have laid a meld of my own' do
      before do
        game.game_state.draw_deck_turn
        game.game_state.current_player.add_meld(my_meld)
        game.save!
      end

      it 'returns true' do
        expect(presenter.can_lay_off?).to be true
      end
    end

    context 'after drawing, when I have not laid a meld of my own' do
      before do
        game.game_state.draw_deck_turn
        game.save!
      end

      it 'returns false' do
        expect(presenter.can_lay_off?).to be false
      end
    end

    context 'when I have a meld but have not drawn yet' do
      before do
        game.game_state.current_player.add_meld(my_meld)
        game.save!
      end

      it 'returns false' do
        expect(presenter.can_lay_off?).to be false
      end
    end
  end

  describe '#meld_options_h' do
    let(:presenter) { described_class.new(game, user1) }
    let(:my_meld) do
      Rummy::Meld.new([Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'),
                       Rummy::Card.new('7', 'Clubs')])
    end
    let(:opponent_meld) do
      Rummy::Meld.new([Rummy::Card.new('5', 'Spades'), Rummy::Card.new('6', 'Spades'),
                       Rummy::Card.new('7', 'Spades')])
    end

    context 'after drawing, when the current player has melded' do
      before do
        game.game_state.draw_deck_turn
        game.game_state.current_player.add_meld(my_meld)
        game.game_state.players.last.add_meld(opponent_meld)
        game.save!
      end

      it 'labels each meld 1-based and values it by its index in the melds list' do
        expect(presenter.meld_options_h)
          .to eq(described_class::NEW_MELD_LABEL => '', "1: #{my_meld}" => 0, "2: #{opponent_meld}" => 1)
      end
    end

    context 'after drawing, when the current player has not melded' do
      before do
        game.game_state.draw_deck_turn
        game.game_state.players.last.add_meld(opponent_meld)
        game.save!
      end

      it 'offers only the New Meld option' do
        expect(presenter.meld_options_h).to eq(described_class::NEW_MELD_LABEL => '')
      end
    end
  end

  describe '#discardable_cards_h' do
    let(:presenter) { described_class.new(game, user1) }

    before do
      game.game_state.draw_deck_turn
      game.save!
    end

    it 'returns the discardable cards as a hash for the select input' do
      expect(presenter.discardable_cards_h).to eq CardCollection.cards_to_h(game.game_state.discardable_cards)
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
