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

      acl = "iscsi/iqn.2018-01.suse.com.lszhu.target/tpg5/acls/iqn.2018-01.suse.com.lszhu.init/"
      target_name = "iqn.2018-01.suse.com.lszhu.target"
      tpg_num = "5"
      lun_info = {"lun1 "=>["1 ", "home-lszhu-target.raw", "/home/lszhu/target.raw", "file"]}
      portals = ["192.168.100.12", "1234"], ["192.168.101.12", "1234"]
      acl_initiator_names = ["iqn.2018-01.suse.com.lszhu.init"]
      user_id = "teddybear"
      password = "plush"
      mutual_userid = "foo"
      mutual_password = "bar"
      mapping_lun_num = "7"
      mapped_lun_num = "1"

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
      expect(td.get_target_names_array).to eq(["iqn.2018-01.suse.com.lszhu.target"])
      expect(td.get_target_list.fetch_target(target_name).fetch_target_name).to eq(target_name)
      tpg = td.get_target_list.fetch_target(target_name).get_default_tpg
      expect(tpg.fetch_tpg_number).to eq(tpg_num)
      expect(tpg.get_luns_info).to eq(lun_info)
      expect(tpg.fetch_portal).to eq(portals)
      expect(tpg.fetch_acls("acls").get_acl_intitiator_names).to eq(acl_initiator_names)
      acl_rule = tpg.fetch_acls("acls").fetch_rule(acl_initiator_names[0])
      expect(acl_rule.fetch_userid).to eq(user_id)
      expect(acl_rule.fetch_mutual_userid).to eq(mutual_userid)
      expect(acl_rule.fetch_password).to eq(password)
      expect(acl_rule.fetch_mutual_password).to eq(mutual_password)
      mapped_lun = acl_rule.get_mapped_lun.fetch(mapping_lun_num)
      expect(acl_rule.fetch_mutual_password).to eq(mutual_password)
      expect(mapped_lun.fetch_mapping_lun_number).to eq(mapping_lun_num)
      expect(mapped_lun.fetch_mapped_lun_number).to eq(mapped_lun_num)
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
