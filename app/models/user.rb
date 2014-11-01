class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  serialize :oauth_credentials

 	def token_expires_in?(time)
 		oauth_credentials ?
     (Time.at(oauth_credentials[:expires_at]) - Time.now) <= time :
     false
  end
end
