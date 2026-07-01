class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.integer :state
      t.integer :min_players
      t.integer :max_players
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
