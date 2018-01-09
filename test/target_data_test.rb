#! /usr/bin/env rspec --format doc

require_relative "./test_helper"
require "yast"
require "yast2/execute" # this one should actually be part of TargetData
require "TargetData"

describe TargetData do
  describe "#analyze" do
    it "parses an empty output" do
      output = ""
      # Stubbing the backtick method is a bit tricky.
      expect_any_instance_of(described_class)
        .to receive(:`)
        .with("targetcli ls")
        .and_return(output)

      td = TargetData.new
      expect(td.get_target_names_array).to eq([])
    end

    it "parses a typical output" do
      output = <<EOS
I don't know how the typical output looks like
Let's assume this is fine ;-)

iqn.9999-99.aaa ... [TPGs: 99]
tpg99 whatever
acls .............. [ACLs: 99] 
iqn.9999-99.aaa ... [bbb ccc Mapped LUNs: 99]
EOS
      # Anyway, the problem is that the method calls it multiple times
      # with various arguments. Refactoring is needed to make this work.
      expect_any_instance_of(described_class)
        .to receive(:`)
        .with("targetcli ls")
        .and_return(output)

      acl_output = "please don't steal our secrets"
      expect_any_instance_of(described_class)
        .to receive(:`)
        .with("targetcli iscsi/iqn.9999-99.foo/tpg44/acls/iqn.9999-99.bla/ get auth userid")
        .and_return(acl_output)

      td = TargetData.new
      expect(td.get_target_names_array).to eq(["iqn.9999-99.aaa"])
    end

    it "parses an error output" do
      output = <<EOS
WWN not valid as: iqn, naa, eui
EOS
      expect_any_instance_of(described_class).to receive(:`).and_return(output)

      td = TargetData.new
      expect(td.get_target_names_array).to eq([])
    end
  end
end
