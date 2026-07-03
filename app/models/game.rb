class Game < ApplicationRecord
  has_many :players
  has_many :users, through: :players

  has_one :winner, class_name: 'Player'

  validates :name, uniqueness: {case_sensitive: true, message: "A game with that name already exists!"}
  validates :name, presence: true

  validates :player_count, comparison: { greater_than: 1, less_than_or_equal_to: 6}

  def started?
    !!(!started_at.nil?)
  end

  def full?
    return num_joined_players>=player_count
  end

  def start!
    update!(started_at: Time.zone.now)
  end

  def num_joined_players
    players.count
  end

  def finished?
    (!ended_at.nil?)
  end
  
end
