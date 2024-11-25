require 'rails_helper'

RSpec.describe "Api::V1::StripeEvents", type: :request do
  describe "POST /api/v1/stripe_events" do
    let(:payload) { { id: "evt_1QP6CAKvFeX4s4udBhiaRFou" }.to_json }

    it "calls the StripeEventDispatcher with the parsed event data" do
      expect(StripeEventDispatcher).to receive(:call).with( { id: "evt_1QP6CAKvFeX4s4udBhiaRFou" } )

      post "/api/v1/stripe_events", params: payload, headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:ok)
    end

    context "with a subscription created event" do
      let(:payload) { File.read("spec/fixtures/stripe_events/customer_subscription_created.json") }

      it "creates a subscription and a customer" do
        stripe_customer_double = double(Stripe::Customer, id: "cus_RHfnYDKffI7ob7", email: "mark@white.com", name: "Mark White")
        expect(Stripe::Customer).to receive(:retrieve).with("cus_RHfnYDKffI7ob7").and_return(stripe_customer_double)

        perform_enqueued_jobs do
          expect {
            post "/api/v1/stripe_events", params: payload, headers: { "Content-Type" => "application/json" }
          }.to change(Subscription, :count).by(1)
            .and change(Customer, :count).by(1)
        end

        customer = Customer.last
        subscription = Subscription.last

        expect(customer.stripe_id).to eq("cus_RHfnYDKffI7ob7")
        expect(customer.email).to eq("mark@white.com")
        expect(customer.name).to eq("Mark White")

        expect(subscription.stripe_id).to eq("sub_1QP6g6KvFeX4s4udFvSJLuTa")
        expect(subscription.customer).to eq(customer)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with a invoice paid event" do
      let(:payload) { File.read("spec/fixtures/stripe_events/invoice_paid.json") }
      let!(:subscription) { create(:subscription, stripe_id: "sub_1QP6g6KvFeX4s4udFvSJLuTa") }

      it "updates the subscription status from unpaid to paid" do
        perform_enqueued_jobs do
          expect {
            post "/api/v1/stripe_events", params: payload, headers: { "Content-Type" => "application/json" }
          }.to change { subscription.reload.status }.from("unpaid").to("paid")
        end

        expect(response).to have_http_status(:ok)
      end
    end

    context "with a subscription updated event" do
      let(:payload) { File.read("spec/fixtures/stripe_events/customer_subscription_updated.json") }
      let!(:subscription) { create(:subscription, stripe_id: "sub_1QP6g6KvFeX4s4udFvSJLuTa", status: "paid") }

      it "updates the subscription status from paid to unpaid" do
        perform_enqueued_jobs do
          expect {
            post "/api/v1/stripe_events", params: payload, headers: { "Content-Type" => "application/json" }
          }.to change { subscription.reload.status }.from("paid").to("unpaid")
        end

        expect(response).to have_http_status(:ok)
      end
    end

    context "with a customer subscription deleted event" do
      let(:payload) { File.read("spec/fixtures/stripe_events/customer_subscription_deleted.json") }
      let!(:subscription) { create(:subscription, stripe_id: "sub_1QP6g6KvFeX4s4udFvSJLuTa", status: "paid") }

      it "updates the subscription status from paid to canceled" do
        perform_enqueued_jobs do
          expect {
            post "/api/v1/stripe_events", params: payload, headers: { "Content-Type" => "application/json" }
          }.to change { subscription.reload.status }.from("paid").to("cancelled")
        end
      end
    end
  end
end
