# 创建超级管理员账号
admin = User.find_by(phone_number: '19329336476')

if admin.nil?
  admin = User.create!(
    phone_number: '19329336476',
    email: 'admin@xixihealth.com',
    nickname: '超级管理员',
    password: 'xixiHealth',
    membership_type: '年卡会员',
    role: 'admin',
    status: 'active'
  )
  puts "✅ 超级管理员账号创建成功！"
  puts "   手机号: #{admin.phone_number}"
  puts "   密码: xixiHealth"
  puts "   角色: #{admin.role}"
else
  # 更新现有账号为管理员
  admin.update!(
    password: 'xixiHealth',
    role: 'admin',
    status: 'active'
  )
  puts "✅ 超级管理员账号已更新！"
  puts "   手机号: #{admin.phone_number}"
  puts "   密码: xixiHealth"
  puts "   角色: #{admin.role}"
end

# 创建测试用户
user = User.find_by(email: 'test@example.com')

if user.nil?
  user = User.create!(
    email: 'test@example.com',
    phone_number: '13800138001',
    nickname: '健康测试用户',
    password: 'password123',
    membership_type: '月卡会员',
    role: 'user',
    status: 'active',
    avatar_path: 'https://picsum.photos/seed/test-user/300/300.jpg'
  )
  puts "✅ 测试用户创建成功！"
else
  user.update!(role: 'user', status: 'active')
  puts "✅ 测试用户已更新！"
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

puts "\n✨ 测试数据创建成功！"
puts "\n📊 账号信息汇总："
puts "=" * 50
puts "【超级管理员】"
puts "  手机号: #{admin.phone_number}"
puts "  密码: xixiHealth"
puts "  角色: #{admin.role}"
puts "  昵称: #{admin.nickname}"
puts "\n【普通用户】"
puts "  手机号: #{user.phone_number}"
puts "  密码: password123"
puts "  角色: #{user.role}"
puts "  昵称: #{user.nickname}"
puts "  会员类型: #{user.membership_type}"
puts "  健康报告: #{user.health_reports.count} 份"
puts "=" * 50