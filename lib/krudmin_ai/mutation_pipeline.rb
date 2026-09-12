module KrudminAI
  class AuditSinkRequired < StandardError; end
  class AuditFailure < StandardError; end

  AuditEvent = Data.define(:operation, :actor, :tenant, :roles, :record_id, :affected_child_references)

  MutationResult = Data.define(:operation, :outcome, :record, :errors, :audit_event) do
    def success?
      outcome == :success
    end
  end

  class MutationPipeline
    OPERATIONS = %i[create update destroy].freeze

    def initialize(resource:, context:, auditor:, authorization_provider: nil)
      @resource = resource
      @context = context
      @auditor = auditor
      @authorization_provider = authorization_provider
    end

    def call(operation:, record:, attributes: {})
      operation = normalize_operation(operation)
      context.validate!
      resource.validate_mutation_contract!(operation)
      validate_auditor!
      authorize_tenant!(record)
      authorize_action!(operation, record)
      validate_relationships!(record, attributes) if %i[create update].include?(operation)
      @submitted_child_references = submitted_child_references(attributes) if %i[create update].include?(operation)

      persisted, event = persist_and_audit(operation, record, attributes)
      return failure(operation, :invalid, record_errors(record)) unless persisted

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

    attr_reader :resource, :context, :auditor, :authorization_provider

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
      return if handler.call(record, context) && provider_authorized?(operation, record)

      raise AuthorizationDenied, "Authorization policy rejected #{operation}"
    end

    def provider_authorized?(operation, record)
      return true unless authorization_provider

      authorization_provider.authorize?(action: operation, record: record, resource: resource, context: context)
    rescue StandardError
      false
    end

    def persist(operation, record, attributes)
      return record.destroy if operation == :destroy

      save_record = -> do
        record.assign_attributes(attributes)
        assign_nested_tenants(record)
        record.save
      end
      save_record.call
    end

    def persist_and_audit(operation, record, attributes)
      return persist_and_audit_without_transaction(operation, record, attributes) unless record.class.respond_to?(:transaction)

      event = nil
      persisted = record.class.transaction do
        saved = persist(operation, record, attributes)
        raise ActiveRecord::Rollback unless saved

        event = audit(operation, record)
        true
      end
      [persisted, event]
    end

    def persist_and_audit_without_transaction(operation, record, attributes)
      persisted = persist(operation, record, attributes)
      return [false, nil] unless persisted

      [true, audit(operation, record)]
    end

    def audit(operation, record)
      event = AuditEvent.new(
        operation,
        context.actor,
        context.tenant,
        context.roles,
        record.respond_to?(:id) ? record.id : nil,
        affected_child_references(record)
      )
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

    def validate_relationships!(record, attributes)
      resource.relationships.each_value do |relationship|
        rows = nested_rows(attributes, relationship.name)
        raise ScopeViolation, "Nested row limit exceeded" if rows.length > relationship.maximum

        rows.each do |row|
          child = relationship_child(record, relationship, row)
          action = nested_action(row, child)
          next if relationship.authorizer.call(child, action, context) && relationship.tenant_record_handler.call(child, context)

          raise AuthorizationDenied, "Nested record access rejected"
        end
      end
    end

    def nested_rows(attributes, name)
      values = attributes["#{name}_attributes"] || attributes["#{name}_attributes".to_sym] || {}
      values.respond_to?(:to_unsafe_h) ? values.to_unsafe_h.values : values.to_h.values
    end

    def relationship_child(record, relationship, row)
      identifier = row["id"] || row[:id]
      return relationship_child_class(record, relationship).new unless identifier

      raise ScopeViolation, "New records cannot reference nested children" if record.new_record?

      record.public_send(relationship.name).find(identifier)
    rescue ActiveRecord::RecordNotFound
      raise ScopeViolation, "Nested record is outside the parent association"
    end

    def relationship_child_class(record, relationship)
      record.association(relationship.name).klass
    end

    def nested_action(row, child)
      return :destroy if ActiveModel::Type::Boolean.new.cast(row["_destroy"] || row[:_destroy])

      child.persisted? ? :update : :create
    end

    def affected_child_references(record)
      resource.relationships.each_with_object({}) do |(name, relationship), references|
        next unless relationship

        current_ids = record.public_send(name).map(&:id).compact
        submitted_ids = (@submitted_child_references || {}).fetch(name, [])
        references[name] = (current_ids + submitted_ids).uniq
      end
    end

    def submitted_child_references(attributes)
      resource.relationships.each_with_object({}) do |(name, _relationship), references|
        references[name] = nested_rows(attributes, name).filter_map { |row| row["id"] || row[:id] }
      end
    end

    def assign_nested_tenants(record)
      resource.relationships.each_key do |name|
        record.public_send(name).each do |child|
          child.public_send("#{resource.tenant_attribute}=", context.tenant) if child.new_record? && child.respond_to?("#{resource.tenant_attribute}=")
        end
      end
    end

    def failure(operation, outcome, errors)
      MutationResult.new(operation, outcome, nil, errors, nil)
    end

    def error(code, detail)
      { code:, detail: }
    end
  end
end