class DemoTicket < ApplicationRecord
  include AASM

  STATES = %w[open assigned resolved].freeze
  PRIORITIES = %w[low normal high urgent].freeze

  validates :tenant, :title, :state, :priority, presence: true
  validates :state, inclusion: { in: STATES }
  validates :priority, inclusion: { in: PRIORITIES }

  has_many :passengers, class_name: "DemoPassenger", dependent: :destroy
  accepts_nested_attributes_for :passengers, allow_destroy: true

  aasm column: :state do
    state :open, initial: true
    state :assigned
    state :resolved

    event :resolve do
      transitions from: %i[open assigned], to: :resolved
      after { self.resolved_at = Time.current }
    end
  end
end
