# Health_Wise

# 初始化项目
rails new Health_Wise -d mysql

# c初始化静态登录，用户和健康报告页面
rails generate controller login index

rails generate controller users index

rails generate controller HealthReports index

# 初步搭建静态登录，用户健康报告和报告预览页面