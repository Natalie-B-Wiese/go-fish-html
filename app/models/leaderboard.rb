class Leaderboard < ApplicationRecord
  def self.ransackable_attributes(_auth_object = nil)
    %w[total_games games_won total_time_played win_percentage]
  end

  def readonly?
    true
  end
end
