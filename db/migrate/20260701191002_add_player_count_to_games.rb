class AddPlayerCountToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :player_count, :integer
  end
end
