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
end