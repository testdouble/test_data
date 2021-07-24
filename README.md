# The `test_data` gem

**HEADS UP: 0.2.0 made a whole bunch of breaking changes to the public API and
we haven't finished rewriting the README yet. Please bear with us while we work
through it. 🙇**

`test_data` does what it says on the tin: it provides a fast & reliable system
for managing your Rails application's test data.

The gem serves as both an alternative to
[fixtures](https://guides.rubyonrails.org/testing.html#the-low-down-on-fixtures)
& [factory_bot](https://github.com/thoughtbot/factory_bot), as well a broader
workflow for building test suites that will scale gracefully as your application
grows in size and complexity.

What it does:

* Establishes a fourth Rails environment (you can [define custom Rails
  environments](https://guides.rubyonrails.org/configuring.html#creating-rails-environments)!)
  named `test_data`, which you'll use to create a universe of data for your
  tests by simply running and using your application. No Ruby DSL, no YAML
  files, no precarious approximations of realism: **real data created by your
  app**

* Exposes a simple API for ensuring that each of your tests will against
  pristine data, whether the test depends on test_data, an empty database, or
  Rails fixtures

* Safeguards your tests from flaky failures and supercharges your build by
  providing a sophisticated transaction manager that isolates each test while
  ensuring your data is only loaded once

If you've despaired over the seeming inevitability that all Rails test suites
will eventually grow to become slow, incomprehensible, and brittle, then this
gem is for you! And even if you're [a factory_bot
fan](https://twitter.com/searls/status/1379491813099253762?s=20), we hope you'll
be open to the idea that [there might be a better way](
#but-we-use-and-like-factory_bot-and-so-i-am-inclined-to-dislike-everything-about-this-gem).

_[Full disclosure: because the gem is still brand new, it makes a number of
[assumptions](#assumptions) and may not work for every project just yet.]_

## Documentation

This gem requires a lot of documentation—not because `test_data` does a lot of
things, but because managing one's test data is an inherently complex task. If
one reason Rails apps chronically suffer from slow tests is that other
approaches oversimplify test data management, it stands to reason that any
discomfort caused by `test_data`'s scope may not indicate _unnecessary
complexity_ so much as highlight how much acclimatization is needed to adopt the
necessary diligence to achieve fast, isolated tests that scale with your
application.

1. [Getting Started Guide](#getting-started-guide)
    1. [Install and initialize `test_data`](#step-1-install-and-initialize-test_data)
    2. [Create some test data](#step-2-create-some-test-data)
    3. [Dump your `test_data` database](#step-3-dump-your-test_data-database)
    4. [Load your data in your tests](#step-4-load-your-data-in-your-tests)
    5. [Keeping your test data up-to-date](#step-5-keeping-your-test-data-up-to-date)
2. [Factory & Fixture Interoperability Guide](#factory--fixture-interoperability-guide)
    * [Using `test_data` with `factory_bot`](#using-test_data-with-factory_bot)
    * [Using `test_data` with Rails fixtures](#using-test_data-with-rails-fixtures)
3. [Rake Task Reference](#rake-task-reference)
    * [test_data:install](#test_datainstall)
    * [test_data:configure](#test_dataconfigure)
    * [test_data:verify_config](#test_dataverify_config)
    * [test_data:initialize](#test_datainitialize)
    * [test_data:dump](#test_datadump)
    * [test_data:load](#test_dataload)
    * [test_data:create_database](#test_datacreate_database)
    * [test_data:drop_database](#test_datadrop_database)
4. [API Reference](#api-reference)
    * [TestData.config](#testdataconfig)
    * [TestData.uses_test_data](#testdatauses_test_data)
    * [TestData.uses_clean_slate](#testdatauses_clean_slate)
    * [TestData.prevent_rails_fixtures_from_loading_automatically!](#testdataprevent_rails_fixtures_from_loading_automatically)
    * [TestData.uses_rails_fixtures(self)](#testdatauses_rails_fixtures)
    * [TestData.insert_test_data_dump](#testdatainsert_test_data_dump)
5. [Assumptions](#assumptions)
6. [Fears, Uncertainties, and Doubts](#fears-uncertainties-and-doubts) (Q & A)
7. [Code of Conduct](#code-of-conduct)
8. [Changelog](/CHANGELOG.md)
9. [MIT License](/LICENSE.txt)

## Getting started guide

This guide will walk you through setting up `test_data` in your application. You
might notice that it's more complicated than installing a gem and declaring some
default `Widget` attributes! The hard truth is that designing robust and
reliable test data is an inherently complex problem and takes some thoughtful
planning. There are plenty of shortcuts available, but experience has shown they
tend to collapse under their own weight as your app scales and your team
grows—exactly when having a suite of fast & reliable tests is most valuable.

And if you get stuck or need help as you're getting started, please feel free to
[ask us for help](https://github.com/testdouble/test_data/discussions/new)!

### Step 1: Install and initialize `test_data`

#### Adding the gem

First, add `test_data` to your Gemfile. Either include it in all groups or add
it to the `:development`, `:test`, and (the all new!) `:test_data` gem groups:

```ruby
group :development, :test, :test_data do
  gem "test_data"
  # … other gems available to development & test
end
```

Since the `test_data` environment is designed to be used similarly to
`development` (i.e. with a running server and interacting via a browser), any
gems in your `:development` gem group should likely be included in a
`:test_data` gem group as well.

#### Configuring the gem and initializing the database

The gem ships with a number of Rake tasks, including
[test_data:install](#test_datainstall), which will generate the necessary
configuration and initialize a `test_data` database:

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

Your test_data environment and database are ready for use! You can now run
your server (or any command) to create some test data like so:

  $ RAILS_ENV=test_data bin/rails server

````

The purpose of the `test_data` database is to provide a sandbox in which you
will manually generate test data by playing aroundo with your app. Once you've
craeted enough data to drive tests of your application, `test_data` facilitates
dumping the resulting state of the `test_data` database so that your tests can
load it into the `test` database. Rather than try to imitate realistic data
using factories and fixtures (a task which only grows more difficult as your
models and their associations increase in complexity), your test data will
always be realistic because your real application will have created it!

The database dumps are meant to be committed in git and versioned alongside your
tests over the life of the application. Its schema & data are should be
incrementally migrated over time, just like your production database. (As a
happy side effect of running your migrations against your test data, this means
your `test_data` database may help you identify hard-to-catch migration bugs
early, before being deployed to production!)

### Step 2: Create some test data

Now comes the fun part! It's time to start up your server in the new environment
and create some records by interacting with your system.

#### Running the server (and other commands)

To run your server against the new `test_data` database, set the `RAILS_ENV`
environment variable:

```
$ RAILS_ENV=test_data bin/rails server
```

_[If you're using [webpacker](https://github.com/rails/webpacker), you may also
need to start its development server as well with `RAILS_ENV=test_data
bin/webpack-dev-server`]_

Because `test_data` creates a full-fledged Rails environment, you can run any
number of Rails commands or Rake tasks against its database by setting
`RAILS_ENV=test_data`, either in your shell environment or with each command
(e.g. `RAILS_ENV=test_data bin/rake db:migrate`)

_[Aside: If you experience any hiccups in getting your server to work, please
[open an issue](https://github.com/testdouble/test_data/issues/new) and let us
know—it may present an opportunity to improve the `test_data:configure` task!]_

#### Create test data by using your app

Once the app is running, it's time to generate some test data. You'll know how
to accomplish this step better than anyone—it's your app, after all!

Our advice? Spend a little time thoughtfully navigating each feature of your app
in order to generate enough data to be _representative_ of what would be needed
to test your system's main behaviors (e.g. one `User` for each role, one of each
kind of `Order`, etc.), while still being _minimal_ enough that the universe of
data will be comprehensible & memorable to yourself and your teammates. It can
also help to give new records memorable names, perhaps in keeping with a common
theme (easier to refer to "Rafael" than "TestUser #1").

If you make a mistake, it's perfectly okay to reset the database and start over!
Your future tests will be coupled to this data as your application grows and
evolves, so it's worth taking the time to ensure the foundation is solid. (But
that's not to say everything needs to be perfect; you can always change things
or add more data later—you'll just have to update your tests accordingly.)

### Step 3: Dump your `test_data` database

Once you have your test data how you want it, dump the schema and data to SQL
files:

```
$ bin/rake test_data:dump
```

This will dump three files into `test/support/test_data`:

* Schema DDL in `schema.sql`

* Test data in `data.sql`

* Non-test data (`ar_internal_metadata` and `schema_migrations` by default) in
  `non_test_data.sql`

You probably won't need to, but these paths can be overridden with
[TestData.config](#testdataconfig) method. Additional details can also be found
in the [test_data:dump](#test_datadump) Rake task reference.

Once you've made your initial set of dumps, briefly inspect them and—if
everything looks good—commit them. (And if the files are gigantic or full of
noise, you might find [these ideas
helpful](#are-you-sure-i-should-commit-these-sql-dumps-theyre-way-too-big)).

Does it feel weird to dump and commit SQL files? That's okay! It's [healthy to
be skeptical](https://twitter.com/searls/status/860553435116187649?s=20)
whenever you're asked to commit a generated file! Remember that the `test_data`
environment exists only for creating your test data. Your tests will, in turn,
load the SQL dump of your data into the `test` database, and things will proceed
just as if you'd been loading [Rails' built-in
fixtures](https://guides.rubyonrails.org/testing.html#the-low-down-on-fixtures)
from a set of YAML files—the major difference being that `test_data` databases
are generated through realistic use, whereas fixtures are defined manually in
(sometimes painstaking) YAML.

### Step 4: Load your data in your tests

Now that you've dumped the contents of your `test_data` database, you can start
writing tests that rely on this test data.

To accomplish this, you'll likely want to add hooks to run before & after each
test—first to load your test data and then to rollback any changes made by the
test in order to clear the air for the next test. The `test_data` gem
accomplishes this with its [TestData.uses_test_data](#testdatauses_test_data)
method.

If you're using (Rails' default)
[Minitest](https://github.com/seattlerb/minitest) and want to include your test
data with every test, you could load them in a `setup` hook in
`ActiveSupport::TestCase`:

```ruby
class ActiveSupport::TestCase
  setup do
    TestData.uses_test_data
  end
end
```

If you use [RSpec](https://rspec.info), you can accomplish the same thing with
global `before(:each)` hook in your `rails_helper.rb` file:

```ruby
RSpec.configure do |config|
  config.before(:each) do
    TestData.uses_test_data
  end
end
```

That should be all you need to have access to your test data in each of your
tests! Your tests will also benefit from the speed and data integrity that comes
with covering each test's behavior in an always-rolled-back transaction. For
more information on how all this works, see the [API reference](#api-reference).
If your test suite is already using fixtures or factories and the above hooks
just broke everything, check out our [interoperability
guide](#factory--fixture-interoperability-guide) for help.

If you _don't_ want all of your Rails-aware tests to see this test data (suppose
you have existing tests that use factories instead), you probably want to use
[TestData.uses_clean_slate](#testdatauses_clean_slate) to clear data generated
by this gem out before they run. One way to do that would be to define two test
types:

```ruby
# Tests using data created by `test_data`
class TestDataTestCase < ActiveSupport::TestCase
  setup do
    TestData.uses_test_data
  end
end

# Tests that don't rely on test_data or Rails fixtures:
class CleanSlateTestCase < ActiveSupport::TestCase
  setup do
    TestData.uses_clean_slate
  end
end
```

### Step 5: Keeping your test data up-to-date

Your app relies on its tests and your tests rely on their test data. This
creates a bit of a paradox: creating & maintaining test data is _literally_ a
tertiary concern but simultaneously an inescapable responsibility that will live
with you for the life of your application. That's true whether you use this gem,
`factory_bot`, Rails fixtures, or persist your test data manually inside each
and every test.

But `test_data` stores your data as SQL, as opposed to Ruby or YAML. So
providing a straightforward way to maintain it as your application grows and
your schema evolves is a going concern of this gem.

Fortunately, because your `test_data` database needs to be maintained for the
entire life of your application and because production databases need the same
thing, we already have a fantastic tool for the job: [Rails
migrations](https://guides.rubyonrails.org/active_record_migrations.html). If
your migrations are resilient enough for your production data, they should also
be able to keep your `test_data` database up-to-date.

Whenever you update your schema, migrate your data, or add a feature that
necessitates the creation of more test data, you'll need to update your test
data. Here's a rough outline to updating your `test_data` database:

1. If your local `test_data` database is out-of-date with your latest SQL dump
   files (i.e. if someone has updated the SQL dump and your local Postgres
   database is out of date), drop it with `rake test_data:drop_database`

2. Load your schema & data into the `test_data` database with `rake
   test_data:load`

3. Run any pending migrations with `RAILS_ENV=test_data bin/rake db:migrate`

4. If you need to create any additional data, start up the server
   (`RAILS_ENV=test_data bin/rails s`), just like in [Step
   2](#step-2-create-some-test-data)

5. Export your newly-updated `test_data` database with `rake test_data:dump`

6. Ensure your tests are passing and then commit the resulting SQL files

It's important to keep in mind that your test data SQL dumps are a shared,
generated resource among your team (just like a `structure.sql` or `schema.rb`
file). As a result, if your team doesn't integrate code frequently or if the
test data experiences a lot of churn in coincident feature branches, you'd be
right to be concerned that [the resulting merge conflicts could become
significant](#how-will-i-handle-merge-conflicts-in-these-sql-files-if-i-have-lots-of-people-working-on-lots-of-feature-branches-all-adding-to-the-test_data-database-dumps),
so sweeping changes should be made deliberately and in collaboration with other
contributors.

_[Aside: some Rails teams are averse to using migrations to migrate data as well
as schemas, instead preferring one-off scripts and tasks. You'll have an easier
time of things if you use migrations for both schema and data changes. Here are
some notes on [how to write data migrations
safely](https://blog.testdouble.com/posts/2014-11-04-healthy-migration-habits/#habit-4-dont-reference-models).]_

## Factory & Fixture Interoperability Guide

Let's be real, most Rails apps already have some tests, and most of those test
suites will already be relying on
[factory_bot](https://github.com/thoughtbot/factory_bot) or Rails' built-in
[test
fixtures](https://guides.rubyonrails.org/testing.html#the-low-down-on-fixtures).
While `test_data` is designed to be an alternative to both of these approaches
to managing your test data, it wouldn't be practical to ask a team to rewrite
all their existing tests in order to migrate to a different tool. That's why the
`test_data` gem goes to great lengths to play nicely with your existing tests,
while ensuring each test is wrapped in an isolated and fast always-rolled-back
transaction—regardless if the test depends on `test_data`, factories, fixtures,
all three, or none-of-the-above.

This section will hopefully make it a little easier to incorporate new
`test_data` tests into a codebase that's already using `factory_bot` and/or
Rails fixtures, whether you choose to incrementally rewrite the older tests to
conform to your `test_data` or not.

### Using `test_data` with `factory_bot`

This section will document some thoughts and strategies for introducing
`test_data` to a test suite that's already using `factory_bot`.

#### Getting your factory tests passing after adding `test_data`

Depending on the assumptions your tests make about the state of the database
before you've loaded any factories, it's possible that everything will "just
work" after adding `TestData.uses_test_data` in a before-each hook (as shown in
the [setup guide](#step-4-load-your-data-in-your-tests)). So by all means, try
running your suite after following the initial setup guide and see if the suite
just passes.

If you find that your test suite is failing after adding
`TestData.uses_test_data` to your setup, don't panic! It probably means that you
have test data and factory invocations that are, when combined, violating unique
validations or database constraints. Depending on your situation (e.g. the size
of your test suite, how well you understand the intentions of older tests) you
might try to resolve these errors one-by-one—usually by updating the offending
factories or editing your `test_data` database to ensure they steer clear of one
another. Care should be taken to preserve the conceptual encapsulation of each
test, however, as naively squashing errors can introduce coupling between your
factories and your `test_data` database that inadvertently tangles the two
together (where both test data sources become necessary to interact with the
system).

If your tests are failing after introducing `test_data` and it's not desirable
or feasible to work through the individual failures, you can accomplish a clean
segregation between your factory-dependent tests and your tests that rely on
`test_data` by wrapping each test that depends on `factory_bot` with
[TestData.truncate](#testdatatruncate) in a before-each hook and
[TestData.rollback(:after_data_truncate)](#rolling-back-to-after-test-data-was-truncated)
in an after-each hook, like this:

```ruby
class AnExistingFactoryUsingTest < ActiveSupport::Testcase
  def setup
    TestData.truncate
    # pre-existing setup
  end

  def test_stuff
    #… etc
  end

  def teardown
    TestData.rollback(:after_truncate)
  end
end
```

What this will do is complicated and counter-intuitive, but also fast and
reliable: [TestData.truncate](#testdatatruncate) will first ensure that your
`test_data` database is loaded inside a transaction, then will truncate that
data (set the `truncate_these_test_data_tables` [config option](#testdataconfig)
if necessary), and will finally create _yet another_ transaction save point
named `:after_data_truncate`. From that point onward, your test is free to
create all the factories it needs without fear of colliding with whatever you've
got stored in your `test_data` tables.

_[Why does this approach potentially load all the `test_data` data only to
immediately truncate it? Because it's actually much faster to truncate a large
data load in a live transaction, rollback the truncation, and then re-truncate
the data for a subsequent test than it would be to rollback the large data load
itself and re-load it for a subsequent test. It's silly but it works.]_

Hopefully one of these approaches, or some combination of them will get your
test suite passing after you've introduced `test_data`.

#### Separating your `test_data` and factory tests

Just because your tests _can_ access both your `factory_bot` factories and
`test_data` database doesn't mean they _should_.

Integration tests inevitably become coupled to the data that's available to
them, and if a test has access to both records created by a factory and a
`test_data` SQL dump, it is likely to unintentionally become inextricable from
both. This could result in the test having more ways to fail than necessary and
make it harder to simplify your test data strategy later. Instead, consider
explicitly opting into a single type of test data by separating your tests based
on which source of test data they use.

Every situation will be different, but one strategy that suits a lot of
circumstances would be to write a class method that runs at test-load time to
declare and configure the test data strategy for the current test.

Taking from [this
example](/example/test/integration/better_mode_switching_demo_test.rb) test, you
could implement a class method like this:

```ruby
class ActiveSupport::TestCase
  def self.test_data_mode(mode)
    case mode
    when :factory_bot
      require "factory_bot_rails"
      include FactoryBot::Syntax::Methods

      setup do
        TestData.truncate
      end

      teardown do
        TestData.rollback(:after_data_truncate)
      end
    when :test_data
      setup do
        TestData.load
      end

      teardown do
        TestData.rollback
      end
    end
  end
end
```

And then (without any class inheritance complications), simply declare which
kind of test you're specifying:

```ruby
class SomeFactoryUsingTest < ActiveSupport::TestCase
  test_data_mode :factory_bot

  # … tests go here
end

class SomeTestDataUsingTest < ActionDispatch::IntegrationTest
  test_data_mode :test_data

  # etc.
end
```

By following an approach like this one, your `test_data` tests won't even see
your `create_*` factory methods and your `factory_bot` tests won't have access
to any of your `test_data`, either. From there, you can  migrate tests onto
`test_data` incrementally, secure in the knowledge that you're not inadvertently
tangling your tests' dependency graph further.

#### Speeding up your test suite when using factories

##### Addressing redundant data cleanup

After adding `test_data` to your test suite, consider is how database cleanup
was being handled previously to make sure it isn't unnecessarily truncating
everything or resetting the transaction between tests. It's possible that your
suite is relying on Rails' built-in `use_transactional_tests` feature to wrap
your tests in always-rolled-back transactions, even if you're not using
fixtures. Or perhaps your suite uses
[database_cleaner](https://github.com/DatabaseCleaner/database_cleaner) to
truncate the database before or after each test. In either case, it's important
to know that by default [TestData.load](#testdataload) and
[TestData.rollback](#testdatarollback) will start and rollback a nested
transaction, respectively. That means—so long as they're called at the top of a
before-each hook and the end of an after-each hook—you might be able to disable
`use_transactional_tests` or remove your dependency on `database_cleaner` or any
other custom truncation logic you might have. Even if you get your suite running
immediately after adding `test_data`, it's still worth taking the time to
understand what's going on during test setup & teardown, because there may be an
opportunity to make your tests faster and more comprehensible by eliminating
redundant clean-up steps.

##### Avoiding truncate rollback churn

It's important to know that if your test suite has a mix of tests that call
[TestData.load](#testdataload) and tests that call
[TestData.truncate](#testdatatruncate), each time the test runner switches
between the two types, each call to `TestData.load` will cause the transaction
state to be rolled back from
[:after_data_truncate](#rolling-back-to-after-test-data-was-truncated) to
[:after_data_load](#rolling-back-to-after-the-data-was-loaded), only for the
next test to call `TestData.truncate` truncates all the tables again. In
practice, this shouldn't be too costly an operation, but if your test order is
randomized you might find that your build will run faster if you separate each
set of tests at runtime.

Separating your `test_data` and `factory_bot` tests is pretty trivial if you're
using RSpec, as the
[tag](https://relishapp.com/rspec/rspec-core/v/3-10/docs/command-line/tag-option)
feature was built with this sort of need in mind. Otherwise, you might consider
organizing the tests in different directories and running multiple commands to
execute them (e.g. `bin/rails test test/test_data_tests` and `bin/rails
test/factory_tests`). Every CI configuration is different, however, and you may
find yourself needing to get creative in configuring things to achieve the
fastest build time.

### Using `test_data` with Rails fixtures

While [Rails
fixtures](https://guides.rubyonrails.org/testing.html#the-low-down-on-fixtures)
are similar to factories, the fact that they're run globally by Rails and
permanently committed to the test database actually makes them a little trickier
to work with. This section will cover a couple approaches for integrating
`test_data` into suites that use fixtures.

#### Getting your fixtures-dependent tests passing with `test_data`

It's more likely than not that all your tests will explode in dramatic fashion
as soon as you add `TestData.load` to a `setup` or `before(:each)` hook. Because
fixtures will be loaded all-at-once then your `test_data` dump will be inserted
directly on top of them. If everything works, or if you only encounter a few
errors throughout your test suite (perhaps based on assertions of the `count` of
a particular model), congratulations! You should still consider mitigating the
risks of coupling your tests to both data sources ([as discussed
above](#separating-your-test_data-and-factory-tests)) by migrating completely
onto `test_data` over time, but no further action is necessary or recommended.

If, however, you find yourself running into non-trivial challenges (like rampant
validation or constraint errors), `test_data` provides an API that **overrides
Rails' built-in fixtures behavior with a monkey patch**. If that bold text
warning wasn't enough to scare you from reading on, here's how to do it.

_[Note that the following requires `use_transactional_data_loader` to be enabled
in your [config](#testdataconfig), because it depends on transaction
rollbacks.]_

Here's what you can do if you can't get your fixtures to play nicely with your
`test_data` dump:

1. Near the top of your test helper, call:
   [TestData.prevent_rails_fixtures_from_loading_automatically!](#testdataprevent_rails_fixtures_from_loading_automatically)
   This will effectively turn
   [setup_fixtures](https://github.com/rails/rails/blob/main/activerecord/lib/active_record/test_fixtures.rb#L105)
   into a no-op, which means that your test fixtures will not be automatically
   loaded into your test database

2. In tests that rely on your `test_data` dump, call [TestData.load and
   TestData.rollback](#step-4-load-your-data-in-your-tests) as you normally
   would. Because your fixtures won't be loaded automatically, they won't be
   available to these tests

3. In tests that need fixtures, call
   [TestData.load_rails_fixtures(self)](#testdataload_rails_fixtures)
   in a before-each hook and
   [TestData.rollback(:after_load_rails_fixtures)](#rolling-back-to-after-rails-fixtures-were-loaded)
   in an after-each hook. This will (in an almost comic level of
   transaction-nesting) ensure your `test_data` dump is loaded in an initial
   transaction, then ensure that it is truncated in a second transaction, before
   loading your rails fixtures in a third transaction. These tests will have
   access to all your fixture data without being tainted by any of your
   `test_data` data

For example, you might add the following to an existing fixtures-dependent
test to get it passing:

```ruby
class AnExistingFixtureUsingTest < ActiveSupport::Testcase
  def setup
    TestData.load_rails_fixtures(self)
    # pre-existing setup
  end

  def test_stuff
    #… etc
  end

  def teardown
    TestData.rollback(:after_load_rails_fixtures)
  end
end
```

_[You don't need to worry about whether `TestData.load` has been called
previously, the loader will infer your intent and ensure that the transaction
state is correct before loading your fixtures.]_

#### Separating your `test_data` and fixture tests

*This only applies if you had to use
[TestData.load_rails_fixtures(self)](#testdataload_rails_fixtures) as shown
above.*

Just [like with factories](#separating-your-test_data-and-factory-tests), you
might benefit from a test helper to clearly declare whether a test uses fixtures
or `test_data` right at the top. Following the same pattern, you might do this:

```ruby
class ActiveSupport::TestCase
  def self.test_data_mode(mode)
    case mode
    when :fixtures
      fixtures :all

      setup do
        TestData.load_rails_fixtures(self)
      end

      teardown do
        TestData.rollback(:after_load_rails_fixtures)
      end
    when :test_data
      setup do
        TestData.load
      end

      teardown do
        TestData.rollback
      end
    end
  end
end
```

Which would allow you to simplify the above fixtures-using test to:

```ruby
class AnExistingFixtureUsingTest < ActiveSupport::Testcase
  test_data_mode :fixtures

  def test_stuff
    #… etc
  end
end
```

#### Improving test suite speed with fixtures

Again, as is [the case with
factories](#improving-test-suite-speed-with-factories), every time your test
runner randomly picks a `test_data` test after running a fixtures-dependent
test, it will roll back your fixtures and the truncation of your `test_data`,
only to re-truncate your `test_data` data and reload your fixtures for the next
test that happens to use fixtures. But unlike truncation alone, loading your
fixtures is a non-trivial operation that can chew up a some serious time as your
suite runs.

As a result, we strongly encourage breaking up your test suite to avoid this
churn, even if it means splitting your test run over multiple CLI commands. If
you're using the Rails test runner and Minitest, that likely means sequestering
one set of tests to one directory and the other to a different directory, as
there is no granular control over to how the runner randomizes suites. And for
RSpec,
[tagging](https://relishapp.com/rspec/rspec-core/v/3-10/docs/command-line/tag-option)
each spec and running separate commands for each tag could yield significant
performance improvements.

## Rake Task Reference

### test_data:install

A meta-task that runs [test_data:configure](#test_dataconfigure) and [test_data:initialize](#test_datainitialize).

### test_data:configure

This task runs several generators:

* `config/environments/test_data.rb` - As you may know, Rails ships with
  `development`, `test`, and `production` environments defined by default. But
  you can [actually define custom
  environments](https://guides.rubyonrails.org/configuring.html#creating-rails-environments),
  too! This gem adds a new `test_data` environment and database that's intended
  to be used to create and dump your test data. This new environment file loads
  your `development` environment's configuration and disables migration schema
  dumps so that you can run migrations against your `test_data` database without
  affecting your app's `schema.rb` or `structure.sql`.

* `config/initializers/test_data.rb` - Creates an initializer for the gem that
  calls [TestData.config](#testdataconfig) with an empty block and comments
  documenting the currently-available options and their default values

* `config/database.yml` - This generator adds a new `test_data` section to your
  database configuration, named with the same scheme as your other databases
  (e.g. `your_app_test_data`). If your configuration resembles Rails' generated
  `database.yml` and has a working `&default` alias, then this should "just
  work"

* `config/webpacker.yml` - The gem has nothing to do with web assets, but
  [webpacker](https://github.com/rails/webpacker) will display some prominent
  warnings or errors if it is loaded without a configuration entry for the
  currently-running environment, so this generator defines an alias based on
  your `development` config and then defines `test_data` as extending it

* `config/secrets.yml` - If your app still uses (the now-deprecated)
  [secrets.yml](https://guides.rubyonrails.org/4_1_release_notes.html#config-secrets-yml)
  file introduced in Rails 4.1, this generator will ensure that the `test_data`
  environment is accounted for with a generated `secret_key_base` value. If you
  have numerous secrets in this file's `development:` stanza, you may want to
  alias and inherit it into `test_data:` like the `webpacker.yml` generator does

* `config/cable.yml` - In the absences of a configuration stanza,
  [ActionCable](https://guides.rubyonrails.org/action_cable_overview.html) will
  assume you're using Redis for tracking Websocket connections, so this
  generator explicitly specifies `async` instead, since that's the default for
  `development:`

### test_data:verify_config

This task will verify that your configuration appears to be valid by checking
with each of the gem's generators to inspect your configuration files, and will
error whenever a configuration problem is detected.

### test_data:initialize

This task gets your local `test_data` database up-and-running, either from a set
of dump files (if they already exist), or by loading your schema and running
your seed file. Specifically:

1. Creates the `test_data` environment's database, if it doesn't already exist

2. Ensures the database is non-empty to preserve data integrity (run
   [test_data:drop_database](#test_datadrop_database) first if it contains
   outdated test data)

3. Checks to see if a dump of the database already exists (by default, stored in
   `test/support/test_data/`)

    * If dumps do exist, it invokes [test_data:load](#test_dataload) to load
      them into the database

    * Otherwise, it invokes the task `db:schema:load` and `db:seed` (similar to
      Rails' built-in `db:setup` task)

### test_data:dump

This task is designed to be run after you've created or updated your test data
and you're ready to run your tests against it. The task creates several plain
SQL dumps from your `test_data` environment's database:

* A schema-only dump, by default in `test/support/test_data/schema.sql`

* A data-only dump of records you want to be loaded in your tests, by default in
  `test/support/test_data/data.sql`

* A data-only dump of records that you *don't* want loaded in your tests in
  `test/support/test_data/non_test_data.sql` (by default, this includes Rails'
  internal tables: `ar_internal_metadata` and `schema_migrations`, configurable
  with [TestData.config](#testdataconfig)'s `non_test_data_tables`)

Each of these files are designed to be committed and versioned with the rest of
your application. [TestData.config](#testdataconfig) includes several
options to control which tables are exported into which group.

### test_data:load

This task will load your SQL dumps into your `test_data` database by:

1. Verifying the `test_data` environment's database is empty (creating it if it
   doesn't exist and failing if it's not empty)

2. Verifying that your schema, test data, and non-test data SQL dumps can be
   found at the configured paths

3. Loading the dumps into the `test_data` database

4. Warning if there are pending migrations that haven't been run yet

If there are pending migrations, you'll probably want to run them and then
dump & commit your test data so that they're all up-to-date:

```
$ RAILS_ENV=test_data bin/rake db:migrate
$ bin/rake test_data:dump
```

### test_data:create_database

This task will create the `test_data` environment's database if it does not
already exist. It also
[enhances](https://dev.to/molly/rake-task-enhance-method-explained-3bo0) Rails'
`db:create` task so that `test_data` is created along with `development` and
`test`.

### test_data:drop_database

This task will drop the `test_data` environment's database if it exists. It also
enhances Rails' `db:drop` task so that `test_data` is dropped along with
`development` and `test`.

## API Reference

### TestData.config

The generated `config/initializers/test_data.rb` initializer will include a call
to `TestData.config`, which takes a block that yields a mutable configuration
object (similar to `Rails.application.config`):

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

  # Perform TestData.load and TestData.truncate inside nested
  #   transactions for increased test isolation and speed. Setting this
  #   to false will disable several features that depend on transactions
  #   being used
  # config.use_transactional_data_loader = true

  # Log level (valid values: [:debug, :info, :warn, :error, :quiet])
  # Can also be set with env var TEST_DATA_LOG_LEVEL
  # config.log_level = :info
end
```

### TestData.load

This is the method designed to be used by your tests to load your test data
into your `test` database so that your tests can rely on it.

#### Loading with the speed & safety of transaction savepoints

For the sake of speed and integrity, `TestData.load` is designed to take
advantage of nested transactions ([Postgres
savepoints](https://www.postgresql.org/docs/current/sql-savepoint.html)). By
default, data is loaded in a transaction and intended to be rolled back to the
point _immediately after_ the data was imported after each test. This way, your
test suite only pays the cost of importing the SQL file once, but each of your
tests can enjoy a clean slate that's free of data pollution from other tests.
(This is similar to, but separate from, Rails fixtures'
[use_transactional_tests](https://edgeguides.rubyonrails.org/testing.html#testing-parallel-transactions)
option.)

To help think through the method's behavior, the method nicknames its
transactions `:before_data_load` and `:after_data_load`. The first time you call
`TestData.load`:

1. Creates the `:before_data_load` savepoint
2. Executes the SQL found in the data dump (e.g.
   `test/support/test_data/data.sql`) to insert your test data
3. Creates the `:after_data_load` savepoint

If the method is called and the `:after_data_load` savepoint is already active
(indicating that the data is loaded), the method rolls back to
`:after_data_load`, inferring that the user's intention is to have a clean load
of the test data.

As an additional safeguard, in case a rollback is triggered unexpectedly (i.e.
calling `rollback_transaction` on `ActiveRecord::Base.connection` instead of via
`TestData.rollback`), `test_data` writes a memo indicating that the data is
loaded in `ar_internal_metadata`. `TestData.load` uses this memo to detect this
issue and will recreate the `:after_data_load` savepoint rather than attempt to
erroneously reload your SQL data dump. (Similar error-handling is built-into
[TestData.truncate](#testdatatruncate) and
[TestData.load_rails_fixtures](#testdataload_rails_fixtures), as well.)

#### Loading without transactions

For most cases, we strongly recommend using the default transactional testing
strategy, both because it's faster and because it reduces the risk of test
pollution. However, you may need to commit your test data if the data needs to
be loaded by multiple processes or over multiple connections.

If you need to load the test data and commit it to the database, simply set
`TestData.config.use_transactional_data_loader = false`.

If transactions are disabled, you'll need to decide whether and how to clear the
data out after each test. Many folks use
[database_cleaner](https://github.com/DatabaseCleaner/database_cleaner) for
this, while `test_data` offers a rudimentary
[TestData.truncate](https://github.com/testdouble/test_data#testdatatruncate)
method that may be sufficient for your needs.

You might imagine something like this if you were loading the data just once for
the full run of a test suite:

```ruby
RSpec.configure do |config|
  config.before :all do
    TestData.load
  end

  config.after :all do
    TestData.truncate
  end
end
```

Note that when `use_transactional_data_loader` is `false`, subsequent
`TestData.load` calls won't be able to detect whether the data is already loaded
and will try to re-insert the data, which will almost certainly result in
primary key conflicts.

### TestData.rollback

Because the gem loads your data in a transaction, it makes it easy to rollback
to any of its defined savepoints. In most cases you'll want to roll back to
`:after_data_load` after each test, and that's what `TestData.rollback` will do
when called without an argument. If the specified savepoint isn't active,
calling `rollback` is a no-op.

The gem may create up to four nested savepoints in a single transaction, and
this method allows you to rollback to any of them. They form the following
stack:

* `:before_data_load` - Taken before loading your `test_data` dump
* `:after_data_load` - Taken after loading your `test_data` dump
* `:after_truncate` - Taken after your `test_data` is truncated
* `:after_load_rails_fixtures` - Taken after Rails fixtures are loaded via
  [TestData.load_rails_fixtures](#testdataload_rails_fixtures)

More details on rolling back to each of the gem's savepoints follows below.

#### Rolling back to before test data was loaded

If some tests rely on data loaded by `TestData.load` and you have other tests
that depend on that data _not being there_, you probably want to call
[TestData.truncate](#testdatatruncate). But if that won't work for your needs,
you can rewind to the moment just before your test data was loaded by calling
`TestData.rollback(:before_data_load)`.

**⚠️ Warning⚠️** Repeatedly loading and rolling back to `:before_data_load` is
expensive! If your test suite calls `TestData.rollback(:before_data_load)`
multiple times, it's likely you're re-loading your (possibly large) SQL file of
test data many more times than is necessary. Consider using
[TestData.truncate](#testdatatruncate) to achieve the same goal with faster
performance. Failing that, it might be preferable to partition your test suite
so that similar tests are run in separate groups (as opposed to in a fully
random or arbitrary order) to avoid repeatedly thrashing between rollbacks and
reloads. This partitioning could be accomplished by either configuring your test
runner or by running separate test commands for each group of tests.

#### Rolling back to after the data was loaded

This is the way you're likely to call this method most often.

When `TestData.rollback` is passed no arguments or called more explicitly as
`TestData.rollback(:after_data_load)`, the method will rollback to the
`:after_data_load` transaction savepoint taken immediately after the SQL dump
was loaded. As a result, it is intended to be run after each test (e.g. in an
`after(:each)` or `teardown`), to undo any changes made by the test.

#### Rolling back to after test data was truncated

If some of your tests call [TestData.truncate](#testdatatruncate) to clear out
your test data after it's been loaded (as
[described](#getting-your-factory-tests-passing-after-adding-test_data) when
using `test_data` in conjunction with `factory_bot`), then you will likely want
to run `TestData.rollback(:after_data_truncate)` after each of them. This will
rewind your test database's state to when those tables were first
truncated—effectively re-cleaning the slate for the next test.

#### Rolling back to after Rails fixtures were loaded

If you're using
[TestData.load_rails_fixtures(self)](#testdataload_rails_fixtures) in your
test's before-each hook, you'll probably want to teardown that test by rolling
back with `TestData.rollback(:after_load_rails_fixtures)` in an after-each hook,
which will rewind to the point just after your Rails fixtures were loaded.

### TestData.truncate

Do you have some tests that _shouldn't_ access your test data? Or did some
existing tests started failing after `test_data` was added? If you want to clear
the state of your `test` database to support these tests, you can accomplish
this with `TestData.truncate`. It truncates all the tables that `TestData.load`
inserted into and then creates a savepoint named `:after_data_truncate`.

Most often, you'll want to call `TestData.truncate` before each test that
should _not_ have access to your test data created with this gem. After each
such test, it can clean up by calling `TestData.rollback(:after_data_truncate)`:

```ruby
class CleanSlateTest < ActiveDispatch::IntegrationTest
  def setup do
    TestData.truncate
  end

  def teardown do
    TestData.rollback(:after_data_truncate)
  end
end
```

By default, all tables for which there is an `INSERT INTO` statement in your
test data SQL dump will be truncated (and cascading to any tables with foreign
keys pointing to those tables), but you can also explicitly specify which tables
should be truncated yourself by setting the `truncate_these_test_data_tables`
property on [TestData.config](#testdataconfig) to an array of table names.

#### If you're not using transactions

Just [like TestData.load](#loading-without-transactions), you can call
`TestData.truncate` when `use_transactional_data_loader` is `false` and it will
commit the truncation.

### TestData.prevent_rails_fixtures_from_loading_automatically!

Call this method before any tests have been loaded or executed by your test
runner if you're planning to use
[TestData.load_rails_fixtures](#testdataload_rails_fixtures) to load Rails
fixtures into any of your tests. This method will disable the default behavior
of loading your Rails fixtures into the test database as soon as the first test
case with fixtures enabled is executed. (Inspect the [source for the
patch](/lib/test_data/active_record_ext.rb) to make sure you're comfortable with
what it's doing.)

### TestData.load_rails_fixtures

As described in this README's [fixture interop
guide](#getting-your-fixtures-dependent-tests-passing-with-test_data),
`TestData.load_rails_fixtures` will load your app's [Rails
fixtures](https://guides.rubyonrails.org/testing.html#the-low-down-on-fixtures)
into an effectively empty test database inside a nested transaction. Because the
feature uses Rails built-in fixtures-loading code as well as its caching
mechanism, the method must be passed an instance of the running test class (in
a Minitest `setup` hook, that means `TestData.load_rails_fixtures(self)`)

Using this feature requires that you've:

1. Invoked
[TestData.prevent_rails_fixtures_from_loading_automatically!](#testdataprevent_rails_fixtures_from_loading_automatically)
2. Have `config.use_transactional_data_loader` set to true (the default) in your
   [config](#testdataconfig)

When you call this method, it will do the following:

1. Verify your `test_data` dump has been loaded (or else load it)
2. Verify the loaded data has been truncated (or else truncate it)
3. Load your Rails fixtures from their YAML source files into your test database
4. Create a new savepoint in the nested transactions named
   `:after_load_rails_fixtures`

Once loaded, your tests will be able to use your test fixtures inside a
transaction. At teardown-time, you can reset those fixtures by rolling back with
[TestData.rollback(:after_load_rails_fixtures)](#rolling-back-to-after-rails-fixtures-were-loaded).

## Assumptions

The `test_data` gem is still brand new and doesn't cover every use case just
yet. Here are some existing assumptions and limitations:

* You're using Postgres

* You're using Rails 6 or higher

* Your app does not require Rails' [multi-database
  support](https://guides.rubyonrails.org/active_record_multiple_databases.html)
  in order to be tested

* Your app has the binstubs `bin/rake` and `bin/rails` that Rails generates and
  they work (protip: you can regenerate them with `rails app:update:bin`)

* Your `database.yml` defines a `&default` alias from which to extend the
  `test_data` database configuration (if your YAML file lacks one, you can
  always specify the `test_data` database configuration manually)

## Fears, Uncertainties, and Doubts

### But we use and like `factory_bot` and so I am inclined to dislike everything about this gem!

If you use `factory_bot` and all of these are true:

* Your integration tests are super fast and not getting significantly slower
  over time

* Innocuous changes to factories rarely result in unrelated test failures
  that—rather than indicating a bug in the production code—instead require that
  each of those tests be analyzed & updated to get them passing again

* The number of associated records generated between your most-used factories
  are representative of production data, as opposed to generating a sprawling
  hierarchy of models, as if your test just ordered "one of everything" off the
  menu

* Your default factories generate models that resemble real records created by
  your production application, as opposed to representing the
  sum-of-all-edge-cases with every boolean flag enabled and optional attribute
  set

* You've avoided mitigating the above problems with confusingly-named and
  confidence-eroding nested factories with names like `:user`, `:basic_user`,
  `:lite_user`, and `:plain_user_no_associations_allowed`

If none of these things are true, then congratulations! You are using
`factory_bot` with great success! Unfortunately, in our experience, this outcome
is exceedingly rare, especially for large and long-lived applications.

However, if any of the above issues resonate with your experience using
`factory_bot`: these are the sorts of failure modes the `test_data` gem was
designed to address. We hope you'll consider trying it with an open mind. At the
same time, we acknowledge that large test suites can't be rewritten and migrated
to a different source of test data overnight—nor should they be! See our notes
on [migrating to `test_data`
incrementally](#factory--fixture-interoperability-guide)

### How will I handle merge conflicts in these SQL files if I have lots of people working on lots of feature branches all adding to the `test_data` database dumps?

In a word: carefully!

First, in terms of expectations-setting, you should expect your test data SQL
dumps to churn at roughly the same rate as your schema: lots of changes up
front, but tapering off as the application stabilizes.

If your schema isn't changing frequently and you're not running data migrations
against production very often, it might make the most sense to let this concern
present itself as a real problem before attempting to solve it, as you're likely
to find that other best-practices around collaboration and deployment (frequent
merges, continuous integration, coordinating breaking changes) will also manage
this risk. The reason that the dumps are stored as plain SQL (aside from the
fact that git's text compression is very good) is to make merge conflicts with
other branches feasible, if not entirely painless.

However, if your app is in the very initial stages of development and you're
making breaking changes to your schema very frequently, our best advice is to
hold off a bit on writing _any_ integration tests that depend on shared sources
of test data, as they'll be more likely to frustrate your ability to rapidly
iterate than detect bugs. Once you you have a reasonably stable feature working
end-to-end, that's a good moment to start adding integration tests (and thus
pulling in a test data gem like this one to help you).

### Why can't I save multiple database dumps to cover different scenarios?

For the same reason you (probably) don't have multiple production databases: the
fact that Rails apps are monolithic and consolidated is a big reason why they're
so productive and comprehensible. This gem is not
[VCR](https://github.com/vcr/vcr) for databases. If you were to design separate
test data dumps for each feature, stakeholder, or concern, you'd also have more
moving parts to maintain, more complexity to communicate, and more pieces that
could someday fall into disrepair.

By having a single `test_data` database that grows up with your application just
like `production` does—with both having their schemas and data migrated
incrementally over time—your integration tests that depend on `test_data` will
have an early opportunity to catch bugs that otherwise wouldn't be found until
they were deployed into a long-lived environment like staging or (gasp!)
production itself.

### Are you sure I should commit these SQL dumps? They're way too big!

If the dump files generated by `test_data:dump` seem massive, consider the
cause:

1. If you inadvertently created more data than necessary, you might consider
   resetting (or rolling back) your changes and making another attempt at
   generating a more minimal set of test data

2. If certain tables have a lot of records but aren't very relevant to your
   tests (e.g. audit logs), you might consider either of these options:

    * Add those tables to the `config.non_test_data_tables` configuration array,
      where they'd still be committed to git, but won't loaded by your tests

    * Exclude data from those tables entirely by adding them to the
      `config.dont_dump_these_tables` array. (Note that `rake test_data:load`
      won't be able to restore these tables into your `test_data` environment,
      so if the data is needed for the app to operate, you'll need to dump them)

3. If the dumps are _necessarily_ really big (some apps are complex!), consider
   looking into [git-lfs](https://git-lfs.github.com) for tracking them without
   impacting the size and performance of the git slug. (See [GitHub's
   documentation](https://docs.github.com/en/github/managing-large-files/working-with-large-files)
   on what their service supports)

_[Beyond these options, we'd also be interested in a solution that filtered data
in a more granular way than ignoring entire tables. If you have a proposal you'd
be interested in implementing, [suggest it in an issue](/issues/new)!]_

### Tests shouldn't use shared test data, they should instantiate the objects they need!

Agreed! Nothing is simpler than calling `new` to create an object.

If it's possible to write a test that looks like this, do it. Don't use shared
test data loaded from this gem or any other:

```ruby
def test_exclude_cancelled_orders
  good_order = Order.new
  bad_order = Order.new(cancelled: true)
  user = User.create!(orders: good_order, bad_order)

  result = user.active_orders

  assert_includes good_order
  refute_includes bad_order
end
```

This test is simple, self-contained, clearly denotes
[arrange-act-assert](https://github.com/testdouble/contributing-tests/wiki/Arrange-Act-Assert),
and (most importantly) will only fail if the functionality stops working.
Maximizing the number of tests that can be written expressively and succinctly
without the aid of shared test data is a laudable goal that more teams should
embrace.

However, what if the code you're writing doesn't need 3 records in the database,
but 30? Writing that much test setup would be painstaking and—despite being
fully-encapsulated—hard for readers to understand what's going on. At that
point, you have two options:

1. Critically validate your design: why is it so hard to set up? Does it
   _really_ require so much persisted data to exercise this behavior? Would a
   [plain old Ruby
   object](https://steveklabnik.com/writing/the-secret-to-rails-oo-design) that
   defined a pure function have been feasible? Could a model instance or even a
   `Struct` be passed to the
   [subject](https://github.com/testdouble/contributing-tests/wiki/Subject)
   instead of loading everything from the database? When automated testing is
   saved for the very end of a feature's development, it can feel too costly to
   reexamine design decisions like this, but it's valuable feedback all the
   same. *Easy to test code is easy to use code*

2. If the complex setup is a necessary reality of the situation that your app
   needs to handle (and it often will be!), then having _some_ kind of shared
   source of test data to use as a starting point can be hugely beneficial.
   That's why `factory_bot` is so popular, why this gem exists, etc.

As a result, there is no one-size-fits-all approach. Straightforward behavior
that can be invoked with a clear, concise test has no reason to be coupled to a
shared source of test data. Subtle behavior that requires lots of
carefully-arranged data would see its tests grow unwieldy without something to
help populate that data. So both kinds of test clearly have their place.

But this is a pretty nuanced discussion that can be hard to keep in mind when
under deadline pressure or on a large team where building consensus around norms
is challenging. As a result, leaving the decision of which type of test to write
to spur-of-the-moment judgment is likely to result in inconsistent test design.
Instead, you might consider separating these two categories into separate test
types or suites.

For example, it would be completely reasonable to load this gem's test data for
integration tests, but not for basic tests of models, like so:

```ruby
class ActionDispatch::IntegrationTest
  setup do
    TestData.load
  end

  teardown do
    TestData.rollback
  end
end

class ActiveSupport::TestCase
  setup do
    TestData.truncate
  end

  teardown do
    TestData.rollback(:after_data_truncate)
  end
end
```

In short, this skepticism is generally healthy, and encapsulated tests that
forego reliance on shared sources of test data should be maximized. For
everything else, there's `test_data`.

## Code of Conduct

This project follows Test Double's [code of
conduct](https://testdouble.com/code-of-conduct) for all community interactions,
including (but not limited to) one-on-one communications, public posts/comments,
code reviews, pull requests, and GitHub issues. If violations occur, Test Double
will take any action they deem appropriate for the infraction, up to and
including blocking a user from the organization's repositories.

