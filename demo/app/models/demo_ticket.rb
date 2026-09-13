class DemoTicket < ApplicationRecord
  STATES = %w[open assigned resolved].freeze
  PRIORITIES = %w[low normal high urgent].freeze

  validates :tenant, :title, :state, :priority, presence: true
  validates :state, inclusion: { in: STATES }
  validates :priority, inclusion: { in: PRIORITIES }

  has_many :passengers, class_name: "DemoPassenger", dependent: :destroy
  accepts_nested_attributes_for :passengers, allow_destroy: true
end
