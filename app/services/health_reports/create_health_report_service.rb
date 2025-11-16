class HealthReports::CreateHealthReportService
  def self.call(params)
    new(params).execute
  end

  def initialize(params)
    @params = params
  end

  def execute
    # 参数验证
    validation_result = validate_params
    return validation_result unless validation_result[:success]

    # 创建健康报告
    report = HealthReport.new(report_params)
    
    if report.save
      Rails.logger.info "健康报告创建成功: 用户ID #{report.user_id}, 报告ID #{report.id}"
      { success: true, data: { health_report: report }, error: nil }
    else
      error_message = report.errors.full_messages.join(', ')
      Rails.logger.error "健康报告创建失败: #{error_message}"
      { success: false, data: nil, error: error_message }
    end
  rescue StandardError => e
    Rails.logger.error "健康报告创建异常: #{e.message}"
    { success: false, data: nil, error: e.message }
  end

  private

  def validate_params
    # 检查必填字段
    required_fields = [:user_id, :report_type, :report_path]
    missing_fields = required_fields.select { |field| @params[field].blank? }
    
    if missing_fields.any?
      return { success: false, error: "缺少必填字段: #{missing_fields.join(', ')}" }
    end

    # 验证用户存在且未被软删除
    user = User.find_by(id: @params[:user_id], deleted_at: nil)
    return { success: false, error: "用户不存在" } unless user

    # 验证报告类型
    unless %w[基因检查报告 蛋白质检测报告].include?(@params[:report_type])
      return { success: false, error: "报告类型不正确" }
    end

    # 验证报告路径
    if @params[:report_path].blank?
      return { success: false, error: "报告路径不能为空" }
    end

    # 验证用户报告类型唯一性
    if HealthReport.exists?(user_id: @params[:user_id], report_type: @params[:report_type])
      return { success: false, error: "该用户已存在相同类型的报告" }
    end

    { success: true }
  end

  def report_params
    {
      user_id: @params[:user_id],
      report_type: @params[:report_type],
      report_path: @params[:report_path],
      report_icon_path: @params[:report_icon_path]
    }
  end
end