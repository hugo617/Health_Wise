# Health_Wise

# 初始化项目
rails new Health_Wise -d mysql

# c初始化静态登录，用户和健康报告页面
rails generate controller login index

rails generate controller users index

rails generate controller HealthReports index

# 初步搭建静态登录，用户健康报告和报告预览页面

## 数据库迁移与配置
- 生成迁移文件：
  - `rails generate migration CreateUsers`
  - `rails generate migration CreateHealthReports`

- 迁移文件内容：
  - `db/migrate/*_create_users.rb`
  ```ruby
  class CreateUsers < ActiveRecord::Migration[7.2]
    def change
      create_table :users do |t|
        t.string :phone_number, limit: 20, null: false, comment: '用户手机号'
        t.string :email,        limit: 100, null: false, comment: '用户邮箱'
        t.string :nickname,     limit: 50,  null: false, comment: '用户昵称'
        t.string :password_digest, limit: 255, null: false, comment: '加密后的密码'
        t.column :membership_type, "ENUM('次卡会员','月卡会员','年卡会员','其他会员类别')",
                 default: '次卡会员', null: false, comment: '会员类型'
        t.string :avatar_path,  limit: 255, comment: '头像存储路径'
        t.timestamps
      end
      add_index :users, :phone_number, unique: true
      add_index :users, :email, unique: true
      add_index :users, :nickname, unique: true
    end
  end
  ```

  - `db/migrate/*_create_health_reports.rb`
  ```ruby
  class CreateHealthReports < ActiveRecord::Migration[7.2]
    def change
      create_table :health_reports do |t|
        t.references :user, foreign_key: { on_delete: :cascade }, null: false, comment: '关联用户ID'
        t.column :report_type, "ENUM('基因检查报告','蛋白质检测报告')",
                 null: false, comment: '报告类型'
        t.string :report_path,     limit: 255, null: false, comment: '报告文件存储路径'
        t.string :report_icon_path, limit: 255, comment: '报告图标路径'
        t.timestamps
      end
      add_index :health_reports, [:user_id, :report_type], unique: true
    end
  end
  ```

- 执行迁移：
  - `bundle install`
  - `rails db:migrate`

- 回滚迁移：
  - `rails db:rollback STEP=2`

- 验证数据库结构：
  - 检查 `db/schema.rb` 是否出现 `users` 与 `health_reports` 表、唯一索引与外键级联
  - 在 `rails console` 中创建样例记录验证唯一性与枚举值约束

- 测试：
  - 模型测试位于 `test/models/user_test.rb` 与 `test/models/health_report_test.rb`
  - 创建测试数据库并迁移：`rails db:create RAILS_ENV=test`、`rails db:migrate RAILS_ENV=test`
  - 运行测试：`rails test`

- 配置与依赖：
  - 在 `config/application.rb` 添加：
    - `config.time_zone = 'Asia/Shanghai'`
    - `config.active_record.default_timezone = :local`
  - 在 `Gemfile` 启用：`gem 'bcrypt', '~> 3.1.7'` 并执行 `bundle install`