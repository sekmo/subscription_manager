class Subscription < ApplicationRecord
  include AASM
  enum :status, { unpaid: 0, paid: 1, cancelled: 2 }
  validates :stripe_id, presence: true
  belongs_to :customer

  audited

  aasm column: :status, enum: true do
    state :unpaid, initial: true
    state :paid
    state :cancelled

    event :pay do
      transitions from: :unpaid, to: :paid
    end

    event :unpay do
      transitions from: :paid, to: :unpaid
    end

    event :cancel do
      transitions from: :paid, to: :cancelled
    end
  end
end
