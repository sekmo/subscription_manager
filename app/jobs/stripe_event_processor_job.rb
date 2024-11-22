class StripeEventProcessorJob < ApplicationJob
  EVENTS_TO_PROCESS = [
    "customer.subscription.created",
    "invoice.paid",
    "customer.subscription.deleted"
  ]

  def perform(event_data)
    event = Stripe::Event.construct_from(event_data)
    case event.type
    when "customer.subscription.created"
      subscription = event.data.object
      Subscription.create_or_find_by(stripe_id: subscription.id)
    when "invoice.paid"
      stripe_subscription_id = event.data.object.subscription
      subscription = Subscription.find_by!(stripe_id: stripe_subscription_id)
      subscription.pay!
    when "customer.subscription.deleted"
      stripe_subscription_id = event.data.object
      subscription = Subscription.find_by!(stripe_id: stripe_subscription_id)
      subscription.cancel!
    end
  end
end
