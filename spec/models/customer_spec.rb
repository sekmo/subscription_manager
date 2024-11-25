require "rails_helper"

RSpec.describe Customer, type: :model do
  let(:customer) { build(:customer, stripe_id: "cus_123", email: "test@example.com", name: "Test User") }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(customer).to be_valid
    end

    it "is not valid without a stripe_id" do
      customer.stripe_id = nil
      expect(customer).not_to be_valid
    end

    it "is not valid without an email" do
      customer.email = nil
      expect(customer).not_to be_valid
    end

    it "is not valid without a name" do
      customer.name = nil
      expect(customer).not_to be_valid
    end
  end

  describe "associations" do
    it "has many subscriptions" do
      customer.save
      subscription = customer.subscriptions.create!(stripe_id: "sub_123")
      expect(customer.subscriptions).to include(subscription)
    end
  end
end
