def wrong_env?
  Rails.env != "test_data"
end

def run_in_test_data_env(task_name)
  command = "RAILS_ENV=test_data #{Rails.root}/bin/rake #{task_name}"
  unless system(command)
    fail "An error ocurred when running: #{command}"
  end
end

def create_database_or_else_blow_up_if_its_not_empty!
  unless TestData::DetectsDatabaseEmptiness.new.empty?
    raise TestData::Error.new("Database '#{TestData.config.database_name}' already exists and is not empty. To re-initialize it, drop it first (e.g. `rake test_data:drop_database`)")
  end
rescue TestData::Error => e
  raise e
rescue
  # Only (anticipated) cause for raise here is DB did not exist
  Rake::Task["test_data:create_database"].invoke
end

desc "Verifies test_data environment looks good"
task "test_data:verify_config" do
  config = TestData::VerifiesConfiguration.new.call
  unless config.looks_good?
    TestData.log.warn "The test_data gem is not configured correctly. Try 'rake test_data:configure'?\n"
    config.problems.each do |problem|
      TestData.log.warn "  - #{problem}"
    end
    fail
  end
end

desc "Install default configuration files and snippets"
task "test_data:configure" do
  TestData::InstallsConfiguration.new.call
end

desc "Initialize test_data's interactive database"
task "test_data:initialize" => ["test_data:verify_config", :environment] do
  next run_in_test_data_env("test_data:initialize") if wrong_env?

  create_database_or_else_blow_up_if_its_not_empty!
  if TestData::VerifiesDumpsAreLoadable.new.call(quiet: true)
    Rake::Task["test_data:load"].invoke
  else
    ActiveRecord::Tasks::DatabaseTasks.load_schema_current(ActiveRecord::Base.schema_format, ENV["SCHEMA"], "test_data")
    ActiveRecord::Tasks::DatabaseTasks.load_seed
  end
end

desc "Initialize test_data Rails environment & configure database"
task "test_data:install" => ["test_data:configure", "test_data:initialize"]

desc "Dumps the interactive test_data database"
task "test_data:dump" => "test_data:verify_config" do
  TestData::DumpsDatabase.new.call
end

desc "Dumps the interactive test_data database"
task "test_data:load" => ["test_data:verify_config", :environment] do
  next run_in_test_data_env("test_data:load") if wrong_env?

  create_database_or_else_blow_up_if_its_not_empty!

  unless TestData::VerifiesDumpsAreLoadable.new.call
    fail "Cannot load schema & data into database '#{TestData.config.database_name}'"
  end

  TestData::LoadsDatabaseDumps.new.call

  if ActiveRecord::Base.connection.migration_context.needs_migration?
    TestData.log.warn "There are pending migrations for database '#{TestData.config.database_name}'. To run them, run:\n\n  RAILS_ENV=test_data bin/rake db:migrate\n\n"
  end
end

desc "Creates the test_data interactive database"
task "test_data:create_database" => :environment do
  if TestData::Configurators::DatabaseYaml.new.verify.looks_good?
    ActiveRecord::Tasks::DatabaseTasks.create_current("test_data")
  else
    warn "Warning: 'test_data' section not defined in config/database.yml - Skipping"
  end
end

# Add the test_data env to Rails' default rake db:create task
Rake::Task["db:create"].enhance do |task|
  Rake::Task["test_data:create_database"].invoke
end

desc "Drops the test_data interactive database"
task "test_data:drop_database" => :environment do
  if TestData::Configurators::DatabaseYaml.new.verify.looks_good?
    ActiveRecord::Tasks::DatabaseTasks.drop_current("test_data")
  else
    warn "Warning: 'test_data' section not defined in config/database.yml - Skipping"
  end
end

# Add the test_data env to Rails' default rake db:create task
Rake::Task["db:drop"].enhance do |task|
  Rake::Task["test_data:drop_database"].invoke
end
