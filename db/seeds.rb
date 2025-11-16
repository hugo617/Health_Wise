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