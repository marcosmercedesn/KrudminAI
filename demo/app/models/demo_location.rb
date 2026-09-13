class DemoLocation < ApplicationRecord
  has_many :assets, class_name: "DemoAsset", dependent: :restrict_with_error

  validates :tenant, :name, :region, :timezone, presence: true
end