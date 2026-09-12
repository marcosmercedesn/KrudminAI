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

  it "inherits presentation metadata and defaults fields to permitted attributes" do
    parent_resource = Class.new(described_class) do
      permit :name, :status
      label "Order"
      plural_label "Orders"
      list :name
      form :name
      show :name, :status
    end
    child_resource = Class.new(parent_resource)
    default_resource = Class.new(described_class) { permit :name, :status }

    expect(child_resource.label).to eq("Order")
    expect(child_resource.plural_label).to eq("Orders")
    expect(child_resource.list).to eq([:name])
    expect(child_resource.form).to eq([:name])
    expect(child_resource.show).to eq([:name, :status])
    expect(default_resource.list).to eq([:name, :status])
    expect(default_resource.form).to eq([:name, :status])
    expect(default_resource.show).to eq([:name, :status])
  end

  it "inherits eager-loading and archive lifecycle metadata" do
    parent_resource = Class.new(described_class) do
      includes :owner
      preload :comments
      archive :archived_at
    end
    child_resource = Class.new(parent_resource)

    expect(child_resource.included_associations).to eq([:owner])
    expect(child_resource.preloaded_associations).to eq([:comments])
    expect(child_resource).to be_archivable
    expect(child_resource.archive_attribute).to eq(:archived_at)
  end
end