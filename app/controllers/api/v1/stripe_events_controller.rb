class Api::V1::StripeEventsController < ApplicationController
  before_action :set_payload
  before_action :verify_stripe_signature

  def create
    event_data = JSON.parse(@payload, symbolize_names: true)

    StripeEventDispatcher.call(event_data)

    head :ok
  end

  private

  def set_payload
    @payload = request.body.read
  end

  def verify_stripe_signature
    stripe_signature = request.env["HTTP_STRIPE_SIGNATURE"]
    Stripe::Webhook.construct_event(@payload, stripe_signature, ENV.fetch("STRIPE_WEBHOOK_SECRET"))
  rescue Stripe::SignatureVerificationError
    head :bad_request
  end
end
