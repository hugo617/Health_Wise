# SMS验证码基础服务
# 提供验证码生成、存储、验证等基础功能
class Authentication::SmsCodeBaseService
  # 验证码有效期（秒）
  CODE_EXPIRY = 300 # 5分钟

  # 发送间隔限制（秒）
  SEND_INTERVAL = 60 # 60秒

  # 每小时发送次数限制
  HOURLY_LIMIT = 5

  protected

  # 校验手机号格式
  def valid_phone?(phone)
    /^1[3-9]\d{9}$/.match?(phone.to_s)
  end

  # 生成6位数字验证码
  def generate_code
    rand(100000..999999).to_s
  end

  # 从 Redis 获取存储的验证码
  def get_stored_code(phone_number)
    key = "sms:code:#{phone_number}"
    REDIS.get(key)
  end

  # 存储验证码到 Redis
  def store_code(phone_number, code)
    key = "sms:code:#{phone_number}"
    REDIS.setex(key, CODE_EXPIRY, code)
    Rails.logger.info "验证码已存储: #{phone_number} (有效期#{CODE_EXPIRY}秒)"
  end

  # 删除验证码（一次性使用）
  def delete_code(phone_number)
    key = "sms:code:#{phone_number}"
    REDIS.del(key)
    Rails.logger.info "验证码已使用并删除: #{phone_number}"
  end

  # 检查发送频率限制
  def check_rate_limit(phone_number)
    # 检查60秒内是否已发送
    last_send_key = "sms:last_send:#{phone_number}"
    last_send_time = REDIS.get(last_send_key)

    if last_send_time
      elapsed = Time.now.to_i - last_send_time.to_i
      if elapsed < SEND_INTERVAL
        remaining = SEND_INTERVAL - elapsed
        return { success: false, error: "请#{remaining}秒后再试" }
      end
    end

    # 检查每小时发送次数
    hourly_key = "sms:hourly:#{phone_number}:#{Time.now.strftime('%Y%m%d%H')}"
    send_count = REDIS.get(hourly_key).to_i

    if send_count >= HOURLY_LIMIT
      return { success: false, error: "发送次数过多，请稍后再试" }
    end

    { success: true }
  end

  # 记录发送尝试
  def record_send_attempt(phone_number)
    # 记录最后发送时间
    last_send_key = "sms:last_send:#{phone_number}"
    REDIS.setex(last_send_key, SEND_INTERVAL, Time.now.to_i)

    # 记录每小时发送次数
    hourly_key = "sms:hourly:#{phone_number}:#{Time.now.strftime('%Y%m%d%H')}"
    REDIS.incr(hourly_key)
    REDIS.expire(hourly_key, 3600) # 1小时过期
  end

  # 成功响应
  def success(data: {})
    { success: true, data: data }
  end

  # 错误响应
  def error(message)
    { success: false, error: message }
  end
end