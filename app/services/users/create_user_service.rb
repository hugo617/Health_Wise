class Users::CreateUserService
  def self.call(params)
    new(params).execute
  end

  def initialize(params)
    @params = params
  end

  def execute
    # 参数验证
    validation_result = validate_params
    return validation_result unless validation_result[:success]

    # 创建用户
    user = User.new(user_params)
    
    if user.save
      Rails.logger.info "用户创建成功: #{user.phone_number} (ID: #{user.id})"
      { success: true, data: { user: user }, error: nil }
    else
      error_message = user.errors.full_messages.join(', ')
      Rails.logger.error "用户创建失败: #{error_message}"
      { success: false, data: nil, error: error_message }
    end
  rescue StandardError => e
    Rails.logger.error "用户创建异常: #{e.message}"
    { success: false, data: nil, error: e.message }
  end

  private

  def validate_params
    # 检查必填字段
    required_fields = [:phone_number, :email, :nickname, :password]
    missing_fields = required_fields.select { |field| @params[field].blank? }
    
    if missing_fields.any?
      return { success: false, error: "缺少必填字段: #{missing_fields.join(', ')}" }
    end

    # 验证手机号格式
    unless valid_phone_number?(@params[:phone_number])
      return { success: false, error: "手机号格式不正确" }
    end

    # 验证手机号唯一性（排除软删除用户）
    if User.exists?(phone_number: @params[:phone_number], deleted_at: nil)
      return { success: false, error: "手机号已存在" }
    end

    # 验证邮箱格式
    unless valid_email?(@params[:email])
      return { success: false, error: "邮箱格式不正确" }
    end

    # 验证邮箱唯一性（排除软删除用户）
    if User.exists?(email: @params[:email], deleted_at: nil)
      return { success: false, error: "邮箱已存在" }
    end

    # 验证密码长度
    if @params[:password].length < 6
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

    { success: true }
  end

  def user_params
    {
      phone_number: @params[:phone_number],
      email: @params[:email],
      nickname: @params[:nickname],
      password: @params[:password],
      role: @params[:role] || 'user',
      status: @params[:status] || 'active',
      membership_type: @params[:membership_type] || '次卡会员'
    }
  end

  def valid_phone_number?(phone)
    phone.match?(/^1[3-9]\d{9}$/)
  end

  def valid_email?(email)
    email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end
end