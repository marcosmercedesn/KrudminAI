require "spec_helper"
require "erb"
require "rails"
require "krudmin_ai/engine"

RSpec.describe KrudminAI::Engine do
  it "is an isolated Rails engine" do
    expect(described_class).to be < Rails::Engine
    expect(described_class.isolated?).to be(true)
  end

  it "renders breadcrumbs only for controllers that provide the breadcrumb contract" do
    layout = described_class.root.join("app/views/layouts/krudmin_ai/application.html.erb").read

    expect(layout).to include('render "krudmin_ai/ui/breadcrumbs" if respond_to?(:krudmin_ai_breadcrumbs)')
  end
end
