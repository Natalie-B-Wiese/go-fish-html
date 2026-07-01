class RemoveStateFromGames < ActiveRecord::Migration[8.1]
  def change
    remove_column :games, :state, :integer
  end
end
