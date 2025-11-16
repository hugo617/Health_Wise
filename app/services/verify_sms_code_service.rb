# 验证短信验证码服务
# 遵循 rails.md 规范：控制器与服务层分离
class VerifySmsCodeService
  # @param params [Hash] 包含 :phone_number, :code
  # @return [Hash] { success: 布尔值, data: 结果数据, error: 错误信息 }
  def self.call(params)
    new(params).execute
  end

  def initialize(params)
    @phone_number = params[:phone_number]
    @code = params[:code]
  end

  # @return [Hash]
  def execute
    # 参数校验
    return error(:invalid_params, "手机号不能为空") if @phone_number.blank?
    return error(:invalid_params, "验证码不能为空") if @code.blank?
    return error(:invalid_params, "手机号格式不正确") unless valid_phone?(@phone_number)
    return error(:invalid_params, "验证码应为6位数字") unless valid_code_format?(@code)

    # 从 Redis 获取存储的验证码
    stored_code = get_stored_code

    # 验证码不存在或已过期
    if stored_code.nil?
      return error(:code_expired, "验证码已过期或不存在")
    end

    # 验证码不匹配
    if stored_code != @code
      return error(:code_invalid, "验证码错误")
    end

    # 验证成功，删除验证码（一次性使用）
    delete_code

    # 查找或创建用户
    user = find_or_create_user

    if user
      success(data: { user: serialize_user(user), message: "登录成功" })
    else
      error(:user_creation_failed, "用户创建失败")
    end
  rescue => e
    Rails.logger.error "VerifySmsCodeService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    error(:server_error, "验证失败，请稍后重试")
  end

  private

  # 校验手机号格式
  def valid_phone?(phone)
    /^1[3-9]\d{9}$/.match?(phone.to_s)
  end

  # 校验验证码格式
  def valid_code_format?(code)
    /^\d{6}$/.match?(code.to_s)
  end

  # 从 Redis 获取存储的验证码
  def get_stored_code
    key = "sms:code:#{@phone_number}"
    REDIS.get(key)
  end

  # 删除验证码（一次性使用）
  def delete_code
    key = "sms:code:#{@phone_number}"
    REDIS.del(key)
    Rails.logger.info "验证码已使用并删除: #{@phone_number}"
  end

  # 查找或创建用户
  def find_or_create_user
    user = User.find_by(phone_number: @phone_number, deleted_at: nil)

    # 如果用户不存在，自动注册
    unless user
      user = User.new(
        phone_number: @phone_number,
        email: "#{@phone_number}@temp.com", # 临时邮箱
        nickname: "用户#{@phone_number[-4..-1]}", # 使用手机号后4位作为昵称
        membership_type: "次卡会员",
        status: "active",
        role: "user",
        password: SecureRandom.hex(16) # 随机密码
      )

      if user.save
        Rails.logger.info "新用户自动注册成功: #{@phone_number}"
      else
        Rails.logger.error "用户创建失败: #{user.errors.full_messages.join(', ')}"
        return nil
      end
    end

    user
  end

  # 序列化用户信息
  def serialize_user(user)
    {
      id: user.id,
      phone_number: user.phone_number,
      nickname: user.nickname,
      membership_type: user.membership_type,
      status: user.status,
      role: user.role
    }
  end

  # 成功响应
  def success(data:)
    { success: true, data: data }
  end

  # 错误响应
  def error(code, message)
    { success: false, error: { code: code, message: message } }
  end
end

