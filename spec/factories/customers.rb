FactoryBot.define do
  factory :customer do
    sequence(:stripe_id) { |n| "cus_#{n}" }
    email { Faker::Internet.email }
    name { "#{Faker::Name.first_name} #{Faker::Name.last_name}" }
  end
end
