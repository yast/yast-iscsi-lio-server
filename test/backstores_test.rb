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
      expect(bs.get_backstores_list).to eq([])
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
