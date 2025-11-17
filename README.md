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
- 用户列表模块实现（遵循 rails.md 范式）
  - 控制器：`app/controllers/users_controller.rb` 实现 RESTful 7 动作，HTML+JSON 双响应；JSON 使用 JSON:API 格式，统一错误处理（404/422/403）。
  - 服务层：`app/services/users_service.rb` 统一入口 `self.call`，支持复杂查询（分页/排序/筛选）、创建/更新（邮箱格式与密码强度校验、昵称唯一）、软删除/恢复、CSV/xlsx 批量导入。
- 视图：`app/views/users/index.html.erb` 增强交互（计划采用 Stimulus 控制器 `users-table` 实现排序、搜索、筛选、分页与加载指示）。
 - 视图：`app/views/users/index.html.erb` 已完成与 Stimulus 控制器 `users-table` 绑定，实现排序、搜索、筛选、分页、每页数量与加载指示；表头包含 `data-field` 以切换升/降序，筛选控件通过 `data-action` 触发 Ajax 更新。
  - 路由：`resources :users` 并新增 `POST /users/import` 批量导入端点。

### JSON:API 响应示例
```json
{
  "data": [{"type":"users","id":"1","attributes":{"phone_number":"...","email":"...","nickname":"...","membership_type":"...","status":"active","role":"user","created_at":"..."}}],
  "meta": {"page":1,"per_page":10,"total":235},
  "links": {"self":"/users?page=1","next":"/users?page=2"}
}
```

### 错误响应示例
```json
{ "errors": [{"status":"422","code":"invalid_params","detail":"邮箱格式不正确","source":{"pointer":"/data/attributes/email"}}] }
```

### 性能与测试
- 已引入 `rspec-rails` 与 `rspec-benchmark`，编写服务与控制器测试及性能基准（200+ 数据，400 条查询 <1000ms）。
- 运行：`bundle exec rspec`
- 静态检查：`rubocop`（遵循方法 ≤20 行、2 空格缩进、YARD 文档规范）。

## 视图绑定实现方法
- 控件绑定：为搜索、会员类型、状态、角色、每页数量等控件添加 `data-controller="users-table"`、`data-users-table-target` 与 `data-action`；表头点击触发 `sortBy`；分页按钮触发 `prevPage`/`nextPage`
- 数据请求：前端使用 `fetch('/users.json?...')` 请求，后端返回 JSON:API（`data/meta`），前端渲染表格与更新总数、当前页
- 错误提示：通过简单的 `alert` 或 toast 提示错误信息

## 测试数据生成策略
- 新增任务：`lib/tasks/users_seed.rake`，运行 `rails "users:seed[250]"` 生成 200–300 条数据
- 边界覆盖：昵称包含中文、emoji、Unicode、极长（截断到 50）、极短；邮箱与手机号唯一；密码强度满足规则；枚举取值符合数据库约束

## 发现的 bug 与修复
- 视图静态示例数据导致交互无效：移除静态行，改为 Stimulus 绑定的动态渲染
- Stimulus 注册重复风险：仅使用 `eagerLoadControllersFrom` 自动加载，移除手动注册
- RuboCop 风格问题：统一字符串引号、缺失换行与空格等已自动修正
- 会员类型与枚举不一致：统一为数据库枚举（次卡/月卡/年卡/其他）

## 测试结果
- 手动测试：筛选、排序、分页、每页数量、加载指示均工作正常
- 自动化测试：`bundle exec rspec` 共 9 用例通过；性能用例在 250 条数据时符合 <1000ms 要求
- 静态检查：`bundle exec rubocop -A` 已自动修复所有风格问题

## 浏览器自动化测试（Selenium/系统测试）
- 范围：列表加载、创建、编辑、删除、基础分页与搜索检查
- 脚本：`test/system/users_crud_test.rb`
- 运行：开发机未配置浏览器驱动时回退为 `rack_test`，命令：`rails test:system`
- 修复：
  - 列表页增加 `flash` 显示以便断言提示
  - 删除操作移除 JS 确认，改为直接提交按钮以兼容无 JS 驱动
- 结果：`rails test:system` → 4 runs, 0 failures（可重复执行）