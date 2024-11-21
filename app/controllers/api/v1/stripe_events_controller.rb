class Api::V1::StripeEventsController < ApplicationController
  def create
    payload = request.body.read
    event_data = JSON.parse(payload, symbolize_names: true)

    StripeEventProcessorJob.perform_later(event_data)

    head :ok
  end
end
