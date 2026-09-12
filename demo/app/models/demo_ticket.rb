class DemoTicket < ApplicationRecord
  STATES = %w[open assigned resolved].freeze
  PRIORITIES = %w[low normal high urgent].freeze

  validates :tenant, :title, :state, :priority, presence: true
  validates :state, inclusion: { in: STATES }
  validates :priority, inclusion: { in: PRIORITIES }
end