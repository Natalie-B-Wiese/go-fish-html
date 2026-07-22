require 'rails_helper'

RSpec.describe Rummy::Implementation, type: :model do
  let(:players) { user_ids.map { |id| Rummy::Player.new(id) } }
  let(:game) { described_class.new(players) }

  describe '#start!' do
    context 'with 2 players' do
      let(:user_ids) { [1, 2] }

      it "deals #{Rummy::Implementation::SMALL_GAME_CARDS} cards to each player" do
        game.start!
        players.each { |player| expect(player.cards.length).to eq Rummy::Implementation::SMALL_GAME_CARDS }
      end

      it 'shuffles the deck' do
        expect(game.deck).to receive(:shuffle)
        game.start!
      end
    end

    context 'with 3 or 4 players' do
      let(:user_ids) { [1, 2, 3, 4] }

      it "deals #{Rummy::Implementation::MEDIUM_GAME_CARDS} cards to each player" do
        game.start!
        players.each { |player| expect(player.cards.length).to eq Rummy::Implementation::MEDIUM_GAME_CARDS }
      end
    end

    context 'with 5 or 6 players' do
      let(:user_ids) { [1, 2, 3, 4, 5, 6] }

      it "deals #{Rummy::Implementation::BIG_GAME_CARDS} cards to each player" do
        game.start!
        players.each { |player| expect(player.cards.length).to eq Rummy::Implementation::BIG_GAME_CARDS }
      end
    end
  end

  describe '#game_over?' do
    # TODO: implement a real test once the win condition (a player emptying their hand) is implemented
  end

  describe '#winning_player' do
    # TODO: implement a real test once the win condition (a player emptying their hand) is implemented
  end

  describe '#as_json, .from_json, and #==' do
    let(:user_ids) { [1, 2] }

    before { game.start! }

    it 'round-trips through dump and load' do
      restored = described_class.load(described_class.dump(game).as_json)
      expect(restored).to eq game
    end

    it 'is not equal when a field differs' do
      restored = described_class.load(described_class.dump(game).as_json)
      restored.switch_turn
      expect(restored).to_not eq game
    end

    it 'is not equal to nil' do
      expect(game).to_not eq(nil)
    end
  end
end
