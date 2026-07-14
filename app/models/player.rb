class Player < ApplicationRecord
  # allows dom_id to be used
  include ActionView::RecordIdentifier

  belongs_to :game
  belongs_to :user

  validates :game_id, uniqueness: { scope: :user_id, message: 'You already joined the game' }

  after_create_commit :on_player_joined

  private

  def on_player_joined
    is_in_game = Current.user.games.include?(game)

    # TODO: remove game from list if it is full and user is not in game
    # TODO: if user joins game move it to correct section

    broadcast_replace_to 'games',
                         target: dom_id(game),
                         partial: 'application/game_card',
                         locals: { game: game, is_in_game: is_in_game }
  end
end
