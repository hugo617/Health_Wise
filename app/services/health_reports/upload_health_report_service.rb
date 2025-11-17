class HealthReports::UploadHealthReportService
  def self.call(params)
    new(params).execute
  end

  def initialize(params)
    @params = params
    @user_id = params[:user_id]
    @report_type = params[:report_type]
    @report_file = params[:file]
    @current_user_id = params[:current_user_id]
  end

  def execute
    begin
      # 验证参数
      validation_result = validate_params
      return validation_result unless validation_result[:success]

      # 验证文件
      file_validation_result = validate_file
      return file_validation_result unless file_validation_result[:success]

      # 处理文件上传
      file_path = process_file_upload
      return { success: false, error: '文件上传失败' } if file_path.blank?

      # 生成报告图标路径
      icon_path = generate_icon_path(@report_type)

      # 创建或更新健康报告记录
      health_report = save_health_report(file_path, icon_path)

      Rails.logger.info "健康报告上传成功: 用户ID=#{@user_id}, 报告类型=#{@report_type}, 文件路径=#{file_path}"

      {
        success: true,
        data: {
          health_report: health_report,
          message: '健康报告上传成功'
        },
        error: nil
      }
    rescue StandardError => e
      Rails.logger.error "健康报告上传异常: #{e.message}\n#{e.backtrace.join("\n")}"
      { success: false, data: nil, error: "上传失败: #{e.message}" }
    end
  end

  private

  def validate_params
    # 检查必填字段
    if @user_id.blank?
      return { success: false, error: '用户ID不能为空' }
    end

    if @report_type.blank?
      return { success: false, error: '报告类型不能为空' }
    end

    if @report_file.blank?
      return { success: false, error: '请选择要上传的报告文件' }
    end

    # 验证用户存在且未被软删除
    user = User.find_by(id: @user_id, deleted_at: nil)
    unless user
      return { success: false, error: '用户不存在或已被删除' }
    end

    # 验证报告类型
    unless %w[基因检查报告 蛋白质检测报告].include?(@report_type)
      return { success: false, error: '报告类型不正确，只支持：基因检查报告、蛋白质检测报告' }
    end

    # 权限验证：普通用户只能为自己上传报告
    if @current_user_id.present?
      current_user = User.find_by(id: @current_user_id, deleted_at: nil)
      if current_user && current_user.role == 'user' && current_user.id != @user_id.to_i
        return { success: false, error: '您只能为自己上传报告' }
      end
    end

    { success: true }
  end

  def validate_file
    # 验证文件对象
    unless @report_file.respond_to?(:original_filename) && @report_file.respond_to?(:content_type)
      return { success: false, error: '无效的文件对象' }
    end

    # 验证文件类型（只允许 PDF）
    unless @report_file.content_type == 'application/pdf'
      return { success: false, error: '只支持 PDF 格式的报告文件' }
    end

    # 验证文件扩展名
    file_extension = File.extname(@report_file.original_filename).downcase
    unless file_extension == '.pdf'
      return { success: false, error: '文件扩展名必须为 .pdf' }
    end

    # 验证文件大小（最大 10MB）
    if @report_file.size > 10.megabytes
      return { success: false, error: '报告文件不能超过 10MB' }
    end

    # 验证文件名安全性（防止路径遍历攻击）
    original_filename = @report_file.original_filename
    if original_filename.include?('..') || original_filename.include?('/')
      return { success: false, error: '文件名包含非法字符' }
    end

    { success: true }
  end

  def process_file_upload
    # 生成安全的文件名
    timestamp = Time.current.to_i
    safe_filename = "#{@user_id}_#{sanitize_report_type(@report_type)}_#{timestamp}.pdf"
    
    # 确定存储目录
    upload_dir = Rails.root.join('public', 'uploads', 'reports')
    FileUtils.mkdir_p(upload_dir) unless Dir.exist?(upload_dir)
    
    # 完整文件路径
    file_full_path = upload_dir.join(safe_filename)
    
    # 保存文件到服务器
    File.open(file_full_path, 'wb') do |file|
      file.write(@report_file.read)
    end
    
    # 返回相对路径（用于存储到数据库）
    "/uploads/reports/#{safe_filename}"
  rescue StandardError => e
    Rails.logger.error "文件保存失败: #{e.message}"
    nil
  end

  def save_health_report(file_path, icon_path)
    # 查找是否已存在相同类型的报告
    existing_report = HealthReport.find_by(user_id: @user_id, report_type: @report_type)

    if existing_report
      # 更新现有报告
      existing_report.update!(
        report_path: file_path,
        report_icon_path: icon_path
      )
      existing_report
    else
      # 创建新报告
      HealthReport.create!(
        user_id: @user_id,
        report_type: @report_type,
        report_path: file_path,
        report_icon_path: icon_path
      )
    end
  end

  def sanitize_report_type(report_type)
    # 将报告类型转换为安全的文件名部分
    case report_type
    when '基因检查报告'
      'gene'
    when '蛋白质检测报告'
      'protein'
    else
      'report'
    end
  end

  def generate_icon_path(report_type)
    # 根据报告类型生成图标路径
    case report_type
    when '基因检查报告'
      'https://placehold.co/44x44/10b981/white?text=🧬'
    when '蛋白质检测报告'
      'https://placehold.co/44x44/06b6d4/white?text=🧪'
    else
      'https://placehold.co/44x44/6366f1/white?text=📄'
    end
  end
end

