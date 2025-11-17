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
    # 普通用户只能为自己上传报告
    result = HealthReports::UploadHealthReportService.call(
      user_id: current_user.id,
      report_type: params[:report_type],
      file: params[:file],
      current_user_id: current_user.id
    )

    if result[:success]
      render json: {
        success: true,
        message: result[:data][:message],
        report: report_data(result[:data][:health_report])
      }
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
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
end