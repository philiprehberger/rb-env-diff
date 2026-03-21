# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
