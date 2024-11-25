require "rails_helper"

RSpec.describe FindOrCreateSubscription, type: :service do
  subject(:find_or_create_subscription) { described_class }

  describe ".call" do
    let(:stripe_subscription_id) { "sub_1QP6g6KvFeX4s4udFvSJLuTa" }
    let(:stripe_subscription) { double(Stripe::Subscription, id: stripe_subscription_id, customer: "cus_RHdASrW482cUtQ") }

    before do
      allow(Stripe::Subscription).to receive(:retrieve).with(stripe_subscription_id).and_return(stripe_subscription)
    end

    context "when the subscription exists" do
      let!(:subscription) { create(:subscription, stripe_id: stripe_subscription_id) }

      it "finds the subscription" do
        result = find_or_create_subscription.call(stripe_subscription_id)
        expect(result).to eq(subscription)
      end
    end

    context "when the subscription does not exist" do
      it "creates a new customer and subscription" do
        expect(CreateCustomerAndSubscription).to receive(:call).with(stripe_subscription)

        find_or_create_subscription.call(stripe_subscription_id)
      end
    end
  end
end 