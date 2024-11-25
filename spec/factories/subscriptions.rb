FactoryBot.define do
  factory :subscription do
    sequence(:stripe_id) { |n| "sub_#{n}" }
    customer

    trait :paid do
      status { "paid" }
    end

    trait :cancelled do
      status { "cancelled" }
    end
  end
end
