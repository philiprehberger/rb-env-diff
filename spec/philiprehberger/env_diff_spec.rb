# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'json'

RSpec.describe Philiprehberger::EnvDiff do
  it 'has a version number' do
    expect(Philiprehberger::EnvDiff::VERSION).not_to be_nil
  end

  describe '.compare' do
    it 'detects added keys' do
      diff = described_class.compare({ 'A' => '1' }, { 'A' => '1', 'B' => '2' })
      expect(diff.added).to eq(['B'])
    end

    it 'detects removed keys' do
      diff = described_class.compare({ 'A' => '1', 'B' => '2' }, { 'A' => '1' })
      expect(diff.removed).to eq(['B'])
    end

    it 'detects changed keys' do
      diff = described_class.compare({ 'A' => '1' }, { 'A' => '2' })
      expect(diff.changed).to eq({ 'A' => { source: '1', target: '2' } })
    end

    it 'detects unchanged keys' do
      diff = described_class.compare({ 'A' => '1', 'B' => '2' }, { 'A' => '1', 'B' => '3' })
      expect(diff.unchanged).to eq(['A'])
    end

    it 'handles all difference types together' do
      source = { 'KEEP' => 'same', 'CHANGE' => 'old', 'REMOVE' => 'bye' }
      target = { 'KEEP' => 'same', 'CHANGE' => 'new', 'ADD' => 'hello' }
      diff = described_class.compare(source, target)

      expect(diff.added).to eq(['ADD'])
      expect(diff.removed).to eq(['REMOVE'])
      expect(diff.changed).to eq({ 'CHANGE' => { source: 'old', target: 'new' } })
      expect(diff.unchanged).to eq(['KEEP'])
    end
  end

  describe Philiprehberger::EnvDiff::Diff do
    describe '#changed?' do
      it 'returns true when there are differences' do
        diff = described_class.new({ 'A' => '1' }, { 'B' => '2' })
        expect(diff.changed?).to be true
      end

      it 'returns false when hashes are identical' do
        diff = described_class.new({ 'A' => '1' }, { 'A' => '1' })
        expect(diff.changed?).to be false
      end

      it 'returns false for empty hashes' do
        diff = described_class.new({}, {})
        expect(diff.changed?).to be false
      end
    end

    describe '#summary' do
      it "returns 'No differences found.' for identical hashes" do
        diff = described_class.new({ 'A' => '1' }, { 'A' => '1' })
        expect(diff.summary).to eq('No differences found.')
      end

      it 'includes added, removed, and changed keys' do
        source = { 'KEEP' => 'same', 'CHANGE' => 'old', 'REMOVE' => 'bye' }
        target = { 'KEEP' => 'same', 'CHANGE' => 'new', 'ADD' => 'hello' }
        diff = described_class.new(source, target)
        summary = diff.summary

        expect(summary).to include('+ ADD')
        expect(summary).to include('- REMOVE')
        expect(summary).to include('~ CHANGE')
      end

      it 'returns no-diff message for empty hashes' do
        diff = described_class.new({}, {})
        expect(diff.summary).to eq('No differences found.')
      end
    end

    describe '#summary with mask' do
      let(:source) { { 'SECRET_KEY' => 'abc123', 'DB_PASSWORD' => 'pass', 'APP_NAME' => 'myapp', 'PORT' => '3000' } }
      let(:target) { { 'SECRET_KEY' => 'xyz789', 'API_TOKEN' => 'tok', 'APP_NAME' => 'myapp' } }
      let(:diff) { described_class.new(source, target) }

      it 'masks values for exact string match' do
        summary = diff.summary(mask: ['SECRET_KEY'])
        expect(summary).to include('~ SECRET_KEY: *** -> ***')
        expect(summary).not_to include('abc123')
        expect(summary).not_to include('xyz789')
      end

      it 'masks values for regex match' do
        summary = diff.summary(mask: [/SECRET|TOKEN|PASSWORD/])
        expect(summary).to include('~ SECRET_KEY: *** -> ***')
        expect(summary).to include('+ API_TOKEN=***')
        expect(summary).to include('- DB_PASSWORD=***')
      end

      it 'does not mask non-matching keys' do
        summary = diff.summary(mask: [/SECRET/])
        expect(summary).to include('- PORT')
        expect(summary).not_to include('PORT=***')
      end

      it 'handles empty mask array' do
        summary_masked = diff.summary(mask: [])
        summary_default = diff.summary
        expect(summary_masked).to eq(summary_default)
      end
    end

    describe '#to_h' do
      it 'returns structured hash with all categories' do
        source = { 'KEEP' => 'same', 'CHANGE' => 'old', 'REMOVE' => 'bye' }
        target = { 'KEEP' => 'same', 'CHANGE' => 'new', 'ADD' => 'hello' }
        diff = described_class.new(source, target)
        result = diff.to_h

        expect(result[:added]).to eq({ 'ADD' => 'hello' })
        expect(result[:removed]).to eq({ 'REMOVE' => 'bye' })
        expect(result[:changed]).to eq({ 'CHANGE' => { source: 'old', target: 'new' } })
        expect(result[:unchanged]).to eq({ 'KEEP' => 'same' })
      end

      it 'returns empty hashes when no differences' do
        diff = described_class.new({ 'A' => '1' }, { 'A' => '1' })
        result = diff.to_h

        expect(result[:added]).to eq({})
        expect(result[:removed]).to eq({})
        expect(result[:changed]).to eq({})
        expect(result[:unchanged]).to eq({ 'A' => '1' })
      end
    end

    describe '#to_json' do
      it 'returns valid JSON matching to_h' do
        source = { 'A' => '1', 'B' => '2' }
        target = { 'A' => '3', 'C' => '4' }
        diff = described_class.new(source, target)
        parsed = JSON.parse(diff.to_json)

        expect(parsed['added']).to eq({ 'C' => '4' })
        expect(parsed['removed']).to eq({ 'B' => '2' })
        expect(parsed['changed']).to eq({ 'A' => { 'source' => '1', 'target' => '3' } })
        expect(parsed['unchanged']).to eq({})
      end
    end

    describe '#filter' do
      let(:source) { { 'DB_HOST' => 'localhost', 'DB_PORT' => '5432', 'APP_NAME' => 'myapp', 'REMOVED' => 'x' } }
      let(:target) { { 'DB_HOST' => 'prod', 'DB_PORT' => '5432', 'APP_NAME' => 'myapp', 'DB_PASS' => 'secret' } }
      let(:diff) { described_class.new(source, target) }

      it 'returns a new Diff with only matching keys' do
        filtered = diff.filter(pattern: /^DB_/)
        expect(filtered.added).to eq(['DB_PASS'])
        expect(filtered.removed).to eq([])
        expect(filtered.changed.keys).to eq(['DB_HOST'])
        expect(filtered.unchanged).to eq(['DB_PORT'])
      end

      it 'excludes non-matching keys' do
        filtered = diff.filter(pattern: /^DB_/)
        expect(filtered.added).not_to include('APP_NAME')
        expect(filtered.removed).not_to include('REMOVED')
      end

      it 'returns empty diff when no keys match' do
        filtered = diff.filter(pattern: /^ZZZZZ/)
        expect(filtered.changed?).to be false
        expect(filtered.stats[:total]).to eq(0)
      end
    end

    describe '#stats' do
      it 'returns counts for each category' do
        source = { 'KEEP' => 'same', 'CHANGE' => 'old', 'REMOVE' => 'bye' }
        target = { 'KEEP' => 'same', 'CHANGE' => 'new', 'ADD' => 'hello' }
        diff = described_class.new(source, target)
        result = diff.stats

        expect(result[:added]).to eq(1)
        expect(result[:removed]).to eq(1)
        expect(result[:changed]).to eq(1)
        expect(result[:unchanged]).to eq(1)
        expect(result[:total]).to eq(4)
      end

      it 'returns all zeros for empty hashes' do
        diff = described_class.new({}, {})
        expect(diff.stats).to eq({ added: 0, removed: 0, changed: 0, unchanged: 0, total: 0 })
      end
    end
  end

  describe Philiprehberger::EnvDiff::Parser do
    describe '.parse' do
      it 'parses simple KEY=VALUE pairs' do
        result = described_class.parse("FOO=bar\nBAZ=qux")
        expect(result).to eq({ 'FOO' => 'bar', 'BAZ' => 'qux' })
      end

      it 'ignores comments' do
        result = described_class.parse("# this is a comment\nFOO=bar")
        expect(result).to eq({ 'FOO' => 'bar' })
      end

      it 'ignores blank lines' do
        result = described_class.parse("FOO=bar\n\n\nBAZ=qux")
        expect(result).to eq({ 'FOO' => 'bar', 'BAZ' => 'qux' })
      end

      it 'handles double-quoted values' do
        result = described_class.parse('FOO="hello world"')
        expect(result).to eq({ 'FOO' => 'hello world' })
      end

      it 'handles single-quoted values' do
        result = described_class.parse("FOO='hello world'")
        expect(result).to eq({ 'FOO' => 'hello world' })
      end

      it 'handles export prefix' do
        result = described_class.parse('export FOO=bar')
        expect(result).to eq({ 'FOO' => 'bar' })
      end

      it 'handles empty values' do
        result = described_class.parse('FOO=')
        expect(result).to eq({ 'FOO' => '' })
      end
    end

    describe '.parse_file' do
      it 'reads and parses a file' do
        file = Tempfile.new('.env')
        file.write("FOO=bar\nBAZ=qux")
        file.close

        result = described_class.parse_file(path: file.path)
        expect(result).to eq({ 'FOO' => 'bar', 'BAZ' => 'qux' })
      ensure
        file&.unlink
      end
    end
  end

  describe '.from_hash' do
    it 'compares two hashes' do
      diff = described_class.from_hash({ 'A' => '1' }, { 'A' => '2' })
      expect(diff.changed?).to be true
      expect(diff.changed).to eq({ 'A' => { source: '1', target: '2' } })
    end
  end

  describe '.from_env_file' do
    it 'parses and compares two env files' do
      file_a = Tempfile.new('.env.a')
      file_a.write("FOO=bar\nOLD=val")
      file_a.close

      file_b = Tempfile.new('.env.b')
      file_b.write("FOO=baz\nNEW=val")
      file_b.close

      diff = described_class.from_env_file(file_a.path, file_b.path)
      expect(diff.added).to eq(['NEW'])
      expect(diff.removed).to eq(['OLD'])
      expect(diff.changed).to eq({ 'FOO' => { source: 'bar', target: 'baz' } })
    ensure
      file_a&.unlink
      file_b&.unlink
    end
  end

  describe '.from_system' do
    it 'compares ENV against a target hash' do
      target = { 'PATH' => '/custom/path', 'NONEXISTENT_VAR_XYZ' => 'value' }
      diff = described_class.from_system(target)

      expect(diff).to be_a(Philiprehberger::EnvDiff::Diff)
      expect(diff.added).to include('NONEXISTENT_VAR_XYZ')
    end

    it 'compares ENV against a .env file path' do
      file = Tempfile.new('.env.target')
      file.write("NONEXISTENT_VAR_ABC=hello\n")
      file.close

      diff = described_class.from_system(file.path)
      expect(diff.added).to include('NONEXISTENT_VAR_ABC')
    ensure
      file&.unlink
    end

    it 'detects changed values compared to ENV' do
      env_key = ENV.keys.first
      target = { env_key => 'definitely_not_the_real_value_12345' }
      diff = described_class.from_system(target)

      expect(diff.changed.keys).to include(env_key)
    end
  end

  describe '.compare edge cases' do
    it 'returns no differences for identical environments' do
      env = { 'A' => '1', 'B' => '2' }
      diff = described_class.compare(env, env.dup)
      expect(diff.changed?).to be false
      expect(diff.added).to be_empty
      expect(diff.removed).to be_empty
      expect(diff.changed).to be_empty
      expect(diff.unchanged).to eq(%w[A B])
    end

    it 'handles both environments empty' do
      diff = described_class.compare({}, {})
      expect(diff.changed?).to be false
      expect(diff.unchanged).to be_empty
    end

    it 'handles source empty and target full' do
      diff = described_class.compare({}, { 'A' => '1', 'B' => '2' })
      expect(diff.added).to eq(%w[A B])
      expect(diff.removed).to be_empty
      expect(diff.changed).to be_empty
    end

    it 'handles source full and target empty' do
      diff = described_class.compare({ 'A' => '1', 'B' => '2' }, {})
      expect(diff.added).to be_empty
      expect(diff.removed).to eq(%w[A B])
      expect(diff.changed).to be_empty
    end

    it 'treats keys as case-sensitive' do
      diff = described_class.compare({ 'foo' => '1' }, { 'FOO' => '1' })
      expect(diff.removed).to eq(['foo'])
      expect(diff.added).to eq(['FOO'])
    end

    it 'detects value-only whitespace differences' do
      diff = described_class.compare({ 'A' => 'hello' }, { 'A' => 'hello ' })
      expect(diff.changed).to eq({ 'A' => { source: 'hello', target: 'hello ' } })
    end

    it 'handles empty string values' do
      diff = described_class.compare({ 'A' => '' }, { 'A' => '' })
      expect(diff.changed?).to be false
      expect(diff.unchanged).to eq(['A'])
    end

    it 'detects empty vs non-empty value' do
      diff = described_class.compare({ 'A' => '' }, { 'A' => 'val' })
      expect(diff.changed).to eq({ 'A' => { source: '', target: 'val' } })
    end
  end

  describe Philiprehberger::EnvDiff::Diff do
    describe '#summary edge cases' do
      it 'formats multiple added keys' do
        diff = described_class.new({}, { 'X' => '1', 'Y' => '2', 'Z' => '3' })
        summary = diff.summary
        expect(summary).to include('+ X')
        expect(summary).to include('+ Y')
        expect(summary).to include('+ Z')
      end

      it 'formats multiple removed keys' do
        diff = described_class.new({ 'X' => '1', 'Y' => '2' }, {})
        summary = diff.summary
        expect(summary).to include('- X')
        expect(summary).to include('- Y')
      end

      it 'includes old and new values in changed line' do
        diff = described_class.new({ 'PORT' => '3000' }, { 'PORT' => '8080' })
        expect(diff.summary).to include('3000')
        expect(diff.summary).to include('8080')
      end
    end
  end

  describe Philiprehberger::EnvDiff::Parser do
    describe '.parse edge cases' do
      it 'handles values with equals signs' do
        result = described_class.parse('URL=http://example.com?a=1&b=2')
        expect(result).to eq({ 'URL' => 'http://example.com?a=1&b=2' })
      end

      it 'handles export with quoted value' do
        result = described_class.parse('export FOO="bar baz"')
        expect(result).to eq({ 'FOO' => 'bar baz' })
      end

      it 'parses content with only comments and blank lines' do
        result = described_class.parse("# comment\n\n# another\n")
        expect(result).to eq({})
      end

      it 'handles keys with underscores and numbers' do
        result = described_class.parse('MY_VAR_2=value')
        expect(result).to eq({ 'MY_VAR_2' => 'value' })
      end
    end
  end
end
