class DemoAuditEvent < ApplicationRecord
  serialize :metadata, coder: YAML, type: Hash

  validates :event_type, :tenant, presence: true
end
