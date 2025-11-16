class HealthReports::SearchHealthReportsService
  def self.call(params)
    new(params).execute
  end

  def initialize(params)
    @params = params
  end

  def execute
    begin
      # 构建查询
      reports = build_query
      
      # 获取总数
      total = reports.count
      
      # 分页
      page = (@params[:page] || 1).to_i
      per_page = [(@params[:per_page] || 10).to_i, 50].min # 最大50条每页
      
      # 手动分页
      offset = (page - 1) * per_page
      reports = reports.limit(per_page).offset(offset)
      
      # 计算总页数
      total_pages = (total.to_f / per_page).ceil
      
      Rails.logger.info "健康报告搜索完成: 共#{total}条记录，第#{page}页，每页#{per_page}条"
      
      {
        success: true,
        data: {
          health_reports: reports,
          total: total,
          page: page,
          per_page: per_page,
          total_pages: total_pages
        },
        error: nil
      }
    rescue StandardError => e
      Rails.logger.error "健康报告搜索异常: #{e.message}"
      { success: false, data: nil, error: e.message }
    end
  end

  private

  def build_query
    # 基础查询：排除软删除的报告
    reports = HealthReport.joins(:user).where(users: { deleted_at: nil })
    
    # 权限控制：普通用户只能查看自己的报告
    if @params[:current_user_id].present?
      current_user = User.find_by(id: @params[:current_user_id], deleted_at: nil)
      if current_user&.role == 'user'
        reports = reports.where(user_id: current_user.id)
      end
    end
    
    # 用户筛选（仅管理员可用）
    if @params[:user_id].present?
      reports = reports.where(user_id: @params[:user_id])
    end
    
    # 关键字搜索（在报告类型、用户昵称、手机号中模糊匹配）
    if @params[:search].present?
      search_term = "%#{@params[:search]}%"
      reports = reports.where(
        "health_reports.report_type LIKE :search OR users.nickname LIKE :search OR users.phone_number LIKE :search",
        search: search_term
      )
    end
    
    # 报告类型筛选
    if @params[:report_type].present? && %w[基因检查报告 蛋白质检测报告].include?(@params[:report_type])
      reports = reports.where(report_type: @params[:report_type])
    end
    
    # 排序
    sort_field = @params[:sort] || 'created_at'
    order_direction = @params[:order] || 'desc'
    
    # 只允许特定的排序字段
    allowed_sort_fields = %w[created_at updated_at id]
    if allowed_sort_fields.include?(sort_field)
      reports = reports.order("health_reports.#{sort_field} #{order_direction}")
    else
      reports = reports.order(created_at: :desc)
    end
    
    reports
  end
end