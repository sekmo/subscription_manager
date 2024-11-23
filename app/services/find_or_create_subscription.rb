class FindOrCreateSubscription
  def self.call(stripe_subscription_id, customer_id)
    begin
      Subscription.create_or_find_by(stripe_id: stripe_subscription_id) do |subscription|
        subscription.customer_id = customer_id
      end
    rescue ActiveRecord::RecordNotFound
      retry
    end
  end
end
