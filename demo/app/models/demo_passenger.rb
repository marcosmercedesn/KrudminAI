class DemoPassenger < ApplicationRecord
  belongs_to :demo_ticket

  validates :tenant, :name, presence: true
end