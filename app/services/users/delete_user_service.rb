class Users::DeleteUserService
  def self.call(user_id)
    new(user_id).execute
  end

  def initialize(user_id)
    @user_id = user_id
  end

  def execute
    # 查找用户
    user = User.find_by(id: @user_id, deleted_at: nil)
    return { success: false, error: "用户不存在" } unless user

    # 检查是否是当前登录用户
    current_user_id = Thread.current[:current_user_id]
    if current_user_id && user.id == current_user_id
      return { success: false, error: "不能删除当前登录的用户" }
    end

    # 软删除用户
    if user.update(deleted_at: Time.current)
      Rails.logger.info "用户软删除成功: #{user.phone_number} (ID: #{user.id})"
      { success: true, data: { user: user }, error: nil }
    else
      error_message = user.errors.full_messages.join(', ')
      Rails.logger.error "用户软删除失败: #{error_message}"
      { success: false, data: nil, error: error_message }
    end
  rescue StandardError => e
    Rails.logger.error "用户软删除异常: #{e.message}"
    { success: false, data: nil, error: e.message }
  end
end