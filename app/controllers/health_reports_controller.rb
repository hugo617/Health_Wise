class HealthReportsController < ApplicationController
  # 已经在 ApplicationController 中有 require_login，这里不需要重复
  # 普通用户可以访问健康档案

  before_action :set_current_user_id, only: [:create, :update, :destroy]

  def index
    @user = current_user
    @health_reports = @user.health_reports.order(created_at: :desc)
    @health_reports_by_type = @health_reports.group_by(&:report_type)

    respond_to do |format|
      format.html
      format.json { 
        render json: {
          user: user_data,
          reports: reports_data
        }
      }
    end
  end

  def show
    # 用户只能查看自己的报告
    @health_report = current_user.health_reports.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: report_data(@health_report) }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html do
        redirect_to health_report_path, alert: "报告不存在或无权访问"
      end
      format.json do
        render json: { success: false, error: "报告不存在或无权访问" }, status: :not_found
      end
    end
  end

  def create
    result = HealthReports::CreateHealthReportService.call(create_params.merge(current_user_id: current_user&.id))
    
    if result[:success]
      render json: { 
        success: true, 
        message: '健康报告创建成功',
        report: report_data(result[:data][:health_report])
      }
    else
      render json: { 
        success: false, 
        error: result[:error] 
      }, status: :unprocessable_entity
    end
  end

  def update
    result = HealthReports::UpdateHealthReportService.call(params[:id], update_params)
    
    if result[:success]
      render json: { 
        success: true, 
        message: '健康报告更新成功',
        report: report_data(result[:data][:health_report])
      }
    else
      render json: { 
        success: false, 
        error: result[:error] 
      }, status: :unprocessable_entity
    end
  end

  def destroy
    result = HealthReports::DeleteHealthReportService.call(params[:id], current_user&.id)
    
    if result[:success]
      render json: { 
        success: true, 
        message: '健康报告删除成功'
      }
    else
      render json: { 
        success: false, 
        error: result[:error] 
      }, status: :unprocessable_entity
    end
  end

  def update_profile
    result = Users::UpdateUserProfileService.call(current_user, profile_params)
    
    if result[:success]
      # 更新成功后，重新获取用户数据
      @user = current_user
      render json: { 
        success: true, 
        message: '个人信息更新成功',
        user: user_data
      }
    else
      render json: { 
        success: false, 
        error: result[:error] 
      }, status: :unprocessable_entity
    end
  end

  def upload_avatar
    result = Users::UploadUserAvatarService.call(current_user, params[:avatar])

    if result[:success]
      render json: {
        success: true,
        message: '头像上传成功',
        avatar_url: result[:avatar_url]
      }
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  end

  def upload
    # 移动端上传增强日志
    Rails.logger.info "移动端上传请求开始: 用户ID=#{current_user.id}, 报告类型=#{params[:report_type]}"
    Rails.logger.info "请求头信息: Content-Type=#{request.content_type}, User-Agent=#{request.user_agent}"
    Rails.logger.info "请求参数: #{params.inspect[0..500]}..." # 限制日志长度
    
    # 移动端特殊处理
    if request.user_agent&.match?(/Mobile|Android|iPhone|iPad/i)
      Rails.logger.info "检测到移动端请求"
      
      # 检查必要的参数
      if params[:report_type].blank?
        Rails.logger.error "移动端上传失败: 缺少报告类型参数"
        return render json: {
          success: false,
          error: '请选择报告类型'
        }, status: :bad_request
      end
      
      if params[:file].blank?
        Rails.logger.error "移动端上传失败: 缺少文件参数"
        return render json: {
          success: false,
          error: '请选择要上传的文件'
        }, status: :bad_request
      end
    end
    
    # 普通用户只能为自己上传报告
    result = HealthReports::UploadHealthReportService.call(
      user_id: current_user.id,
      report_type: params[:report_type],
      file: params[:file],
      current_user_id: current_user.id
    )
    
    Rails.logger.info "上传服务执行完成: success=#{result[:success]}"

    if result[:success]
      Rails.logger.info "移动端上传成功: 报告ID=#{result[:data][:health_report]&.id}"
      render json: {
        success: true,
        message: result[:data][:message],
        report: report_data(result[:data][:health_report])
      }
    else
      Rails.logger.error "移动端上传失败: #{result[:error]}"
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
    
  rescue StandardError => e
    Rails.logger.error "移动端上传异常: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: {
      success: false,
      error: "上传失败: #{e.message}"
    }, status: :internal_server_error
  end

  def preview
    # 用户只能预览自己的报告
    @health_report = current_user.health_reports.find(params[:id])
    @user = current_user

    # 检查文件是否存在
    file_path = Rails.root.join('public', @health_report.report_path.sub(/^\//, ''))
    unless File.exist?(file_path)
      redirect_to health_report_path, alert: "报告文件不存在"
      return
    end

    # 获取文件大小
    @file_size = File.size(file_path)

    respond_to do |format|
      format.html
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to health_report_path, alert: "报告不存在或无权访问"
  end

  def download
    # 用户只能下载自己的报告
    health_report = current_user.health_reports.find(params[:id])

    # 构建文件路径
    file_path = Rails.root.join('public', health_report.report_path.sub(/^\//, ''))

    unless File.exist?(file_path)
      respond_to do |format|
        format.html { redirect_to health_report_path, alert: "报告文件不存在" }
        format.json { render json: { success: false, error: "报告文件不存在" }, status: :not_found }
      end
      return
    end

    # 生成下载文件名
    date_str = health_report.created_at.strftime('%Y-%m-%d')
    filename = "#{health_report.report_type}_#{date_str}.pdf"

    # 使用 send_file 进行流式传输
    send_file file_path,
              filename: filename,
              type: 'application/pdf',
              disposition: 'attachment',
              stream: true,
              buffer_size: 4096 # 4KB 缓冲区，适合大文件
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to health_report_path, alert: "报告不存在或无权访问" }
      format.json { render json: { success: false, error: "报告不存在或无权访问" }, status: :not_found }
    end
  end

  # 新的上传界面（现代化UI）
  def upload_new
    @user = current_user
    @health_reports = @user.health_reports.order(created_at: :desc)
    @health_reports_by_type = @health_reports.group_by(&:report_type)
    
    respond_to do |format|
      format.html { render 'health_reports/upload_new' }
    end
  end

  # 带有进度跟踪的上传
  def upload_with_progress
    # 使用增强的上传服务
    result = HealthReports::UploadHealthReportServiceV2.call(
      {
        user_id: current_user.id,
        report_type: params[:report_type],
        file: params[:file],
        current_user_id: current_user.id
      },
      ->(progress) {
        # 这里可以集成WebSocket或Server-Sent Events发送进度
        Rails.logger.info "上传进度: #{progress[:percent]}% - #{progress[:message]}"
      }
    )

    if result[:success]
      render json: {
        success: true,
        message: result[:data][:message],
        report: report_data(result[:data][:health_report]),
        file_size: result[:data][:file_size]
      }
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "上传控制器异常: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: {
      success: false,
      error: "上传失败: #{e.message}"
    }, status: :internal_server_error
  end

  # 获取上传进度
  def upload_progress
    upload_id = params[:upload_id]
    
    # 这里可以实现更复杂的进度跟踪逻辑
    # 目前使用简单的内存存储或Redis
    $upload_progress ||= {}
    progress = $upload_progress[upload_id]
    
    if progress
      render json: {
        success: true,
        progress: progress
      }
    else
      render json: {
        success: false,
        error: '上传任务不存在'
      }, status: :not_found
    end
  end

  # 取消上传
  def cancel_upload
    upload_id = params[:upload_id]
    
    # 清理临时文件
    cleanup_upload_files(upload_id)
    
    # 清除进度记录
    clear_upload_progress(upload_id)
    
    render json: {
      success: true,
      message: '上传已取消'
    }
  end

  private

  def set_current_user_id
    Thread.current[:current_user_id] = current_user&.id
  end

  def create_params
    params.permit(:user_id, :report_type, :report_path, :report_icon_path)
  end

  def update_params
    params.permit(:report_type, :report_path, :report_icon_path)
  end

  def profile_params
    params.permit(:nickname, :phone_number, :email, :password)
  end

  def user_data
    user = @user || current_user
    {
      id: user.id,
      nickname: user.nickname,
      phone_number: user.phone_number,
      email: user.email,
      membership_type: user.membership_type,
      avatar_url: user.avatar_path || 'https://picsum.photos/seed/user-avatar/300/300.jpg'
    }
  end

  def reports_data
    @health_reports.map { |report| report_data(report) }
  end

  def report_data(report)
    {
      id: report.id,
      user_id: report.user_id,
      user_nickname: report.user.nickname,
      user_phone: report.user.phone_number,
      report_type: report.report_type,
      report_path: report.report_path,
      report_icon_path: report.report_icon_path,
      created_at: report.created_at.strftime('%Y-%m-%d %H:%M:%S'),
      updated_at: report.updated_at.strftime('%Y-%m-%d %H:%M:%S'),
      summary: generate_report_summary(report)
    }
  end

  def generate_report_summary(report)
    case report.report_type
    when '蛋白质检测报告'
      '蛋白质指标检查完成，结果正常'
    when '基因检查报告'
      '基因检测分析完成，风险较低'
    else
      '检查报告已生成'
    end
  end

  def get_upload_progress(upload_id)
    $upload_progress ||= {}
    $upload_progress[upload_id]
  end

  def set_upload_progress(upload_id, progress)
    $upload_progress ||= {}
    $upload_progress[upload_id] = progress
  end

  def clear_upload_progress(upload_id)
    $upload_progress ||= {}
    $upload_progress.delete(upload_id)
  end

  def cleanup_upload_files(upload_id)
    temp_dir = Rails.root.join('tmp', 'uploads')
    temp_pattern = temp_dir.join("#{upload_id}_*")
    
    Dir.glob(temp_pattern).each do |file|
      File.delete(file) if File.exist?(file)
      Rails.logger.info "清理取消上传的临时文件: #{file}"
    rescue StandardError => e
      Rails.logger.error "清理临时文件失败: #{e.message}"
    end
  end
end