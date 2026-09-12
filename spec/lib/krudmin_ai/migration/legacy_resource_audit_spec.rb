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
    expect(report.warnings.join(" ")).to include("HasMany", "field-adapter", "action authorization", "pagination")
    expect(report.blockers.join(" ")).to include("HasOne", "StateMachine", "INLINE_EDITABLE_ATTRIBUTES", "BULK_ACTIONS")
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
end