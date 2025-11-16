class HealthReports::UpdateHealthReportService
  def self.call(report_id, params)
    new(report_id, params).execute
  end

  def initialize(report_id, params)
    @report_id = report_id
    @params = params
  end

  def execute
    # 查找报告
    report = HealthReport.find_by(id: @report_id)
    return { success: false, error: "报告不存在" } unless report

    # 参数验证
    validation_result = validate_params(report)
    return validation_result unless validation_result[:success]

    # 更新报告
    if report.update(update_params)
      Rails.logger.info "健康报告更新成功: 报告ID #{report.id}"
      { success: true, data: { health_report: report }, error: nil }
    else
      error_message = report.errors.full_messages.join(', ')
      Rails.logger.error "健康报告更新失败: #{error_message}"
      { success: false, data: nil, error: error_message }
    end
  rescue StandardError => e
    Rails.logger.error "健康报告更新异常: #{e.message}"
    { success: false, data: nil, error: e.message }
  end

  private

  def validate_params(report)
    # 验证报告类型（如果更新）
    if @params[:report_type].present? && !%w[基因检查报告 蛋白质检测报告].include?(@params[:report_type])
      return { success: false, error: "报告类型不正确" }
    end

    # 验证报告路径（如果更新）
    if @params[:report_path].present? && @params[:report_path].blank?
      return { success: false, error: "报告路径不能为空" }
    end

    # 验证用户报告类型唯一性（如果更新用户或报告类型）
    if @params[:user_id].present? || @params[:report_type].present?
      user_id = @params[:user_id] || report.user_id
      report_type = @params[:report_type] || report.report_type
      
      if HealthReport.where(user_id: user_id, report_type: report_type)
                     .where.not(id: report.id)
                     .exists?
        return { success: false, error: "该用户已存在相同类型的报告" }
      end
    end

    { success: true }
  end

  def update_params
    allowed_params = [:report_type, :report_path, :report_icon_path]
    @params.slice(*allowed_params).compact
  end
end