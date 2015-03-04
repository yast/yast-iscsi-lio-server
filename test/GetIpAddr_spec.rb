#!/usr/bin/env rspec
require_relative '../src/modules/IscsiLioData'

describe Yast::IscsiLioDataClass do

  before :each do
    @iscsilib = Yast::IscsiLioDataClass.new
    @iscsilib.main() 
    
    @test_class = @iscsilib
    
  end

  describe "#GetIpAddr" do
    context "when filtering output of ifconfig (current format)" do
      it "returns list of available IP addresses" do
        @iscsilib.stub(:GetNetConfig).
          and_return([
                      "1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default",
                      "    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00",
                      "    inet 127.0.0.1/8 scope host lo",
                      "       valid_lft forever preferred_lft forever",
                      "    inet6 ::1/128 scope host",
                      "       valid_lft forever preferred_lft forever",
                      "2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000",
                      "    link/ether 08:00:27:77:e8:2c brd ff:ff:ff:ff:ff:ff",
                      "    inet 10.160.65.187/16 brd 10.160.255.255 scope global eth0",
                      "       valid_lft forever preferred_lft forever",
                      "    inet6 2620:113:80c0:8080:10:160:68:237/64 scope global dynamic",
                      "       valid_lft 7339sec preferred_lft 7339sec",
                      "    inet6 2620:113:80c0:8080:610e:9a73:879a:4a8f/64 scope global temporary dynamic",
                      "       valid_lft 3567sec preferred_lft 1767sec",
                      "    inet6 2620:113:80c0:8080:6077:847c:8f17:a04e/64 scope global temporary deprecated dynamic",
                      "       valid_lft 3567sec preferred_lft 0sec",
                      "    inet6 2620:113:80c0:8080:bd9d:5c4d:6668:3c80/64 scope global temporary deprecated dynamic",
                      "       valid_lft 3567sec preferred_lft 0sec",
                      "    inet6 2620:113:80c0:8080:44e9:89:f96d:d7ed/64 scope global temporary deprecated dynamic",
                      "       valid_lft 3567sec preferred_lft 0sec",
                      "    inet6 2620:113:80c0:8080:1576:6de2:c048:6cd3/64 scope global temporary deprecated dynamic",
                      "       valid_lft 3567sec preferred_lft 0sec",
                      "    inet6 2620:113:80c0:8080:814d:6ba4:6846:779b/64 scope global temporary deprecated dynamic",
                      "       valid_lft 3567sec preferred_lft 0sec",
                      "    inet6 2620:113:80c0:8080:a00:27ff:fe77:e82c/64 scope global dynamic",
                      "       valid_lft 3567sec preferred_lft 1767sec",
                      "    inet6 0:0:0:0:0:0:101.45.75.219/64 scope global dynamic",
                      "       valid_lft 3567sec preferred_lft 1767sec",
                      "    inet6 fe80::a00:27ff:fe77:e82c/64 scope link",
                      "       valid_lft forever preferred_lft forever"
                     ])
        ip_list = @iscsilib.GetIpAddr()
        ip_list.should eq(["10.160.65.187",
                           "2620:113:80c0:8080:10:160:68:237",
                           "2620:113:80c0:8080:610e:9a73:879a:4a8f",
                           "2620:113:80c0:8080:a00:27ff:fe77:e82c",
                           "0:0:0:0:0:0:101.45.75.219"
                          ])
      end
    end
    
    context "when filtering output with white spaces added/removed" do
      it "also returns correct list of IP addresses" do
        @iscsilib.stub(:GetNetConfig).
          and_return([
                      "1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default",
                      "    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00",
                      "inet 127.0.0.1/8 scope host lo",
                      "       valid_lft forever preferred_lft forever",
                      "inet6 ::1/128 scope host",
                      "       valid_lft forever preferred_lft forever",
                      "2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000",
                      "    link/ether 08:00:27:77:e8:2c brd ff:ff:ff:ff:ff:ff",
                      "inet 10.160.65.187/16 brd 10.160.255.255 scope global eth0",
                      "       valid_lft forever preferred_lft forever",
                      "            inet6 2620:113:80c0:8080:10:160:68:237/64 scope global dynamic",
                      "       valid_lft 7339sec preferred_lft 7339sec",
                      "inet6 2620:113:80c0:8080:610e:9a73:879a:4a8f/64 scope global temporary dynamic",
                      "inet6 fe80::a00:27ff:fe77:e82c/64 scope link",
                      "       valid_lft forever preferred_lft forever"
                     ])
        ip_list = @iscsilib.GetIpAddr()
        ip_list.should eq(["10.160.65.187",
                           "2620:113:80c0:8080:10:160:68:237",
                           "2620:113:80c0:8080:610e:9a73:879a:4a8f"
                          ])
      end
    end

    context "when filtering output without any valid IP" do
      it "returns [\"\"]" do
        @iscsilib.stub(:GetNetConfig).
          and_return([
                      "2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000",
                      "    link/ether 08:00:27:77:e8:2c brd ff:ff:ff:ff:ff:ff",
                      "    inet6 fe80::a00:27ff:fe77:e82c/64 scope link",
                      "       valid_lft forever preferred_lft forever"
                     ])
        ip_list = @iscsilib.GetIpAddr()
        ip_list.should eq([""])
      end
    end

  end
end
