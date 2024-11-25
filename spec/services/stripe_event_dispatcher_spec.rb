require "rails_helper"

RSpec.describe StripeEventDispatcher, type: :service do
  subject(:stripe_event_dispatcher) { described_class }

  describe ".call" do
    let(:event_data) { { type: event_type } }

    context "when the event is subscription_created" do
      let(:event_type) { "customer.subscription.created" }

      it "enqueues CreateSubscriptionJob" do
        expect(CreateSubscriptionJob).to receive(:perform_later).with(event_data)
        stripe_event_dispatcher.call(event_data)
      end
    end

    context "when the event is invoice_paid" do
      let(:event_type) { "invoice.paid" }

      it "enqueues PaySubscriptionJob" do
        expect(PaySubscriptionJob).to receive(:perform_later).with(event_data)
        stripe_event_dispatcher.call(event_data)
      end
    end

    context "when the event is subscription_deleted" do
      let(:event_type) { "customer.subscription.deleted" }

      it "enqueues CancelSubscriptionJob" do
        expect(CancelSubscriptionJob).to receive(:perform_later).with(event_data)
        stripe_event_dispatcher.call(event_data)
      end
    end

    context "when the event is subscription_updated" do
      let(:event_type) { "customer.subscription.updated" }

      it "enqueues UpdateSubscriptionJob" do
        expect(UpdateSubscriptionJob).to receive(:perform_later).with(event_data)
        stripe_event_dispatcher.call(event_data)
      end
    end
  end
end
