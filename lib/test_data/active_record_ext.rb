module TestData
  def self.prevent_rails_fixtures_from_loading_automatically!
    ActiveRecord::TestFixtures.define_method(:__test_data_gem_setup_fixtures,
      ActiveRecord::TestFixtures.instance_method(:setup_fixtures))
    ActiveRecord::TestFixtures.remove_method(:setup_fixtures)
    ActiveRecord::TestFixtures.define_method(:setup_fixtures, ->(config = nil) {})

    ActiveRecord::TestFixtures.remove_method(:teardown_fixtures)
    ActiveRecord::TestFixtures.define_method(:teardown_fixtures, -> {})
  end
end
