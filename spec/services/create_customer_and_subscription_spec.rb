require "rails_helper"

RSpec.describe CreateCustomerAndSubscription, type: :service do
  subject(:create_customer_and_subscription) { described_class }

  let(:stripe_subscription) { double(Stripe::Subscription, id: "sub_1QP6g6KvFeX4s4udFvSJLuTa", customer: "cus_RHdASrW482cUtQ") }
  let(:stripe_customer) { double(Stripe::Customer, id: "cus_RHdASrW482cUtQ", email: "mark@white.com", name: "Mark White") }

  before do
    allow(Stripe::Customer).to receive(:retrieve).with(stripe_customer.id).and_return(stripe_customer)
  end

  describe ".call" do
    context "when the customer and subscription do not exist" do
      it "creates a new customer and subscription" do
        expect {
          create_customer_and_subscription.call(stripe_subscription)
        }.to change(Customer, :count).by(1)
          .and change(Subscription, :count).by(1)
        
        customer = Customer.last
        expect(customer.stripe_id).to eq(stripe_customer.id)
        expect(customer.email).to eq(stripe_customer.email)
        expect(customer.name).to eq(stripe_customer.name)

        subscription = Subscription.last
        expect(subscription.stripe_id).to eq(stripe_subscription.id)
        expect(subscription.customer_id).to eq(customer.id)
      end
    end

    context "when the customer exists" do
      before do
        create(:customer, stripe_id: stripe_customer.id)
      end

      it "creates only a new subscription" do
        expect {
          create_customer_and_subscription.call(stripe_subscription)
        }.to change(Subscription, :count).by(1)
          .and change(Customer, :count).by(0)
      end
    end

    context "when the subscription exists" do
      let!(:subscription) { create(:subscription, stripe_id: stripe_subscription.id) }

      it "creates only a new customer" do
        expect {
          create_customer_and_subscription.call(stripe_subscription)
        }.to change(Customer, :count).by(1)
          .and change(Subscription, :count).by(0)
      end

      it "finds and return the existing subscription" do
        found_subscription = create_customer_and_subscription.call(stripe_subscription)
        expect(found_subscription).to eq(subscription)
      end
    end
  end
end