class Api::V1::StripeEventsController < ApplicationController
  def create
    payload = request.body.read
    event_data = JSON.parse(payload, symbolize_names: true)

    if StripeEventProcessorJob::EVENTS_TO_PROCESS.include?(event_data[:type])
      StripeEventProcessorJob.perform_later(event_data) 
    end

    head :ok
  end
end
