class DemoMaintenanceTask < ApplicationRecord
  STATUSES = %w[planned scheduled complete].freeze

  belongs_to :demo_asset

  validates :tenant, :title, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
end
