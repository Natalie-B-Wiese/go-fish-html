class RemoveMaxPlayersFromGames < ActiveRecord::Migration[8.1]
  def change
    remove_column :games, :max_players, :integer
  end
end
