#!/usr/bin/env rspec
# encoding: utf-8

# Copyright (c) [2019] SUSE LLC
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

describe DiscoveryAuth do
  describe "#analyze" do
    before do
      allow(Yast::Execute).to receive(:locally!).and_return(output)
    end

    let(:execute_object) { Yast::Execute.new }

    context "when 'targetcli' output is correct" do
      let(:output) { fixture("auth-typical") }

      it "reads the correct values" do
        subject.analyze

        expect(subject.fetch_status).to eq true
        expect(subject.fetch_userid).to eq "name1"
        expect(subject.fetch_password).to eq "secret1"
        expect(subject.fetch_mutual_userid).to eq "name2"
        expect(subject.fetch_mutual_password).to eq "secret2"
      end
    end

    context "when 'targetcli' output is broken" do
      let(:output) { fixture("auth-broken") }

      it "raises an exception" do
        expect { subject.analyze }.to raise_error(Exception)
      end
    end
  end
end
