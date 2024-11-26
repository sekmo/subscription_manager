require "rails_helper"

RSpec.describe PaySubscriptionJob, type: :job do
  subject(:pay_subscription_job) { described_class.new }

  describe "#perform" do
    let(:event_data) { { "id" => "evt_123", "data" => { "object" => { "subscription" => "sub_1QP6g6KvFeX4s4udFvSJLuTa" } } } }
    let(:subscription) { create(:subscription) }

    before do
      allow(FindOrCreateSubscription).to receive(:call).with("sub_1QP6g6KvFeX4s4udFvSJLuTa").and_return(subscription)
    end

    context "when the subscription is unpaid" do
      it "updates the subscription status to paid" do
        expect { pay_subscription_job.perform(event_data) }
          .to change { subscription.reload.status }.from("unpaid").to("paid")
      end
    end

    context "when the subscription is already paid" do
      before do
        subscription.update(status: "paid")
      end

      it "does not update the subscription status" do
        expect { pay_subscription_job.perform(event_data) }.not_to change { subscription.reload.status }
      end
    end

    context "when the subscription is cancelled" do
      before do
        subscription.update(status: "cancelled")
      end

      it "raises an invalid transition error" do
        expect {
          pay_subscription_job.perform(event_data)
        }.to raise_error(AASM::InvalidTransition, "Event 'pay' cannot transition from 'cancelled'.")
      end
    end
  end
end
