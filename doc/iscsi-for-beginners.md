# Getting used to iscsi

**iscsi Newspeak: when iscsi folks talk about *target*, think *server*,
when they say *initiator*, think *client*.**

I will describe here the steps necessary to setup some minimal iscsi testing
environment.

Best seems to be to setup a dedicated vm to serve as target and to use another one
as initiator.

On the target, install packages `yast2-iscsi-lio-server` and `targetcli` (SLE-12)
resp. `python3-targetcli-fb` (SLE-15).

The initiator needs `open-iscsi` (and `yast2-iscsi-client`); both should
be installed by default.

Read the documentation on how to setup things: 'Mass Storage over IP Networks: iSCSI' for
[SLE-12](https://www.suse.com/documentation/sles-12/stor_admin/data/cha_iscsi.html) or
[SLE-15](https://www.suse.com/documentation/sles-15/book_storage/data/cha_iscsi.html).

For more in-depth documentation read
- http://linux-iscsi.org/wiki/ISCSI
- http://linux-iscsi.org/wiki/LIO

*Note that you must know the initiator name when creating the target config.
You can't just connect 'something' to the target. So look it up on your
initiator first.*

## iscsi target setup

For first steps, use `yast2 iscsi-lio-server`.

*Disable firewall or open the iscsi port (3260).*

> SLE-12 only
>
> When you setup a vm with dhcp, make sure you have a stable ip address, else it
> will drive you mad, as the target ip is part of the config - see last step in the
> `targetcli` example below.
>
> *For me, `/etc/target/lio_setup.sh` always failed when run the very first time
> (the initial `mkdir` in the script fails), restarting the `target` service helped.*

The iscsi target is handled by kernel modules. Config goes to `/sys/kernel/config/target/iscsi/`.

On SLE-12 `/etc/target/lio_setup.sh` is a generated shell script that takes
care of kernel space modifications.

On SLE-15 the config is stored in a JSON file `/etc/target/saveconfig.json`. Old (up to 10)
versions of this file are kept in `/etc/target/backup/`.

Check that things work: `systemctl status target` (SLE-12) resp. `systemctl status targetcli` (SLE-15).

Instead of `yast2 iscsi-lio-server` you can use `targetcli` for config. `targetcli` is a rather
peculiar tool. You basically navigate through a virtual filesystem (Use `ls` often!).
Basic syntax is `[PATH] COMMAND ARGS`. Just watch examples below.

> Note that not all COMMANDs are available in all PATHs.

Alternatively you can supply arguments to `targetcli` directly, like

```sh
targetcli /iscsi set discovery_auth enable=0
```

Here's how to setup a target with it. Run `targetcli`, then

```sh
# first, make the block device you want to export known
cd /backstores/iblock
create dev_sda1 /dev/sda1

# or use /backstores/fileio to export a file
/backstores/fileio create foo1 /tmp/foo1.img 1G

# then, create an iscsi target
cd /iscsi
create

# change into the newly created target portal group (Note the final '/tpg1'!)
# (the name is just an example)
cd iqn.2003-01.org.linux-iscsi.e111.x8664:sn.18436556ef11/tpg1

# add a lun
luns/ create /backstores/iblock/dev_sda1

# add an acl to make it accessible to your initiator
# (use your real iscsi initiator name here)
acls/ create iqn.1996-04.de.suse:01:ded3a83a491

# then, export it
# Note that this uses your current ip address!
portals/ create

# to enhance your testing experience it is very helpful to turn off authentication
set attribute authentication=0

# ... and also for the discovery process
/iscsi set discovery_auth enable=0
```

At this point the iscsi initiator should see the device (check with `iscsiadm -m discovery ...`).

> Note SLE-15
>
> While you have to set boolean config variables with `set xxx enable=0|1`, `targetcli` reports the setting
> with `'True'` or `'False'`.

To make changes persistent, on SLE-12 you have to stop the `target` service.
This will update `/etc/target/lio_setup.sh`.

On SLE-15, the config is auto-updated when you `exit` from `targetcli` or
call `targetcli / saveconfig` directly.

```sh
# only needed for SLE-12
#
systemctl stop target
systemctl start target
```

### demo mode

If the setup is used only for testing and not for production, you might
consider granting access to all initiators. This saves you all the hassle
with getting the initiator IQN right.

For this, create the target portal group as descibed in the last section. Then do:

```sh
# change into the newly created target portal group (Note the final '/tpg1'!)
# (the name is just an example)
cd iqn.2003-01.org.linux-iscsi.e111.x8664:sn.18436556ef11/tpg1

# enable demo mode (generate_node_acls=1)
set attribute authentication=0 generate_node_acls=1 demo_mode_write_protect=0 cache_dynamic_acls=1
```

And that's it. Setting `generate_node_acls=1` is called 'demo mode'.


### multipath setup

A multipath setup uses several servers but the same WWN
(`iqn.2003-01.org.linux-iscsi.e111.x8664:sn.18436556ef11` in the example above).
Note that `create` accepts a WWN as argument.

> Note SLE-12
>
> If you decide to simply clone the virtual machine don't forget that the
> config is stored in `/etc/target/lio_setup.sh` and contains the IP address of the
> server. Replace it with the real IP address before starting the `target` service.
>
> *If you inadvertently started with the wrong IP still in the config the `target` service will fail. Do **NOT**
> stop the service as that will overwrite `lio_setup.sh` with the half-done broken setup. Instead make a backup copy
> of `lio_setup.sh` before stopping the service.*

## iscsi initiator setup

For first steps, use `yast2 iscsi-client`.

On the initiator, iscsid must be running: `systemctl status iscsi iscsid`.

The config is in `/etc/iscsi`. Important is `/etc/iscsi/iscsi.initiatorname`
which sets the initiator name (*client name* in the yast lio-server dialog).

Important commands:

- `iscsiadm -m discovery --type=st --portal=<target_server>`: list the available nodes.

- `iscsiadm -m node -n <node_name> --login`: use the nodes from the output of the command above
(2nd column) to connect to the target - this makes the device available

- `iscsiadm -m node -n <node_name> --logout`: disconnect the device

Connections (with config) you have made are stored (cached) in `/etc/iscsi/{send_targets,nodes}`.

`/etc/iscsi/iscsid.conf` is a red herring and not used for anything.

