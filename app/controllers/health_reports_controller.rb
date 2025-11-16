class HealthReportsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @user = current_user
    @health_reports = @user.health_reports.order(created_at: :desc)
    
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
    @report = current_user.health_reports.find(params[:id])
    
    respond_to do |format|
      format.html
      format.json { render json: report_data(@report) }
    end
  end

  def update_profile
    result = UpdateUserProfileService.call(current_user, profile_params)
    
    if result[:success]
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
    result = UploadUserAvatarService.call(current_user, params[:avatar])
    
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

  private

  def authenticate_user!
    # 模拟用户认证 - 实际项目中应该使用真实的认证机制
    @current_user = User.first || create_default_user
  end

  def current_user
    @current_user
  end

  def create_default_user
    User.create!(
      phone_number: '13800138000',
      email: 'user@example.com',
      nickname: '健康用户',
      password: 'password123',
      membership_type: '次卡会员'
    )
  end

  def profile_params
    params.permit(:nickname, :phone_number, :email, :password)
  end

  def user_data
    {
      id: @user.id,
      nickname: @user.nickname,
      phone_number: @user.phone_number,
      email: @user.email,
      membership_type: @user.membership_type,
      avatar_url: @user.avatar_path || 'https://picsum.photos/seed/user-avatar/300/300.jpg'
    }
  end

  def reports_data
    @health_reports.map { |report| report_data(report) }
  end

  def report_data(report)
    {
      id: report.id,
      report_type: report.report_type,
      report_path: report.report_path,
      report_icon_path: report.report_icon_path,
      created_at: report.created_at.strftime('%Y-%m-%d'),
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