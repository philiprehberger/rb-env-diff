# philiprehberger-env_diff

[![Tests](https://github.com/philiprehberger/rb-env-diff/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-env-diff/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-env_diff.svg)](https://rubygems.org/gems/philiprehberger-env_diff)
[![License](https://img.shields.io/github/license/philiprehberger/rb-env-diff)](LICENSE)

Compare environment variables across environments and report differences

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-env_diff"
```

Or install directly:

```bash
gem install philiprehberger-env_diff
```

## Usage

```ruby
require "philiprehberger/env_diff"

# Compare two hashes
source = { "DATABASE_URL" => "postgres://localhost/dev", "SECRET" => "abc", "OLD_KEY" => "remove_me" }
target = { "DATABASE_URL" => "postgres://prod-host/app", "SECRET" => "abc", "NEW_KEY" => "added" }

diff = Philiprehberger::EnvDiff.compare(source, target)

diff.added     # => ["NEW_KEY"]
diff.removed   # => ["OLD_KEY"]
diff.changed   # => { "DATABASE_URL" => { source: "postgres://localhost/dev", target: "postgres://prod-host/app" } }
diff.unchanged # => ["SECRET"]
diff.changed?  # => true
puts diff.summary
# + NEW_KEY
# - OLD_KEY
# ~ DATABASE_URL: "postgres://localhost/dev" -> "postgres://prod-host/app"
```

### Compare .env files

```ruby
diff = Philiprehberger::EnvDiff.from_env_file(".env.development", ".env.production")
puts diff.summary
```

### Parse .env files

```ruby
vars = Philiprehberger::EnvDiff::Parser.parse(<<~ENV)
  # Database config
  DATABASE_URL=postgres://localhost/dev
  export SECRET_KEY="my-secret"
  APP_NAME='my-app'
ENV
# => { "DATABASE_URL" => "postgres://localhost/dev", "SECRET_KEY" => "my-secret", "APP_NAME" => "my-app" }
```

## API

| Method / Class | Description |
|----------------|-------------|
| `EnvDiff.compare(source, target)` | Compare two hashes and return a `Diff` |
| `EnvDiff.from_hash(hash_a, hash_b)` | Alias for `compare` |
| `EnvDiff.from_env_file(path_a, path_b)` | Parse two `.env` files and compare them |
| `Diff#added` | Array of keys in target but not source |
| `Diff#removed` | Array of keys in source but not target |
| `Diff#changed` | Hash of keys with different values |
| `Diff#unchanged` | Array of keys with identical values |
| `Diff#changed?` | `true` if any differences exist |
| `Diff#summary` | Human-readable multiline diff string |
| `Parser.parse(content)` | Parse `.env` string into a hash |
| `Parser.parse_file(path:)` | Read and parse a `.env` file |

## Development

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec rubocop    # Check code style
```

## License

MIT
