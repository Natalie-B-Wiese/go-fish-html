class LeaderboardsController < ApplicationController
  def index
    @q = Leaderboard.order(user_id: :asc)
                    .page(params[:page])
                    .per(10)
                    .ransack(params[:q])

    @leaderboards = @q.result
  end
end
