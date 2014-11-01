class DashboardController < ApplicationController
	before_filter :authenticate_user!, only: [:show]
	before_filter :check_for_linked_coinbase, only: [:show]
	
	def show
    @current_balance_btc = current_coinbase_client.balance.to_d
    @current_balance_usd = current_coinbase_client.spot_price("USD").to_d * @current_balance_btc
    @current_buy_price = current_coinbase_client.buy_price(1).format
    @current_sell_price = current_coinbase_client.sell_price(1).format

    @default_currency = 'USD'
    @exchange_rate = current_coinbase_client.spot_price("USD").to_d
    @members = User.find(:all, :conditions => ["email != ?", current_user.email]) rescue nil
	end

	def summary
		@balance = current_coinbase_client.balance.format
		render layout: false
	end

	def link_coinbase
	end

	def authorize_coinbase
		redirect_to @oauth_client.auth_code.authorize_url(redirect_uri: coinbase_callback_uri) + "&scope=all"
	end

	def oauth
    code = params[:code]
    token = @oauth_client.auth_code.get_token(code, redirect_uri: coinbase_callback_uri)

    current_user.update!({oauth_credentials: token.to_hash})
    email = current_coinbase_client.get('/users').users[0].user.email

    current_user.update(coinbase_email: email)

    flash[:success] = "You have successfully linked your Coinbase account #{email}. "
    redirect_to dashboard_show_path
	end

	def transact
		puts params[:amount_usd]
		redirect_to dashboard_show_path
	end

end
