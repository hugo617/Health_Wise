# 创建测试用户
user = User.find_by(email: 'test@example.com')

if user.nil?
  user = User.create!(
    email: 'test@example.com',
    phone_number: '13800138001',
    nickname: '健康测试用户',
    password: 'password123',
    membership_type: '月卡会员',
    avatar_path: 'https://picsum.photos/seed/test-user/300/300.jpg'
  )
end

# 创建健康报告
protein_report = HealthReport.find_or_create_by!(user: user, report_type: '蛋白质检测报告') do |report|
  report.report_path = '/reports/protein_report_2025.pdf'
  report.report_icon_path = 'https://placehold.co/44x44/06b6d4/white?text=🧪'
end

gene_report = HealthReport.find_or_create_by!(user: user, report_type: '基因检查报告') do |report|
  report.report_path = '/reports/gene_report_2025.pdf'
  report.report_icon_path = 'https://placehold.co/44x44/10b981/white?text=🧬'
end

puts "✨ 测试数据创建成功！"
puts "用户: #{user.nickname} (#{user.phone_number})"
puts "会员类型: #{user.membership_type}"
puts "健康报告: #{user.health_reports.count} 份"