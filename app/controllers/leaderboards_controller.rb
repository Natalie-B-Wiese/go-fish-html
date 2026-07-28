class LeaderboardsController < ApplicationController
  def index
    @leaderboards = Leaderboard.all
  end
end
