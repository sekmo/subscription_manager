require "rails_helper"

RSpec.describe CreateSubscriptionJob, type: :job do
  subject(:create_subscription_job) { described_class.new }

  describe "#perform" do
    let(:event_data) { { "id" => "evt_1QP6CAKvFeX4s4udBhiaRFou", "data" => { "object" => { "id" => "sub_123" } } } }
    let(:stripe_event) { Stripe::Event.construct_from(event_data) }
    let(:stripe_subscription) { stripe_event.data.object }

    it "calls CreateCustomerAndSubscription with the stripe subscription" do
      expect(CreateCustomerAndSubscription).to receive(:call).with(stripe_subscription)

      create_subscription_job.perform(event_data)
    end
  end
end