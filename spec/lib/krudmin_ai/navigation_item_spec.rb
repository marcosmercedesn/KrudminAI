require "spec_helper"
require "krudmin_ai/resources/base"
require "krudmin_ai/navigation_item"

RSpec.describe KrudminAI::NavigationItem do
  let(:resource) do
    Class.new(KrudminAI::Resources::Base) do
      icon :shopping_cart

      def self.model_class
        Struct.new(:model_name).new(Class.new do
          def self.human(**)
            "Orders"
          end
        end)
      end
    end
  end

  it "derives its label and icon from the configured resource" do
    item = described_class.new(resource:, route: :orders_path)

    expect(item.display_label).to eq("Orders")
    expect(item.icon).to eq(:shopping_cart)
  end

  it "uses a file-text icon when no explicit or resource icon exists" do
    item = described_class.new(label: "Reports", route: :reports_path)

    expect(item.icon).to eq(:file_text)
  end

  it "evaluates visibility with the same access context supplied by the controller" do
    context = Struct.new(:roles).new([:manager])
    item = described_class.new(label: "Admin", route: :admin_path, visible: ->(access_context) { access_context.roles.include?(:manager) })

    expect(item).to be_visible(context)
  end

  it "fails closed when a visibility predicate raises or does not return true" do
    context = Struct.new(:roles).new([:manager])
    raising_item = described_class.new(label: "Admin", route: :admin_path, visible: ->(_access_context) { raise "unavailable" })
    ambiguous_item = described_class.new(label: "Reports", route: :reports_path, visible: ->(_access_context) { "yes" })

    expect(raising_item).not_to be_visible(context)
    expect(ambiguous_item).not_to be_visible(context)
  end

  it "fails inactive when its custom active predicate raises" do
    item = described_class.new(label: "Reports", route: :reports_path, active: ->(_view_context) { raise "unavailable" })

    expect(item).not_to be_active(Object.new)
  end
end