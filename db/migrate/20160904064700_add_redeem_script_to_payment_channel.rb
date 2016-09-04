class AddRedeemScriptToPaymentChannel < ActiveRecord::Migration[5.0]
  def change
    add_column :payment_channels, :redeem_script, :string
  end
end
