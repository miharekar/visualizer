class ShotPolicy < ApplicationPolicy
  def owner_or_admin?
    user.id == record.user_id || user.admin?
  end

  def index?
    true
  end

  def show?
    true
  end

  def compare?
    owner_or_admin?
  end

  def create?
    owner_or_admin?
  end

  def update?
    owner_or_admin?
  end

  def destroy?
    owner_or_admin?
  end
end
