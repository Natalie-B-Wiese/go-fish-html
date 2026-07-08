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

  def play
    game_id=turn_result_params[:game_id]
    game=Game.find(game_id)

    # opponent user id and rank requested is nil when player is out of cards and drawing from deck
    opponent_user_id = turn_result_params[:player].nil? ? nil : Integer(turn_result_params[:player])

    game.go_fish.play_turn(opponent_user_id: opponent_user_id, rank_requested: turn_result_params[:rank])
    game.save!

    # TODO: only redirect if successful and user can view the game?
    redirect_to show_game_path(game_id)

  end
  

  private

  def game_params
    params.require(:game).permit(:name, :game_type, :player_count)
  end

  def turn_result_params
    params.expect(turn_result: [:player, :rank, :game_id])
  end
end