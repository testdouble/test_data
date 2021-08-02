module TestData
  module CustomLoaders
    class RailsFixtures < AbstractBase
      def initialize
        @config = TestData.config
        @statistics = TestData.statistics
        @already_loaded_rails_fixtures = {}
      end

      def name
        :rails_fixtures
      end

      def validate!(test_instance:)
        if !test_instance.respond_to?(:setup_fixtures)
          raise Error.new("'TestData.uses_rails_fixtures(self)' must be passed a test instance that has had ActiveRecord::TestFixtures mixed-in (e.g. `TestData.uses_rails_fixtures(self)` in an ActiveSupport::TestCase `setup` block), but the provided argument does not respond to 'setup_fixtures'")
        elsif !test_instance.respond_to?(:__test_data_gem_setup_fixtures)
          raise Error.new("'TestData.uses_rails_fixtures(self)' depends on Rails' default fixture-loading behavior being disabled by calling 'TestData.prevent_rails_fixtures_from_loading_automatically!' as early as possible (e.g. near the top of your test_helper.rb), but it looks like it was never called.")
        end
      end

      def load_requested(test_instance:)
        ActiveRecord::FixtureSet.reset_cache
        test_instance.instance_variable_set(:@loaded_fixtures,
          @already_loaded_rails_fixtures.slice(*test_instance.class.fixture_table_names))
        test_instance.instance_variable_set(:@fixture_cache, {})
      end

      def loaded?(test_instance:)
        test_instance.class.fixture_table_names.all? { |table_name|
          @already_loaded_rails_fixtures.key?(table_name)
        }
      end

      def load(test_instance:)
        test_instance.pre_loaded_fixtures = false
        test_instance.use_transactional_tests = false
        test_instance.__test_data_gem_setup_fixtures
        @already_loaded_rails_fixtures.merge!(test_instance.instance_variable_get(:@loaded_fixtures))
        @statistics.count_load_rails_fixtures!
        @config.after_rails_fixture_load_hook.call
      end
    end
  end
end
