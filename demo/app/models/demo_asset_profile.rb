class DemoAssetProfile < ApplicationRecord
  belongs_to :demo_asset

  validates :tenant, presence: true
end