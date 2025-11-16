class HealthReports::DeleteHealthReportService
  def self.call(report_id, current_user_id = nil)
    new(report_id, current_user_id).execute
  end

  def initialize(report_id, current_user_id = nil)
    @report_id = report_id
    @current_user_id = current_user_id
  end

  def execute
    # 查找报告
    report = HealthReport.find_by(id: @report_id)
    return { success: false, error: "报告不存在" } unless report

    # 权限检查：用户只能删除自己的报告（除非是管理员）
    if @current_user_id.present?
      current_user = User.find_by(id: @current_user_id, deleted_at: nil)
      if current_user&.role == 'user' && report.user_id != current_user.id
        return { success: false, error: "只能删除自己的健康报告" }
      end
    end

    # 删除报告（硬删除，因为健康报告可能需要彻底删除）
    if report.destroy
      Rails.logger.info "健康报告删除成功: 报告ID #{@report_id}"
      { success: true, data: { health_report: report }, error: nil }
    else
      error_message = report.errors.full_messages.join(', ')
      Rails.logger.error "健康报告删除失败: #{error_message}"
      { success: false, data: nil, error: error_message }
    end
  rescue StandardError => e
    Rails.logger.error "健康报告删除异常: #{e.message}"
    { success: false, data: nil, error: e.message }
  end
end