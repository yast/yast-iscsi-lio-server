#! /usr/bin/env rspec --format doc

require_relative "./test_helper"
require "yast"
require "yast2/execute" # this one should actually be part of TargetData
require "TargetData"

describe Backstores do
  describe "#analyze" do
    it "parses an empty output" do
      output = ""
      expect(Yast::Execute).to receive(:locally).and_return(output)

      bs = Backstores.new
      expect(bs.get_backstores_list).to eq([])
    end

    it "parses a typical output" do
      output = <<EOS
I don't know how the typical output looks like
Let's assume this is fine ;-)
EOS
      expect(Yast::Execute).to receive(:locally).and_return(output)

      bs = Backstores.new
      expect(bs.get_backstores_list).to eq([42])
    end

    it "parses an error output" do
      output = <<EOS
WWN not valid as: iqn, naa, eui
EOS
      expect(Yast::Execute).to receive(:locally).and_return(output)

      bs = Backstores.new
      expect(bs.get_backstores_list).to eq([])
    end
  end
end
