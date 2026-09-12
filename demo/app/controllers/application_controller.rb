class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  helper_method :current_user, :current_tenant, :signed_in?

  private

  def current_user
    @current_user ||= DemoUser.find_by(id: session[:demo_user_id])
  end

  def current_tenant
    current_user&.tenant
  end

  def signed_in?
    current_user.present?
  end

  def require_sign_in
    return if signed_in?

    redirect_to new_session_path, alert: "Sign in to view the admin workspace."
  end

  def access_context
    KrudminAI::AccessContext.new(actor: current_user, tenant: current_tenant, roles: current_user.roles)
  end

  def audit_sink
    DemoAuditSink.new
  end
end
