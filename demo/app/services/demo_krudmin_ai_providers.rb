class DemoAuthenticationProvider
  def authenticate(controller:)
    DemoUser.find_by(id: controller.session[:demo_user_id])
  end
end

class DemoTenantProvider
  def resolve(controller:, actor:)
    actor&.tenant
  end
end

class DemoAuthorizationProvider
  def scope(relation:, resource:, context:)
    relation
  end

  def authorize?(action:, record:, resource:, context:)
    true
  end
end

class DemoNotificationProvider
  def deliver(notification:)
    true
  end
end