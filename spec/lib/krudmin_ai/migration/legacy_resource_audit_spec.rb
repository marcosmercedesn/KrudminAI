require "spec_helper"
require "tmpdir"
require "krudmin_ai/migration/legacy_resource_audit"

RSpec.describe KrudminAI::Migration::LegacyResourceAudit do
  def audit(source)
    Dir.mktmpdir do |directory|
      path = File.join(directory, "cars_resource_manager.rb")
      File.write(path, source)
      return described_class.new.call(path)
    end
  end

  it "maps safe legacy constants and flags Car/Passenger migration decisions that cannot be automated" do
    report = audit(<<~RUBY)
      class CarsResourceManager < Krudmin::ResourceManagers::Base
        MODEL_CLASSNAME = "Car"
        EDITABLE_ATTRIBUTES = [:model, :passengers]
        DISPLAYABLE_ATTRIBUTES = [:model, :passengers]
        LISTABLE_ATTRIBUTES = [:model]
        LISTABLE_ACTIONS = [:show, :edit]
        PAGINATOR_POSITION = :bottom
        LISTABLE_INCLUDES = [:car_brand]
        ORDER_BY = [:year]
        ATTRIBUTE_TYPES = { passengers: :HasMany, insurance: :HasOne, status: :StateMachine }
        INLINE_EDITABLE_ATTRIBUTES = [:year]
        BULK_ACTIONS = [:destroy]
      end
    RUBY

    expect(report.mappings).to include(
      "MODEL_CLASSNAME" => "model ModelClass",
      "EDITABLE_ATTRIBUTES" => "form",
      "LISTABLE_ATTRIBUTES" => "list"
    )
    expect(report.warnings.join(" ")).to include("HasMany", "HasOne", "assisted", "pagination")
    expect(report.blockers.join(" ")).to include("StateMachine")
    expect(report.blockers.join(" ")).not_to include("HasOne", "INLINE_EDITABLE_ATTRIBUTES", "BULK_ACTIONS")
    expect(report).not_to be_success
  end

  it "passes a simple supported legacy resource to the manual migration checklist" do
    report = audit(<<~RUBY)
      class CarsResourceManager < Krudmin::ResourceManagers::Base
        MODEL_CLASSNAME = "Car"
        RESOURCE_LABEL = "Car"
        RESOURCES_LABEL = "Cars"
        EDITABLE_ATTRIBUTES = [:model, :passengers]
        ATTRIBUTE_TYPES = { passengers: :HasMany }
      end
    RUBY

    expect(report).to be_success
    expect(report.warnings.join(" ")).to include("HasMany")
  end

  it "classifies a representative Classic Car, Passenger, and Insurance manager precisely" do
    report = audit(<<~RUBY)
      class CarsResourceManager < Krudmin::ResourceManagers::Base
        MODEL_CLASSNAME = "Car"
        ATTRIBUTE_TYPES = {
          model: { type: :Text },
          year: :Number,
          passengers: :HasMany,
          car_insurance: { type: :HasOne },
          car_brand_id: { type: :BelongsTo, remote: true },
          status: { type: :StateMachine },
          car_owner: :BelongsToOne
        }
        INLINE_EDITABLE_ATTRIBUTES = [:year]
        BULK_ACTIONS = [:destroy]
      end
    RUBY

    expect(report.classifications).to include(
      { source: "ATTRIBUTE_TYPES.model", target: "field :model, :text", classification: :automatic, reason: "Supported scalar adapter" },
      { source: "ATTRIBUTE_TYPES.passengers", target: "has_many with child tenant, policy, field, and row-limit declarations", classification: :assisted, reason: "Requires protected relationship declarations" },
      { source: "ATTRIBUTE_TYPES.car_insurance", target: "has_one with child tenant, policy, and field declarations", classification: :assisted, reason: "Requires protected relationship declarations" },
      { source: "ATTRIBUTE_TYPES.status", target: "no automatic mapping", classification: :blocked, reason: "StateMachine requires explicit resource actions or transitions" }
    )
    expect(report.classifications).to include(a_hash_including(source: "ATTRIBUTE_TYPES.car_owner", classification: :blocked))
  end
end
