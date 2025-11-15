class User < ApplicationRecord
  has_secure_password
  has_many :health_reports, dependent: :destroy

  validates :phone_number, :email, :nickname, :password_digest, presence: true
  validates :phone_number, :email, :nickname, uniqueness: true
  validates :membership_type, inclusion: { in: %w(次卡会员 月卡会员 年卡会员 其他会员类别) }
end