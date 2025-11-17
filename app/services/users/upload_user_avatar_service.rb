class Users::UploadUserAvatarService
  def self.call(user, avatar_file)
    new(user, avatar_file).execute
  end

  def initialize(user, avatar_file)
    @user = user
    @avatar_file = avatar_file
  end

  def execute
    begin
      # 验证文件
      validation_result = validate_avatar_file
      return validation_result unless validation_result[:success]

      # 处理头像上传
      avatar_url = process_avatar_upload
      
      { success: true, avatar_url: avatar_url }
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end

  private

  def validate_avatar_file
    return { success: false, error: '请选择头像文件' } if @avatar_file.blank?

    # 验证文件类型
    unless @avatar_file.content_type.start_with?('image/')
      return { success: false, error: '请选择图片文件' }
    end

    # 验证文件大小 (最大5MB)
    if @avatar_file.size > 5.megabytes
      return { success: false, error: '头像文件不能超过5MB' }
    end

    # 验证文件格式
    allowed_formats = %w[jpg jpeg png gif webp]
    file_extension = File.extname(@avatar_file.original_filename).downcase[1..-1]
    
    unless allowed_formats.include?(file_extension)
      return { success: false, error: '支持的图片格式：JPG、PNG、GIF、WebP' }
    end

    { success: true }
  end

  def process_avatar_upload
    # 生成基于手机号的文件名，确保唯一性
    phone_number = @user.phone_number || "user_#{@user.id}"
    file_extension = File.extname(@avatar_file.original_filename).downcase
    file_name = "#{phone_number}#{file_extension}"
    
    # 本地存储路径
    avatar_dir = Rails.root.join('public', 'uploads', 'avatars')
    avatar_path = avatar_dir.join(file_name)
    
    # 确保目录存在
    FileUtils.mkdir_p(avatar_dir) unless File.exist?(avatar_dir)
    
    # 保存文件到本地存储
    File.open(avatar_path, 'wb') do |file|
      file.write(@avatar_file.read)
    end
    
    # 更新用户的avatar_path字段
    save_avatar_path("/uploads/avatars/#{file_name}")
    
    # 返回头像URL
    "/uploads/avatars/#{file_name}"
  end

  def generate_thumbnail(image_path, size)
    # 在实际项目中，这里应该使用ImageMagick或类似工具生成缩略图
    # 这里只是模拟实现
    "#{image_path}_#{size}x#{size}"
  end

  def save_avatar_path(avatar_path)
    @user.update!(avatar_path: avatar_path)
  end
end