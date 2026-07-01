class RemoveMinPlayersFromGames < ActiveRecord::Migration[8.1]
  def change
    remove_column :games, :min_players, :integer
  end
end
