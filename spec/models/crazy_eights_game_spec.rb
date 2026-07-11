require 'rails_helper'

RSpec.describe CrazyEightsGame, type: :model do
  describe 'serialization round trip ' do
    it 'can dump and restore data' do
      players = [CrazyEights::Player.new(1), CrazyEights::Player.new(2)]
      current_player_index = 1
      original = CrazyEights::Implementation.new(players, current_player_index: current_player_index)
      original.start!
      json = CrazyEights::Implementation.dump(original)

      restored = CrazyEights::Implementation.load(json.as_json)

      expect(restored).to eq original
    end
  end
end
