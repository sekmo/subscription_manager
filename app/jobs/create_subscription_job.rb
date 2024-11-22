class CreateSubscriptionJob < ApplicationJob
  def perform(event_data)
    event = Stripe::Event.construct_from(event_data)
    subscription = event.data.object
    Subscription.create_or_find_by(stripe_id: subscription.id)
  end
end
