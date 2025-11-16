# Redis configuration for SMS verification code storage
require 'redis'

REDIS = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))

# Test Redis connection on initialization
begin
  REDIS.ping
  Rails.logger.info "Redis connection established successfully"
rescue Redis::CannotConnectError => e
  Rails.logger.error "Failed to connect to Redis: #{e.message}"
  Rails.logger.error "SMS verification functionality will not work without Redis"
end

