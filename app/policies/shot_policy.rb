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
  alias :update? :create?
  alias :remove_image? :create?
  alias :destroy? :create?
end
