# frozen_string_literal: true

require 'database_cleaner/active_record'

RSpec.configure do |config|
  config.before(:suite) do
    # DATABASE_URL uses the Docker service hostname "db" which DatabaseCleaner
    # considers remote. Explicitly allow it since this is an isolated test DB.
    DatabaseCleaner.allow_remote_database_url = true

    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    DatabaseCleaner.strategy = example.metadata[:type] == :system ? :truncation : :transaction
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
