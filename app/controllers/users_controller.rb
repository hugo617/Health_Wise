class UsersController < ApplicationController
  # 用户管理需要管理员权限
  before_action :require_admin
  before_action :set_current_user_id, only: [:destroy]
  
  # 错误处理
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  def index
    respond_to do |format|
      format.html do
        # HTML 请求：渲染视图页面
        @users = User.where(deleted_at: nil).order(created_at: :desc).limit(10)
      end
      
      format.json do
        # JSON 请求（Ajax）：返回搜索和分页数据
        result = Users::SearchUsersService.call(params)
        
        if result[:success]
          render json: {
            users: result[:data][:users].as_json(
              only: [:id, :phone_number, :email, :nickname, :role, :status, :membership_type, :created_at, :updated_at, :avatar_path]
            ),
            total: result[:data][:total],
            page: result[:data][:page],
            per_page: result[:data][:per_page],
            total_pages: result[:data][:total_pages]
          }
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    @user = User.find(params[:id])
    
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end

  def new
    @user = User.new
  end

  def create
    result = Users::CreateUserService.call(user_params)
    
    if result[:success]
      redirect_to users_path, notice: '用户创建成功！'
    else
      @user = User.new(user_params)
      flash.now[:alert] = result[:error]
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    result = Users::UpdateUserService.call(params[:id], user_params)
    
    if result[:success]
      redirect_to user_path(result[:data][:user]), notice: '用户更新成功！'
    else
      @user = User.find(params[:id])
      flash.now[:alert] = result[:error]
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    result = Users::DeleteUserService.call(params[:id])
    
    if result[:success]
      redirect_to users_path, notice: '用户删除成功！'
    else
      redirect_to users_path, alert: result[:error]
    end
  end

  private

  def user_params
    params.require(:user).permit(:phone_number, :email, :nickname, :password, :role, :status, :membership_type, :avatar_path)
  end

  def set_current_user_id
    # 为 DeleteUserService 提供当前用户ID，防止自我删除
    Thread.current[:current_user_id] = current_user&.id
  end

  def record_not_found
    redirect_to users_path, alert: '用户不存在'
  end

  def record_invalid(exception)
    redirect_to users_path, alert: "数据验证失败: #{exception.message}"
  end
end
