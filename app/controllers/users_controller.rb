class UsersController < ApplicationController
  # 用户管理需要管理员权限
  before_action :require_admin

  def index
    @users = User.where(deleted_at: nil).order(created_at: :desc)
  end
end
