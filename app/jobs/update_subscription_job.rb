# This job is responsible for updating the subscription status based on the Stripe event data.
# At the moment, it only handles the "past_due" status update which sets the local subscription
# to "unpaid". In the Stripe dashboard the Billing config should be set so that when an Invoice
# is past due, the subscription status is updated to "unpaid", in order to receive this event.
class UpdateSubscriptionJob < StripeEventJob
  PAST_DUE_STATUS = "past_due".freeze

  def perform(event_data)
    event = Stripe::Event.construct_from(event_data)
    stripe_subscription = event.data.object

    return unless stripe_subscription.status == PAST_DUE_STATUS

    subscription = FindOrCreateSubscription.call(stripe_subscription.id)

    # Handle potential duplicated events
    return if subscription.unpaid?

    subscription.unpay!
  end
end
