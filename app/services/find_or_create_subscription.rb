class FindOrCreateSubscription
  def self.call(stripe_subscription_id)
    Subscription.find_by!(stripe_id: stripe_subscription_id)
  rescue ActiveRecord::RecordNotFound
    # if we don't have a subscription, we probably need to create both
    # the customer and the subscription
    stripe_subscription = Stripe::Subscription.retrieve(stripe_subscription_id)
    CreateCustomerAndSubscription.call(stripe_subscription)
  end
end
