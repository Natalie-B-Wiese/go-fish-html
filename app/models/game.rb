class Game < ApplicationRecord
  validates :name, uniqueness: {case_sensitive: true, message: "A game with that name already exists!"}
  validates :name, presence: true

  validates :player_count, comparison: { greater_than: 1, less_than_or_equal_to: 6}
end
