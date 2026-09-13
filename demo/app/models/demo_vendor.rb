class DemoVendor < ApplicationRecord
  SERVICE_TIERS = %w[standard priority enterprise].freeze

  has_many :assets, class_name: "DemoAsset", dependent: :restrict_with_error

  validates :tenant, :name, :service_tier, presence: true
  validates :service_tier, inclusion: { in: SERVICE_TIERS }
end