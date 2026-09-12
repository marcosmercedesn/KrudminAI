module KrudminAI
  QueryResult = Data.define(:records, :page, :per_page)

  class QueryAccessPipeline
    def initialize(resource:, context:, params: {}, authorization_provider: nil)
      @resource = resource
      @context = context
      @params = params
      @authorization_provider = authorization_provider
    end

    def call(relation)
      paginate(apply_sort(authorized_relation(relation)))
    end

    def authorized_relation(relation)
      context.validate!
      resource.validate_query_contract!

      tenant_scoped = apply_scope(resource.tenant_scope_handler, relation, ScopeViolation, "Tenant scope")
      policy_scoped = apply_scope(resource.policy_scope_handler, tenant_scoped, AuthorizationDenied, "Policy scope")
      policy_scoped = apply_provider_scope(policy_scoped)
      apply_filters(apply_eager_loading(apply_archive_visibility(policy_scoped)))
    end

    private

    attr_reader :resource, :context, :params, :authorization_provider

    def apply_scope(handler, relation, error_class, name)
      handler.call(relation, context) || raise(error_class, "#{name} denied access")
    end

    def apply_provider_scope(relation)
      return relation unless authorization_provider

      authorization_provider.scope(relation: relation, resource: resource, context: context) ||
        raise(AuthorizationDenied, "Authorization provider denied access")
    rescue StandardError
      raise AuthorizationDenied, "Authorization provider denied access"
    end

    def apply_eager_loading(relation)
      relation = relation.includes(*resource.included_associations) if resource.included_associations.any?
      relation = relation.preload(*resource.preloaded_associations) if resource.preloaded_associations.any?
      relation
    end

    def apply_archive_visibility(relation)
      return relation unless resource.archivable?

      case requested_archive_state
      when :active then relation.where(resource.archive_attribute => nil)
      when :archived then relation.where.not(resource.archive_attribute => nil)
      else relation
      end
    end

    def requested_archive_state
      value = params[:archive] || params["archive"]
      return :active if value.nil?

      %w[active archived all].include?(value) ? value.to_sym : :active
    end

    def apply_filters(relation)
      filter_params.reduce(relation) do |scoped_relation, (name, value)|
        handler = resource.filters[name.to_sym]
        next scoped_relation unless handler

        handler.call(scoped_relation, value, context)
      end
    end

    def apply_sort(relation)
      sort = requested_sort || resource.default_sort
      relation.order(sort[:attribute] => sort[:direction])
    end

    def paginate(relation)
      options = resource.pagination_options
      page = positive_integer(params[:page], fallback: 1)
      per_page = [positive_integer(params[:per_page], fallback: options[:per_page]), options[:max_per_page]].min
      QueryResult.new(relation.limit(per_page).offset((page - 1) * per_page), page, per_page)
    end

    def filter_params
      params.fetch(:filters, params.fetch("filters", {})) || {}
    end

    def requested_sort
      value = params[:sort] || params["sort"]
      return unless value.is_a?(String)

      attribute, direction = value.split(":", 2)
      return unless resource.sortable_attributes.include?(attribute&.to_sym)
      return unless %w[asc desc].include?(direction)

      { attribute: attribute.to_sym, direction: direction.to_sym }
    end

    def positive_integer(value, fallback:)
      integer = Integer(value, exception: false)
      integer && integer.positive? ? integer : fallback
    end
  end
end