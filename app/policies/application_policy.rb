class ApplicationPolicy < ActionPolicy::Base
  authorize :user, allow_nil: true

  def owner?
    user && record.user_id == user.id
  end
end
