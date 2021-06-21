require "rails/generators"
require_relative "../../test_data/generator_support"

module TestData
  class CableYamlGenerator < Rails::Generators::Base
    def call
      unless Configurators::CableYaml.new.verify.looks_good?
        inject_into_file "config/cable.yml", before: BEFORE_TEST_STANZA_REGEX do
          <<~YAML

            test_data:
              adapter: async
          YAML
        end
      end
    end
  end
end
