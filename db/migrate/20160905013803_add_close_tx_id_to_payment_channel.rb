class AddCloseTxIdToPaymentChannel < ActiveRecord::Migration[5.0]
  def change
    add_column :payment_channels, :close_txid, :string
  end
end
