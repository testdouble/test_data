require "rails/railtie"
require "pathname"

module TestData
  class Railtie < Rails::Railtie
    railtie_name :test_data

    rake_tasks do
      load Pathname.new(__dir__).join("rake.rb")
    end
  end
end
