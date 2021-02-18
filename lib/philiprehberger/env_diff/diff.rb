# frozen_string_literal: true

module Philiprehberger
  module EnvDiff
    # Represents the result of comparing two sets of environment variables.
    class Diff
      # @return [Array<String>] keys present in target but not source
      attr_reader :added

      # @return [Array<String>] keys present in source but not target
      attr_reader :removed

      # @return [Hash{String => Hash}] keys with different values ({ key => { source:, target: } })
      attr_reader :changed

      # @return [Array<String>] keys with identical values in both sets
      attr_reader :unchanged

      # Build a diff from two environment hashes.
      #
      # @param source [Hash] the baseline environment hash
      # @param target [Hash] the environment hash to compare against
      def initialize(source, target)
        @added = (target.keys - source.keys).sort
        @removed = (source.keys - target.keys).sort
        @changed = build_changed(source, target)
        @unchanged = build_unchanged(source, target)
      end

      # Whether there are any differences between source and target.
      #
      # @return [Boolean] true if added, removed, or changed are non-empty
      def changed?
        !@added.empty? || !@removed.empty? || !@changed.empty?
      end

      # Human-readable multiline summary of all differences.
      #
      # @return [String] formatted summary
      def summary
        lines = []
        append_added(lines)
        append_removed(lines)
        append_changed(lines)
        lines.empty? ? 'No differences found.' : lines.join("\n")
      end

      private

      def build_changed(source, target)
        common = source.keys & target.keys
        common.each_with_object({}) do |key, hash|
          next if source[key] == target[key]

          hash[key] = { source: source[key], target: target[key] }
        end
      end

      def build_unchanged(source, target)
        common = source.keys & target.keys
        common.select { |key| source[key] == target[key] }.sort
      end

      def append_added(lines)
        @added.each { |key| lines << "+ #{key}" }
      end

      def append_removed(lines)
        @removed.each { |key| lines << "- #{key}" }
      end

      def append_changed(lines)
        @changed.each do |key, vals|
          lines << "~ #{key}: #{vals[:source].inspect} -> #{vals[:target].inspect}"
        end
      end
    end
  end
end
