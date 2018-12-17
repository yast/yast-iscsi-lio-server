#!/usr/bin/env rspec
# encoding: utf-8

# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "./test_helper"

require "TargetData"

describe TargetData do
  describe "#analyze" do
    before do
      allow(Yast::Execute).to receive(:locally!).and_return(execute_object)

      allow(execute_object).to receive(:stdout).with("targetcli", "ls").and_return(output)
    end

    let(:execute_object) { Yast::Execute.new }

    context "when 'targetcli ls' output is empty" do
      let(:output) { "" }

      it "does not read target names" do
        expect(subject.get_target_names_array).to eq([])
      end
    end

    context "when 'targetcli ls' output is valid" do
      let(:output) { fixture("ls-typical") }

      before do
        allow(execute_object).to receive(:stdout).with("targetcli", acl, "get", "auth", "userid")
          .and_return("userid=teddybear")

        allow(execute_object).to receive(:stdout).with("targetcli", acl, "get", "auth", "password")
          .and_return("password=plush")

        allow(execute_object).to receive(:stdout).with("targetcli", acl, "get", "auth", "mutual_userid")
          .and_return("mutual_userid=foo")

        allow(execute_object).to receive(:stdout).with("targetcli", acl, "get", "auth", "mutual_password")
          .and_return("mutual_password=bar")
      end

      let(:acl) { "iscsi/iqn.2018-01.suse.com.lszhu.target/tpg5/acls/iqn.2018-01.suse.com.lszhu.init/" }

      it "reads the data correctly" do
        # Anyway, the problem is that the method calls it multiple times
        # with various arguments. Refactoring is needed to make this work.
        test_unitls = Test_Utils.new
        expect(test_unitls.setup).to eq(0)

        target_name = "iqn.2018-01.suse.com.lszhu.target"
        tpg_num = "5"
        lun_info = {"lun0 "=>["0 ", "var-tmp-target.raw", "/var/tmp/target.raw", "file"]}
        portals = ["192.168.100.12", "1234"], ["192.168.101.12", "1234"]
        acl_initiator_names = ["iqn.2018-01.suse.com.lszhu.init"]
        user_id = "teddybear"
        password = "plush"
        mutual_userid = "foo"
        mutual_password = "bar"
        mapping_lun_num = "7"
        mapped_lun_num = "0"

        expect(subject.get_target_names_array).to eq(["iqn.2018-01.suse.com.lszhu.target"])
        expect(subject.get_target_list.fetch_target(target_name).fetch_target_name).to eq(target_name)

        tpg = subject.get_target_list.fetch_target(target_name).get_default_tpg

        expect(tpg.fetch_tpg_number).to eq(tpg_num)
        expect(tpg.get_luns_info).to eq(lun_info)
        expect(tpg.fetch_portal).to eq(portals)
        expect(tpg.fetch_acls("acls").get_acl_intitiator_names).to eq(acl_initiator_names)

        acl_rule = tpg.fetch_acls("acls").fetch_rule(acl_initiator_names.first)

        expect(acl_rule.fetch_userid).to eq(user_id)
        expect(acl_rule.fetch_mutual_userid).to eq(mutual_userid)
        expect(acl_rule.fetch_password).to eq(password)
        expect(acl_rule.fetch_mutual_password).to eq(mutual_password)

        mapped_lun = acl_rule.get_mapped_lun.fetch(mapping_lun_num)

        expect(mapped_lun.fetch_mapping_lun_number).to eq(mapping_lun_num)
        expect(mapped_lun.fetch_mapped_lun_number).to eq(mapped_lun_num)
      end
    end

    context "when 'targetcli ls' output is not valid" do
      let(:output) { "WWN not valid as: iqn, naa, eui" }

      it "does not read target names" do
        expect(subject.get_target_names_array).to eq([])
      end
    end
  end
end
