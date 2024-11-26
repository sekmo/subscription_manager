require "rails_helper"

RSpec.describe CancelSubscriptionJob, type: :job do
  subject(:cancel_subscription_job) { described_class.new }

  describe "#perform" do
    let(:event_data) { { "id" => "evt_123", "data" => { "object" => { "id" => "sub_1QP6g6KvFeX4s4udFvSJLuTa" } } } }
    let(:subscription) { create(:subscription) }

    before do
      allow(FindOrCreateSubscription).to receive(:call).with("sub_1QP6g6KvFeX4s4udFvSJLuTa").and_return(subscription)
    end

    context "when the subscription is paid" do
      before do
        subscription.update(status: "paid")
      end

      it "updates the subscription status to canceled" do
        expect { cancel_subscription_job.perform(event_data) }
          .to change { subscription.reload.status }.from("paid").to("canceled")
      end
    end

    context "when the subscription is already canceled" do
      before do
        subscription.update(status: "canceled")
      end

      it "does not update the subscription status" do
        expect { cancel_subscription_job.perform(event_data) }.not_to change { subscription.reload.status }
      end
    end

    context "when the subscription is unpaid" do
      it "raises an invalid transition error" do
        expect {
          cancel_subscription_job.perform(event_data)
        }.to raise_error(AASM::InvalidTransition, "Event 'cancel' cannot transition from 'unpaid'.")
      end
    end
  end
end
