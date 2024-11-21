class StripeEventProcessorJob < ApplicationJob
  def perform(event_data)
    event = Stripe::Event.construct_from(event_data)
    case event.type
    when "customer.subscription.created"
      subscription = event.data.object
      Subscription.create!(stripe_id: subscription.id)
    when "invoice.paid"
      stripe_subscription_id = event.data.object.subscription
      subscription = Subscription.find_by!(stripe_id: stripe_subscription_id)
      subscription.update(status: :paid)
    when "customer.subscription.deleted"
      stripe_subscription_id = event.data.object
      subscription = Subscription.find_by!(stripe_id: stripe_subscription_id)
      subscription.update(status: :cancelled)
    else
      Rails.logger.info "XXX Unhandled event type: #{event.type}"
    end
  end
end
