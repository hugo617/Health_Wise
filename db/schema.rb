# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_11_16_100000) do
  create_table "health_reports", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false, comment: "关联用户ID"
    t.column "report_type", "enum('基因检查报告','蛋白质检测报告')", null: false, comment: "报告类型"
    t.string "report_path", null: false, comment: "报告文件存储路径"
    t.string "report_icon_path", comment: "报告图标路径"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "report_type"], name: "index_health_reports_on_user_id_and_report_type", unique: true
    t.index ["user_id"], name: "index_health_reports_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "phone_number", limit: 20, null: false, comment: "用户手机号"
    t.string "email", limit: 100, null: false, comment: "用户邮箱"
    t.string "nickname", limit: 50, null: false, comment: "用户昵称"
    t.string "password_digest", null: false, comment: "加密后的密码"
    t.column "membership_type", "enum('次卡会员','月卡会员','年卡会员','其他会员类别')", default: "次卡会员", null: false, comment: "会员类型"
    t.string "avatar_path", comment: "头像存储路径"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", comment: "软删除时间"
    t.column "status", "enum('active','inactive','suspended')", comment: "账户状态"
    t.column "role", "enum('user','admin')", comment: "角色"
    t.index ["deleted_at", "role"], name: "index_users_on_deleted_at_and_role"
    t.index ["deleted_at", "status"], name: "index_users_on_deleted_at_and_status"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["nickname"], name: "index_users_on_nickname", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "health_reports", "users", on_delete: :cascade
end
