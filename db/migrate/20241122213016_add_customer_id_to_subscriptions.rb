class AddCustomerIdToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_reference :subscriptions, :customer, foreign_key: true, null: false
  end
end
