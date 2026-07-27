class ChangeWinnerRefOnGamesToUsers < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :games, column: :winner_id
    add_foreign_key :games, :users, column: :winner_id
  end
end
