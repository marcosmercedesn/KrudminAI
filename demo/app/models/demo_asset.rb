class DemoAsset < ApplicationRecord
  LIFECYCLES = %w[commissioning operational maintenance retired].freeze

  belongs_to :demo_location
  belongs_to :demo_vendor
  has_one :profile, class_name: "DemoAssetProfile", dependent: :destroy
  has_many :maintenance_tasks, class_name: "DemoMaintenanceTask", dependent: :destroy
  has_one_attached :photo
  has_one_attached :manual
  has_rich_text :inspection_notes

  accepts_nested_attributes_for :profile
  accepts_nested_attributes_for :maintenance_tasks, allow_destroy: true

  validates :tenant, :name, :asset_tag, :lifecycle, presence: true
  validates :lifecycle, inclusion: { in: LIFECYCLES }

  def service_score
    return 0 unless installed_on

    [ 100 - ((Date.current - installed_on).to_i / 30), 0 ].max
  end
end
