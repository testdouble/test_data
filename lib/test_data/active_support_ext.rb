require "active_support/environment_inquirer"
module ActiveSupport
  class EnvironmentInquirer
    def initialize(env)
      super(env)

      @test_data = env == "test_data"
    end

    def test_data?
      @test_data
    end
  end
end
