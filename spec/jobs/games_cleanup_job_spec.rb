require 'rails_helper'

RSpec.describe GamesCleanupJob, type: :job do
  # pending "add some examples to (or delete) #{__FILE__}"
  describe '#perform' do
    let!(:game1) { create :game, name: 'Game 1', updated_at: 1.day.ago }
    let!(:game2) { create :game, name: 'Game 2', updated_at: 2.days.ago }
    let!(:game3) { create :game, name: 'Game 3', updated_at: 23.hours.ago }

    it 'archives only games that have not had activity in 1 day' do
      GamesCleanupJob.perform_now
      reload_games([game1, game2, game3])

      expect(game1.archived_at).to_not be_nil
      expect(game2.archived_at).to_not be_nil
      expect(game3.archived_at).to be_nil
    end

    it 'is idempotent' do
      GamesCleanupJob.perform_now
      game1.reload

      archived_at = game1.archived_at
      sleep(3)

      GamesCleanupJob.perform_now
      game1.reload
      expect(game1.archived_at).to eq archived_at
    end
  end

  def reload_games(games)
    games.each(&:reload)
  end
end
