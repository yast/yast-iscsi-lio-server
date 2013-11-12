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
  module IscsiLioServerWidgetsInclude
    def initialize_iscsi_lio_server_widgets(include_target)
      textdomain "iscsi-lio-server"
      Yast.import "IscsiLioData"
      Yast.import "Label"
      Yast.import "Event"
      Yast.import "ContextMenu"
      Yast.import "IP"
      #	**************** global funcions and variables *****
      @curr_target = ""
      @curr_tpg = 1
      @changed_lun = {}
      @changed_auth = {}
      @del_clnt = []
    end

    # set incoming authentication enabled/disabled status
    def SetAuthIn(status)
      Builtins.y2milestone("Status of AuthIncoming %1", status)
      UI.ChangeWidget(Id(:user_in), :Enabled, status)
      UI.ChangeWidget(Id(:pass_in), :Enabled, status)
      UI.ChangeWidget(Id(:auth_in), :Value, status)
      if UI.WidgetExists(Id(:auth_none)) && status
        UI.ChangeWidget(Id(:auth_none), :Value, !status)
      end

      nil
    end

    # set outgoing authentication enabled/disabled status
    def SetAuthOut(status)
      Builtins.y2milestone("Status of AuthOutgoing %1", status)
      UI.ChangeWidget(Id(:user_out), :Enabled, status)
      UI.ChangeWidget(Id(:pass_out), :Enabled, status)
      UI.ChangeWidget(Id(:auth_out), :Value, status)
      if UI.WidgetExists(Id(:auth_none)) && status
        UI.ChangeWidget(Id(:auth_none), :Value, !status)
      end

      nil
    end

    # get values for incoming authentication
    def GetIncomingValues
      values = []
      if Convert.to_boolean(UI.QueryWidget(Id(:auth_in), :Value)) == true
        values = [
          Convert.to_string(UI.QueryWidget(Id(:user_in), :Value)),
          Convert.to_string(UI.QueryWidget(Id(:pass_in), :Value))
        ]
      end
      deep_copy(values)
    end

    # get values for outgoing authentication
    def GetOutgoingValues
      values = []
      if Convert.to_boolean(UI.QueryWidget(Id(:auth_out), :Value)) == true
        values = [
          Convert.to_string(UI.QueryWidget(Id(:user_out), :Value)),
          Convert.to_string(UI.QueryWidget(Id(:pass_out), :Value))
        ]
      end
      deep_copy(values)
    end

    #	**************** Global Dialog	*********************
    def initGlobalValues(auth)
      auth = deep_copy(auth)
      user = ""
      pass = ""
      # incoming authentication
      if !Builtins.isempty(Ops.get_list(auth, "incoming", []))
        user = Ops.get_string(auth, ["incoming", 0], "")
        pass = Ops.get_string(auth, ["incoming", 1], "")
      end
      UI.ChangeWidget(Id(:user_in), :Value, user)
      UI.ChangeWidget(Id(:pass_in), :Value, pass)
      SetAuthIn(!Builtins.isempty(Ops.get_list(auth, "incoming", [])))
      # outgoing authentication
      user = ""
      pass = ""
      if !Builtins.isempty(Ops.get_list(auth, "outgoing", []))
        user = Ops.get_string(auth, ["outgoing", 0], "")
        pass = Ops.get_string(auth, ["outgoing", 1], "")
      end
      UI.ChangeWidget(Id(:user_out), :Value, user)
      UI.ChangeWidget(Id(:pass_out), :Value, pass)
      SetAuthOut(!Builtins.isempty(Ops.get_list(auth, "outgoing", [])))

      nil
    end

    # initialize discovery authentication or authentication for given target
    def initGlobal(key)
      initGlobalValues(IscsiLioData.GetAuth("", 0, ""))

      nil
    end

    # save discovery authentication or authentication for given target
    def storeGlobal(option_id, option_map)
      option_map = deep_copy(option_map)
      Builtins.y2milestone("storeGlobal id:%1 map:%2", option_id, option_map)
      ret = false
      ret = IscsiLioData.SetAuth(
        "",
        0,
        "",
        GetIncomingValues(),
        GetOutgoingValues()
      )
      Popup.Error(_("Problem changing authentication")) if !ret
      IscsiLioData.UpdateConfig

      nil
    end

    # validate functions checks the secret for incoming and outgoing cannot be same
    def validateGlobal(key, event)
      event = deep_copy(event)
      Builtins.y2milestone("validateGlobal key:%1 ev:%2", key, event)
      ret = true
      _in = GetIncomingValues()
      if Ops.greater_than(Builtins.size(_in), 0) &&
          (Builtins.size(Ops.get(_in, 0, "")) == 0 ||
            Builtins.size(Ops.get(_in, 1, "")) == 0)
        user_fail = Builtins.size(Ops.get(_in, 0, "")) == 0
        txt = user_fail ? _("Invalid Username") : _("Invalid Password.")
        UI.SetFocus(Id(user_fail ? :user_in : :pass_in))
        Popup.Error(txt)
        ret = false
      end
      out = GetOutgoingValues()
      if Ops.greater_than(Builtins.size(out), 0) &&
          (Builtins.size(Ops.get(out, 0, "")) == 0 ||
            Builtins.size(Ops.get(out, 1, "")) == 0)
        user_fail = Builtins.size(Ops.get(out, 0, "")) == 0
        txt = user_fail ? _("Invalid Username") : _("Invalid Password.")
        UI.SetFocus(Id(user_fail ? :user_out : :pass_out))
        Popup.Error(txt)
        ret = false
      end
      ret
    end

    #	**************** Target Auth	*******************
    # handle authentication dialog
    def handleAuth(key, event)
      event = deep_copy(event)
      if Ops.get_string(event, "EventReason", "") == "ValueChanged"
        status = false
        # enable/disable none/incoming/outgoing authentication
        case Ops.get_symbol(event, "ID")
          when :auth_none
            status = Convert.to_boolean(UI.QueryWidget(Id(:auth_none), :Value))
            SetAuthIn(!status)
            SetAuthOut(!status)
          when :auth_in
            status = Convert.to_boolean(UI.QueryWidget(Id(:auth_in), :Value))
            SetAuthIn(status)
          when :auth_out
            status = Convert.to_boolean(UI.QueryWidget(Id(:auth_out), :Value))
            SetAuthOut(status)
        end
      end
      nil
    end

    def AuthTerm(discovery)
      no_auth = Empty()
      if discovery
        no_auth = VBox(
          Left(
            CheckBox(Id(:auth_none), Opt(:notify), _("No Authentication"), true)
          ),
          VSpacing(1.5)
        )
      end
      t = VBox(
        no_auth,
        Left(
          CheckBox(
            Id(:auth_in),
            Opt(:notify),
            _("Incoming Authentication"),
            false
          )
        ),
        HBox(
          InputField(Id(:user_in), Opt(:hstretch), _("Username")),
          Password(Id(:pass_in), _("Password"))
        ),
        VSpacing(1.5),
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
      deep_copy(t)
    end

    def CheckLun(l, other, silent)
      other = deep_copy(other)
      s = Builtins.tostring(l)
      ret = Builtins.isempty(Builtins.filter(other) do |i|
        Ops.get_string(i, 1, "") == s
      end)
      Builtins.y2milestone("CheckLun other:%1", other)
      Builtins.y2milestone("CheckLun l:%1 ret:%2", l, ret)
      Popup.Error(_("Selected Lun is already in use!")) if !ret && !silent
      ret
    end

    def CheckName(n, other)
      other = deep_copy(other)
      ret = Builtins.isempty(Builtins.filter(other) do |i|
        Ops.get_string(i, 2, "") == n
      end)
      Popup.Error(_("Selected Name is already in use!")) if !ret
      ret
    end

    def CheckPath(p, other)
      other = deep_copy(other)
      ret = Ops.get_boolean(IscsiLioData.CheckPath(p), 0, false)
      if !ret
        Popup.Error(
          _("Selected Path must be either block device or normal file!")
        )
      end
      if ret && !Builtins.isempty(Builtins.filter(other) do |i|
          Ops.get_string(i, 3, "") == p
        end)
        Popup.Error(_("Selected Path is already in use!"))
        ret = false
      end
      ret
    end

    def LUNDetailDialog(pos, items)
      items = deep_copy(items)
      Builtins.y2milestone("LUNDetailDialog pos:%1 items:%2", pos, items)
      other = Ops.greater_or_equal(pos, 0) ? Builtins.remove(items, pos) : items
      Builtins.y2milestone("LUNDetailDialog other:%1", other)
      previous = Ops.get(items, pos, Empty())
      ret = Empty()
      lun_def = "99"
      if Ops.less_than(pos, 0)
        count = 0
        while !CheckLun(count, other, true)
          count = Ops.add(count, 1)
        end
        lun_def = Builtins.tostring(count)
      end
      lun_dialog = VBox(
        Left(
          InputField(
            Id(:lun),
            Opt(:hstretch),
            _("LUN"),
            Ops.get_string(previous, 1, lun_def)
          )
        ),
        VSpacing(1),
        HBox(
          InputField(
            Id(:path),
            Opt(:hstretch),
            _("Path:"),
            Ops.get_string(previous, 3, "")
          ),
          VBox(Label(""), PushButton(Id(:browse), _("Browse")))
        ),
        InputField(
          Id(:name),
          Opt(:hstretch),
          "Name (autogenerated when empty):",
          Ops.get_string(previous, 2, "")
        ),
        VSpacing(1),
        ButtonBox(
          PushButton(Id(:ok), Opt(:default), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        )
      )
      UI.OpenDialog(lun_dialog)
      UI.ChangeWidget(Id(:lun), :ValidChars, "0123456789")
      sym = :nil
      while sym != :ok && sym != :cancel
        sym = Convert.to_symbol(UI.UserInput)
        if sym == :browse
          file = UI.AskForExistingFile("/", "", _("Select file or device"))
          if file != nil && CheckPath(file, other)
            UI.ChangeWidget(:path, :Value, file)
          end
        elsif sym == :path
          CheckPath(Convert.to_string(UI.QueryWidget(:path, :Value)), other)
        end
        if sym == :ok
          lun = Builtins.tointeger(UI.QueryWidget(:lun, :Value))
          name = Convert.to_string(UI.QueryWidget(:name, :Value))
          pth = Convert.to_string(UI.QueryWidget(:path, :Value))
          Builtins.y2milestone(
            "LUNDetailDialog lun:%1 name:%2 path:%3",
            lun,
            name,
            pth
          )
          if !CheckPath(pth, other) || !CheckLun(lun, other, false) ||
              !CheckName(name, other)
            sym = :again
          end
          if sym == :ok
            if Builtins.isempty(name)
              used = Builtins.maplist(other) { |i| Ops.get_string(i, 2, "") }
              Builtins.y2milestone("LUNDetailDialog used:%1", used)
              name = IscsiLioData.CreateLunName(used, pth)
            end
            ret = Item(
              Id(Ops.greater_or_equal(pos, 0) ? pos : Builtins.size(other)),
              lun,
              name,
              pth
            )
            Builtins.y2milestone("LUNDetailDialog ret:%1", ret)
          end
        end
      end
      UI.CloseDialog
      Builtins.y2milestone("LUNDetailDialog ret:%1", ret)
      deep_copy(ret)
    end

    def TpgIdFromTpgItem(s)
      val = s != "-" ? Builtins.tointeger(s) : -1
      val = -1 if val == nil
      val
    end

    def TpgItemFromTpgId(i)
      Ops.greater_or_equal(i, 0) ? Builtins.tostring(i) : "-"
    end

    def ChangeTpgItems(id, value, items)
      Builtins.y2milestone("ChangeTpgItems id:%1 value:%2", id, value)
      if value != nil
        it = Ops.get(items.value, id, Empty())
        Ops.set(it, 2, TpgItemFromTpgId(value))
        Ops.set(items.value, id, it)
        UI.ChangeWidget(Id(:lun), :Items, items.value)
        UI.ChangeWidget(Id(:lun), :CurrentItem, id)
      end

      nil
    end

    def LUNMapDialog(clnt)
      Builtins.y2milestone("LUNMapDialog clnt:%1", clnt)
      lmap = {}
      Builtins.y2milestone("changed_lun: %1", @changed_lun)
      if Builtins.haskey(@changed_lun, clnt)
        lmap = Ops.get(@changed_lun, clnt, {})
      else
        lmap = IscsiLioData.GetClntLun(@curr_target, @curr_tpg, clnt)
      end
      Builtins.y2milestone("LUNMapDialog map:%1", lmap)
      ll = Builtins.maplist(lmap) { |l, d| l }
      lt = Builtins.maplist(IscsiLioData.GetLun(@curr_target, @curr_tpg)) do |l, d|
        Item(Id(l), Builtins.tostring(l))
      end
      lt = Builtins.add(lt, Item(Id(-1), "-"))
      mx = Ops.get(ll, Ops.subtract(Builtins.size(ll), 1), -1)
      i = 0
      items = []
      while Ops.less_or_equal(i, mx)
        items = Builtins.add(
          items,
          Item(
            Id(i),
            Builtins.tostring(i),
            Builtins.haskey(lmap, i) ?
              Builtins.tostring(Ops.get(lmap, i, 99)) :
              "-"
          )
        )
        i = Ops.add(i, 1)
      end
      Builtins.y2milestone("LUNMapDialog items:%1", items)
      lun_dialog = VBox(
        MinHeight(
          10,
          Table(
            Id(:lun),
            Opt(:keepSorting, :immediate, :notify, :notifyContextMenu),
            Header(_("Client Lun"), _("Target LUN")),
            items
          )
        ),
        Left(
          HBox(
            PushButton(Id(:add), _("Add")),
            PushButton(Id(:delete), _("Delete")),
            Label(_("Change:")),
            ComboBox(Id(:change), Opt(:notify), "", lt)
          )
        ),
        ButtonBox(
          PushButton(Id(:ok), Opt(:default), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        )
      )
      UI.OpenDialog(lun_dialog)
      if Builtins.size(items) == 0
        UI.ChangeWidget(Id(:change), :Enabled, false)
        UI.ChangeWidget(Id(:delete), :Enabled, false)
      end
      UI.ChangeWidget(
        Id(:change),
        :Value,
        TpgIdFromTpgItem(Ops.get_string(items, [0, 2], "-"))
      )
      sym = :nil
      while sym != :ok && sym != :cancel
        ev = UI.WaitForEvent
        sym = Event.IsWidgetActivatedOrSelectionChanged(ev)
        sym = Event.IsWidgetValueChanged(ev) if sym == nil
        sym = Event.IsWidgetContextMenuActivated(ev) if sym == nil
        Builtins.y2milestone("LUNMapDialog event:%1 sym:%2", ev, sym)
        if sym == :lun
          id = Convert.to_integer(UI.QueryWidget(:lun, :CurrentItem))
          Builtins.y2milestone(
            "LUNMapDialog id:%1 item:%2",
            id,
            Ops.get(items, id)
          )
          if Event.IsWidgetContextMenuActivated(ev) != nil
            UI.OpenContextMenu(term(:menu, lt))
            value = Convert.to_integer(UI.UserInput)
            items_ref = arg_ref(items)
            ChangeTpgItems(id, value, items_ref)
            items = items_ref.value
            UI.ChangeWidget(Id(:change), :Value, value)
          else
            UI.ChangeWidget(
              Id(:change),
              :Value,
              TpgIdFromTpgItem(Ops.get_string(items, [id, 2], "-"))
            )
          end
        elsif sym == :add
          n = Builtins.size(items)
          items = Builtins.add(items, Item(Id(n), Builtins.tostring(n), "-"))
          UI.ChangeWidget(Id(:lun), :Items, items)
          UI.ChangeWidget(Id(:lun), :CurrentItem, n)
          UI.ChangeWidget(Id(:change), :Value, -1)
          if Builtins.size(items) == 1
            UI.ChangeWidget(Id(:change), :Enabled, true)
            UI.ChangeWidget(Id(:delete), :Enabled, true)
          end
        elsif sym == :delete
          id = Convert.to_integer(UI.QueryWidget(:lun, :CurrentItem))
          if id != nil && Ops.less_than(id, Builtins.size(items))
            items_ref = arg_ref(items)
            ChangeTpgItems(id, -1, items_ref)
            items = items_ref.value
          end
        elsif sym == :change
          id = Convert.to_integer(UI.QueryWidget(:lun, :CurrentItem))
          value = Convert.to_integer(UI.QueryWidget(:change, :Value))
          if id != nil && Ops.less_than(id, Builtins.size(items))
            items_ref = arg_ref(items)
            ChangeTpgItems(id, value, items_ref)
            items = items_ref.value
          end
        elsif sym == :ok
          lmap = {}
          Builtins.foreach(items) do |it|
            s = Ops.get_string(it, 2, "-")
            i = nil
            i = Builtins.tointeger(Ops.get_string(it, 2, "")) if s != "-"
            if i != nil
              Ops.set(lmap, Builtins.tointeger(Ops.get_string(it, 1, "0")), i)
            end
          end
          Builtins.y2milestone("LUNMapDialog ret:%1", lmap)
          ok = true
          ll2 = Builtins.maplist(lmap) { |l, d| l }
          ld = Builtins.maplist(lmap) { |l, d| d }
          i = 0
          while Ops.less_than(i, Builtins.size(ll2)) && ok
            ok = Ops.less_or_equal(Builtins.size(Builtins.filter(ld) do |j|
              j == Ops.get(ld, i, -1)
            end), 1)
            if !ok
              txt = Builtins.sformat(
                _("Target LUN %1 used more than once!"),
                Ops.get(ld, i, -1)
              )
              j = Ops.add(i, 1)
              while Ops.get(ld, i, -1) != Ops.get(ld, j, -1) &&
                  Ops.less_than(j, Builtins.size(ll2))
                j = Ops.add(j, 1)
              end
              if Ops.less_than(j, Builtins.size(items))
                UI.ChangeWidget(Id(:lun), :CurrentItem, Ops.get(ll2, j, 0))
              end
              Popup.Error(txt)
            end
            i = Ops.add(i, 1)
          end
          sym = :again if !ok
        elsif sym == :cancel
          lmap = nil
        end
      end
      UI.CloseDialog
      Ops.set(@changed_lun, clnt, lmap) if lmap != nil
      Builtins.y2milestone("LUNMapDialog ret:%1", lmap)
      deep_copy(lmap)
    end

    def ClntAuthDialog(clnt)
      Builtins.y2milestone("ClntAuthDialog clnt:%1", clnt)
      lmap = {}
      if Builtins.haskey(@changed_auth, clnt)
        lmap = Ops.get(@changed_auth, clnt, {})
      else
        lmap = IscsiLioData.GetAuth(@curr_target, @curr_tpg, clnt)
      end
      Builtins.y2milestone("ClntAuthDialog map:%1", lmap)
      auth_dialog = VBox(
        MarginBox(6, 2, AuthTerm(false)),
        ButtonBox(
          PushButton(Id(:ok), Opt(:default), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        )
      )
      UI.OpenDialog(auth_dialog)
      initGlobalValues(lmap)
      sym = :nil
      while sym != :ok && sym != :cancel
        ev = UI.WaitForEvent
        sym = Event.IsWidgetActivatedOrSelectionChanged(ev)
        sym = Event.IsWidgetValueChanged(ev) if sym == nil
        Builtins.y2milestone("ClntAuthDialog event:%1 sym:%2", ev, sym)
        handleAuth("", ev) if sym != nil
        if sym == :ok
          lmap = {}
          if !validateGlobal("", {})
            sym = :again
          else
            _in = GetIncomingValues()
            out = GetOutgoingValues()
            Ops.set(lmap, "incoming", _in)
            Ops.set(lmap, "outgoing", out)
            if Builtins.size(_in) == 0 && Builtins.size(out) == 0
              sym = :again
              Popup.Error(_("Need to enable at least one Authentification!"))
            end
          end
        elsif sym == :cancel
          lmap = nil
        end
      end
      UI.CloseDialog
      Ops.set(@changed_auth, clnt, lmap) if lmap != nil
      Builtins.y2milestone("ClntAuthDialog ret:%1", lmap)
      deep_copy(lmap)
    end

    def AddClntDialog
      Builtins.y2milestone("AddClntDialog")
      ret = {}
      dlg = VBox(
        MarginBox(
          4,
          1,
          VBox(
            Left(Label(_("Client name:"))),
            MinWidth(50, InputField(Id(:clnt), Opt(:hstretch), "", "")),
            VSpacing(0.5),
            Left(CheckBox(Id(:import), _("Import LUNs from TPG"), true))
          )
        ),
        ButtonBox(
          PushButton(Id(:ok), Opt(:default), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        )
      )
      UI.OpenDialog(dlg)
      sym = :nil
      while sym != :ok && sym != :cancel
        sym = Convert.to_symbol(UI.UserInput)
        Builtins.y2milestone("AddClntDialog sym:%1", sym)
        if sym == :ok
          txt = ""
          s = Convert.to_string(UI.QueryWidget(Id(:clnt), :Value))
          txt = _("Client name must not be empty!") if Builtins.isempty(s)
          Builtins.y2milestone("Changed_lun: %1 new client name: %2", @changed_lun, s)
          # Don't check IscsiLioData.GetClntList(@curr_target, @curr_tpg) for existing
          # client name. It's allowed to have several LUNs accessable for same client.
          # TODO: verify whether it's necessary to check @changed_lun here?
          if @changed_lun.has_key?(s)
            txt = _("Client name already exists!")
          end
          if !Builtins.isempty(txt)
            sym = :again
            UI.SetFocus(Id(:clnt))
            Popup.Error(txt)
          else
            Ops.set(ret, "clnt", s)
            Ops.set(
              ret,
              "import",
              Convert.to_boolean(UI.QueryWidget(Id(:import), :Value))
            )
          end
        end
      end
      UI.CloseDialog
      Builtins.y2milestone("AddClntDialog ret:%1", ret)
      deep_copy(ret)
    end

    #
    # Copy exisiting LUN, i.e. give additional client access to the LUN
    # (which is allowed, makes sense e.g. with multipath)
    #
    def CopyClntDialog
      Builtins.y2milestone("CopyClntDialog")
      ret = ""
      dlg = VBox(
        MarginBox(
          4,
          1,
          VBox(
            Left(Label(_("New client name:"))),
            MinWidth(50, InputField(Id(:clnt), Opt(:hstretch), "", ""))
          )
        ),
        ButtonBox(
          PushButton(Id(:ok), Opt(:default), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        )
      )
      UI.OpenDialog(dlg)
      sym = :nil
      while sym != :ok && sym != :cancel
        sym = Convert.to_symbol(UI.UserInput)
        Builtins.y2milestone("CopyClntDialog sym:%1", sym)
        if sym == :ok
          txt = ""
          s = Convert.to_string(UI.QueryWidget(Id(:clnt), :Value))
          txt = _("Client name must not be empty!") if Builtins.isempty(s)
          if Builtins.haskey(@changed_lun, s) ||
              Builtins.contains(
                IscsiLioData.GetClntList(@curr_target, @curr_tpg),
                s
              )
            txt = _("Client name already exists!")
          end
          if !Builtins.isempty(txt)
            sym = :again
            UI.SetFocus(Id(:clnt))
            Popup.Error(txt)
          else
            ret = s
          end
        end
      end
      UI.CloseDialog
      Builtins.y2milestone("CopyClntDialog ret:%1", ret)
      ret
    end

    # dialog to add/modify user and password
    def getDialogValues(user, pass)
      UI.OpenDialog(
        VBox(
          InputField(Id(:p_user), Opt(:hstretch), _("Username"), user),
          Password(Id(:p_pass), _("Password"), pass),
          HBox(
            PushButton(Id(:ok), _("OK")),
            PushButton(Id(:cancel), _("Cancel"))
          )
        )
      )
      cycle = true
      while cycle
        case Convert.to_symbol(UI.UserInput)
          when :ok
            user = Builtins.tostring(UI.QueryWidget(Id(:p_user), :Value))
            pass = Builtins.tostring(UI.QueryWidget(Id(:p_pass), :Value))
            UI.CloseDialog
            cycle = false
          when :cancel
            cycle = false
            UI.CloseDialog
        end
      end
      if !Builtins.isempty(user) && !Builtins.isempty(pass)
        return [user, pass]
      else
        return []
      end
    end


    def RemoveById(it, id)
      it = deep_copy(it)
      id = deep_copy(id)
      Builtins.y2milestone("RemoveById id:%1 item:%2", id, Builtins.filter(it) do |i|
        Ops.get(i, [0, 0], 99) == id
      end)
      Builtins.filter(it) { |i| Ops.get(i, [0, 0], 99) != id }
    end

    def GetById(it, id)
      it = deep_copy(it)
      id = deep_copy(id)
      Builtins.y2milestone("GetById id:%1", id)
      t = Ops.get(Builtins.filter(it) { |i| Ops.get(i, [0, 0], 99) == id }, 0, Empty(
      ))
      deep_copy(t)
    end

    #	**************** Server Dialog	*********************
    # dialog with targets

    # initialize target dialog
    def initTable(key)
      count = 0
      inc_items = []
      # create items from targets
      tgt = IscsiLioData.GetTargets
      cur = 0
      Builtins.foreach(tgt) do |l|
        inc_items = Builtins.add(
          inc_items,
          Item(
            Id(count),
            Ops.get_string(l, 0, ""),
            Builtins.tostring(Ops.get_integer(l, 1, 0))
          )
        )
        Builtins.y2milestone(
          "tgt:%1 tpg:%2 ctgt:%3 ctpg:%4",
          Ops.get_string(l, 0, ""),
          Ops.get_integer(l, 1, 0),
          @curr_target,
          @curr_tpg
        )
        if @curr_target == Ops.get_string(l, 0, "") &&
            @curr_tpg == Ops.get_integer(l, 1, 1)
          cur = count
        end
        count = Ops.add(count, 1)
      end
      # put it into table
      UI.ChangeWidget(Id(:server), :Items, inc_items)
      UI.ChangeWidget(Id(:server), :CurrentItem, cur) if cur != 0

      nil
    end

    def handleTable(table, event)
      event = deep_copy(event)
      ret = nil
      if Ops.get_string(event, "EventReason", "") == "Activated"
        case Ops.get_symbol(event, "ID")
          when :add
            # goto  AddDialog() (initAddTarget)
            ret = :add
          when :delete
            # remove a item
            @del = UI.QueryWidget(Id(:server), :CurrentItem)
            Builtins.y2milestone("handleTable del:%1", @del)
            if @del != nil
              if Popup.ContinueCancel(_("Really delete the selected item?"))
                it = Convert.convert(
                  UI.QueryWidget(Id(:server), :Items),
                  :from => "any",
                  :to   => "list <term>"
                )
                i = GetById(it, @del)
                Builtins.y2milestone("handleTable item:%1", i)
                if IscsiLioData.DelTarget(
                    Ops.get_string(i, 1, ""),
                    Builtins.tointeger(Ops.get_string(i, 2, "-1"))
                  )
                  it = RemoveById(it, @del)
                  UI.ChangeWidget(Id(:server), :Items, it)
                  IscsiLioData.UpdateConfig
                end
              else
                Builtins.y2milestone("handleTable Delete canceled")
              end
            end
          when :edit
            # edit new item
            @edit = Builtins.tointeger(
              UI.QueryWidget(Id(:server), :CurrentItem)
            )
            @t = Convert.to_term(
              UI.QueryWidget(Id(:server), term(:Item, @edit))
            )
            Builtins.y2milestone("handleTable num:%1 t:%2", @edit, @t)
            @curr_target = Ops.get_string(@t, 1, "")
            @curr_tpg = Builtins.tointeger(Ops.get_string(@t, 2, ""))
            Builtins.y2milestone(
              "handleTable tgt:%1 tpg:%2",
              @curr_target,
              @curr_tpg
            )
            ret = :edit
        end
      end
      empt = Builtins.isempty(Convert.to_list(UI.QueryWidget(:server, :Items)))
      UI.ChangeWidget(:edit, :Enabled, !empt)
      UI.ChangeWidget(:delete, :Enabled, !empt)
      ret
    end

    #	**************** Edit Dialog	*****************************

    # init values for modifying target (read it from stored map)
    def initModify(key)
      inc_items = []
      Builtins.y2milestone("initModify %1 %2", @curr_target, @curr_tpg)
      UI.ChangeWidget(
        Id(:target),
        :Value,
        Ops.get(Builtins.splitstring(@curr_target, ":"), 0, "")
      )
      UI.ChangeWidget(Id(:target), :Enabled, false)
      UI.ChangeWidget(
        Id(:identifier),
        :Value,
        Ops.get(Builtins.splitstring(@curr_target, ":"), 1, "")
      )
      UI.ChangeWidget(Id(:identifier), :Enabled, false)
      UI.ChangeWidget(Id(:tpg), :Value, Builtins.tostring(@curr_tpg))
      UI.ChangeWidget(Id(:tpg), :Enabled, false)
      ipp = Ops.get(
        IscsiLioData.GetNetworkPortal(@curr_target, @curr_tpg),
        0,
        ""
      )
      Builtins.y2milestone("initModify ipp:%1", ipp)
      ip, port = IscsiLioData.GetIpAndPort(ipp)
      UI.ChangeWidget(
        Id(:ipaddr),
        :Value,
        ip || ""
      )
      UI.ChangeWidget(Id(:ipaddr), :Enabled, true)
      UI.ChangeWidget(
        Id(:port),
        :Value,
        port || ""
      )
      UI.ChangeWidget(Id(:port), :Enabled, true)
      UI.ChangeWidget(
        Id(:auth),
        :Value,
        IscsiLioData.GetTpgAuth(@curr_target, @curr_tpg)
      )
      lun = IscsiLioData.GetLunList(@curr_target, @curr_tpg)
      Builtins.y2milestone("initModify lun:%1", lun)
      Builtins.foreach(lun) do |l|
        inc_items = Builtins.add(
          inc_items,
          Item(
            Id(Builtins.size(inc_items)),
            Ops.get_integer(l, 0, 99),
            Ops.get_string(l, 1, ""),
            Ops.get_string(l, 2, "")
          )
        )
      end
      UI.ChangeWidget(Id(:lun_table), :Items, inc_items)

      nil
    end

    def handleModify(key, event)
      event = deep_copy(event)
      if Ops.get_string(event, "EventReason", "") == "Activated"
        case Ops.get_symbol(event, "WidgetID")
          when :delete
            @del = UI.QueryWidget(Id(:lun_table), :CurrentItem)
            if @del != nil
              if Popup.ContinueCancel(_("Really delete the selected item?"))
                Builtins.y2milestone("Delete LUN %1 from table", @del)
                it = Convert.convert(
                  UI.QueryWidget(:lun_table, :Items),
                  :from => "any",
                  :to   => "list <term>"
                )
                it = RemoveById(it, @del)
                UI.ChangeWidget(Id(:lun_table), :Items, it)
              else
                Builtins.y2milestone("Delete canceled")
              end
            end
          when :edit
            @items = Convert.convert(
              UI.QueryWidget(:lun_table, :Items),
              :from => "any",
              :to   => "list <term>"
            )
            @edit_pos = Builtins.tointeger(
              UI.QueryWidget(:lun_table, :CurrentItem)
            )
            Builtins.y2milestone(
              "handleModify pos:%1 items:%2",
              @edit_pos,
              @items
            )
            @ret = LUNDetailDialog(@edit_pos, @items)
            Builtins.y2milestone("handleModify ret:%1", @ret)
            if @ret != Empty()
              Ops.set(@items, @edit_pos, @ret)
              UI.ChangeWidget(:lun_table, :Items, @items)
              UI.ChangeWidget(:lun_table, :CurrentItem, @edit_pos)
            end
          when :add
            @items = Convert.convert(
              UI.QueryWidget(:lun_table, :Items),
              :from => "any",
              :to   => "list <term>"
            )
            @ret = LUNDetailDialog(-1, @items)
            if @ret != Empty()
              @items = Builtins.add(@items, @ret)
              UI.ChangeWidget(:lun_table, :Items, @items)
              UI.ChangeWidget(
                :lun_table,
                :CurrentItem,
                Ops.subtract(Builtins.size(@items), 1)
              )
            end
        end
      end
      enab = !Builtins.isempty(
        Convert.to_list(UI.QueryWidget(:lun_table, :Items))
      )
      UI.ChangeWidget(:edit, :Enabled, enab)
      UI.ChangeWidget(:delete, :Enabled, enab)

      nil
    end

    def storeModify(option_id, option_map)
      option_map = deep_copy(option_map)
      chg = false
      if !IscsiLioData.HasTarget(@curr_target, @curr_tpg)
        chg = true
        if !IscsiLioData.AddTarget(@curr_target, @curr_tpg)
          txt = Builtins.sformat(
            _("Problem creating target %1 with tpg %2"),
            @curr_target,
            @curr_tpg
          )
          Popup.Error(txt)
        end
      end
      ipp = Ops.get(
        IscsiLioData.GetNetworkPortal(@curr_target, @curr_tpg),
        0,
        ""
      )
      ip = Convert.to_string(UI.QueryWidget(:ipaddr, :Value))
      port = Builtins.tointeger(UI.QueryWidget(:port, :Value))
      Builtins.y2milestone("storeModify ip:%1 port:%2 ipp:%3", ip, port, ipp)
      if IP.Check6(ip)
         ip = "[#{ip}]" # brackets needed around IPv6
      end
      np = Builtins.sformat("%1:%2", ip, port)
      if !Builtins.isempty(ip) && np != ipp
        chg = true
        if !IscsiLioData.SetNetworkPortal(@curr_target, @curr_tpg, np)
          txt = Builtins.sformat(_("Problem setting network portal to %1"), np)
          Popup.Error(txt)
        end
      end
      it = Convert.convert(
        UI.QueryWidget(:lun_table, :Items),
        :from => "any",
        :to   => "list <term>"
      )
      nll = Builtins.maplist(it) do |t|
        Builtins.tointeger(Ops.get_string(t, 1, "-1"))
      end
      oll = Builtins.maplist(IscsiLioData.GetLunList(@curr_target, @curr_tpg)) do |lli|
        Ops.get_integer(lli, 0, -1)
      end
      Builtins.y2milestone("storeModify oll:%1", oll)
      Builtins.y2milestone("storeModify nll:%1", nll)
      Builtins.foreach(oll) do |l|
        if !Builtins.contains(nll, l)
          chg = true
          if !IscsiLioData.DoRemoveLun(@curr_target, @curr_tpg, l)
            txt = Builtins.sformat(_("Problem removing lun %1"), l)
            Popup.Error(txt)
          end
        end
      end
      Builtins.foreach(it) do |row|
        lun = {
          "lun"  => Builtins.tointeger(Ops.get_string(row, 1, "-1")),
          "nm"   => Ops.get_string(row, 2, ""),
          "path" => Ops.get_string(row, 3, "")
        }
        if (
            lun_ref = arg_ref(lun);
            _NeedUpdateLun_result = IscsiLioData.NeedUpdateLun(
              @curr_target,
              @curr_tpg,
              lun_ref
            );
            lun = lun_ref.value;
            _NeedUpdateLun_result
          )
          Builtins.y2milestone("storeModify lun:%1", lun)
          chg = true
          if !IscsiLioData.DoUpdateLun(@curr_target, @curr_tpg, lun)
            txt = Builtins.sformat(
              _("Problem setting lun %1 (name:%2) to path %3"),
              Ops.get_integer(lun, "lun", -1),
              Ops.get_string(lun, "nm", ""),
              Ops.get_string(lun, "path", "")
            )
            Popup.Error(txt)
          end
        end
      end
      val = Convert.to_boolean(UI.QueryWidget(:auth, :Value))
      if val != IscsiLioData.GetTpgAuth(@curr_target, @curr_tpg)
        chg = true
        if !IscsiLioData.SetTpgAuth(@curr_target, @curr_tpg, val)
          txt = Builtins.sformat(
            _("Problem setting auth on %1:%2 to %3"),
            @curr_target,
            @curr_tpg,
            val
          )
          Popup.Error(txt)
        end
      end
      if chg
        IscsiLioData.UpdateConfig
        initModify("")
      end

      nil
    end

    #	************** Add Target Dialog	******************
    # initialize function for create new target
    def initAddTarget(key)
      # some proposed values
      target = "iqn"
      date = Ops.get_string(
        Convert.convert(
          SCR.Execute(path(".target.bash_output"), "date +%Y-%m"),
          :from => "any",
          :to   => "map <string, any>"
        ),
        "stdout",
        ""
      )
      domain = Ops.get_string(
        Convert.convert(
          SCR.Execute(path(".target.bash_output"), "dnsdomainname"),
          :from => "any",
          :to   => "map <string, any>"
        ),
        "stdout",
        ""
      )
      uuid = Ops.get_string(
        Convert.convert(
          SCR.Execute(path(".target.bash_output"), "uuidgen"),
          :from => "any",
          :to   => "map <string, any>"
        ),
        "stdout",
        ""
      )
      uuid = Builtins.deletechars(uuid, "\n")
      if !Builtins.isempty(domain)
        domain = Ops.get(Builtins.splitstring(domain, "\n"), 0, "")
        tmp_list = Builtins.splitstring(domain, ".")
        domain = Builtins.sformat(
          "%1.%2",
          Ops.get(tmp_list, 1, ""),
          Ops.get(tmp_list, 0, "")
        )
      else
        domain = "com.example"
      end
      target = Builtins.deletechars(
        Builtins.sformat("%1.%2.%3", target, date, domain),
        "\n"
      )
      Builtins.y2milestone("init values for add_target %1", target)
      UI.ChangeWidget(Id(:target), :Value, target)
      UI.ChangeWidget(Id(:identifier), :Value, uuid)
      UI.ChangeWidget(Id(:tpg), :ValidChars, String.CDigit)
      UI.ChangeWidget(Id(:tpg), :Value, "1")
      ip = Convert.convert(
        UI.QueryWidget(Id(:ipaddr), :Items),
        :from => "any",
        :to   => "list <term>"
      )
      Builtins.y2milestone("Items: %1", ip)
      s = Ops.get_string(ip, [0, 1], "")
      Builtins.y2milestone("initAddTarget ip:%1", s)
      UI.ChangeWidget(Id(:ipaddr), :Value, s)
      UI.ChangeWidget(Id(:port), :ValidChars, String.CDigit)
      UI.ChangeWidget(Id(:port), :Value, "3260")
      UI.ChangeWidget(Id(:auth), :Value, true)

      nil
    end

    def uiTarget
      tpg = nil
      tpg = Builtins.tointeger(UI.QueryWidget(Id(:tpg), :Value))
      [
        Convert.to_string(UI.QueryWidget(Id(:target), :Value)),
        Convert.to_string(UI.QueryWidget(Id(:identifier), :Value)),
        tpg
      ]
    end

    def storeAddTarget(option_id, option_map)
      option_map = deep_copy(option_map)
      target = uiTarget
      Builtins.y2milestone("storeAddTarget %1", target)
      @curr_target = Builtins.sformat(
        "%1:%2",
        Ops.get_string(target, 0, ""),
        Ops.get_string(target, 1, "")
      )
      @curr_tpg = Ops.get_integer(target, 2, -1)
      storeModify(option_id, option_map)

      nil
    end


    # validate function checks if target/tpg are unique and not empty
    def validateAddTarget(key, event)
      event = deep_copy(event)
      target = uiTarget
      Builtins.y2milestone("validateAddTarget %1", target)
      ret = true
      if Builtins.isempty(Ops.get_string(target, 0, ""))
        Popup.Error(_("The target cannot be empty."))
        UI.SetFocus(Id(:target))
        ret = false
      elsif Ops.get(target, 2) == nil
        Popup.Error(_("The target portal group cannot be empty."))
        UI.SetFocus(Id(:tpg))
        ret = false
      elsif IscsiLioData.HasTarget(
          Builtins.sformat(
            "%1:%2",
            Ops.get_string(target, 0, ""),
            Ops.get_string(target, 1, "")
          ),
          Ops.get_integer(target, 2, -1)
        )
        Popup.Error(_("The target already exists."))
        UI.SetFocus(Id(:target))
        ret = false
      end
      ret
    end

    def GetLunList(lmap)
      lmap = deep_copy(lmap)
      s = ""
      Builtins.foreach(lmap) do |l1, l2|
        s = Ops.add(s, "-") if !Builtins.isempty(s)
        s = Ops.add(s, Builtins.sformat("%1:%2", l1, l2))
      end
      s
    end

    def GetAuthString(am)
      am = deep_copy(am)
      ret = ""
      ret = _("Incoming") if !Builtins.isempty(Ops.get_list(am, "incoming", []))
      if !Builtins.isempty(Ops.get_list(am, "outgoing", []))
        ret = Ops.add(ret, "/") if !Builtins.isempty(ret)
        ret = Ops.add(ret, _("Outgoing"))
      end
      ret = _("None") if Builtins.isempty(ret)
      ret
    end

    def initClient(key)
      Builtins.y2milestone("initClient %1 %2", @curr_target, @curr_tpg)
      UI.ChangeWidget(
        Id(:target),
        :Value,
        Ops.get(Builtins.splitstring(@curr_target, ":"), 0, "")
      )
      UI.ChangeWidget(Id(:target), :Enabled, false)
      UI.ChangeWidget(
        Id(:identifier),
        :Value,
        Ops.get(Builtins.splitstring(@curr_target, ":"), 1, "")
      )
      UI.ChangeWidget(Id(:identifier), :Enabled, false)
      UI.ChangeWidget(Id(:tpg), :Value, Builtins.tostring(@curr_tpg))
      UI.ChangeWidget(Id(:tpg), :Enabled, false)
      clnt = IscsiLioData.GetClntList(@curr_target, @curr_tpg)
      Builtins.y2milestone("initClient clnt:%1", clnt)
      inc_items = []
      auth = _("Disabled")
      tgt_auth = IscsiLioData.GetTpgAuth(@curr_target, @curr_tpg)
      Builtins.foreach(clnt) do |s|
        if tgt_auth
          m = IscsiLioData.GetAuth(@curr_target, @curr_tpg, s)
          auth = GetAuthString(m)
        end
        luns = GetLunList(IscsiLioData.GetClntLun(@curr_target, @curr_tpg, s))
        inc_items = Builtins.add(
          inc_items,
          Item(Id(Builtins.size(inc_items)), s, luns, auth)
        )
      end
      UI.ChangeWidget(Id(:clnt_table), :Items, inc_items)

      nil
    end

    def handleClient(key, event)
      event = deep_copy(event)
      if Ops.get_string(event, "EventReason", "") == "Activated"
        case Ops.get_symbol(event, "WidgetID")
          when :delete
            del = Convert.to_integer(
              UI.QueryWidget(Id(:clnt_table), :CurrentItem)
            )
            if del != nil
              if Popup.ContinueCancel(_("Really delete the selected item?"))
                Builtins.y2milestone(
                  "handleClient Delete Client %1 from table",
                  del
                )
                it = Convert.convert(
                  UI.QueryWidget(:clnt_table, :Items),
                  :from => "any",
                  :to   => "list <term>"
                )
                clnt = Ops.get_string(GetById(it, del), 1, "")
                if !Builtins.contains(@del_clnt, clnt)
                  @del_clnt = Builtins.add(@del_clnt, clnt)
                end
                Builtins.y2milestone("handleClient del_clnt:%1", @del_clnt)
                if Builtins.haskey(@changed_lun, clnt)
                  @changed_lun = Builtins.remove(@changed_lun, clnt)
                end
                if Builtins.haskey(@changed_auth, clnt)
                  @changed_auth = Builtins.remove(@changed_auth, clnt)
                end
                it = RemoveById(it, del)
                UI.ChangeWidget(Id(:clnt_table), :Items, it)
              else
                Builtins.y2milestone("handleClient: Delete canceled")
              end
            end
          when :edit_lun
            edit_pos = Builtins.tointeger(
              UI.QueryWidget(:clnt_table, :CurrentItem)
            )
            items = Convert.convert(
              UI.QueryWidget(:clnt_table, :Items),
              :from => "any",
              :to   => "list <term>"
            )
            it = Ops.get(items, edit_pos, Empty())
            s = Ops.get_string(it, 1, "")
            Builtins.y2milestone("handleClient pos:%1 clnt:%2", edit_pos, s)
            lm = LUNMapDialog(s)
            Builtins.y2milestone("handleClient lun_map:%1", lm)
            if lm != nil
              Ops.set(it, 2, GetLunList(lm))
              Ops.set(items, edit_pos, it)
              UI.ChangeWidget(:clnt_table, :Items, items)
              UI.ChangeWidget(:clnt_table, :CurrentItem, edit_pos)
            end
          when :edit_auth
            edit_pos = Builtins.tointeger(
              UI.QueryWidget(:clnt_table, :CurrentItem)
            )
            items = Convert.convert(
              UI.QueryWidget(:clnt_table, :Items),
              :from => "any",
              :to   => "list <term>"
            )
            it = Ops.get(items, edit_pos, Empty())
            s = Ops.get_string(it, 1, "")
            Builtins.y2milestone("handleClient pos:%1 clnt:%2", edit_pos, s)
            auth = ClntAuthDialog(s)
            Builtins.y2milestone("handleClient auth:%1", auth)
            if auth != nil
              Ops.set(it, 3, GetAuthString(auth))
              Ops.set(items, edit_pos, it)
              UI.ChangeWidget(:clnt_table, :Items, items)
              UI.ChangeWidget(:clnt_table, :CurrentItem, edit_pos)
            end
          when :add
            ret = AddClntDialog()
            if !Builtins.isempty(ret) &&
                !Builtins.isempty(Ops.get_string(ret, "clnt", ""))
              items = Convert.convert(
                UI.QueryWidget(:clnt_table, :Items),
                :from => "any",
                :to   => "list <term>"
              )
              auth = _("Disabled")
              c = Ops.get_string(ret, "clnt", "")
              if IscsiLioData.GetTpgAuth(@curr_target, @curr_tpg)
                auth = GetAuthString({})
                Ops.set(@changed_auth, c, {})
              end
              lmap = {}
              if Ops.get_boolean(ret, "import", false)
                lmap = Builtins.mapmap(
                  IscsiLioData.GetLun(@curr_target, @curr_tpg)
                ) { |l, m| { l => l } }
              end
              Builtins.y2milestone("handleClient clnt:%1 lmap:%2", c, lmap)
              Ops.set(@changed_lun, c, lmap)
              it = Item(Id(Builtins.size(items)), c, GetLunList(lmap), auth)
              items = Builtins.add(items, it)
              UI.ChangeWidget(:clnt_table, :Items, items)
              UI.ChangeWidget(
                :clnt_table,
                :CurrentItem,
                Ops.subtract(Builtins.size(items), 1)
              )
            end
          when :copy
            edit_pos = Builtins.tointeger(
              UI.QueryWidget(:clnt_table, :CurrentItem)
            )
            items = Convert.convert(
              UI.QueryWidget(:clnt_table, :Items),
              :from => "any",
              :to   => "list <term>"
            )
            it = Ops.get(items, edit_pos, Empty())
            s = Ops.get_string(it, 1, "")
            Builtins.y2milestone("handleClient pos:%1 clnt:%2", edit_pos, s)
            c = CopyClntDialog()
            if !Builtins.isempty(c)
              auth = _("Disabled")
              if IscsiLioData.GetTpgAuth(@curr_target, @curr_tpg)
                m = {}
                if Builtins.haskey(@changed_auth, s)
                  m = Ops.get(@changed_auth, s, {})
                else
                  m = IscsiLioData.GetAuth(@curr_target, @curr_tpg, s)
                end
                auth = GetAuthString(m)
                Ops.set(@changed_auth, c, m)
              end
              lmap = {}
              if Builtins.haskey(@changed_lun, s)
                lmap = Ops.get(@changed_lun, s, {})
              else
                lmap = IscsiLioData.GetClntLun(@curr_target, @curr_tpg, s)
              end
              Ops.set(@changed_lun, c, lmap)
              Builtins.y2milestone("handleClient clnt:%1", c)
              it2 = Item(Id(Builtins.size(items)), c, GetLunList(lmap), auth)
              items = Builtins.add(items, it2)
              UI.ChangeWidget(:clnt_table, :Items, items)
              UI.ChangeWidget(
                :clnt_table,
                :CurrentItem,
                Ops.subtract(Builtins.size(items), 1)
              )
            end
        end
      end
      enab = !Builtins.isempty(
        Convert.to_list(UI.QueryWidget(:clnt_table, :Items))
      )
      UI.ChangeWidget(:edit_lun, :Enabled, enab)
      UI.ChangeWidget(:delete, :Enabled, enab)
      UI.ChangeWidget(:copy, :Enabled, enab)
      enab = enab && IscsiLioData.GetTpgAuth(@curr_target, @curr_tpg)
      UI.ChangeWidget(:edit_auth, :Enabled, enab)

      nil
    end

    def validateClient(key, event)
      event = deep_copy(event)
      ret = true
      ret
    end

    def removeClntLun(tgt, tpg, clnt, lun)
      ret = IscsiLioData.DoRemoveClntLun(tgt, tpg, clnt, lun)
      if !ret
        txt = Builtins.sformat(
          _("Problem removing lun %4 for client %3 in %1:%2"),
          tgt,
          tpg,
          clnt,
          lun
        )
        Popup.Error(txt)
      end
      ret
    end

    def createClntLun(tgt, tpg, clnt, lun, tlun)
      ret = IscsiLioData.DoCreateClntLun(tgt, tpg, clnt, lun, tlun)
      if !ret
        txt = Builtins.sformat(
          _("Problem adding lun %4:%5 for client %3 in %1:%2"),
          tgt,
          tpg,
          clnt,
          lun,
          tlun
        )
        Popup.Error(txt)
      end
      ret
    end

    def storeClient(option_id, option_map)
      option_map = deep_copy(option_map)
      chg = false
      cl = IscsiLioData.GetClntList(@curr_target, @curr_tpg)
      Builtins.foreach(@del_clnt) do |c|
        if Builtins.contains(cl, c)
          chg = true
          if !IscsiLioData.DoRemoveClnt(@curr_target, @curr_tpg, c)
            txt = Builtins.sformat(
              _("Problem removing client %3 from %1:%2"),
              @curr_target,
              @curr_tpg,
              c
            )
            Popup.Error(txt)
          end
        end
      end
      @del_clnt = []
      new_clnt = Builtins.maplist(@changed_auth) { |c, m| c }
      new_clnt = Convert.convert(
        Builtins.union(new_clnt, Builtins.maplist(@changed_lun) { |c, m| c }),
        :from => "list",
        :to   => "list <string>"
      )
      new_clnt = Builtins.filter(new_clnt) { |c| !Builtins.contains(cl, c) }
      if !Builtins.isempty(new_clnt)
        Builtins.y2milestone("storeClient new clnt:%1", new_clnt)
      end
      Builtins.foreach(new_clnt) do |c|
        chg = true
        if !IscsiLioData.DoCreateClnt(@curr_target, @curr_tpg, c)
          txt = Builtins.sformat(
            _("Problem creating client %3 for %1:%2"),
            @curr_target,
            @curr_tpg,
            c
          )
          Popup.Error(txt)
        else
          cl = Builtins.add(cl, c)
        end
      end
      Builtins.foreach(@changed_auth) do |c, m|
        if Builtins.contains(cl, c)
          ca = IscsiLioData.GetAuth(@curr_target, @curr_tpg, c)
          if Builtins.isempty(Ops.get_list(m, "incoming", [])) !=
              Builtins.isempty(Ops.get_list(ca, "incoming", [])) ||
              Builtins.isempty(Ops.get_list(m, "outgoing", [])) !=
                Builtins.isempty(Ops.get_list(ca, "outgoing", [])) ||
              Ops.get_string(m, ["incoming", 0], "") !=
                Ops.get_string(ca, ["incoming", 0], "") ||
              Ops.get_string(m, ["incoming", 1], "") !=
                Ops.get_string(ca, ["incoming", 1], "") ||
              Ops.get_string(m, ["outgoing", 0], "") !=
                Ops.get_string(ca, ["outgoing", 0], "") ||
              Ops.get_string(m, ["outgoing", 1], "") !=
                Ops.get_string(ca, ["outgoing", 1], "")
            Builtins.y2milestone("storeClient auth c:%1", c)
            Builtins.y2milestone("storeClient cur:%1 new:%2", ca, m)
            chg = true
            if !IscsiLioData.SetAuth(
                @curr_target,
                @curr_tpg,
                c,
                Ops.get_list(m, "incoming", []),
                Ops.get_list(m, "outgoing", [])
              )
              txt = Builtins.sformat(
                _("Problem changing auth for client %3 in %1:%2"),
                @curr_target,
                @curr_tpg,
                c
              )
              Popup.Error(txt)
            end
          end
        end
      end
      @changed_auth = {}
      Builtins.foreach(@changed_lun) do |c, m|
        if Builtins.contains(cl, c)
          cl2 = IscsiLioData.GetClntLun(@curr_target, @curr_tpg, c)
          Builtins.foreach(cl2) do |l, ol|
            if !Builtins.haskey(m, l) &&
                removeClntLun(@curr_target, @curr_tpg, c, l)
              chg = true
            end
          end
          Builtins.foreach(m) do |l, ol|
            if !Builtins.haskey(cl2, l)
              chg = true if createClntLun(@curr_target, @curr_tpg, c, l, ol)
            elsif Ops.get(cl2, l, -1) != ol
              chg = true if removeClntLun(@curr_target, @curr_tpg, c, l)
              chg = true if createClntLun(@curr_target, @curr_tpg, c, l, ol)
            end
          end
        end
      end
      @changed_lun = {}
      Builtins.y2milestone("storeClient chg:%1", chg)
      IscsiLioData.UpdateConfig if chg

      nil
    end
  end
end
