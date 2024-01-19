require_relative "../yaml_loader"

module TestData
  module Wrap
    class WebpackerConfig
      def initialize
        @user_config_path = Pathname.new("#{TestData.config.pwd}/config/webpacker.yml")
      end

      def relative_user_config_path
        @user_config_path.relative_path_from(Rails.root)
      end

      def no_user_config_exists?
        !@user_config_path.readable?
      end

      def user_config
        load_yaml(@user_config_path)
      end

      def webpacker_gem_spec_loaded?
        !!Gem.loaded_specs["webpacker"]
      end

      def builtin_config
        webpacker_path = Gem.loaded_specs["webpacker"].full_gem_path
        load_yaml(File.join(webpacker_path, "lib/install/config/webpacker.yml"))
      end

      def required_entries_missing_from_test_data_config
        missing_keys = builtin_config["development"].keys - user_config["test_data"].keys
        builtin_config["development"].slice(*missing_keys).presence
      end

      private

      def load_yaml(path)
        YAMLLoader.load_file(path)
      rescue
      end
    end
  end
end
