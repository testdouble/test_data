require "active_support/environment_inquirer"

module ActiveSupport
  class EnvironmentInquirer < StringInquirer
    def test_data?
      self == "test_data"
    end
  end
end
