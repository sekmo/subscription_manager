class Api::V1::StripeEventsController < ApplicationController
  def create
    payload = request.body.read
    event = Stripe::Event.construct_from(
        JSON.parse(payload, symbolize_names: true)
    )

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

    head :ok
  end
end
