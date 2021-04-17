require "rails/railtie"
require "pathname"

module TestData
  class Railtie < Rails::Railtie
    railtie_name :test_data

    rake_tasks do
      load Pathname.new(__dir__).join("rake.rb")
    end

    # generators do
    #   require "test_data/generators/environment_file"
    # end
  end
end
