require "csv"
require "spec_helper"
require "krudmin_ai/access_context"
require "krudmin_ai/resources/base"
require "krudmin_ai/query_access_pipeline"
require "krudmin_ai/mutation_pipeline"
require "krudmin_ai/data_operations/exporter"
require "krudmin_ai/data_operations/importer"

RSpec.describe "data operations" do
  class DataOperationsRecord
    class << self
      attr_accessor :records

      def transaction
        snapshot = records.dup
        yield
      rescue StandardError
        self.records = snapshot
        raise
      end
    end

    attr_accessor :tenant, :title, :priority
    attr_reader :errors

    def initialize(tenant: nil, title: nil, priority: nil)
      @tenant = tenant
      @title = title
      @priority = priority
      @errors = []
    end

    def assign_attributes(attributes)
      attributes.each { |field, value| public_send("#{field}=", value) }
    end

    def save
      return false if title.to_s.empty?

      self.class.records << self unless self.class.records.include?(self)
      true
    end
  end

  class DataOperationsRelation
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

  class DataOperationsAuditor
    attr_reader :events

    def initialize
      @events = []
    end

    def record(event)
      events << event
    end
  end

  class DataOperationsIdempotencyStore
    def initialize
      @results = {}
    end

    def fetch(key)
      @results[key]
    end

    def record(key, result)
      @results[key] = result
    end
  end

  class FailingDataOperationsAuditor
    def record(_event)
      raise "audit unavailable"
    end
  end

  let(:context) { KrudminAI::AccessContext.new(actor: :morgan, tenant: :north, roles: [:operator]) }
  let(:auditor) { DataOperationsAuditor.new }
  let(:store) { DataOperationsIdempotencyStore.new }
  let(:resource) do
    Class.new(KrudminAI::Resources::Base) do
      model DataOperationsRecord
      tenant_scope { |relation, access_context| relation.where(tenant: access_context.tenant) }
      policy_scope { |relation, _access_context| relation }
      tenant_record { |record, access_context| record.tenant == access_context.tenant }
      permit :title, :priority
      sortable :title
      default_sort_by :title
      authorize :create, ->(_record, _context) { true }
      authorize :export, ->(_record, _context) { true }
      authorize :import, ->(_record, _context) { true }
      authorize_field :title, read: ->(_record, _context) { true }, write: ->(_record, _context) { true }
      authorize_field :priority, read: ->(_record, _context) { false }, write: ->(_record, _context) { true }
      export_profile :safe_csv, fields: %i[title priority], masks: { title: ->(value, _record, _context) { value.upcase } }
      import_profile :tickets_csv, mapping: { "Title" => :title, "Priority" => :priority }, required: [:title]
    end
  end

  before do
    DataOperationsRecord.records = [
      DataOperationsRecord.new(tenant: :north, title: "North ticket", priority: "high"),
      DataOperationsRecord.new(tenant: :south, title: "South ticket", priority: "urgent")
    ]
  end

  it "exports only tenant-scoped, field-readable, masked columns and audits the result" do
    result = KrudminAI::DataOperations::Exporter.new(resource:, context:, auditor:).call(
      profile: :safe_csv,
      relation: DataOperationsRelation.new(DataOperationsRecord.records)
    )

    expect(result).to be_success
    expect(CSV.parse(result.csv, headers: true).map(&:to_h)).to eq([{ "title" => "NORTH TICKET" }])
    expect(result.csv).not_to include("high", "South ticket", "urgent")
    expect(auditor.events.last).to have_attributes(operation: :export, profile: :safe_csv, row_count: 1)
  end

  it "previews row-level validation errors without persisting records" do
    result = KrudminAI::DataOperations::Importer.new(resource:, context:, auditor:, idempotency_store: store).preview(
      profile: :tickets_csv,
      csv: "Title,Priority,Secret\n,high,forged\n"
    )

    expect(result.outcome).to eq(:invalid)
    expect(result.rows.first).to have_attributes(number: 2, attributes: { title: nil, priority: "high" })
    expect(result.rows.first.errors).to include("title is required", "Unknown column: Secret")
    expect(DataOperationsRecord.records.length).to eq(2)
    expect(auditor.events).to be_empty
  end

  it "commits through the mutation/audit path once and returns the stored result on retry" do
    importer = KrudminAI::DataOperations::Importer.new(resource:, context:, auditor:, idempotency_store: store)
    csv = "Title,Priority\nImported ticket,normal\n"

    first = importer.commit(profile: :tickets_csv, csv:, idempotency_key: "upload-42")
    second = importer.commit(profile: :tickets_csv, csv:, idempotency_key: "upload-42")

    expect(first).to be_success
    expect(second).to equal(first)
    expect(DataOperationsRecord.records.map(&:title)).to contain_exactly("North ticket", "South ticket", "Imported ticket")
    expect(auditor.events.map(&:operation)).to include(:create, :import)
  end

  it "rolls back every row and reports an audit failure when auditing fails" do
    result = KrudminAI::DataOperations::Importer.new(
      resource:,
      context:,
      auditor: FailingDataOperationsAuditor.new,
      idempotency_store: store
    ).commit(profile: :tickets_csv, csv: "Title,Priority\nRejected ticket,normal\n", idempotency_key: "upload-43")

    expect(result.outcome).to eq(:audit_failed)
    expect(DataOperationsRecord.records.map(&:title)).to contain_exactly("North ticket", "South ticket")
    expect(store.fetch("upload-43")).to be_nil
  end
end