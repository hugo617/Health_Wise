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

# 创建50个测试用户
puts "创建测试用户数据..."

membership_types = ['次卡会员', '月卡会员', '年卡会员', '其他会员类别']
roles = ['admin', 'user']
statuses = ['active', 'inactive', 'suspended']  # 修正为数据库支持的枚举值

50.times do |i|
  phone = "138#{sprintf('%08d', i + 10000000)}"
  
  # 跳过已存在的手机号
  next if User.exists?(phone_number: phone)
  
  User.create!(
    phone_number: phone,
    email: "user#{i}@test.com",
    nickname: "测试用户#{i}",
    password: "password123",
    role: roles.sample,
    status: statuses.sample,
    membership_type: membership_types.sample
  )
  
  print "."
  puts if (i + 1) % 10 == 0
end

puts "\n✅ 测试用户创建完成！"
puts "📊 总计用户数量: #{User.count}"
puts "👥 管理员用户: #{User.where(role: 'admin').count}"
puts "👤 普通用户: #{User.where(role: 'user').count}"
puts "✅ 活跃用户: #{User.where(status: 'active').count}"
puts "🚫 禁用用户: #{User.where(status: 'inactive').count}"
puts "⏸️ 暂停用户: #{User.where(status: 'suspended').count}"

# 创建健康报告测试数据
puts "创建健康报告测试数据..."

report_types = ['基因检查报告', '蛋白质检测报告']
report_paths = [
  '/reports/gene_report_2025.pdf',
  '/reports/protein_analysis_2025.pdf',
  '/uploads/reports/genetic_test_001.pdf',
  '/uploads/reports/protein_check_002.pdf'
]
report_icons = [
  'https://picsum.photos/seed/gene-report/100/100.jpg',
  'https://picsum.photos/seed/protein-report/100/100.jpg',
  'https://picsum.photos/seed/medical-report/100/100.jpg'
]

# 为前20个用户创建健康报告
User.where(deleted_at: nil).limit(20).each_with_index do |user, index|
  # 每个用户创建2-4份健康报告
  rand(2..4).times do |i|
    report_type = report_types.sample
    
    # 跳过已存在的相同类型报告
    next if HealthReport.exists?(user_id: user.id, report_type: report_type)
    
    HealthReport.create!(
      user: user,
      report_type: report_type,
      report_path: report_paths.sample,
      report_icon_path: report_icons.sample,
      created_at: rand(30).days.ago,
      updated_at: rand(30).days.ago
    )
  end
  
  print "."
  puts if (index + 1) % 5 == 0
end

puts "\n✅ 健康报告测试数据创建完成！"
puts "📋 总报告数量: #{HealthReport.count}"
puts "🧬 基因检查报告: #{HealthReport.where(report_type: '基因检查报告').count}"
puts "🧪 蛋白质检测报告: #{HealthReport.where(report_type: '蛋白质检测报告').count}"