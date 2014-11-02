namespace :group_transactions do
  require 'open-uri'
  require "oauth2"
  require 'bitsome_coinbase_client'
	task update: :environment do
    COINBASE_CLIENT_ID = '7abefe9ae0829021549ad7f51e7e8c18aaafa55852ff09c4d258dbf0454a106e'
    COINBASE_CLIENT_SECRET = 'a7a9396ba91e85e9b1bead017e36881a31bf0581fb4f72c808aa07729b114671'
    coinbase_client_id = !Rails.env.production? ? COINBASE_CLIENT_ID : '79bc6ea3848ab1a18e8efe451f1c740fa3fb639913c2b41eb3cb20c242528b46'
    coinbase_client_secret = !Rails.env.production? ? COINBASE_CLIENT_SECRET : '871a186df155c37c90ec1615dd01ff8b4d0c83e8d2d2db0e18365bac164ace5f'
    
    last_update = DateTime.parse(Transaction.last.time) rescue DateTime.new(2000)

    User.all.each do |u|
      client = BitSomeCoinbaseClient.new(coinbase_client_id, coinbase_client_secret, u.oauth_credentials.symbolize_keys, u)
      
      page = 1
      response = client.transactions(page, limit: 10)
      num_pages = response['num_pages'].to_i

      catch (:done) do
        num_pages.times do
          transactions = response['transactions'].map { |t| t['transaction'] }
          transactions.each do |t|
            throw :done if last_update >= DateTime.parse(t['created_at'])
            next if t['request']
            next if !Transaction.find_by_transaction_id(t['id']).nil?
            eligible = !User.find_by_coinbase_email(t['sender']['email']).nil? and !User.find_by_coinbase_email(t['recipient']['email']).nil? rescue false
            unless not eligible
              puts "Recording " + u.coinbase_email + " transaction " + t['id']
              transaction = Transaction.new do |u|
                u.transaction_id = t['id']
                u.time = t['created_at']
                u.amount = t['amount'].amount.to_d.abs
                u.sender = t['sender']['email']
                u.receiver = t['recipient']['email']
              end
              transaction.save
            end
          end
          response = client.transactions(page, limit: 10)
        end
      end
    end
  end
end
