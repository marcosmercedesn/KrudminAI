module KrudminAI
  class AuthenticationRequired < StandardError; end
  class TenantRequired < StandardError; end

  class AccessContext
    attr_reader :actor, :tenant, :roles

    def initialize(actor:, tenant:, roles: [])
      @actor = actor
      @tenant = tenant
      @roles = Array(roles).map(&:to_sym).uniq.freeze
    end

    def validate!
      raise AuthenticationRequired, "An authenticated actor is required" unless actor
      raise TenantRequired, "A tenant is required" unless tenant

      self
    end
  end
end