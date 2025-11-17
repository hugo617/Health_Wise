class ApplicationController < ActionController::Base
  # 全局登录拦截
  before_action :require_login

  # 对于 multipart/form-data 请求（文件上传），跳过 CSRF 验证
  skip_before_action :verify_authenticity_token, if: :multipart_request?

  helper_method :show_sidenav?, :current_user, :logged_in?, :admin?

  def show_sidenav?
    # 只在特定的控制器和动作中显示侧边栏
    (controller_name == 'users' && action_name == 'index') ||
    (controller_name == 'projects' && action_name.in?(%w[index show]))
  end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  # 检查是否是 multipart/form-data 请求（文件上传）
  def multipart_request?
    request.content_type&.start_with?('multipart/form-data')
  end

  # 获取当前登录用户
  def current_user
    @current_user ||= User.find_by(id: session[:user_id], deleted_at: nil) if session[:user_id]
  end

  # 检查是否已登录
  def logged_in?
    current_user.present?
  end

  # 检查是否是管理员
  def admin?
    logged_in? && current_user.role == 'admin'
  end

  # 要求用户登录
  def require_login
    unless logged_in?
      Rails.logger.info "未登录用户尝试访问: #{request.path}"
      redirect_to login_path, alert: "请先登录"
    end
  end

  # 要求管理员权限
  def require_admin
    unless admin?
      Rails.logger.warn "非管理员用户尝试访问管理功能: #{current_user&.phone_number} -> #{request.path}"
      redirect_to health_reports_path, alert: "权限不足，仅管理员可访问"
    end
  end

  # 检查用户是否有权限访问指定路由
  def check_user_permission
    return if admin? # 管理员可以访问所有路由

    # 普通用户只能访问健康档案相关路由
    allowed_paths = [
      health_reports_path,
      '/health_reports',
      '/health_reports/update_profile',
      '/health_reports/upload_avatar'
    ]

    # 检查当前路径是否在允许列表中
    unless allowed_paths.any? { |path| request.path.start_with?(path) }
      Rails.logger.warn "普通用户尝试访问受限路由: #{current_user.phone_number} -> #{request.path}"
      redirect_to health_reports_path, alert: "您没有权限访问该页面"
    end
  end
end