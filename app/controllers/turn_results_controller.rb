class TurnResultsController < ApplicationController
  def create
    game_id=turn_result_params[:game_id]
    game=Game.find(game_id)

    game.go_fish.play_turn(opponent_user_id: Integer(turn_result_params[:player]), rank_requested: turn_result_params[:rank])
    game.save!

    # TODO: only redirect if successful and user can view the game?
    redirect_to show_game_path(game_id)

  end

  private
  def turn_result_params
    params.expect(turn_result: [:player, :rank, :game_id])
  end

end