# frozen_string_literal: true

require_relative 'env_diff/version'
require_relative 'env_diff/diff'
require_relative 'env_diff/parser'

module Philiprehberger
  module EnvDiff
    class Error < StandardError; end

    # Compare two environment hashes and return a Diff.
    #
    # @param source [Hash] the baseline environment hash
    # @param target [Hash] the environment hash to compare against
    # @param case_sensitive [Boolean] whether key comparison is case-sensitive (default: true)
    # @return [Diff] the computed differences
    def self.compare(source, target, case_sensitive: true)
      if case_sensitive
        Diff.new(source, target)
      else
        normalized_source = source.transform_keys(&:upcase)
        normalized_target = target.transform_keys(&:upcase)
        Diff.new(normalized_source, normalized_target)
      end
    end

    # Validate that all required keys exist in target.
    #
    # @param target [Hash, String] a hash of target variables or a path to a .env file
    # @param required [Array<String>] list of required key names
    # @return [Hash] with :valid (Boolean) and :missing (Array<String>)
    def self.validate(target, required:)
      target_hash = target.is_a?(String) ? Parser.parse_file(path: target) : target
      missing = required.reject { |key| target_hash.key?(key) }
      { valid: missing.empty?, missing: missing }
    end

    # Format a diff result as a Markdown table string.
    #
    # @param diff [Diff] the diff to format
    # @return [String] Markdown table
    def self.to_markdown(diff)
      lines = []
      lines << '| Key | Status | Source | Target |'
      lines << '| --- | ------ | ------ | ------ |'

      diff.added.each do |key|
        lines << "| #{key} | added | | #{diff.to_h[:added][key]} |"
      end

      diff.removed.each do |key|
        lines << "| #{key} | removed | #{diff.to_h[:removed][key]} | |"
      end

      diff.changed.each do |key, vals|
        lines << "| #{key} | changed | #{vals[:source]} | #{vals[:target]} |"
      end

      diff.unchanged.each do |key|
        lines << "| #{key} | unchanged | #{diff.to_h[:unchanged][key]} | #{diff.to_h[:unchanged][key]} |"
      end

      lines.join("\n")
    end

    # Format a diff result as an HTML table string.
    #
    # @param diff [Diff] the diff to format
    # @return [String] HTML table
    def self.to_html(diff)
      rows = diff.added.map do |key|
        "  <tr><td>#{key}</td><td>added</td><td></td><td>#{diff.to_h[:added][key]}</td></tr>"
      end

      diff.removed.each do |key|
        rows << "  <tr><td>#{key}</td><td>removed</td><td>#{diff.to_h[:removed][key]}</td><td></td></tr>"
      end

      diff.changed.each do |key, vals|
        rows << "  <tr><td>#{key}</td><td>changed</td><td>#{vals[:source]}</td><td>#{vals[:target]}</td></tr>"
      end

      diff.unchanged.each do |key|
        val = diff.to_h[:unchanged][key]
        rows << "  <tr><td>#{key}</td><td>unchanged</td><td>#{val}</td><td>#{val}</td></tr>"
      end

      lines = []
      lines << '<table>'
      lines << '  <tr><th>Key</th><th>Status</th><th>Source</th><th>Target</th></tr>'
      lines.concat(rows)
      lines << '</table>'
      lines.join("\n")
    end

    # Alias for compare — compare two hashes.
    #
    # @param hash_a [Hash] the baseline environment hash
    # @param hash_b [Hash] the environment hash to compare against
    # @param case_sensitive [Boolean] whether key comparison is case-sensitive (default: true)
    # @return [Diff] the computed differences
    def self.from_hash(hash_a, hash_b, case_sensitive: true)
      compare(hash_a, hash_b, case_sensitive: case_sensitive)
    end

    # Parse two .env files and compare them.
    #
    # @param path_a [String] path to the source .env file
    # @param path_b [String] path to the target .env file
    # @param case_sensitive [Boolean] whether key comparison is case-sensitive (default: true)
    # @return [Diff] the computed differences
    def self.from_env_file(path_a, path_b, case_sensitive: true)
      compare(Parser.parse_file(path: path_a), Parser.parse_file(path: path_b), case_sensitive: case_sensitive)
    end

    # Compare the current system ENV against a target hash or .env file path.
    #
    # @param target [Hash, String] a hash of target variables or a path to a .env file
    # @param case_sensitive [Boolean] whether key comparison is case-sensitive (default: true)
    # @return [Diff] the computed differences between ENV and target
    def self.from_system(target, case_sensitive: true)
      target_hash = target.is_a?(String) ? Parser.parse_file(path: target) : target
      compare(ENV.to_h, target_hash, case_sensitive: case_sensitive)
    end
  end
end
