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
# File:	include/iscsi-lio-server/helps.ycp
# Package:	Configuration of iscsi-lio-server
# Summary:	Help texts of all the dialogs
# Authors:	Thomas Fehr <fehr@suse.de>
#
# $Id$
module Yast
  module IscsiLioServerHelpsInclude
    def initialize_iscsi_lio_server_helps(include_target)
      textdomain "iscsi-lio-server"

      # All helps are here
      @HELPS = {
        # Read dialog help 1/2
        "read"               => _(
          "<p><b><big>Initializing iSCSI LIO Target Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ) +
          # Read dialog help 2/2
          _(
            "<p><b><big>Aborting Initialization</big></b><br>\n" +
            "Safely abort the configuration utility by pressing <b>Abort</b> now.</p>\n"
          ),
        # Write dialog help 1/2
        "write"              => _(
          "<p><b><big>Saving iSCSI Target Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ) +
          # Write dialog help 2/2
          _(
            "<p><b><big>Aborting Saving:</big></b><br>\n" +
              "Abort the save procedure by pressing <b>Abort</b>.\n" +
              "An additional dialog informs whether it is safe to do so.\n" +
              "</p>\n"
          ),
        "save_configuration" => _(
          "<p><b>Save</b> button will export some information about\ntargets into selected file.</p>"
        ),
        # Summary dialog help 1/3
        "summary"            => _(
          "<p><b><big>iSCSI Target Configuration</big></b><br>\nConfigure an iSCSI target here.<br></p>\n"
        ) +
          # Summary dialog help 2/3
          _(
            "<p><b><big>Adding an iSCSI Target</big></b><br>\n" +
              "Choose an iSCSI target from the list of detected iSCSI targets.\n" +
              "If your target was not detected, use <b>Other (not detected)</b>.\n" +
              "Then press <b>Configure</b>.</p>\n"
          ) +
          # Summary dialog help 3/3
          _(
            "<p><b><big>Editing or Deleting</big></b><br>\n" +
              "If you press <b>Edit</b>, an additional dialog in which to change\n" +
              "the configuration opens.</p>\n"
          ),
        # Ovreview dialog help 1/3
        "overview"           => _(
          "<p><b><big>iSCSI Target Configuration Overview</big></b><br>\n" +
            "Obtain an overview of installed iSCSI targets. Additionally\n" +
            "edit their configurations.<br></p>\n"
        ) +
          # Ovreview dialog help 2/3
          _(
            "<p><b><big>Adding an iSCSI Target</big></b><br>\n" +
            "Press <b>Add</b> to configure an iSCSI target.</p>"
          ) +
          # Ovreview dialog help 3/3
          _(
            "<p><b><big>Editing or Deleting</big></b><br>\n" +
              "Choose an iSCSI target to change or remove.\n" +
              "Then press <b>Edit</b> or <b>Delete</b> as desired.</p>\n"
          ),
        # Configure1 dialog help 1/2
        "c1"                 => _(
          "<p><b><big>Configuration Part One</big></b><br>\n" +
            "Press <b>Next</b> to continue.\n" +
            "<br></p>"
        ) +
          # Configure1 dialog help 2/2
          _(
            "<p><b><big>Selecting Something</big></b><br>\n" +
              "It is not possible. You must code it first. :-)\n" +
              "</p>"
          ),
        # Configure2 dialog help 1/2
        "c2"                 => _(
          "<p><b><big>Configuration Part Two</big></b><br>\n" +
            "Press <b>Next</b> to continue.\n" +
            "<br></p>\n"
        ) +
          # Configure2 dialog help 2/2
          _(
            "<p><b><big>Selecting Something</big></b><br>\n" +
              "It is not possible. You must code it first. :-)\n" +
              "</p>"
          ),
        # discovery authentication
        "global_config"      => _(
          "Select the type of authentication. Use <b>No Authentication</b> or one of <b>Incoming</b>" +
          " and <b>Outgoing</b> (can be both together). Then insert <b>User</b> and <b>Password</b>."
        ),
        # target client setup.
        "target-clnt"        => _(
           "<p>Use <b>Add</b> to give a client access for a LUN imported from target portal group." +
           " Specify which client is allowed to access it (client name is <i>InitiatorName</i> in" +
           " '/etc/iscsi/initiatorname.iscsi' on iscsi initiator). <b>Delete</b> will remove the" +
           " client access to the LUN.</p>"
         ) +
          _(
            "<p>With <b>Edit LUN</b> one can modify the LUN mapping. Please note that LUN target number" +
            " must be unique.<br>After pressing <b>Edit Auth</b>, select the type of authentication." +
            " Use <b>Incoming</b>, <b>Outgoing</b> or both together. Then insert <b>User</b> and <b>Password</b>." +
            " If <b>Use Authentication</b> is disabled in previous dialog, <b>Edit Auth</b> is disabled here.</p>"
          ) +
        _( "<p><b>Copy</b> offers the possibility to give an additional client access to the LUN.</p>"),
        # target dialog
        "server_table"       => _(
          "List of offered targets and target portal groups. Create a new target by clicking <b>Add</b>.\n" +
          "To delete or modify an item, select it and press <b>Edit</b> or <b>Delete</b>."
        ),
        # edit target
        "target-modify"      => _(
          "<h1>iSCSI Target IP/Port and LUN setup</h1>"
        ) + "<p>" +
          _(
            "It is possible to make arbitary block devices or files available under a <b>LUN</b>.\n" +
              "You have to provide <b>path</b> to either block devices or file. \n" +
              "The <b>LUN name</b> is an arbitrary name to uniquely identify the <b>LUN</b>. \n" +
              "The name needs to be unique within the target portal group. If the user\n" +
              "does not provide a name for LUN, it is generated automatically."
          ) + "</p>" + "<p>" +
          _(
            "<p>Under <b>Ip Address</b> and <b>Port Number</b> you specify under which address\n" +
              "and port the service will be available. Default for port number is 3260.\n" +
              "Only ip addresses assigned to one of the network cards are possible."
          ) + "</p>",
        # add target
        "target-add"         => _(
          "<h1>iSCSI Target IP/Port and LUN setup</h1>"
        ) + "<p>" +
          _(
            "Create a new target. Replace template values with the correct values."
          ) + "</p>" +
          _(
            "It is possible to make arbitary block devices or files available under a lun.\n" +
              "You have to provide <b>path</b> to either block devices or file. \n" +
              "The <b>LUN name</b> is an arbitrary name to uniquely identify the <b>LUN</b>. \n" +
              "The name needs to be unique within the target portal group. If the user\n" +
              "does not provide a name for LUN, it is generated automatically."
          ) + "</p>" + "<p>" +
          _(
            "<p>Under <b>Ip Address</b> and <b>Port Number</b> you specify under which address\n" +
              "and port the service will be available. Default for port number is 3260.\n" +
              "Only ip addresses assigned to one of the network cards are possible."
          ) + "</p>",
        # expert dialog
        "expert"             => _("<h1>iSCSI Target</h1>") +
          _(
            "It is possible to <b>add</b>, <b>edit</b> or <b>delete</b> all additional configuration options."
          ),
        # LUN details
        "lun-details"        => _("<h1>iSCSI Target</h1>") +
          _(
            "Edit <b>LUN</b> number if needed, set <b>Type</b> (nullio is for testing purposes).\n" +
            "If Type=fileio set <b>Path</b> to disk device or file.<b>SCSI ID</b> and <b>Sectors</b> are optional."
          )
      } 

      # EOF
    end
  end
end
