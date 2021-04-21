# The `test_data` gem

## Getting started

### Phase 1: Installing and initializing `test_data`

#### Adding the gem

First, add `test_data` to your Gemfile. Either include it in all groups or
ensure it's available to the `:development`, `:test`, and (all new!)
`:test_data` gem groups:

```ruby
group :development, :test, :test_data do
  gem "test_data"
  # … other gems
end
```

Since the `test_data` environment is designed to be interacted with a running
server, it may make sense to add `:test_data` to any existing group lists
that contain `:development`.

#### Initializing configuration and database

The gem ships with a number of Rake tasks, including a task `test_data:install`
task that will both generate configuration and initialize a test data database:

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
the app and persisting the database. Rather than try to imitate realistic data
(which only grows more difficult as your models and their associations increase
in complexity) using factories and fixtures, your test_data database will always
be realistic because your application will have generated it!

### Phase 2: Interactively creating some test data

After your database is initialized comes the fun part! Start up your application
server in the new environment and create some records by interacting with your
system.

#### Running the server and other commands

Because `test_data` crates a full-fledged Rails environment, you can run any
number of Rails commands or Rake tasks against its database by setting
`RAILS_ENV=test_data` in your shell environment or with each command:

```
$ RAILS_ENV=test_data bin/rails server
```

(The same hoilds for `RAILS_ENV=test_data bin/webpack-dev-server`,
`RAILS_ENV=test_data bin/rake db:migrate`, and so on)

_[Aside: If you have any hiccups in this step, please [open an
issue](/issues/new) to let us know—we may be able to improve our
`test_data:configure` task to be more thorough!]_

After starting the server and getting up-and-running, spend a little time
thoughtfully using your app to generate enough data to be _representative_ of
what would be needed to test your system's main behaviors (e.g. one user in each
role, one type of each order, etc.), while still being _minimal_ enough that the
universe of data will be comprehensible & memorable to yourself and your
teammates. Your future tests will become coupled to this data, even as both
evolve in the future, so it's worth resetting and starting over until you get
things how you want them.



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
  test data database that's intended to be used to create and dump your
  interactively-created test data. The file will simply load your development
  environment's configuration by default, while also illustrating the
  gem's own configuration options and disabling migration schema dumps.

* `config/database.yml` - This generator adds a new `test_data` section of your
  database configuration, named with the same scheme as your other databases. If
  your configuration resembles Rails' generated database.yml and has a working
  `&default` alias, then this should "just work"

* `config/webpacker.yml` - The gem has nothing to do with web assets or
  webpacker, but webpacker will display some prominent warnings or errors if it
  is loaded without a configuration entry for the currently-running environment,
  so this generator defines an alias based on your development section and then
  defines `test_data` as extending it

### test_data:initialize

This task gets your local test_data database up-and-running, either from a set
of dump files (if they already exist), or by loading your schema and running
your seed file. Specifically:

1. Creates the `test_data` environment's database, if it doesn't already exist
2. Fails if the database is non-empty to preserve data integrity (run
  `test_data:drop_database` first if you need to drop it)
3. Checks to see f a dump of the test_data database already exists (by default,
  stored in `test/support/test_data/`)
  * If dumps do exist, it invokes `test_data:load` to load it into the database
  * Otherwise, it invokes the task `db:schema:load` and `db:seed` (similar to
    how `db:setup` does)

### test_data:dump

This task is designed to be run after you've created or updated your test data
and you want to persist and commit it. The task creates several plain SQL dumps
from your test_data environment's database:

* A schema-only dump, by default in `test/support/test_data/schema.sql`
* A data-only dump of records you want to be loaded in your tests, by default in
  `test/support/test_data/data.sql`
* A data-only dump of records that you *don't* want loaded in your tests in
  `test/support/test_data/non_test_data.sql` (by default, this includes Rails'
  internal tables: `["ar_internal_metadata", "schema_migrations"]`)

### test_data:load

This task is similar to `test_data:initialize`, but will only load from SQL
dumps, it won't try loading a fresh schema in their absence:

1. Verify the test_data environment's datbase is empty (creating it if it
   doesn't exist)
2. Verify that your schema, test data, and non-test data SQL dumps are all
   readable
3. Load the dumps into the test_data database
4. Warn you if you their are pending migrations that haven't been run yet

### test_data:create_database

Will create the `test_data` environment's database. This task also enhances the
`db:create` task, so running that task should create the databases for
`development`, `test`, and `test_data`.

### test_data:drop_database

Will drop the `test_data` environment's database. This task also enhances the
`db:drop` task, so running that task should drop the databases for
`development`, `test`, and `test_data`.

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

This is the method designed to be used by your tests to load data from your data
dump into your test database, so that your tests can depend on the data. It is
also designed to be rolled back after each test (so that the test data is only
loaded into the database once).

The method uses ActiveRecord's transaction API to participate in its
nested-transaction strategies (which relies on Postgres
[savepoints](https://www.postgresql.org/docs/current/sql-savepoint.html) under
the hood).

To help think through the method's behavior, the method nicknames its
transactions `:before_data_load` and `:after_data_load`

1. If `:after_data_load` is already open, the method does nothing
2. Starts transaction `:before_data_load` if it's not already open
3. Executes the SQL in the test data dump file into the test database
4. Starts transaction `:after_data_load`

This way, your tests can call `TestData.load` in every `setup`
method or `before_each` hook and only import the data if necessary

### TestData.rollback(to: :after_data_load)

You can call `TestData.rollback` to rollback a transaction savepoint that was
made immediately after the SQL dump was loaded, and is intended to be run
between each test (most often in a `teardown`, `after_each`, or equivalent).

Sometimes, you'll want to rollback to _before_ the test database was loaded at
all (for example, if you have some tests that use a different test data source
like fixtures or factories, or perhaps where it simply makes more sense to have
an empty database as a test's starting point). For these cases, you can call
`TestData.rollback(to :before_data_load)`. [Warning: re-loading a large SQL file
repeatedly during a test suite is resource-intensive, so consider partitioning
these tests into separately run test suites or otherwise ensuring that you
aren't inadvertently loading and rolling back your test data more than
necessary]

TODO can i delete all this??
Whether you should call it depends on whether your test runner has something
else invoking a rollback after each test. For example:

* **You're using Minitest & Rails' `use_transaction_tests` is `true` (the
  default) -** In this case, Rails will [issue one rollback at the end of every
  test](https://github.com/rails/rails/blob/291a3d2ef29a3842d1156ada7526f4ee60dd2b59/activerecord/lib/active_record/test_fixtures.rb#L168),
  which is likely all you need, so running `TestData.rollback` is probably
  unnecessary
  ([example](https://github.com/testdouble/test_data/blob/master/example/test/test_helper.rb#L18-L28))

* **You're using Minitest & Rails' `use_transaction_tests` is `false` -** In
  this case, Rails won't be rolling back anything between tests, so you should
  call `TestData.rollback` in a `teardown` method
  ([example](https://github.com/testdouble/test_data/blob/master/example/test/test_helper.rb#L18-L28))
/TODO

## Assumptions

The `test_data` gem is still brand new and doesn't cover every use case just
yet. Here are some existing assumptions and limitations:

* You're using Postgres
* You're using Rails 6 or higher
* Your app does not use [multi-database
  support](https://guides.rubyonrails.org/active_record_multiple_databases.html)
* The gem only supports one test data environment and dump per application
* Your app has Rails-generated `bin/rake` and `bin/rails` binstubs and that they
  are in working
* The database.yml generator assumes you have a working `&default` alias to base
  the test_data database configuration on
* All tests have the same setting for `use_transactional_tests` (whether true or
  false), or else separates test runs so as to not intermingle them.

## Fears, Uncertainties, and Doubts

### How will I handle merge conflicts with lots of feature branches all adding to the `test_data` database dumps?

### We already have thousands of tests that depend on Rails fixtures or [factory_bot](https://github.com/thoughtbot/factory_bot), can we start using `test_data` without throwing them away and starting over!

Yes! A little-known secret of testing is that "test suites" are nothing more
than directories and you're allowed to make as many of them as you want (see
this [talk on test suite
design](https://blog.testdouble.com/talks/2014-05-25-breaking-up-with-your-test-suite/)
for more).

You can, of course, include factories, fixtures, and `test_data` in the same
test cases, but it'd probably get confusing in a hurry—especially if the same
tests came to depend on more than one test data source. As a result, we'd
recommend splitting them apart somehow.

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

