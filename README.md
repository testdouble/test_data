# The `test_data` gem

## What/Why

TODO

## Getting started guide

### Phase 1: Installing and initializing `test_data`

#### Adding the gem

First, add `test_data` to your Gemfile. Either include it in all groups or
ensure it's available to the `:development`, `:test`, and (all new!)
`:test_data` gem groups:

```ruby
group :development, :test, :test_data do
  gem "test_data"
  # … other gems available to development & test
end
```

Since the `test_data` environment is designed to be interacted via a running
server, the `:test_data` gem group should probably include everything that's
available to the `:development` group.

#### Configuring the gem and initializing the database

The gem ships with a number of Rake tasks, including `test_data:install`, which
both generate configuration and initialize a test data database:

```
$ bin/rake test_data:install
```

This should output something like:

```
      create  config/environments/test_data.rb
      insert  config/database.yml
      insert  config/webpacker.yml
      insert  config/webpacker.yml
Created database 'yourappname_test_data'
 set_config
------------

(1 row)
````

As will become clear soon, the purpose of the `test_data` database is to be an
interactive sandbox in which to generate realistic test data by actually using
your app and then dumping the resulting state of your database for later use by
your tests. Rather than try to imitate realistic data using factories and
fixtures (a task which only grows more difficult as your models and their
associations increase in complexity), your `test_data` database will always be
realistic because your application will have generated it!

### Phase 2: Interactively creating some test data

Now that your database is initialized comes the fun part! It's time to start up
your server in the new environment and create some records by interacting with
your system.

#### Running the server and other commands

To run your server against the new `test_data` database:

```
$ RAILS_ENV=test_data bin/rails server
```

Because `test_data` crates a full-fledged Rails environment, you can run any
number of Rails commands or Rake tasks against its database by setting
`RAILS_ENV=test_data` in your shell environment or with each command (e.g.
`RAILS_ENV=test_data bin/webpack-dev-server`, `RAILS_ENV=test_data bin/rake
db:migrate`, etc.)

_[Aside: If you have any hiccups in getting your server to work, please [open an
issue](/issues/new) to let us know—we may be able to expand the
`test_data:configure` task to be more thorough!]_

#### Create test data by using your app

You'll know how to do this part better than us; it's your app, after all.

Spend a little time thoughtfully using your app to generate enough data to be
_representative_ of what would be needed to test your system's main behaviors
(e.g. one user in each role, one type of each order, etc.), while still being
_minimal_ enough that the universe of data will be comprehensible & memorable to
yourself and your teammates. Your future tests will become coupled to this data
for the long-term as your application grows and evolves, so it's worth resetting
and starting this step over until you get your system state how you want it.

### Phase 3: Dumping your test data

TODO
dump, commit

### Phase 4: Using your data in your tests

TODO

### Phase 5: Keeping your test data up-to-date

migrate
 - link to blog post on data migrations
interact
commit

## Rake Task Reference

### test_data:install

A meta-task that runs `test_data:configure` and `test_data:initialize`.

### test_data:configure

This task runs several generators:

* `config/environments/test_data.rb` - As you may know, Rails ships with
  `development`, `test`, and `production` environments defined by default. But
  you can [actually define custom
  environments](https://guides.rubyonrails.org/configuring.html#creating-rails-environments),
  too! This gem adds a new `test_data` environment intended to be paired with a
  test data database that's intended to be used to create and dump your test
  data. This new environment file does three things (1) load your development
  environment's configuration (2) call `TestData.config`, (3) disable migration
  schema dumps so that you can run migrations of your `test_data` database
  without affecting your `schema.rb` or `structure.sql`.

* `config/database.yml` - This generator adds a new `test_data` section of your
  database configuration, named with the same scheme as your other databases
  (e.g. `yourapp_test_data`). If your configuration resembles Rails' generated
  database.yml and has a working `&default` alias, then this should "just work"

* `config/webpacker.yml` - The gem has nothing to do with web assets or
  webpacker, but webpacker will display some prominent warnings or errors if it
  is loaded without a configuration entry for the currently-running environment,
  so this generator defines an alias based on your development section and then
  defines `test_data` as extending it

### test_data:initialize

This task gets your local `test_data` database up-and-running, either from a set
of dump files (if they already exist), or by loading your schema and running
your seed file. Specifically:

1. Creates the `test_data` environment's database, if it doesn't already exist

2. Ensures the database is non-empty to preserve data integrity (run
   `test_data:drop_database` first if you need to drop it)

3. Checks to see if a dump of the database already exists (by default, stored in
   `test/support/test_data/`)

    * If dumps do exist, it invokes `test_data:load` to load them into the
      database

    * Otherwise, it invokes the task `db:schema:load` and `db:seed` (similar to
      the `db:setup` task)

### test_data:dump

This task is designed to be run after you've created or whenever you've updated
your test data and you want to run tests against it. The task creates several
plain SQL dumps from your test_data environment's database:

* A schema-only dump, by default in `test/support/test_data/schema.sql`

* A data-only dump of records you want to be loaded in your tests, by default in
  `test/support/test_data/data.sql`

* A data-only dump of records that you *don't* want loaded in your tests in
  `test/support/test_data/non_test_data.sql` (by default, this includes Rails'
  internal tables: `ar_internal_metadata` and `schema_migrations`)

It may feel wrong to commit SQL dumps to version control, but all of these files
are designed to be committed and tracked with the rest of your repository.

### test_data:load

This task will load your SQL dumps, into your `test_data` database by:

1. Verifying the test_data environment's datbase is empty (creating it if it
   doesn't exist)

2. Verifying that your schema, test data, and non-test data SQL dumps are all
   readable

3. Loading the dumps into the test_data database

4. Warning you if you there are pending migrations that haven't been run yet

If there are pending migrations, you'll probably want to run them and then
re-dump and commit your test data so that they're all up-to-date:

```
$ RAILS_ENV=test_data bin/rake db:migrate
$ bin/rake test_data:dump
```

### test_data:create_database

This task will create the `test_data` environment's database if it does not
already exist. This task also enhances the `db:create` task so that
`test_data` is also created alongside `development` and `test`.

### test_data:drop_database

This task will drop the `test_data` environment's database if it exists. This
task also enhances the `db:drop` task so that `test_data` is also dropped
alongside `development` and `test`.

## API Reference

### TestData.config

The generated `config/environments/test_data.rb` file will include a call to
`TestData.config`, which takes a block that yields the mutable configuration
object (similar to Rails' application config):

```ruby
TestData.config do |config|
  # Where to store SQL dumps of the test_data database schema
  # config.schema_dump_path = "test/support/test_data/schema.sql"

  # Where to store SQL dumps of the test_data database test data
  # config.data_dump_path = "test/support/test_data/data.sql"

  # Where to store SQL dumps of the test_data database non-test data
  # config.non_test_data_dump_path = "test/support/test_data/non_test_data.sql"

  # Tables whose data shouldn't be loaded into tests
  # config.non_test_data_tables = ["ar_internal_metadata", "schema_migrations"]
end
```

### TestData.load

This is the method designed to be used by your tests to load your test data
dump into your test database so that your tests can depend on the data.

For the sake of speed and integrity, `TestData.load` is designed to be rolled
back to the point _immediately after_ importing your test data between each
test—that way your test suite only pays the cost of importing the SQL file once,
but each of your tests can enjoy a clean slate on which to build their own
scenarios without fear of data inserted by one test polluting the next. (This is
similar to how Rails fixtures'
`[use_transactional_tests](https://edgeguides.rubyonrails.org/testing.html#testing-parallel-transactions)`
option works.) The `load` method accomplishes this by using ActiveRecord's
transaction API to participate in Rails nested-transaction state management
(which ultimately relies on Postgres
[savepoints](https://www.postgresql.org/docs/current/sql-savepoint.html) under
the hood).

To help think through the method's behavior, the method nicknames its
transactions `:before_data_load` and `:after_data_load`

1. If `:after_data_load` is already open, the method does nothing
2. Starts transaction `:before_data_load` if it's not already open
3. Executes the SQL in the test data dump file into the test database
4. Starts transaction `:after_data_load`

Additionally, if something else triggers a rollback (such that your test data is
still present but the `after_data_load` savepoint has been rolled back),
`test_data` will also write a note in `ar_internal_metadata` to detect the issue
and create a new `:after_data_load` savepoint. This way, your tests can call
`TestData.load` in every `setup` method or `before_each` hook and be confident
that the data will only be loaded if necessary.

### TestData.rollback

#### Rolling back to after the data was loaded between tests

When `TestData.rollback` is passed no arguments or called more explicitly as
`TestData.rollback(:after_data_load)`, this method will rollback to the
`:after_data_load` transaction savepoint taken immediately after the SQL dump
was loaded. As a result, it is intended to be run after each test (e.g. in an
`after_each` or `teardown`), so that the next test will have access to your test
data and a clean slate to start from, free of any pollution in the database.

#### Rolling back to _before_ the data was loaded

You probably won't need to do this, but you can also call this method to
rollback to the point just _before_ the test data was loaded with
`TestData.rollback(:before_data_load)`. Not every test suite will need to do
this, but places where you might want to:

* In an `after_all` hook (while not explicitly necessary, it's reasonable to
  desire the test process rollback any open transactions before exiting)

* When various tests in a suite use different sources of test data (e.g.
  factories or fixtures) and you need to keep them separated, you might want to
  ensure any test data inserted by this gem is rolled back prior to the start of
  other types of tests ([example
  test](https://github.com/testdouble/test_data/blob/master/example/test/integration/mode_switching_demo_test.rb))

* In more "unit-ish" tests that would more clearly express their intent if they
  instantiated their own test data and for which success might depend on the
  database being otherwise empty

**⚠️ Warning: ⚠️** If your test suite calls `TestData.rollback(:before_data_load)`
multiple times, it's likely you're re-loading your (possibly large) SQL file of
test data more times than is necessary. Consider
partitioning your test suite so that all the tests that rely on
this test data are run as a group. This may be accomplished by configuring your
test runner or else by running multiple test commands.

## Assumptions

The `test_data` gem is still brand new and doesn't cover every use case just
yet. Here are some existing assumptions and limitations:

* You're using Postgres

* You're using Rails 6 or higher

* Your app does not rely on Rails' [multi-database
  support](https://guides.rubyonrails.org/active_record_multiple_databases.html)

* The gem only supports one test data environment and dump per application

* Your app has Rails-generated `bin/rake` and `bin/rails` binstubs and that they
  are in working order

* The `database.yml` generator assumes you have a working `&default` alias from
  which to extend the `test_data` database configuration

## Fears, Uncertainties, and Doubts

### How will I handle merge conflicts in these SQL files if I have lots of people working on lots of feature branches all adding to the `test_data` database dumps?

In a word: thoughtfully!

First, in terms of expectations-setting, you should expect your test data SQL
dumps to churn at roughly the same rate as your schema does.

Once an application's initial development stabilizes, the rate of schema changes
tends to slow dramatically. If your schema isn't changing frequently and you're
not running data migrations against production very often, it might make the
most sense to let this concern present itself as a real problem before
attempting to solve it, as you're likely to find that other best-practices
around collaboration and deployment (frequent merges, continuous integration,
coordinating breaking changes) will also manage this risk. The reason that the
dumps are stored as plain SQL (aside from the fact that git's text compression
is very good) is to make merge conflicts with other branches feasible, if not
entirely painless.

However, if your app is in the very initial stages of development and you're
making breaking changes to your schema very frequently, our best advice is to
hold off a bit on writing _any_ integration tests, as they'll be more likely to
frustrate your ability to rapidly iterate while also never being up-to-date long
enough to be relied upon to detect bugs. Once you you have a reasonably stable
feature working end-to-end, that's a good moment to start adding integration
tests (and thus pulling in a test data gem like this one to help you).

### We already have thousands of tests that depend on Rails fixtures or [factory_bot](https://github.com/thoughtbot/factory_bot), can we start using `test_data` without throwing them away and starting over!

Yes! A little-known secret of testing is that "test suites" are nothing more
than directories and you're allowed to make as many of them as you want (see
this [talk on test suite
design](https://blog.testdouble.com/talks/2014-05-25-breaking-up-with-your-test-suite/)
for more).

You can, of course, include Rails fixtures, `factory_bot`, and `test_data` in
the same test cases, but it'd probably get confusing in a hurry—especially if
the same tests came to depend on more than one test data source. As a result,
we'd recommend splitting them apart somehow.

Suppose you have this in your `test_helper.rb`:

``` ruby
class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
end
```

You might consider breaking out two subclasses, one that includes the factory
method, and one that calls `TestData.load`:

```ruby
class FactoryBotTestCase < ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
end

class TestDataTestCase < ActiveSupport::TestCase
  self.use_transactional_tests = false
  def setup
    TestData.load
  end

  def teardown
    TestData.rollback
  end
end
```

Alternatively, you could pull that test data election into a custom class method
so that each existing test file would declare what source of test data they use,
and you could gradually migrate your tests over time:

```ruby
class ActiveSupport::TestCase
  def self.test_data_type(mode)
    if mode == :factory_bot
      include FactoryBot::Syntax::Methods
    else
    end
  end
end

class TestDataTestCase < ActiveSupport::TestCase
  self.use_transactional_tests = false
  def setup
    TestData.load
  end

  def teardown
    TestData.rollback
  end
end
```

### Why can't I save multiple database dumps for different scenarios?

For the same reason you (probably) don't have multiple production databases: the
fact that Rails apps are monolithic and consolidated is a big reason that
they're so productive and comprehensible. This gem is not
[VCR](https://github.com/vcr/vcr) for databases. If you were to design
separate test data dumps for each feature, team, or concern, you'd also have
more moving parts to manage, more complexity to communicate, and more things to
fall into disrepair.




### But tests should stand on their own, not coupled to some invisible, shared state!

The idea of building your `test_data` interactively and then coupling your tests
to random names and dates you entered into a form may feel


missing out on one of the main benefits of the `test_data` gem:


## Code of Conduct

This project follows Test Double's [code of
conduct](https://testdouble.com/code-of-conduct) for all community interactions,
including (but not limited to) one-on-one communications, public posts/comments,
code reviews, pull requests, and GitHub issues. If violations occur, Test Double
will take any action they deem appropriate for the infraction, up to and
including blocking a user from the organization's repositories.

