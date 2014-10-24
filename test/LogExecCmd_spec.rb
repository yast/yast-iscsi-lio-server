#!/usr/bin/env rspec
require_relative '../src/modules/IscsiLioData'

describe Yast::IscsiLioDataClass do

  before :each do
    @iscsilib = Yast::IscsiLioDataClass.new
    @iscsilib.main()

    @test_class = @iscsilib
  end

  describe "#LogExecCmd" do
    context "when told not to write command to YaST log" do
      it "executes command and doesn't write to y2log" do
        cmd = "lio-node --setchap hugo 12345"

        expect(Yast::Builtins).not_to receive(:y2milestone)
        expect(Yast::SCR).to receive(:Execute).once
        @iscsilib.LogExecCmd(cmd, do_log: false)
      end
    end
  end
  
  describe "#LogExecCmd" do
    context "when called with command not containing sensitive data" do
      it "executes command and write command to y2log" do
        cmd = "lio-node --list"

        expect(Yast::Builtins).to receive(:y2milestone).once
        expect(Yast::SCR).to receive(:Execute).once
        @iscsilib.LogExecCmd(cmd)
      end
    end
  end

end
