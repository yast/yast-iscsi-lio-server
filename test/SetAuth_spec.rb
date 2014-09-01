#! /usr/bin/rspec
require_relative '../src/modules/IscsiLioData'

describe Yast::IscsiLioDataClass do

  before :each do
    @iscsilib = Yast::IscsiLioDataClass.new
    @iscsilib.main()

    @test_class = @iscsilib
  end

  describe "#SetAuth" do
    context "when called with user and password info" do
      it "filters out sensitive data" do
        tgt = ""
        tpg = -42
        clnt = ""
        inc = ["SECRET1"]
        out = ["SECRET2"]
        expect(Yast::Builtins).to receive(:y2milestone) do |*args|
          expect(args.to_s).not_to match /SECRET/
        end.at_least(2).times

        expect(@iscsilib).
          to receive(:LogExecCmd).
          twice.
          and_return true

        expect(@iscsilib.SetAuth(tgt, tpg, clnt, inc, out)).to be true
      end
    end
  end

  describe "#SetAuth" do
    context "when called with user and password info" do
      it "calls LogExecCmd correctly" do
        tgt = ""
        tpg = -42
        clnt = ""
        inc = ["User", "Password"]
        out = []

        expect(@iscsilib).to receive(:LogExecCmd) do |*args|
          expect(args).to eq ["lio_node --setchapdiscauth User Password", {:do_log=>false}]
        end

        @iscsilib.SetAuth(tgt, tpg, clnt, inc, out)
      end
    end
  end


end
