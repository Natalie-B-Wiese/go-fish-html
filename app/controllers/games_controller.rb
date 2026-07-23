class GamesController < ApplicationController
  def show
    game = Game.find(params[:id])

    @presenter = game.presenter_class.new(game, Current.user)

    game.start! if game.full? && !game.started?

    if game.game_over?
      game.end! unless game.ended?
      redirect_to games_history_path
    else
      render layout: 'application_game'
    end
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)
    if Player.create(user: Current.user, game: @game) && @game.save
      redirect_to root_url
    else
      flash.now[:alert] = 'There was a problem creating a game.'
      render :new, status: :unprocessable_content
    end
  end

  def join
    game = Game.find(params[:id])

    # prevents user from joining a game they are already in
    if Player.create(user: Current.user, game: game)
      redirect_to show_game_path(game)
    else
      flash.now[:alert] = 'There was a problem joining a game.'
      render :index, status: :unprocessable_content
    end
  end

  def play
    game = Game.find(params[:id])

    game.save! if game.valid_turn? && game.play_turn?(**turn_params_hash)

    redirect_to show_game_path(game)
  end

  private

  # returns nil if user is user cannot play a card even though it's their turn
  def turn_params_hash
    params.require(:turn).permit(:player, :rank, :card, :source).to_h.symbolize_keys
  rescue ActionController::ParameterMissing
    {}
  end

  def game_params
    params.require(:game).permit(:name, :player_count, :type)
  end
end
