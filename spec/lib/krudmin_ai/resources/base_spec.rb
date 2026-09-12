require "spec_helper"
require "krudmin_ai/resources/base"

RSpec.describe KrudminAI::Resources::Base do
  it "uses an inheritable file-text icon by default" do
    child_resource = Class.new(described_class)

    expect(child_resource.icon).to eq(:file_text)
  end

  it "allows a resource to configure an icon" do
    child_resource = Class.new(described_class) { icon :shopping_cart }

    expect(child_resource.icon).to eq(:shopping_cart)
  end
end