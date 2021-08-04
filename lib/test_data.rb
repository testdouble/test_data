require_relative "test_data/active_record_ext"
require_relative "test_data/active_support_ext"
require_relative "test_data/config"
require_relative "test_data/configuration_verification"
require_relative "test_data/configurators"
require_relative "test_data/configurators/environment_file"
require_relative "test_data/configurators/initializer"
require_relative "test_data/configurators/cable_yaml"
require_relative "test_data/configurators/database_yaml"
require_relative "test_data/configurators/secrets_yaml"
require_relative "test_data/configurators/webpacker_yaml"
require_relative "test_data/custom_loaders/abstract_base"
require_relative "test_data/custom_loaders/rails_fixtures"
require_relative "test_data/detects_database_emptiness"
require_relative "test_data/dumps_database"
require_relative "test_data/error"
require_relative "test_data/inserts_test_data"
require_relative "test_data/installs_configuration"
require_relative "test_data/loads_database_dumps"
require_relative "test_data/log"
require_relative "test_data/railtie"
require_relative "test_data/save_point"
require_relative "test_data/statistics"
require_relative "test_data/manager"
require_relative "test_data/truncates_test_data"
require_relative "test_data/verifies_configuration"
require_relative "test_data/verifies_dumps_are_loadable"
require_relative "test_data/version"
require_relative "generators/test_data/environment_file_generator"
require_relative "generators/test_data/initializer_generator"
require_relative "generators/test_data/cable_yaml_generator"
require_relative "generators/test_data/database_yaml_generator"
require_relative "generators/test_data/secrets_yaml_generator"
require_relative "generators/test_data/webpacker_yaml_generator"

module TestData
  def self.uninitialize
    @manager ||= Manager.new
    @manager.rollback_to_before_data_load
    nil
  end

  def self.uses_test_data
    @manager ||= Manager.new
    @manager.load
    nil
  end

  def self.uses_clean_slate
    @manager ||= Manager.new
    @manager.truncate
    nil
  end

  def self.uses_rails_fixtures(test_instance)
    @rails_fixtures_loader ||= CustomLoaders::RailsFixtures.new
    @manager ||= Manager.new
    @manager.load_custom_data(@rails_fixtures_loader, test_instance: test_instance)
    nil
  end

  def self.insert_test_data_dump
    InsertsTestData.new.call
    nil
  end
end
