class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :transaction_id
      t.string :time
      t.decimal :amount
      t.string :sender
      t.string :receiver

      t.timestamps
    end
  end
end
