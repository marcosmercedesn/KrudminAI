require "spec_helper"
require "krudmin_ai/resources/base"
require "krudmin_ai/access_context"
require "krudmin_ai/data_operations/exporter"

RSpec.describe KrudminAI::Fields::Registry do
  Column = Data.define(:type)

  class FieldAdapterRecord
    class << self
      attr_accessor :records

      def columns_hash
        { "title" => Column.new(:string) }
      end
    end

    attr_accessor :tenant

    def initialize(tenant: :north)
      @tenant = tenant
    end

    def title
      raise "A denied adapter must not read the field"
    end
  end

  class FieldAdapterRelation
    def initialize(records)
      @records = records
    end

    def where(tenant:)
      self.class.new(@records.select { |record| record.tenant == tenant })
    end

    def order(_sort)
      self
    end

    def each(&block)
      @records.each(&block)
    end
  end

  class FieldAdapterAuditor
    def record(_event); end
  end

  let(:context) { KrudminAI::AccessContext.new(actor: :operator, tenant: :north, roles: [ :operator ]) }

  it "selects a declared string adapter" do
    resource = Class.new(KrudminAI::Resources::Base) do
      field :title, :string, placeholder: "Title"
    end

    adapter = resource.field_adapter(:title)
    expect(adapter).to be_a(KrudminAI::Fields::String)
    expect(adapter.options).to eq(placeholder: "Title")
  end

  it "infers a string adapter from a safe model schema lookup" do
    resource = Class.new(KrudminAI::Resources::Base) do
      model FieldAdapterRecord
    end

    expect(resource.field_adapter(:title)).to be_a(KrudminAI::Fields::String)
  end

  it "maps scalar schemas, formats values, rejects invalid input, and redacts secrets" do
    model = Class.new do
      define_singleton_method(:columns_hash) { { "price" => Column.new(:decimal), "published_on" => Column.new(:date) } }
    end
    resource = Class.new(KrudminAI::Resources::Base) do
      model model
      field :password, :password
      field :token, :hidden
      field :price, :currency, unit: "EUR ", precision: 2
      field :state, :enum, values: %w[draft published]
    end
    record = Struct.new(:price, :password, :token).new(BigDecimal("12.5"), "secret", "token")

    expect(resource.field_adapter(:price)).to be_a(KrudminAI::Fields::Currency)
    expect(resource.field_adapter(:published_on)).to be_a(KrudminAI::Fields::Date)
    expect(resource.field_adapter(:price).show_value(record)).to eq("EUR 12.50")
    expect { resource.field_adapter(:price).parameter("not-a-number") }.to raise_error(ArgumentError)
    expect { resource.field_adapter(:state).parameter("invalid") }.to raise_error(ArgumentError)
    expect(resource.field_adapter(:password).json_value(record)).to be_nil
    expect(resource.field_adapter(:token).export_value(record)).to be_nil
    expect(resource.field_adapter(:password)).not_to be_serializable
    expect(resource.field_adapter(:token)).not_to be_serializable
    expect(resource.field_adapter(:price).filter_definition).to include(type: :number_range)
    expect(resource.field_adapter(:state).filter_definition).to eq(type: :select, options: %w[draft published])
  end

  it "normalizes nullable scalar input, time zones, JSON, and labelled enum options" do
    resource = Class.new(KrudminAI::Resources::Base) do
      field :opens_at, :time
      field :published_at, :datetime, time_zone: ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
      field :metadata, :json
      field :state, :enum, values: { "draft" => "Draft", "published" => "Published" }, allow_blank: true
    end
    record = Struct.new(:opens_at, :published_at, :metadata).new(
      Time.utc(2000, 1, 1, 9, 5),
      Time.utc(2026, 9, 12, 15, 30),
      { "source" => "import" }
    )

    expect(resource.field_adapter(:opens_at).parameter("09:05")).to eq("09:05:00")
    expect { resource.field_adapter(:opens_at).parameter("morning") }.to raise_error(ArgumentError)
    expect(resource.field_adapter(:opens_at).show_value(record)).to eq("09:05")
    expect(resource.field_adapter(:published_at).parameter("2026-09-12T11:30:00-04:00")).to eq(Time.utc(2026, 9, 12, 15, 30))
    expect(resource.field_adapter(:published_at).show_value(record)).to eq("2026-09-12 11:30")
    expect(resource.field_adapter(:metadata).parameter('{"source":"import"}')).to eq("source" => "import")
    expect { resource.field_adapter(:metadata).parameter("nope") }.to raise_error(ArgumentError)
    expect(resource.field_adapter(:metadata).show_value(record)).to eq('{"source":"import"}')
    form = instance_double("Form", object: record)
    expect(form).to receive(:text_area).with(
      :metadata,
      hash_including(value: '{"source":"import"}', disabled: false)
    )
    resource.field_adapter(:metadata).form_control(form, writable: true, errors: [], access_note_id: "metadata-note")
    expect(resource.field_adapter(:state).filter_definition).to eq(type: :select, options: [ [ "Draft", "draft" ], [ "Published", "published" ] ])
    expect(resource.field_adapter(:state).parameter("draft")).to eq("draft")
    expect(resource.field_adapter(:state).parameter("")).to be_nil
    expect { resource.field_adapter(:state).parameter("archived") }.to raise_error(ArgumentError)
    expect(resource.field_adapter(:published_at).parameter("")).to be_nil
  end

  it "redacts masked fields unless an explicit reveal policy authorizes access" do
    resource = Class.new(KrudminAI::Resources::Base) do
      field :national_id, :masked
      authorize_field :national_id,
        read: ->(_record, _context) { true },
        write: ->(_record, _context) { true },
        reveal: ->(_record, access_context) { access_context.roles.include?(:compliance) }
    end
    record = Struct.new(:national_id).new("123456789")
    compliance_context = KrudminAI::AccessContext.new(actor: :compliance, tenant: :north, roles: [ :compliance ])

    adapter = resource.field_adapter(:national_id)
    expect(adapter).to be_a(KrudminAI::Fields::Masked)
    expect(adapter.list_value(record)).to eq("[REDACTED]")
    expect(adapter.show_value(record)).to eq("[REDACTED]")
    expect(adapter.json_value(record)).to be_nil
    expect(adapter.export_value(record)).to be_nil
    expect(adapter.ai_value(record)).to be_nil
    expect(adapter).not_to be_serializable
    expect(adapter.revealable?(record, context)).to be(false)
    expect(adapter.revealable?(record, compliance_context)).to be(true)
  end

  it "uses the target resource's protected relation for belongs-to options and labels" do
    candidate = Struct.new(:id, :tenant, :name).new(1, :north, "Regional")
    hidden_candidate = Struct.new(:id, :tenant, :name).new(2, :south, "Other tenant")
    relation_class = Class.new do
      def initialize(records) = @records = records
      def where(tenant:) = self.class.new(@records.select { |record| record.tenant == tenant })
      def order(*) = self
      def each(&block) = @records.each(&block)
      def find(id) = @records.find { |record| record.id == id.to_i } || raise(ActiveRecord::RecordNotFound)
    end
    target_model = Class.new do
      define_singleton_method(:all) { relation_class.new([ candidate, hidden_candidate ]) }
    end
    target_resource = Class.new(KrudminAI::Resources::Base) do
      model target_model
      tenant_scope { |relation, access_context| relation.where(tenant: access_context.tenant) }
      policy_scope { |relation, _context| relation }
      sortable :name
      default_sort_by :name
    end
    resource = Class.new(KrudminAI::Resources::Base) do
      field :rank_id, :belongs_to, resource: target_resource, association: :rank, label: :name,
        label_read: ->(record, _context) { record.name != "Other tenant" }, link: ->(record, _context) { "/ranks/#{record.id}" }
    end
    record = Struct.new(:rank).new(candidate)
    adapter = resource.field_adapter(:rank_id)

    expect(adapter.list_value(record, context:)).to eq("Regional")
    expect(adapter.association_link(record, context)).to eq("/ranks/1")
    expect(adapter.filter_definition[:options].call(context)).to eq([ [ "Regional", 1 ] ])
    expect { adapter.validate_submission(record, 2, context) }.to raise_error(KrudminAI::ScopeViolation)
  end

  it "normalizes and protects every authorized multi-select ID" do
    candidate = Struct.new(:id, :tenant, :name).new(1, :north, "Operations")
    relation_class = Class.new do
      def initialize(records) = @records = records
      def where(tenant:) = self.class.new(@records.select { |record| record.tenant == tenant })
      def order(*) = self
      def each(&block) = @records.each(&block)
      def find(id) = @records.find { |record| record.id == id.to_i } || raise(StandardError)
    end
    target_model = Class.new { define_singleton_method(:all) { relation_class.new([ candidate ]) } }
    target_resource = Class.new(KrudminAI::Resources::Base) do
      model target_model
      tenant_scope { |relation, access_context| relation.where(tenant: access_context.tenant) }
      policy_scope { |relation, _context| relation }
      sortable :name
      default_sort_by :name
    end
    resource = Class.new(KrudminAI::Resources::Base) do
      field :team_ids, :has_many_ids, resource: target_resource, association: :teams, label: :name, label_read: ->(_record, _context) { true }
    end
    adapter = resource.field_adapter(:team_ids)

    expect(adapter.parameter([ "", "1", nil ])).to eq([ "1" ])
    expect { adapter.validate_submission(Object.new, [ "1", "9" ], context) }.to raise_error(KrudminAI::ScopeViolation)
  end

  it "does not invoke a denied field adapter while exporting" do
    resource = Class.new(KrudminAI::Resources::Base) do
      model FieldAdapterRecord
      tenant_scope { |relation, access_context| relation.where(tenant: access_context.tenant) }
      policy_scope { |relation, _context| relation }
      tenant_record { |record, access_context| record.tenant == access_context.tenant }
      permit :title
      sortable :title
      default_sort_by :title
      authorize :export, ->(_record, _context) { true }
      authorize_field :title, read: ->(_record, _context) { false }, write: ->(_record, _context) { false }
      export_profile :titles, fields: [ :title ]
    end

    result = KrudminAI::DataOperations::Exporter.new(resource:, context:, auditor: FieldAdapterAuditor.new).call(
      profile: :titles,
      relation: FieldAdapterRelation.new([ FieldAdapterRecord.new ])
    )

    expect(result.outcome).to eq(:forbidden)
  end
end
