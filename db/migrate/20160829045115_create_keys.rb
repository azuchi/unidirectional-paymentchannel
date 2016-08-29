class CreateKeys < ActiveRecord::Migration[5.0]
  def change
    create_table :keys do |t|
      t.string :pubkey, null: false
      t.string :privkey, unique: true, null: false
      t.timestamps
    end
  end
end
