class Game < ApplicationRecord
  validates :name, uniqueness: {case_sensitive: true, message: "A game with that name already exists!"}
  validates :name, presence: true

  validates :player_count, comparison: { greater_than: 1, less_than_or_equal_to: 6}

  # waiting: game does not have all the players yet
  # ready: game has all the player but it has not been started yet
  # started: game has all the players and it has been started
  # finished: the game is over

  # TODO: remove this enum it can be inferred from start_date and end_gate
  enum :state, { waiting: 0, ready: 1, started: 2, finished: 3 }

  # enums automatically add boolean checks and other helper find methods to each one.
  # this means you can do game.started? to see if the status is started

  # other helper find methods include:
  # returns all games that are started:
  # Game.started 

  # returns all games that are not finished:
  # Game.where.not(status: :finished)
end
