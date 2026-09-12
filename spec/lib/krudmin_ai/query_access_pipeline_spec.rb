require "spec_helper"
require "krudmin_ai/access_context"
require "krudmin_ai/providers"
require "krudmin_ai/resources/base"
require "krudmin_ai/query_access_pipeline"

RSpec.describe KrudminAI::QueryAccessPipeline do
  FakeRelation = Data.define(:operations) do
    WhereChain = Data.define(:relation) do
      def not(value)
        relation.send(:with, :where_not, value)
      end
    end

    def tenant(tenant)
      with(:tenant, tenant)
    end

    def policy(actor, roles)
      with(:policy, actor, roles)
    end

    def filter(name, value)
      with(:filter, name, value)
    end

    def order(value)
      with(:order, value)
    end

    def limit(value)
      with(:limit, value)
    end

    def offset(value)
      with(:offset, value)
    end

    def includes(*associations)
      with(:includes, associations)
    end

    def preload(*associations)
      with(:preload, associations)
    end

    def where(value = nil)
      return WhereChain.new(self) if value.nil?

      with(:where, value)
    end

    private

    def with(*operation)
      self.class.new(operations + [operation])
    end
  end

  let(:actor) { Object.new }
  let(:tenant) { Object.new }
  let(:relation) { FakeRelation.new([]) }
  let(:context) { KrudminAI::AccessContext.new(actor:, tenant:, roles: %i[operator manager]) }

  let(:resource) do
    Class.new(KrudminAI::Resources::Base) do
      model Object
      tenant_scope { |scoped_relation, access_context| scoped_relation.tenant(access_context.tenant) }
      policy_scope { |scoped_relation, access_context| scoped_relation.policy(access_context.actor, access_context.roles) }
      filter(:status) { |scoped_relation, value, _access_context| scoped_relation.filter(:status, value) }
      sortable :created_at, :name
      default_sort_by :created_at, direction: :desc
      paginate per_page: 20, max_per_page: 50
    end
  end

  it "applies tenant, policy, filters, sort, and pagination in canonical order" do
    result = described_class.new(
      resource:,
      context:,
      params: { filters: { status: "active" }, sort: "name:asc", page: "2", per_page: "30" }
    ).call(relation)

    expect(result.records.operations).to eq([
      [:tenant, tenant], [:policy, actor, %i[operator manager]], [:filter, :status, "active"],
      [:order, { name: :asc }], [:limit, 30], [:offset, 30]
    ])
    expect(result).to have_attributes(page: 2, per_page: 30)
  end

  it "requires an authenticated actor before querying" do
    unauthenticated = KrudminAI::AccessContext.new(actor: nil, tenant:)

    expect { described_class.new(resource:, context: unauthenticated).call(relation) }
      .to raise_error(KrudminAI::AuthenticationRequired)
  end

  it "requires a tenant before querying" do
    tenantless = KrudminAI::AccessContext.new(actor:, tenant: nil)

    expect { described_class.new(resource:, context: tenantless).call(relation) }
      .to raise_error(KrudminAI::TenantRequired)
  end

  it "requires authentication for every resource" do
    expect(resource.authentication_required?).to be(true)
  end

  it "rejects a resource without a policy scope" do
    unsecured_resource = Class.new(KrudminAI::Resources::Base) do
      model Object
      tenant_scope { |scoped_relation, _access_context| scoped_relation }
      sortable :created_at
      default_sort_by :created_at
    end

    expect { described_class.new(resource: unsecured_resource, context:).call(relation) }
      .to raise_error(KrudminAI::Resources::ConfigurationError, "Policy scope is required")
  end

  it "denies access when a policy scope rejects the actor" do
    resource.policy_scope { |_scoped_relation, _access_context| false }

    expect { described_class.new(resource:, context:).call(relation) }
      .to raise_error(KrudminAI::AuthorizationDenied)
  end

  it "fails closed when the authorization provider denies or raises" do
    denied_provider = KrudminAI::Providers::TestAdapters::Authorization.new(allowed: false)
    raising_provider = Class.new do
      def scope(relation:, resource:, context:)
        relation
      end
    end.new
    allow(raising_provider).to receive(:scope).and_raise("provider unavailable")

    expect { described_class.new(resource:, context:, authorization_provider: denied_provider).call(relation) }
      .to raise_error(KrudminAI::AuthorizationDenied)
    expect { described_class.new(resource:, context:, authorization_provider: raising_provider).call(relation) }
      .to raise_error(KrudminAI::AuthorizationDenied)
  end

  it "does not allow unknown filters or sort fields to reach the relation" do
    result = described_class.new(
      resource:,
      context:,
      params: { filters: { internal_sql: "unsafe" }, sort: "internal_sql:desc" }
    ).call(relation)

    expect(result.records.operations).to include([:order, { created_at: :desc }])
    expect(result.records.operations).not_to include([:filter, :internal_sql, "unsafe"])
  end

  it "clamps per-page requests to the configured maximum" do
    result = described_class.new(resource:, context:, params: { page: "3", per_page: "1000" }).call(relation)

    expect(result).to have_attributes(page: 3, per_page: 50)
    expect(result.records.operations.last(2)).to eq([[:limit, 50], [:offset, 100]])
  end

  it "applies declared eager loading before filters, sort, and pagination" do
    resource.includes :owner
    resource.preload :comments

    result = described_class.new(resource:, context:, params: { filters: { status: "active" } }).call(relation)

    expect(result.records.operations).to eq([
      [:tenant, tenant], [:policy, actor, %i[operator manager]], [:includes, [:owner]], [:preload, [:comments]],
      [:filter, :status, "active"], [:order, { created_at: :desc }], [:limit, 20], [:offset, 0]
    ])
  end

  it "defaults archive-aware resources to active records and safely handles archive values" do
    resource.archive :archived_at

    active = described_class.new(resource:, context:).call(relation)
    archived = described_class.new(resource:, context:, params: { archive: "archived" }).call(relation)
    all = described_class.new(resource:, context:, params: { archive: "all" }).call(relation)
    invalid = described_class.new(resource:, context:, params: { archive: "outside" }).call(relation)

    expect(active.records.operations).to include([:where, { archived_at: nil }])
    expect(archived.records.operations).to include([:where_not, { archived_at: nil }])
    expect(all.records.operations).not_to include([:where, { archived_at: nil }], [:where_not, { archived_at: nil }])
    expect(invalid.records.operations).to include([:where, { archived_at: nil }])
  end
end