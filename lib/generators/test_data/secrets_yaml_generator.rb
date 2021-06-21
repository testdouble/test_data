require "rails/generators"
require_relative "../../test_data/generator_support"

module TestData
  class SecretsYamlGenerator < Rails::Generators::Base
    def call
      unless Configurators::SecretsYaml.new.verify.looks_good?
        inject_into_file "config/secrets.yml", before: BEFORE_TEST_STANZA_REGEX do
          <<~YAML

            # Simplify configuration with the test_data environment
            test_data:
              secret_key_base: #{SecureRandom.hex(64)}
          YAML
        end
      end
    end
  end
end
