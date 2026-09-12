module KrudminAI
  class ResourceController < ActionController::Base
    helper KrudminAI::IconHelper
    class_attribute :resource_class, instance_accessor: false
    layout "krudmin_ai/application"

    helper_method :model, :models, :resource, :resource_path, :new_resource_path, :edit_resource_path,
            :collection_path, :resource_label, :resources_label, :current_user, :current_tenant,
          :signed_in?, :navigation_items, :authorized_action?

    before_action :authenticate_resource_request
    before_action :load_model, only: %i[show edit update destroy]

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
      persist(:destroy)
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
      @model = query_pipeline.authorized_relation(resource.model_class.all).find(params[:id])
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

      return render json: response.payload, status: response.status if response.format == :json
      return render_turbo_mutation(response, result, operation) if response.format == :turbo_stream

      render_html_mutation(response, result, operation)
    end

    def render_html_mutation(response, result, operation)
      if response.payload[:redirect]
        destination = operation == :destroy ? collection_path : resource_path(model)
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
        self.response.set_header("Turbo-Location", operation == :destroy ? collection_path : resource_path(model))
        flash.now[:notice] = "#{resource_label} #{operation}d and audited."
      else
        flash.now[:alert] = result.errors.map { |error| error[:detail] }.join(" ")
      end

      render template: response.payload[:template], formats: [:turbo_stream], status: response.status
    end

    def query_pipeline
      QueryAccessPipeline.new(
        resource:,
        context: access_context,
        params: query_params,
        authorization_provider: authorization_provider
      )
    end

    def authorization_provider
      KrudminAI.config.authorization_provider
    end

    def query_params
      params.permit(:page, :per_page, :sort, filters: resource.filters.keys).to_h
    end

    def permitted_attributes
      params.fetch(resource.model_class.model_name.param_key, {}).permit(
        *resource.permitted_attributes,
        *resource.nested_permitted_attributes
      )
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

      "#{namespace.join("_")}_#{name}"
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