class ShotPolicy < ApplicationPolicy
  def owner?
    user && user.id == record.user_id
  end

  def index?
    true
  end

  def show?
    true
  end

  def create?
    owner?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end
end
