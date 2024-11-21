class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions do |t|
      t.string :stripe_id, null: false, index: { unique: true }
      t.integer :status, null: false, default: 0, limit: 1, index: true
      t.timestamps
    end
  end
end
