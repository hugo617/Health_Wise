class Users::UpdateUserProfileService
  def self.call(user, params)
    new(user, params).execute
  end

  def initialize(user, params)
    @user = user
    @params = params
  end

  def execute
    begin
      # 验证参数
      validation_result = validate_params
      return validation_result unless validation_result[:success]

      # 更新用户资料
      update_user_profile
      
      { success: true, user: @user }
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end

  private

  def validate_params
    # 验证昵称
    if @params[:nickname].blank?
      return { success: false, error: '昵称不能为空' }
    end

    if @params[:nickname].length > 50
      return { success: false, error: '昵称长度不能超过50个字符' }
    end

    # 验证手机号
    if @params[:phone_number].present?
      unless valid_phone_number?(@params[:phone_number])
        return { success: false, error: '手机号格式不正确' }
      end

      # 检查手机号是否已被其他用户使用
      if User.where(phone_number: @params[:phone_number])
             .where.not(id: @user.id)
             .exists?
        return { success: false, error: '该手机号已被其他用户使用' }
      end
    end

    # 验证邮箱
    if @params[:email].present?
      unless valid_email?(@params[:email])
        return { success: false, error: '邮箱格式不正确' }
      end

      # 检查邮箱是否已被其他用户使用
      if User.where(email: @params[:email])
             .where.not(id: @user.id)
             .exists?
        return { success: false, error: '该邮箱已被其他用户使用' }
      end
    end

    # 验证密码
    if @params[:password].present?
      if @params[:password].length < 6
        return { success: false, error: '密码长度不能少于6个字符' }
      end

      if @params[:password].length > 128
        return { success: false, error: '密码长度不能超过128个字符' }
      end
    end

    { success: true }
  end

  def update_user_profile
    @user.assign_attributes(filtered_params)
    
    # 如果有新密码，则更新密码
    if @params[:password].present?
      @user.password = @params[:password]
    end

    @user.save!
  end

  def filtered_params
    @params.slice(:nickname, :phone_number, :email)
  end

  def valid_phone_number?(phone)
    # 中国大陆手机号验证
    phone.match?(/^1[3-9]\d{9}$/)
  end

  def valid_email?(email)
    # 邮箱格式验证
    email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end
end