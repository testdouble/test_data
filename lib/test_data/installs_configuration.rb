module TestData
  class InstallsConfiguration
    def call
      Configurators.all.each do |configurator|
        configurator.configure
      end
    end
  end
end
