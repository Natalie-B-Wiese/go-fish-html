class LeaderboardsController < ApplicationController
  def index
    @q = Leaderboard.ransack(params[:q])
    @leaderboards = @q.result
  end
end
