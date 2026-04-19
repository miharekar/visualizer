class ShotPolicy < ApplicationPolicy
  alias_rule :edit?, :destroy?, :remove_image?, to: :update?
  alias_rule :show?, to: :index?

  def index?
    true
  end

  def create?
    owner?
  end

  def update?
    create?
  end
end
