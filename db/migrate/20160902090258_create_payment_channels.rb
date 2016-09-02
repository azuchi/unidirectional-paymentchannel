class CreatePaymentChannels < ActiveRecord::Migration[5.0]
  def change
    create_table :payment_channels do |t|
      t.string :channel_id, null: false, unique: true
      t.references :key, foreign_keys: true
      t.timestamps
    end
  end
end
