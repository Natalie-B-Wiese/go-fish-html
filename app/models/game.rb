class Game < ApplicationRecord
  has_many :players
  has_many :users, through: :players

  belongs_to :winner, class_name: 'Player', optional: true

  serialize :game_state, coder: GoFish::Game

  validates :name, uniqueness: { case_sensitive: true, message: 'A game with that name already exists!' }
  validates :name, presence: true

  validates :player_count, comparison: { greater_than: 1, less_than_or_equal_to: 6 }

  def find_game_state_player_by_user_id(user_id)
    return nil if game_state.nil?

    game_state.players.find { |player| player.user_id == user_id }
  end

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
    self.game_state = GoFish::Game.new(users.map { |u| GoFish::Player.new(u.id) })
    game_state.deal!
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
