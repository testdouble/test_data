require_relative "configuration_verification"

module TestData
  class VerifiesConfiguration
    def call
      problems = Configurators.all.flat_map { |configurator|
        configurator.verify.problems
      }.compact

      ConfigurationVerification.new(
        looks_good?: problems.none?,
        problems: problems
      )
    end
  end
end
