# frozen_string_literal: true

module Philiprehberger
  module EnvDiff
    # Parses .env file content into a key-value hash.
    module Parser
      # Parse a string of env file content into a hash.
      #
      # @param content [String] the raw .env file content
      # @return [Hash{String => String}] parsed key-value pairs
      def self.parse(content)
        result = {}
        content.each_line do |line|
          key, value = parse_line(line.strip)
          result[key] = value if key
        end
        result
      end

      # Read a file and parse its content.
      #
      # @param path [String] path to the .env file
      # @return [Hash{String => String}] parsed key-value pairs
      # @raise [Errno::ENOENT] if the file does not exist
      def self.parse_file(path:)
        parse(File.read(path))
      end

      # Parse a single line from an env file.
      #
      # @param line [String] a stripped line
      # @return [Array(String, String), nil] key-value pair or nil
      def self.parse_line(line)
        return nil if line.empty? || line.start_with?('#')

        line = line.sub(/\Aexport\s+/, '')
        key, _, value = line.partition('=')
        return nil if key.empty? || value.nil?

        [key.strip, unquote(value.strip)]
      end
      private_class_method :parse_line

      # Remove surrounding quotes from a value.
      #
      # @param value [String] the raw value
      # @return [String] the unquoted value
      def self.unquote(value)
        if (value.start_with?('"') && value.end_with?('"')) ||
           (value.start_with?("'") && value.end_with?("'"))
          return value[1..-2]
        end

        value
      end
      private_class_method :unquote
    end
  end
end
