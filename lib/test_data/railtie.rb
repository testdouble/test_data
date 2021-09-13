require "rails/railtie"
require "pathname"

module TestData
  class Railtie < Rails::Railtie
    railtie_name :test_data

    rake_tasks do
      load Pathname.new(__dir__).join("rake.rb")
    end

    initializer "test_data.validate_data_up_to_date" do
      WarnsIfDumpIsNewerThanDatabase.new.call
    end
  end
end
