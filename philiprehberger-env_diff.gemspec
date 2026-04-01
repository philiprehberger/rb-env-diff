# frozen_string_literal: true

require_relative 'lib/philiprehberger/env_diff/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-env_diff'
  spec.version = Philiprehberger::EnvDiff::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']

  spec.summary = 'Compare environment variables across environments and report differences'
  spec.description = 'Parse .env files or environment hashes, compare them, ' \
                     'and get a clear report of added, removed, changed, and unchanged variables.'
  spec.homepage = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-env_diff'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/philiprehberger/rb-env-diff'
  spec.metadata['changelog_uri'] = 'https://github.com/philiprehberger/rb-env-diff/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/philiprehberger/rb-env-diff/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
