class Customer < ApplicationRecord
  validates :stripe_id, presence: true, uniqueness: true
  validates :email, presence: true
  validates :name, presence: true

  has_many :subscriptions, dependent: :destroy
end
