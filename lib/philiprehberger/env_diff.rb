# frozen_string_literal: true

require_relative "env_diff/version"
require_relative "env_diff/diff"
require_relative "env_diff/parser"

module Philiprehberger
  module EnvDiff
    class Error < StandardError; end

    # Compare two environment hashes and return a Diff.
    #
    # @param source [Hash] the baseline environment hash
    # @param target [Hash] the environment hash to compare against
    # @return [Diff] the computed differences
    def self.compare(source, target)
      Diff.new(source, target)
    end

    # Alias for compare — compare two hashes.
    #
    # @param hash_a [Hash] the baseline environment hash
    # @param hash_b [Hash] the environment hash to compare against
    # @return [Diff] the computed differences
    def self.from_hash(hash_a, hash_b)
      compare(hash_a, hash_b)
    end

    # Parse two .env files and compare them.
    #
    # @param path_a [String] path to the source .env file
    # @param path_b [String] path to the target .env file
    # @return [Diff] the computed differences
    def self.from_env_file(path_a, path_b)
      compare(Parser.parse_file(path: path_a), Parser.parse_file(path: path_b))
    end
  end
end
