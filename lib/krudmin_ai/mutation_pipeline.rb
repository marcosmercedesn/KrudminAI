module KrudminAI
  class AuditSinkRequired < StandardError; end
  class AuditFailure < StandardError; end

  AuditEvent = Data.define(:operation, :actor, :tenant, :roles, :record_id)

  MutationResult = Data.define(:operation, :outcome, :record, :errors, :audit_event) do
    def success?
      outcome == :success
    end
  end

  class MutationPipeline
    OPERATIONS = %i[create update destroy].freeze

    def initialize(resource:, context:, auditor:)
      @resource = resource
      @context = context
      @auditor = auditor
    end

    def call(operation:, record:, attributes: {})
      operation = normalize_operation(operation)
      context.validate!
      resource.validate_mutation_contract!(operation)
      validate_auditor!
      authorize_tenant!(record)
      authorize_action!(operation, record)

      return failure(operation, :invalid, record_errors(record)) unless persist(operation, record, attributes)

      event = audit(operation, record)
      MutationResult.new(operation, :success, record, [], event)
    rescue AuthenticationRequired
      failure(operation, :unauthenticated, [error(:unauthenticated, "An authenticated actor is required")])
    rescue TenantRequired
      failure(operation, :tenant_required, [error(:tenant_required, "A tenant is required")])
    rescue AuthorizationDenied, ScopeViolation
      failure(operation, :forbidden, [error(:forbidden, "You are not authorized to perform this action")])
    rescue Resources::ConfigurationError, AuditSinkRequired
      failure(operation, :configuration_error, [error(:configuration_error, "Mutation security is not configured")])
    rescue AuditFailure
      failure(operation, :audit_failed, [error(:audit_failed, "The mutation could not be audited")])
    rescue StandardError
      failure(operation, :persistence_failed, [error(:persistence_failed, "The mutation could not be completed")])
    end

    private

    attr_reader :resource, :context, :auditor

    def normalize_operation(operation)
      normalized = operation.to_sym
      return normalized if OPERATIONS.include?(normalized)

      raise ArgumentError, "Unsupported mutation operation: #{operation}"
    end

    def validate_auditor!
      raise AuditSinkRequired unless auditor.respond_to?(:record)
    end

    def authorize_tenant!(record)
      return if resource.tenant_record_handler.call(record, context)

      raise ScopeViolation, "Record does not belong to the current tenant"
    end

    def authorize_action!(operation, record)
      handler = resource.action_authorizers.fetch(operation)
      return if handler.call(record, context)

      raise AuthorizationDenied, "Authorization policy rejected #{operation}"
    end

    def persist(operation, record, attributes)
      record.assign_attributes(attributes) if %i[create update].include?(operation)
      operation == :destroy ? record.destroy : record.save
    end

    def audit(operation, record)
      event = AuditEvent.new(operation, context.actor, context.tenant, context.roles, record.respond_to?(:id) ? record.id : nil)
      auditor.record(event)
      event
    rescue StandardError
      raise AuditFailure
    end

    def record_errors(record)
      errors = record.respond_to?(:errors) ? record.errors : []
      errors = errors.full_messages if errors.respond_to?(:full_messages)
      Array(errors).map { |message| error(:invalid, message) }
    end

    def failure(operation, outcome, errors)
      MutationResult.new(operation, outcome, nil, errors, nil)
    end

    def error(code, detail)
      { code:, detail: }
    end
  end
end