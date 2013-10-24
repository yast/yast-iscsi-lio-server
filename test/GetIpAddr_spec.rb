#! env rspec
require_relative '../src/modules/IscsiLioData'

describe Yast::IscsiLioDataClass do

  before :each do
    @iscsilib = Yast::IscsiLioDataClass.new
    @iscsilib.main() 
    
    @test_class = @iscsilib
    
  end

  describe "#GetIpAddr filters output of \'ifconfig\'" do
    context "when in usual format" do
      it "it returns list of available IP addresses" do
        @iscsilib.stub(:GetNetConfig).and_return([
"enp3s0f0  Link encap:Ethernet  HWaddr 00:21:5A:F6:69:80",
"          inet addr:10.121.8.83  Bcast:10.121.63.255  Mask:255.255.192.0",
"          inet6 addr: 2620:113:80c0:8000:19ca:2ad:d755:fd68/64 Scope:Global",
"          inet6 addr: fe80::221:5aff:fef6:6980/64 Scope:Link",
"          inet6 addr: 2620:113:80c0:8000:a845:8232:ab79:6a7c/64 Scope:Global",
"          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1",
"          RX packets:807334589 errors:0 dropped:96 overruns:0 frame:0",
"          TX packets:147793653 errors:0 dropped:0 overruns:0 carrier:0",
"          collisions:0 txqueuelen:1000",
"          RX bytes:1138190820596 (1085463.3 Mb)  TX bytes:121179938780 (115566.1 Mb)",
"          Interrupt:16 Memory:fd000000-fd7fffff",
"",
"lo        Link encap:Local Loopback  ",
"          inet addr:127.0.0.1  Mask:255.0.0.0",
"          inet6 addr: ::1/128 Scope:Host",
"          UP LOOPBACK RUNNING  MTU:65536  Metric:1"])

        ip_list = @iscsilib.GetIpAddr()
        ip_list.should eq(["10.121.8.83",
                           "2620:113:80c0:8000:19ca:2ad:d755:fd68",
                           "2620:113:80c0:8000:a845:8232:ab79:6a7c"
                          ] )
      end
    end
    
    context "when white spaces differ" do
      it "it also returns correct list of IP addresses" do
        @iscsilib.stub(:GetNetConfig).and_return([
"enp3s0f0  Link encap:Ethernet  HWaddr 00:21:5A:F6:69:80",
"  inet addr:10.121.8.83  Bcast:10.121.63.255  Mask:255.255.192.0",
"  inet addr: 10.122.8.83    Bcast:10.121.63.255  Mask:255.255.192.0",
"inet addr:10.120.9.76\tBcast:10.121.63.255  Mask:255.255.192.0",
"\tinet6 addr: 2620:113:80c0:8000:19ca:2ad:d755:fd68/64 Scope:Global",
"inet6 addr: 2620:113:80c0:8000:a845:8232:ab79:6a7c/64 Scope:Global",
"        inet6 addr:2620:113:80c0:7000:a845:8232:ab79:6a7c/64 Scope:Global",
"        inet6 addr:   2620:113:80c0:7777:a845:8232:ab79:6a7c/64 Scope:Global",
"     Interrupt:16 Memory:fd000000-fd7fffff"])

        ip_list = @iscsilib.GetIpAddr()
        ip_list.should eq(["10.121.8.83",
                           "10.122.8.83",
                           "10.120.9.76",
                           "2620:113:80c0:8000:19ca:2ad:d755:fd68",
                           "2620:113:80c0:8000:a845:8232:ab79:6a7c",
                           "2620:113:80c0:7000:a845:8232:ab79:6a7c",
                           "2620:113:80c0:7777:a845:8232:ab79:6a7c"
                          ])
      end
    end

    context "when not containing any valid IP" do
      it "it returns [\"\"]" do
        @iscsilib.stub(:GetNetConfig).and_return([
"enp3s0f0  Link encap:Ethernet  HWaddr 00:21:5A:F6:69:80",
"     inet6 addr: fe80::221:5aff:fef6:6980/64 Scope:Link",
"     Interrupt:16 Memory:fd000000-fd7fffff"])

        ip_list = @iscsilib.GetIpAddr()
        ip_list.should eq([""])
      end
    end

  end
end
