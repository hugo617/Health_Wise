# 用户密码认证服务
# 遵循 rails.md 规范：服务层封装业务逻辑
class AuthenticateUserService
  # 统一入口方法
  def self.call(params)
    new(params).execute
  end

  def initialize(params)
    @phone_number = params[:phone_number]
    @password = params[:password]
  end

  def execute
    # 验证参数
    return error(:invalid_params, "手机号和密码不能为空") if @phone_number.blank? || @password.blank?

    # 验证手机号格式
    unless valid_phone_number?
      return error(:invalid_phone_number, "手机号格式不正确")
    end

    # 查找用户
    user = find_user
    return error(:user_not_found, "用户不存在") unless user

    # 检查用户状态
    return error(:user_inactive, "用户已被禁用") unless user.status == 'active'

    # 验证密码
    unless user.authenticate(@password)
      Rails.logger.warn "密码验证失败: #{@phone_number}"
      return error(:invalid_password, "密码错误")
    end

    # 记录登录日志
    Rails.logger.info "用户登录成功: #{@phone_number} (ID: #{user.id}, Role: #{user.role})"

    # 返回成功结果
    success(data: { user: user })
  end

  private

  # 验证手机号格式
  def valid_phone_number?
    @phone_number.match?(/^1[3-9]\d{9}$/)
  end

  # 查找用户
  def find_user
    User.find_by(phone_number: @phone_number, deleted_at: nil)
  end

  # 成功响应
  def success(data: {})
    {
      success: true,
      data: data
    }
  end

  # 错误响应
  def error(code, message)
    {
      success: false,
      error: message,
      error_code: code
    }
  end
end

