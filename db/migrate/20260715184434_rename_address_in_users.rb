class RenameAddressInUsers < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :address_country, :country
    rename_column :users, :address_state, :state
  end
end
