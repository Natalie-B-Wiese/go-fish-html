class AddAddressToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :address_country, :string
    add_column :users, :address_state, :string
  end
end
