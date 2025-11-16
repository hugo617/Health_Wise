class Users::UpdateUserService
  def self.call(user_id, params)
    new(user_id, params).execute
  end

  def initialize(user_id, params)
    @user_id = user_id
    @params = params
  end

  def execute
    # 查找用户
    user = User.find_by(id: @user_id, deleted_at: nil)
    return { success: false, error: "用户不存在" } unless user

    # 参数验证
    validation_result = validate_params(user)
    return validation_result unless validation_result[:success]

    # 更新用户
    if user.update(update_params)
      Rails.logger.info "用户更新成功: #{user.phone_number} (ID: #{user.id})"
      { success: true, data: { user: user }, error: nil }
    else
      error_message = user.errors.full_messages.join(', ')
      Rails.logger.error "用户更新失败: #{error_message}"
      { success: false, data: nil, error: error_message }
    end
  rescue StandardError => e
    Rails.logger.error "用户更新异常: #{e.message}"
    { success: false, data: nil, error: e.message }
  end

  private

  def validate_params(user)
    # 验证邮箱格式和唯一性（如果更新邮箱）
    if @params[:email].present?
      unless valid_email?(@params[:email])
        return { success: false, error: "邮箱格式不正确" }
      end

      # 检查邮箱唯一性（排除当前用户和软删除用户）
      if User.where(email: @params[:email])
             .where.not(id: user.id, deleted_at: nil)
             .exists?
        return { success: false, error: "邮箱已存在" }
      end
    end

    # 验证密码长度（如果更新密码）
    if @params[:password].present? && @params[:password].length < 6
      return { success: false, error: "密码长度至少为6位" }
    end

    # 验证角色值
    if @params[:role].present? && !%w[admin user].include?(@params[:role])
      return { success: false, error: "角色只能是 admin 或 user" }
    end

    # 验证状态值
    if @params[:status].present? && !%w[active inactive suspended].include?(@params[:status])
      return { success: false, error: "状态只能是 active、inactive 或 suspended" }
    end

    # 验证会员类型
    if @params[:membership_type].present? && !%w[次卡会员 月卡会员 年卡会员 其他会员类别].include?(@params[:membership_type])
      return { success: false, error: "会员类型不正确" }
    end

    { success: true }
  end

  def update_params
    # 手机号不允许修改
    allowed_params = [:email, :nickname, :password, :role, :status, :membership_type, :avatar_path]
    @params.slice(*allowed_params).compact
  end

  def valid_email?(email)
    email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end
end