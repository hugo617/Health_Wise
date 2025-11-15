require 'test_helper'

class HealthReportTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(phone_number: '13800000003', email: 'd@example.com', nickname: 'nick4', password: 'Secret123', membership_type: '月卡会员')
  end

  test '必填与枚举校验' do
    hr = HealthReport.new(user: @user, report_type: '非法', report_path: nil)
    assert_not hr.valid?
    assert hr.errors[:report_type].present?
    assert hr.errors[:report_path].present?
  end

  test '唯一性 (user_id, report_type) 组合' do
    HealthReport.create!(user: @user, report_type: '基因检查报告', report_path: '/a.pdf')
    dup = HealthReport.new(user: @user, report_type: '基因检查报告', report_path: '/b.pdf')
    assert_not dup.valid?
    assert dup.errors[:user_id].present?
  end

  test '关联与级联删除（ON DELETE CASCADE）' do
    HealthReport.create!(user: @user, report_type: '蛋白质检测报告', report_path: '/c.pdf')
    assert_difference('HealthReport.count', -1) do
      @user.destroy
    end
  end
end