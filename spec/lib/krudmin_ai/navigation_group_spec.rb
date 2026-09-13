require "spec_helper"
require "krudmin_ai/navigation_group"

RSpec.describe KrudminAI::NavigationGroup do
  let(:context) { Struct.new(:roles).new([ :manager ]) }

  it "is visible only when its own predicate and a child predicate return true" do
    group = described_class.new(label: "Configuration", visible: ->(access_context) { access_context.roles.include?(:manager) })
    group.navigation_item(label: "Countries", route: :countries_path, visible: ->(_access_context) { true })
    group.navigation_item(label: "Users", route: :users_path, visible: ->(_access_context) { false })

    expect(group).to be_visible(context)
    expect(group.visible_items(context).map(&:display_label)).to eq([ "Countries" ])
  end

  it "fails closed when its visibility predicate raises or no child is visible" do
    raising_group = described_class.new(label: "Configuration", visible: ->(_access_context) { raise "unavailable" })
    raising_group.navigation_item(label: "Countries", route: :countries_path)
    empty_group = described_class.new(label: "Configuration")
    empty_group.navigation_item(label: "Countries", route: :countries_path, visible: ->(_access_context) { false })

    expect(raising_group).not_to be_visible(context)
    expect(empty_group).not_to be_visible(context)
  end

  it "becomes active when one of its children is active" do
    group = described_class.new(label: "Configuration")
    group.navigation_item(label: "Countries", route: :countries_path, active: ->(_view_context) { true })

    expect(group).to be_active(Object.new)
  end
end