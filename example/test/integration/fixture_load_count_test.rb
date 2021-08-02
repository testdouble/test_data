# Regression test to make sure we don't load fixtures too many times

class HookCounter
  def self.count
    @call_count || 0
  end

  def self.count!
    @call_count ||= 0
    @call_count += 1
  end
end
at_exit do
  if TestData.statistics.load_rails_fixtures_count > 2 # could be 1 if :all runs first, 2 if :boops only does
    raise "Rails fixture load was called #{TestData.statistics.load_rails_fixtures_count} times, shouldn't be more than 2!"
  end
  if HookCounter.count > 2
    raise "Rails fixture load hook was called #{HookCounter.count} times, shouldn't be more than 2!"
  end
end

require "test_helper"

TestData.prevent_rails_fixtures_from_loading_automatically!

TestData.config do |config|
  config.after_rails_fixture_load {
    HookCounter.count!
  }
end

class PartialFixtureTest < ActiveSupport::TestCase
  fixtures :boops

  setup do
    TestData.uses_rails_fixtures(self)
  end

  def test_has_only_boops
    assert boops(:boop_1)
    assert_raises(NameError) { method(:pants) }
  end
end

class AllFixtureTest < ActiveSupport::TestCase
  fixtures :all

  setup do
    TestData.uses_rails_fixtures(self)
  end

  def test_has_both
    assert boops(:boop_1)
    assert pants(:pant_1)
  end
end

class AllFixtureTest2 < ActiveSupport::TestCase
  fixtures :all

  setup do
    TestData.uses_rails_fixtures(self)
  end

  def test_has_both
    assert boops(:boop_1)
    assert pants(:pant_1)
  end
end

class AllFixtureTest3 < ActiveSupport::TestCase
  fixtures :all

  setup do
    TestData.uses_rails_fixtures(self)
  end

  def test_has_both
    assert boops(:boop_1)
    assert pants(:pant_1)
  end
end
