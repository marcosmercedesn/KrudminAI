class DemoOperationsPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

  def create? = @user.present?
  def update? = same_tenant?
  def destroy? = same_tenant? && @user.manager?

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @user ? @scope.where(tenant: @user.tenant) : @scope.none
    end
  end

  private

  def same_tenant?
    @user.present? && @record.tenant == @user.tenant
  end
end
