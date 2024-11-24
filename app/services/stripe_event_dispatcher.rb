# Class responsible for dispatching Stripe events to the appropriate jobs.
# It takes as a parameter a hash with the Stripe event data.
# To avoid being bombarded by Stripe events that we're not interested in,
# the event destination in Stripe should be configured to receive only specific events.
class StripeEventDispatcher
  EVENTS_TO_PROCESS = {
    subscription_created: "customer.subscription.created",
    invoice_paid: "invoice.paid",
    subscription_deleted: "customer.subscription.deleted",
    subscription_updated: "customer.subscription.updated"
  }.freeze

  def self.call(event_data)
    case event_data[:type]
    when EVENTS_TO_PROCESS[:subscription_created]
      CreateSubscriptionJob.perform_later(event_data)
    when EVENTS_TO_PROCESS[:invoice_paid]
      PaySubscriptionJob.perform_later(event_data)
    when EVENTS_TO_PROCESS[:subscription_deleted]
      CancelSubscriptionJob.perform_later(event_data)
    when EVENTS_TO_PROCESS[:subscription_updated]
      UpdateSubscriptionJob.perform_later(event_data)
    end
  end
end
