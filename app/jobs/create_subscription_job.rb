class CreateSubscriptionJob < StripeEventJob
  def perform(event_data)
    stripe_event = Stripe::Event.construct_from(event_data)
    stripe_subscription = stripe_event.data.object

    CreateCustomerAndSubscription.call(stripe_subscription)
  end
end
