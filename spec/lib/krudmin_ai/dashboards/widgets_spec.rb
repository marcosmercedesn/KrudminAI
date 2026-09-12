require "spec_helper"
require "krudmin_ai/access_context"
require "krudmin_ai/resources/base"
require "krudmin_ai/query_access_pipeline"
require "krudmin_ai/dashboards/widgets/base"
require "krudmin_ai/dashboards/widgets/count"
require "krudmin_ai/dashboards/widgets/table"
require "krudmin_ai/dashboards/widgets/summary"

RSpec.describe "dashboard widgets" do
  DashboardRecord = Data.define(:tenant, :permitted_roles, :name, :amount, :created_at)

  DashboardRelation = Data.define(:records, :operations) do
    def where(tenant:)
      with(records.select { |record| record.tenant == tenant }, [:tenant, tenant])
    end

    def policy(actor, roles)
      with(records.select { |record| (record.permitted_roles & roles).any? }, [:policy, actor, roles])
    end

    def order(sort)
      attribute, direction = sort.first
      with(records.sort_by { |record| record.public_send(attribute) }.then { |values| direction == :desc ? values.reverse : values }, [:order, attribute, direction])
    end

    def limit(value)
      with(records.first(value), [:limit, value])
    end

    def offset(value)
      with(records.drop(value), [:offset, value])
    end

    def count
      records.length
    end

    def sum(attribute)
      records.sum { |record| record.public_send(attribute) }
    end

    private

    def with(updated_records, operation)
      self.class.new(updated_records, operations + [operation])
    end
  end

  let(:tenant) { :north }
  let(:actor) { :morgan }
  let(:context) { KrudminAI::AccessContext.new(actor:, tenant:, roles: [:manager]) }
  let(:relation) do
    DashboardRelation.new([
      DashboardRecord.new(:north, [:manager], "North allowed", 25, 2),
      DashboardRecord.new(:north, [:auditor], "North forbidden", 40, 3),
      DashboardRecord.new(:south, [:manager], "South forbidden", 100, 1)
    ], [])
  end
  let(:resource) do
    Class.new(KrudminAI::Resources::Base) do
      model DashboardRecord
      tenant_scope { |scoped_relation, access_context| scoped_relation.where(tenant: access_context.tenant) }
      policy_scope { |scoped_relation, access_context| scoped_relation.policy(access_context.actor, access_context.roles) }
      sortable :created_at
      default_sort_by :created_at, direction: :desc
      paginate per_page: 25, max_per_page: 50
    end
  end

  it "counts only records in the tenant and policy scope" do
    widget = KrudminAI::Dashboards::Widgets::Count.new(resource:, context:, relation:)

    expect(widget.value).to eq(1)
  end

  it "uses the full access pipeline before rendering table records" do
    widget = KrudminAI::Dashboards::Widgets::Table.new(resource:, context:, relation:, columns: [:name], limit: 10)

    expect(widget.records.records.map(&:name)).to eq(["North allowed"])
    expect(widget.records.operations.map(&:first)).to eq(%i[tenant policy order limit offset])
  end

  it "summarizes only authorized tenant data" do
    widget = KrudminAI::Dashboards::Widgets::Summary.new(
      resource:,
      context:,
      relation:,
      summarize: ->(scoped_relation) { { total_amount: scoped_relation.sum(:amount) } }
    )

    expect(widget.value).to eq(total_amount: 25)
  end

  it "does not evaluate a summary when policy scope denies access" do
    resource.policy_scope { |_scoped_relation, _access_context| false }
    widget = KrudminAI::Dashboards::Widgets::Summary.new(resource:, context:, relation:, summarize: ->(_relation) { raise "unsafe" })

    expect { widget.value }.to raise_error(KrudminAI::AuthorizationDenied)
  end
end