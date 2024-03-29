# 0.3.2

- Improve the flexibility of the webpacker config generator
- Improve failure output when an error is raised during rake tests that fork
  into a `test_data` env

# 0.3.1

- Loosen railties dependencies after verifying basic Rails 7 support

# 0.3.0

- Add a `test_data:reinitialize` task that will delete the `test_data` database
  if necessary before invoking `test_data:initialize`
  - Warn if re-initializing and the local database appears to have been dumped
    or loaded from a dump that is newer than the dumps on disk
- Add a warning on app load if the dumps on disk appear
  newer than the local `test_data` database

# 0.2.2

- Improve performance of Rails fixtures being repeatedly loaded by changing the
caching strategy

# 0.2.1

- Adds several lifecycle hooks:
  - config.after_test_data_load
  - config.after_test_data_truncate
  - config.after_rails_fixture_load

# 0.2.0

- BREAKING CHANGES: Remove or rename a bunch of APIs that aren't quite necessary
  and leak too much implementation, requiring too much cognitive load for users.
  - Remove config.use_transactional_data_loader
  - Remove TestData.rollback
  - Change TestData.load to TestData.uses_test_data and make it transaction-only
  - Change TestData.truncate to TestData.uses_clean_slate and make it
    transaction-only
  - Change TestData.load_rails_fixtures to TestData.uses_rails_fixtures and make
    it transaction-only
  - Add TestData.insert_test_data_dump, which will blindly insert the test SQL
    dump of test data without any transaction management
- [#2](https://github.com/testdouble/test_data/issues/2) - Work around
  hard-coded environment names when initializing test_data environment secrets

# 0.1.0

- New feature: `TestData.load_rails_fixtures` to override default fixtures
  behavior by loading it in a nested transaction after `TestData.truncate`
- Breaking change: move transactions configuration out of `TestData.load` and
  instead a global setting for `TestData.config` named
  `use_transactional_data_loader`
- Cascades truncation of test_data tables unless they're explicitly specified by
  the truncate_these_test_data_tables` option
- Add secrets.yml and cable.yml generators to `test_data:configure` task
- Print the size of each dump and warn when dump size reaches certain thresholds
  or increases significantly in the `test_data:dump` task

# 0.0.2

- Make the rest of the gem better
- Rename `TransactionData.load_data_dump` to `TransactionData.load`

# 0.0.1

- Make it work

