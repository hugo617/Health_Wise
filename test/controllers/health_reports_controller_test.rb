require "test_helper"

class HealthReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get health_reports_index_url
    assert_response :success
  end
end
