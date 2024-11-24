# This job is responsible for updating the subscription status based on the Stripe event data.
# At the moment, it only handles the "past_due" status update which sets the local subscription
# to "unpaid". In the Stripe dashboard the Billing config should be set so that when an Invoice
# is past due, the subscription status is updated to "unpaid", in order to receive this event.
class UpdateSubscriptionJob < ApplicationJob
  def perform(event_data)
    event = Stripe::Event.construct_from(event_data)
    stripe_subscription = event.data.object

    if stripe_subscription.status == "past_due"
      subscription = Subscription.find_by!(stripe_id: stripe_subscription.id)
      return if subscription.unpaid?

      subscription.unpay!
    end
  end
end
