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

