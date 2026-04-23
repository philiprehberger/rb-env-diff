# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-04-14

### Added
- `EnvDiff.validate(target, required:)` — check that all required keys exist in a target hash or .env file
- `case_sensitive:` keyword on `compare`, `from_hash`, `from_env_file`, and `from_system` — normalize keys to uppercase when false
- `EnvDiff.to_markdown(diff)` — format a diff result as a Markdown table string
- `EnvDiff.to_html(diff)` — format a diff result as an HTML table string

## [0.2.0] - 2026-04-03

### Added
- `Diff#summary(mask:)` — mask values for sensitive keys using string or regex patterns
- `Diff#to_h` — structured hash output with added, removed, changed, and unchanged categories
- `Diff#to_json` — JSON serialization of the structured hash
- `Diff#filter(pattern:)` — return a new Diff containing only keys matching a regex pattern
- `Diff#stats` — returns counts of added, removed, changed, unchanged, and total keys
- `EnvDiff.from_system(target)` — compare current ENV against a target hash or .env file path

## [0.1.8] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.7] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.6] - 2026-03-26

### Changed
- Add Sponsor badge to README
- Fix License section format


## [0.1.5] - 2026-03-24

### Fixed
- Remove inline comments from Development section to match template

## [0.1.4] - 2026-03-22

### Changed

- Expand test coverage to 30+ examples with edge cases for identical environments, empty inputs, case sensitivity, whitespace handling, and parser edge cases

## [0.1.4] - 2026-03-21

### Fixed
- Standardize Installation section in README

## [0.1.3] - 2026-03-16

### Changed
- Add License badge to README
- Add bug_tracker_uri to gemspec

## [0.1.2] - 2026-03-13

### Fixed
- Fix RuboCop ExtraSpacing offense in gemspec metadata

## [0.1.0] - 2026-03-13

### Added
- Initial release
- Compare two environment variable hashes and report added, removed, changed, and unchanged keys
- Parse `.env` files with support for comments, blank lines, quoted values, and `export` prefix
- `Diff` class with `changed?` predicate and human-readable `summary`
- Module-level `compare`, `from_hash`, and `from_env_file` convenience methods
