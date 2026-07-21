class Player < ApplicationRecord
  # allows dom_id to be used
  include ActionView::RecordIdentifier

  GAME_FULL_MESSAGE = 'This game is already full'.freeze

  belongs_to :game
  belongs_to :user

  validates :game_id, uniqueness: { scope: :user_id, message: 'You already joined the game' }
  validate :game_not_full, on: :create

  after_create_commit :on_player_joined

  private

  def game_not_full
    errors.add(:base, GAME_FULL_MESSAGE) if game.full?
  end

  def on_player_joined
    move_game_to_my_games(user)

    User.all.each do |user|
      update_index_page(user)
    end
  end

  def update_index_page(user)
    is_in_game = user.games.include?(game)

    if game.full? && !is_in_game
      remove_game_from_index(user)
    else
      update_user_game_card(user, is_in_game)
    end
  end

  # removes it from the All Games and adds it to My Games section
  def move_game_to_my_games(user)
    remove_game_from_index(user)
    broadcast_append_later_to 'games', user,
                              target: 'my_games_list',
                              partial: 'application/game_card',
                              locals: { game: game }
  end

  def remove_game_from_index(user)
    broadcast_remove_to 'games', user, target: dom_id(game)
  end

  def update_user_game_card(user, is_in_game)
    broadcast_replace_later_to 'games', user, target: dom_id(game), partial: 'application/game_card',
                                              locals: { game: game, is_in_game: is_in_game }
  end
end
