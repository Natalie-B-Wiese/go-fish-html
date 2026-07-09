class GamesController < ApplicationController
  def show
    @game = Game.find(params[:id])
    @turn = Turn.new(game: @game, requestor_user: Current.user)

    @game.start! if @game.full? && !@game.started?

    if @game.game_over?
      @game.end! unless @game.ended?
      redirect_to games_history_path
    else
      respond_to do |format|
        format.html { render layout: 'application_game' }
        format.json { render json: @game.as_json(current_user) }
      end
    end
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)
    if @game.save && Player.create(user: Current.user, game: @game)
      redirect_to root_url
    else
      flash.now[:alert] = 'There was a problem creating a game.'
      render :new, status: :unprocessable_content
    end
  end

  def join
    game = Game.find(params[:id])

    # TODO: don't let them join a game that is full

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

    return redirect_to show_game_path(game) if game.go_fish.current_user_id != Current.user.id

    play_turn(game)
    game.save!

    # TODO: only redirect if successful and user can view the game?
    redirect_to show_game_path(game)
  end

  private

  def play_turn(game)
    turn_params = turn_result_params
    game.go_fish.play_turn(opponent_user_id: Integer(turn_params[:player]), rank_requested: turn_params[:rank])
  rescue ActionController::ParameterMissing
    game.go_fish.play_turn(opponent_user_id: nil, rank_requested: nil)
  end

  # throws a ActionController::ParameterMissing if user is requesting a card from the deck (aka hand empty)
  def turn_result_params
    params.require(:turn).permit(:player, :rank)
  end

  def game_params
    params.require(:game).permit(:name, :game_type, :player_count)
  end
end
