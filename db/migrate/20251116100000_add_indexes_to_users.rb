class AddIndexesToUsers < ActiveRecord::Migration[7.2]
  def change
    # 添加索引（如果不存在）
    add_index :users, :phone_number, unique: true unless index_exists?(:users, :phone_number)
    add_index :users, :email, unique: true unless index_exists?(:users, :email)
    add_index :users, :role unless index_exists?(:users, :role)
    add_index :users, :status unless index_exists?(:users, :status)
    add_index :users, :deleted_at unless index_exists?(:users, :deleted_at)
    
    # 添加复合索引用于搜索优化
    add_index :users, [:deleted_at, :role] unless index_exists?(:users, [:deleted_at, :role])
    add_index :users, [:deleted_at, :status] unless index_exists?(:users, [:deleted_at, :status])
  end
end