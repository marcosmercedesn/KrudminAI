module KrudminAI
  class ResourceController < ActionController::Base
    helper KrudminAI::IconHelper
    class_attribute :resource_class, instance_accessor: false
    layout "krudmin_ai/application"

    helper_method :model, :models, :resource, :resource_path, :new_resource_path, :edit_resource_path,
            :collection_path, :resource_label, :resources_label, :current_user, :current_tenant,
          :signed_in?, :navigation_items, :authorized_action?, :field_readable?, :field_writable?,
          :readable_fields, :readable_relationship_fields, :relationship_field_writable?, :resource_actions,
            :resource_action_path, :pagination_path

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

    def resource_label
      resource.label || resource.model_class.model_name.human
    end

    def resources_label
      resource.plural_label || resource.model_class.model_name.human(count: 2)
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

    def relationship_field_writable?(relationship, field, record)
      relationship.field_writable?(field, record, access_context)
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
      render template:, formats: [:turbo_stream], status: response.status
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

    def query_params
      params.permit(:page, :per_page, :sort, :archive, filters: resource.filters.keys).to_h
    end

    def permitted_attributes
      params.fetch(resource.model_class.model_name.param_key, {}).permit(
        *resource.permitted_attributes,
        *resource.nested_permitted_attributes
      )
    end

    def serialize_json_record(record)
      return unless record

      readable_fields(resource.show, record).to_h { |field| [field, record.public_send(field)] }
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

      prefix, route_name = name.match(/\A(new|edit|action)_(.+)\z/)&.captures || [nil, name]
      [prefix, namespace.join("_"), route_name].compact.join("_")
    end

    def render_resource_template(name, status: :ok)
      if lookup_context.exists?(name.to_s, [controller_path], false)
        render name, status: status
      else
        render template: "krudmin_ai/resources/#{name}", status: status
      end
    end
  end
end