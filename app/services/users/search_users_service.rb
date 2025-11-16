class Users::SearchUsersService
  def self.call(params)
    new(params).execute
  end

  def initialize(params)
    @params = params
  end

  def execute
    begin
      # 构建查询
      users = build_query
      
      # 获取总数
      total = users.count
      
      # 分页
      page = (@params[:page] || 1).to_i
      per_page = [(@params[:per_page] || 10).to_i, 50].min # 最大50条每页
      
      # 手动分页（不使用kaminari/will_paginate）
      offset = (page - 1) * per_page
      total = users.count
      users = users.limit(per_page).offset(offset)
      
      # 计算总页数
      total_pages = (total.to_f / per_page).ceil
      
      Rails.logger.info "用户搜索完成: 共#{total}条记录，第#{page}页，每页#{per_page}条"
      
      {
        success: true,
        data: {
          users: users,
          total: total,
          page: page,
          per_page: per_page,
          total_pages: total_pages
        },
        error: nil
      }
    rescue StandardError => e
      Rails.logger.error "用户搜索异常: #{e.message}"
      { success: false, data: nil, error: e.message }
    end
  end

  private

  def build_query
    # 基础查询：排除软删除的用户
    users = User.where(deleted_at: nil)
    
    # 关键字搜索（在手机号、昵称、邮箱中模糊匹配）
    if @params[:search].present?
      search_term = "%#{@params[:search]}%"
      users = users.where(
        "phone_number LIKE :search OR nickname LIKE :search OR email LIKE :search",
        search: search_term
      )
    end
    
    # 角色筛选
    if @params[:role].present? && %w[admin user].include?(@params[:role])
      users = users.where(role: @params[:role])
    end
    
    # 状态筛选
    if @params[:status].present? && %w[active inactive suspended].include?(@params[:status])
      users = users.where(status: @params[:status])
    end
    
    # 排序
    sort_field = @params[:sort] || 'created_at'
    order_direction = @params[:order] || 'desc'
    
    # 只允许特定的排序字段
    allowed_sort_fields = %w[created_at updated_at phone_number id]
    if allowed_sort_fields.include?(sort_field)
      users = users.order("#{sort_field} #{order_direction}")
    else
      users = users.order(created_at: :desc)
    end
    
    users
  end
end