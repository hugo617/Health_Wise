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
