class TurnResultsController < ApplicationController
  def create
    game_id=params[:game_id]
    game=Game.find(game_id)

    result=game.go_fish.play_turn(rank: params[:rank], opponent: params[:player])

    # turn_result=GoFish::TurnResult.new(game_params)

    # if @game.save && Player.create(user: Current.user, game: @game)  
    #   redirect_to games_path
    # end

  end

  private
  def turn_result_params
    params.expect(turn_result: [:player, :rank, :game_id])
  end

end