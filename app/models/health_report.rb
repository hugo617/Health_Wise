class HealthReport < ApplicationRecord
  belongs_to :user

  validates :report_type, :report_path, presence: true
  validates :report_type, inclusion: { in: %w(基因检查报告 蛋白质检测报告) }
  validates :user_id, uniqueness: { scope: :report_type }
end