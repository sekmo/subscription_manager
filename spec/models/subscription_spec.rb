require "rails_helper"

RSpec.describe Subscription, type: :model do
  let(:customer) { create(:customer) }
  let(:subscription) { create(:subscription, customer: customer, stripe_id: "sub_123") }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subscription).to be_valid
    end

    it "is not valid without a stripe_id" do
      subscription.stripe_id = nil
      expect(subscription).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to a customer" do
      expect(subscription.customer).to eq(customer)
    end
  end

  describe "state transitions" do
    it "initial state is unpaid" do
      expect(subscription.status).to eq("unpaid")
    end

    context "from state of unpaid" do
      it "can transition to paid" do
        expect { subscription.pay }.to change(subscription, :status).from("unpaid").to("paid")
      end

      it "cannot transition to cancelled" do
        expect { subscription.cancel }.to raise_error(AASM::InvalidTransition)
      end
    end

    context "from state of paid" do
      let(:subscription) { create(:subscription, :paid) }

      it "can transition to unpaid" do
        expect { subscription.unpay }.to change(subscription, :status).from("paid").to("unpaid")
      end

      it "can transition to cancelled" do
        expect { subscription.cancel }.to change(subscription, :status).from("paid").to("cancelled")
      end
    end

    context "from state of cancelled" do
      let(:subscription) { create(:subscription, :cancelled) }

      it "cannot transition to unpaid" do
        expect { subscription.unpay }.to raise_error(AASM::InvalidTransition)
      end

      it "cannot transition to paid" do
        expect { subscription.pay }.to raise_error(AASM::InvalidTransition)
      end
    end
  end
end
