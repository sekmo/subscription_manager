class CreateCustomers < ActiveRecord::Migration[7.2]
  def change
    create_table :customers do |t|
      t.string :stripe_id, null: false, index: { unique: true }
      t.string :email, null: false, index: :true
      t.string :name, null: false
      t.timestamps
    end
  end
end
