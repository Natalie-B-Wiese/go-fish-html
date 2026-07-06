require 'rails_helper'

RSpec.describe Game, type: :model do
  describe 'validations' do
    context 'when names is blank or whitespace' do
      it 'is not valid' do
        
        # name {'Game 1'}
        # state { 0 }
        # player_count { 2 }
        # min_players { 1 }
        # max_players { 5 }
        # started_at { "2026-07-01 14:23:43" }
        # ended_at { nil }

        game=build(:game, name: '  ')
        expect(game).to_not be_valid
      end
    end

    context 'when game with that name already exists' do
      it 'is not valid' do
        game1=create(:game)
        game2=build(:game, name: game1.name)
        expect(game1).to be_valid
        expect(game2).to_not be_valid
      end
    end

    context 'when player count is less than 2' do
      it 'is not valid' do
        game=build(:game, player_count: 1)
        expect(game).to_not be_valid
      end
    end

    context 'when player count is more than 6' do
      it 'is not valid' do
        game=build(:game, player_count: 7)
        expect(game).to_not be_valid
      end
    end

    context 'when player count is between 2 and 6 and name is unique' do
      it 'is valid' do
        game=build(:game, player_count: 3, name: 'My Game')
        expect(game).to be_valid
      end
    end
  end

  xdescribe 'serialization round trip ' do
    # original = GoFish.new(players)
    # original.deal!
    # json = GoFish.dump(original)
    # restored = GoFish.load(json)
    
    # restored should have the same players, same cards, same turn
  end
end
