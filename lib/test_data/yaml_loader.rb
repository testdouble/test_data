module TestData
  module YAMLLoader
    def self.load_file(path)
      begin
        YAML.load_file(path, aliases: true)
      rescue ArgumentError
        YAML.load_file(path)
      end
    end
  end
end
