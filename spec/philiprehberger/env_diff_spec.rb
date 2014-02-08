# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe Philiprehberger::EnvDiff do
  it "has a version number" do
    expect(Philiprehberger::EnvDiff::VERSION).not_to be_nil
  end

  describe ".compare" do
    it "detects added keys" do
      diff = described_class.compare({ "A" => "1" }, { "A" => "1", "B" => "2" })
      expect(diff.added).to eq(["B"])
    end

    it "detects removed keys" do
      diff = described_class.compare({ "A" => "1", "B" => "2" }, { "A" => "1" })
      expect(diff.removed).to eq(["B"])
    end

    it "detects changed keys" do
      diff = described_class.compare({ "A" => "1" }, { "A" => "2" })
      expect(diff.changed).to eq({ "A" => { source: "1", target: "2" } })
    end

    it "detects unchanged keys" do
      diff = described_class.compare({ "A" => "1", "B" => "2" }, { "A" => "1", "B" => "3" })
      expect(diff.unchanged).to eq(["A"])
    end

    it "handles all difference types together" do
      source = { "KEEP" => "same", "CHANGE" => "old", "REMOVE" => "bye" }
      target = { "KEEP" => "same", "CHANGE" => "new", "ADD" => "hello" }
      diff = described_class.compare(source, target)

      expect(diff.added).to eq(["ADD"])
      expect(diff.removed).to eq(["REMOVE"])
      expect(diff.changed).to eq({ "CHANGE" => { source: "old", target: "new" } })
      expect(diff.unchanged).to eq(["KEEP"])
    end
  end

  describe Philiprehberger::EnvDiff::Diff do
    describe "#changed?" do
      it "returns true when there are differences" do
        diff = described_class.new({ "A" => "1" }, { "B" => "2" })
        expect(diff.changed?).to be true
      end

      it "returns false when hashes are identical" do
        diff = described_class.new({ "A" => "1" }, { "A" => "1" })
        expect(diff.changed?).to be false
      end

      it "returns false for empty hashes" do
        diff = described_class.new({}, {})
        expect(diff.changed?).to be false
      end
    end

    describe "#summary" do
      it "returns 'No differences found.' for identical hashes" do
        diff = described_class.new({ "A" => "1" }, { "A" => "1" })
        expect(diff.summary).to eq("No differences found.")
      end

      it "includes added, removed, and changed keys" do
        source = { "KEEP" => "same", "CHANGE" => "old", "REMOVE" => "bye" }
        target = { "KEEP" => "same", "CHANGE" => "new", "ADD" => "hello" }
        diff = described_class.new(source, target)
        summary = diff.summary

        expect(summary).to include("+ ADD")
        expect(summary).to include("- REMOVE")
        expect(summary).to include("~ CHANGE")
      end

      it "returns no-diff message for empty hashes" do
        diff = described_class.new({}, {})
        expect(diff.summary).to eq("No differences found.")
      end
    end
  end

  describe Philiprehberger::EnvDiff::Parser do
    describe ".parse" do
      it "parses simple KEY=VALUE pairs" do
        result = described_class.parse("FOO=bar\nBAZ=qux")
        expect(result).to eq({ "FOO" => "bar", "BAZ" => "qux" })
      end

      it "ignores comments" do
        result = described_class.parse("# this is a comment\nFOO=bar")
        expect(result).to eq({ "FOO" => "bar" })
      end

      it "ignores blank lines" do
        result = described_class.parse("FOO=bar\n\n\nBAZ=qux")
        expect(result).to eq({ "FOO" => "bar", "BAZ" => "qux" })
      end

      it "handles double-quoted values" do
        result = described_class.parse('FOO="hello world"')
        expect(result).to eq({ "FOO" => "hello world" })
      end

      it "handles single-quoted values" do
        result = described_class.parse("FOO='hello world'")
        expect(result).to eq({ "FOO" => "hello world" })
      end

      it "handles export prefix" do
        result = described_class.parse("export FOO=bar")
        expect(result).to eq({ "FOO" => "bar" })
      end

      it "handles empty values" do
        result = described_class.parse("FOO=")
        expect(result).to eq({ "FOO" => "" })
      end
    end

    describe ".parse_file" do
      it "reads and parses a file" do
        file = Tempfile.new(".env")
        file.write("FOO=bar\nBAZ=qux")
        file.close

        result = described_class.parse_file(path: file.path)
        expect(result).to eq({ "FOO" => "bar", "BAZ" => "qux" })
      ensure
        file&.unlink
      end
    end
  end

  describe ".from_hash" do
    it "compares two hashes" do
      diff = described_class.from_hash({ "A" => "1" }, { "A" => "2" })
      expect(diff.changed?).to be true
      expect(diff.changed).to eq({ "A" => { source: "1", target: "2" } })
    end
  end

  describe ".from_env_file" do
    it "parses and compares two env files" do
      file_a = Tempfile.new(".env.a")
      file_a.write("FOO=bar\nOLD=val")
      file_a.close

      file_b = Tempfile.new(".env.b")
      file_b.write("FOO=baz\nNEW=val")
      file_b.close

      diff = described_class.from_env_file(file_a.path, file_b.path)
      expect(diff.added).to eq(["NEW"])
      expect(diff.removed).to eq(["OLD"])
      expect(diff.changed).to eq({ "FOO" => { source: "bar", target: "baz" } })
    ensure
      file_a&.unlink
      file_b&.unlink
    end
  end
end
