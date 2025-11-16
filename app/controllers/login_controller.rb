# 登录控制器
# 遵循 rails.md 规范：控制器只负责接收请求、调用服务层、处理响应
class LoginController < ApplicationController
  # 跳过登录验证（登录页面本身不需要登录）
  skip_before_action :require_login

  # 跳过 CSRF 验证（用于 API 接口）
  skip_before_action :verify_authenticity_token, only: [:send_code, :verify_code, :authenticate]

  # 登录页面
  def index
    # 如果已登录，重定向到健康档案页面
    redirect_to health_reports_path if logged_in?
  end

  # 发送短信验证码
  # POST /login/send_code
  def send_code
    phone_number = params[:phone_number]

    # 调用服务层
    result = SendSmsService.call(phone_number: phone_number)

    # 根据服务层返回结果处理响应
    if result[:success]
      render json: { success: true, message: result[:data][:message] }, status: :ok
    else
      render json: { success: false, error: result[:error][:message] }, status: :unprocessable_entity
    end
  end

  # 验证短信验证码并登录
  # POST /login/verify_code
  def verify_code
    phone_number = params[:phone_number]
    code = params[:code]

    # 调用服务层
    result = VerifySmsCodeService.call(phone_number: phone_number, code: code)

    # 根据服务层返回结果处理响应
    if result[:success]
      # 设置 session（登录成功）
      user = result[:data][:user]
      session[:user_id] = user[:id]
      session[:phone_number] = user[:phone_number]

      Rails.logger.info "用户通过短信验证码登录成功: #{user[:phone_number]} (ID: #{user[:id]})"

      render json: {
        success: true,
        message: result[:data][:message],
        user: user
      }, status: :ok
    else
      render json: { success: false, error: result[:error][:message] }, status: :unprocessable_entity
    end
  end

  # 手机号密码登录
  # POST /login/authenticate
  def authenticate
    phone_number = params[:phone_number]
    password = params[:password]

    # 调用服务层
    result = AuthenticateUserService.call(phone_number: phone_number, password: password)

    # 根据服务层返回结果处理响应
    if result[:success]
      # 设置 session（登录成功）
      user = result[:data][:user]
      session[:user_id] = user.id
      session[:phone_number] = user.phone_number

      render json: {
        success: true,
        message: "登录成功",
        user: {
          id: user.id,
          phone_number: user.phone_number,
          nickname: user.nickname,
          email: user.email,
          role: user.role,
          membership_type: user.membership_type,
          status: user.status
        }
      }, status: :ok
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  # 登出
  # DELETE /login/logout
  def logout
    user_phone = session[:phone_number]
    session.delete(:user_id)
    session.delete(:phone_number)
    reset_session

    Rails.logger.info "用户登出: #{user_phone}"

    redirect_to login_path, notice: "已成功登出"
  end
end
