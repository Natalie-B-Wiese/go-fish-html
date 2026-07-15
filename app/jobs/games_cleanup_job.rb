class GamesCleanupJob < ApplicationJob
  queue_as :default

  def perform
    old_nonarchived_games.update_all(archived_at: Time.zone.now)
  end

  private

  def old_nonarchived_games
    Game.where(archived_at: nil).where('updated_at <= ?', 1.day.ago)
  end
end
