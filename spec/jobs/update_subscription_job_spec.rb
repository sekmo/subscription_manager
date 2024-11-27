require "rails_helper"

RSpec.describe UpdateSubscriptionJob, type: :job do
  subject(:update_subscription_job) { described_class.new }

  describe "#perform" do
    let(:event_data) { { "id" => "evt_123", "data" => { "object" => { "id" => "sub_1QP6g6KvFeX4s4udFvSJLuTa", "status" => stripe_subscription_status } } } }
    let(:subscription) { create(:subscription) }

    before do
      allow(FindOrCreateSubscription).to receive(:call).with("sub_1QP6g6KvFeX4s4udFvSJLuTa").and_return(subscription)
    end

    shared_examples "doesn't update the subscription status" do
      it "doesn't update the subscription status" do
        expect { update_subscription_job.perform(event_data) }
          .not_to change { subscription.reload.status }
      end
    end

    context "when the stripe subscription status is past_due" do
      let(:stripe_subscription_status) { "past_due" }

      context "when the subscription is paid" do
        before do
          subscription.update(status: "paid")
        end

        it "updates the subscription status to unpaid" do
          expect { update_subscription_job.perform(event_data) }
            .to change { subscription.reload.status }.from("paid").to("unpaid")
        end
      end

      context "when the subscription is already unpaid" do
        before do
          subscription.update(status: "unpaid")
        end

        include_examples "doesn't update the subscription status"
      end

      context "when the subscription is canceled" do
        before do
          subscription.update(status: "canceled")
        end
  
        it "raises an invalid transition error" do
          expect {
            update_subscription_job.perform(event_data)
          }.to raise_error(AASM::InvalidTransition, "Event 'unpay' cannot transition from 'canceled'.")
        end
      end
    end

    context "when the stripe subscription status is not past_due" do
      let(:stripe_subscription_status) { "active" }

      context "when the subscription is paid" do
        before do
          subscription.update(status: "paid")
        end

        include_examples "doesn't update the subscription status"
      end

      context "when the subscription is already unpaid" do
        before do
          subscription.update(status: "unpaid")
        end

        include_examples "doesn't update the subscription status"
      end

      context "when the subscription is canceled" do
        before do
          subscription.update(status: "canceled")
        end
  
        include_examples "doesn't update the subscription status"
      end
    end
  end
end
