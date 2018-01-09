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
      output = fixture("ls-typical")
      # Anyway, the problem is that the method calls it multiple times
      # with various arguments. Refactoring is needed to make this work.
      expect_any_instance_of(described_class)
        .to receive(:`)
        .with("targetcli ls")
        .and_return(output)

      acl = "iscsi/iqn.2018-01.cz.suse:2e149e55-4d2e-43b7-bc6b-a999c837d6fe/tpg1/acls/iqn.2018-01.cz.suse:2e149e55-4d2e-43b7-bc6b-a999c837d6fe/"

      expect_any_instance_of(described_class).to receive(:`)
        .with("targetcli #{acl} get auth userid")
        .and_return("userid=teddybear")

      expect_any_instance_of(described_class).to receive(:`)
        .with("targetcli #{acl} get auth password")
        .and_return("password=plush")

      expect_any_instance_of(described_class).to receive(:`)
        .with("targetcli #{acl} get auth mutual_userid")
        .and_return("mutual_userid=foo")

      expect_any_instance_of(described_class).to receive(:`)
        .with("targetcli #{acl} get auth mutual_password")
        .and_return("mutual_password=bar")

      td = TargetData.new
      expect(td.get_target_names_array).to eq(["iqn.2018-01.cz.suse:2e149e55-4d2e-43b7-bc6b-a999c837d6fe"])
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
