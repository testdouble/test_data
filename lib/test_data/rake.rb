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
  raise unless Rails.env.test_data?

  unless TestData::DetectsDatabaseExistence.new.call
    Rake::Task["test_data:create_database"].invoke
  end

  unless TestData::DetectsDatabaseEmptiness.new.empty?
    raise TestData::Error.new("Database '#{TestData.config.database_name}' already exists and is not empty. To re-initialize it, drop it first (e.g. `rake test_data:drop_database`)")
  end
end

desc "Verifies that the test_data environment looks good"
task "test_data:verify_config" do
  TestData.log.with_plain_writer do
    config = TestData::VerifiesConfiguration.new.call
    unless config.looks_good?
      TestData.log.warn "\nThe test_data gem is not configured correctly. Try running: rake test_data:configure\n\n"
      config.problems.each do |problem|
        TestData.log.warn "  - #{problem}"
      end
      fail
    end
  end
end

desc "Installs default configuration files and snippets"
task "test_data:configure" do
  TestData::InstallsConfiguration.new.call
end

desc "Initializes test_data's interactive database"
task "test_data:initialize" => ["test_data:verify_config", :environment] do
  next run_in_test_data_env("test_data:initialize") if wrong_env?

  create_database_or_else_blow_up_if_its_not_empty!
  if TestData::VerifiesDumpsAreLoadable.new.call(quiet: true)
    Rake::Task["test_data:load"].invoke
  else
    ActiveRecord::Tasks::DatabaseTasks.load_schema_current(ActiveRecord::Base.schema_format, ENV["SCHEMA"], "test_data")
    ActiveRecord::Tasks::DatabaseTasks.load_seed
  end

  TestData.log.info <<~MSG
    Your test_data environment and database are ready for use! You can now run your server (or any command) to create some test data like so:

      $ RAILS_ENV=test_data bin/rails server

  MSG
end

desc "Re-initializes test_data's interactive database (by dropping and reloading it)"
task "test_data:reinitialize" => ["test_data:verify_config", :environment] do
  next run_in_test_data_env("test_data:reinitialize") if wrong_env?

  # Take caution only if the test_data database exists
  if TestData::DetectsDatabaseExistence.new.call
    TestData::WarnsIfDatabaseIsNewerThanDump.new.call

    unless ENV["TEST_DATA_CONFIRM"].present?
      confirmed = if $stdin.isatty
        puts "This will DROP test_data database '#{TestData.config.database_name}'. Are you sure you want to re-initialize it? [yN]"
        $stdin.gets.chomp.downcase.start_with?("y")
      else
        puts "'#{TestData.config.database_name}' exists. Set TEST_DATA_CONFIRM=true to drop the database and re-initialize it."
        false
      end

      unless confirmed
        puts "Exiting without making any changes"
        exit 1
      end
    end

    Rake::Task["test_data:drop_database"].invoke
  end

  Rake::Task["test_data:initialize"].invoke
end

desc "Initializes test_data Rails environment & configure database"
task "test_data:install" => ["test_data:configure", "test_data:initialize"]

desc "Dumps the interactive test_data database"
task "test_data:dump" => ["test_data:verify_config", :environment] do
  next run_in_test_data_env("test_data:dump") if wrong_env?

  TestData::DumpsDatabase.new.call
end

desc "Loads the schema and data SQL dumps into the test_data database"
task "test_data:load" => ["test_data:verify_config", :environment] do
  next run_in_test_data_env("test_data:load") if wrong_env?

  create_database_or_else_blow_up_if_its_not_empty!

  unless TestData::VerifiesDumpsAreLoadable.new.call
    fail "Cannot load schema & data into database '#{TestData.config.database_name}'"
  end

  TestData::LoadsDatabaseDumps.new.call

  if ActiveRecord::Base.connection.migration_context.needs_migration?
    TestData.log.warn "There are pending migrations for database '#{TestData.config.database_name}'. To run them, run:\n\n  $ RAILS_ENV=test_data bin/rake db:migrate\n\n"
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
