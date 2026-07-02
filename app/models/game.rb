class Game < ApplicationRecord
  has_many :players

  validates :name, uniqueness: {case_sensitive: true, message: "A game with that name already exists!"}
  validates :name, presence: true

  validates :player_count, comparison: { greater_than: 1, less_than_or_equal_to: 6}

  # enums automatically add boolean checks and other helper find methods to each one.
  # this means you can do game.started? to see if the status is started

  # other helper find methods include:
  # returns all games that are started:
  # Game.started 

  # returns all games that are not finished:
  # Game.where.not(status: :finished)
end
