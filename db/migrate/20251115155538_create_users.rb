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
