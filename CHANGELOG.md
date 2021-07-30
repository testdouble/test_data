# unreleased

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

