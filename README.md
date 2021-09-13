# The `test_data` gem

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

* Exposes a simple API for ensuring that your data will be pristine for each of
  your tests, whether the test depends on test_data, an empty database, or Rails
  fixtures

* Safeguards your tests from flaky failures and supercharges your build by
  providing a sophisticated transaction manager that isolates each test while
  ensuring your data is only loaded once

If you've despaired over the seeming inevitability that all Rails test suites
will eventually grow to become slow, flaky, and incomprehensible, then this gem
is for you! And even if you're [a factory_bot
fan](https://twitter.com/searls/status/1379491813099253762?s=20), we hope you'll
be open to the idea that [there might be a better way](
#but-we-use-and-like-factory_bot-and-so-i-am-inclined-to-dislike-everything-about-this-gem).

_[Full disclosure: because the gem is still brand new, it makes a number of
[assumptions](#assumptions)—chief among them being that **Postgres & Rails 6+
are required**—so it may not work for every project just yet.]_

## Documentation

This gem requires a lot of documentation—not because `test_data` does a lot of
things, but because managing one's test data is an inherently complex task. If
one reason Rails apps chronically suffer from slow tests is that other
approaches oversimplify test data management, it stands to reason that any
discomfort caused by `test_data`'s scope may not be _unnecessary complexity_ but
instead be an indication of how little of the problem's _essential complexity_
we have reckoned with to this point.

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
    * [test_data:reinitialize](#test_datareinitialize)
    * [test_data:dump](#test_datadump)
    * [test_data:load](#test_dataload)
    * [test_data:create_database](#test_datacreate_database)
    * [test_data:drop_database](#test_datadrop_database)
4. [API Reference](#api-reference)
    * [TestData.uses_test_data](#testdatauses_test_data)
    * [TestData.uses_clean_slate](#testdatauses_clean_slate)
    * [TestData.uses_rails_fixtures(self)](#testdatauses_rails_fixtures)
        * [TestData.prevent_rails_fixtures_from_loading_automatically!](#testdataprevent_rails_fixtures_from_loading_automatically)
    * [TestData.config](#testdataconfig)
    * [TestData.insert_test_data_dump](#testdatainsert_test_data_dump)
5. [Assumptions](#assumptions)
6. [Fears, Uncertainties, and Doubts](#fears-uncertainties-and-doubts) (Q & A)
    * [But we're already happy with
      factory_bot!](#but-we-use-and-like-factory_bot-and-so-i-am-inclined-to-dislike-everything-about-this-gem)
    * [How will we handle merge conflicts in the schema
      dumps?](#how-will-i-handle-merge-conflicts-in-these-sql-files-if-i-have-lots-of-people-working-on-lots-of-feature-branches-all-adding-to-the-test_data-database-dumps)
    * [Why can't I manage different SQL dumps for different
      scenarios?](#why-cant-i-save-multiple-database-dumps-to-cover-different-scenarios)
    * [These SQL dumps are way too large to commit to
      git!](#are-you-sure-i-should-commit-these-sql-dumps-theyre-way-too-big)
    * [Tests shouldn't rely on shared test data if they don't need
      to](#tests-shouldnt-use-shared-test-data-they-should-instantiate-the-objects-they-need)
    * [My tests aren't as fast as they should
      be](#im-worried-my-tests-arent-as-fast-as-they-should-be)
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
will manually generate test data by playing around with your app. Rather than
try to imitate realistic data using factories and fixtures (a task which only
grows more difficult as your models and their associations increase in
complexity), your test data will always be realistic because your real
application will have created it!

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
know—it may present an opportunity for us to improve the `test_data:configure`
task!]_

#### Create test data by using your app

Once the app is running, it's time to generate some test data. You'll know how
to accomplish this step better than anyone—it's your app, after all!

A few bits of advice click & type some test data into existence:

* Spend a little time thoughtfully navigating each feature of your app in order
  to generate enough data to be representative of what would be needed to test
  them (e.g. one `User` per role, one of each kind of `Order`, etc.)
* Less is more: the less test data you create, the more meaningful & memorable
  it will be to yourself and your teammates when writing tests. Don't keep
  adding test data unless it will allow you to exercise additional application
  code (e.g. enough `Project` models to require pagination, but not hundreds of
  them for the sake of looking "production-like")
* Memorable names can become memes for the team to quickly recall and reference
  later (if the admin user is named "Angela" and the manager is "Maria", that'll
  probably serve you better than generic names like "TestUser #1")

If you make a mistake when creating your initial set of test data, it's
perfectly okay to reset the database and start over! Your future tests will be
coupled to this data as your application grows and evolves, so it's worth taking
the time to ensure the foundation is solid. (But that's not to say everything
needs to be perfect; you can always change things or add more data later—you'll
just have to update your tests accordingly.)

### Step 3: Dump your `test_data` database

Once you've created a good sampling of test data by interacting with your app,
the next step is to flush it from the `test_data` database to SQL files. These
database dumps are meant to be committed to source control and versioned
alongside your tests over the life of the application. Additionally, they are
designed to be incrementally
[migrated](#step-5-keeping-your-test-data-up-to-date) over time, just like you
migrate production database with every release.

Once you have your test data how you want it, dump the schema and data to SQL
files with the `test_data:dump` Rake task:

```
$ bin/rake test_data:dump
```

This will dump three files into `test/support/test_data`:

* `schema.sql` - Schema DDL used to (re-)initialize the `test_data` environment
  database for anyone looking to update your test data

* `data.sql` - The test data itself, exported as a bunch of SQL `INSERT`
  statements, which will be executed by your tests to load your test data

* `non_test_data.sql` - Data needed to run the `test_data` environment, but
  which shouldn't be inserted by your tests (the `ar_internal_metadata` and
  `schema_migrations` tables, by default; see `config.non_test_data_tables`)

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
from a set of YAML files.

### Step 4: Load your data in your tests

Now that you've dumped the contents of your `test_data` database, you can start
writing tests that rely on this test data.

To accomplish this, you'll likely want to add hooks to run before each test to
put the database into whatever state the test needs.

For the simplest case—ensuring your test data is loaded into the `test` database
and available to your test, you'll want to call the
[TestData.uses_test_data](#testdatauses_test_data) method at the beginning of
the test. The first time `uses_test_data` is called, `test_data` will start a
transaction and insert your test data. On subsequent calls to `uses_test_data`
by later tests, the transaction will be rolled back to a save point taken just
after the data was initially loaded, so that each test gets a clean starting
point without repeatedly executing the expensive SQL operation.

#### If you want every single test to have access to your test data

If, for the sake of consistency & simplicity you want every single Rails-aware
test to have access to your test data, you
can accomplish this with a single global before-each hook.

If you're using Rails' default
[Minitest](https://github.com/seattlerb/minitest), you can load it in a `setup`
hook in `ActiveSupport::TestCase`:

```ruby
class ActiveSupport::TestCase
  setup do
    TestData.uses_test_data
  end
end
```

Likewise, if you use [RSpec](https://rspec.info), you can accomplish the same
thing with global `before(:each)` hook in your `rails_helper.rb` file:

```ruby
RSpec.configure do |config|
  config.before(:each) do
    TestData.uses_test_data
  end
end
```

#### If some tests rely on test data and others need a clean slate

Of course, for simple units of code, it may be more prudent to manually create
the test data they need inline as opposed to relying on a shared source of test
data. For these tests, you can call
[TestData.uses_clean_slate](#testdatauses_clean_slate) in a `setup` hook.

For the best performance, you might consider a mode-switching method that's
invoked at the top of each test listing like this:

```ruby
class ActiveSupport::TestCase
  def self.uses(mode)
    case mode
    when :clean_slate
      setup { TestData.uses_clean_slate }
    when :test_data
      setup { TestData.uses_test_data }
    else
      raise "Invalid test data mode: #{mode}"
    end
  end
end

# A simple model that will `create` its own data
class WidgetTest < ActiveSupport::TestCase
  uses :clean_slate
  # …
end

# An integrated test that depends on a lot of data
class KitchenSinkTest < ActionDispatch::IntegrationTest
  uses :test_data
  # …
end
```

Or, with RSpec:

```ruby
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

RSpec.describe Widget, type: :model do
  uses :clean_slate
  # …
end

RSpec.describe "Kitchen sink", type: :request do
  uses :test_data
  # …
end
```

But wait, there's more! If your test suite switches between multiple modes from
test-to-test, it's important to be aware of the marginal cost _between_ each of
those tests. For example, two tests in a row that call `TestData.uses_test_data`
only need a simple rollback as test setup, but a `TestData.uses_test_data`
followed by a `TestData.uses_clean_slate` requires a rollback, a truncation, and
another savepoint. These small costs add up, so consider [speeding up your
build](#im-worried-my-tests-arent-as-fast-as-they-should-be) by grouping your
tests into sub-suites based on their source of test data.

#### If your situation is more complicated

If you're adding `test_data` to an existing application, it's likely that you
won't be able to easily adopt a one-size-fits-all approach to test setup across
your entire suite. Some points of reference, if that's the situation you're in:

* If your test suite is **already using fixtures or factories** and the above
  hooks just broke everything, check out our [interoperability
  guide](#factory--fixture-interoperability-guide) for help.
* If you need to make any changes to the data after it's loaded, truncated, or
  after Rails fixtures are loaded, you can configure [lifecycle
  hooks](#lifecycle-hooks) that will help you achieve a **very fast test suite**
  by including those changes inside the transaction savepoints
* If you **don't want `test_data` managing transactions** and cleanup for you
  and just want to load the SQL dump, you can call
  [TestData.insert_test_data_dump](#testdatainsert_test_data_dump)
* For more information on how all this works, see the [API
  reference](#api-reference).

### Step 5: Keeping your test data up-to-date

Your app relies on its tests and your tests rely on their test data. This
creates a bit of a paradox: creating & maintaining test data is _literally_ a
tertiary concern but simultaneously an inescapable responsibility that will live
with you for the life of your application. That's true whether you use this gem,
`factory_bot`, Rails fixtures, or something else as a source of shared test
data.

Fortunately, we already have a fantastic tool available for keeping our
`test_data` database up-to-date over the life of our application: [Rails
migrations](https://guides.rubyonrails.org/active_record_migrations.html). If
your migrations are resilient enough for your production database, they should
also be able to keep your `test_data` database up-to-date. (As a happy side
effect of running your migrations against your test data, this means your
`test_data` database may help you identify hard-to-catch migration bugs early,
before being deployed to production!)

Whenever you create a new migration or add a major feature, you'll probably need
to update your test data. Here's how to do it:

* If the current SQL dumps in `test/support/test_data` are newer than your local
  `test_data` database:

    1. Be sure there's nothing in your local `test_data` database that you added
       intentionally and forgot to dump, because it's about to be erased

    2. Run `rake test_data:reinitialize` drop and recreate the `test_data`
       database and load the latest SQL dumps into it

    3. Run any pending migrations with `RAILS_ENV=test_data bin/rake db:migrate`

    4. If you need to create any additional data, start up the server
       (`RAILS_ENV=test_data bin/rails s`), just like in [Step
       2](#step-2-create-some-test-data)

    5. Export your newly-updated `test_data` database with `rake test_data:dump`

    6. Ensure your tests are passing and then commit the resulting SQL files

* If the local `test_data` database is already up-to-date with the current SQL
  dumps, follow steps **3 through 6** above

It's important to keep in mind that your test data SQL dumps are a shared,
generated resource among your team (just like a `structure.sql` or `schema.rb`
file). As a result, if your team doesn't integrate code frequently or if the
test data changes frequently, you'd be right to be concerned that [the resulting
merge conflicts could become
significant](#how-will-i-handle-merge-conflicts-in-these-sql-files-if-i-have-lots-of-people-working-on-lots-of-feature-branches-all-adding-to-the-test_data-database-dumps),
so sweeping changes should be made deliberately and in collaboration with other
contributors.

_[Aside: some Rails teams are averse to using migrations to migrate data as well
as schemas, instead preferring one-off scripts and tasks. You'll have an easier
time of things if you use migrations for both schema and data changes. Here are
some notes on [how to write data migrations
safely](https://blog.testdouble.com/posts/2014-11-04-healthy-migration-habits/#habit-4-dont-reference-models).
Otherwise, you'll need to remember to run any ad hoc deployment scripts against
your `test_data` Rails environment along with each of your other deployed
environments.]_

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
Rails fixtures, whether you choose to incrementally migrate to using `test_data`
over time.

### Using `test_data` with `factory_bot`

This section will document some thoughts and strategies for introducing
`test_data` to a test suite that's already using `factory_bot`.

#### Getting your factory tests passing after adding `test_data`

Depending on the assumptions your tests make about the state of the database
before you've loaded any factories, it's possible that everything will "just
work" after adding [TestData.uses_test_data](#testdatauses_test_data) in a
before-each hook (as shown in the [setup
guide](#step-4-load-your-data-in-your-tests)). So by all means, try running your
suite after following the initial setup guide and see if the suite just passes.

If you find that your test suite is failing after adding
`TestData.uses_test_data` to your setup, don't panic! Test failures are most
likely caused by the combination of your `test_data` SQL dump with the records
inserted by your factories.

One approach would be to attempt to resolve each such failure one-by-one—usually
by updating the offending factories or editing your `test_data` database to
ensure they steer clear of one another. Care should be taken to preserve the
conceptual encapsulation of each test, however, as naively squashing errors
risks introducing inadvertent coupling between your factories and your
`test_data` data such that neither can be used independently of the other.

Another approach that the `test_data` gem provides is an additional mode with
`TestData.uses_clean_slate`, which—when called at the top of a factory-dependent
test—will ensure that the tables that `test_data` had written to will be
truncated, allowing the test to create whatever factories it needs without fear
of conflicts.

```ruby
class AnExistingFactoryUsingTest < ActiveSupport::Testcase
  setup do
    TestData.uses_clean_slate
    # pre-existing setup
  end
  # …
end
```

If you have a lot of tests, you can find a more sophisticated approaches for
logically switching between types of test data declaratively above in the
[getting started
section](#if-some-tests-rely-on-test-data-and-others-need-a-clean-slate)

### Using `test_data` with Rails fixtures

While [Rails
fixtures](https://guides.rubyonrails.org/testing.html#the-low-down-on-fixtures)
are similar to factories, the fact that they're run globally by Rails and
permanently committed to the test database actually makes them a little trickier
to work with. This section will cover a couple approaches for integrating
`test_data` into suites that use fixtures.

It's more likely than not that all your tests will explode in dramatic fashion
as soon as you add `TestData.uses_test_data` to a `setup` or `before(:each)`
hook. Typically, your fixtures will be loaded and committed immediately with
your `test_data` dump inserted afterward, which makes it exceedingly likely that
your tests will fail with primary key and unique constraint conflicts. If that's
the case you find yourself in, `test_data` provides an API that **overrides
Rails' built-in fixtures behavior with a monkey patch**.

And if that bold text wasn't enough to scare you off, here's how to do
it:

1. Before your tests have loaded (e.g. near the top of your test helper), call:
   [TestData.prevent_rails_fixtures_from_loading_automatically!](#testdataprevent_rails_fixtures_from_loading_automatically)
   This will patch Rails'
   [setup_fixtures](https://github.com/rails/rails/blob/main/activerecord/lib/active_record/test_fixtures.rb#L105)
   and effectively render it into a no-op, which means that your test fixtures
   will not be automatically loaded into your test database

2. In tests that rely on your `test_data` dump, call
   [TestData.uses_test_data](#step-4-load-your-data-in-your-tests) as you
   normally would. Because your fixtures won't be loaded automatically, they
   won't be available to these tests

3. In tests that need fixtures, call
   [TestData.uses_rails_fixtures(self)](#testdatauses_rails_fixtures) in a
   before-each hook. This will first ensure that any tables written to by
   `test_data` are truncated (as with `TestData.uses_clean_slate`) before
   loading your Rails fixtures

For example, you might add the following to an existing fixtures-dependent
test to get it passing:

```ruby
class AnExistingFixtureUsingTest < ActiveSupport::Testcase
  setup do
    TestData.uses_rails_fixtures(self)
    # pre-existing setup
  end

  # …
end
```

If you've adopted a mode-switching helper method [like the one described
above](#if-some-tests-rely-on-test-data-and-others-need-a-clean-slate), you
could of course add a third mode to cover any tests that depend on Rails
fixtures.

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

* `config/cable.yml` - Simply defines a `test_data:` entry that tells
  [ActionCable](https://guides.rubyonrails.org/action_cable_overview.html) to
  use the `async` adapter, since that's also the default for `development`

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
   [test_data:drop_database](#test_datadrop_database) first if you intend to
   reinitialize it)

3. Checks to see if a dump of the database already exists (by default, stored in
   `test/support/test_data/`)

    * If dumps do exist, it invokes [test_data:load](#test_dataload) to load
      them into the database

    * Otherwise, it invokes the task `db:schema:load` and `db:seed` (similar to
      Rails' built-in `db:setup` task)

### test_data:reinitialize

This task is designed for the situation where you may already have a `test_data`
database created and simply want to drop it and replace it with whatever dumps
are in the `test/support/test_data` directory.

Dropping the database requires confirmation, either interactively or by setting
the environment variable `TEST_DATA_CONFIRM`. It will additionally warn you in
the event that the local database appears to be newer than the dumps on disk
that would replace it. From there, this task behaves the same way as `rake
test_data:initialize`.

### test_data:dump

This task is designed to be run after you've created or updated your test data
in the `test_data` database and you're ready to run your tests against it. The
task creates several plain SQL dumps from your `test_data` environment's
database:

* A schema-only dump, by default in `test/support/test_data/schema.sql`

* A data-only dump of records you want to be loaded in your tests, by default in
  `test/support/test_data/data.sql`

* A data-only dump of records that you *don't* want loaded in your tests in
  `test/support/test_data/non_test_data.sql`. By default, this includes Rails'
  internal tables: `ar_internal_metadata` and `schema_migrations`, configurable
  with [TestData.config](#testdataconfig)'s `non_test_data_tables`

Each of these files are designed to be committed and versioned with the rest of
your application. [TestData.config](#testdataconfig) includes several
options to control this task.

### test_data:load

This task will load your SQL dumps into your `test_data` database by:

1. Verifying the `test_data` environment's database is empty (creating it if it
   doesn't exist and failing if it's not empty)

2. Verifying that your schema, test data, and non-test data SQL dumps can be
   found at the configured paths

3. Loading the dumps into the `test_data` database

4. Warning if there are pending migrations that haven't been run yet

If there are pending migrations, you'll probably want to run them and then
dump & commit your test data so that they're up-to-date:

```
$ RAILS_ENV=test_data bin/rake db:migrate
$ bin/rake test_data:dump
```

### test_data:create_database

This task will create the `test_data` environment's database if it does not
already exist. It also
[enhances](https://dev.to/molly/rake-task-enhance-method-explained-3bo0) Rails'
`db:create` task so that `test_data` is created along with `development` and
`test` whenever `rake db:create` is run.

### test_data:drop_database

This task will drop the `test_data` environment's database if it exists. It also
enhances Rails' `db:drop` task so that `test_data` is dropped along with
`development` and `test` whenever `rake db:drop` is run.

## API Reference

### TestData.uses_test_data

This is the method designed to be used by your tests to load your test data
into your `test` database so that your tests can rely on it. Typically, you'll
want to call it at the beginning of each test that relies on the test data
managed by this gem—most often, in a before-each hook.

For the sake of speed and integrity, `TestData.uses_test_data` is designed to
take advantage of nested transactions ([Postgres
savepoints](https://www.postgresql.org/docs/current/sql-savepoint.html)). By
default, data is loaded in a transaction and intended to be rolled back to the
point _immediately after_ the data was imported between tests. This way, your
test suite only pays the cost of importing the SQL file once, but each of your
tests can enjoy a clean slate that's free of data pollution from other tests.
(This is similar to, but separate from, Rails fixtures'
[use_transactional_tests](https://edgeguides.rubyonrails.org/testing.html#testing-parallel-transactions)
option.)

_See configuration option:
[config.after_test_data_load](#configafter_test_data_load)_

### TestData.uses_clean_slate

If a test does not rely on your `test_data` data, you can instead ensure that it
runs against empty tables by calling `TestData.uses_clean_slate`. Like
`TestData.uses_test_data`, this would normally be called at the beginning of
each such test in a before-each hook.

This method works by first ensuring that your test data is loaded (and the
correspondent savepoint created), then will truncate all affected tables and
create another savepoint. It's a little counter-intuitive that you'd first
litter your database with data only to wipe it clean again, but it's much faster
to repeatedly truncate tables than to repeatedly import large SQL files.

_See configuration options:
[config.after_test_data_truncate](#configafter_test_data_truncate),
[config.truncate_these_test_data_tables](#configtruncate_these_test_data_tables)_

### TestData.uses_rails_fixtures

As described in this README's [fixture interop
guide](#using-test_data-with-rails-fixtures), `TestData.uses_rails_fixtures`
will load your app's [Rails
fixtures](https://guides.rubyonrails.org/testing.html#the-low-down-on-fixtures)
by intercepting Rails' built-in fixture-loading code. As with the other "uses"
methods, you'll likely want to call it in a before-each hook before any test
that needs access to your Rails fixtures.

There are two additional things to keep in mind if using this method:

1. Using this feature requires that you've first invoked
   [TestData.prevent_rails_fixtures_from_loading_automatically!](#testdataprevent_rails_fixtures_from_loading_automatically)
   before your tests have started running to override Rails' default behavior
   before any of your tests have loaded or started running

2. Because the method depends on Rails' fixture caching mechanism, it must be
   passed an instance of the running test class (e.g.
   `TestData.uses_rails_fixtures(self)`)

Under the hood, this method effectively ensures a clean slate the same way
`TestData.uses_clean_slate` does, except that after creating the truncation
savepoint, it will then load your fixtures and finally create—wait for it—yet
another savepoint that subsequent calls to `uses_rails_fixtures` can rollback
to.

_See configuration option:
[config.after_rails_fixture_load](#configafter_rails_fixture_load)_

#### TestData.prevent_rails_fixtures_from_loading_automatically!

Call this method before any tests have been loaded or executed by your test
runner if you're planning to use
[TestData.uses_rails_fixtures](#testdatauses_rails_fixtures) to load Rails
fixtures into any of your tests. This method will disable the default behavior
of loading your Rails fixtures into the test database as soon as the first test
case with fixtures enabled is executed. (Inspect the [source for the
patch](/lib/test_data/active_record_ext.rb) to make sure you're comfortable with
what it's doing.)

### TestData.config

The generated `config/initializers/test_data.rb` initializer will include a call
to `TestData.config`, which takes a block that yields a mutable configuration
object (similar to `Rails.application.config`). If anything is unclear after
reading the documentation, feel free to review the
[initializer](lib/generators/test_data/initializer_generator.rb) and the [Config
class](/lib/test_data/config.rb) themselves.

#### Lifecycle hooks

Want to shift forward several timestamp fields after your `test_data` SQL dumps
are loaded into your test database? Need to refresh a materialized view after
your Rails fixtures are loaded? You _could_ do these things after calling
`TestData.uses_test_data` and `TestData.uses_rails_fixtures`, respectively, but
you'd take the corresponding performance hit in each and every test.

Instead, you can pass a callable or a block and `test_data` will execute it just
_after_ performing the associated data operation but just _before_ creating a
transaction savepoint. That way, whenever the gem rolls back between tests, your
hook won't need to be run again.

##### config.after_test_data_load

This is hook is run immediately after `TestData.uses_test_data` has loaded your
SQL dumps into the `test` database, but before creating a savepoint. Takes a
block or anything that responds to `call`.


```ruby
TestData.config do |config|
  # Example: roll time forward
  config.after_test_data_load do
    Boop.connection.exec_update(<<~SQL, nil, [[nil, Time.zone.now - System.epoch]])
      update boops set booped_at = booped_at + $1
    SQL
  end
end
```

##### config.after_test_data_truncate

This is hook is run immediately after `TestData.uses_clean_slate` has truncated
your test data, but before creating a savepoint. Takes a block or anything that
responds to `call`.

```ruby
TestData.config do |config|
  # Example: pass a callable instead of a block
  config.after_test_data_truncate(SomethingThatRespondsToCall.new)
end
```

##### config.after_rails_fixture_load

This is hook is run immediately after `TestData.uses_rails_fixtures` has loaded
your Rails fixtures into the `test` database, but before creating a savepoint.
Takes a block or anything that responds to `call`.

```ruby
TestData.config do |config|
  # Example: refresh Postgres assets like materialized views
  config.after_rails_fixture_load do
    RefreshesMaterializedViews.new.call
  end
end
```

#### test_data:dump options

The gem provides several options governing the behavior of the
[test_data:dump](#test_datadump) Rake task. You probably won't need to set these
unless you run into a problem with the defaults.

##### config.non_test_data_tables

Your application may have some tables that are necessary for the operation of
the application, but irrelevant or incompatible with you your tests. This data
is still dumped for the sake of being able to restore the database with [rake
test_data:load](#test_dataload), but will not be loaded when your tests are
running. Defaults to `[]`, (but will always include `ar_internal_metadata` and
`schema_migrations`).

```ruby
TestData.config do |config|
  config.non_test_data_tables = []
end
```

##### config.dont_dump_these_tables

Some tables populated by your application may not be necessary to either its
proper functioning or useful to your tests (e.g. audit logs), so you can save
time and storage by preventing those tables from being dumped entirely. Defaults
to `[]`.

```ruby
TestData.config do |config|
  config.dont_dump_these_tables = []
end
```

##### config.schema_dump_path

The path to which the schema DDL of your `test_data` database will be written.
This is only used by [rake test_data:load](#test_dataload) when initializing the
`test_data` database. Defaults to `"test/support/test_data/schema.sql"`.

```ruby
TestData.config do |config|
  config.schema_dump_path = "test/support/test_data/schema.sql"
end
```

##### config.data_dump_path

The path that the SQL dump of your test data will be written. This is the dump
that will be executed by `TestData.uses_test_data` in your tests. Defaults to
`"test/support/test_data/data.sql"`.

```ruby
TestData.config do |config|
  config.data_dump_path = "test/support/test_data/data.sql"
end
```

##### config.non_test_data_dump_path

The path to which the [non_test_data_tables](#confignon_test_data_tables) in
your `test_data` database will be written. This is only used by [rake
test_data:load](#test_dataload) when initializing the `test_data` database.
Defaults to `"test/support/test_data/non_test_data.sql"`.

```ruby
TestData.config do |config|
  config.non_test_data_dump_path = "test/support/test_data/non_test_data.sql"
end
```

#### Other configuration options

##### config.truncate_these_test_data_tables

By default, when [TestData.uses_clean_slate](#testdatauses_clean_slate) is
called, it will truncate any tables for which an `INSERT` operation was
detected in your test data SQL dump. This may not be suitable for every case,
however, so this option allows you to specify which tables are truncated.
Defaults to `nil`.

```ruby
TestData.config do |config|
  config.truncate_these_test_data_tables = []
end
```

##### config.log_level

The gem outputs its messages to standard output and error by assigning a log
level to each message. Valid values are `:debug`, `:info`, `:warn`, `:error`,
`:quiet`. Defaults to `:info`.

```ruby
TestData.config do |config|
  config.log_level = :info
end
```

### TestData.insert_test_data_dump

If you just want to insert the test data in your application's SQL dumps without
any of the transaction management or test runner assumptions inherent in
[TestData.uses_test_data](#testdatauses_test_data), then you can call
`TestData.insert_test_data_dump` to load and execute the dump.

This might be necessary in a few different situations:

* Running tests in environments that can't be isolated to a single database
  transaction (e.g. orchestrating tests across multiple databases, processes,
  etc.)
* You might ant to use your test data to seed pre-production environments with
  enough data to exploratory test (as you might do in a `postdeploy` script with
  your [Heroku Review
  Apps](https://devcenter.heroku.com/articles/github-integration-review-apps))
* Your tests require complex heterogeneous sources of data that aren't a good
  fit for the assumptions and constraints of this library's default methods for
  preparing test data

In any case, since `TestData.insert_test_data_dump` is not wrapped in a
transaction, when used for automated tests, data cleanup becomes your
responsibility.

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

* Your integration tests are super fast and are not getting significantly slower
  over time

* Minor changes to existing factories rarely result in test failures that
  require unrelated tests to be read & updated to get them passing again

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

If none of these things are true, then congratulations! You are probably using
`factory_bot` to great effect! Unfortunately, in our experience, this outcome
is exceedingly rare, especially for large and long-lived applications.

However, if you'd answer "no" to any of the above questions, just know that
these are the sorts of failure modes the `test_data` gem was designed to
avoid—and we hope you'll consider trying it with an open mind. At the same time,
we acknowledge that large test suites can't be rewritten and migrated to a
different source of test data overnight—nor should they be! See our notes on
[migrating to `test_data`
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

However, if your app is in the very initial stages of development or you're
otherwise making breaking changes to your schema and data very frequently, our
best advice is to hold off a bit on writing _any_ integration tests that depend
on shared sources of test data (regardless of tool), as they'll be more likely
to frustrate your ability to rapidly iterate than detect bugs. Once you you have
a reasonably stable feature working end-to-end, that's a good moment to start
adding integration tests—and perhaps pulling in a gem like this one to help you.

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
they were deployed into a long-lived staging or (gasp!) production environment.

### Are you sure I should commit these SQL dumps? They're way too big!

If the dump files generated by `test_data:dump` seem massive, consider the
cause:

1. If you inadvertently created more data than necessary, you might consider
   resetting (or rolling back) your changes and making another attempt at
   generating a more minimal set of test data

2. If some records persisted by your application aren't very relevant to your
   tests, you might consider either of these options:

    * If certain tables are necessary for running the app but aren't needed by
      your tests, you can add them to the `config.non_test_data_tables`
      configuration array. They'll still be committed to git, but won't loaded
      by your tests

    * If the certain tables are not needed by your application or by your tests
      (e.g. audit logs), add them to the `config.dont_dump_these_tables` array,
      and they won't be persisted by `rake test_data:dump`

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
  user = User.create!(orders: [good_order, bad_order])

  result = user.active_orders

  assert_includes good_order
  refute_includes bad_order
end
```

This test is simple, self-contained, clearly demarcates the
[arrange-act-assert](https://github.com/testdouble/contributing-tests/wiki/Arrange-Act-Assert)
phases, and (most importantly) will only fail if the functionality stops
working. Maximizing the number of tests that can be written expressively and
succinctly without the aid of shared test data is a laudable goal that more
teams should embrace.

However, what if the code you're writing doesn't need 3 records in the database,
but 30? Writing that much test setup would be painstaking, despite being
fully-encapsulated. Long test setup is harder for others to read and understand.
And because that setup depends on more of your system's code, it will have more
reasons to break as your codebase changes. At that point, you have two options:

1. Critically validate your design: why is it so hard to set up? Does it
   _really_ require so much persisted data to exercise this behavior? Would a
   [plain old Ruby
   object](https://steveklabnik.com/writing/the-secret-to-rails-oo-design) that
   defined a pure function have been feasible? Could a model instance or even a
   `Struct` be passed to the
   [subject](https://github.com/testdouble/contributing-tests/wiki/Subject)
   instead of loading everything from the database? When automated testing is
   saved for the very end of a feature's development, it can feel too costly to
   reexamine design decisions like this, but it can be valuable to consider all
   the same. *Easy to test code is easy to use code*

2. If the complex setup is a necessary reality of the situation that your app
   needs to handle (and it often will be!), then having _some_ kind of shared
   source of test data to use as a starting point can be hugely beneficial.
   That's why `factory_bot` is so popular, why this gem exists, etc.

As a result, there is no one-size-fits-all approach. Straightforward behavior
that can be invoked with a clear, concise test has no reason to be coupled to a
shared source of test data. Meanwhile, tests of more complex behaviors that
require lots of carefully-arranged data might be unmaintainable without a shared
source of test data to lean on. So both kinds of test clearly have their place.

But this is a pretty nuanced discussion that can be hard to keep in mind when
under deadline pressure or on a large team where building consensus around norms
is challenging. As a result, leaving the decision of which type of test to write
to spur-of-the-moment judgment is likely to result in inconsistent test design.
Instead, you might consider separating these two categories into separate test
types or suites, with simple heuristics to determine which types of code demand
which type of test.

For example, it would be completely reasonable to load this gem's test data for
integration tests, but not for basic tests of models, like so:

```ruby
class ActionDispatch::IntegrationTest
  setup do
    TestData.uses_test_data
  end
end

class ActiveSupport::TestCase
  setup do
    TestData.uses_clean_slate
  end
end
```

In short, this skepticism is generally healthy, and encapsulated tests that
forego reliance on shared sources of test data should be maximized. For
everything else, there's `test_data`.

### I'm worried my tests aren't as fast as they should be

The `test_data` gem was written to enable tests that are not only more
comprehensible and maintainable over the long-term, but also _much faster_ to
run. That said—and especially if you're adding `test_data` to an existing test
suite—care should be taken to audit everything the suite does between tests in
order to optimize its overall runtime.

#### Randomized test order leading to data churn

Generally speaking, randomizing the order in which tests run is an unmitigated
win: randomizing helps you catch any unintended dependency between two tests
early, when it's still cheap & easy to fix. However, if your tests use different
sources of test data (e.g. some call `TestData.uses_test_data` and some call
`TestData.uses_clean_slate`), it's very likely that randomizing your tests will
result in a significantly slower overall test suite. Instead, if you group tests
that use the same type of test data together (e.g. by separating them into
separate suites), you might find profound speed gains.

To illustrate this, suppose you had 5 tests that relied on your `test_data` data
and 5 that relied on Rails fixtures. If all of these tests ran in random order
(the default), you might see the following behavior at run-time:

```
$ bin/rails test test/example_test.rb
Run options: --seed 63999

# Running:

   test_data -- loading test_data SQL dump
.  fixtures  -- truncating tables, loading Rails fixtures
.  fixtures  -- rolling back to Rails fixtures
.  test_data -- rolling back to clean test_data
.  fixtures  -- truncating tables, loading Rails fixtures
.  test_data -- rolling back to clean test_data
.  fixtures  -- truncating tables, loading Rails fixtures
.  test_data -- rolling back to clean test_data
.  fixtures  -- truncating tables, loading Rails fixtures
.  test_data -- rolling back to clean test_data
.

Finished in 2.449957s, 4.0817 runs/s, 4.0817 assertions/s.
10 runs, 10 assertions, 0 failures, 0 errors, 0 skips
```

So, what can you do to speed this up? The most effective strategy to avoiding
this churn is to group the execution of each tests that use each source of test
data into sub-suites that are run serially, on e after the other.

* If you're using Rails' defualt Minitest, we wrote a gem called
  [minitest-suite](https://github.com/testdouble/minitest-suite) to accomplish
  exactly this. Just declare something like `suite :test_data` or `suite
  :fixtures` at the top of each test class
* If you're using RSpec, the [suite option combined with a custom
  ordering](https://gist.github.com/myronmarston/8fea012b9eb21b637335bb29069bce6b)
  can accomplish this. You might also consider using
  [tags](https://relishapp.com/rspec/rspec-core/v/3-10/docs/command-line/tag-option)
  to organize your tests by type, but you'll likely have to
  run a separate CLI invocation for each to avoid the tests from being
  interleaved

Here's what the same example would do at run-time after adding
[minitest-suite](https://github.com/testdouble/minitest-suite):

```
$ bin/rails test test/example_test.rb
Run options: --seed 50105

# Running:

   test_data -- loading test_data SQL dump
.  test_data -- rolling back to clean test_data
.  test_data -- rolling back to clean test_data
.  test_data -- rolling back to clean test_data
.  test_data -- rolling back to clean test_data
.  fixtures -- truncating tables, loading Rails fixtures
.  fixtures -- rolling back to clean fixtures
.  fixtures -- rolling back to clean fixtures
.  fixtures -- rolling back to clean fixtures
.  fixtures -- rolling back to clean fixtures
.

Finished in 2.377050s, 4.2069 runs/s, 4.2069 assertions/s.
10 runs, 10 assertions, 0 failures, 0 errors, 0 skips
```

By grouping the execution in this way, the most expensive operations will
usually only be run once: at the beginning of the first test in each suite.

#### Expensive data manipulation

If you're doing anything repeatedly that's data-intensive in your test setup
after calling one of the `TestData.uses_*` methods, that operation is being
repeated once per test, which could be very slow. Instead, you might consider
moving that behavior into a [lifecycle hook](#lifecycle-hooks).

Any code passed to a lifecycle hook will only be executed when data is
_actually_ loaded or truncated and its effect will be included in the
transaction savepoint that the `test_data` gem rolls back between tests.
Seriously, appropriately moving data adjustments into these hooks can cut your
test suite's runtime by an order of magnitude.

#### Redundant test setup tasks

One of the most likely sources of unnecessary slowness is redundant test
cleanup. The speed gained from sandwiching every expensive operation between
transaction savepoints can be profound… but can also easily be erased by a
single before-each hook calling
[database_cleaner](https://github.com/DatabaseCleaner/database_cleaner) to
commit a truncation of the database. As a result, it's worth taking a little
time to take stock of everything that's called between tests during setup &
teardown to ensure multiple tools aren't attempting to clean up the state of the
database and potentially interfering with one another.

## Code of Conduct

This project follows Test Double's [code of
conduct](https://testdouble.com/code-of-conduct) for all community interactions,
including (but not limited to) one-on-one communications, public posts/comments,
code reviews, pull requests, and GitHub issues. If violations occur, Test Double
will take any action they deem appropriate for the infraction, up to and
including blocking a user from the organization's repositories.

