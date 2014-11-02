class DashboardController < ApplicationController
	before_filter :authenticate_user!, only: [:show]
	before_filter :check_for_linked_coinbase, only: [:show]
	
	def show
		client = current_coinbase_client
    @current_balance_btc = client.balance.to_d
    @current_balance_usd = client.spot_price("USD").to_d * @current_balance_btc
    @current_spot_price = client.spot_price.format

    @default_currency = 'USD'
    @exchange_rate = client.spot_price("USD").to_d
    @members = User.where("email != ?", current_user.email) rescue nil
	end

	def transaction_history
    @data = Transaction.all
		render layout: false
	end

	def graph_canvas
		@nodes = User.all
		@edges = []
		@max = 0
		@nodes.each_with_index do |n,i|
			@nodes.each_with_index.reject {|m,j| i == j}.each do |m,j|
				net = 0
				Transaction.where(:sender=>m.name).where(:receiver=>n.name).each do |t|
					net += t.amount
				end
				if net > 0
					@edges += [[net,m.name.downcase.split.join,n.name.downcase.split.join]] 
				end
				@max = [@max,net].max
			end
		end
		print @edges
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
		recipient = User.find_by_email(params[:recipient]).coinbase_email
		amount = params[:currency] == "USD" ? params[:amount_usd].to_f : params[:amount_btc].to_f
		message = params[:message]
		
		begin
			r = current_coinbase_client.send_money recipient, amount.to_money(params[:currency]), message
			r.success ? flash[:success] = "Transaction completed!" : flash[:alert] = "Transaction Unsuccessful"
			redirect_to dashboard_show_path
		rescue => e
      flash[:alert] = "Transaction failed. " + e.message
      redirect_to dashboard_show_url
    end
	end

end
