class HealthReports::MobileController < ApplicationController
  # 移动端专用的健康报告控制器
  # 处理移动端的上传请求，包含特殊的认证和错误处理
  
  skip_before_action :require_login, only: [:upload_guest, :test_upload]
  before_action :authenticate_mobile_user, except: [:upload_guest, :test_upload]
  before_action :log_mobile_request
  
  # 移动端上传（需要认证）
  def upload
    Rails.logger.info "移动端上传请求开始: 用户代理=#{request.user_agent}"
    Rails.logger.info "移动端请求头: Content-Type=#{request.content_type}, Content-Length=#{request.content_length}"
    Rails.logger.info "移动端参数: report_type=#{params[:report_type]}, file_present=#{params[:file].present?}"
    
    # 检查移动端特殊参数
    if params[:report_type].blank?
      Rails.logger.error "移动端上传失败: 缺少报告类型"
      return render json: {
        success: false,
        error: '请选择报告类型'
      }, status: :bad_request
    end
    
    if params[:file].blank?
      Rails.logger.error "移动端上传失败: 缺少文件"
      return render json: {
        success: false,
        error: '请选择要上传的文件'
      }, status: :bad_request
    end
    
    # 使用移动端优化的上传服务
    result = HealthReports::MobileUploadService.call({
      user_id: current_user.id,
      report_type: params[:report_type],
      file: params[:file],
      current_user_id: current_user.id
    })
    
    if result[:success]
      Rails.logger.info "移动端上传成功: 报告ID=#{result[:data][:health_report]&.id}"
      
      render json: {
        success: true,
        message: result[:data][:message],
        report: mobile_report_data(result[:data][:health_report]),
        file_size: result[:data][:file_size]
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
  
  # 移动端测试上传（无需认证）
  def test_upload
    Rails.logger.info "移动端测试上传开始"
    
    # 创建测试文件
    test_content = "移动端测试文件 - #{Time.current}"
    test_file = StringIO.new(test_content)
    test_file.class_eval do
      attr_accessor :original_filename, :content_type
    end
    test_file.original_filename = "mobile_test_#{Time.current.to_i}.pdf"
    test_file.content_type = 'application/pdf'
    
    result = HealthReports::MobileUploadService.call({
      user_id: 317, # 使用测试用户"陈"
      report_type: '基因检查报告',
      file: test_file,
      current_user_id: 317
    })
    
    if result[:success]
      render json: {
        success: true,
        message: '移动端测试上传成功',
        test_data: result[:data]
      }
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  end
  
  # 移动端上传状态检查
  def upload_status
    upload_id = params[:upload_id]
    
    # 这里可以实现上传进度查询
    # 目前返回简单的状态
    render json: {
      success: true,
      upload_id: upload_id,
      status: 'processing',
      message: '上传处理中'
    }
  end
  
  private
  
  def authenticate_mobile_user
    # 移动端特殊认证逻辑
    unless current_user
      Rails.logger.warn "移动端未认证用户尝试访问: #{request.user_agent}"
      
      render json: {
        success: false,
        error: '请先登录',
        login_required: true
      }, status: :unauthorized
    end
  end
  
  def log_mobile_request
    Rails.logger.info "移动端请求详情:"
    Rails.logger.info "  User-Agent: #{request.user_agent}"
    Rails.logger.info "  Remote-IP: #{request.remote_ip}"
    Rails.logger.info "  Content-Type: #{request.content_type}"
    Rails.logger.info "  Content-Length: #{request.content_length}"
    Rails.logger.info "  Accept: #{request.headers['Accept']}"
    Rails.logger.info "  Origin: #{request.headers['Origin']}"
    Rails.logger.info "  Referer: #{request.headers['Referer']}"
  end
  
  def mobile_report_data(report)
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
      summary: generate_report_summary(report),
      file_size: File.exist?(Rails.root.join('public', report.report_path.sub(/^\//, ''))) ? 
                 File.size(Rails.root.join('public', report.report_path.sub(/^\//, ''))) : 0
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
end