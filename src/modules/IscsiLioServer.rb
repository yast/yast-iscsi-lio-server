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
# File:	modules/IscsiLioServer.ycp
# Package:	Configuration of iscsi-lio-server
# Summary:	IscsiLioServer settings, input and output functions
# Authors:	Thomas Fehr <fehr@suse.de>
#
# $Id$
#
# Representation of the configuration of iscsi-lio-server.
# Input and output routines.
require "yast"

module Yast
  class IscsiLioServerClass < Module
    def main
      textdomain "iscsi-lio-server"

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Message"
      Yast.import "Service"
      Yast.import "Package"
      Yast.import "Popup"
      Yast.import "SuSEFirewall"
      Yast.import "Confirm"
      Yast.import "IscsiLioData"
      Yast.import "Mode"
      Yast.import "NetworkService"
      Yast.import "PackageSystem"
      Yast.import "Label"

      @serviceStatus = false
      @statusOnStart = false

      # Data was modified?
      @modified = false
      @configured = false


      @proposal_valid = false

      # Write only, used during autoinstallation.
      # Don't run services and SuSEconfig, it's all done at one place.
      @write_only = false

      # Abort function
      # return boolean return true if abort
      @AbortFunction = fun_ref(method(:Modified), "boolean ()")
    end

    # Abort function
    # @return [Boolean] return true if abort
    def Abort
      return @AbortFunction.call == true if @AbortFunction != nil
      false
    end

    # Data was modified?
    # @return true if modified
    def Modified
      Builtins.y2debug("modified=%1", @modified)
      @modified
    end



    # Settings: Define all variables needed for configuration of iscsi-lio-server
    # TODO FIXME: Define all the variables necessary to hold
    # TODO FIXME: the configuration here (with the appropriate
    # TODO FIXME: description)
    # TODO FIXME: For example:
    #   /**
    #    * List of the configured cards.
    #   list cards = [];
    #
    #   /**
    #    * Some additional parameter needed for the configuration.
    #   boolean additional_parameter = true;

    # read configuration file /etc/ietd.conf
    def readConfig
      IscsiLioData.SetData(IscsiLioData.ParseConfigLio)
      true
    end

    # read configuration file /etc/ietd.conf
    def readIetdConfig
      read_values = Convert.convert(
        SCR.Read(path(".etc.ietd.all")),
        :from => "any",
        :to   => "map <string, any>"
      )
      IscsiLioData.ParseConfigIetd(read_values)
    end

    def activateIetdConfig(ietd)
      ietd = deep_copy(ietd)
      IscsiLioData.ActivateConfigIetd(ietd)
    end


    # dummy function since LIO has no config file
    def writeConfig
      true
    end

    # test if required package ("lio-utils") is installed
    def installed_packages
      if !PackageSystem.PackageInstalled("lio-utils")
        Builtins.y2milestone("Not installed, will install")
        confirm = Popup.AnyQuestionRichText(
          "",
          _("Can't continue without installing lio-utils package"),
          40,
          10,
          Label.InstallButton,
          Label.CancelButton,
          :focus_yes
        )

        if confirm
          service = "tgtd"
          Service.Stop(service) if Service.Status(service) == 0
          Service.Disable(service)
          service = "iscsitarget"
          Service.Stop(service) if Service.Status(service) == 0
          Service.Disable(service)
          PackageSystem.DoInstall(["lio-utils"])
          if PackageSystem.PackageInstalled("lio-utils")
            return true
          else
            return false
          end
        end
        return false
      else
        return true
      end
    end

    # check status of target service
    # if not enabled, start it manually
    def getServiceStatus
      ret = true
      if Service.Status("target") == 0
        @statusOnStart = true
        @serviceStatus = true
      end
      Builtins.y2milestone("Service status = %1", @statusOnStart)
      if !@statusOnStart
        if !Service.Start("target")
          # to translator: %1 is replaced by pathname e.g. /etc/init.d/target
          txt = Builtins.sformat(
            _("Could not start service \"%1\""),
            "/etc/init.d/target"
          )
          Popup.Error(txt)
        end
      end
      ret
    end

    # Read all iscsi-lio-server settings
    # @return true on success
    def Read
      # IscsiLioServer read dialog caption
      caption = _("Initializing iSCSI LIO Target Configuration")

      # TODO FIXME Set the right number of stages
      steps = 4

      sl = 500
      Builtins.sleep(sl)

      # TODO FIXME Names of real stages
      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/3
          _("Read the database"),
          # Progress stage 2/3
          _("Read the previous settings"),
          # Progress stage 3/3
          _("Detect the devices")
        ],
        [
          # Progress step 1/3
          _("Reading the database..."),
          # Progress step 2/3
          _("Reading the previous settings..."),
          # Progress step 3/3
          _("Detecting the devices..."),
          # Progress finished
          _("Finished")
        ],
        ""
      )

      # check if user is root
      return false if !Confirm.MustBeRoot
      return false if !NetworkService.RunningNetworkPopup
      Progress.NextStage
      # check if required packages ("lio-utils") are installed
      return false if !installed_packages
      Builtins.sleep(sl)

      return false if Abort()
      Progress.NextStep
      # get status of target init script
      return false if !getServiceStatus
      Builtins.sleep(sl)

      return false if Abort()
      Progress.NextStage
      # read configuration (/etc/ietd.conf)
      readConfig
      if Builtins.size(IscsiLioData.GetTargets) == 0
        ietd = readIetdConfig
        msg = _(
          "You have currently no active LIO targets but there seems \n" +
            "to be a valid config in /etc/ietd.conf. Should the module \n" +
            "try to import setting from /etc/ietd.conf into LIO?"
        )
        if Ops.greater_than(Builtins.size(Ops.get_map(ietd, "tgt", {})), 0) &&
            Ops.get_boolean(Report.yesno_message_settings, "show", true) &&
            Popup.YesNo(msg)
          if !activateIetdConfig(ietd)
            err = _("Errors during import. Check LIO state!")
            Report.Error(err)
          end
        end
      end
      Builtins.sleep(sl)

      # detect devices
      Progress.set(false)
      SuSEFirewall.Read
      Progress.set(true)

      Progress.NextStage
      # Error message
      return false if false
      Builtins.sleep(sl)

      return false if Abort()
      @modified = false
      @configured = true
      true
    end

    # Write all iscsi-lio-server settings
    # @return true on success
    def Write
      # IscsiLioServer write dialog caption
      caption = _("Saving iSCSI LIO Target Configuration")

      # TODO FIXME And set the right number of stages
      steps = 2

      sl = 500
      Builtins.sleep(sl)

      # TODO FIXME Names of real stages
      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/2
          _("Write the settings"),
          # Progress stage 2/2
          _("Run SuSEconfig")
        ],
        [
          # Progress step 1/2
          _("Writing the settings..."),
          # Progress step 2/2
          _("Running SuSEconfig..."),
          # Progress finished
          _("Finished")
        ],
        ""
      )


      Progress.set(false)
      SuSEFirewall.Write
      Progress.set(true)

      Progress.NextStage
      Builtins.sleep(sl)
      true
    end

    # Get all iscsi-lio-server settings from the first parameter
    # (For use by autoinstallation.)
    # @param [Hash] settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(settings)
      settings = deep_copy(settings)
      Builtins.foreach(
        Convert.convert(settings, :from => "map", :to => "map <string, any>")
      ) do |key, value|
        case key
          when "service"
            @serviceStatus = Convert.to_boolean(value)
          when "auth"
            @incom = []
            @outgoin = ""
            Builtins.foreach(
              Convert.convert(
                value,
                :from => "any",
                :to   => "list <map <string, any>>"
              )
            ) do |row|
              if Ops.get_string(row, "KEY", "") == "IncomingUser"
                @incom = Builtins.add(@incom, Ops.get_string(row, "VALUE", ""))
              else
                @outgoin = Ops.get_string(row, "VALUE", "")
              end
            end
            IscsiLioData.SetIetdAuth("", 0, @incom, @outgoin)
          when "targets"
            @name = ""
            @lun = []
            @inc = []
            @out = ""
            Builtins.foreach(
              Convert.convert(
                value,
                :from => "any",
                :to   => "list <list <map <string, any>>>"
              )
            ) do |val|
              @name = ""
              @lun = []
              @inc = []
              @out = ""
              tpg = 1
              Builtins.foreach(val) do |row|
                case Ops.get_string(row, "KEY", "")
                  when "Target"
                    @name = Ops.get_string(row, "VALUE", "")
                  when "Tpg"
                    tpg = Builtins.tointeger(Ops.get_string(row, "VALUE", "1"))
                    tpg = 1 if tpg == nil
                  when "Lun"
                    @lun = Builtins.add(@lun, Ops.get_string(row, "VALUE", ""))
                  when "IncomingUser"
                    @inc = Builtins.add(@inc, Ops.get_string(row, "VALUE", ""))
                  when "OutgoingUser"
                    @out = Ops.get_string(row, "VALUE", "")
                end
              end
              IscsiLioData.AddNewTarget(@name, tpg, @lun)
              IscsiLioData.SetIetdAuth(@name, tpg, @inc, @out)
            end
        end
      end

      @configured = true
      true
    end

    # Dump the iscsi-lio-server settings to a single map
    # (For use by autoinstallation.)
    # @return [Hash] Dumped settings (later acceptable by Import ())
    def Export
      targets = []
      Builtins.foreach(IscsiLioData.GetExportTargets) do |k, v|
        targets = Builtins.add(targets, v)
      end

      result = {
        "version" => "1.0",
        "service" => @serviceStatus,
        "auth"    => IscsiLioData.GetExportAuth("", 0),
        "targets" => targets
      }
      @configured = true
      deep_copy(result)
    end

    def getLunDesc(lun)
      lun = deep_copy(lun)
      ret = ""
      Builtins.foreach(lun) do |l, m|
        ret = Ops.add(ret, ", ") if Ops.greater_than(Builtins.size(ret), 0)
        ret = Ops.add(ret, IscsiLioData.GetExportLun(l, m))
      end
      ret
    end

    # Create a textual summary and a list of unconfigured cards
    # @return summary of the current configuration
    def Summary
      summary = _("Configuration summary...")
      if @configured
        summary = Summary.AddHeader("", _("Global"))
        if @serviceStatus
          summary = Summary.AddLine(summary, _("When Booting"))
        else
          summary = Summary.AddLine(summary, _("Manually"))
        end
        if !IscsiLioData.HasAuth("", 0, "")
          summary = Summary.AddLine(summary, _("No Authentication"))
        else
          if IscsiLioData.HasIncomingAuth("", 0, "")
            summary = Summary.AddLine(summary, _("Incoming Authentication"))
          end
          if IscsiLioData.HasOutgoingAuth("", 0, "")
            summary = Summary.AddLine(summary, _("Outgoing Authentication"))
          end
        end
        summary = Summary.AddHeader(summary, _("Targets"))
        summary = Summary.OpenList(summary)
        Builtins.foreach(IscsiLioData.GetTargets) do |keys|
          summary = Summary.AddListItem(summary, Ops.get_string(keys, 0, ""))
          summary = Summary.AddLine(
            summary,
            getLunDesc(
              IscsiLioData.GetLun(
                Ops.get_string(keys, 0, ""),
                Ops.get_integer(keys, 1, 1)
              )
            )
          )
        end
        summary = Summary.CloseList(summary)
      else
        summary = Summary.NotConfigured
      end
      # TODO FIXME: your code here...
      # Configuration summary text for autoyast
      [summary, []]
    end

    # Create an overview table with all configured cards
    # @return table items
    def Overview
      # TODO FIXME: your code here...
      []
    end

    # Return packages needed to be installed and removed during
    # Autoinstallation to insure module has all needed software
    # installed.
    # @return [Hash] with 2 lists.
    def AutoPackages
      # TODO FIXME: your code here...
      { "install" => [], "remove" => [] }
    end


    # get/set service accessors for CWMService component
    def GetStartService
      status = Service.Enabled("target")
      Builtins.y2milestone("target service status %1", status)
      status
    end

    def SetStartService(status)
      Builtins.y2milestone("Set service status %1", status)
      @serviceStatus = status
      if status == true
        Service.Enable("target")
      else
        Service.Disable("target")
      end

      nil
    end

    publish :function => :Modified, :type => "boolean ()"
    publish :variable => :modified, :type => "boolean"
    publish :variable => :configured, :type => "boolean"
    publish :variable => :proposal_valid, :type => "boolean"
    publish :variable => :write_only, :type => "boolean"
    publish :variable => :AbortFunction, :type => "boolean ()"
    publish :function => :Abort, :type => "boolean ()"
    publish :function => :readConfig, :type => "boolean ()"
    publish :function => :readIetdConfig, :type => "map ()"
    publish :function => :activateIetdConfig, :type => "boolean (map)"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "list ()"
    publish :function => :Overview, :type => "list ()"
    publish :function => :AutoPackages, :type => "map ()"
    publish :function => :GetStartService, :type => "boolean ()"
    publish :function => :SetStartService, :type => "void (boolean)"
  end

  IscsiLioServer = IscsiLioServerClass.new
  IscsiLioServer.main
end
