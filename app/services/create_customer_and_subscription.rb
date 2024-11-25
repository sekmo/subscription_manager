# This class is responsible for creating a customer and a subscription
# when receiving potentially out-of-order events, in a thread-safe manner.
class CreateCustomerAndSubscription
  def self.call(stripe_subscription)
    stripe_customer = Stripe::Customer.retrieve(stripe_subscription.customer)
    customer = Customer.create_or_find_by(stripe_id: stripe_customer.id) do |cust|
      cust.email = stripe_customer.email
      cust.name = stripe_customer.name
    end

    Subscription.create_or_find_by(stripe_id: stripe_subscription.id) do |subscription|
      subscription.customer_id = customer.id
    end
  end
end
