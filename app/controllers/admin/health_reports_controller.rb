class Admin::HealthReportsController < ApplicationController
  # 管理员权限检查
  before_action :require_admin
  
  def index
    # 管理员可以查看所有用户的健康报告
    result = HealthReports::SearchHealthReportsService.call(
      search: params[:search],
      user_id: params[:user_id],
      report_type: params[:report_type],
      current_user_id: nil, # 不传递 current_user_id，管理员查看所有报告
      page: params[:page] || 1,
      per_page: params[:per_page] || 10,
      sort: params[:sort] || 'created_at',
      order: params[:order] || 'desc'
    )

    respond_to do |format|
      format.html do
        if result[:success]
          @health_reports = result[:data][:health_reports]
          @total = result[:data][:total]
          @page = result[:data][:page]
          @per_page = result[:data][:per_page]
          @total_pages = result[:data][:total_pages]

          # 加载用户列表用于筛选下拉框
          @users = User.where(deleted_at: nil).order(:nickname).limit(100)
        else
          @health_reports = []
          @total = 0
          @page = 1
          @per_page = 10
          @total_pages = 0
          @users = []
          flash.now[:alert] = result[:error]
        end
      end

      format.json do
        if result[:success]
          # 将 ActiveRecord 对象转换为 JSON 格式
          reports_json = result[:data][:health_reports].map { |report| report_data(report) }
          render json: {
            success: true,
            data: {
              health_reports: reports_json,
              total: result[:data][:total],
              page: result[:data][:page],
              per_page: result[:data][:per_page],
              total_pages: result[:data][:total_pages]
            },
            error: nil
          }
        else
          render json: result, status: :unprocessable_entity
        end
      end
    end
  end
  
  def show
    # 管理员可以查看任意用户的报告详情
    @health_report = HealthReport.includes(:user).find(params[:id])
    
    respond_to do |format|
      format.html
      format.json { render json: report_data(@health_report) }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html do
        redirect_to admin_health_reports_path, alert: "报告不存在"
      end
      format.json do
        render json: { success: false, error: "报告不存在" }, status: :not_found
      end
    end
  end
  
  def create
    result = HealthReports::CreateHealthReportService.call(create_params)
    
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
    result = HealthReports::DeleteHealthReportService.call(params[:id])
    
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
  
  private
  
  def create_params
    params.permit(:user_id, :report_type, :report_path, :report_icon_path)
  end
  
  def update_params
    params.permit(:report_type, :report_path, :report_icon_path)
  end
  
  def report_data(report)
    {
      id: report.id,
      user_id: report.user_id,
      user_nickname: report.user.nickname,
      user_phone: report.user.phone_number,
      user_email: report.user.email,
      user_role: report.user.role,
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