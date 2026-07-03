class AddWinnerRefToGames < ActiveRecord::Migration[8.1]
  def change
    add_reference :games, :winner, foreign_key: { to_table: :players }, index: true
  end
end
