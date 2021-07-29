require "rails_helper"

TestData.prevent_rails_fixtures_from_loading_automatically!

module TestDataModes
  def uses(mode)
    case mode
    when :clean_slate
      before(:each) { TestData.uses_clean_slate }
    when :test_data
      before(:each) { TestData.uses_test_data }
    else
      raise "Invalid test data mode: #{mode}"
    end
  end
end

RSpec.configure do |config|
  config.extend(TestDataModes)
end

RSpec.describe "FixtureFreeTestData", type: :request do
  fixtures :boops

  uses :test_data
  it "has 15 boops in the test_data" do
    expect(Boop.count).to eq(15)
  end
end

RSpec.describe "Clean Slate" do
  uses :clean_slate

  it "has no boops" do
    expect(Boop.count).to eq(0)
  end
end

RSpec.describe "FixturesUsingTest", type: :request do
  fixtures :boops

  before(:each) do
    TestData.uses_rails_fixtures(self)
  end

  it "has_fixture_boops" do
    expect(boops(:boop_1)).to be_persisted
    expect(Boop.count).to eq(2)
  end

  it "does_not_get_the_other_fixture_accessor" do
    expect { method(:pants) }.to raise_error(NameError)
  end

  it "even_explicitly_loading_test_data_will_truncate_and_then_load_fixtures" do
    TestData.uses_test_data
    TestData.uses_rails_fixtures(self)

    expect(Boop.count).to eq(2)
  end

  it "load_and_rollback_leaves_them_as_is" do
    boop = Boop.first
    original_created_on = boop.created_at.to_date
    a_year_ago = 1.year.ago.to_date

    boop.update!(created_at: a_year_ago)

    expect(Boop.find(boop.id).created_at.to_date).to eq(a_year_ago)

    # Now after rollback
    TestData.uses_rails_fixtures(self)

    expect(Boop.find(boop.id).created_at.to_date).to eq(original_created_on)
  end
end

RSpec.describe "SomeFixturesAndSomeTestDataInOneClassTest", type: :request do
  fixtures :all

  it "fixtures_work" do
    TestData.uses_rails_fixtures(self)

    expect(boops(:boop_1).updated_at.to_date).to eq(Date.civil(2020, 1, 1))
    expect(pants(:pant_1).brand).to eq("Levi")
  end

  it "test_that_rewinds_to_test_data" do
    TestData.uses_test_data

    expect(Boop.count).to eq(15)
  end

  it "that_rewinds_to_the_very_start" do
    TestData.uninitialize

    expect(Boop.count).to eq(0)
  end

  it "fixtures_get_reloaded_because_cache_is_cleared" do
    TestData.uses_rails_fixtures(self)

    expect(boops(:boop_2).updated_at.to_date).to eq(Date.civil(2019, 1, 1))
    expect(pants(:pant_2).brand).to eq("Wrangler")
  end
end
