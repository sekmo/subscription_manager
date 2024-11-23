class FindOrCreateCustomer
  def self.call(stripe_customer)
    begin
      Customer.create_or_find_by(stripe_id: stripe_customer.id) do |cust|
        cust.email = stripe_customer.email
        cust.name = stripe_customer.name
      end
    rescue ActiveRecord::RecordNotFound
      retry
    end
  end
end
