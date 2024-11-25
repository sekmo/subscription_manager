class CancelSubscriptionJob < StripeEventJob
  def perform(event_data)
    event = Stripe::Event.construct_from(event_data)
    stripe_subscription = event.data.object

    subscription = FindOrCreateSubscription.call(stripe_subscription.id)

    # Handle potential duplicated cancel subscription events
    return if subscription.cancelled?

    subscription.cancel!
  end
end
