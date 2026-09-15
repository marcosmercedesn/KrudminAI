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
    expect(child_resource.list).to eq([ :name ])
    expect(child_resource.form).to eq([ :name ])
    expect(child_resource.show).to eq([ :name, :status ])
    expect(default_resource.list).to eq([ :name, :status ])
    expect(default_resource.form).to eq([ :name, :status ])
    expect(default_resource.show).to eq([ :name, :status ])
  end

  it "declares inheritable constrained form sections" do
    parent_resource = Class.new(described_class) do
      section :identity, fields: %i[name email], label: "Identity", columns: :two
    end

    expect(Class.new(parent_resource).form_sections).to eq(identity: { label: "Identity", fields: %i[name email], columns: :two })
    expect do
      Class.new(described_class) { section :invalid, fields: [ :name ], columns: :three }
    end.to raise_error(ArgumentError, "Section columns must be :one or :two")
  end

  it "declares inheritable constrained list priorities" do
    parent_resource = Class.new(described_class) { list_priority :email, :secondary }

    expect(Class.new(parent_resource).list_field_priorities).to eq(email: :secondary)
    expect do
      Class.new(described_class) { list_priority :email, :hidden }
    end.to raise_error(ArgumentError, "List priority must be :primary, :standard, or :secondary")
  end

  it "inherits eager-loading and archive lifecycle metadata" do
    parent_resource = Class.new(described_class) do
      includes :owner
      preload :comments
      archive :archived_at
    end
    child_resource = Class.new(parent_resource)

    expect(child_resource.included_associations).to eq([ :owner ])
    expect(child_resource.preloaded_associations).to eq([ :comments ])
    expect(child_resource).to be_archivable
    expect(child_resource.archive_attribute).to eq(:archived_at)
  end

  it "denies field access by default and fails closed when a policy raises" do
    resource = Class.new(described_class) do
      authorize_field :name, read: ->(_record, _context) { true }, write: ->(_record, _context) { true }
      authorize_field :secret, read: ->(_record, _context) { raise "unavailable" }, write: ->(_record, _context) { false }
    end

    expect(resource).to be_field_readable(:name, Object.new, Object.new)
    expect(resource).to be_field_writable(:name, Object.new, Object.new)
    expect(resource).not_to be_field_readable(:secret, Object.new, Object.new)
    expect(resource).not_to be_field_writable(:secret, Object.new, Object.new)
    expect(resource).not_to be_field_readable(:unconfigured, Object.new, Object.new)
    expect(resource).not_to be_field_writable(:unconfigured, Object.new, Object.new)
  end

  it "declares inheritable custom actions and state transitions" do
    resource = Class.new(described_class) do
      action(:assign_to_me, label: "Assign to me", writes: [ :assignee ]) { |_record, _context| true }
      transition :resolve, from: %i[open assigned], to: :resolved
    end
    record = Struct.new(:state).new("open")

    expect(resource.action_for(:assign_to_me)).to have_attributes(label: "Assign to me", writes: [ :assignee ])
    expect(resource).to be_action(:resolve)
    expect(resource.action_for(:resolve).call(record, Object.new)).to be(true)
    expect(record.state).to eq("resolved")
  end

  it "enables only previously declared actions for bulk workflows" do
    resource = Class.new(described_class) do
      action(:archive_selected) { |_record, _context| true }
      bulk_action :archive_selected
    end

    expect(Class.new(resource).bulk_actions).to eq([ :archive_selected ])
    expect do
      Class.new(described_class) { bulk_action :undeclared }
    end.to raise_error(ArgumentError, "Bulk action must be declared before it can be enabled")
  end

  it "allows inline editing only for supported adapters" do
    resource = Class.new(described_class) do
      field :name, :string
      inline_edit :name
    end

    expect(resource.inline_editable_fields).to eq([ :name ])
    expect do
      Class.new(described_class) { field :token, :hidden; inline_edit :token }
    end.to raise_error(ArgumentError, "Inline editing is not supported for token")
  end

  describe "range field filters" do
    let(:relation) do
      Class.new do
        attr_reader :conditions

        def initialize(conditions = [])
          @conditions = conditions
        end

        def where(condition)
          self.class.new(conditions + [ condition ])
        end
      end.new
    end

    let(:resource) do
      model = Class.new do
        define_singleton_method(:connection) { Struct.new(:noop).new.tap { |c| def c.quote_column_name(name) = "\"#{name}\"" } }
      end
      Class.new(described_class) { model model }
    end

    def filter(bounds)
      KrudminAI::Resources::Filter.apply_field_filter(relation, resource.model_class, :quantity, :number_range, bounds, :between)
    end

    it "builds a bounded range so each bound is cast through the attribute type" do
      expect(filter({ from: "2", to: "9" }).conditions).to eq([ { quantity: "2".."9" } ])
    end

    it "builds beginless and endless ranges for a single bound" do
      expect(filter({ to: "9" }).conditions).to eq([ { quantity: .."9" } ])
      expect(filter({ from: "2" }).conditions).to eq([ { quantity: "2".. } ])
    end

    it "returns the untouched relation when no bound is supplied" do
      expect(filter({ from: "", to: "" }).conditions).to be_empty
    end

    it "keeps returning a relation so later filters can chain" do
      expect(filter({ from: "2", to: "9" })).to respond_to(:where)
    end
  end

  describe "text field filters" do
    let(:relation) do
      Class.new do
        attr_reader :conditions

        def initialize(conditions = [])
          @conditions = conditions
        end

        def where(condition, value = nil)
          self.class.new(conditions + [ value ? [ condition, value ] : condition ])
        end
      end.new
    end

    let(:resource) do
      model = Class.new do
        define_singleton_method(:connection) { Struct.new(:noop).new.tap { |c| def c.quote_column_name(name) = "\"#{name}\"" } }
      end
      Class.new(described_class) { model model }
    end

    it "uses lower-case SQL comparisons for every text operator" do
      expect(KrudminAI::Resources::Filter.apply_field_filter(relation, resource.model_class, :name, :text, "North%", :equals).conditions).to eq([
        [ 'LOWER("name") LIKE LOWER(?)', "North\\%" ]
      ])
      expect(KrudminAI::Resources::Filter.apply_field_filter(relation, resource.model_class, :name, :text, "North", :contains).conditions).to eq([
        [ 'LOWER("name") LIKE LOWER(?)', "%North%" ]
      ])
    end
  end
end
