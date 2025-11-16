require 'aliyun/sms'

# 发送短信验证码服务
class SendSmsService
  # 验证码有效期（秒）
  CODE_EXPIRY = 300 # 5分钟

  # 发送间隔限制（秒）
  SEND_INTERVAL = 60 # 60秒

  # 每小时发送次数限制
  HOURLY_LIMIT = 5

  # @param params [Hash] 包含 :phone_number
  # @return [Hash] { success: 布尔值, data: 结果数据, error: 错误信息 }
  def self.call(params)
    new(params).execute
  end

  def initialize(params)
    @phone_number = params[:phone_number]
  end

  # @return [Hash]
  def execute
    # 参数校验
    return error(:invalid_params, "手机号不能为空") if @phone_number.blank?
    return error(:invalid_params, "手机号格式不正确") unless valid_phone?(@phone_number)

    # 检查发送频率限制
    rate_limit_result = check_rate_limit
    return rate_limit_result unless rate_limit_result[:success]

    # 生成6位数字验证码
    code = generate_code

    # 发送短信
    send_result = send_sms_via_aliyun(code)
    return send_result unless send_result[:success]

    # 存储验证码到 Redis
    store_code(code)

    # 记录发送次数
    record_send_attempt

    success(data: { message: "验证码已发送", phone_number: @phone_number })
  rescue => e
    Rails.logger.error "SendSmsService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    error(:server_error, "发送验证码失败，请稍后重试")
  end

  private

  # 校验手机号格式
  def valid_phone?(phone)
    /^1[3-9]\d{9}$/.match?(phone.to_s)
  end

  # 生成6位数字验证码
  def generate_code
    rand(100000..999999).to_s
  end

  # 检查发送频率限制
  def check_rate_limit
    # 检查60秒内是否已发送
    last_send_key = "sms:last_send:#{@phone_number}"
    last_send_time = REDIS.get(last_send_key)

    if last_send_time
      elapsed = Time.now.to_i - last_send_time.to_i
      if elapsed < SEND_INTERVAL
        remaining = SEND_INTERVAL - elapsed
        return error(:rate_limit, "请#{remaining}秒后再试")
      end
    end

    # 检查每小时发送次数
    hourly_key = "sms:hourly:#{@phone_number}:#{Time.now.strftime('%Y%m%d%H')}"
    send_count = REDIS.get(hourly_key).to_i

    if send_count >= HOURLY_LIMIT
      return error(:rate_limit, "发送次数过多，请稍后再试")
    end

    success(data: {})
  end

  # 通过阿里云发送短信
  def send_sms_via_aliyun(code)
    # 如果配置为不使用真实短信，则模拟发送
    unless ENV['USE_REAL_SMS'] == 'true'
      Rails.logger.info "模拟发送短信验证码: #{code} 到 #{@phone_number}"
      return success(data: { code: code })
    end

    # 配置阿里云 SMS 客户端
    Aliyun::Sms.configure do |config|
      config.access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
      config.access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
      config.action = 'SendSms'
      config.format = 'JSON'
      config.region_id = 'cn-hangzhou'
      config.sign_name = ENV['ALIYUN_SMS_SIGN_NAME']
      config.signature_method = 'HMAC-SHA1'
      config.signature_version = '1.0'
      config.version = '2017-05-25'
    end

    # 发送短信，模板参数需要转换为 JSON 字符串
    template_param = { code: code }.to_json

    response = Aliyun::Sms.send(
      @phone_number,
      ENV['ALIYUN_SMS_TEMPLATE_CODE'],
      template_param
    )

    Rails.logger.info "阿里云短信发送响应: #{response.inspect}"

    # 解析响应体（response 是 Typhoeus::Response 对象）
    response_body = JSON.parse(response.body)
    Rails.logger.info "阿里云短信响应解析: #{response_body.inspect}"

    if response_body['Code'] == 'OK'
      Rails.logger.info "短信发送成功: BizId=#{response_body['BizId']}"
      success(data: { message: "短信发送成功" })
    else
      error_msg = response_body['Message'] || '未知错误'
      Rails.logger.error "阿里云短信发送失败: #{error_msg}"
      error(:sms_send_failed, "短信发送失败: #{error_msg}")
    end
  rescue => e
    Rails.logger.error "阿里云短信发送异常: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    error(:sms_send_failed, "短信发送失败")
  end

  # 存储验证码到 Redis
  def store_code(code)
    key = "sms:code:#{@phone_number}"
    REDIS.setex(key, CODE_EXPIRY, code)
    Rails.logger.info "验证码已存储: #{@phone_number} (有效期#{CODE_EXPIRY}秒)"
  end

  # 记录发送尝试
  def record_send_attempt
    # 记录最后发送时间
    last_send_key = "sms:last_send:#{@phone_number}"
    REDIS.setex(last_send_key, SEND_INTERVAL, Time.now.to_i)

    # 记录每小时发送次数
    hourly_key = "sms:hourly:#{@phone_number}:#{Time.now.strftime('%Y%m%d%H')}"
    REDIS.incr(hourly_key)
    REDIS.expire(hourly_key, 3600) # 1小时过期
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

