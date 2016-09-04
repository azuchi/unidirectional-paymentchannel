class AddRefuntTxToPaymentChannel < ActiveRecord::Migration[5.0]
  def change
    add_column :payment_channels, :refund_tx, :text, limit: 4294967295
  end
end

