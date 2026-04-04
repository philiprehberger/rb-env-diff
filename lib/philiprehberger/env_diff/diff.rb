# frozen_string_literal: true

require 'json'

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
        @source = source
        @target = target
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
      # @param mask [Array<String, Regexp>] patterns for keys whose values should be masked
      # @return [String] formatted summary
      def summary(mask: [])
        lines = []
        append_added(lines, mask)
        append_removed(lines, mask)
        append_changed(lines, mask)
        lines.empty? ? 'No differences found.' : lines.join("\n")
      end

      # Structured hash representation of the diff.
      #
      # @return [Hash] with :added, :removed, :changed, :unchanged keys
      def to_h
        {
          added: @added.to_h { |k| [k, @target[k]] },
          removed: @removed.to_h { |k| [k, @source[k]] },
          changed: @changed.transform_values { |v| { source: v[:source], target: v[:target] } },
          unchanged: @unchanged.to_h { |k| [k, @source[k]] }
        }
      end

      # JSON serialization of the structured hash.
      #
      # @return [String] JSON string
      def to_json(*_args)
        JSON.generate(to_h)
      end

      # Return a new Diff containing only keys matching the given pattern.
      #
      # @param pattern [Regexp] regex pattern to match keys against
      # @return [Diff] filtered diff
      def filter(pattern:)
        filtered_source = @source.select { |k, _| k.match?(pattern) }
        filtered_target = @target.select { |k, _| k.match?(pattern) }
        Diff.new(filtered_source, filtered_target)
      end

      # Statistics about the diff.
      #
      # @return [Hash] counts of added, removed, changed, unchanged, and total keys
      def stats
        {
          added: @added.length,
          removed: @removed.length,
          changed: @changed.length,
          unchanged: @unchanged.length,
          total: @added.length + @removed.length + @changed.length + @unchanged.length
        }
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

      def masked?(key, mask)
        mask.any? do |pattern|
          pattern.is_a?(Regexp) ? key.match?(pattern) : key == pattern
        end
      end

      def mask_value(_value, key, mask)
        masked?(key, mask) ? '***' : yield
      end

      def append_added(lines, mask)
        @added.each do |key|
          lines << if masked?(key, mask)
                     "+ #{key}=***"
                   else
                     "+ #{key}"
                   end
        end
      end

      def append_removed(lines, mask)
        @removed.each do |key|
          lines << if masked?(key, mask)
                     "- #{key}=***"
                   else
                     "- #{key}"
                   end
        end
      end

      def append_changed(lines, mask)
        @changed.each do |key, vals|
          lines << if masked?(key, mask)
                     "~ #{key}: *** -> ***"
                   else
                     "~ #{key}: #{vals[:source].inspect} -> #{vals[:target].inspect}"
                   end
        end
      end
    end
  end
end
