require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test '必填字段校验' do
    u = User.new
    assert_not u.valid?
    assert u.errors[:phone_number].present?
    assert u.errors[:email].present?
    assert u.errors[:nickname].present?
    assert u.errors[:password_digest].present?
  end

  test '唯一性索引校验' do
    User.create!(phone_number: '13800000000', email: 'a@example.com', nickname: 'nick', password: 'Secret123', membership_type: '次卡会员')
    dup = User.new(phone_number: '13800000000', email: 'a@example.com', nickname: 'nick', password: 'Secret123', membership_type: '次卡会员')
    assert_not dup.valid?
    assert dup.errors[:phone_number].present?
    assert dup.errors[:email].present?
    assert dup.errors[:nickname].present?
  end

  test '会员类型枚举校验' do
    u = User.new(phone_number: '13800000001', email: 'b@example.com', nickname: 'nick2', password: 'Secret123', membership_type: '非法值')
    assert_not u.valid?
    assert u.errors[:membership_type].present?
  end

  test 'has_secure_password 工作正常' do
    u = User.create!(phone_number: '13800000002', email: 'c@example.com', nickname: 'nick3', password: 'Secret123', membership_type: '次卡会员')
    assert u.authenticate('Secret123')
    assert_not u.authenticate('Wrong')
  end
end