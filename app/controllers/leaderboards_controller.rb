class LeaderboardsController < ApplicationController
  def index
    @q = Leaderboard.page(params[:page])
                    .per(10)
                    .ransack(params[:q])

    @leaderboards = @q.result.order(user_id: :asc)
  end
end
