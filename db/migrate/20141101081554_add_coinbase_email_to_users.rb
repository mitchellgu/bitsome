class AddCoinbaseEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :coinbase_email, :string
    add_column :users, :oauth_credentials, :string
  end
end
