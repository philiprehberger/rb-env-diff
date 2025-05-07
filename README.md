# philiprehberger-env_diff

[![Tests](https://github.com/philiprehberger/rb-env-diff/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-env-diff/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-env_diff.svg)](https://rubygems.org/gems/philiprehberger-env_diff)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-env-diff)](https://github.com/philiprehberger/rb-env-diff/commits/main)

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

### Masked summary

Hide sensitive values in the summary output using exact strings or regex patterns:

```ruby
puts diff.summary(mask: ["SECRET", /PASSWORD|TOKEN/])
# + NEW_KEY
# - OLD_KEY
# ~ SECRET: *** -> ***
```

### Structured output

```ruby
diff.to_h
# => { added: { "NEW_KEY" => "added" }, removed: { "OLD_KEY" => "remove_me" },
#      changed: { "DATABASE_URL" => { source: "postgres://localhost/dev", target: "postgres://prod-host/app" } },
#      unchanged: { "SECRET" => "abc" } }

diff.to_json  # => JSON string of the structured hash
```

### Filter by pattern

```ruby
db_diff = diff.filter(pattern: /^DATABASE/)
db_diff.changed.keys  # => ["DATABASE_URL"]
```

### Stats

```ruby
diff.stats
# => { added: 1, removed: 1, changed: 1, unchanged: 1, total: 4 }
```

### Compare against system ENV

```ruby
diff = Philiprehberger::EnvDiff.from_system({ "APP_ENV" => "production" })
diff = Philiprehberger::EnvDiff.from_system(".env.production")
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
| `EnvDiff.from_system(target)` | Compare current `ENV` against a target hash or `.env` file path |
| `Diff#added` | Array of keys in target but not source |
| `Diff#removed` | Array of keys in source but not target |
| `Diff#changed` | Hash of keys with different values |
| `Diff#unchanged` | Array of keys with identical values |
| `Diff#changed?` | `true` if any differences exist |
| `Diff#summary(mask: [])` | Human-readable multiline diff string with optional value masking |
| `Diff#to_h` | Structured hash with `:added`, `:removed`, `:changed`, `:unchanged` |
| `Diff#to_json` | JSON serialization of the structured hash |
| `Diff#filter(pattern:)` | New `Diff` containing only keys matching the regex pattern |
| `Diff#stats` | Hash of counts: `:added`, `:removed`, `:changed`, `:unchanged`, `:total` |
| `Parser.parse(content)` | Parse `.env` string into a hash |
| `Parser.parse_file(path:)` | Read and parse a `.env` file |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-env-diff)

🐛 [Report issues](https://github.com/philiprehberger/rb-env-diff/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-env-diff/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
