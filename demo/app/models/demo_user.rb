class DemoUser < ApplicationRecord
  serialize :roles, coder: YAML, type: Array

  validates :name, :tenant, presence: true

  def manager?
    roles.include?("manager")
  end
end
