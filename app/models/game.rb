class Game < ApplicationRecord
  has_many :players
  has_many :users, through: :players

  belongs_to :winner, class_name: 'Player', optional: true

  validates :name, uniqueness: { case_sensitive: true, message: 'A game with that name already exists!' }
  validates :name, presence: true

  validates :player_count, comparison: { greater_than: 1, less_than_or_equal_to: 6 }

  def types
    { 'Go Fish' => 'GoFishGame' }
  end

  def create_and_start_game
    raise NoMethodError, "Abstract method '#{__method__}' must be overridden to create, start, and return a game"
  end

  # finds a specific player (eg a GoFish player) from a user id
  def find_game_state_player_by_user_id(user_id)
    return nil if game_state.nil?

    game_state.players.find { |player| player.user_id == user_id }
  end

  # the user whose turn it is
  def current_game_state_user
    index = game_state.nil? ? 0 : game_state.current_player_index
    users[index]
  end

  def started?
    !started_at.nil?
  end

  def ended?
    !ended_at.nil?
  end

  def full?
    num_joined_players >= player_count
  end

  def start!
    update!(started_at: Time.zone.now)
    self.game_state = create_and_start_game
    save!
  end

  def end!
    update!(ended_at: Time.zone.now, winner: players.find_by(user_id: game_state.winning_player.user_id))
    save!
  end

  def num_joined_players
    players.count
  end

  def finished?
    !ended_at.nil?
  end

  def game_over?
    return false if game_state.nil?

    game_state.game_over?
  end
end
