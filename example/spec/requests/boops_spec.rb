require "rails_helper"

RSpec.configure do |config|
  config.before(:each) do
    TestData.load
  end

  config.after(:each) do
    TestData.rollback
  end
end

RSpec.describe "Boops", type: :request do
  30.times do |i|
    it "counts the boops ##{i}" do
      expect(Boop.count).to eq(10)
      Boop.create!
      expect(Boop.count).to eq(11)
    end
  end
end
