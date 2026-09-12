require "csv"
require "krudmin_ai/observability"
require "krudmin_ai/query_access_pipeline"

module KrudminAI
  module DataOperations
    AuditEvent = Data.define(:operation, :actor, :tenant, :roles, :resource, :profile, :row_count)
    ExportResult = Data.define(:outcome, :csv, :row_count, :errors) do
      def success?
        outcome == :success
      end
    end

    class Exporter
      def initialize(resource:, context:, auditor:, authorization_provider: nil)
        @resource = resource
        @context = context
        @auditor = auditor
        @authorization_provider = authorization_provider
      end

      def call(profile:, relation:, params: {})
        context.validate!
        export_profile = resource.export_profiles.fetch(profile.to_sym)
        authorize!(:export)
        raise AuditSinkRequired unless auditor.respond_to?(:record)

        fields = resource.readable_fields(export_profile.fields, resource.model_class.new, context)
        raise AuthorizationDenied if fields.empty?

        row_count = 0
        csv = CSV.generate do |output|
          output << fields
          QueryAccessPipeline.new(resource:, context:, params:, authorization_provider:).export_relation(relation).each do |record|
            output << fields.map { |field| serialize(record, field, export_profile.masks[field]) }
            row_count += 1
          end
        end
        auditor.record(AuditEvent.new(:export, context.actor, context.tenant, context.roles, resource.name, export_profile.name, row_count))
        Observability.emit("export.completed", resource: resource.name, profile: export_profile.name, row_count:, tenant: context.tenant)
        ExportResult.new(:success, csv, row_count, [])
      rescue KeyError, Resources::ConfigurationError
        failure(:configuration_error, "Export is not configured")
      rescue AuthenticationRequired, TenantRequired, AuthorizationDenied, ScopeViolation
        failure(:forbidden, "Export access was denied")
      rescue AuditSinkRequired
        failure(:audit_failed, "Export could not be audited")
      rescue StandardError
        failure(:failed, "Export could not be completed")
      end

      private

      attr_reader :resource, :context, :auditor, :authorization_provider

      def authorize!(operation)
        record = resource.model_class.new
        allowed = resource.action_authorizers.fetch(operation).call(record, context)
        allowed &&= authorization_provider.authorize?(action: operation, record:, resource:, context:) if authorization_provider
        raise AuthorizationDenied unless allowed == true
      rescue KeyError, StandardError
        raise AuthorizationDenied
      end

      def serialize(record, field, mask)
        value = record.public_send(field)
        mask ? mask.call(value, record, context) : value
      end

      def failure(outcome, detail)
        ExportResult.new(outcome, nil, 0, [{ code: outcome, detail: }])
      end
    end
  end
end