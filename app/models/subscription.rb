class Subscription < ApplicationRecord
  enum :status, { unpaid: 0, paid: 1, cancelled: 2 }

  validates :stripe_id, presence: true, uniqueness: true
end
