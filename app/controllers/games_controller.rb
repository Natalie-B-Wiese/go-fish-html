class GamesController < ApplicationController
  def new
    @game=Game.new
  end

  def show
    game=Game.find(params[:id])

    if (game.full? && !game.started?)
      game.start!
    end
  end

  def create
    @game=Game.new(game_params)
    if @game.save && Player.create(user: Current.user, game: @game)  
      redirect_to root_url
    else
      flash.now[:alert]="There was a problem creating a game."
      render :new, status: :unprocessable_content
    end
  end

  def join
    game=Game.find(params[:id])

    # TODO: don't let them join a game that is full

    # don't let them join in a game they are already in
    if Player.create(user: Current.user, game: game)
      # TODO: redirect them to a show page that isn't started but shows the players
      redirect_to games_url
    else
      flash.now[:alert]="There was a problem joining a game."
      render :index, status: :unprocessable_content
    end
  end

  private

  def game_params
    params.require(:game).permit(:name, :game_type, :player_count)
  end
end