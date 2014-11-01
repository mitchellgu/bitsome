require "oauth2"
require 'bitsome_coinbase_client'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :prepare_oauth_client

  COINBASE_CLIENT_ID = '7abefe9ae0829021549ad7f51e7e8c18aaafa55852ff09c4d258dbf0454a106e'
  COINBASE_CLIENT_SECRET = 'a7a9396ba91e85e9b1bead017e36881a31bf0581fb4f72c808aa07729b114671'
  COINBASE_CALLBACK_URI = 'https://localhost:3000/dashboard/oauth'

  def coinbase_client_id
    !Rails.env.production? ? COINBASE_CLIENT_ID : '79bc6ea3848ab1a18e8efe451f1c740fa3fb639913c2b41eb3cb20c242528b46'
  end

  def coinbase_client_secret
    !Rails.env.production? ? COINBASE_CLIENT_SECRET : '871a186df155c37c90ec1615dd01ff8b4d0c83e8d2d2db0e18365bac164ace5f'
  end

  def coinbase_callback_uri
    !Rails.env.production? ? COINBASE_CALLBACK_URI : 'https://bitso.me/dashboard/oauth'
  end

  def check_for_linked_coinbase
  	redirect_to dashboard_link_coinbase_path if current_user.coinbase_email.nil?
  end

  def prepare_oauth_client
    @oauth_client = OAuth2::Client.new(coinbase_client_id, coinbase_client_secret, site: 'https://coinbase.com')
  end

  def coinbase_client_with_oauth_credentials(credentials, user = nil)
    BitSomeCoinbaseClient.new(coinbase_client_id, coinbase_client_secret, credentials.symbolize_keys, user)
  end

  def current_coinbase_client
    if current_user.oauth_credentials
      @current_coinbase_client ||= coinbase_client_with_oauth_credentials(current_user.oauth_credentials, current_user)
    else
      nil
    end
  end

end
