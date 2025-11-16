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

    # 验证文件大小 (最大2MB)
    if @avatar_file.size > 2.megabytes
      return { success: false, error: '头像文件不能超过2MB' }
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
    # 生成唯一文件名
    file_name = "avatar_#{@user.id}_#{Time.current.to_i}#{File.extname(@avatar_file.original_filename)}"
    
    # 模拟文件上传路径 - 实际项目中应该使用真实的文件存储服务
    avatar_path = "uploads/avatars/#{file_name}"
    
    # 在实际项目中，这里应该：
    # 1. 将文件上传到云存储（如AWS S3、阿里云OSS等）
    # 2. 生成不同尺寸的缩略图
    # 3. 更新用户的avatar_path字段
    
    # 模拟上传成功，返回头像URL
    # 这里使用随机图片服务作为示例
    "https://picsum.photos/seed/avatar_#{@user.id}_#{Time.current.to_i}/300/300.jpg"
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