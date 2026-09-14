module KrudminAI
  class ResourceController < ActionController::Base
    helper KrudminAI::IconHelper
    class_attribute :resource_class, instance_accessor: false
    layout "krudmin_ai/application"

    helper_method :model, :models, :resource, :resource_path, :new_resource_path, :edit_resource_path,
            :collection_path, :resource_label, :resources_label, :current_user, :current_tenant,
          :signed_in?, :navigation_items, :authorized_action?, :field_readable?, :field_writable?,
          :readable_fields, :readable_relationship_fields, :relationship_field_writable?, :resource_actions,
            :resource_action_path, :pagination_path, :filter_current_value, :filter_options, :relationship_records,
            :readable_relationship_display_fields, :krudmin_ai_access_context, :krudmin_ai_authorization_provider,
              :remote_lookup_field_path, :reset_filters_path, :sort_path, :sort_direction, :sort_active?, :bulk_action_path,
              :page_title, :krudmin_ai_validation_rules, :krudmin_ai_relationship_validation_rules

    before_action :authenticate_resource_request
    before_action :load_model, only: %i[show edit update destroy restore perform_action]
    around_action :observe_resource_request

    class << self
      def resource(value = nil)
        return resource_class unless value

        self.resource_class = value
      end
    end

    def index
      @query_result = query_pipeline.call(resource.model_class.all)
      @models = @query_result.records
      render_resource_template(:index)
    end

    def show
      render_resource_template(:show)
    end

    def new
      @model = resource.model_class.new
      render_resource_template(:new)
    end

    def create
      @model = resource.model_class.new(resource.tenant_attribute => access_context.tenant)
      persist(:create)
    end

    def edit
      render_resource_template(:edit)
    end

    def update
      persist(:update)
    end

    def destroy
      persist(resource.archivable? ? :archive : :destroy)
    end

    def restore
      persist(:restore)
    end

    def perform_action
      action = resource.action_for(params[:action_name])
      raise ActionController::RoutingError, "Unknown resource action" unless action

      persist(action.name)
    end

    def perform_bulk_action
      action = resource.action_for(params[:action_name])
      raise ActionController::RoutingError, "Unknown bulk resource action" unless action && resource.bulk_actions.include?(action.name)

      records = bulk_records
      authorize_bulk_records!(action, records)
      results = records.map { |record| mutation_pipeline.call(operation: action.name, record:) }
      return render_bulk_failure(results) unless results.all?(&:success?)

      respond_to do |format|
        format.html { redirect_to collection_path, status: :see_other, notice: "#{records.length} #{resources_label.downcase} updated and audited." }
        format.json { render json: { outcome: "success", data: records.map { |record| serialize_json_record(record) } } }
      end
    rescue AuthenticationRequired, TenantRequired, AuthorizationDenied, ScopeViolation
      respond_to do |format|
        format.html { head :forbidden }
        format.json { render json: { outcome: "forbidden", errors: [ { code: "forbidden", detail: "You are not authorized to perform this action" } ] }, status: :forbidden }
      end
    end

    def lookup_field
      adapter = resource.field_adapter(params[:field_name])
      raise ActionController::RoutingError, "Unknown remote lookup field" unless adapter.is_a?(Fields::RemoteBelongsTo)

      page = Integer(params[:page], exception: false) || 1
      raise ActionController::BadRequest, "Invalid lookup page" unless page.positive?

      render json: adapter.lookup_results(
        query: params[:q],
        page:,
        context: access_context,
        authorization_provider:
      )
    rescue AuthenticationRequired, TenantRequired, AuthorizationDenied, ScopeViolation
      render json: { error: "Not authorized" }, status: :forbidden
    end

    def export
      result = DataOperations::Exporter.new(
        resource:,
        context: access_context,
        auditor: audit_sink,
        authorization_provider:
      ).call(profile: params[:profile], relation: resource.model_class.all, params: query_params)
      return render json: { outcome: result.outcome, errors: result.errors }, status: export_status(result) unless result.success?

      send_data result.csv, filename: "#{route_key}-#{params[:profile]}.csv", type: "text/csv", disposition: "attachment"
    end

    def import_preview
      render_import_result(importer.preview(profile: params[:profile], csv: import_csv))
    end

    def import_commit
      render_import_result(importer.commit(profile: params[:profile], csv: import_csv, idempotency_key: request.headers["Idempotency-Key"]))
    end

    def model
      @model
    end

    def models
      @models || []
    end

    def resource_path(record = model)
      route_helper("#{route_key.singularize}_path", record)
    end

    def new_resource_path
      route_helper("new_#{route_key.singularize}_path")
    end

    def edit_resource_path(record = model)
      route_helper("edit_#{route_key.singularize}_path", record)
    end

    def collection_path
      route_helper("#{route_key}_path")
    end

    def pagination_path(page)
      route_helper("#{route_key}_path", query_params.merge(page: page))
    end

    def reset_filters_path
      route_helper("#{route_key}_path")
    end

    def sort_path(attribute)
      route_helper("#{route_key}_path", query_params.merge(page: nil, sort: "#{attribute}:#{sort_direction(attribute)}"))
    end

    def sort_direction(attribute)
      sort_active?(attribute) && params[:sort].to_s.end_with?(":asc") ? :desc : :asc
    end

    # An unpermitted sort parameter is ignored by the query pipeline, so the table must not
    # advertise it as the active sort.
    def sort_active?(attribute)
      return false unless resource.sortable_attributes.include?(attribute.to_sym)

      params[:sort].to_s.split(":", 2).first == attribute.to_s
    end

    def resource_label
      resource.label || resource.model_class.model_name.human
    end

    def resources_label
      resource.plural_label || resource.model_class.model_name.human(count: 2)
    end

    def page_title
      resource_title = case action_name
      when "new", "create"
        t("krudmin_ai.new", resource: resource_label)
      when "edit", "update"
        t("krudmin_ai.edit", resource: resource_label)
      when "show"
        resource_label
      else
        resources_label
      end

      t("krudmin_ai.page_title", resource: resource_title)
    end

    def authorized_action?(action, record = model)
      authorizer = resource.action_authorizers[action.to_sym]
      authorizer&.call(record, access_context) && authorization_provider.authorize?(
        action: action.to_sym,
        record: record,
        resource: resource,
        context: access_context
      )
    rescue StandardError
      false
    end

    def field_readable?(field, record = model)
      resource.field_readable?(field, record, access_context)
    end

    def field_writable?(field, record = model)
      resource.field_writable?(field, record, access_context)
    end

    def krudmin_ai_validation_rules(field, record = model)
      resource.validation_rules(field, record, access_context)
    end

    def krudmin_ai_relationship_validation_rules(relationship, field, record)
      relationship.validation_rules(field, record, access_context, resource)
    end

    def readable_fields(fields, record = model)
      resource.readable_fields(fields, record, access_context)
    end

    def readable_relationship_fields(relationship, record)
      relationship.readable_fields(record, access_context)
    end

    def resource_actions(record = model)
      resource.resource_actions.values.select { |action| authorized_action?(action.name, record) }
    end

    def resource_action_path(record, action)
      route_helper("action_#{route_key.singularize}_path", record, action_name: action)
    end

    def bulk_action_path(action)
      route_helper("bulk_action_#{route_key}_path", action_name: action)
    end

    def relationship_field_writable?(relationship, field, record)
      relationship.field_writable?(field, record, access_context)
    end

    def relationship_records(relationship)
      records = model.public_send(relationship.name)
      return [ records ].compact if relationship.singular?
      return records unless relationship.order && records.respond_to?(:order)

      records.order(relationship.order)
    end

    def readable_relationship_display_fields(relationship, record)
      relationship.readable_display_fields(record, access_context)
    end

    def filter_current_value(definition, part = :value)
      value = params.dig(:filters, definition.name) || params.dig("filters", definition.name.to_s)
      return value if part == :value && !value.respond_to?(:to_unsafe_h) && !value.is_a?(Hash)
      return unless value.respond_to?(:[])

      value&.[](part) || value&.[](part.to_s)
    end

    def filter_options(definition)
      return definition.options unless definition.options.respond_to?(:call)

      definition.options.arity.zero? ? definition.options.call : definition.options.call(access_context)
    end

    def current_user
      current_actor
    end

    def signed_in?
      current_actor.present?
    end

    def navigation_items
      KrudminAI.config.navigation_items.select { |item| item.visible?(access_context) }
    end

    def krudmin_ai_access_context
      access_context
    end

    def krudmin_ai_authorization_provider
      authorization_provider
    end

    def remote_lookup_field_path(field)
      route_helper("lookup_field_#{route_key}_path", field_name: field)
    end

    private

    def resource
      self.class.resource_class || raise(Resources::ConfigurationError, "A resource class is required")
    end

    def authenticate_resource_request
      redirect_to sign_in_path unless access_context.actor
    end

    def observe_resource_request
      Observability.with_correlation(request.request_id) do
        yield
        Observability.emit("request.completed", method: request.request_method, path: request.path, resource: resource.name, status: response.status)
      end
    rescue StandardError => error
      Observability.emit("request.failed", method: request.request_method, path: request.path, resource: resource.name, error_class: error.class.name)
      raise
    end

    def access_context
      @access_context ||= AccessContext.new(actor: current_actor, tenant: current_tenant, roles: current_roles)
    end

    def current_actor
      KrudminAI.config.authentication_provider.authenticate(controller: self)
    rescue StandardError
      nil
    end

    def current_tenant
      authorization_actor = current_actor
      return unless authorization_actor

      KrudminAI.config.tenant_provider.resolve(controller: self, actor: authorization_actor)
    rescue StandardError
      nil
    end

    def current_roles
      current_actor.respond_to?(:roles) ? current_actor.roles : []
    end

    def audit_sink
      KrudminAI.config.audit_provider
    end

    def sign_in_path
      main_app.new_session_path
    end

    def load_model
      @model = query_pipeline(archive: action_name == "restore" ? "archived" : nil)
        .authorized_relation(resource.model_class.all)
        .find(params[:id])
    end

    def persist(operation)
      result = MutationPipeline.new(
        resource:,
        context: access_context,
        auditor: audit_sink,
        authorization_provider: authorization_provider
      )
        .call(operation:, record: model, attributes: permitted_attributes)
      response = MutationResponseAdapter.for(result, format: request.format.symbol)

      return render json: response.payload.merge(data: serialize_json_record(response.payload[:data])), status: response.status if response.format == :json
      return render_turbo_mutation(response, result, operation) if response.format == :turbo_stream

      render_html_mutation(response, result, operation)
    end

    def mutation_pipeline
      MutationPipeline.new(resource:, context: access_context, auditor: audit_sink, authorization_provider:)
    end

    def bulk_records
      identifiers = Array(params[:ids]).filter_map { |identifier| Integer(identifier, exception: false) }.uniq
      raise AuthorizationDenied, "At least one record is required" if identifiers.empty?

      records = query_pipeline.authorized_relation(resource.model_class.all).where(id: identifiers).to_a
      raise ScopeViolation, "A bulk record is outside the protected relation" unless records.length == identifiers.length

      records
    end

    def authorize_bulk_records!(action, records)
      records.each do |record|
        raise AuthorizationDenied, "Bulk action access rejected" unless authorized_action?(action.name, record)

        action.writes.each do |field|
          raise AuthorizationDenied, "Bulk action field access rejected" unless resource.field_writable?(field, record, access_context)
        end
      end
    end

    def render_bulk_failure(results)
      result = results.find { |candidate| !candidate.success? }
      render json: { outcome: result.outcome, errors: result.errors }, status: :unprocessable_entity
    end

    def render_html_mutation(response, result, operation)
      if response.payload[:redirect]
        destination = %i[destroy archive].include?(operation) ? collection_path : resource_path(model)
        return redirect_to(destination, status: response.status, notice: "#{resource_label} #{operation}d and audited.")
      end

      flash.now[:alert] = result.errors.map { |error| error[:detail] }.join(" ")
      render_resource_template(
        response.payload[:template],
        status: response.status
      )
    end

    def render_turbo_mutation(response, result, operation)
      if response.payload[:outcome] == :success
        self.response.set_header("Turbo-Location", %i[destroy archive].include?(operation) ? collection_path : resource_path(model))
        flash.now[:notice] = "#{resource_label} #{operation}d and audited."
      else
        flash.now[:alert] = result.errors.map { |error| error[:detail] }.join(" ")
      end

      template = resource.action?(operation) ? "krudmin_ai/mutations/action_#{result.success? ? "success" : "error"}" : response.payload[:template]
      render template:, formats: [ :turbo_stream ], status: response.status
    end

    def query_pipeline(archive: nil)
      QueryAccessPipeline.new(
        resource:,
        context: access_context,
        params: archive ? query_params.merge(archive:) : query_params,
        authorization_provider: authorization_provider
      )
    end

    def authorization_provider
      KrudminAI.config.authorization_provider
    end

    def importer
      DataOperations::Importer.new(
        resource:,
        context: access_context,
        auditor: audit_sink,
        operation_store: KrudminAI.config.operation_store,
        authorization_provider:
      )
    end

    def import_csv
      params.require(:file).read
    end

    def render_import_result(result)
      status = result.success? ? :ok : result.outcome == :preview ? :unprocessable_entity : :forbidden
      render json: { outcome: result.outcome, rows: result.rows.map(&:to_h), errors: result.errors }, status:
    rescue ActionController::ParameterMissing
      render json: { outcome: "invalid", errors: [ { code: "invalid", detail: "A CSV file is required" } ] }, status: :unprocessable_entity
    end

    def export_status(result)
      result.outcome == :forbidden ? :forbidden : :unprocessable_entity
    end

    def query_params
      params.permit(:page, :per_page, :sort, :archive).to_h.merge(filters: permitted_filters)
    end

    def permitted_filters
      resource.filter_definitions.each_with_object({}) do |(name, definition), permitted|
        value = params.dig(:filters, name) || params.dig("filters", name.to_s)
        next if value.nil?

        permitted[name] = permitted_filter_value(value, definition)
      end.compact
    end

    def permitted_filter_value(value, definition)
      return value if value.is_a?(String) || value.is_a?(Numeric)
      return unless value.respond_to?(:to_unsafe_h)

      raw = value.to_unsafe_h
      range_filter = %i[number_range date_range datetime_range].include?(definition.type)
      allowed_keys = range_filter ? %w[from to] : %w[value operator]
      raw.slice(*allowed_keys).transform_values { |item| item if item.is_a?(String) || item.is_a?(Numeric) }.compact
    end

    def permitted_attributes
      params.fetch(resource.model_class.model_name.param_key, {}).permit(
        *resource.permitted_attribute_parameters,
        *resource.nested_permitted_attributes
      )
    end

    def serialize_json_record(record)
      return unless record

      readable_fields(resource.show, record).filter_map do |field|
        adapter = resource.field_adapter(field)
        [ field, adapter.json_value(record) ] if adapter.serializable?
      end.to_h
    end

    def route_key
      resource.route_key&.to_s || controller_name
    end

    def route_helper(name, *arguments)
      main_app.public_send(namespaced_route_helper(name), *arguments)
    end

    def namespaced_route_helper(name)
      namespace = controller_path.split("/")[0...-1]
      return name if namespace.empty?

      prefix, route_name = name.match(/\A(new|edit|action|bulk_action|lookup_field)_(.+)\z/)&.captures || [ nil, name ]
      [ prefix, namespace.join("_"), route_name ].compact.join("_")
    end

    def render_resource_template(name, status: :ok)
      if lookup_context.exists?(name.to_s, [ controller_path ], false)
        render name, status: status
      else
        render template: "krudmin_ai/resources/#{name}", status: status
      end
    end
  end
end
