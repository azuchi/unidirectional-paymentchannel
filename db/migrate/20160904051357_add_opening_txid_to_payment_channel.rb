class AddOpeningTxidToPaymentChannel < ActiveRecord::Migration[5.0]
  def change
    add_column :payment_channels, :opening_txid, :string
  end
end
