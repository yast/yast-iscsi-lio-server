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
# File:	modules/IscsiLioData.ycp
# Package:	Configuration Data of iscsi-lio-server
# Summary:	IscsiLioServer data manipulation functions
# Authors:	Thomas Fehr <fehr@suse.cz>
#
# $Id$
#
# Representation of the configuration of iscsi-lio-server.
require "yast"

module Yast
  class IscsiLioDataClass < Module
    def main

      textdomain "iscsi-lio-server"

      @data = {}
    end

    def SplitStringNE(str, delim)
      Builtins.filter(Builtins.splitstring(str, delim)) do |s|
        !Builtins.isempty(s)
      end
    end

    def GetIpAndPort(np)
      return [] if !np || np.empty?

      if !np.start_with?("[")
        ret = Builtins.splitstring(np, ":")
      elsif match_data = np.match(/\[([:\w]+)\]:(\d+)/)
        ret = [match_data[1] || "", match_data[2] || ""]
      else
        ret = []
      end
      ret
    end

    def MyFind(s, pat)
      ret = Builtins.search(s, pat)
      ret = -1 if ret == nil
      ret
    end

    def GetTgt(data, tgt, tpg)
      data = deep_copy(data)
      m = Ops.get_map(data, ["tgt", tgt, tpg], {})
      m = deep_copy(data) if Builtins.isempty(tgt)
      deep_copy(m)
    end

    def SetTgt(data, tgt, tpg, m)
      m = deep_copy(m)
      if Builtins.isempty(tgt)
        data.value = deep_copy(m)
      else
        Ops.set(data.value, ["tgt", tgt], { tpg => m })
      end

      nil
    end

    def FindTcmKey(p)
      ret = Ops.get(
        Builtins.maplist(Builtins.filter(Ops.get_map(@data, "tcm", {})) do |k, m|
          Ops.get_string(m, "path", "") == p
        end) { |key, du| key },
        0,
        ""
      )
      Builtins.y2milestone("FindTcmKey p:%1 ret:%2", p, ret)
      ret
    end

    def ReplaceSlashUs(i)
      ret = ""
      count = 0
      Builtins.foreach(SplitStringNE(i, "/")) do |s|
        ret = Ops.add(ret, "_") if Ops.greater_than(count, 0)
        ret = Ops.add(ret, s)
        count = Ops.add(count, 1)
      end
      ret
    end

    def CreateLunName(used, p)
      used = deep_copy(used)
      ret = ReplaceSlashUs(p)
      base = ret
      count = 0
      while !Builtins.isempty(Builtins.filter(used) { |s| s == ret })
        count = Ops.add(count, 1)
        ret = Ops.add(Ops.add(base, "_"), count)
      end
      Builtins.y2milestone("CreateLunName p:%1 ret:%2", p, ret)
      ret
    end

    def CreateTcmKey(tcm, base, p)
      tcm = deep_copy(tcm)
      ret = Ops.add(base, ReplaceSlashUs(p))
      base = ret
      count = 0
      while Builtins.haskey(tcm, ret)
        count = Ops.add(count, 1)
        ret = Ops.add(Ops.add(base, "_"), count)
      end
      Builtins.y2milestone("CreateTcmKey base:%1 p:%2 ret:%3", base, p, ret)
      ret
    end

    def AddLun(tgt, val)
      tgt = deep_copy(tgt)
      Ops.set(tgt, "ep", { "lun" => {} }) if !Builtins.haskey(tgt, "ep")
      sl = SplitStringNE(val, " \t")
      Builtins.y2milestone("AddLun sl:%1", sl)
      if !Builtins.isempty(Ops.get(sl, 0, "")) &&
          !Builtins.isempty(Ops.get(sl, 1, ""))
        l = Builtins.tointeger(Ops.get(sl, 0, ""))
        if l != nil && !Builtins.haskey(Ops.get_map(tgt, ["ep", "lun"], {}), l)
          Ops.set(tgt, ["ep", "lun", l], {})
        end
        if Builtins.haskey(Ops.get_map(tgt, ["ep", "lun"], {}), l)
          tmps = SplitStringNE(Ops.get(sl, 1, ""), ",")
          sl = []
          Builtins.foreach(tmps) do |s|
            sl = Convert.convert(
              Builtins.merge(sl, Builtins.splitstring(s, "=")),
              :from => "list",
              :to   => "list <string>"
            )
          end
          Builtins.y2milestone("AddLun sl:%1", sl)
          while !Builtins.isempty(sl)
            if Ops.get(sl, 0, "") == "Path" &&
                Ops.greater_than(Builtins.size(sl), 1)
              tk = FindTcmKey(Ops.get(sl, 1, ""))
              if !Builtins.isempty(tk)
                Ops.set(tgt, ["ep", "lun", l, "tcm_key"], tk)
              else
                Ops.set(tgt, ["ep", "lun", l, "path"], Ops.get(sl, 1, ""))
              end
              used = Builtins.maplist(Ops.get_map(tgt, ["ep", "lun"], {})) do |i, m|
                Ops.get_string(m, "nm", "")
              end
              Builtins.y2milestone("AddLun used:%1", used)
              Ops.set(
                tgt,
                ["ep", "lun", l, "nm"],
                CreateLunName(used, Ops.get(sl, 1, ""))
              )
              sl = Builtins.remove(sl, 0)
            end
            sl = Builtins.remove(sl, 0)
          end
        end
        if Builtins.isempty(Ops.get_string(tgt, ["ep", "lun", l, "path"], "")) &&
            Builtins.isempty(
              Ops.get_string(tgt, ["ep", "lun", l, "tcm_key"], "")
            )
          Ops.set(
            tgt,
            ["ep", "lun"],
            Builtins.remove(Ops.get_map(tgt, ["ep", "lun"], {}), l)
          )
        end
      end
      deep_copy(tgt)
    end

    def AddIncoming(tgt, val)
      tgt = deep_copy(tgt)
      sl = SplitStringNE(val, " \t")
      if !Builtins.isempty(Ops.get(sl, 0, "")) &&
          !Builtins.isempty(Ops.get(sl, 1, ""))
        Ops.set(
          tgt,
          "incoming",
          Builtins.add(
            Ops.get_list(tgt, "incoming", []),
            [Ops.get(sl, 0, ""), Ops.get(sl, 1, "")]
          )
        )
      end
      deep_copy(tgt)
    end

    def AddOutgoing(tgt, val)
      tgt = deep_copy(tgt)
      sl = SplitStringNE(val, " \t")
      if !Builtins.isempty(Ops.get(sl, 0, "")) &&
          !Builtins.isempty(Ops.get(sl, 1, ""))
        Ops.set(tgt, "outgoing", [Ops.get(sl, 0, ""), Ops.get(sl, 1, "")])
      end
      deep_copy(tgt)
    end

    def ParseConfigIetd(rv)
      rv = deep_copy(rv)
      data = {}
      target = ""
      tpg = 1
      Builtins.foreach(Ops.get_list(rv, "value", [])) do |v|
        name = Builtins.toupper(Ops.get_string(v, "name", ""))
        val = Ops.get_string(v, "value", "")
        if Builtins.contains(["ISNSSERVER", "ISNSACCESSCONTROL"], name)
          Ops.set(data, name, val)
        elsif name == "TARGET"
          Ops.set(data, "tgt", {}) if !Builtins.haskey(data, "tgt")
          if !Builtins.haskey(Ops.get_map(data, "tgt", {}), val)
            Ops.set(data, ["tgt", val], { tpg => {} })
          end
          target = val
        elsif name == "LUN" && !Builtins.isempty(target)
          Ops.set(
            data,
            ["tgt", target, tpg],
            AddLun(Ops.get_map(data, ["tgt", target, tpg], {}), val)
          )
        elsif name == "INCOMINGUSER"
          m = GetTgt(data, target, tpg)
          m = AddIncoming(m, val)
          data_ref = arg_ref(data)
          SetTgt(data_ref, target, tpg, m)
          data = data_ref.value
        elsif name == "OUTGOINGUSER"
          m = GetTgt(data, target, tpg)
          m = AddOutgoing(m, val)
          data_ref = arg_ref(data)
          SetTgt(data_ref, target, tpg, m)
          data = data_ref.value
        end
      end
      deep_copy(data)
    end

    def IsTpgActive(tgt, tpg)
      Ops.get_boolean(@data, ["tgt", tgt, tpg, "ep", "enabled"], false)
    end

    def LogExecCmd(cmd)
      Builtins.y2milestone("Executing cmd:%1", cmd)
      ret = Convert.convert(
        SCR.Execute(path(".target.bash_output"), cmd),
        :from => "any",
        :to   => "map <string, any>"
      )
      if Ops.get_integer(ret, "exit", -1) != 0
        Builtins.y2error("Error ret:%1", ret)
      else
        Builtins.y2milestone("Ret:%1", ret)
      end
      Ops.get_integer(ret, "exit", -1) == 0
    end

    def AddNewTarget(name, tpg, lun)
      lun = deep_copy(lun)
      Builtins.y2milestone("AddNewTarget name:%1 tpg:%2", name, tpg)
      Ops.set(@data, "tgt", {}) if !Builtins.haskey(@data, "tgt")
      Ops.set(@data, ["tgt", name], { tpg => {} })
      Builtins.foreach(lun) do |s|
        Ops.set(
          @data,
          ["tgt", name, tpg],
          AddLun(Ops.get_map(@data, ["tgt", name, tpg], {}), s)
        )
      end

      nil
    end

    def SetIetdAuth(tgt, tpg, incom, outgo)
      incom = deep_copy(incom)
      m = GetTgt(@data, tgt, tpg)
      Builtins.foreach(incom) { |s| m = AddIncoming(m, s) }
      m = AddOutgoing(m, outgo) if !Builtins.isempty(outgo)
      data_ref = arg_ref(@data)
      SetTgt(data_ref, tgt, tpg, m)
      @data = data_ref.value

      nil
    end

    def HasTarget(tgt, tpg)
      Builtins.haskey(Ops.get_map(@data, "tgt", {}), tgt) &&
        Builtins.haskey(Ops.get_map(@data, ["tgt", tgt], {}), tpg)
    end

    def HasIncomingAuth(tgt, tpg, clnt)
      m = GetTgt(@data, tgt, tpg)
      m = Ops.get_map(m, ["clnt", clnt], {}) if !Builtins.isempty(clnt)
      ret = !Builtins.isempty(Ops.get_list(m, "incoming", []))
      Builtins.y2milestone(
        "HasIncomingAuth m:%1 ret:%2",
        Ops.get_list(m, "incoming", []),
        ret
      )
      ret
    end

    def HasOutgoingAuth(tgt, tpg, clnt)
      m = GetTgt(@data, tgt, tpg)
      m = Ops.get_map(m, ["clnt", clnt], {}) if !Builtins.isempty(clnt)
      ret = Ops.greater_than(Builtins.size(Ops.get_list(m, "outgoing", [])), 1)
      Builtins.y2milestone(
        "HasOutgoingAuth m:%1 ret:%2",
        Ops.get_list(m, "outgoing", []),
        ret
      )
      ret
    end

    def HasAuth(tgt, tpg, clnt)
      HasIncomingAuth(tgt, tpg, clnt) || HasOutgoingAuth(tgt, tpg, clnt)
    end

    def GetAuth(tgt, tpg, clnt)
      m = GetTgt(@data, tgt, tpg)
      m = Ops.get_map(m, ["clnt", clnt], {}) if !Builtins.isempty(tgt)
      {
        "incoming" => Ops.get_list(m, ["incoming", 0], []),
        "outgoing" => Ops.get_list(m, "outgoing", [])
      }
    end


    def GetLun(tgt, tpg)
      ret = Ops.get_map(@data, ["tgt", tgt, tpg, "ep", "lun"], {})
      deep_copy(ret)
    end

    def GetLunList(tgt, tpg)
      ret = Builtins.maplist(
        Ops.get_map(@data, ["tgt", tgt, tpg, "ep", "lun"], {})
      ) do |l, m|
        [
          l,
          Ops.get_string(m, "nm", ""),
          Ops.get_string(
            @data,
            ["tcm", Ops.get_string(m, "tcm_key", ""), "path"],
            ""
          )
        ]
      end
      deep_copy(ret)
    end

    # format ip and port information for use in commands
    def FormatIpPort(ip, port)
      # brackets needed around IPv6
      ip = "[#{ip}]" if IP.Check6(ip)
      return "#{ip}:#{port}"
    end

    def GetNetworkPortal(tgt, tpg)
      Builtins.y2milestone("Data: %1, tgt: %2, tpg: %3", @data, tgt, tpg)
      ret = Builtins.maplist(
        Ops.get_list(@data, ["tgt", tgt, tpg, "ep", "np"], [])
      ) do |n|
        ip = n["ip"] || ""
        port = n["port"] || 3260
        ipp = FormatIpPort(ip, port)
      end
      deep_copy(ret)
    end

    def GetTpgAuth(tgt, tpg)
      ret = Ops.get_boolean(@data, ["tgt", tgt, tpg, "auth"], true)
      ret
    end

    def GetClntList(tgt, tpg)
      ret = Builtins.maplist(Ops.get_map(@data, ["tgt", tgt, tpg, "clnt"], {})) do |s, m|
        s
      end
      deep_copy(ret)
    end

    def GetClntLun(tgt, tpg, clnt)
      ret = Ops.get_map(@data, ["tgt", tgt, tpg, "clnt", clnt, "lun"], {})
      deep_copy(ret)
    end

    def SetNetworkPortal(tgt, tpg, np, new_port, add_all)
      Builtins.y2milestone("SetNetworkPortal tgt:%1 tpg:%2 np:%3", tgt, tpg, np)

      target_info = "#{tgt} #{tpg}"
      ip_list = Ops.get_list(@data, ["tgt", tgt, tpg, "ep", "np"], [])

      if !ip_list.empty? && !add_all
        ip_list.each do |ipp|
          ip = ipp["ip"]
          port = ipp["port"] || 3260
          LogExecCmd("lio_node --delnp #{target_info} #{FormatIpPort(ip, port)}") if !ip.nil?
        end
      end

      if add_all
        ret = true
        IscsiLioData.GetIpAddr.each do |ip|
          success = LogExecCmd("lio_node --addnp #{target_info} #{FormatIpPort(ip, new_port)}")
          ret = false if !success 
        end
      else
        ret = LogExecCmd("lio_node --addnp #{target_info} #{np}")
      end
      ret
    end

    def GetTargets
      ret = []
      Builtins.foreach(Ops.get_map(@data, "tgt", {})) do |key, m|
        Builtins.foreach(m) do |tpg, dummy|
          ret = Builtins.add(ret, [key, tpg])
          Builtins.y2milestone("GetTargets key:%1 tpg:%2", key, tpg)
          Builtins.y2milestone("GetTargets ret:%1", ret)
        end
      end
      Builtins.y2milestone("GetTargets ret:%1", ret)
      deep_copy(ret)
    end

    def GetExportLun(l, m)
      m = deep_copy(m)
      p = Ops.get_string(m, "path", "")
      if Builtins.isempty(p)
        p = Ops.get_string(
          @data,
          ["tcm", Ops.get_string(m, "tcm_key", ""), "path"],
          ""
        )
      end
      ret = Ops.add(
        Ops.add(Ops.add(Builtins.tostring(l), " Path="), p),
        ",Type=fileio"
      )
      ret
    end

    def GetExportAuth(tgt, tpg)
      ret = []
      m = GetTgt(@data, tgt, tpg)
      Builtins.foreach(Ops.get_list(m, "incoming", [])) do |s|
        ret = Builtins.add(
          ret,
          {
            "KEY"   => "IncomingUser",
            "VALUE" => Ops.add(
              Ops.add(Ops.get_string(s, 0, ""), " "),
              Ops.get_string(s, 1, "")
            )
          }
        )
      end
      if Ops.greater_than(Builtins.size(Ops.get_list(m, "outgoing", [])), 1)
        ret = Builtins.add(
          ret,
          {
            "KEY"   => "OutgoingUser",
            "VALUE" => Ops.add(
              Ops.add(Ops.get_string(m, ["outgoing", 0], ""), " "),
              Ops.get_string(m, ["outgoing", 1], "")
            )
          }
        )
      end
      deep_copy(ret)
    end

    def GetExportTargets
      ret = {}
      Builtins.foreach(GetTargets()) do |s|
        tgt = [
          { "KEY" => "Target", "VALUE" => Ops.get_string(s, 0, "") },
          {
            "KEY"   => "Tpg",
            "VALUE" => Builtins.tostring(Ops.get_integer(s, 1, 1))
          }
        ]
        Builtins.foreach(
          Ops.get_map(
            @data,
            [
              "tgt",
              Ops.get_string(s, 0, ""),
              Ops.get_integer(s, 1, 1),
              "ep",
              "lun"
            ],
            {}
          )
        ) do |i, m|
          tgt = Builtins.add(
            tgt,
            { "KEY" => "Lun", "VALUE" => GetExportLun(i, m) }
          )
        end
        tgt = Builtins.union(
          tgt,
          GetExportAuth(Ops.get_string(s, 0, ""), Ops.get_integer(s, 1, 1))
        )
        Ops.set(ret, Ops.get_string(s, 0, ""), tgt)
      end
      deep_copy(ret)
    end

    def GetData
      deep_copy(@data)
    end

    def SetData(dat)
      dat = deep_copy(dat)
      @data = deep_copy(dat)

      nil
    end

    def ClearData
      @data = {}

      nil
    end

    def GetChanges
      {}
    end

    def GetConfig
      {}
    end

    #
    # Get information about network interfaces from 'ifconfig'
    #
    def GetNetConfig
      out = Convert.to_map(
        SCR.Execute(path(".target.bash_output"), "LC_ALL=POSIX /sbin/ifconfig")
      )
      ls = out.fetch("stdout", "").split("\n")
      deep_copy(ls)
    end

    #
    # Get list of IP addresses
    #
    def GetIpAddr
      ip_list = GetNetConfig()
      ip_list.select! do |line|
        line.include?("inet") && !line.include?("Scope:Link")
      end

      ip_list = ip_list.map do |ip|
        ip.lstrip!
        case ip
        when /^inet addr: *([.\w]+)[\t ].*/
          $1
        when /^inet6 addr: *([:\w]+)\/.*/
          $1
        else
          ip
        end
      end

      ip_list.reject! do |address|
        address.start_with?("127.") ||  # local IPv4
          address.start_with?("::1") # local IPv6
      end

      ip_list = [""] if ip_list.empty?
      Builtins.y2milestone("GetIpAddr: %1", ip_list)
      deep_copy(ip_list)
    end

    def GetConnected
      cmd = "find /sys/kernel/config/target/iscsi -name info"
      ret = Convert.convert(
        SCR.Execute(path(".target.bash_output"), cmd),
        :from => "any",
        :to   => "map <string, any>"
      )
      ls = SplitStringNE(Ops.get_string(ret, "stdout", ""), "\n")
      Builtins.y2milestone("GetConnected ls:%1", ls)
      state = {}
      inact = "No active iSCSI Session "
      act = "InitiatorName: "
      Builtins.foreach(ls) do |f|
        cmd = Ops.add("head -1 ", f)
        ret = Convert.convert(
          SCR.Execute(path(".target.bash_output"), cmd),
          :from => "any",
          :to   => "map <string, any>"
        )
        if Ops.get_integer(ret, "exit", -1) == 0
          if Builtins.substring(
              Ops.get_string(ret, "stdout", ""),
              0,
              Builtins.size(inact)
            ) == inact
            Ops.set(state, f, false)
          elsif Builtins.substring(
              Ops.get_string(ret, "stdout", ""),
              0,
              Builtins.size(act)
            ) == act
            Ops.set(state, f, true)
          end
        end
      end
      Builtins.y2milestone("GetConnected state:%1", state)
      state = Builtins.mapmap(state) do |s, b|
        ls = Builtins.splitstring(s, "/")
        {
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(Ops.get(ls, 6, ""), " "),
                Builtins.substring(Ops.get(ls, 7, ""), 5)
              ),
              " "
            ),
            Ops.get(ls, 9, "")
          ) => b
        }
      end
      Builtins.y2milestone("GetConnected state:%1", state)
      ls = Builtins.maplist(Builtins.filter(state) { |s, b| b }) { |s, b| s }
      Builtins.y2milestone("GetConnected ret:%1", ls)
      deep_copy(ls)
    end


    def ParseAuthData(tgt, tpg, clnt, chap, mutual)
      Builtins.y2milestone(
        "ParseAuthData tgt:%1 tpg:%2 clnt:%3",
        tgt,
        tpg,
        clnt
      )
      cmd = ""
      if !Builtins.isempty(tgt)
        cmd = Ops.add(
          Ops.add(
            Ops.add(Ops.add(Ops.add("lio_node --showchapauth ", tgt), " "), tpg),
            " "
          ),
          clnt
        )
      else
        cmd = "lio_node --showchapdiscauth"
      end
      cmd = Ops.add("LC_ALL=POSIX ", cmd)
      out = Convert.to_map(SCR.Execute(path(".target.bash_output"), cmd))
      ls = SplitStringNE(Ops.get_string(out, "stdout", ""), "\n")
      i = 0
      while Ops.less_than(i, Builtins.size(ls))
        if Builtins.search(Ops.get(ls, i, ""), "password_mutual:") != nil
          Ops.set(
            mutual.value,
            1,
            Ops.get(SplitStringNE(Ops.get(ls, i, ""), " "), 1, "")
          )
        end
        if Builtins.search(Ops.get(ls, i, ""), "userid_mutual:") != nil
          Ops.set(
            mutual.value,
            0,
            Ops.get(SplitStringNE(Ops.get(ls, i, ""), " "), 1, "")
          )
        end
        if Builtins.search(Ops.get(ls, i, ""), "password:") != nil
          Ops.set(
            chap.value,
            1,
            Ops.get(SplitStringNE(Ops.get(ls, i, ""), " "), 1, "")
          )
        end
        if Builtins.search(Ops.get(ls, i, ""), "userid:") != nil
          Ops.set(
            chap.value,
            0,
            Ops.get(SplitStringNE(Ops.get(ls, i, ""), " "), 1, "")
          )
        end
        i = Ops.add(i, 1)
      end

      nil
    end

    def ParseConfigLio
      tcm = {}
      out = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          "LC_ALL=POSIX tcm_node --listhbas"
        )
      )
      ls = SplitStringNE(Ops.get_string(out, "stdout", ""), "\n")
      i = 0
      while Ops.less_than(i, Builtins.size(ls))
        while Ops.less_than(i, Builtins.size(ls)) &&
            Builtins.search(Ops.get(ls, i, ""), "\\---") != 0
          i = Ops.add(i, 1)
        end
        hba = Ops.get(Builtins.splitstring(Ops.get(ls, i, ""), " "), 1, "")
        nm = ""
        i = Ops.add(i, 1)
        pos = MyFind(Ops.get(ls, i, ""), "\\---")
        while Ops.less_than(i, Builtins.size(ls)) && pos != 0
          if Ops.greater_than(pos, 0)
            nm = Ops.get(SplitStringNE(Ops.get(ls, i, ""), " "), 1, "")
            Builtins.y2milestone("ParseConfigLio nm=%1", nm)
          end
          if Builtins.search(Ops.get(ls, i, ""), "TCM FILEIO") != nil
            pos = Builtins.search(Ops.get(ls, i, ""), "File:")
            if pos != nil
              p = Ops.get(
                SplitStringNE(Builtins.substring(Ops.get(ls, i, ""), pos), " "),
                1,
                ""
              )
              key = Ops.add(Ops.add(hba, "/"), nm)
              if !Builtins.isempty(p)
                Ops.set(tcm, key, { "path" => p, "type" => :fileio })
              end
              Builtins.y2milestone(
                "ParseConfigLio hba[%1]:%2",
                key,
                Ops.get_map(tcm, key, {})
              )
            end
          end
          if Builtins.search(Ops.get(ls, i, ""), "iBlock device:") != nil
            pos = Builtins.search(Ops.get(ls, i, ""), "UDEV PATH:")
            if pos != nil
              p = Ops.get(
                SplitStringNE(Builtins.substring(Ops.get(ls, i, ""), pos), " "),
                2,
                ""
              )
              key = Ops.add(Ops.add(hba, "/"), nm)
              if !Builtins.isempty(p)
                Ops.set(tcm, key, { "path" => p, "type" => :iblock })
              end
              Builtins.y2milestone(
                "ParseConfigLio hba[%1]:%2",
                key,
                Ops.get_map(tcm, key, {})
              )
            end
          end
          i = Ops.add(i, 1)
          pos = MyFind(Ops.get(ls, i, ""), "\\---")
        end
      end
      endp = {}
      out = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          "LC_ALL=POSIX lio_node --listendpoints"
        )
      )
      ls = SplitStringNE(Ops.get_string(out, "stdout", ""), "\n")
      i = 0
      while Ops.less_than(i, Builtins.size(ls))
        while Ops.less_than(i, Builtins.size(ls)) &&
            Builtins.search(Ops.get(ls, i, ""), "\\---") != 0
          i = Ops.add(i, 1)
        end
        tgt = Ops.get(Builtins.splitstring(Ops.get(ls, i, ""), " "), 1, "")
        ts = ""
        Ops.set(endp, tgt, {})
        i = Ops.add(i, 1)
        pos = MyFind(Ops.get(ls, i, ""), "\\---")
        tpg = 0
        while Ops.less_than(i, Builtins.size(ls)) && pos != 0
          if Builtins.search(Ops.get(ls, i, ""), "-> tpgt") != nil
            tpg = Builtins.tointeger(
              Builtins.substring(
                Ops.get(SplitStringNE(Ops.get(ls, i, ""), " "), 1, ""),
                5
              )
            )
            if tpg != nil
              Ops.set(endp, [tgt, tpg], {})
            else
              tpg = 0
            end
            Builtins.y2milestone("ParseConfigLio tpg:%1", tpg)
          end
          if Ops.greater_than(tpg, 0) &&
              Builtins.search(Ops.get(ls, i, ""), "TPG Status:") != nil
            ts = Ops.get(SplitStringNE(Ops.get(ls, i, ""), " "), 2, "")
            Ops.set(endp, [tgt, tpg, "enabled"], ts == "ENABLED")
            Builtins.y2milestone(
              "ParseConfigLio enabled:%1",
              Ops.get_boolean(endp, [tgt, tpg, "enabled"], false)
            )
          end
          if Ops.greater_than(tpg, 0) &&
              Builtins.search(Ops.get(ls, i, ""), "TPG Network Portals:") != nil
            i = Ops.add(i, 1)
            while Ops.greater_than(MyFind(Ops.get(ls, i, ""), "-> "), 0)
              np = Ops.get(SplitStringNE(Ops.get(ls, i, ""), " "), 1, "")
              tls = GetIpAndPort(np)
              port = Builtins.tointeger(Ops.get(tls, 1, ""))
              if port != nil
                Ops.set(
                  endp,
                  [tgt, tpg, "np"],
                  Builtins.add(
                    Ops.get_list(endp, [tgt, tpg, "np"], []),
                    { "ip" => Ops.get(tls, 0, ""), "port" => port }
                  )
                )
                Builtins.y2milestone("Set ip to: %1", Ops.get(tls, 0, ""))
              end
              i = Ops.add(i, 1)
            end
            i = Ops.subtract(i, 1)
            Builtins.y2milestone(
              "ParseConfigLio np:%1",
              Ops.get_list(endp, [tgt, tpg, "np"], [])
            )
          end
          if Ops.greater_than(tpg, 0) &&
              Builtins.search(Ops.get(ls, i, ""), "-> lun") != nil
            tls = SplitStringNE(Ops.get(ls, i, ""), " ")
            ti = Builtins.tointeger(
              Builtins.substring(
                Ops.get(SplitStringNE(Ops.get(tls, 1, ""), "/"), 0, ""),
                4
              )
            )
            if ti != nil
              if !Builtins.haskey(Ops.get_map(endp, [tgt, tpg], {}), "lun")
                Ops.set(endp, [tgt, tpg, "lun"], {})
              end
              lun = {}
              Ops.set(
                lun,
                "nm",
                Ops.get(SplitStringNE(Ops.get(tls, 1, ""), "/"), 1, "")
              )
              Ops.set(
                lun,
                "tcm_key",
                Builtins.substring(Ops.get(tls, 3, ""), 12)
              )
              Ops.set(endp, [tgt, tpg, "lun", ti], lun)
              Builtins.y2milestone("ParseConfigLio lun[%1]:%2", ti, lun)
              if !Builtins.haskey(tcm, Ops.get_string(lun, "tcm_key", ""))
                Builtins.y2warning(
                  "tcm key %1 should exist",
                  Ops.get_string(lun, "tcm_key", "")
                )
              end
            end
          end
          i = Ops.add(i, 1)
          pos = MyFind(Ops.get(ls, i, ""), "\\---")
        end
      end
      ret = { "tcm" => tcm }
      tgmap = {}
      mutual = ["", ""]
      chap = ["", ""]
      chap_ref = arg_ref(chap)
      mutual_ref = arg_ref(mutual)
      ParseAuthData("", 0, "", chap_ref, mutual_ref)
      chap = chap_ref.value
      mutual = mutual_ref.value
      if !Builtins.isempty(Ops.get(mutual, 0, "")) &&
          !Builtins.isempty(Ops.get(mutual, 1, ""))
        Ops.set(ret, "outgoing", mutual)
      end
      if !Builtins.isempty(Ops.get(chap, 0, "")) &&
          !Builtins.isempty(Ops.get(chap, 1, ""))
        Ops.set(ret, "incoming", [chap])
      end
      Builtins.foreach(endp) do |tgt, m|
        Ops.set(tgmap, tgt, {})
        Builtins.foreach(
          Convert.convert(m, :from => "map", :to => "map <integer, map>")
        ) do |tpg, tp|
          Ops.set(
            tgmap,
            [tgt, tpg],
            { "ep" => Ops.get_map(endp, [tgt, tpg], {}), "clnt" => {} }
          )
          Builtins.y2milestone("ParseConfigLio tgt:%1 tpg:%2", tgt, tpg)
          cmd = Ops.add(
            Ops.add(Ops.add("LC_ALL=POSIX lio_node --listlunacls ", tgt), " "),
            tpg
          )
          out = Convert.to_map(SCR.Execute(path(".target.bash_output"), cmd))
          ls = SplitStringNE(Ops.get_string(out, "stdout", ""), "\n")
          i = 0
          nm = ""
          while Ops.less_than(i, Builtins.size(ls))
            if Builtins.search(Ops.get(ls, i, ""), "InitiatorName ACL:") != nil
              nm = Ops.get(SplitStringNE(Ops.get(ls, i, ""), " "), 3, "")
              if !Builtins.isempty(nm)
                Ops.set(tgmap, [tgt, tpg, "clnt", nm], {})
              end
              Builtins.y2milestone("ParseConfigLio nm:%1", nm)
            end
            if !Builtins.isempty(nm) &&
                Builtins.search(Ops.get(ls, i, ""), "-> lun") != nil
              tls = SplitStringNE(Ops.get(ls, i, ""), " ")
              ti = Builtins.tointeger(
                Builtins.substring(
                  Ops.get(SplitStringNE(Ops.get(tls, 1, ""), "/"), 0, ""),
                  4
                )
              )
              lun = Builtins.tointeger(
                Builtins.substring(
                  Ops.get(SplitStringNE(Ops.get(tls, 3, ""), "/"), 5, ""),
                  4
                )
              )
              if ti != nil && lun != nil
                if !Builtins.haskey(
                    Ops.get_map(tgmap, [tgt, tpg, "clnt", nm], {}),
                    "lun"
                  )
                  Ops.set(tgmap, [tgt, tpg, "clnt", nm, "lun"], {})
                end
                Ops.set(tgmap, [tgt, tpg, "clnt", nm, "lun", ti], lun)
                Builtins.y2milestone("ParseConfigLio lun[%1]:%2", ti, lun)
                if !Builtins.haskey(
                    Ops.get_map(tgmap, [tgt, tpg, "ep", "lun"], {}),
                    lun
                  )
                  Builtins.y2warning("lun %1 should exist in endpoints", lun)
                end
              end
            end
            i = Ops.add(i, 1)
          end
          Builtins.foreach(Ops.get_map(tgmap, [tgt, tpg, "clnt"], {})) do |clnt, m2|
            mutual = ["", ""]
            chap = ["", ""]
            chap_ref = arg_ref(chap)
            mutual_ref = arg_ref(mutual)
            ParseAuthData(tgt, tpg, clnt, chap_ref, mutual_ref)
            chap = chap_ref.value
            mutual = mutual_ref.value
            if !Builtins.isempty(Ops.get(mutual, 0, "")) &&
                !Builtins.isempty(Ops.get(mutual, 1, ""))
              Ops.set(tgmap, [tgt, tpg, "clnt", clnt, "outgoing"], mutual)
            end
            if !Builtins.isempty(Ops.get(chap, 0, "")) &&
                !Builtins.isempty(Ops.get(chap, 1, ""))
              Ops.set(tgmap, [tgt, tpg, "clnt", clnt, "incoming"], [chap])
            end
          end
          cmd = Ops.add(
            Ops.add(Ops.add("LC_ALL=POSIX lio_node --listtpgattr ", tgt), " "),
            tpg
          )
          out = Convert.to_map(SCR.Execute(path(".target.bash_output"), cmd))
          ls = SplitStringNE(Ops.get_string(out, "stdout", ""), "\n")
          i = 0
          while Ops.less_than(i, Builtins.size(ls))
            if Builtins.search(Ops.get(ls, i, ""), "authentication=") != nil
              val = Ops.get(SplitStringNE(Ops.get(ls, i, ""), "="), 1, "")
              Ops.set(tgmap, [tgt, tpg, "auth"], val == "1")
            end
            i = Ops.add(i, 1)
          end
        end
      end
      cl = GetConnected()
      Builtins.foreach(cl) do |s|
        ls2 = SplitStringNE(s, " ")
        Ops.set(ls2, 1, Builtins.tointeger(Ops.get_string(ls2, 1, "-1")))
        Builtins.y2milestone("ParseConfigLio conn:%1", ls2)
        if Builtins.haskey(
            Ops.get_map(tgmap, Ops.get_string(ls2, 0, ""), {}),
            Ops.get_integer(ls2, 1, -1)
          )
          Ops.set(
            tgmap,
            [Ops.get_string(ls2, 0, ""), Ops.get_integer(ls2, 1, -1), "conn"],
            Ops.add(
              Ops.get_integer(
                tgmap,
                [Ops.get_string(ls2, 0, ""), Ops.get_integer(ls2, 1, -1), "conn"],
                0
              ),
              1
            )
          )
        end
        if Builtins.haskey(
            Ops.get_map(
              tgmap,
              [Ops.get_string(ls2, 0, ""), Ops.get_integer(ls2, 1, -1), "clnt"],
              {}
            ),
            Ops.get_string(ls2, 2, "")
          )
          Ops.set(
            tgmap,
            [
              Ops.get_string(ls2, 0, ""),
              Ops.get_integer(ls2, 1, -1),
              "clnt",
              Ops.get_string(ls2, 2, ""),
              "connected"
            ],
            true
          )
        end
      end
      Ops.set(ret, "tgt", tgmap)
      deep_copy(ret)
    end

    def CheckPath(p)
      ret = [false, false, 0]
      stat = Convert.to_map(SCR.Read(path(".target.stat"), p))
      Ops.set(
        ret,
        0,
        Ops.get_boolean(stat, "isblock", false) ||
          Ops.get_boolean(stat, "isreg", false)
      )
      Ops.set(
        ret,
        1,
        Ops.get_boolean(ret, 0, false) &&
          Ops.get_boolean(stat, "isblock", false)
      )
      if Ops.get_boolean(ret, 0, false)
        Ops.set(ret, 2, Ops.get_integer(stat, "size", 0))
      end
      Builtins.y2milestone("CheckPath p:%1 ret:%2", p, ret)
      deep_copy(ret)
    end

    def CreateTcmDev(p)
      ret = ""
      cmd = "tcm_node "
      bl = CheckPath(p)
      file = !Ops.get_boolean(bl, 1, false)
      if Ops.get_boolean(bl, 0, false)
        ret = Ops.get_boolean(bl, 1, false) ? "iblock_0/" : "fileio_0/"
        cmd = Ops.add(
          cmd,
          Ops.get_boolean(bl, 1, false) ? "--block " : "--fileio "
        )
      end
      if !Builtins.isempty(ret)
        ret = CreateTcmKey(Ops.get_map(@data, "tcm", {}), ret, p)
        cmd = Ops.add(Ops.add(Ops.add(cmd, ret), " "), p)
        cmd = Ops.add(Ops.add(cmd, " "), Ops.get_integer(bl, 2, 1)) if file
      end
      if !Builtins.isempty(ret) && !LogExecCmd(cmd)
        ret = ""
      else
        Ops.set(
          @data,
          ["tcm", ret],
          { "path" => p, "type" => file ? :fileio : :iblock }
        )
      end
      Builtins.y2milestone("CreateTcmDev path:%1 ret:%2", p, ret)
      if !Builtins.isempty(ret)
        Builtins.y2milestone(
          "CreateTcmDev new tcm:%1",
          Ops.get_map(@data, ["tcm", ret], {})
        )
      end
      ret
    end

    def DoRemoveLun(tgt, tpg, l)
      kt = Ops.add(Ops.add(Ops.add(Ops.add(tgt, " "), tpg), " "), l)
      ret = LogExecCmd(Ops.add("lio_node --dellun ", kt))
      Builtins.y2milestone(
        "DoRemoveLun tgt:%1 tpg:%2 l:%3 ret:%4",
        tgt,
        tpg,
        l,
        ret
      )
      ret
    end

    def ActivateLun(tgt, tpg, lun, lm)
      lm = deep_copy(lm)
      Builtins.y2milestone("ActivateLun tgt:%1 tpg:%2 lun:%3", tgt, tpg, lun)
      kt = Ops.add(Ops.add(Ops.add(Ops.add(tgt, " "), tpg), " "), lun)
      ok = true
      done = false
      if Builtins.haskey(
          Ops.get_map(@data, ["tgt", tgt, tpg, "ep", "lun"], {}),
          lun
        )
        if Ops.get_string(
            @data,
            ["tgt", tgt, tpg, "ep", "lun", lun, "tcm_key"],
            ""
          ) !=
            Ops.get_string(lm, "tcm_key", "") ||
            Ops.get_string(@data, ["tgt", tgt, tpg, "ep", "lun", lun, "nm"], "") !=
              Ops.get_string(lm, "nm", "")
          ok = DoRemoveLun(tgt, tpg, lun)
        else
          done = true
        end
      end
      if !done && ok && Builtins.isempty(Ops.get_string(lm, "tcm_key", ""))
        key = CreateTcmDev(Ops.get_string(lm, "path", ""))
        if Builtins.isempty(key)
          ok = false
        else
          Ops.set(lm, "tcm_key", key)
        end
      end
      if !done && ok
        ok = LogExecCmd(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(Ops.add("lio_node --addlun ", kt), " "),
                Ops.get_string(lm, "nm", "")
              ),
              " "
            ),
            Ops.get_string(lm, "tcm_key", "")
          )
        )
      end
      Builtins.y2milestone("ActivateLun ok:%1 done:%2 lm:%3", ok, done, lm)
      ok
    end

    def EnableTpg(tgt, tpg)
      ret = LogExecCmd(
        Ops.add(Ops.add(Ops.add("lio_node --enabletpg ", tgt), " "), tpg)
      )
      ret
    end

    def ActivateConfigIetd(dat)
      dat = deep_copy(dat)
      cmd = ""
      ok = true
      Builtins.y2milestone("ActivateConfigIetd start")
      Builtins.foreach(Ops.get_map(dat, "tgt", {})) do |key, m|
        Builtins.foreach(m) do |tpg, d|
          kt = Ops.add(Ops.add(key, " "), tpg)
          Builtins.foreach(Ops.get_map(d, ["ep", "lun"], {})) do |l, lun|
            ok = ActivateLun(key, tpg, l, lun) && ok
          end
          ok = EnableTpg(key, tpg) && ok if !IsTpgActive(key, tpg)
        end
      end
      Builtins.y2milestone("ActivateConfigIetd ok:%1", ok)
      @data = ParseConfigLio()
      ok
    end

    def NeedUpdateLun(tgt, tpg, lm)
      lun = Ops.get_integer(lm.value, "lun", -1)
      ret = !Builtins.haskey(
        Ops.get_map(@data, ["tgt", tgt, tpg, "ep", "lun"], {}),
        lun
      )
      tk = FindTcmKey(Ops.get_string(lm.value, "path", ""))
      Ops.set(lm.value, "tcm_key", tk) if !Builtins.isempty(tk)
      if !ret
        ret = Ops.get_string(
          @data,
          ["tgt", tgt, tpg, "ep", "lun", lun, "tcm_key"],
          ""
        ) !=
          Ops.get_string(lm.value, "tcm_key", "") ||
          Ops.get_string(@data, ["tgt", tgt, tpg, "ep", "lun", lun, "nm"], "") !=
            Ops.get_string(lm.value, "nm", "")
      end
      Builtins.y2milestone("NeedUpdateLun ret:%1 lm:%2", ret, lm.value)
      ret
    end

    def DoUpdateLun(tgt, tpg, lm)
      lm = deep_copy(lm)
      Builtins.y2milestone("DoUpdateLun tgt:%1 tpg:%2 lm:%3", tgt, tpg, lm)
      lun = Ops.get_integer(lm, "lun", -1)
      ret = ActivateLun(tgt, tpg, lun, lm)
      Builtins.y2milestone("DoUpdateLun ret:%1", ret)
      ret
    end

    def AddTarget(tgt, tpg)
      ret = LogExecCmd(
        Ops.add(Ops.add(Ops.add("lio_node --addtpg ", tgt), " "), tpg)
      )
      ret = EnableTpg(tgt, tpg) if ret
      Builtins.y2milestone("AddTarget tgt:%1 tpg:%2 ret:%3", tgt, tpg, ret)
      ret
    end

    def DelTarget(tgt, tpg)
      ret = LogExecCmd(
        Ops.add(Ops.add(Ops.add("lio_node --deltpg ", tgt), " "), tpg)
      )
      if ret &&
          Ops.less_or_equal(
            Builtins.size(Ops.get_map(@data, ["tgt", tgt], {})),
            1
          )
        ret = LogExecCmd(Ops.add("lio_node --deliqn ", tgt))
      end
      Builtins.y2milestone("DelTarget tgt:%1 tpg:%2 ret:%3", tgt, tpg, ret)
      ret
    end

    def SetAuth(tgt, tpg, clnt, inc, out)
      inc = deep_copy(inc)
      out = deep_copy(out)
      Builtins.y2milestone(
        "SetAuth tgt:%1 tpg:%2 clnt:%3 in:%4 out:%5",
        tgt,
        tpg,
        clnt,
        inc,
        out
      )
      cmd = ""
      ret = true
      if Builtins.isempty(tgt)
        cmd = "lio_node --setchapdiscauth "
        if !Builtins.isempty(inc)
          ret = LogExecCmd(
            Ops.add(
              Ops.add(Ops.add(cmd, Ops.get_string(inc, 0, "")), " "),
              Ops.get_string(inc, 1, "")
            )
          ) && ret
        elsif HasIncomingAuth("", 0, "")
          ret = LogExecCmd(Ops.add(cmd, "\"\" \"\" ")) && ret
        end
        cmd = "lio_node --setchapdiscmutualauth "
        if !Builtins.isempty(out)
          ret = LogExecCmd(
            Ops.add(
              Ops.add(Ops.add(cmd, Ops.get_string(out, 0, "")), " "),
              Ops.get_string(out, 1, "")
            )
          ) && ret
        elsif HasOutgoingAuth("", 0, "")
          ret = LogExecCmd(Ops.add(cmd, "\"\" \"\" ")) && ret
        end
      else
        param = Ops.add(
          Ops.add(Ops.add(Ops.add(Ops.add(tgt, " "), tpg), " "), clnt),
          " "
        )
        cmd = Ops.add("lio_node --setchapauth ", param)
        if !Builtins.isempty(inc)
          ret = LogExecCmd(
            Ops.add(
              Ops.add(Ops.add(cmd, Ops.get_string(inc, 0, "")), " "),
              Ops.get_string(inc, 1, "")
            )
          ) && ret
        elsif HasIncomingAuth(tgt, tpg, clnt)
          ret = LogExecCmd(Ops.add(cmd, "\"\" \"\" ")) && ret
        end
        cmd = Ops.add("lio_node --setchapmutualauth ", param)
        if !Builtins.isempty(out)
          ret = LogExecCmd(
            Ops.add(
              Ops.add(Ops.add(cmd, Ops.get_string(out, 0, "")), " "),
              Ops.get_string(out, 1, "")
            )
          ) && ret
        elsif HasOutgoingAuth(tgt, tpg, clnt)
          ret = LogExecCmd(Ops.add(cmd, "\"\" \"\" ")) && ret
        end
      end
      Builtins.y2milestone("SetAuth ret:%1", ret)
      ret
    end

    def SetTpgAuth(tgt, tpg, value)
      ret = true
      tgt_auth_info = GetTgt(@data, tgt, tpg)
      Builtins.y2milestone("SetTpgAuth tgt:%1 tpg:%2 value:%3 auth_info:%4",
                           tgt, tpg, value, tgt_auth_info)

      value_changed = value != tgt_auth_info.fetch("auth", false)
      if value_changed || tgt_auth_info.empty?
        auth = value ? "--enableauth" : "--disableauth"
        cmd = "lio_node #{auth} #{tgt} #{tpg}"
        ret = LogExecCmd(cmd)
      end
      Builtins.y2milestone("SetTpgAuth ret:%1", ret)
      ret
    end

    def DoRemoveClnt(tgt, tpg, clnt)
      kt = Ops.add(Ops.add(Ops.add(Ops.add(tgt, " "), tpg), " "), clnt)
      ret = LogExecCmd(Ops.add("lio_node --delnodeacl ", kt))
      Builtins.y2milestone(
        "DoRemoveClnt tgt:%1 tpg:%2 clnt:%3 ret:%4",
        tgt,
        tpg,
        clnt,
        ret
      )
      ret
    end

    def DoCreateClnt(tgt, tpg, clnt)
      kt = Ops.add(Ops.add(Ops.add(Ops.add(tgt, " "), tpg), " "), clnt)
      ret = LogExecCmd(Ops.add("lio_node --addnodeacl ", kt))
      Builtins.y2milestone(
        "DoCreateClnt tgt:%1 tpg:%2 clnt:%3 ret:%4",
        tgt,
        tpg,
        clnt,
        ret
      )
      ret
    end


    def DoRemoveClntLun(tgt, tpg, clnt, lun)
      kt = Ops.add(
        Ops.add(
          Ops.add(Ops.add(Ops.add(Ops.add(tgt, " "), tpg), " "), clnt),
          " "
        ),
        lun
      )
      ret = LogExecCmd(Ops.add("lio_node --dellunacl ", kt))
      Builtins.y2milestone(
        "DoRemoveClntLun tgt:%1 tpg:%2 clnt:%3 lun:%4 ret:%5",
        tgt,
        tpg,
        clnt,
        lun,
        ret
      )
      ret
    end


    def DoCreateClntLun(tgt, tpg, clnt, lun, tlun)
      kt = Ops.add(
        Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(Ops.add(Ops.add(Ops.add(tgt, " "), tpg), " "), clnt),
              " "
            ),
            tlun
          ),
          " "
        ),
        lun
      )
      ret = LogExecCmd(Ops.add("lio_node --addlunacl ", kt))
      Builtins.y2milestone(
        "DoCreateClntLun tgt:%1 tpg:%2 clnt:%3 lun:%4:%5 ret:%6",
        tgt,
        tpg,
        clnt,
        lun,
        tlun,
        ret
      )
      ret
    end

    def UpdateConfig
      @data = ParseConfigLio()
      Builtins.y2milestone("UpdateConfig done")

      nil
    end

    def SaveSettings
      dump_cmd = "/usr/sbin/lio_dump --file /etc/target/lio_setup.sh"
      if !LogExecCmd(dump_cmd)
        Report.Error(_("Cannot save lio setup"))
      end
      setup_cmd = "/usr/sbin/tcm_dump --file /etc/target/tcm_setup.sh"
      if !LogExecCmd(setup_cmd)
        Report.Error(_("Cannot save tcm setup"))
      end
    end

    publish :function => :CreateLunName, :type => "string (list <string>, string)"
    publish :function => :ParseConfigIetd, :type => "map <string, any> (map <string, any>)"
    publish :function => :AddNewTarget, :type => "void (string, integer, list <string>)"
    publish :function => :SetIetdAuth, :type => "void (string, integer, list <string>, string)"
    publish :function => :HasTarget, :type => "boolean (string, integer)"
    publish :function => :HasIncomingAuth, :type => "boolean (string, integer, string)"
    publish :function => :HasOutgoingAuth, :type => "boolean (string, integer, string)"
    publish :function => :HasAuth, :type => "boolean (string, integer, string)"
    publish :function => :GetAuth, :type => "map (string, integer, string)"
    publish :function => :GetLun, :type => "map <integer, map> (string, integer)"
    publish :function => :GetLunList, :type => "list <list> (string, integer)"
    publish :function => :GetNetworkPortal, :type => "list <string> (string, integer)"
    publish :function => :GetTpgAuth, :type => "boolean (string, integer)"
    publish :function => :GetClntList, :type => "list <string> (string, integer)"
    publish :function => :GetClntLun, :type => "map <integer, integer> (string, integer, string)"
    publish :function => :SetNetworkPortal, :type => "boolean (string, integer, string, string, boolean)"
    publish :function => :GetTargets, :type => "list <list> ()"
    publish :function => :GetExportLun, :type => "string (integer, map)"
    publish :function => :GetExportAuth, :type => "list <map <string, any>> (string, integer)"
    publish :function => :GetExportTargets, :type => "map <string, any> ()"
    publish :function => :GetData, :type => "map <string, any> ()"
    publish :function => :SetData, :type => "void (map <string, any>)"
    publish :function => :ClearData, :type => "void ()"
    publish :function => :GetChanges, :type => "map <string, any> ()"
    publish :function => :GetConfig, :type => "map <string, any> ()"
    publish :function => :GetIpAddr, :type => "list <string> ()"
    publish :function => :GetConnected, :type => "list <string> ()"
    publish :function => :ParseConfigLio, :type => "map <string, any> ()"
    publish :function => :CheckPath, :type => "list (string)"
    publish :function => :DoRemoveLun, :type => "boolean (string, integer, integer)"
    publish :function => :EnableTpg, :type => "boolean (string, integer)"
    publish :function => :ActivateConfigIetd, :type => "boolean (map)"
    publish :function => :NeedUpdateLun, :type => "boolean (string, integer, map &)"
    publish :function => :DoUpdateLun, :type => "boolean (string, integer, map)"
    publish :function => :AddTarget, :type => "boolean (string, integer)"
    publish :function => :DelTarget, :type => "boolean (string, integer)"
    publish :function => :SetAuth, :type => "boolean (string, integer, string, list, list)"
    publish :function => :SetTpgAuth, :type => "boolean (string, integer, boolean)"
    publish :function => :DoRemoveClnt, :type => "boolean (string, integer, string)"
    publish :function => :DoCreateClnt, :type => "boolean (string, integer, string)"
    publish :function => :DoRemoveClntLun, :type => "boolean (string, integer, string, integer)"
    publish :function => :DoCreateClntLun, :type => "boolean (string, integer, string, integer, integer)"
    publish :function => :UpdateConfig, :type => "void ()"
    publish :function => :SaveSettings, :type => "void()"
  end

  IscsiLioData = IscsiLioDataClass.new
  IscsiLioData.main
end
