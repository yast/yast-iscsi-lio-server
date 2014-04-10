# encoding: utf-8

# |***************************************************************************
# |
# | Copyright (c) [2012] Novell, Inc.
# | All Rights Reserved.
# |
# | This program is free software; you can redistribute it and/or
# | modify it under the terms of version 2 of the GNU General Public License as
# | published by the Free Software Foundation.
# |
# | This program is distributed in the hope that it will be useful,
# | but WITHOUT ANY WARRANTY; without even the implied warranty of
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# | GNU General Public License for more details.
# |
# | You should have received a copy of the GNU General Public License
# | along with this program; if not, contact Novell, Inc.
# |
# | To contact Novell about this file by physical or electronic mail,
# | you may find current contact information at www.novell.com
# |
# |***************************************************************************
# File:	clients/iscsi-lio-server.ycp
# Package:	Configuration of iscsi-lio-server
# Summary:	Main file
# Authors:	Thomas Fehr <fehr@suse.de>
#
# $Id$
#
# Main file for iscsi-lio-server configuration. Uses all other files.
module Yast
  module IscsiLioServerDialogsInclude
    def initialize_iscsi_lio_server_dialogs(include_target)
      textdomain "iscsi-lio-server"

      Yast.import "Label"
      Yast.import "String"
      Yast.import "Wizard"
      Yast.import "IscsiLioServer"
      Yast.import "IscsiLioData"
      Yast.import "CWMTab"
      Yast.import "CWM"
      Yast.import "CWMServiceStart"
      Yast.import "CWMFirewallInterfaces"
      Yast.import "TablePopup"

      Yast.include include_target, "iscsi-lio-server/helps.rb"
      Yast.include include_target, "iscsi-lio-server/widgets.rb"

      # store current here
      @current_tab = "service"

      @tabs_descr = {
        # first tab - service status and firewall
        "service"        => {
          "header"       => _("Service"),
          "contents"     => VBox(
            VStretch(),
            HBox(
              HStretch(),
              HSpacing(1),
              VBox("auto_start_up", VSpacing(2), "firewall", VSpacing(2)),
              HSpacing(1),
              HStretch()
            ),
            VStretch()
          ),
          "widget_names" => ["auto_start_up", "firewall"]
        },
        # second tab - global authentication
        "global"         => {
          "header"       => _("Global"),
          "contents"     => VBox(
            VStretch(),
            HBox(
              HStretch(),
              HSpacing(1),
              VBox("global_config", VSpacing(2)),
              HSpacing(1),
              HStretch()
            ),
            VStretch()
          ),
          "widget_names" => ["global_config"]
        },
        # third tab - targets / luns
        "targets"        => {
          "header"       => _("Targets"),
          "contents"     => VBox(
            VStretch(),
            HBox(
              HStretch(),
              HSpacing(1),
              VBox("server_table", VSpacing(2)),
              HSpacing(1),
              HStretch()
            ),
            VStretch()
          ),
          "widget_names" => ["server_table"]
        },
        "target-details" => {
          "contents" => HBox(
            HWeight(2, Empty()),
            HWeight(
              4,
              VBox(
                HBox(
                  HWeight(
                    3,
                    InputField(
                      Id(:target),
                      Opt(:hstretch),
                      _("Target"),
                      "iqn.2001-04.com.example"
                    )
                  ),
                  HWeight(
                    3,
                    InputField(
                      Id(:identifier),
                      Opt(:hstretch),
                      _("Identifier"),
                      "test"
                    )
                  ),
                  HWeight(1, InputField(Id(:tpg), _("Portal group"), "1"))
                ),
                HBox(
                  HWeight(
                    3,
                    ComboBox(
                      Id(:ipaddr),
                      Opt(:hstretch),
                      _("Ip address"),
                      IscsiLioData.GetIpAddr
                    )
                  ),
                  HWeight(1, InputField(Id(:port), _("Port number"), "3260"))
                ),
                VSpacing(0.5),
                Left(HBox(CheckBox(Id(:auth), _("Use Authentication"), true))),
                VSpacing(0.5),
                Table(
                  Id(:lun_table),
                  Header(_("LUN"), _("Name"), _("Path")),
                  []
                ),
                Left(
                  HBox(
                    PushButton(Id(:add), _("Add")),
                    PushButton(Id(:edit), _("Edit")),
                    PushButton(Id(:delete), _("Delete"))
                  )
                )
              )
            ),
            HWeight(2, Empty())
          )
        },
        "clnt"           => {
          "contents" => HBox(
            HWeight(2, Empty()),
            HWeight(
              4,
              VBox(
                HBox(
                  HWeight(
                    3,
                    InputField(
                      Id(:target),
                      Opt(:hstretch),
                      _("Target"),
                      "iqn.2001-04.com.example"
                    )
                  ),
                  HWeight(
                    3,
                    InputField(
                      Id(:identifier),
                      Opt(:hstretch),
                      _("Identifier"),
                      "test"
                    )
                  ),
                  HWeight(1, InputField(Id(:tpg), _("Portal group"), "1"))
                ),
                Table(
                  Id(:clnt_table),
                  Header(_("Client"), _("Lun Mapping"), _("Auth")),
                  []
                ),
                Left(
                  HBox(
                    PushButton(Id(:add), _("Add")),
                    PushButton(Id(:edit_lun), _("Edit LUN")),
                    PushButton(Id(:edit_auth), _("Edit Auth")),
                    PushButton(Id(:delete), _("Delete")),
                    PushButton(Id(:copy), _("Copy"))
                  )
                )
              )
            ),
            HWeight(2, Empty())
          )
        },
        "auth"           => {
          "contents" => VBox(
            Left(
              CheckBox(
                Id(:auth_none),
                Opt(:notify),
                _("No Authentication"),
                true
              )
            ),
            VSpacing(2),
            Left(
              CheckBox(
                Id(:auth_in),
                Opt(:notify),
                _("Incoming Authentication"),
                false
              )
            ),
            VBox(
              Table(
                Id(:incoming_table),
                Header(_("Username"), _("Password")),
                []
              ),
              Left(
                HBox(
                  PushButton(Id(:add), _("Add")),
                  PushButton(Id(:edit), _("Edit")),
                  PushButton(Id(:delete), _("Delete"))
                )
              )
            ),
            VSpacing(2),
            Left(
              CheckBox(
                Id(:auth_out),
                Opt(:notify),
                _("Outgoing Authentication"),
                false
              )
            ),
            HBox(
              InputField(Id(:user_out), Opt(:hstretch), _("Username")),
              Password(Id(:pass_out), _("Password"))
            )
          )
        }
      }



      @widgets = {
        "auto_start_up" => CWMServiceStart.CreateAutoStartWidget(
          {
            "get_service_auto_start" => fun_ref(
              IscsiLioServer.method(:GetStartService),
              "boolean ()"
            ),
            "set_service_auto_start" => fun_ref(
              IscsiLioServer.method(:SetStartService),
              "void (boolean)"
            ),
            # radio button (starting LIO target service - option 1)
            "start_auto_button"      => _(
              "When &Booting"
            ),
            # radio button (starting LIO target service - option 2)
            "start_manual_button"    => _(
              "&Manually"
            ),
            "help"                   => Builtins.sformat(
              CWMServiceStart.AutoStartHelpTemplate,
              # part of help text, used to describe radiobuttons (matching starting LIO target service but without "&")
              _("When Booting"),
              # part of help text, used to describe radiobuttons (matching starting LIO target service but without "&")
              _("Manually")
            )
          }
        ),
        # firewall
        "firewall"      => CWMFirewallInterfaces.CreateOpenFirewallWidget(
          { "services" => ["service:target"], "display_details" => true }
        ),
        # discovery authentication dialog
        "global_config" => {
          "widget"            => :custom,
          "custom_widget"     => AuthTerm(true),
          "init"              => fun_ref(method(:initGlobal), "void (string)"),
          "handle"            => fun_ref(
            method(:handleAuth),
            "symbol (string, map)"
          ),
          "store"             => fun_ref(
            method(:storeGlobal),
            "void (string, map)"
          ),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:validateGlobal),
            "boolean (string, map)"
          ),
          "help"              => Ops.get_string(@HELPS, "global_config", "")
        },
        # targets dialog
        "server_table"  => {
          "widget"        => :custom,
          "custom_widget" => VBox(
            Table(
              Id(:server),
              Header(_("Targets"), Right(_("Portal group"))),
              []
            ),
            Left(
              HBox(
                PushButton(Id(:add), _("Add")),
                PushButton(Id(:edit), _("Edit")),
                PushButton(Id(:delete), _("Delete"))
              )
            )
          ),
          "init"          => fun_ref(method(:initTable), "void (string)"),
          "handle"        => fun_ref(
            method(:handleTable),
            "symbol (string, map)"
          ),
          "help"          => Ops.get_string(@HELPS, "server_table", "")
        },
        # dialog for add new target
        "target-add"    => {
          "widget"            => :custom,
          "custom_widget"     => Ops.get(
            @tabs_descr,
            ["target-details", "contents"]
          ),
          "init"              => fun_ref(
            method(:initAddTarget),
            "void (string)"
          ),
          "store"             => fun_ref(
            method(:storeAddTarget),
            "void (string, map)"
          ),
          "handle"            => fun_ref(
            method(:handleModify),
            "symbol (string, map)"
          ),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:validateAddTarget),
            "boolean (string, map)"
          ),
          "help"              => Ops.get_string(@HELPS, "target-add", "")
        },
        # dialog for expert settings
        "expert"        => {
          "widget"        => :custom,
          "custom_widget" => VBox(
            VBox(
              Table(Id(:expert_table), Header(_("Key"), _("Value")), []),
              Left(
                HBox(
                  PushButton(Id(:add), _("Add")),
                  PushButton(Id(:edit), _("Edit")),
                  PushButton(Id(:delete), _("Delete"))
                )
              )
            )
          ),
          #        "init"   : initGlobal,
          #        "handle" : handleAuth,
          #        "store"  : storeGlobal,
          "help"          => Ops.get_string(
            @HELPS,
            "expert",
            ""
          )
        },
        # dialog for add/edit authentication for target
        "target-clnt"   => {
          "widget"            => :custom,
          "custom_widget"     => Ops.get(@tabs_descr, ["clnt", "contents"]),
          "init"              => fun_ref(method(:initClient), "void (string)"),
          "handle"            => fun_ref(
            method(:handleClient),
            "symbol (string, map)"
          ),
          "store"             => fun_ref(
            method(:storeClient),
            "void (string, map)"
          ),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:validateClient),
            "boolean (string, map)"
          ),
          "help"              => Ops.get_string(@HELPS, "target-clnt", "")
        },
        # dialog for modifying target
        "target-modify" => {
          "widget"        => :custom,
          "custom_widget" => Ops.get(
            @tabs_descr,
            ["target-details", "contents"]
          ),
          "init"          => fun_ref(method(:initModify), "void (string)"),
          "handle"        => fun_ref(
            method(:handleModify),
            "symbol (string, map)"
          ),
          "store"         => fun_ref(method(:storeModify), "void (string, map)"),
          "help"          => Ops.get_string(@HELPS, "target-modify", "")
        }
      }
    end

    # Summary dialog
    # @return dialog result
    # Main dialog - tabbed
    def SummaryDialog
      caption = _("iSCSI LIO Target Overview")
      widget_descr = {
        "tab" => CWMTab.CreateWidget(
          {
            "tab_order"    => ["service", "global", "targets"],
            "tabs"         => @tabs_descr,
            "widget_descr" => @widgets,
            "initial_tab"  => @current_tab,
            "tab_help"     => _("<h1>iSCSI Target</h1>")
          }
        )
      }
      contents = VBox("tab")
      w = CWM.CreateWidgets(
        ["tab"],
        Convert.convert(
          widget_descr,
          :from => "map",
          :to   => "map <string, map <string, any>>"
        )
      )
      help = CWM.MergeHelps(w)
      contents = CWM.PrepareDialog(contents, w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.NextButton,
        Label.FinishButton
      )
      Wizard.DisableBackButton

      ret = CWM.Run(
        w,
        { :abort => fun_ref(method(:ReallyAbort), "boolean ()") }
      )
      ret
    end

    # dialog for add target
    def AddDialog
      @current_tab = "targets"
      caption = _("Add iSCSI Target")
      w = CWM.CreateWidgets(["target-add"], @widgets)
      contents = VBox(
        VStretch(),
        HBox(
          HStretch(),
          HSpacing(1),
          VBox(Ops.get_term(w, [0, "widget"]) { VSpacing(1) }, VSpacing(2)),
          HSpacing(1),
          HStretch()
        ),
        VStretch()
      )

      help = CWM.MergeHelps(w)
      contents = CWM.PrepareDialog(contents, w)
      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "target-add", ""),
        Label.BackButton,
        Label.NextButton
      )

      ret = CWM.Run(
        w,
        { :abort => fun_ref(method(:ReallyAbort), "boolean ()") }
      )
      deep_copy(ret)
    end

    # discovery authentication dialog
    def AuthDialog
      @current_tab = "targets"
      caption = _("Modify iSCSI Target Client Setup")
      w = CWM.CreateWidgets(["target-clnt"], @widgets)
      contents = VBox(
        VStretch(),
        HBox(
          HStretch(),
          HSpacing(1),
          VBox(Ops.get_term(w, [0, "widget"]) { VSpacing(1) }, VSpacing(2)),
          HSpacing(1),
          HStretch()
        ),
        VStretch()
      )

      help = CWM.MergeHelps(w)
      contents = CWM.PrepareDialog(contents, w)
      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "target-clnt", ""),
        Label.BackButton,
        Label.NextButton
      )

      ret = CWM.Run(
        w,
        { :abort => fun_ref(method(:ReallyAbort), "boolean ()") }
      )
      deep_copy(ret)
    end

    # edit target dialog
    def EditDialog
      @current_tab = "targets"
      caption = _("Modify iSCSI Target Lun Setup")
      w = CWM.CreateWidgets(["target-modify"], @widgets)
      contents = VBox(
        VStretch(),
        HBox(
          HStretch(),
          HSpacing(1),
          VBox(Ops.get_term(w, [0, "widget"]) { VSpacing(1) }, VSpacing(2)),
          HSpacing(1),
          HStretch()
        ),
        VStretch()
      )

      help = CWM.MergeHelps(w)
      contents = CWM.PrepareDialog(contents, w)
      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "target-modify", ""),
        Label.BackButton,
        Label.NextButton
      )

      ret = CWM.Run(
        w,
        { :abort => fun_ref(method(:ReallyAbort), "boolean ()") }
      )
      deep_copy(ret)
    end

    # expert target dialog
    def ExpertDialog
      caption = _("iSCSI Target Expert Settings")
      w = CWM.CreateWidgets(["expert"], @widgets)
      contents = VBox(
        VStretch(),
        HBox(
          HStretch(),
          HSpacing(1),
          VBox(Ops.get_term(w, [0, "widget"]) { VSpacing(1) }, VSpacing(2)),
          HSpacing(1),
          HStretch()
        ),
        VStretch()
      )

      help = CWM.MergeHelps(w)
      contents = CWM.PrepareDialog(contents, w)
      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "expert", ""),
        Label.BackButton,
        Label.NextButton
      )

      ret = CWM.Run(
        w,
        { :abort => fun_ref(method(:ReallyAbort), "boolean ()") }
      )
      deep_copy(ret)
    end
  end
end
