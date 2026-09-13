class DemoTicketPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def create?
    user.present?
  end

  def update?
    same_tenant? && (user.manager? || record.assignee == user.name)
  end

  def destroy?
    same_tenant? && user.manager?
  end

  def restore?
    same_tenant? && user.manager?
  end

  def assign_to_me?
    same_tenant?
  end

  def resolve?
    same_tenant? && user.manager?
  end

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
    user.present? && record.tenant == user.tenant
  end
end
