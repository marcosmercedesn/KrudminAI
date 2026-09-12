require "csv"
require "krudmin_ai/data_operations/exporter"
require "krudmin_ai/mutation_pipeline"

module KrudminAI
  module DataOperations
    ImportRow = Data.define(:number, :attributes, :errors)
    ImportResult = Data.define(:outcome, :rows, :errors, :idempotency_key) do
      def success?
        outcome == :success
      end
    end

    class Importer
      def initialize(resource:, context:, auditor:, idempotency_store:, authorization_provider: nil)
        @resource = resource
        @context = context
        @auditor = auditor
        @idempotency_store = idempotency_store
        @authorization_provider = authorization_provider
      end

      def preview(profile:, csv:)
        context.validate!
        import_profile = resource.import_profiles.fetch(profile.to_sym)
        authorize!(:import)
        validate_profile!(import_profile)
        parsed_rows = CSV.parse(csv, headers: true)
        rows = parsed_rows.each_with_index.map { |row, index| preview_row(row, index + 2, import_profile) }
        ImportResult.new(rows.any? { |row| row.errors.any? } ? :invalid : :preview, rows, [], nil)
      rescue CSV::MalformedCSVError
        failure(:invalid, "Import file is not valid CSV")
      rescue KeyError, Resources::ConfigurationError
        failure(:configuration_error, "Import is not configured")
      rescue AuthenticationRequired, TenantRequired, AuthorizationDenied
        failure(:forbidden, "Import access was denied")
      end

      def commit(profile:, csv:, idempotency_key:)
        raise ArgumentError, "An idempotency key is required" if idempotency_key.to_s.empty?
        raise ArgumentError, "An idempotency store is required" unless idempotency_store.respond_to?(:fetch) && idempotency_store.respond_to?(:record)

        existing = idempotency_store.fetch(idempotency_key)
        return existing if existing

        raise AuditSinkRequired unless auditor.respond_to?(:record)

        preview_result = preview(profile:, csv:)
        return preview_result unless preview_result.outcome == :preview

        transaction do
          preview_result.rows.each do |row|
            record = resource.model_class.new(resource.tenant_attribute => context.tenant)
            result = MutationPipeline.new(resource:, context:, auditor:, authorization_provider:).call(operation: :create, record:, attributes: row.attributes)
            raise AuditFailure if result.outcome == :audit_failed
            raise ImportFailure unless result.success?
          end
          auditor.record(AuditEvent.new(:import, context.actor, context.tenant, context.roles, resource.name, profile.to_sym, preview_result.rows.length))
        end
        result = ImportResult.new(:success, preview_result.rows, [], idempotency_key)
        idempotency_store.record(idempotency_key, result)
        Observability.emit("import.completed", resource: resource.name, profile: profile.to_sym, row_count: preview_result.rows.length, tenant: context.tenant)
        result
      rescue ImportFailure
        failure(:failed, "Import could not be completed")
      rescue AuditFailure, AuditSinkRequired
        failure(:audit_failed, "Import could not be audited")
      end

      private

      class ImportFailure < StandardError; end

      attr_reader :resource, :context, :auditor, :idempotency_store, :authorization_provider

      def preview_row(row, number, profile)
        attributes = profile.mapping.each_with_object({}) do |(header, field), values|
          values[field] = row[header] if row.headers.include?(header)
        end
        errors = []
        profile.mapping.each do |header, field|
          next unless profile.required_fields.include?(field)
          next if row.headers.include?(header)

          errors << "Missing required column: #{header}"
        end
        (row.headers - profile.mapping.keys).each { |header| errors << "Unknown column: #{header}" }
        profile.required_fields.each { |field| errors << "#{field} is required" if attributes[field].to_s.strip.empty? }
        record = resource.model_class.new(resource.tenant_attribute => context.tenant)
        attributes.each_key { |field| errors << "#{field} is not writable" unless resource.field_writable?(field, record, context) }
        ImportRow.new(number, attributes, errors)
      end

      def validate_profile!(profile)
        invalid_fields = profile.mapping.values - resource.permitted_attributes
        raise Resources::ConfigurationError unless invalid_fields.empty?
      end

      def authorize!(operation)
        record = resource.model_class.new
        allowed = resource.action_authorizers.fetch(operation).call(record, context)
        allowed &&= authorization_provider.authorize?(action: operation, record:, resource:, context:) if authorization_provider
        raise AuthorizationDenied unless allowed == true
      rescue KeyError, StandardError
        raise AuthorizationDenied
      end

      def transaction(&block)
        return resource.model_class.transaction(&block) if resource.model_class.respond_to?(:transaction)

        yield
      rescue AuditFailure, AuditSinkRequired
        raise
      rescue StandardError
        raise ImportFailure
      end

      def failure(outcome, detail)
        ImportResult.new(outcome, [], [{ code: outcome, detail: }], nil)
      end
    end
  end
end