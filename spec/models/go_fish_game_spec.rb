require 'rails_helper'

RSpec.describe GoFishGame, type: :model do
  describe 'serialization round trip ' do
    it 'can dump and restore data' do
      players = [GoFish::Player.new(1), GoFish::Player.new(2)]
      current_player_index = 1
      original = GoFish::Implementation.new(players, current_player_index: current_player_index)
      original.deal!
      json = GoFish::Implementation.dump(original)

      restored = GoFish::Implementation.load(json.as_json)

      # restored should have the same players, same cards, same turn
      expect(restored).to eq original
    end
  end
end
