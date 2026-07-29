class Leaderboard < ApplicationRecord
  belongs_to :user

  def self.ransackable_attributes(_auth_object = nil)
    %w[total_games games_won total_time_played win_percentage user_name]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  def readonly?
    true
  end
end
