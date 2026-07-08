class GamesController < ApplicationController
  def new
    @game=Game.new
  end

  def show
    @game=Game.find(params[:id])

    @game.start! if (@game.full? && !@game.started?)

    if @game.game_over?
      @game.end! unless @game.ended?
      redirect_to games_history_path
    else
      respond_to do |format|
        format.html {render layout: 'application_game'}
        format.json { render json: @game.as_json(current_user) }
      end
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

    # prevents user from joining a game they are already in
    if Player.create(user: Current.user, game: game)
      redirect_to show_game_path(game.id)
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