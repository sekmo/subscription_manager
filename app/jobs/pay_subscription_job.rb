class PaySubscriptionJob < ApplicationJob
  def perform(event_data)
    event = Stripe::Event.construct_from(event_data)
    stripe_subscription_id = event.data.object.subscription
    subscription = Subscription.find_by!(stripe_id: stripe_subscription_id)
    # Handle potential duplicated pay subscription events
    return if subscription.paid?

    subscription.pay!
  end
end
