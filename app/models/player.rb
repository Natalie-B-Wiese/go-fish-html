class Player < ApplicationRecord
  # allows dom_id to be used
  include ActionView::RecordIdentifier

  belongs_to :game
  belongs_to :user

  validates :game_id, uniqueness: { scope: :user_id, message: 'You already joined the game' }

  after_create_commit :on_player_joined

  private

  def on_player_joined
    User.all.each do |user|
      is_in_game = user.games.include?(game)

      if game.full? && !is_in_game
        remove_game_from_index(user)
      else
        update_user_game_card(user, is_in_game)
      end
    end
  end

  def remove_game_from_index(user)
    broadcast_remove_to 'games', user, target: dom_id(game)
  end

  def update_user_game_card(user, is_in_game)
    broadcast_replace_to 'games', user, target: dom_id(game), partial: 'application/game_card',
                                        locals: { game: game, is_in_game: is_in_game }
  end
end
