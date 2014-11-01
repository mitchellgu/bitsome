class ChangeOauthCredentialsFormatInMyTable < ActiveRecord::Migration
  def up
    change_column :users, :oauth_credentials, :text
  end

  def down
    change_column :users, :oauth_credentials, :string
  end
end
