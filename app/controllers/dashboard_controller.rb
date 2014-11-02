class DashboardController < ApplicationController
	before_filter :authenticate_user!, only: [:show]
	before_filter :check_for_linked_coinbase, only: [:show]
	
	def show
		client = current_coinbase_client
    @current_balance_btc = client.balance.to_d
    @current_balance_usd = client.spot_price("USD").to_d * @current_balance_btc
    @current_buy_price = client.buy_price(1).format
    @current_sell_price = client.sell_price(1).format

    @default_currency = 'USD'
    @exchange_rate = client.spot_price("USD").to_d
    @members = User.where("email != ?", current_user.email) rescue nil
	end

	def transaction_history
    client = current_coinbase_client
    page = params[:page] || 1
    page = page.to_i
    current_page = page
    entries_per_page = 10

    cb_response = client.transactions(page, limit: entries_per_page)
    coinbase_id = cb_response['current_user']['id']
    num_pages = cb_response['num_pages'].to_i
    # FIXME assuming the user has no more than 1000 transfers
    transfers = client.transfers(limit: [1000, page * entries_per_page].min)
    transfers = transfers['transfers'].map { |t| t['transfer'] }
    cb_transactions = cb_response['transactions'].map { |t| t['transaction'] }

    cb_transactions.each do |e|
      ts = transfers.select { |t| t['transaction_id'] == e['id'] }
      e['transfer_type'] = ts.first['type'].downcase unless ts.empty?
    end

    @data = cb_transactions.map do |t|
      next if t['request']
      display_data_from_cb_transaction(t, coinbase_id, current_user)
    end

    @next_page = (current_page < num_pages) ? dashboard_transaction_history_path(page: current_page + 1) : nil
    @prev_page = (current_page != 1) ? dashboard_transaction_history_path(page: current_page - 1) : nil

    puts @data.to_json

		render layout: false
	end

  def display_data_from_cb_transaction(t, current_coinbase_id, current_user)
    begin
      r = {
        time: DateTime.parse(t['created_at']),
        display_time: DateTime.parse(t['created_at']).strftime('%b %d'),
        amount: friendly_amount_from_money(t['amount']),
        direction: t['sender'].nil? ? :from : ((t['sender']['id'] == current_coinbase_id) ? :to : :from),
        pending: t['status'] == 'pending'
      }
    rescue => e
      puts e.message
    end

    id = t['id']

    if !t['transfer_type']
      if r[:direction] == :to
        r[:target] = t['recipient'] ? (User.find_by_coinbase_email(t['recipient']['email']).email rescue t['recipient']['name']) : 'External Account'
      else
        r[:target] = t['sender'] ? (User.find_by_coinbase_email(t['sender']['email']).email rescue t['sender']['name']) : 'External Account'
      end
    end

    r
  end

  def friendly_amount_from_money(amount, options = {})
    friendly_amount(amount.amount, amount.currency, options)
  end

  def friendly_amount(amount, currency, options = {})
    round = options[:round] || 2

    case currency
    when 'BTC'
      (amount * 1000).round(round).to_s + ' mBTC'
    when 'USD'
      amount.round(round).to_s + ' USD'
    end
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
