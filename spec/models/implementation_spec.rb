require 'rails_helper'

RSpec.describe Implementation, type: :model do
  let!(:user1) { create :user1 }
  let!(:user2) { create :user2 }
  let!(:user3) { create :user3 }
  let!(:user4) { create :user4 }

  let!(:player1) { GoFish::Player.new(user1.id) }
  let!(:player2) { GoFish::Player.new(user2.id) }
  let!(:player3) { GoFish::Player.new(user3.id) }
  let!(:player4) { GoFish::Player.new(user4.id) }

  let(:players) { [player1, player2, player3] }
  let(:deck) { Deck.new }
  let(:game) { described_class.new(players, deck: deck) }

  describe 'abstract hooks' do
    it 'requires subclasses to implement #start!' do
      expect { game.start! }.to raise_error(NotImplementedError)
    end

    it 'requires subclasses to implement #game_over?' do
      expect { game.game_over? }.to raise_error(NotImplementedError)
    end

    it 'requires subclasses to implement #winning_player' do
      expect { game.winning_player }.to raise_error(NotImplementedError)
    end

    it 'requires subclasses to implement .player_class' do
      expect { described_class.player_class }.to raise_error(NotImplementedError)
    end

    it 'requires subclasses to implement .turn_result_class' do
      expect { described_class.turn_result_class }.to raise_error(NotImplementedError)
    end

    it 'requires subclasses to implement #starting_hand_size' do
      expect { game.send(:starting_hand_size) }.to raise_error(NotImplementedError)
    end
  end

  describe '#switch_turn' do
    it 'advances to the next player' do
      game.switch_turn
      expect(game.current_player_index).to eq 1
    end

    it 'wraps back to the first player after the last' do
      game.current_player_index = players.length - 1
      game.switch_turn
      expect(game.current_player_index).to eq 0
    end
  end

  describe '#current_player and #current_user_id' do
    it 'returns the player at the current index' do
      expect(game.current_player).to eq player1
    end

    it 'returns the current player user id' do
      expect(game.current_user_id).to eq player1.user_id
    end
  end

  describe '#players_hash' do
    it 'indexes players by user id' do
      expect(game.players_hash[player2.user_id]).to eq player2
    end
  end

  describe '#as_json' do
    it 'includes only the shared fields' do
      expect(game.as_json.keys).to contain_exactly(:players, :deck, :current_player_index, :feed)
    end
  end

  describe '#==' do
    let(:twin) { described_class.new(players, deck: deck) }

    it 'is equal when all shared fields match' do
      expect(game).to eq twin
    end

    it 'is not equal when the turn differs' do
      twin.switch_turn
      expect(game).to_not eq twin
    end

    it 'is not equal to nil' do
      expect(game).to_not eq(nil)
    end
  end

  describe '.load' do
    it 'returns nil for blank json' do
      expect(described_class.load(nil)).to be_nil
    end
  end

  describe '.dump' do
    it 'returns the object as_json' do
      expect(described_class.dump(game)).to eq game.as_json
    end
  end
end
