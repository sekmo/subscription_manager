class CreateSubscriptionJob < StripeEventJob
  def perform(event_data)
    stripe_event = Stripe::Event.construct_from(event_data)
    stripe_subscription = stripe_event.data.object
    stripe_customer = Stripe::Customer.retrieve(stripe_subscription.customer)

    # Handle potential duplicated create subscription events
    customer = CreateOrFindCustomer.call(stripe_customer)
    CreateOrFindSubscription.call(stripe_subscription.id, customer.id)
  end
end
