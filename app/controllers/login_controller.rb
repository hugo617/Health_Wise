# 登录控制器
# 遵循 rails.md 规范：控制器只负责接收请求、调用服务层、处理响应
class LoginController < ApplicationController
  # 跳过 CSRF 验证（用于 API 接口）
  skip_before_action :verify_authenticity_token, only: [:send_code, :verify_code]

  # 登录页面
  def index
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
      session[:user_id] = result[:data][:user][:id]
      session[:phone_number] = result[:data][:user][:phone_number]

      render json: {
        success: true,
        message: result[:data][:message],
        user: result[:data][:user]
      }, status: :ok
    else
      render json: { success: false, error: result[:error][:message] }, status: :unprocessable_entity
    end
  end
end
