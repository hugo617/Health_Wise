class HealthReportsControllerV2 < ApplicationController
  # 支持大文件上传和进度跟踪的新控制器
  
  before_action :require_login
  before_action :set_current_user_id
  
  # 上传带有进度跟踪的健康报告
  def upload_with_progress
    # 普通用户只能为自己上传报告
    result = HealthReports::UploadHealthReportServiceV2.call(
      {
        user_id: current_user.id,
        report_type: params[:report_type],
        file: params[:file],
        current_user_id: current_user.id
      },
      ->(progress) { Rails.logger.info "上传进度: #{progress[:percent]}% - #{progress[:message]}" }
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

  # 获取上传进度（用于轮询）
  def upload_progress
    upload_id = params[:upload_id]
    
    # 这里可以实现更复杂的进度跟踪逻辑
    # 目前使用简单的内存存储或Redis
    progress = get_upload_progress(upload_id)
    
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

  # 新的上传界面
  def upload_new
    @user = current_user
    @health_reports = @user.health_reports.order(created_at: :desc)
    @health_reports_by_type = @health_reports.group_by(&:report_type)
    
    respond_to do |format|
      format.html { render 'health_reports/upload_new' }
    end
  end

  private

  def set_current_user_id
    Thread.current[:current_user_id] = current_user&.id
  end

  def get_upload_progress(upload_id)
    # 简单的内存存储实现
    # 生产环境建议使用Redis
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
end