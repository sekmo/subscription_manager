class AddStripeEventIdToAudits < ActiveRecord::Migration[7.2]
  def change
    add_column :audits, :stripe_event_id, :string
  end
end
