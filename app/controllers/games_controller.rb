class GamesController < ApplicationController
  def new
    @game=Game.new
  end

  def create
    @game=Game.new(game_params)
    if @game.save
      user= Current.user
      Player.create!(user_id: user.id, game_id: @game.id)

      # Player.all(user_id: @user.id)
      
      redirect_to root_url
    else
      flash.now[:alert]="There was a problem creating a game."
      render :new, status: :unprocessable_content
    end
  end

  private

  def game_params
    params.require(:game).permit(:name, :game_type, :player_count)
  end
end