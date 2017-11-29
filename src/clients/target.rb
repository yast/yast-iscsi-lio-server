# Simple example to demonstrate object API for CWM

#require_relative "example_helper"
require './src/lib/TargetData.rb'
require './src/lib/dialogs/UI_dialogs.rb'
require "cwm/widget"
require "ui/service_status"
require "yast"

Yast.import "CWM"
Yast.import "CWMTab"
Yast.import "TablePopup"
Yast.import "CWMServiceStart"
Yast.import "Popup"
Yast.import "Wizard"
Yast.import "CWMFirewallInterfaces"
Yast.import "Service"
Yast.import "CWMServiceStart"
Yast.import "UI"


module Yast
  class ISCSILioServer
    include Yast::I18n
    include Yast::UIShortcuts
    include Yast::Logger
    def run
      textdomain "iscsi-lio-server"
      msg = ""
      global_tab = GlobalTab.new
      targets_tab = TargetsTab.new
      service_tab = ServiceTab.new
      tabs = ::CWM::Tabs.new(service_tab,global_tab,targets_tab)
      contents = VBox(tabs,VStretch())
      Yast::Wizard.CreateDialog
      ret = CWM.show(contents, caption: _("Yast iSCSI Targets"),next_button: _("Finish"))
      Yast::Wizard.CloseDialog
      if ret == :next
        status = $discovery_auth.fetch_status()
        userid = $discovery_auth.fetch_userid()
        password = $discovery_auth.fetch_password()
        mutual_userid = $discovery_auth.fetch_mutual_userid()
        mutual_password = $discovery_auth.fetch_mutual_password()
        cmd = 'targetcli'
        p1 = "iscsi/ set discovery_auth "
        if userid.empty? != true
          p1 += ("userid=" + userid + " ")
        end
        if password != nil
          p1 += ("password=" + password + " ")
        end
        if mutual_userid != nil
          p1 += ("mutual_userid=" + mutual_userid + " ")
        end
        if mutual_password != nil
          p1 += ("mutual_password=" + mutual_password)
        end

        if status == true
          p1 += " enable=1"
          if (userid == mutual_userid)
            msg = _("It seems that Authentication by Initiators and Authentication by Targets using a same username")
            msg += _("This may cause a CHAP negotiation error, an authenticaiton failure.")
          end
        else
          p1 = "iscsi/ set discovery_auth enable = 0"
        end
        begin
          Cheetah.run(cmd, p1)
        rescue Cheetah::ExecutionFailed => e
          if e.stderr != nil
            err_msg = _("Failed to set discovery authentication with errors: ")
            err_msg += e.stderr
            Yast::Popup.Error(err_msg)
          end
        end
      end
    end
  end
end

$target_data = TargetData.new
$global_data = Global.new
$global_data.execute_init_commands
$discovery_auth = DiscoveryAuth.new
Yast::ISCSILioServer.new.run
