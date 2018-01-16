require_relative '../include/iscsi-lio-server/iscsi-lio-server_helper.rb'
require_relative '../include/iscsi-lio-server/TargetData.rb'
require_relative '../include/iscsi-lio-server/UI_dialogs.rb'
require "cwm/widget"
require "ui/service_status"
require "yast"
require "yast2/execute"

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
Yast.import "Confirm"

module Yast
  class ISCSILioServer
    include Yast::I18n
    include Yast::UIShortcuts
    include Yast::Logger

    def is_root
      Confirm.MustBeRoot
    end

    def installed_packages
      if !PackageSystem.PackageInstalled("targetcli-fb")
        confirm = Popup.AnyQuestionRichText(
            "",
            _("Yast iscsi-lio-server can't run without installing targetcli-fb package. Do you want to install?"),
            40,
            10,
            Label.InstallButton,
            Label.CancelButton,
            :focus_yes
        )

        if confirm
          PackageSystem.DoInstall(["targetcli-fb"])
          if PackageSystem.PackageInstalled("targetcli-fb")
            true
          else
            false
          end
        end
        false
      else
        true
      end
    end

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
        status = $discovery_auth.fetch_status
        userid = $discovery_auth.fetch_userid
        password = $discovery_auth.fetch_password
        mutual_userid = $discovery_auth.fetch_mutual_userid
        mutual_password = $discovery_auth.fetch_mutual_password
        cmd = 'targetcli'
        p1 = "iscsi/ set discovery_auth "
        # status == false means "No discovery auth" is not checked, means we need enable discovery auth
        if !status
          unless userid.empty?
            p1 += ("userid=" + userid + " ")
          end
          unless password.empty?
            p1 += ("password=" + password + " ")
          end
          unless mutual_userid.empty?
            p1 += ("mutual_userid=" + mutual_userid + " ")
          end
          if !mutual_password.empty?
            p1 += ("mutual_password=" + mutual_password)
          end
          p1 += " enable=1"
          if userid == mutual_userid
            msg = _("It seems that Authentication by Initiators and Authentication by Targets using a same username")
            msg += _("This may cause a CHAP negotiation error, an authenticaiton failure.")
            Yast::Popup.Error(msg)
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
        $global_data.execute_exit_commands
      end
    end

  end
end


iscsi_target_server = Yast::ISCSILioServer.new
ret = iscsi_target_server.is_root
if !ret
  exit
end
ret = iscsi_target_server.installed_packages
if ret
  $target_data = TargetData.new
  $global_data = Global.new
  $global_data.execute_init_commands
  $discovery_auth = DiscoveryAuth.new
  iscsi_target_server.run
end