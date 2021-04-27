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
      create  config/initializers/test_data.rb
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

#### Running the server (or other commands)

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

Once you have your test data how you want it, it's time to dump the schema and
data to SQL files that can be committed to version control and loaded by your
tests. (It's a little counter-intuitive at first, but the `test_data`
environment and database are only for creating and maintaining your test data,
they're only helpful to your tests when they're loaded in your `test`
environment's database!)

To dump your SQL files, just run:

```
$ bin/rake test_data:dump
```

This will dump:

* Schema DDL in `test/support/test_data/schema.sql`
* Test data in `test/support/test_data/data.sql`
* Non-test data (`ar_internal_metadata` and `schema_migrations`) in
  `test/support/test_data/non_test_data.sql`

(More details and configuration notes can be found in the [Rake task's
reference](https://github.com/testdouble/test_data#test_datadump).)

Once you've made your initial set of dumps, briefly inspect them and—if they
look good—commit them. (And if the files are gigantic or full of noise, [read
this](#are-you-sure-i-should-commit-these-sql-dumps-theyre-way-too-big)).

### Phase 4: Using your data in your tests

Finally, now that you've dumped the contents of your `test_data` database, you
can start using the burgeoning universe of realistically-created test data in
your tests!

To accomplish this, you'll likely want to add hooks to run before & after each
test case—first to load your test data into the `test` database, and then to
rollback to undo any changes made by the test. The `test_data` gem helps you
accomplish this by offering [TestData.load](#testdataload) and
[TestData.rollback](#testdatarollback) methods.

If you're using (Rails' default) Minitest and want to include your test data
with every test, you can add these hooks to `ActiveSupport::TestCase`:

```ruby
class ActiveSupport::TestCase
  def setup
    TestData.load
  end

  def teardown
    TestData.rollback
  end
end
```

If you use [RSpec](https://rspec.info), you can accomplish the same thing with
global `before(:each)` and `after(:each)` hooks in your `rails_helper.rb` file:

```ruby
RSpec.configure do |config|
  config.before(:each) do
    TestData.load
  end

  config.after(:each) do
    TestData.rollback
  end
end
```

That should be all you need to have access to your test data in all of your
tests, along with the speed and data integrity of wrapping those tests in an
always-rolled-back transaction. For more information and to learn how all this
works, see the [API reference](#api-reference).

If you have existing tests that depend on factories or fixtures, or if you don't
want all Rails-aware tests to have access to your test data, you might want to
consider splitting your tests into multiple suites. ([More
here](#we-already-have-thousands-of-tests-that-depend-on-rails-fixtures-or-factory_bot-can-we-start-using-test_data-without-throwing-them-away-and-starting-over).)

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
  data. This new environment file loads your development environment's
  configuration and disables migration schema dumps so that you can run
  migrations of your `test_data` database without affecting your app's
  `schema.rb` or `structure.sql`.

* `config/initializers/test_data.rb` - Calls `TestData.config` with an empty
  block and comments documenting the (at install-time) available options and
  their default configuration values

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

The [generated `config/initializers/test_data.rb`
initializer](/lib/generators/test_data/initializer_generator.rb) will include a
call to `TestData.config`, which takes a block that yields the mutable
configuration object (similar to Rails' application config):

```ruby
TestData.config do |config|
  # Where to store SQL dumps of the test_data database schema
  # config.schema_dump_path = "test/support/test_data/schema.sql"

  # Where to store SQL dumps of the test_data database test data
  # config.data_dump_path = "test/support/test_data/data.sql"

  # Where to store SQL dumps of the test_data database non-test data
  # config.non_test_data_dump_path = "test/support/test_data/non_test_data.sql"

  # Tables whose data shouldn't be loaded into tests.
  #   ("ar_internal_metadata" and "schema_migrations" are always excluded)
  # config.non_test_data_tables = []

  # Tables whose data should be excluded from all dumps (does not affect schema DDL)
  # config.dont_dump_these_tables = []

  # Tables whose data should be truncated by TestData.truncate
  #   If left as `nil`, all tables inserted into by the SQL file at
  #   `data_dump_path` will be truncated
  # config.truncate_these_test_data_tables = nil

  # Log level (valid values: [:debug, :info, :warn, :error, :quiet])
  # Can also be set with env var TEST_DATA_LOG_LEVEL
  # config.log_level = :info
end
```

### TestData.load

This is the method designed to be used by your tests to load your test data
dump into your test database so that your tests can depend on the data.

#### Loading with the speed & safety of transaction savepoints

For the sake of speed and integrity, `TestData.load` is designed to be rolled
back to the point _immediately after_ importing your test data between each
test—that way your test suite only pays the cost of importing the SQL file once,
but each of your tests can enjoy a clean slate on which to build their own
scenarios without fear of data inserted by one test polluting the next. (This is
similar to how Rails fixtures'
[use_transactional_tests](https://edgeguides.rubyonrails.org/testing.html#testing-parallel-transactions)
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

#### Loading without transactions

For most cases, we strongly recommend using the default transactional testing
strategy, both because it's faster and because it reduces incidents of test
pollution. However, if you need your test data to be loaded by multiple
processes, over multiple connections, and so on, you'll need to commit the test
data to your test database during your test run. (Cleaning up after each test
run becomes an exercise for the reader; a lot of folks use and like
[database_cleaner](https://github.com/DatabaseCleaner/database_cleaner) for
this.

To load the test data without transactions, simply call
`TestData.load(transactions: false)`. You might imagine something like this if
you were loading the data just once for the full run of a test suite:

```ruby
DatabaseCleaner.strategy = :truncation

RSpec.configure do |config|
  config.before :all do
    TestData.load(transactions: false)
  end

  config.after :all do
    DatabaseCleaner.clean
  end
end
```

Note that subsequent calls won't try to detect whether the data is already
loaded and will try to re-insert the data, which will almost invariably result
in primary key conflicts.

### TestData.rollback

#### Rolling back to after the data was loaded between tests

When `TestData.rollback` is passed no arguments or called more explicitly as
`TestData.rollback(:after_data_load)`, this method will rollback to the
`:after_data_load` transaction savepoint taken immediately after the SQL dump
was loaded. As a result, it is intended to be run after each test (e.g. in an
`after_each` or `teardown`), so that the next test will have access to your test
data and a clean slate to start from, free of any pollution in the database.

#### Rolling back to _before_ test data was loaded

If some tests rely on data loaded by `TestData.load` and you're writing a test
that depends on that data _not being there_, you probably want to call
[TestData.truncate](#testdatatruncate). But if that doesn't work for your needs,
you can also use this  method to rewind to the save point just _before_ the test
data was loaded with `TestData.rollback(:before_data_load)`.

**⚠️ Warning: ⚠️** Repeatedly rolling back to `:before_data_load` can get
expensive! If your test suite calls `TestData.rollback(:before_data_load)`
multiple times, it's likely you're re-loading your (possibly large) SQL file of
test data more times than is necessary. Consider using
[TestData.truncate](#testdatatruncate) to achieve a clean slate instead;
otherwise, it might be faster to partition your test suite so that all the tests
that rely on this test data are run as a group (as opposed to in a fully random
or arbitrary order). This may be accomplished by configuring your test runner or
else by running separate test commands—one for each source of test data.

#### Rolling back to after test data was truncated

If some of your tests call [TestData.truncate](#testdatatruncate) to clear out
your test data, then you may want to run
`TestData.rollback(:after_data_truncate))` to rewind your test database's state
to when those tables were first loaded. 

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


### But we use and like `factory_bot` and so I am inclined to dislike everything about this

If you use `factory_bot` and all of these are true:

* Your integration tests are super fast and not getting significantly slower
  over time

* A single change to a factory rarely results in test failures that (rather than
  indicating a bug in the production code) instead require that each of those
  tests be updated to get back to a passing state

* The number of associated records generated between your most-used, default
  factories are representative of production data, as opposed to just generating
  "one of everything" (i.e. you don't have multiple `User` factories with names
  like `:user` and `:basic_user` and `:lite_user` and
  `:plain_user_no_associations_allowed`)

* Your most-invoked factories generate realistic attributes, as opposed to
  representing the sum-of-all-edge-cases with every boolean flag enabled and
  optional field filled

If none of these things are true, then congratulations! You are using
`factory_bot` the right way! (And if you've been using it extensively for more
than two years and can honestly say that all of the above is true, please
[contact Justin](mailto:justin@testdouble.com), because he would love to meet
with you, as he's never seen a team accomplish this).

However, if any of the above might be reasonably used to describe your test
suite's use of `factory_bot`, these are the sorts of failure modes that
`test_data` was designed to address and we hope you'll consider it with an open
mind. At the same time, we acknowledge that large test suites can't be rewritten
and migrated to a different source of test data overnight—nor should they be!

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

You certainly _could_ include Rails fixtures, `factory_bot`, and `test_data` in
the same test cases, but we wouldn't recommend it. Integration tests inevitably
become coupled to the data that's available to them, and if a test is written in
the presence of fixtures, records created by a factory, and a `test_data` SQL
dump, it is likely to become dependent on all three, even unintentionally. This
would result in the test having more ways to fail than necessary and make it
harder to simplify your test data strategy and dependencies later. That's why we
recommend segregating integration tests that use different types of test data.

One approach is to define different types of tests based on different data
sources (like [this
test](https://github.com/testdouble/test_data/blob/master/example/test/integration/mode_switching_demo_test.rb)
in the example app). However, this strategy is insufficient, because a naive
approach would likely result in superfluous resource-intensive [reloading of the
test data SQL by calling `TestData.load` and
TestData.rollback(:before_data_load)](https://github.com/testdouble/test_data#rolling-back-to-before-the-data-was-loaded)
numerous times in a single test run. As a result, you should strive to find a
solution that will partition the tests by their test data source, so they can
each take advantage of the speed & safety of running each test in an
always-rolled-back transaction.

### Why can't I save multiple database dumps to cover different scenarios?

For the same reason you (probably) don't have multiple production databases: the
fact that Rails apps are monolithic and everything is consolidated is a big
reason why they're so productive and comprehensible. This gem is not
[VCR](https://github.com/vcr/vcr) for databases. If you were to design separate
test data dumps for each feature, team, or concern, you'd also have more moving
parts to maintain, more complexity to communicate, and more pieces to fall into
disrepair.

By having a single `test_data` database that grows up with your application just
like `production` does—with both having their schemas and data migrated
incrementally over time—your integration tests that depend on `test_data` will
have an early opportunity to catch bugs that otherwise wouldn't be found until
they were deployed into a long-lived environment like staging or (gasp!)
production itself.

### Are you sure I should commit these SQL dumps? They're way too big!

If the dump files generated by `test_data:dump` are absolutely massive, consider the cause:

1. If you inadvertently created more data than necessary, you might consider
   resetting (or rolling back) your changes and making another attempt at
   generating a more minimal set of test data

2. If certain tables have a lot of records but aren't very relevant to your
   tests (e.g. audit logs), you might consider either of these options:

    * Add those tables to the `config.non_test_data_tables` configuration array,
      where they'd still be committed to git, but wouldn't loaded by your tests

    * Exclude data from those tables entirely by adding them to the
      `config.dont_dump_these_tables` array, but be sure to validate that you
      can reinitialize your `test_data` database without them using
      `test_data:load`

3. If the dumps are _necessarily_ really big (some apps are complex!), consider
   looking into [git-lfs](https://git-lfs.github.com) for tracking them without
   impacting the size and performance of the git slug. (See [GitHub's
   documentation](https://docs.github.com/en/github/managing-large-files/working-with-large-files)
   on what their service supports)

Beyond these options, we'd also be interested in a solution that filtered data
in a more granular way than ignoring entire tables. If you have a proposal you'd
be interested in implementing, [suggest it in an issue](/issues/new)!

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

