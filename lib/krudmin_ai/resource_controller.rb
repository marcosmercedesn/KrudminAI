module KrudminAI
  class ResourceController < ActionController::Base
    helper KrudminAI::IconHelper
    class_attribute :resource_class, instance_accessor: false
    layout "krudmin_ai/application"

    helper_method :model, :models, :resource_path, :new_resource_path, :edit_resource_path,
                  :collection_path, :resource_label, :current_user, :current_tenant, :signed_in?,
                  :navigation_items

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
    end

    def show; end

    def new
      @model = resource.model_class.new
    end

    def create
      @model = resource.model_class.new(resource.tenant_attribute => access_context.tenant)
      persist(:create)
    end

    def edit; end

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
      resource.model_class.model_name.human
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
      provider = KrudminAI.config.authentication_provider
      provider.respond_to?(:call) ? provider.call(self) : nil
    end

    def current_tenant
      provider = KrudminAI.config.tenant_provider
      provider.respond_to?(:call) ? provider.call(self) : nil
    end

    def current_roles
      current_actor.respond_to?(:roles) ? current_actor.roles : []
    end

    def audit_sink
      provider = KrudminAI.config.audit_provider
      provider.respond_to?(:call) ? provider.call : provider
    end

    def sign_in_path
      main_app.new_session_path
    end

    def load_model
      @model = query_pipeline.authorized_relation(resource.model_class.all).find(params[:id])
    end

    def persist(operation)
      result = MutationPipeline.new(resource:, context: access_context, auditor: audit_sink)
        .call(operation:, record: model, attributes: permitted_attributes)

      if result.success?
        destination = operation == :destroy ? collection_path : resource_path(model)
        return redirect_to(destination, status: :see_other, notice: "#{resource_label} #{operation}d and audited.")
      end

      flash.now[:alert] = result.errors.map { |error| error[:detail] }.join(" ")
      render(operation == :create ? :new : :edit, status: result.outcome == :invalid ? :unprocessable_entity : :forbidden)
    end

    def query_pipeline
      QueryAccessPipeline.new(resource:, context: access_context, params: query_params)
    end

    def query_params
      params.permit(:page, :per_page, :sort, filters: resource.filters.keys).to_h
    end

    def permitted_attributes
      params.fetch(resource.model_class.model_name.param_key, {}).permit(*resource.permitted_attributes)
    end

    def route_key
      resource.route_key&.to_s || controller_name
    end

    def route_helper(name, *arguments)
      main_app.public_send(name, *arguments)
    end
  end
end