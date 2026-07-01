class ChangeColumnDefaultForGames < ActiveRecord::Migration[8.1]
  def change
    change_column_default :games, :state, from: nil, to: 0
  end
end
